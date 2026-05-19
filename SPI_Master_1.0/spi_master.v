`timescale 1ns / 1ps

module spi_master (
    input wire clk,
    input wire reset,
    input wire cpol,  // CPOL: 0=Idle Low, 1=Idle High
    input  wire cpha,   // CPHA: 0=첫 번째 엣지 샘플링, 1=두 번째 엣지 샘플링
    input  wire [7:0] clk_div,  // 클럭 분주비 (시스템 클럭을 SPI 클럭으로 낮춤)
    input wire [7:0] tx_data,  // 보낼 8비트 데이터
    input wire start,  // 전송 시작 트리거 신호
    output reg  [7:0] rx_data,  // 받은 8비트 데이터 (always 블록에서 할당되므로 reg)
    output reg done,  // 전송 완료 플래그 (reg)
    output reg busy,  // 현재 통신 중임을 알리는 플래그 (reg)
    output wire sclk,  // SPI 통신 클럭 (assign으로 연결되므로 wire)
    output reg mosi,  // Master Out Slave In 신호 (reg)
    input wire miso,  // Master In Slave Out 신호
    output reg cs_n  // Chip Select (Active Low, reg)
);

    // [변환 1] typedef enum -> localparam (상수 정의)
    localparam [1:0] IDLE = 2'b00, START = 2'b01, DATA = 2'b10, STOP = 2'b11;

    // [변환 2] logic -> reg (상태 머신 및 내부 플립플롭 변수들)
    reg [1:0] state;  // 현재 상태 저장
    reg [7:0] div_cnt;  // 분주 카운터
    reg half_tick;  // sclk의 반주기(Half-cycle)를 알리는 틱
    reg [7:0] tx_shift_reg;   // 송신용 시프트 레지스터 (데이터를 1비트씩 밀어냄)
    reg [7:0] rx_shift_reg;   // 수신용 시프트 레지스터 (데이터를 1비트씩 받아옴)
    reg [2:0] bit_cnt;        // 몇 번째 비트를 보내고 있는지 세는 카운터 (0~7)
    reg step;  // SPI 한 클럭 내에서 Send/Receive 단계를 구분
    reg sclk_r;  // 내부 sclk 생성용 레지스터

    // [변환 3] 내부 sclk_r 레지스터 값을 실제 외부 sclk 핀(wire)으로 연결
    assign sclk = sclk_r;

    // --- 분주기 (Clock Divider) 블록 ---
    // [변환 4] always_ff -> always @(posedge clk or posedge reset)
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            div_cnt   <= 8'd0;
            half_tick <= 1'b0;
        end else begin
            if (state == DATA) begin
                if (div_cnt == clk_div) begin
                    div_cnt <= 8'd0;
                    half_tick <= 1'b1;  // 지정된 분주비에 도달하면 half_tick 발생
                end else begin
                    div_cnt   <= div_cnt + 1'b1;
                    half_tick <= 1'b0;
                end
            end else begin
                // DATA 상태가 아닐 때는 카운터를 초기화하여 타이밍 꼬임 방지
                div_cnt   <= 8'd0;
                half_tick <= 1'b0;
            end
        end
    end

    // --- 메인 상태 머신 (FSM) 및 데이터 처리 블록 ---
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= IDLE;
            mosi <= 1'b1;
            cs_n <= 1'b1;
            busy <= 1'b0;
            done <= 1'b0;
            tx_shift_reg <= 8'd0;
            rx_shift_reg <= 8'd0;
            bit_cnt <= 3'd0;
            step <= 1'b0;
            rx_data <= 8'd0;
            sclk_r <= cpol;  // 리셋 시 sclk는 CPOL 설정에 맞춰 대기
        end else begin
            done <= 1'b0; // done 플래그는 기본적으로 0 (1클럭만 High 유지용)
            case (state)
                IDLE: begin
                    mosi   <= 1'b1;
                    cs_n   <= 1'b1;
                    sclk_r <= cpol;  // 유휴 상태의 클럭 레벨
                    if (start) begin
                        tx_shift_reg <= tx_data;  // 보낼 데이터 장전
                        bit_cnt      <= 3'd0;
                        step         <= 1'b0;
                        busy         <= 1'b1;  // 통신 시작 알림
                        cs_n         <= 1'b0;  // Slave 활성화 (Active Low)
                        state        <= START;
                    end
                end
                START: begin
                    if (!cpha) begin
                        // CPHA=0: 첫 번째 엣지에서 샘플링하므로, 클럭이 뛰기 전에 미리 데이터를 올려둠
                        mosi <= tx_shift_reg[7];
                        tx_shift_reg <= {
                            tx_shift_reg[6:0], 1'b0
                        };  // 좌측으로 시프트
                    end
                    state <= DATA;
                end
                DATA: begin
                    if (half_tick) begin
                        sclk_r <= ~sclk_r; // SPI 클럭 토글 (0->1 또는 1->0)
                        if (step == 1'b0) begin  // --- Receive Step ---
                            step <= 1'b1;
                            if (!cpha) begin
                                // CPHA=0: 첫 번째 엣지(현재)에서 수신
                                rx_shift_reg <= {rx_shift_reg[6:0], miso};
                            end else begin
                                // CPHA=1: 두 번째 엣지를 위해 지금 송신 데이터 준비
                                mosi         <= tx_shift_reg[7];
                                tx_shift_reg <= {tx_shift_reg[6:0], 1'b0};
                            end
                        end else begin  // --- Send Step ---
                            step <= 1'b0;
                            if (!cpha) begin
                                // CPHA=0: 두 번째 엣지(현재)에서 다음 송신 데이터 준비
                                if (bit_cnt < 3'd7) begin
                                    mosi         <= tx_shift_reg[7];
                                    tx_shift_reg <= {tx_shift_reg[6:0], 1'b0};
                                end
                            end else begin
                                // CPHA=1: 두 번째 엣지(현재)에서 수신
                                rx_shift_reg <= {rx_shift_reg[6:0], miso};
                            end
                            // 8비트를 모두 처리했는지 검사
                            if (bit_cnt == 3'd7) begin
                                state <= STOP;
                                if (!cpha) begin
                                    rx_data <= rx_shift_reg;
                                end else begin
                                    // CPHA=1인 경우 마지막 비트를 방금 받았으므로 합쳐서 저장
                                    rx_data <= {rx_shift_reg[6:0], miso};
                                end
                            end else begin
                                bit_cnt <= bit_cnt + 1'b1;
                            end
                        end
                    end
                end
                STOP: begin
                    sclk_r <= cpol; // 통신 종료 시 클럭을 기본 상태로 복귀
                    cs_n <= 1'b1;  // Slave 비활성화
                    done <= 1'b1;  // 전송 완료 플래그 1클럭 띄움
                    busy <= 1'b0;  // 통신 종료 알림
                    mosi <= 1'b1;
                    state <= IDLE;  // 다시 대기 상태로
                end
                default: begin
                    state <= IDLE;
                end
            endcase
        end
    end
endmodule

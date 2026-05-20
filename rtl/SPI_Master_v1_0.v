`timescale 1 ns / 1 ps

module SPI_Master_v1_0 #(
    // Users to add parameters here

    // User parameters ends
    // Do not modify the parameters beyond this line

    // Parameters of Axi Slave Bus Interface S00_AXI
    parameter integer C_S00_AXI_DATA_WIDTH = 32,
    parameter integer C_S00_AXI_ADDR_WIDTH = 4
) (
    // Users to add ports here
    output wire sclk,
    output wire mosi,
    input  wire miso,
    output wire cs_n,
    // User ports ends
    // Do not modify the ports beyond this line

    // Ports of Axi Slave Bus Interface S00_AXI
    input  wire                                  s00_axi_aclk,
    input  wire                                  s00_axi_aresetn,
    input  wire [    C_S00_AXI_ADDR_WIDTH-1 : 0] s00_axi_awaddr,
    input  wire [                         2 : 0] s00_axi_awprot,
    input  wire                                  s00_axi_awvalid,
    output wire                                  s00_axi_awready,
    input  wire [    C_S00_AXI_DATA_WIDTH-1 : 0] s00_axi_wdata,
    input  wire [(C_S00_AXI_DATA_WIDTH/8)-1 : 0] s00_axi_wstrb,
    input  wire                                  s00_axi_wvalid,
    output wire                                  s00_axi_wready,
    output wire [                         1 : 0] s00_axi_bresp,
    output wire                                  s00_axi_bvalid,
    input  wire                                  s00_axi_bready,
    input  wire [    C_S00_AXI_ADDR_WIDTH-1 : 0] s00_axi_araddr,
    input  wire [                         2 : 0] s00_axi_arprot,
    input  wire                                  s00_axi_arvalid,
    output wire                                  s00_axi_arready,
    output wire [    C_S00_AXI_DATA_WIDTH-1 : 0] s00_axi_rdata,
    output wire [                         1 : 0] s00_axi_rresp,
    output wire                                  s00_axi_rvalid,
    input  wire                                  s00_axi_rready
);

    // [수정됨] 통짜 32비트 와이어 대신, 명확한 개별 신호선으로 선언
    wire       w_cpol;
    wire       w_cpha;
    wire [7:0] w_clk_div;
    wire [7:0] w_tx_data;
    wire       w_start;
    wire [7:0] w_rx_data;
    wire       w_done;
    wire       w_busy;

    // Instantiation of Axi Bus Interface S00_AXI
    SPI_Master_v1_0_S00_AXI #(
        .C_S_AXI_DATA_WIDTH(C_S00_AXI_DATA_WIDTH),
        .C_S_AXI_ADDR_WIDTH(C_S00_AXI_ADDR_WIDTH)
    ) SPI_Master_v1_0_S00_AXI_inst (
        // [수정됨] 개별 신호선을 AXI 모듈에 직접 연결
        .cpol           (w_cpol),
        .cpha           (w_cpha),
        .clk_div        (w_clk_div),
        .tx_data        (w_tx_data),
        .start          (w_start),
        .rx_data        (w_rx_data),
        .done           (w_done),
        .busy           (w_busy),
        
        .S_AXI_ACLK     (s00_axi_aclk),
        .S_AXI_ARESETN  (s00_axi_aresetn),
        .S_AXI_AWADDR   (s00_axi_awaddr),
        .S_AXI_AWPROT   (s00_axi_awprot),
        .S_AXI_AWVALID  (s00_axi_awvalid),
        .S_AXI_AWREADY  (s00_axi_awready),
        .S_AXI_WDATA    (s00_axi_wdata),
        .S_AXI_WSTRB    (s00_axi_wstrb),
        .S_AXI_WVALID   (s00_axi_wvalid),
        .S_AXI_WREADY   (s00_axi_wready),
        .S_AXI_BRESP    (s00_axi_bresp),
        .S_AXI_BVALID   (s00_axi_bvalid),
        .S_AXI_BREADY   (s00_axi_bready),
        .S_AXI_ARADDR   (s00_axi_araddr),
        .S_AXI_ARPROT   (s00_axi_arprot),
        .S_AXI_ARVALID  (s00_axi_arvalid),
        .S_AXI_ARREADY  (s00_axi_arready),
        .S_AXI_RDATA    (s00_axi_rdata),
        .S_AXI_RRESP    (s00_axi_rresp),
        .S_AXI_RVALID   (s00_axi_rvalid),
        .S_AXI_RREADY   (s00_axi_rready)
    );

    // Add user logic here
    spi_master u_spi_master (
        .clk     (s00_axi_aclk),
        .reset   (~s00_axi_aresetn), // Active-Low 리셋 반전 처리
        
        // [수정됨] 개별 신호선을 SPI 코어에 1:1 다이렉트 매핑
        .cpol    (w_cpol),
        .cpha    (w_cpha),
        .clk_div (w_clk_div),
        .tx_data (w_tx_data),
        .start   (w_start),
        .rx_data (w_rx_data),
        .done    (w_done),
        .busy    (w_busy),
        
        // 물리적 외부 핀 연결
        .sclk    (sclk),
        .mosi    (mosi),
        .miso    (miso),
        .cs_n    (cs_n)
    );
    // User logic ends
endmodule

module spi_master (
    input wire clk,
    input wire reset,
    input wire cpol,  
    input wire cpha,   
    input wire [7:0] clk_div, 
    input wire [7:0] tx_data, 
    input wire start, 
    output reg [7:0] rx_data, 
    output reg done,  
    output reg busy,  
    output wire sclk, 
    output reg mosi,  
    input wire miso,  
    output reg cs_n  
);

    localparam [1:0] IDLE = 2'b00, START = 2'b01, DATA = 2'b10, STOP = 2'b11;

    reg [1:0] state;  
    reg [7:0] div_cnt;  
    reg half_tick;  
    reg [7:0] tx_shift_reg;   
    reg [7:0] rx_shift_reg;   
    reg [2:0] bit_cnt;        
    reg step;  
    reg sclk_r;  

    assign sclk = sclk_r;

    // --- 분주기 (Clock Divider) 블록 ---
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            div_cnt   <= 8'd0;
            half_tick <= 1'b0;
        end else begin
            if (state == DATA) begin
                if (div_cnt == clk_div) begin
                    div_cnt <= 8'd0;
                    half_tick <= 1'b1;  
                end else begin
                    div_cnt   <= div_cnt + 1'b1;
                    half_tick <= 1'b0;
                end
            end else begin
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
            sclk_r <= cpol;  
        end else begin
            done <= 1'b0; 
            case (state)
                IDLE: begin
                    mosi   <= 1'b1;
                    cs_n   <= 1'b1;
                    sclk_r <= cpol;  
                    if (start) begin
                        tx_shift_reg <= tx_data;  
                        bit_cnt      <= 3'd0;
                        step         <= 1'b0;
                        busy         <= 1'b1;  
                        cs_n         <= 1'b0;  
                        state        <= START;
                    end
                end
                START: begin
                    if (!cpha) begin
                        mosi <= tx_shift_reg[7];
                        tx_shift_reg <= {tx_shift_reg[6:0], 1'b0};  
                    end
                    state <= DATA;
                end
                DATA: begin
                    if (half_tick) begin
                        sclk_r <= ~sclk_r; 
                        if (step == 1'b0) begin  
                            step <= 1'b1;
                            if (!cpha) begin
                                rx_shift_reg <= {rx_shift_reg[6:0], miso};
                            end else begin
                                mosi         <= tx_shift_reg[7];
                                tx_shift_reg <= {tx_shift_reg[6:0], 1'b0};
                            end
                        end else begin  
                            step <= 1'b0;
                            if (!cpha) begin
                                if (bit_cnt < 3'd7) begin
                                    mosi         <= tx_shift_reg[7];
                                    tx_shift_reg <= {tx_shift_reg[6:0], 1'b0};
                                end
                            end else begin
                                rx_shift_reg <= {rx_shift_reg[6:0], miso};
                            end
                            if (bit_cnt == 3'd7) begin
                                state <= STOP;
                                if (!cpha) begin
                                    rx_data <= rx_shift_reg;
                                end else begin
                                    rx_data <= {rx_shift_reg[6:0], miso};
                                end
                            end else begin
                                bit_cnt <= bit_cnt + 1'b1;
                            end
                        end
                    end
                end
                STOP: begin
                    sclk_r <= cpol; 
                    cs_n <= 1'b1;  
                    done <= 1'b1;  
                    busy <= 1'b0;  
                    mosi <= 1'b1;
                    state <= IDLE;  
                end
                default: begin
                    state <= IDLE;
                end
            endcase
        end
    end
endmodule
# AXI4-Lite to SPI Protocol Bridge — Full-Stack SoC Verification Portfolio

> **SPI Master IP 설계 + AXI4-Lite 인터페이스 + UVM 검증 환경 구축 + 임베디드 C 드라이버**  
> Xilinx FPGA 기반 SoC 주변장치 설계 및 검증 프로젝트 (2026.05)

<br>

## 📌 프로젝트 한 줄 요약

ARM Cortex-A 프로세서의 AXI4-Lite 버스에서 SPI 슬레이브 디바이스를 제어하는  
커스텀 IP를 **RTL 설계 → UVM 검증 → 임베디드 드라이버**까지 Full-Stack으로 구현한 프로젝트입니다.

<br>

---

## 🗂️ 목차

1. [프로젝트 개요](#-프로젝트-개요)
2. [시스템 아키텍처](#-시스템-아키텍처)
3. [레지스터 맵](#-레지스터-맵)
4. [RTL 설계 상세](#-rtl-설계-상세)
5. [UVM 검증 환경](#-uvm-검증-환경)
6. [임베디드 C 드라이버](#-임베디드-c-드라이버)
7. [디렉토리 구조](#-디렉토리-구조)
8. [시뮬레이션 실행 방법](#-시뮬레이션-실행-방법)
9. [검증 결과](#-검증-결과)
10. [기술 스택](#-기술-스택)

---

<br>

## 🔍 프로젝트 개요

### 배경 및 목표

| 항목 | 내용 |
|------|------|
| **대상 플랫폼** | Xilinx Zynq-7000 (ARM Cortex-A9 + Programmable Logic) |
| **인터페이스** | AXI4-Lite Slave (CPU Side) ↔ SPI Master (Device Side) |
| **데이터 폭** | AXI: 32-bit / SPI: 8-bit |
| **SPI 지원 모드** | Mode 0 (CPOL=0, CPHA=0) ~ Mode 3 (CPOL=1, CPHA=1) |
| **검증 방법론** | UVM (Universal Verification Methodology) 1.2 |
| **시뮬레이터** | Synopsys VCS |
| **파형 분석** | Synopsys Verdi (FSDB) |

### 핵심 구현 포인트

- **AXI4-Lite Slave 컨트롤러** : Vivado IP Packager 규격에 맞는 메모리 맵 레지스터 설계
- **SPI Master FSM** : CPOL/CPHA 파라미터를 런타임에 설정 가능한 4-상태 FSM
- **UVM 계층 구조** : Agent / Sequencer / Driver / Monitor / Scoreboard / Coverage 전 계층 구현
- **자동 검증** : 1,000회 반복 랜덤 시나리오 + Pass/Fail 자동 판정 스코어보드
- **HAL 드라이버** : 추상화 계층(HAL)을 갖춘 재사용 가능한 임베디드 C 드라이버

---

<br>

## 🏗️ 시스템 아키텍처

```
  ┌─────────────────────────────────────────────────────────────────┐
  │                     Zynq-7000 SoC                               │
  │                                                                 │
  │  ┌──────────────┐    AXI4-Lite     ┌───────────────────────┐   │
  │  │  ARM          │ ──────────────► │  SPI_Master_v1_0      │   │
  │  │  Cortex-A9   │                 │  (Custom AXI IP)       │   │
  │  │              │ ◄────────────── │                        │   │
  │  │  [C Driver]  │    Read/Status  │  ┌─────────────────┐  │   │
  │  └──────────────┘                 │  │ S00_AXI (Slave) │  │   │
  │                                   │  │  slv_reg0: CTRL │  │   │
  │                                   │  │  slv_reg1: TX   │  │   │
  │                                   │  │  [addr 0x8]:    │  │   │
  │                                   │  │  STATUS+RX      │  │   │
  │                                   │  └────────┬────────┘  │   │
  │                                   │           │ internal  │   │
  │                                   │  ┌────────▼────────┐  │   │
  │                                   │  │   spi_master    │  │   │
  │                                   │  │   (FSM Core)    │  │   │
  │                                   │  └────────┬────────┘  │   │
  │                                   └───────────┼───────────┘   │
  │                                               │ Physical Pins  │
  └───────────────────────────────────────────────┼───────────────┘
                                                  │
                             ┌────────────────────┼─────────────┐
                             │  SPI Bus            │             │
                             │  SCLK ◄─────────────┘            │
                             │  MOSI ◄──────────────────────    │
                             │  MISO ──────────────────────►    │
                             │  CS_N ◄──────────────────────    │
                             │                  SPI Slave       │
                             │               (Sensor/EEPROM)    │
                             └──────────────────────────────────┘
```

<br>

### AXI-SPI 데이터 흐름 (Write Path)

```
CPU                AXI4-Lite               AXI Slave            SPI Core
 │                                                                   │
 │── WRITE 0x04 ──►│                                                 │
 │   data[31]=1    │── awvalid/wvalid ──►│                          │
 │   data[7:0]=TX  │◄── awready/wready ──│                          │
 │                 │                     │── start=1 ──────────────►│
 │                 │                     │   tx_data=TX             │
 │                 │                     │                          │── CS_N↓
 │                 │                     │                          │── 8 SCLK
 │── POLL 0x08 ───►│                     │                          │── MOSI
 │◄── busy[9]=0 ───│◄── rx_data ─────────│◄──── done=1 ─────────────│
 │                 │   done[8]=1         │      rx_data             │
```

---

<br>

## 📋 레지스터 맵

**Base Address**: `0x44A00000` (SPI) / `0x44A30000` (I2C)

| Offset | 이름 | 접근 | 비트 | 설명 |
|--------|------|------|------|------|
| `0x00` | CTRL | R/W | [0] CPOL | SPI Clock Polarity |
| | | | [1] CPHA | SPI Clock Phase |
| | | | [15:8] CLK_DIV | SPI Clock Divider (100MHz / (CLK_DIV+1)) |
| `0x04` | TX_DATA | R/W | [7:0] TX_DATA | 송신할 8비트 데이터 |
| | | | [31] START | `1` 쓰면 SPI 전송 개시 (자동 클리어) |
| `0x08` | STATUS_RX | **R only** | [7:0] RX_DATA | 수신된 8비트 데이터 |
| | | | [8] DONE | 전송 완료 플래그 (1클럭 펄스) |
| | | | [9] BUSY | 전송 진행 중 플래그 |

> ⚠️ **설계 포인트**: `slv_reg2 (0x08)`는 쓰기 로직에서 제외하고, 읽기 시 하드웨어 신호를 즉석 조합(`{22'd0, busy, done, rx_data}`)하여 반환합니다. 별도 레지스터 없이 실시간 상태를 반영합니다.

---

<br>

## ⚙️ RTL 설계 상세

### 모듈 계층 구조

```
SPI_Master_v1_0          ← Top-level AXI IP Wrapper
├── SPI_Master_v1_0_S00_AXI   ← AXI4-Lite Slave 컨트롤러
│   ├── slv_reg0 (CTRL)        ← CPOL, CPHA, CLK_DIV 저장
│   ├── slv_reg1 (TX + START)  ← TX 데이터, START 비트
│   └── read mux (0x08)        ← busy/done/rx_data 실시간 조합
└── spi_master               ← SPI 프로토콜 FSM 코어
    ├── Clock Divider Block    ← half_tick 생성
    └── FSM Block              ← IDLE→START→DATA→STOP
```

### SPI Master FSM 상태 다이어그램

```
         reset
           │
           ▼
    ┌──────────────┐   start=1    ┌──────────────┐
    │     IDLE     │ ────────────►│    START     │
    │  cs_n=1      │              │  cs_n=0      │
    │  sclk=cpol   │              │  load MOSI   │
    └──────────────┘              └──────┬───────┘
           ▲                             │ next cycle
           │                             ▼
    ┌──────────────┐  bit_cnt==7  ┌──────────────┐
    │     STOP     │ ◄────────────│     DATA     │
    │  cs_n=1      │              │  shift 8bit  │
    │  done=1      │              │  half_tick   │
    │  busy=0      │              │  MOSI/MISO   │
    └──────────────┘              └──────────────┘
```

### CPOL/CPHA 지원

| 모드 | CPOL | CPHA | SCLK 유휴 상태 | 데이터 샘플링 |
|------|------|------|---------------|--------------|
| Mode 0 | 0 | 0 | LOW | Rising Edge |
| Mode 1 | 0 | 1 | LOW | Falling Edge |
| Mode 2 | 1 | 0 | HIGH | Falling Edge |
| Mode 3 | 1 | 1 | HIGH | Rising Edge |

```verilog
// CPHA=0: START 상태에서 첫 비트 선행 출력
START: begin
    if (!cpha) begin
        mosi <= tx_shift_reg[7];          // 첫 비트 미리 출력
        tx_shift_reg <= {tx_shift_reg[6:0], 1'b0};
    end
    state <= DATA;
end

// 클럭 분주: clk_div+1 사이클마다 half_tick 1회 발생
// → SPI SCLK 주파수 = 100MHz / (2 × (clk_div+1))
```

### 핵심 설계 결정 (Design Decisions)

**① START 비트 자동 클리어**

```verilog
// SPI_Master_v1_0_S00_AXI.v
// slv_reg_wren이 아닐 때 (= 쓰기가 없는 평상시) START 비트를 클리어
end else begin
    slv_reg1[31] <= 1'b0;  // START 비트 자동 리셋
end
```
→ 소프트웨어가 별도로 클리어하지 않아도 되므로, 단순히 `TX_DATA = (1<<31) | data` 한 번으로 SPI 전송이 시작됩니다.

**② slv_reg2 제거 (읽기 전용 동적 조합)**

```verilog
// 읽기 mux에서 하드웨어 신호를 즉석 조합
2'h2 : reg_data_out <= {22'd0, busy, done, rx_data};
```
→ 레지스터 1개 절약, SPI 완료 직후 즉시 상태 반영 가능 (레지스터 지연 없음).

---

<br>

## 🧪 UVM 검증 환경

### 검증 아키텍처

```
┌─────────────────────────────────────────────────────────┐
│                    UVM Test Layer                        │
│                  axi2spi_test                           │
│         (axi_random_loop_seq × 1000 iterations)        │
└───────────────────────┬─────────────────────────────────┘
                        │
┌───────────────────────▼─────────────────────────────────┐
│                    UVM Env Layer                         │
│                   axi2spi_env                           │
│                                                         │
│  ┌─────────────────┐      ┌──────────────────────────┐  │
│  │   axi_agent     │      │      spi_agent           │  │
│  │  (ACTIVE)       │      │     (ACTIVE)             │  │
│  │                 │      │                          │  │
│  │  ┌───────────┐  │      │  ┌────────────────────┐  │  │
│  │  │axi_driver │  │      │  │    spi_driver       │  │  │
│  │  │           │  │      │  │  (MISO 자동 응답)   │  │  │
│  │  │ drive_write│  │      │  └────────────────────┘  │  │
│  │  │ drive_read │  │      │  ┌────────────────────┐  │  │
│  │  └───────────┘  │      │  │    spi_monitor     │  │  │
│  │  ┌───────────┐  │      │  │  (MOSI/MISO 캡처)  │  │  │
│  │  │axi_monitor│  │      │  └────────────────────┘  │  │
│  │  │           │  │      └──────────────────────────┘  │
│  │  └─────┬─────┘  │                    │               │
│  └────────┼────────┘                    │               │
│           │ ap.write()                  │ ap.write()    │
│           ▼                             ▼               │
│  ┌─────────────────────────────────────────────────┐   │
│  │              axi2spi_scoreboard                  │   │
│  │                                                  │   │
│  │  AXI WRITE check: axi.data[7:0] == spi.mosi     │   │
│  │  AXI READ check:  axi.rdata[7:0] == spi.miso    │   │
│  │                                                  │   │
│  │  pass_cnt / fail_cnt 자동 집계                   │   │
│  └─────────────────────────────────────────────────┘   │
│  ┌─────────────────────────────────────────────────┐   │
│  │              axi2spi_coverage                    │   │
│  │  cp_tx_data: 0x00, 0xFF, 0x55, 0xAA, low, high  │   │
│  │  cp_rx_data: 0x00, 0xFF, 0x55, 0xAA, low, high  │   │
│  │  cross_tx_rx: TX × RX 크로스 커버리지            │   │
│  └─────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────┘
```

### 시퀀스 라이브러리

| 시퀀스 | 용도 |
|--------|------|
| `axi_write_seq` | 단일 AXI Write 트랜잭션 |
| `axi_read_seq` | 단일 AXI Read 트랜잭션 |
| `axi_write_read_seq` | Write 후 Read 확인 (기본 E2E) |
| `axi_random_loop_seq` | 1,000회 랜덤 데이터 Write→Polling→Read |
| `spi_dummy_seq` | SPI 슬레이브 역할 (랜덤 MISO 응답) |

### 스코어보드 검증 로직

```systemverilog
// AXI WRITE 검증: CPU가 보낸 TX 데이터 == SPI MOSI 핀에 나온 데이터
if (a_item.data[7:0] == s_item.mosi_data) begin
    pass_cnt++;
    `uvm_info("SCB", $sformatf("[PASS] WRITE: AXI(0x%0h) == SPI_MOSI(0x%0h)",
        a_item.data[7:0], s_item.mosi_data), UVM_NONE)
end

// AXI READ 검증: CPU가 읽은 RX 데이터 == SPI가 MISO로 쏜 데이터
if (a_item.rdata[7:0] == expected_rdata) begin
    pass_cnt++;
    `uvm_info("SCB", $sformatf("[PASS] READ : AXI_RX(0x%0h) == Expected_MISO(0x%0h)",
        a_item.rdata[7:0], expected_rdata), UVM_NONE)
end
```

### 커버리지 계획

```systemverilog
covergroup cg_axi2spi;
    cp_tx_data: coverpoint cov_tx_data {
        bins zero   = {8'h00};   // 경계값
        bins max    = {8'hFF};   // 경계값
        bins alt_55 = {8'h55};   // 체크보드 패턴
        bins alt_AA = {8'hAA};   // 체크보드 반전
        bins low_rng  = {[8'h01:8'h7F]};  // 일반 저범위
        bins high_rng = {[8'h80:8'hFE]};  // 일반 고범위
    }
    cp_rx_data: coverpoint cov_rx_data { /* 동일 구조 */ }
    cross_tx_rx: cross cp_tx_data, cp_rx_data;  // 6×6 = 36 교차점
endgroup
```

---

<br>

## 🖥️ 임베디드 C 드라이버

### HAL 계층 구조

```
Application Layer (spi_ap.c / i2c_ap.c)
    │  버튼 이벤트 감지, FND 표시
    ▼
HAL Layer (SPI.c / I2C.c)
    │  SPI_Init(), SPI_Transfer()
    │  I2C_SendCmd(), I2C_GetRxData()
    ▼
Driver Layer (GPIO.c, Button.c, FND.c, Switch.c)
    │  GPIO_SetMode(), GPIO_WritePin()
    ▼
Hardware (Memory-Mapped Registers @ 0x44A00000~)
```

### SPI HAL 구조체 매핑

```c
// SPI.h - 하드웨어 레지스터 직접 매핑
typedef struct {
    volatile uint32_t CTRL;      // 0x00: CPOL[0], CPHA[1], CLK_DIV[15:8]
    volatile uint32_t TX_DATA;   // 0x04: START[31], TX_DATA[7:0]
    volatile uint32_t STATUS_RX; // 0x08: BUSY[9], DONE[8], RX_DATA[7:0]
} SPI_Typedef_t;

#define SPI_BASE_ADDR 0x44A00000
#define SPI_PORT ((SPI_Typedef_t *) SPI_BASE_ADDR)
```

### SPI Transfer 구현

```c
uint8_t SPI_Transfer(uint8_t tx_data) {
    // 1. START 비트(bit31)와 TX 데이터를 한 번에 쓰기
    SPI_PORT->TX_DATA = (1U << 31) | tx_data;
    SPI_PORT->TX_DATA = tx_data;  // START 비트 즉시 해제

    // 2. busy 비트 폴링 (bit9)
    while ((SPI_PORT->STATUS_RX & (1 << 9)) != 0);

    // 3. 수신 데이터 반환
    return (uint8_t)(SPI_PORT->STATUS_RX & 0xFF);
}
```

### I2C HAL 구조체 매핑

```c
// I2C.h
typedef struct {
    volatile uint32_t CTRL;    // 0x00: start[0], write[1], read[2], stop[3], ack_in[4]
    volatile uint32_t TX_DATA; // 0x04: tx_data[7:0]
    volatile uint32_t STATUS;  // 0x08: busy[0], done[1], ack_out[2]
    volatile uint32_t RX_DATA; // 0x0C: rx_data[7:0]
} I2C_Typedef_t;
```

### 사용 예시 (Application Layer)

```c
// SPI: 버튼 눌리면 스위치 값 전송 → 수신값 FND 표시
void Spi_Ap_Run() {
    if (Button_GetState(&hbtnStart) == ACT_PUSHED) {
        uint8_t sw_data = Switch_GetState();
        uint8_t rx_data = SPI_Transfer(sw_data);  // 단 한 줄로 송수신 완료
        FND_SetNum(rx_data);
    }
    FND_DispDigit();
    delay_ms(1);
}

// I2C: 버튼별로 Start / Write / Read / Stop 수동 제어
void I2c_Ap_Run() {
    if (Button_GetState(&hbtnStart) == ACT_PUSHED)
        I2C_SendCmd(1, 0, 0, 0, 0);   // START condition
    if (Button_GetState(&hbtnWrite) == ACT_PUSHED) {
        I2C_SetTxData(Switch_GetState());
        I2C_SendCmd(0, 1, 0, 0, 0);   // WRITE
    }
    if (Button_GetState(&hbtnRead) == ACT_PUSHED) {
        I2C_SendCmd(0, 0, 1, 0, 1);   // READ + NACK
        current_rx_data = I2C_GetRxData();
    }
    if (Button_GetState(&hbtnStop) == ACT_PUSHED)
        I2C_SendCmd(0, 0, 0, 1, 0);   // STOP condition
}
```

---

<br>

## 📁 디렉토리 구조

```
.
├── rtl/
│   ├── SPI_Master_v1_0.v            # Top-level AXI IP + SPI FSM 코어
│   ├── SPI_Master_v1_0_S00_AXI.v   # AXI4-Lite Slave 컨트롤러
│   ├── I2C_Master_v1_0.v            # I2C Master IP
│   └── I2C_Master_v1_0_S00_AXI.v   # I2C AXI4-Lite 컨트롤러
│
├── tb/
│   ├── tb_axi4_spi.sv               # Top Testbench (DUT 인스턴스, 클럭/리셋)
│   ├── axi_if.sv                    # AXI4-Lite 인터페이스
│   ├── spi_if.sv                    # SPI 인터페이스
│   ├── test_pkg.sv                  # 테스트 패키지 (모든 시퀀스/테스트 조립)
│   ├── axi2spi_test.sv              # UVM Test (최상위 테스트 클래스)
│   │
│   ├── agents/
│   │   ├── axi_agent/
│   │   │   ├── axi_agent_pkg.sv     # AXI 에이전트 패키지
│   │   │   ├── axi_seq_item.sv      # AXI 트랜잭션 (제약: addr, data 랜덤화)
│   │   │   ├── axi_sequencer.sv     # AXI 시퀀서
│   │   │   ├── axi_driver.sv        # AXI 드라이버 (drive_write / drive_read)
│   │   │   ├── axi_monitor.sv       # AXI 모니터 (Write/Read 트랜잭션 캡처)
│   │   │   └── axi_agent.sv         # AXI 에이전트 (ACTIVE 모드)
│   │   └── spi_agent/
│   │       ├── spi_agent_pkg.sv     # SPI 에이전트 패키지
│   │       ├── spi_seq_item.sv      # SPI 트랜잭션 (MISO 랜덤화)
│   │       ├── spi_sequencer.sv     # SPI 시퀀서
│   │       ├── spi_driver.sv        # SPI 드라이버 (슬레이브 MISO 응답)
│   │       ├── spi_monitor.sv       # SPI 모니터 (MOSI/MISO 캡처)
│   │       └── spi_agent.sv         # SPI 에이전트
│   │
│   ├── env/
│   │   ├── env_pkg.sv               # 환경 패키지
│   │   ├── axi2spi_env.sv           # UVM Env (에이전트 + 스코어보드 연결)
│   │   ├── axi2spi_scoreboard.sv    # 스코어보드 (Pass/Fail 자동 판정)
│   │   └── axi2spi_coverage.sv      # 커버리지 (TX/RX 크로스 커버리지)
│   │
│   └── sequences/
│       ├── axi_write_seq.sv         # 단일 Write
│       ├── axi_read_seq.sv          # 단일 Read
│       ├── axi_write_read_seq.sv    # Write → Read E2E
│       ├── axi_random_loop_seq.sv   # 1000회 랜덤 반복
│       └── spi_dummy_seq.sv         # SPI 슬레이브 시뮬레이션
│
├── sw/
│   ├── HAL/
│   │   ├── SPI/
│   │   │   ├── SPI.h               # SPI HAL 헤더 (레지스터 맵 구조체)
│   │   │   └── SPI.c               # SPI_Init, SPI_Transfer 구현
│   │   ├── I2C/
│   │   │   ├── I2C.h               # I2C HAL 헤더
│   │   │   └── I2C.c               # I2C_SendCmd, I2C_GetRxData 구현
│   │   └── GPIO/
│   │       ├── GPIO.h              # GPIO HAL 헤더 (포트/핀 정의)
│   │       └── GPIO.c              # GPIO 드라이버 구현
│   ├── driver/
│   │   ├── Button/                 # 버튼 디바운싱 드라이버
│   │   ├── Switch/                 # DIP 스위치 드라이버
│   │   └── FND/                    # 7-Segment FND 멀티플렉싱 드라이버
│   ├── ap/
│   │   ├── spi_ap/                 # SPI 애플리케이션
│   │   └── i2c_ap/                 # I2C 애플리케이션
│   └── main.c
│
├── filelist.f                       # VCS 컴파일 파일 목록
└── Makefile                         # 빌드 자동화
```

---

<br>

## 🚀 시뮬레이션 실행 방법

### 사전 요구 사항

- Synopsys VCS (UVM 1.2 포함)
- Synopsys Verdi (파형 뷰어, 선택)

### 빌드 및 시뮬레이션

```bash
# 컴파일 + 시뮬레이션 (기본)
make sim

# 컴파일만
make compile

# 파형 뷰어 포함 실행 (Verdi)
make verdi

# FSDB 파형만 확인
make vw

# 커버리지 리포트 확인
make vc

# 정리
make clean
```

### 시뮬레이션 옵션 커스터마이징

```bash
# 특정 시드로 재현
make sim SEED=42

# 특정 테스트 실행
make sim TC=axi2spi_test

# 상세 로그
# Makefile 내 SIM_OPTS에서 UVM_VERBOSITY=UVM_HIGH 설정됨
```

### 예상 출력 (시뮬레이션 종료 시)

```
UVM_INFO SCB: [PASS] WRITE: AXI(0xa5) == SPI_MOSI(0xa5)
UVM_INFO SCB: [PASS] READ : AXI_RX(0x3c) == Expected_MISO(0x3c)
...
UVM_INFO SCB: =======================================
UVM_INFO SCB: ===== AXI2SPI Scoreboard Summary =====
UVM_INFO SCB:   Total checks : 2000
UVM_INFO SCB:   Pass         : 2000
UVM_INFO SCB:   Fail         : 0
UVM_INFO SCB: =======================================
UVM_INFO SCB: TEST PASSED!

UVM_INFO COV: =======================================
UVM_INFO COV: ===== AXI2SPI Coverage Summary   =====
UVM_INFO COV:   Overall Coverage   : 97.2%
UVM_INFO COV:   TX Data Coverage   : 100.0%
UVM_INFO COV:   RX Data Coverage   : 100.0%
UVM_INFO COV:   Cross (TX x RX)    : 94.4%
UVM_INFO COV: =======================================
```

---

<br>

## 📊 검증 결과

| 검증 항목 | 내용 | 결과 |
|-----------|------|------|
| **AXI Write → SPI MOSI** | CPU가 쓴 데이터가 MOSI 핀으로 정확히 출력 | ✅ Pass |
| **SPI MISO → AXI Read** | MISO로 수신한 데이터가 STATUS_RX 레지스터에 정확히 저장 | ✅ Pass |
| **Busy 폴링** | 전송 중 busy=1, 완료 후 busy=0 타이밍 | ✅ Pass |
| **START 비트 자동 클리어** | 쓰기 완료 후 1클럭 내 START=0 | ✅ Pass |
| **랜덤 1,000회 반복** | 완전 랜덤 데이터 1,000회 E2E 검증 | ✅ 2000 checks / 0 fail |
| **TX 커버리지** | 0x00, 0xFF, 0x55, 0xAA, 저범위, 고범위 | ✅ 100% |
| **RX 커버리지** | 0x00, 0xFF, 0x55, 0xAA, 저범위, 고범위 | ✅ 100% |
| **TX×RX 크로스** | 36개 교차 버킷 달성률 | ✅ ~94% |

### 커버리지 측정 도구

```bash
# VCS 코드 커버리지 (line, cond, fsm, toggle, branch)
-cm line+cond+fsm+tgl+branch+assert
-cm_dir coverage.vdb

# Verdi에서 커버리지 시각화
verdi -cov -covdir coverage.vdb
```

---

<br>

## 🛠️ 기술 스택

| 분류 | 기술 |
|------|------|
| **하드웨어 설계** | Verilog HDL, AXI4-Lite, SPI Protocol, FSM |
| **검증 방법론** | UVM 1.2 (SystemVerilog) |
| **EDA 툴** | Synopsys VCS, Synopsys Verdi |
| **커버리지** | Functional Coverage (SystemVerilog Covergroup), Code Coverage |
| **임베디드 S/W** | C (Bare-metal), Memory-Mapped I/O, HAL 계층 설계 |
| **플랫폼** | Xilinx Zynq-7000, Vivado IP Packager |
| **빌드** | Makefile, VCS filelist |

---

<br>

## 🔑 배운 점 / 핵심 인사이트

1. **AXI4-Lite 핸드쉐이킹**: `awvalid + wvalid → awready + wready` 동시 조건 처리의 타이밍 이슈 디버깅 경험

2. **UVM TLM FIFO 활용**: AXI(100MHz)와 SPI(느린 주파수)의 속도 차이를 `uvm_tlm_analysis_fifo`로 비동기 버퍼링하는 아키텍처 설계

3. **슬레이브 레지스터 최적화**: 읽기 전용 상태를 별도 레지스터로 저장하지 않고 조합 논리로 즉시 조합(`{22'd0, busy, done, rx_data}`)하는 설계로 하드웨어 비용 절감

4. **포크-조인 시뮬레이션**: AXI 마스터와 SPI 슬레이브를 `fork/join_none`으로 병렬 실행하여 실제 하드웨어 동작 재현

5. **HAL 추상화**: 레지스터 주소를 C 구조체로 매핑하여 포터블하고 가독성 높은 드라이버 설계

---

<br>

## 👤 작성자

**김민기**  
SoC 설계 / 검증 엔지니어 지망  
KCCS ISTC 교육과정 (2026.05)

---

*이 프로젝트는 FPGA 기반 SoC 주변장치 IP 설계 및 UVM 검증 역량을 종합적으로 보여주기 위해 작성되었습니다.*

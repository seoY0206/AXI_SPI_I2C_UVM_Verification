# 🎯 AXI_SPI_I2C_UVM 프로젝트 완벽 분석

## 목차
1. [프로젝트 핵심 요약](#1-프로젝트-핵심-요약)
2. [기술 개념 완벽 정리](#2-기술-개념-완벽-정리)
3. [시스템 설계 상세 설명](#3-시스템-설계-상세-설명)
4. [UVM 검증 환경 설명](#4-uvm-검증-환경-설명)
5. [Trouble Shooting 상세 분석](#5-trouble-shooting-상세-분석)
6. [면접 예상 질문 & 답변](#6-면접-예상-질문--답변)

---

# 1. 프로젝트 핵심 요약

## 1.1 프로젝트 한 줄 설명
**"SPI·I2C 통신 프로토콜을 SystemVerilog로 구현하고, UVM 방법론을 활용해 검증한 후, FPGA(Basys3) + MicroBlaze에서 실제 동작을 확인한 프로젝트"**

## 1.2 핵심 성과
- ✅ **SPI Mode 0~3** (CPOL/CPHA 조합) 모두 검증
- ✅ **UVM Scoreboard**를 통한 Golden/Actual 비교로 데이터 오류 즉시 검출
- ✅ **FPGA + MicroBlaze** 실제 하드웨어에서 동작 검증
- ✅ **AXI-Lite 버스**를 통한 I2C 제어 구현

## 1.3 사용 기술 스택
| 분류 | 기술 |
|------|------|
| **설계 언어** | SystemVerilog, Verilog |
| **검증 방법론** | UVM (Universal Verification Methodology) |
| **시뮬레이션** | VCS (Synopsys), Vivado Simulator |
| **하드웨어** | Basys3 FPGA (Xilinx Artix-7) |
| **프로세서** | MicroBlaze (Soft Processor) |
| **버스 프로토콜** | AXI4-Lite |
| **통신 프로토콜** | SPI (Serial Peripheral Interface), I2C (Inter-Integrated Circuit) |

---

# 2. 기술 개념 완벽 정리

## 2.1 SPI (Serial Peripheral Interface)

### 📌 SPI란?
- **동기식(Synchronous) 직렬 통신 프로토콜**
- **Full-Duplex** 통신 (동시 송수신 가능)
- **Master-Slave 구조** (1 Master, 다수 Slave 가능)

### 📌 SPI 신호선
```
Master                           Slave
  │                                │
  ├── SCLK (Serial Clock) ────────▶│  클럭 신호 (Master가 생성)
  │                                │
  ├── MOSI (Master Out Slave In) ─▶│  Master → Slave 데이터
  │                                │
  ├── MISO (Master In Slave Out) ◀─┤  Slave → Master 데이터
  │                                │
  └── SS/CS (Slave Select) ───────▶│  Slave 선택 신호 (Active Low)
```

### 📌 SPI 모드 (CPOL & CPHA)

| Mode | CPOL | CPHA | Clock Polarity | Data Sampling |
|------|------|------|----------------|---------------|
| **0** | 0 | 0 | Idle: Low | Rising Edge (1st edge) |
| **1** | 0 | 1 | Idle: Low | Falling Edge (2nd edge) |
| **2** | 1 | 0 | Idle: High | Falling Edge (1st edge) |
| **3** | 1 | 1 | Idle: High | Rising Edge (2nd edge) |

**CPOL (Clock Polarity)**: 클럭의 Idle 상태
- 0: Idle 시 Low
- 1: Idle 시 High

**CPHA (Clock Phase)**: 데이터 샘플링 시점
- 0: 첫 번째 클럭 에지에서 샘플링
- 1: 두 번째 클럭 에지에서 샘플링

### 📌 SPI 타이밍 다이어그램 (Mode 0 예시)
```
SCLK:  ───┐   ┌───┐   ┌───┐   ┌───┐   ┌───
          └───┘   └───┘   └───┘   └───┘

MOSI:  ──────X─────X─────X─────X─────X────
           D7     D6     D5     D4     D3
                ↑       ↑       ↑       ↑
              Sample  Sample  Sample  Sample

SS:    ──────┐                           ┌───
             └───────────────────────────┘
             (Active Low)
```

### 📌 SPI 장단점
**장점:**
- 고속 통신 (최대 수십 MHz)
- Full-Duplex (동시 송수신)
- 간단한 하드웨어 구조

**단점:**
- 신호선이 많음 (4개 이상)
- Multi-Master 지원 어려움
- 표준화된 프로토콜 없음

---

## 2.2 I2C (Inter-Integrated Circuit)

### 📌 I2C란?
- **동기식 직렬 통신 프로토콜**
- **Half-Duplex** 통신 (송신/수신 교대)
- **Multi-Master, Multi-Slave** 지원
- **2선식** (SDA, SCL)

### 📌 I2C 신호선
```
Master/Slave              Master/Slave
     │                         │
     ├── SDA (Data) ───────────┤  데이터 전송
     │    (Open-Drain)         │
     │                         │
     └── SCL (Clock) ──────────┤  클럭 신호
          (Master 생성)        │
```

### 📌 I2C 주소 지정
- **7-bit 주소** (0x00 ~ 0x7F)
- **10-bit 주소** (확장 모드)
- **Read/Write bit** (LSB)
  - 0: Write
  - 1: Read

### 📌 I2C 통신 절차
```
1. START 조건
   Master가 SDA를 High→Low (SCL이 High일 때)

2. Address 전송
   [7-bit Address][R/W bit]

3. ACK/NACK
   Slave가 SDA를 Low로 당김 (ACK)
   또는 High 유지 (NACK)

4. Data 전송
   8-bit 데이터 전송

5. ACK/NACK
   수신 측이 ACK/NACK 전송

6. STOP 조건
   Master가 SDA를 Low→High (SCL이 High일 때)
```

### 📌 I2C 타이밍 다이어그램
```
SDA:  ───┐           ┌─┐ ┌─┐     ┌─┐     ┌─────
         └───────────┘ └─┘ └─────┘ └─────┘
         START    A6 A5 A4  ...  R/W ACK  D7...
                 
SCL:  ──────┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐
            └─┘ └─┘ └─┘ └─┘ └─┘ └─┘ └─┘ └─
```

### 📌 I2C 레지스터 구조 (본 프로젝트)
| 레지스터 | 기능 |
|---------|------|
| **CR (Control Register)** | I2C 제어 (Enable, Start, Stop) |
| **ODR (Output Data Register)** | 송신 데이터 |
| **IDR (Input Data Register)** | 수신 데이터 |
| **STR (Status Register)** | 통신 상태 (Busy, ACK/NACK) |

### 📌 I2C 장단점
**장점:**
- 신호선 2개만 필요
- Multi-Master 지원
- 주소 지정으로 다수 디바이스 연결

**단점:**
- Half-Duplex (송수신 교대)
- SPI보다 속도 느림 (최대 3.4 Mbps)
- Pull-up 저항 필요

---

## 2.3 AXI4-Lite 프로토콜

### 📌 AXI4-Lite란?
- **AMBA (Advanced Microcontroller Bus Architecture)** 계열
- **간단한 메모리 맵 인터페이스**
- **레지스터 접근**에 최적화
- **5개의 독립적인 채널**

### 📌 AXI4-Lite 채널 구조
```
Master                        Slave
  │                            │
  ├── Write Address (AW) ─────▶│  쓰기 주소 전송
  │                            │
  ├── Write Data (W) ─────────▶│  쓰기 데이터 전송
  │                            │
  ├── Write Response (B) ◀─────┤  쓰기 응답
  │                            │
  ├── Read Address (AR) ──────▶│  읽기 주소 전송
  │                            │
  └── Read Data (R) ◀──────────┤  읽기 데이터 + 응답
```

### 📌 AXI4-Lite 신호
**Write Address Channel (AW)**
- AWADDR: 쓰기 주소
- AWVALID: 주소 유효 신호
- AWREADY: Slave 준비 신호

**Write Data Channel (W)**
- WDATA: 쓰기 데이터
- WSTRB: Byte Strobe (어느 바이트 쓸지)
- WVALID: 데이터 유효 신호
- WREADY: Slave 준비 신호

**Write Response Channel (B)**
- BRESP: 응답 (OKAY, SLVERR 등)
- BVALID: 응답 유효 신호
- BREADY: Master 준비 신호

**Read Address Channel (AR)**
- ARADDR: 읽기 주소
- ARVALID: 주소 유효 신호
- ARREADY: Slave 준비 신호

**Read Data Channel (R)**
- RDATA: 읽기 데이터
- RRESP: 응답
- RVALID: 데이터 유효 신호
- RREADY: Master 준비 신호

### 📌 AXI4-Lite Handshake
```
VALID와 READY가 모두 High일 때 전송 성공

Master    ───VALID───▶    Slave
Slave     ◀──READY────    Master

전송 성공: VALID=1 & READY=1 일 때
```

### 📌 본 프로젝트에서의 역할
```
MicroBlaze (Master)
        │
        ▼ (AXI4-Lite)
   I2C Master IP
        │
        ▼ (I2C)
    I2C Slave (LED)
```

MicroBlaze가 **AXI4-Lite 버스**를 통해 **I2C Master의 레지스터**를 제어
→ I2C Master가 **I2C 프로토콜**로 LED 제어

---

## 2.4 UVM (Universal Verification Methodology)

### 📌 UVM이란?
- **SystemVerilog 기반 검증 방법론**
- **재사용 가능한 검증 환경** 구축
- **표준화된 구조**로 대규모 프로젝트에 적합
- **Constrained Random Verification**

### 📌 UVM 계층 구조
```
┌─────────────────────────────────────┐
│          Test (uvm_test)             │  최상위 테스트 시나리오
└───────────────┬─────────────────────┘
                │
┌───────────────▼─────────────────────┐
│      Environment (uvm_env)           │  전체 검증 환경
│  ┌─────────┐         ┌──────────┐   │
│  │  Agent  │         │Scoreboard│   │
│  └────┬────┘         └──────────┘   │
└───────┼──────────────────────────────┘
        │
┌───────▼──────────────────────────────┐
│         Agent (uvm_agent)             │
│  ┌──────────┐  ┌────────┐  ┌───────┐│
│  │Sequencer │  │ Driver │  │Monitor││
│  └──────────┘  └────────┘  └───────┘│
└───────────────────────────────────────┘
        │              │           │
        ▼              ▼           ▼
   Sequence        DUT Interface   Analysis
```

### 📌 UVM 주요 컴포넌트

#### 1. Sequence (uvm_sequence)
- **테스트 시나리오** 정의
- **Transaction 생성**
- **Constrained Random** 데이터 생성

```systemverilog
class spi_sequence extends uvm_sequence #(spi_transaction);
  `uvm_object_utils(spi_sequence)
  
  virtual task body();
    spi_transaction tx;
    repeat(100) begin
      tx = spi_transaction::type_id::create("tx");
      start_item(tx);
      assert(tx.randomize());  // Constrained Random
      finish_item(tx);
    end
  endtask
endclass
```

#### 2. Sequencer (uvm_sequencer)
- **Sequence와 Driver 연결**
- **Transaction 중재**

#### 3. Driver (uvm_driver)
- **Transaction을 DUT 신호로 변환**
- **핀 레벨 구동**

```systemverilog
class spi_driver extends uvm_driver #(spi_transaction);
  virtual spi_if vif;
  
  task run_phase(uvm_phase phase);
    forever begin
      seq_item_port.get_next_item(req);  // Sequence에서 받기
      drive_transaction(req);             // DUT 구동
      seq_item_port.item_done();          // 완료 알림
    end
  endtask
  
  task drive_transaction(spi_transaction tx);
    // SCLK, MOSI, SS 신호 구동
  endtask
endclass
```

#### 4. Monitor (uvm_monitor)
- **DUT 출력 관찰**
- **Transaction 수집**
- **Coverage 측정**

```systemverilog
class spi_monitor extends uvm_monitor;
  virtual spi_if vif;
  uvm_analysis_port #(spi_transaction) ap;
  
  task run_phase(uvm_phase phase);
    forever begin
      spi_transaction tx;
      collect_transaction(tx);  // MISO에서 수집
      ap.write(tx);              // Scoreboard로 전송
    end
  endtask
endclass
```

#### 5. Scoreboard (uvm_scoreboard)
- **Golden Model과 DUT 비교**
- **Pass/Fail 판정**

```systemverilog
class spi_scoreboard extends uvm_scoreboard;
  uvm_analysis_imp #(spi_transaction, spi_scoreboard) analysis_export;
  
  function void write(spi_transaction tx);
    spi_transaction golden = calculate_golden(tx);
    if (tx.data != golden.data) begin
      `uvm_error("SB", $sformatf("Mismatch! Expected: %h, Got: %h", 
                                  golden.data, tx.data))
    end else begin
      `uvm_info("SB", "Transaction PASS", UVM_MEDIUM)
    end
  endfunction
endclass
```

### 📌 UVM Phase
UVM은 **표준화된 실행 순서**를 제공

```
1. Build Phase       → 컴포넌트 생성
2. Connect Phase     → 연결 설정
3. End of Elaboration→ 연결 확인
4. Start of Simulation→ 시뮬 시작 전 초기화
5. Run Phase         → 실제 테스트 실행
   ├─ reset_phase
   ├─ configure_phase
   ├─ main_phase     ← 여기서 대부분의 테스트
   └─ shutdown_phase
6. Extract Phase     → 결과 수집
7. Check Phase       → 검증
8. Report Phase      → 리포트 생성
9. Final Phase       → 종료
```

### 📌 본 프로젝트 UVM 구조
```
spi_test (uvm_test)
    │
    └── spi_env (uvm_env)
            ├── spi_master_agent
            │       ├── spi_sequencer
            │       ├── spi_driver
            │       └── spi_monitor
            │
            ├── spi_slave_agent
            │       └── spi_monitor
            │
            └── spi_scoreboard
                    └── Golden Model (Expected Data)
```

---

# 3. 시스템 설계 상세 설명

## 3.1 전체 시스템 구조

```
┌──────────────────────────────────────────────────────┐
│                   PC (Test Control)                   │
│                                                        │
│  - VCS UVM Testbench                                  │
│  - MicroBlaze C Code                                  │
└───────────────────┬──────────────────────────────────┘
                    │
                    ▼
┌──────────────────────────────────────────────────────┐
│              FPGA (Basys3 - Artix-7)                  │
│  ┌────────────────────────────────────────────────┐  │
│  │          MicroBlaze (Soft CPU)                 │  │
│  │                                                 │  │
│  │  C Code로 I2C 레지스터 제어                    │  │
│  └───────────────┬─────────────────────────────────┘  │
│                  │ AXI4-Lite Bus                      │
│  ┌───────────────▼─────────────────────────────────┐  │
│  │           I2C Master IP                         │  │
│  │  ┌─────────────────────────────────┐           │  │
│  │  │ CR  │ ODR │ IDR │ STR │         │           │  │
│  │  └─────────────────────────────────┘           │  │
│  └───────────────┬─────────────────────────────────┘  │
│                  │ I2C (SCL, SDA)                     │
│  ┌───────────────▼─────────────────────────────────┐  │
│  │           I2C Slave (LED Controller)            │  │
│  └─────────────────────────────────────────────────┘  │
│                                                        │
│  ┌──────────────────────────────────────────────────┐ │
│  │           SPI Master                             │ │
│  │  (SCLK, MOSI, MISO, SS)                         │ │
│  └───────────────┬──────────────────────────────────┘ │
│                  │                                     │
│  ┌───────────────▼──────────────────────────────────┐ │
│  │           SPI Slave                              │ │
│  └──────────────────────────────────────────────────┘ │
└──────────────────────────────────────────────────────┘
```

## 3.2 SPI Master 설계

### 📌 주요 기능
1. **Mode 설정**: CPOL, CPHA 설정
2. **데이터 전송**: 8-bit 직렬 송수신
3. **Slave Select**: 여러 Slave 선택 가능
4. **클럭 생성**: SCLK 생성 (Prescaler)

### 📌 상태 머신 (FSM)
```
     ┌──────┐
     │ IDLE │ ◀─────────────────┐
     └───┬──┘                   │
         │ start=1              │
         ▼                      │
     ┌──────┐                   │
     │ LOAD │  데이터 로드       │
     └───┬──┘                   │
         │                      │
         ▼                      │
     ┌──────┐                   │
     │TRANSFER│ 8-bit 전송       │
     └───┬──┘                   │
         │ done                 │
         ▼                      │
     ┌──────┐                   │
     │ DONE │ ──────────────────┘
     └──────┘
```

### 📌 핵심 로직 (의사 코드)
```systemverilog
always @(posedge clk) begin
  case (state)
    IDLE: if (start) state <= LOAD;
    
    LOAD: begin
      shift_reg <= tx_data;
      bit_cnt <= 0;
      state <= TRANSFER;
    end
    
    TRANSFER: begin
      if (sclk_edge) begin
        // MOSI 출력
        MOSI <= shift_reg[7];
        shift_reg <= {shift_reg[6:0], MISO};
        bit_cnt <= bit_cnt + 1;
        
        if (bit_cnt == 8) state <= DONE;
      end
    end
    
    DONE: begin
      rx_data <= shift_reg;
      done <= 1;
      state <= IDLE;
    end
  endcase
end
```

## 3.3 SPI Slave 설계

### 📌 주요 기능
1. **클럭 동기화**: Master의 SCLK에 동기화
2. **데이터 수신**: MOSI에서 데이터 수신
3. **데이터 송신**: MISO로 데이터 송신

### 📌 핵심 로직 (의사 코드)
```systemverilog
always @(posedge SCLK or posedge SS) begin
  if (SS) begin
    // Slave Select 비활성화
    shift_reg <= tx_data;
    bit_cnt <= 0;
  end else begin
    // 데이터 수신
    shift_reg <= {shift_reg[6:0], MOSI};
    MISO <= shift_reg[7];
    bit_cnt <= bit_cnt + 1;
    
    if (bit_cnt == 8) begin
      rx_data <= shift_reg;
      rx_valid <= 1;
    end
  end
end
```

## 3.4 I2C Master 설계

### 📌 레지스터 맵
| Offset | Register | Bits | Description |
|--------|----------|------|-------------|
| 0x00 | CR (Control) | [0] EN - Enable<br>[1] START<br>[2] STOP | I2C 제어 |
| 0x04 | ODR (Output Data) | [7:0] Data | 송신 데이터 |
| 0x08 | IDR (Input Data) | [7:0] Data | 수신 데이터 |
| 0x0C | STR (Status) | [0] BUSY<br>[1] ACK/NACK | 상태 |

### 📌 I2C 통신 절차 (코드)
```c
// MicroBlaze C Code
void i2c_write(uint8_t slave_addr, uint8_t data) {
  // 1. START 조건
  I2C_CR |= (1 << 1);  // START bit
  
  // 2. Slave Address 전송
  I2C_ODR = (slave_addr << 1) | 0;  // Write mode
  while (I2C_STR & 0x01);  // BUSY 대기
  
  // 3. ACK 확인
  if (I2C_STR & 0x02) {  // NACK
    // Error handling
  }
  
  // 4. Data 전송
  I2C_ODR = data;
  while (I2C_STR & 0x01);  // BUSY 대기
  
  // 5. STOP 조건
  I2C_CR |= (1 << 2);  // STOP bit
}
```

---

# 4. UVM 검증 환경 설명

## 4.1 검증 전략

### 📌 검증 목표
1. **모든 SPI Mode (0~3) 검증**
2. **다양한 데이터 패턴** 검증 (Random, Corner Case)
3. **Golden Model과 비교**하여 정확성 검증
4. **Coverage** 목표 달성

### 📌 Test Scenario
```systemverilog
// Test 1: All Mode Test
class spi_all_mode_test extends uvm_test;
  task run_phase(uvm_phase phase);
    spi_all_mode_seq seq;
    phase.raise_objection(this);
    
    // Mode 0, 1, 2, 3 각각 테스트
    foreach(mode in {0, 1, 2, 3}) begin
      seq = spi_all_mode_seq::type_id::create("seq");
      seq.mode = mode;
      seq.start(env.agent.sequencer);
    end
    
    phase.drop_objection(this);
  endtask
endclass

// Test 2: Random Data Test
class spi_random_test extends uvm_test;
  task run_phase(uvm_phase phase);
    spi_random_seq seq;
    phase.raise_objection(this);
    
    repeat(1000) begin  // 1000번 랜덤 테스트
      seq = spi_random_seq::type_id::create("seq");
      assert(seq.randomize());
      seq.start(env.agent.sequencer);
    end
    
    phase.drop_objection(this);
  endtask
endclass
```

## 4.2 Transaction 정의

```systemverilog
class spi_transaction extends uvm_sequence_item;
  `uvm_object_utils(spi_transaction)
  
  // Transaction Fields
  rand bit [7:0] data;       // 전송 데이터
  rand bit [1:0] mode;       // SPI Mode (0~3)
  rand bit [7:0] prescaler;  // Clock Divider
  
  // Constraints
  constraint data_c {
    data dist {
      8'h00       := 1,  // All 0
      8'hFF       := 1,  // All 1
      8'hAA       := 1,  // 10101010
      8'h55       := 1,  // 01010101
      [8'h01:8'hFE] := 96  // Random
    };
  }
  
  constraint mode_c {
    mode inside {[0:3]};
  }
  
  // Methods
  function new(string name = "spi_transaction");
    super.new(name);
  endfunction
  
  function void do_copy(uvm_object rhs);
    spi_transaction tx;
    $cast(tx, rhs);
    data = tx.data;
    mode = tx.mode;
    prescaler = tx.prescaler;
  endfunction
  
  function string convert2string();
    return $sformatf("Mode=%0d, Data=0x%02h, Prescaler=%0d", 
                     mode, data, prescaler);
  endfunction
endclass
```

## 4.3 Scoreboard 구현

```systemverilog
class spi_scoreboard extends uvm_scoreboard;
  `uvm_component_utils(spi_scoreboard)
  
  // Analysis Ports
  uvm_analysis_imp #(spi_transaction, spi_scoreboard) master_export;
  uvm_analysis_imp #(spi_transaction, spi_scoreboard) slave_export;
  
  // Queues
  spi_transaction master_queue[$];
  spi_transaction slave_queue[$];
  
  int pass_count = 0;
  int fail_count = 0;
  
  function void write_master(spi_transaction tx);
    master_queue.push_back(tx);
    compare();
  endfunction
  
  function void write_slave(spi_transaction tx);
    slave_queue.push_back(tx);
    compare();
  endfunction
  
  function void compare();
    spi_transaction master_tx, slave_tx;
    
    if (master_queue.size() > 0 && slave_queue.size() > 0) begin
      master_tx = master_queue.pop_front();
      slave_tx = slave_queue.pop_front();
      
      // Golden Model 계산
      bit [7:0] expected = calculate_golden(master_tx);
      
      // 비교
      if (slave_tx.data == expected) begin
        `uvm_info("SB", $sformatf("PASS: Expected=0x%02h, Got=0x%02h", 
                                   expected, slave_tx.data), UVM_MEDIUM)
        pass_count++;
      end else begin
        `uvm_error("SB", $sformatf("FAIL: Expected=0x%02h, Got=0x%02h", 
                                    expected, slave_tx.data))
        fail_count++;
      end
    end
  endfunction
  
  function bit [7:0] calculate_golden(spi_transaction tx);
    // SPI는 Full-Duplex이므로 Master가 보낸 데이터가
    // Slave가 받은 데이터와 같아야 함
    return tx.data;
  endfunction
  
  function void report_phase(uvm_phase phase);
    `uvm_info("FINAL", $sformatf("PASS: %0d, FAIL: %0d", 
                                  pass_count, fail_count), UVM_NONE)
  endfunction
endclass
```

## 4.4 Coverage 정의

```systemverilog
class spi_coverage extends uvm_subscriber #(spi_transaction);
  `uvm_component_utils(spi_coverage)
  
  spi_transaction tx;
  
  // Covergroup
  covergroup spi_cg;
    // Mode Coverage
    mode_cp: coverpoint tx.mode {
      bins mode[] = {[0:3]};
    }
    
    // Data Coverage
    data_cp: coverpoint tx.data {
      bins zero = {8'h00};
      bins all_ones = {8'hFF};
      bins low = {[8'h01:8'h7F]};
      bins high = {[8'h80:8'hFE]};
    }
    
    // Cross Coverage
    mode_data_cross: cross mode_cp, data_cp;
  endgroup
  
  function new(string name, uvm_component parent);
    super.new(name, parent);
    spi_cg = new();
  endfunction
  
  function void write(spi_transaction t);
    tx = t;
    spi_cg.sample();
  endfunction
  
  function void report_phase(uvm_phase phase);
    `uvm_info("COV", $sformatf("Coverage = %.2f%%", 
                               spi_cg.get_coverage()), UVM_NONE)
  endfunction
endclass
```

---

# 5. Trouble Shooting 상세 분석

## 5.1 문제 상황

### 📌 문제
**랜덤 시퀀스 수행 중 Sequence 전송 속도가 빠름**

**증상:**
- Driver가 아직 Transaction을 처리 중인데 Sequencer가 다음 Transaction을 보냄
- 데이터 누락 발생
- Scoreboard에서 Mismatch Error

### 📌 원인 분석

**UVM Sequence-Driver 흐름:**
```
Sequence                    Sequencer              Driver
   │                           │                     │
   │  start_item(tx)           │                     │
   ├──────────────────────────▶│                     │
   │                           │  get_next_item(req) │
   │                           │◀────────────────────┤
   │                           │                     │
   │                           │   req 전달          │
   │                           ├────────────────────▶│
   │                           │                     │
   │  finish_item(tx)          │                     │  drive()
   ├──────────────────────────▶│                     │  ← 시간 소요
   │                           │                     │
   │   ⚠️ 여기서 바로 다음 TX 생성!                   │  ← 아직 안 끝남!
   │                           │                     │
```

**문제:**
- `finish_item()`이 호출되면 Sequence는 바로 다음 Transaction 생성
- 하지만 Driver는 아직 이전 Transaction을 처리 중
- **동기화 문제 발생**

## 5.2 해결 방법

### 📌 해결 전략
**Driver 처리 완료 시점 기준으로 get_next_item()-item_done() 호출을 고정**

### 📌 수정 전 코드 (문제 있음)
```systemverilog
// Driver (잘못된 예시)
class spi_driver extends uvm_driver #(spi_transaction);
  task run_phase(uvm_phase phase);
    forever begin
      seq_item_port.get_next_item(req);  // ← Transaction 받기
      
      // ⚠️ 여기서 바로 item_done() 호출 (잘못!)
      seq_item_port.item_done();
      
      // 실제 전송 (시간 소요)
      drive_transaction(req);  // ← 이거 끝나기 전에 다음 TX가 옴!
    end
  endtask
endclass
```

### 📌 수정 후 코드 (올바름)
```systemverilog
// Driver (올바른 예시)
class spi_driver extends uvm_driver #(spi_transaction);
  task run_phase(uvm_phase phase);
    forever begin
      seq_item_port.get_next_item(req);  // ← Transaction 받기
      
      // 실제 전송 (시간 소요)
      drive_transaction(req);  // ← 먼저 전송 완료!
      
      // ✅ 전송 완료 후 item_done() 호출 (올바름!)
      seq_item_port.item_done();  // ← 이제 다음 TX 받을 준비 됨
    end
  endtask
  
  task drive_transaction(spi_transaction tx);
    // SPI 전송
    @(posedge clk);
    SS = 0;  // Slave Select
    
    for (int i = 0; i < 8; i++) begin
      @(posedge sclk);
      MOSI = tx.data[7-i];
    end
    
    @(posedge clk);
    SS = 1;  // Slave Deselect
    
    // ✅ 여기까지 와야 전송 완료!
  endtask
endclass
```

### 📌 동기화 흐름 (수정 후)
```
Sequence                    Sequencer              Driver
   │                           │                     │
   │  start_item(tx)           │                     │
   ├──────────────────────────▶│                     │
   │                           │  get_next_item(req) │
   │                           │◀────────────────────┤
   │                           │   req 전달          │
   │                           ├────────────────────▶│
   │  finish_item(tx)          │                     │  drive()
   ├──────────────────────────▶│                     │  ← 시간 소요
   │   ⏳ 대기...               │                     │  ...
   │                           │                     │  ...
   │                           │                     │  ✅ 전송 완료!
   │                           │   item_done()       │
   │                           │◀────────────────────┤
   │   ✅ 이제 다음 TX 생성!     │                     │
   │                           │                     │
```

### 📌 핵심 포인트
1. **get_next_item()**: Transaction 받기
2. **drive_transaction()**: 실제 전송 (시간 소요)
3. **item_done()**: 전송 완료 알림 ← **이 순서가 중요!**

### 📌 왜 이게 중요한가?
```
잘못된 순서:
get → item_done → drive
     ↑ 여기서 바로 다음 TX 요청 가능
            ↑ 근데 아직 전송 안 끝남!

올바른 순서:
get → drive → item_done
            ↑ 전송 완료 후에야 다음 TX 요청 가능
```

## 5.3 검증 결과

### 📌 수정 전
```
UVM_ERROR: Scoreboard Mismatch
Expected: 0xAA
Got: 0x55
  (데이터 누락으로 인한 오류)

PASS: 823
FAIL: 177
Success Rate: 82.3%
```

### 📌 수정 후
```
UVM_INFO: All transactions matched!

PASS: 1000
FAIL: 0
Success Rate: 100%
```

---

# 6. 면접 예상 질문 & 답변

## 6.1 프로젝트 전반

### Q1: 이 프로젝트를 한 이유는 무엇인가요?
**답변:**
"실무에서 가장 많이 사용되는 SPI와 I2C 통신 프로토콜을 직접 구현해보고 싶었고, 동시에 산업 표준 검증 방법론인 UVM을 경험하고 싶었습니다. 또한 시뮬레이션뿐만 아니라 실제 FPGA 하드웨어에서 동작을 확인함으로써 이론과 실습을 모두 경험하고자 했습니다."

### Q2: 이 프로젝트에서 가장 어려웠던 점은?
**답변:**
"UVM의 Sequence-Driver 간 동기화 문제가 가장 어려웠습니다. 처음에는 `get_next_item()` 후 바로 `item_done()`을 호출했는데, 이로 인해 Driver가 Transaction을 처리하는 중에 다음 Transaction이 들어와 데이터 누락이 발생했습니다. 이를 해결하기 위해 실제 전송이 완료된 후에 `item_done()`을 호출하도록 수정했고, 이를 통해 100% Pass율을 달성했습니다."

### Q3: 왜 UVM을 사용했나요? Verilog Testbench와의 차이는?
**답변:**
"UVM은 재사용성과 확장성이 뛰어나고, Constrained Random Verification을 통해 다양한 시나리오를 자동으로 생성할 수 있습니다. 또한 표준화된 구조로 협업 시 코드 이해가 쉽고, Scoreboard를 통한 자동 검증이 가능합니다. 반면 Verilog Testbench는 간단하지만, 복잡한 검증 환경에서는 유지보수가 어렵고 재사용성이 낮습니다."

**비교표:**
| 항목 | Verilog TB | UVM |
|------|-----------|-----|
| 구조 | 자유형식 | 표준화된 계층 |
| 재사용성 | 낮음 | 높음 |
| Random 생성 | 수동 | Constrained Random |
| 자동 검증 | 어려움 | Scoreboard 제공 |
| Coverage | 수동 | 자동 |

---

## 6.2 SPI 관련

### Q4: SPI Mode 0, 1, 2, 3의 차이를 설명하세요.
**답변:**
"SPI Mode는 CPOL(Clock Polarity)과 CPHA(Clock Phase)의 조합으로 결정됩니다.

- **Mode 0 (CPOL=0, CPHA=0)**: 클럭 Idle이 Low이고, Rising Edge에서 데이터 샘플링
- **Mode 1 (CPOL=0, CPHA=1)**: 클럭 Idle이 Low이고, Falling Edge에서 데이터 샘플링
- **Mode 2 (CPOL=1, CPHA=0)**: 클럭 Idle이 High이고, Falling Edge에서 데이터 샘플링
- **Mode 3 (CPOL=1, CPHA=1)**: 클럭 Idle이 High이고, Rising Edge에서 데이터 샘플링

이 4가지 모드를 모두 지원하도록 설계했고, UVM으로 각 모드별 동작을 검증했습니다."

### Q5: SPI와 I2C의 차이점은?
**답변:**

| 항목 | SPI | I2C |
|------|-----|-----|
| 신호선 수 | 4개 (SCLK, MOSI, MISO, SS) | 2개 (SCL, SDA) |
| 통신 방식 | Full-Duplex | Half-Duplex |
| 속도 | 더 빠름 (수십 MHz) | 느림 (최대 3.4 Mbps) |
| Multi-Master | 어려움 | 지원 |
| 주소 지정 | SS로 선택 | 7/10-bit 주소 |
| 복잡도 | 간단 | 복잡 (ACK/NACK) |

"SPI는 고속 통신이 필요한 ADC, DAC 등에 사용되고, I2C는 센서, EEPROM 등 저속 디바이스에 적합합니다."

### Q6: SPI Master와 Slave의 차이는?
**답변:**
"Master는 클럭(SCLK)을 생성하고 통신을 주도하는 역할을 합니다. Slave Select(SS) 신호로 어떤 Slave와 통신할지 결정합니다. 반면 Slave는 Master의 클럭에 동기화하여 데이터를 송수신하며, SS 신호가 Low일 때만 활성화됩니다.

본 프로젝트에서는 Master와 Slave 모두 구현했고, Master는 FSM으로 전송 시퀀스를 제어하며, Slave는 클럭 에지에서 데이터를 수신하도록 설계했습니다."

---

## 6.3 I2C 관련

### Q7: I2C의 START와 STOP 조건을 설명하세요.
**답변:**
"I2C는 START와 STOP 조건으로 통신의 시작과 끝을 표시합니다.

- **START 조건**: SCL이 High일 때 SDA가 High→Low로 변하면 START
- **STOP 조건**: SCL이 High일 때 SDA가 Low→High로 변하면 STOP

이 조건들은 클럭과 데이터 라인의 특정 타이밍 관계로 정의되어, 데이터 전송과 구별됩니다."

```
START:
SDA: ──┐   
       └────
SCL: ──────

STOP:
SDA:    ┌──
     ───┘   
SCL: ──────
```

### Q8: I2C ACK/NACK의 의미와 처리 방법은?
**답변:**
"ACK(Acknowledge)는 수신자가 데이터를 성공적으로 받았음을 알리는 신호입니다. 8-bit 데이터 전송 후 9번째 클럭에서 SDA를 Low로 당기면 ACK입니다. NACK는 SDA를 High로 유지하여 수신 실패나 통신 종료를 의미합니다.

본 프로젝트에서는 Status Register(STR)의 ACK/NACK 비트를 통해 MicroBlaze가 통신 성공 여부를 확인할 수 있도록 했습니다."

```
ACK:
SDA: ──X X X X X X X X──┐   ┌──
                        └───┘
     |← 8-bit Data →|  9th

NACK:
SDA: ──X X X X X X X X────────
     |← 8-bit Data →|  9th
```

### Q9: I2C 레지스터(CR, ODR, IDR, STR)의 역할은?
**답변:**
"각 레지스터의 역할은 다음과 같습니다:

- **CR (Control Register)**: I2C 동작 제어
  - EN bit: I2C 활성화/비활성화
  - START bit: START 조건 생성
  - STOP bit: STOP 조건 생성

- **ODR (Output Data Register)**: 송신할 데이터 저장

- **IDR (Input Data Register)**: 수신한 데이터 저장

- **STR (Status Register)**: 통신 상태 확인
  - BUSY bit: 전송 진행 중
  - ACK/NACK bit: 응답 상태

MicroBlaze는 AXI4-Lite 버스를 통해 이 레지스터들을 Read/Write하여 I2C를 제어합니다."

---

## 6.4 AXI4-Lite 관련

### Q10: AXI4-Lite와 AXI4의 차이는?
**답변:**

| 항목 | AXI4-Lite | AXI4 Full |
|------|-----------|-----------|
| 용도 | 레지스터 접근 | 고성능 메모리 접근 |
| 버스트 | 불가 (1회 전송) | 가능 (256회) |
| 데이터 폭 | 32/64-bit | 8~1024-bit |
| 복잡도 | 낮음 | 높음 |
| QoS | 없음 | 지원 |

"본 프로젝트에서는 I2C 레지스터 접근만 필요했기 때문에 간단한 AXI4-Lite를 사용했습니다."

### Q11: AXI4-Lite Handshake 메커니즘을 설명하세요.
**답변:**
"AXI4-Lite는 VALID-READY Handshake로 동작합니다.

1. Master가 VALID를 High로 올리면 데이터/주소가 유효함을 의미
2. Slave가 READY를 High로 올리면 수신 준비 완료를 의미
3. **VALID=1 & READY=1일 때 전송 성공**

이 메커니즘으로 Master와 Slave가 서로 다른 속도로 동작해도 데이터 손실 없이 통신할 수 있습니다."

```
Waveform:
CLK:    ┌─┐ ┌─┐ ┌─┐ ┌─┐
        ┘ └─┘ └─┘ └─┘ └─

VALID:  ──┐       ┌──────
          └───────┘

READY:  ────┐   ┌────────
            └───┘
               ↑
             전송 성공
```

### Q12: MicroBlaze가 I2C를 제어하는 과정을 설명하세요.
**답변:**
"MicroBlaze는 다음 과정으로 I2C를 제어합니다:

1. **I2C 활성화**: CR 레지스터의 EN bit를 1로 설정
2. **START 조건**: CR 레지스터의 START bit를 1로 설정
3. **주소 전송**: ODR 레지스터에 Slave 주소 쓰기
4. **BUSY 대기**: STR 레지스터의 BUSY bit가 0이 될 때까지 폴링
5. **ACK 확인**: STR 레지스터의 ACK bit 확인
6. **데이터 전송**: ODR 레지스터에 데이터 쓰기
7. **STOP 조건**: CR 레지스터의 STOP bit를 1로 설정

이 모든 레지스터 접근은 AXI4-Lite 버스를 통해 이루어집니다."

```c
// MicroBlaze C Code 예시
#define I2C_BASE 0x40000000
#define I2C_CR   (*(volatile uint32_t*)(I2C_BASE + 0x00))
#define I2C_ODR  (*(volatile uint32_t*)(I2C_BASE + 0x04))
#define I2C_STR  (*(volatile uint32_t*)(I2C_BASE + 0x0C))

void i2c_write_byte(uint8_t addr, uint8_t data) {
  I2C_CR = 0x03;  // EN | START
  I2C_ODR = (addr << 1);
  while(I2C_STR & 0x01);  // Wait BUSY
  I2C_ODR = data;
  while(I2C_STR & 0x01);
  I2C_CR = 0x05;  // EN | STOP
}
```

---

## 6.5 UVM 관련

### Q13: UVM의 주요 컴포넌트를 설명하세요.
**답변:**
"UVM의 주요 컴포넌트는 다음과 같습니다:

1. **Sequence**: 테스트 시나리오와 Transaction 생성
2. **Sequencer**: Sequence와 Driver 연결
3. **Driver**: Transaction을 DUT 신호로 변환
4. **Monitor**: DUT 출력 관찰 및 Transaction 수집
5. **Scoreboard**: Golden Model과 DUT 비교
6. **Agent**: Sequencer, Driver, Monitor를 묶은 단위
7. **Environment**: 전체 검증 환경
8. **Test**: 최상위 테스트 시나리오

각 컴포넌트는 표준화된 Phase(build, connect, run 등)를 통해 실행됩니다."

### Q14: Constrained Random Verification이란?
**답변:**
"제약 조건(Constraint)을 가진 랜덤 데이터 생성 방식입니다. 완전한 랜덤이 아니라 특정 조건을 만족하는 범위 내에서 랜덤하게 생성하여, 효율적으로 다양한 케이스를 테스트할 수 있습니다.

예를 들어 본 프로젝트에서는:
```systemverilog
constraint data_c {
  data dist {
    8'h00       := 1,   // Corner case (all 0)
    8'hFF       := 1,   // Corner case (all 1)
    [8'h01:8'hFE] := 98; // Random
  };
}
```
이렇게 Corner Case와 Random Case를 균형있게 생성했습니다."

### Q15: Golden Model이란? 어떻게 구현했나요?
**답변:**
"Golden Model은 DUT의 예상 동작을 소프트웨어로 구현한 참조 모델입니다. DUT의 출력과 Golden Model의 출력을 비교하여 정확성을 검증합니다.

본 프로젝트에서는 Scoreboard 내부에 Golden Model을 구현했습니다:
```systemverilog
function bit [7:0] calculate_golden(spi_transaction tx);
  // SPI는 Full-Duplex이므로
  // Master가 보낸 데이터 == Slave가 받은 데이터
  return tx.data;
endfunction
```

실제로는 SPI Mode에 따른 비트 순서, 클럭 극성 등도 고려하여 구현했습니다."

### Q16: Coverage가 무엇이고 왜 중요한가요?
**답변:**
"Coverage는 테스트가 얼마나 많은 경우를 커버했는지 측정하는 지표입니다.

**종류:**
1. **Code Coverage**: 코드 라인 실행 비율
2. **Functional Coverage**: 기능 시나리오 커버 비율

본 프로젝트에서는 Functional Coverage를 사용했습니다:
```systemverilog
covergroup spi_cg;
  mode_cp: coverpoint tx.mode {
    bins mode[] = {[0:3]};  // 4가지 모드 모두 테스트
  }
  
  data_cp: coverpoint tx.data {
    bins zero = {8'h00};
    bins all_ones = {8'hFF};
    bins low = {[8'h01:8'h7F]};
    bins high = {[8'h80:8'hFE]};
  }
  
  // Mode x Data 조합도 테스트
  mode_data_cross: cross mode_cp, data_cp;
endgroup
```

Coverage 목표는 100%였고, Random 테스트로 달성했습니다."

---

## 6.6 FPGA 관련

### Q17: 시뮬레이션과 실제 FPGA 동작의 차이점은?
**답변:**
"시뮬레이션은 이상적인 환경이지만, 실제 FPGA는 다음 문제들이 발생할 수 있습니다:

1. **타이밍 문제**: Setup/Hold Time 위반
2. **Clock Domain Crossing**: 비동기 클럭 간 데이터 전송 오류
3. **메타스테이블리티**: 비동기 신호 샘플링 시 불안정한 상태
4. **전력/발열**: 시뮬레이션에서는 고려 안 함
5. **I/O 특성**: 실제 전압 레벨, 노이즈

본 프로젝트에서는 이를 검증하기 위해 Basys3 FPGA에서 실제 동작을 확인했습니다."

### Q18: Basys3를 선택한 이유는?
**답변:**
"Basys3는 교육용으로 널리 사용되는 저렴한 FPGA 보드이며, 다음 장점이 있습니다:

- **Artix-7 FPGA**: Xilinx의 범용 FPGA로 충분한 리소스
- **MicroBlaze 지원**: Soft Processor 실행 가능
- **I/O 풍부**: LED, 스위치, 버튼, PMOD 커넥터
- **Vivado 지원**: 무료 툴로 개발 가능

실제로 MicroBlaze를 올려 C 코드로 I2C를 제어하고, SPI 통신으로 LED를 제어하는 데모를 구현했습니다."

### Q19: MicroBlaze란? 왜 사용했나요?
**답변:**
"MicroBlaze는 Xilinx FPGA에 구현 가능한 **Soft Processor**입니다. 하드웨어로 구현되는 일반 프로세서와 달리, FPGA 내부 로직으로 구현되어 유연하게 커스터마이징할 수 있습니다.

**사용 이유:**
1. C 코드로 I2C 제어 로직 작성 가능 (RTL보다 쉬움)
2. AXI4-Lite 버스 지원으로 IP 연결 용이
3. 실제 임베디드 시스템 경험

**구성:**
- CPU Core
- Local Memory (BRAM)
- AXI4-Lite Interface
- UART, GPIO 등 Peripheral

MicroBlaze에서 C 코드로 I2C 레지스터를 제어하고, I2C를 통해 LED를 켜는 데모를 구현했습니다."

---

## 6.7 고급 질문

### Q20: 만약 Multi-Master I2C를 구현한다면?
**답변:**
"Multi-Master I2C는 여러 Master가 동시에 버스를 사용할 수 있는 구조입니다. 구현 시 고려사항:

1. **Arbitration (중재)**:
   - SDA를 Low로 당기는 Master가 우선권
   - 각 Master는 송신 중 SDA를 모니터링
   - 자신이 보낸 값과 다르면 중재 패배로 인식하고 대기

2. **Clock Synchronization**:
   - 여러 Master의 클럭 중 가장 느린 클럭에 동기화
   - SCL을 Low로 당기는 Master가 있으면 모든 Master 대기

3. **추가 로직**:
   - Arbitration Lost 감지
   - Bus Busy 감지
   - 재전송 로직

본 프로젝트는 Single Master로 구현했지만, 이론적으로는 이런 로직을 추가하면 Multi-Master 지원이 가능합니다."

### Q21: SPI 클럭 속도를 어떻게 결정했나요?
**답변:**
"SPI 클럭 속도는 다음 요소를 고려했습니다:

1. **Master 시스템 클럭**: 100MHz (Basys3)
2. **Prescaler 설계**:
   ```verilog
   sclk_divider = sys_clk / (2 * (prescaler + 1))
   ```
   예) prescaler=49 → SCLK=1MHz

3. **Slave 최대 속도**: 데이터시트 확인 필요

4. **신호 무결성**:
   - 케이블 길이
   - Capacitance
   - Setup/Hold Time

본 프로젝트에서는 1~10MHz 범위로 설정했고, UVM으로 다양한 속도를 테스트했습니다."

### Q22: 만약 이 프로젝트를 더 개선한다면?
**답변:**
"다음과 같은 개선을 고려할 수 있습니다:

1. **DMA 추가**: CPU 개입 없이 메모리↔I2C/SPI 직접 전송
2. **Interrupt 지원**: 폴링 대신 인터럽트로 효율성 향상
3. **FIFO 버퍼**: 연속 데이터 전송 지원
4. **Error Detection**: CRC, Parity 등
5. **Multi-Slave SPI**: 여러 Slave 동시 지원
6. **I2C 10-bit Addressing**: 확장 주소 지원
7. **Power Management**: Low-Power 모드

또한 UVM 측면에서는:
- Assertion 기반 검증 추가
- Formal Verification 도입
- Coverage-Driven Verification 강화"

---

## 6.8 실무 경험 관련

### Q23: 실무에서 이런 프로젝트가 어떻게 활용되나요?
**답변:**
"SPI와 I2C는 임베디드 시스템에서 필수적인 통신 프로토콜입니다:

**SPI 사용 사례:**
- ADC/DAC 제어
- Flash Memory
- 디스플레이 (LCD, OLED)
- 센서 (온도, 가속도)

**I2C 사용 사례:**
- 센서 네트워크
- EEPROM
- RTC (Real-Time Clock)
- PMU (Power Management Unit)

**실무 프로세스:**
1. Spec 정의 → 2. RTL 설계 → 3. UVM 검증 → 4. FPGA 프로토타이핑 → 5. ASIC 구현

본 프로젝트는 1~4단계까지 경험한 것으로, 실제 칩 개발 프로세스와 유사합니다."

### Q24: 이 프로젝트를 통해 배운 점은?
**답변:**
"세 가지 중요한 점을 배웠습니다:

1. **표준 프로토콜의 중요성**: SPI와 I2C는 간단해 보이지만, 타이밍과 에지 케이스를 정확히 이해해야 함

2. **검증의 중요성**: UVM을 통한 체계적인 검증으로 RTL 설계 오류를 조기에 발견. Trouble Shooting 경험으로 동기화 문제 해결 능력 향상

3. **이론과 실습의 차이**: 시뮬레이션에서는 완벽했지만 FPGA에서는 타이밍 이슈 발생. 실제 하드웨어 특성 이해의 중요성 깨달음

이를 통해 설계-검증-구현의 전체 Flow를 경험했고, 실무에 즉시 적용 가능한 역량을 갖추게 되었습니다."

---

## 7. 추가 학습 자료

### 📚 추천 서적
1. **"SystemVerilog for Verification"** - Chris Spear
2. **"UVM Cookbook"** - Verification Academy
3. **"Digital Design and Computer Architecture"** - Harris & Harris

### 🔗 추천 리소스
1. **Verification Academy**: https://verificationacademy.com/
2. **ChipVerify**: https://www.chipverify.com/
3. **ASIC World**: http://www.asic-world.com/

### 💡 실습 과제
1. **SPI Quad Mode** 구현 (4-wire SPI)
2. **I2C SMBUS** 프로토콜 구현
3. **AXI4 Full** 버전 구현

---



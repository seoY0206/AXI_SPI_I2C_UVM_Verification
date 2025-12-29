# AXI_SPI_I2C_UVM_Verification
UVM-based verification environment for SPI and I2C communication modules, supporting multiple modes and real hardware validation.

## ✨Overview
SPI 및 I2C 통신 모듈을 설계하고,  
UVM 기반 검증 환경을 구축해 다양한 통신 조건에서 기능 안정성을 검증한 프로젝트입니다.

SPI Mode(CPOL/CPHA)별 동작 차이와 랜덤 트랜잭션 환경을 고려해  
Protocol 중심의 검증 구조를 설계하고, FPGA 실환경까지 연동해 동작을 확인했습니다.

## ⚙️Tool & Language
- SystemVerilog  
- UVM  
- FPGA (Basys3)  
- MicroBlaze  
- Vivado  

## 🧱Architecture
- SPI / I2C Master 통신 모듈 설계  
- AXI 기반 레지스터 접근 구조  
- UVM Sequence / Driver / Monitor / Scoreboard 구성  
- Golden–Actual 데이터 비교 구조  
- FPGA + MicroBlaze 실환경 연동 검증  

## 🪄Verification & Performance
- SPI Mode 0~3(CPOL/CPHA) 전 조합에 대해 Read/Write 기능 자동 검증 수행  
- UVM Scoreboard 기반 Golden/Actual 비교로 데이터 전송 오류를 패킷 단위로 즉시 검출  
- SPI 및 I2C 통신 경로를 실제 환경(FPGA + MicroBlaze)에서 정상 동작 검증  

## 📍Key Features
- SPI / I2C Protocol 특성을 반영한 UVM 검증 환경 구축  
- Mode·타이밍 조건을 고려한 랜덤 시퀀스 테스트  
- 시뮬레이션부터 FPGA 실동작까지 검증 범위 확장  
- 통신 모듈 검증을 통한 Protocol 이해도 향상


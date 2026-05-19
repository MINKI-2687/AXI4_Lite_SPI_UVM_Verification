// 파일 위치: tb/test_pkg.sv
`ifndef TEST_PKG_SV
    `define TEST_PKG_SV

    `include "uvm_macros.svh"

    package test_pkg;
        // 1. UVM 기본 라이브러리 수입
        import uvm_pkg::*;

        // 2. 하위 클래스(axi_seq_item, axi2spi_env 등)를 인식하기 위해 기존 패키지들 수입
        import axi_agent_pkg::*;
        import spi_agent_pkg::*;
        import env_pkg::*;

        // 3. 시퀀스와 테스트 파일을 패키지 안으로 조립
        `include "sequences/axi_write_seq.sv"
        `include "sequences/axi_read_seq.sv"
        `include "sequences/axi_write_read_seq.sv"
        `include "sequences/axi_random_loop_seq.sv"
        `include "sequences/spi_dummy_seq.sv"
        `include "axi2spi_test.sv"

    endpackage

`endif

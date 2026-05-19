// 파일 위치: tb/agents/axi_agent/axi_agent_pkg.sv
`ifndef AXI_AGENT_PKG_SV
`define AXI_AGENT_PKG_SV

// 1. UVM 매크로를 가장 먼저 불러옵니다.
`include "uvm_macros.svh"

package axi_agent_pkg;
    // 2. 패키지 안에서 UVM 라이브러리를 한 번만 Import 합니다.
    import uvm_pkg::*;

    // 3. Makefile의 +incdir+./tb 설정에 맞춰 하위 파일들을 순서대로 조립합니다.
    `include "agents/axi_agent/axi_seq_item.sv"
    `include "agents/axi_agent/axi_sequencer.sv"
    `include "agents/axi_agent/axi_driver.sv"
    `include "agents/axi_agent/axi_monitor.sv"
    `include "agents/axi_agent/axi_agent.sv"

endpackage

`endif

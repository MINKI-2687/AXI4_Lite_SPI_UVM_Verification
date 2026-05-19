`ifndef SPI_AGENT_PKG_SV
`define SPI_AGENT_PKG_SV

`include "uvm_macros.svh"

package spi_agent_pkg;
    import uvm_pkg::*;

    `include "agents/spi_agent/spi_seq_item.sv"
    `include "agents/spi_agent/spi_sequencer.sv"
    `include "agents/spi_agent/spi_driver.sv"
    `include "agents/spi_agent/spi_monitor.sv"
    `include "agents/spi_agent/spi_agent.sv"

endpackage

`endif

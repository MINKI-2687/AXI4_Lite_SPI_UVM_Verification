`ifndef ENV_PKG_SV
    `define ENV_PKG_SV

    `include "uvm_macros.svh"

    package env_pkg;
        import uvm_pkg::*;

        import axi_agent_pkg::*;
        import spi_agent_pkg::*;

        `include "env/axi2spi_coverage.sv"
        `include "env/axi2spi_scoreboard.sv"
        `include "env/axi2spi_env.sv"

    endpackage

`endif

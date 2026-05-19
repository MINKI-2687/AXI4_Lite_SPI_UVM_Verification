`ifndef AXI2SPI_ENV_SV
    `define AXI2SPI_ENV_SV

    class axi2spi_env extends uvm_env;
        `uvm_component_utils(axi2spi_env)

        // 에이전트 및 스코어보드 선언
        axi_agent          m_axi_agent;
        spi_agent          m_spi_agent;
        axi2spi_scoreboard m_scoreboard;
        axi2spi_coverage   m_coverage;

        function new(string name = "axi2spi_env", uvm_component parent);
            super.new(name, parent);
        endfunction

        virtual function void build_phase(uvm_phase phase);
            super.build_phase(phase);
            // 하위 컴포넌트들 생성
            m_axi_agent  = axi_agent::type_id::create("m_axi_agent", this);
            m_spi_agent  = spi_agent::type_id::create("m_spi_agent", this);
            m_scoreboard = axi2spi_scoreboard::type_id::create("m_scoreboard", this);
            m_coverage = axi2spi_coverage::type_id::create("m_coverage", this);
        endfunction

        virtual function void connect_phase(uvm_phase phase);
            super.connect_phase(phase);
            // 각 에이전트의 모니터(ap) -> 스코어보드의 FIFO(analysis_export)
            m_axi_agent.monitor.ap.connect(m_scoreboard.axi_fifo.analysis_export);
            m_spi_agent.monitor.ap.connect(m_scoreboard.spi_fifo.analysis_export);
            m_axi_agent.monitor.ap.connect(m_coverage.analysis_export);
        endfunction
    endclass

`endif

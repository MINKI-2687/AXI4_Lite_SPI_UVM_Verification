`ifndef AXI2SPI_COVERAGE_SV
    `define AXI2SPI_COVERAGE_SV

    class axi2spi_coverage extends uvm_subscriber #(axi_seq_item);
        `uvm_component_utils(axi2spi_coverage)

        // 송신(TX)과 수신(RX) 데이터를 담을 변수
        logic [7:0] cov_tx_data;
        logic [7:0] cov_rx_data;

        covergroup cg_axi2spi;
            option.per_instance = 1;

            // 1. 송신 데이터 (AXI -> SPI) 커버포인트
            cp_tx_data: coverpoint cov_tx_data {
                bins zero     = {8'h00};
                bins max      = {8'hFF};
                bins alt_55   = {8'h55};
                bins alt_AA   = {8'hAA};
                bins low_rng  = {[8'h01 : 8'h7F]};
                bins high_rng = {[8'h80 : 8'hFE]};
            }

            // 2. 수신 데이터 (SPI -> AXI) 커버포인트
            cp_rx_data: coverpoint cov_rx_data {
                bins zero     = {8'h00};
                bins max      = {8'hFF};
                bins alt_55   = {8'h55};
                bins alt_AA   = {8'hAA};
                bins low_rng  = {[8'h01 : 8'h7F]};
                bins high_rng = {[8'h80 : 8'hFE]};
            }

            cross_tx_rx: cross cp_tx_data, cp_rx_data;
        endgroup

        function new(string name, uvm_component parent);
            super.new(name, parent);
            cg_axi2spi = new();
        endfunction

        function void write(axi_seq_item t);
            if (t.dir == axi_seq_item::WRITE && t.addr == 4'h4) begin
                cov_tx_data = t.data[7:0];
            end
            else if (t.dir == axi_seq_item::READ && t.addr == 4'h8) begin
                cov_rx_data = t.rdata[7:0];
                cg_axi2spi.sample();
            end
        endfunction

        virtual function void report_phase(uvm_phase phase);
            super.report_phase(phase);
            `uvm_info("COV", "\n=======================================", UVM_NONE)
            `uvm_info("COV", "===== AXI2SPI Coverage Summary   =====", UVM_NONE)
            `uvm_info("COV", $sformatf("  Overall Coverage   : %.1f%%",
                cg_axi2spi.get_coverage()), UVM_NONE)
            `uvm_info("COV", $sformatf("  TX Data Coverage   : %.1f%%",
                cg_axi2spi.cp_tx_data.get_coverage()), UVM_NONE)
            `uvm_info("COV", $sformatf("  RX Data Coverage   : %.1f%%",
                cg_axi2spi.cp_rx_data.get_coverage()), UVM_NONE)
            `uvm_info("COV", $sformatf("  Cross (TX x RX)    : %.1f%%",
                cg_axi2spi.cross_tx_rx.get_coverage()), UVM_NONE)
            `uvm_info("COV", "=======================================\n", UVM_NONE)
        endfunction
    endclass

`endif

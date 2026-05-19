`ifndef SPI_MONITOR_SV
    `define SPI_MONITOR_SV

    class spi_monitor extends uvm_monitor;
        `uvm_component_utils(spi_monitor)

        virtual spi_if vif;
        uvm_analysis_port #(spi_seq_item) ap;

        function new(string name = "spi_monitor", uvm_component parent);
            super.new(name, parent);
            ap = new("ap", this);
        endfunction

        virtual function void build_phase(uvm_phase phase);
            super.build_phase(phase);
            if (!uvm_config_db#(virtual spi_if)::get(this, "", "vif_spi", vif))
                `uvm_fatal("NO_VIF", "virtual interface not set for spi_monitor")
        endfunction

        virtual task run_phase(uvm_phase phase);
            spi_seq_item item;

            forever begin
                @(negedge vif.cs_n); // 통신 시작 감지
                item = spi_seq_item::type_id::create("item");

                // 8개의 비트를 클럭에 맞춰 수집
                for (int i = 0; i < 8; i++) begin
                    @(posedge vif.sclk); // Mode 0 기준 Rising Edge 샘플링
                    item.mosi_data = {item.mosi_data[6:0], vif.mosi};
                    item.miso_data = {item.miso_data[6:0], vif.miso};
                end

                @(posedge vif.cs_n); // 통신 종료 대기
                `uvm_info("SPI_MON",
                    $sformatf("Captured MOSI = 0x%0h, MISO = 0x%0h",
                        item.mosi_data, item.miso_data), UVM_HIGH)

                ap.write(item); // 조립된 데이터를 스코어보드로 전송
            end
        endtask
    endclass

`endif

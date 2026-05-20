`ifndef SPI_DRIVER_SV
`define SPI_DRIVER_SV

class spi_driver extends uvm_driver #(spi_seq_item);
    `uvm_component_utils(spi_driver)

    virtual spi_if vif;

    function new(string name = "spi_driver", uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual spi_if)::get(this, "", "vif_spi", vif))
            `uvm_fatal("NO_VIF", "virtual interface not set for spi_driver")
    endfunction

    virtual task run_phase(uvm_phase phase);
        vif.miso <= 1'b0; // 초기화

        forever begin
            // 1. 시퀀스에서 보낼 가짜 데이터
            seq_item_port.get_next_item(req);

            // 2. 마스터(DUT)가 통신을 시작할 때까지 대기
            @(negedge vif.cs_n);

            // 3. 8비트 데이터를 SCLK 클럭에 맞춰 MISO 핀 (Mode 0 기준)
            for (int i = 7; i >= 0; i--) begin
                vif.miso <= req.miso_data[i];
                @(negedge vif.sclk); // Falling Edge에서 데이터 변경
            end

            vif.miso <= 1'b0; // 통신 종료 후 0으로 복귀
            seq_item_port.item_done();
        end
    endtask
endclass

`endif

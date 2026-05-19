`ifndef AXI_DRIVER_SV
    `define AXI_DRIVER_SV

    class axi_driver extends uvm_driver #(axi_seq_item);
        `uvm_component_utils(axi_driver)

        virtual axi_if vif;

        function new(string name = "axi_driver", uvm_component parent);
            super.new(name, parent);
        endfunction

        virtual function void build_phase(uvm_phase phase);
            super.build_phase(phase);
            if (!uvm_config_db#(virtual axi_if)::get(this, "", "vif_axi", vif))
                `uvm_fatal("NO_VIF", "virtual interface not set for axi_driver")
        endfunction

        virtual task run_phase(uvm_phase phase);
            // 초기화
            vif.awvalid <= 0; vif.wvalid <= 0; vif.bready <= 0;
            vif.arvalid <= 0; vif.rready <= 0;

            @(posedge vif.reset_n); // 리셋 해제 대기

            forever begin
                seq_item_port.get_next_item(req);

                if (req.dir == axi_seq_item::WRITE) begin
                    drive_write(req);
                end else if (req.dir == axi_seq_item::READ) begin
                    drive_read(req);  // 새로 추가했던 Read 핀 제어 로직
                end

                seq_item_port.item_done();
            end
        endtask

        virtual task drive_write(axi_seq_item item);
            @(posedge vif.clk);
            vif.awaddr <= item.addr; vif.awvalid <= 1;
            vif.wdata  <= item.data; vif.wstrb <= 4'hF; vif.wvalid <= 1;

            wait(vif.awready && vif.wready);
            @(posedge vif.clk);
            vif.awvalid <= 0; vif.wvalid <= 0;

            vif.bready <= 1;
            wait(vif.bvalid);
            @(posedge vif.clk);
            vif.bready <= 0;
        endtask

        virtual task drive_read(axi_seq_item item);
            `uvm_info("DRV", $sformatf("Driving READ: ADDR=0x%0h", item.addr), UVM_HIGH)

            @(posedge vif.clk);
            // 1. Read Address Channel (AR)
            vif.araddr  <= item.addr;
            vif.arvalid <= 1;
            vif.arprot  <= 3'b000;

            wait(vif.arready);
            @(posedge vif.clk);
            vif.arvalid <= 0;

            // 2. Read Data Channel (R)
            vif.rready <= 1; // 데이터를 받을 준비가 되었음을 알림
            wait(vif.rvalid);
            @(posedge vif.clk);

            // DUT가 준 데이터를 아이템에 저장
            item.rdata = vif.rdata;
            item.resp  = vif.rresp;

            vif.rready <= 0;
        endtask
    endclass

`endif

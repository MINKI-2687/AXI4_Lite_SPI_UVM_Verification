`ifndef AXI_MONITOR_SV
    `define AXI_MONITOR_SV

    class axi_monitor extends uvm_monitor;
        `uvm_component_utils(axi_monitor)

        virtual axi_if vif;
        uvm_analysis_port #(axi_seq_item) ap; // 스코어보드로 데이터를 보낼 포트

        function new(string name = "axi_monitor", uvm_component parent);
            super.new(name, parent);
            ap = new("ap", this);
        endfunction

        virtual function void build_phase(uvm_phase phase);
            super.build_phase(phase);
            if (!uvm_config_db#(virtual axi_if)::get(this, "", "vif_axi", vif))
                `uvm_fatal("NO_VIF", "virtual interface not set for axi_monitor")
        endfunction

        virtual task run_phase(uvm_phase phase);
            axi_seq_item item;

            // AR 채널의 주소를 임시로 기억할 변수 선언
            bit [3:0] read_addr_q;

            forever begin
                @(posedge vif.clk);

                // 1. Write 트랜잭션 캡처
                if (vif.awvalid && vif.awready && vif.wvalid && vif.wready) begin
                    item = axi_seq_item::type_id::create("item");
                    item.dir  = axi_seq_item::WRITE;
                    item.addr = vif.awaddr;
                    item.data = vif.wdata;
                    `uvm_info("MON",
                        $sformatf("Captured Write: ADDR=%0h DATA=%0h",
                            item.addr, item.data), UVM_LOW)
                    ap.write(item);
                end
                // 2. Read 트랜잭션 캡처
                // 주소 채널(AR)이 동작할 때 주소를 캡처해서 기억해 둠
                if (vif.arvalid && vif.arready) begin
                    read_addr_q = vif.araddr;
                end
                // 데이터 채널(R)이 동작할 때, 기억해둔 주소와 함께 객체를 생성
                if (vif.rvalid && vif.rready) begin
                    item = axi_seq_item::type_id::create("item");
                    item.dir   = axi_seq_item::READ;
                    item.addr  = read_addr_q;
                    item.rdata = vif.rdata;
                    `uvm_info("MON",
                        $sformatf("Captured Read: ADDR=%0h RDATA=%0h",
                            item.addr, item.rdata), UVM_LOW)
                    ap.write(item);
                end
            end
        endtask
    endclass

`endif

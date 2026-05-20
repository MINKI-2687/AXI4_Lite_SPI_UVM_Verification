`ifndef AXI_WRITE_READ_SEQ_SV
    `define AXI_WRITE_READ_SEQ_SV

    class axi_write_read_seq extends uvm_sequence #(axi_seq_item);
        `uvm_object_utils(axi_write_read_seq)

        function new(string name = "axi_write_read_seq");
            super.new(name);
        endfunction

        virtual task body();
            axi_seq_item req;

            `uvm_info("SEQ", "=== Phase 1: WRITE to trigger SPI ===", UVM_LOW)
            req = axi_seq_item::type_id::create("req");
            start_item(req);
            if (!req.randomize() with { dir == axi_seq_item::WRITE; addr == 4'h4; })
                `uvm_fatal("SEQ", "Write Rand Fail")
            finish_item(req);

            #500;

            `uvm_info("SEQ", "=== Phase 2: READ to check received data ===", UVM_LOW)
            req = axi_seq_item::type_id::create("req");
            start_item(req);
            if (!req.randomize() with { dir == axi_seq_item::READ; addr == 4'h4; })
                `uvm_fatal("SEQ", "Read Rand Fail")
            finish_item(req);

            `uvm_info("SEQ", $sformatf("Final Read DATA = 0x%0h", req.rdata), UVM_LOW)
        endtask
    endclass

`endif

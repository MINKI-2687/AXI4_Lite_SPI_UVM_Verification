`ifndef AXI_READ_SEQ_SV
    `define AXI_READ_SEQ_SV

    class axi_read_seq extends uvm_sequence #(axi_seq_item);
        `uvm_object_utils(axi_read_seq)

        function new(string name = "axi_read_seq");
            super.new(name);
        endfunction

        virtual task body();
            axi_seq_item req;
            req = axi_seq_item::type_id::create("req");

            start_item(req);
            if (!req.randomize() with {
                dir == axi_seq_item::READ;
                addr == 4'h4; // 데이터 레지스터 읽기
            }) `uvm_error("SEQ", "Randomization failed")
            finish_item(req);

            // 읽어온 데이터 확인 (로그 출력)
            `uvm_info("SEQ", $sformatf("Read Done: DATA=0x%0h", req.rdata), UVM_LOW)
        endtask
    endclass

`endif

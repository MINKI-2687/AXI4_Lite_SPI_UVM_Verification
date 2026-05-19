class axi_random_loop_seq extends uvm_sequence #(axi_seq_item);
    `uvm_object_utils(axi_random_loop_seq)
    function new(string name="axi_random_loop_seq");
        super.new(name);
    endfunction

    virtual task body();
        axi_seq_item req;
        int loop_count = 1000; // 50번 연속 테스트

        for (int i = 0; i < loop_count; i++) begin
            `uvm_info("SEQ",
                $sformatf("--- Iteration %0d/%0d ---", i+1, loop_count), UVM_LOW)

            // 1. 랜덤 데이터 WRITE (TX 레지스터 0x4)
            req = axi_seq_item::type_id::create("req");
            start_item(req);
            if (!req.randomize() with {
                dir == axi_seq_item::WRITE;
                addr == 4'h4;
                data[31] == 1'b1;})
            `uvm_fatal("SEQ", "Write Rand Fail")
            finish_item(req);

            do begin
                #100;

                req = axi_seq_item::type_id::create("req");
                start_item(req);
                if (!req.randomize() with { dir == axi_seq_item::READ; addr == 4'h8; })
                    `uvm_fatal("SEQ", "Read Rand Fail")
                finish_item(req);

            end while (req.rdata[9] == 1'b1);
        end
    endtask
endclass

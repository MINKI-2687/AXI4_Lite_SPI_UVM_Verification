`ifndef AXI_WRITE_SEQ_SV
`define AXI_WRITE_SEQ_SV

class axi_write_seq extends uvm_sequence #(axi_seq_item);
    `uvm_object_utils(axi_write_seq)

    function new(string name = "axi_write_seq");
        super.new(name);
    endfunction

    virtual task body();
        axi_seq_item req;

        `uvm_info("SEQ", "Starting AXI Write Sequence...", UVM_LOW)

        req = axi_seq_item::type_id::create("req");

        start_item(req);

        if (!req.randomize() with {
            dir == axi_seq_item::WRITE;
            addr == 4'h4;
        }) begin
            `uvm_error("SEQ", "Randomization failed!")
        end

        `uvm_info("SEQ", $sformatf("Sending Item: ADDR=0x%0h, DATA=0x%0h",
            req.addr, req.data), UVM_LOW)

        finish_item(req);

        `uvm_info("SEQ", "AXI Write Sequence Completed.", UVM_LOW)
    endtask
endclass

`endif

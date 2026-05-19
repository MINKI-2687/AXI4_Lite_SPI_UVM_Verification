class spi_dummy_seq extends uvm_sequence #(spi_seq_item);
    `uvm_object_utils(spi_dummy_seq)
    function new(string name="spi_dummy_seq"); super.new(name); endfunction

    virtual task body();
        forever begin // 테스트가 끝날 때까지 영원히 동작
            spi_seq_item req = spi_seq_item::type_id::create("req");
            start_item(req);
            // MISO 데이터를 무작위로 생성
            if(!req.randomize()) `uvm_fatal("SEQ", "SPI Rand Fail")
            finish_item(req);
        end
    endtask
endclass

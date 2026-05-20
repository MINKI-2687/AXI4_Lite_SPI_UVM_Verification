`ifndef SPI_SEQ_ITEM_SV
    `define SPI_SEQ_ITEM_SV

    class spi_seq_item extends uvm_sequence_item;
        `uvm_object_utils(spi_seq_item)

        // 모니터가 MOSI 핀에서 읽어들일 데이터
        bit [7:0] mosi_data;

        // 읽기 테스트 시, 드라이버가 MISO 핀으로 쏴줄 가짜 센서 데이터
        rand bit [7:0] miso_data;

        constraint miso_data_c {
            miso_data dist {
                8'h00 := 10,  // 00이 나올 가중치 10
                8'hFF := 10,  // FF가 나올 가중치 10
                8'h55 := 10,  // 55가 나올 가중치 10
                8'hAA := 10,  // AA가 나올 가중치 10
                [8'h01:8'hFE] :/ 60  // 나머지 254개 일반 숫자들은 다 합쳐서 가중치 60
            };
        }

        function new(string name = "spi_seq_item");
            super.new(name);
        endfunction
    endclass

`endif

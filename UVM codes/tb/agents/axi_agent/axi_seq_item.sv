`ifndef AXI_SEQ_ITEM_SV
    `define AXI_SEQ_ITEM_SV

    class axi_seq_item extends uvm_sequence_item;
        `uvm_object_utils(axi_seq_item)

        typedef enum {READ, WRITE} kind_e;
        rand kind_e dir;

        rand bit [3:0]  addr;
        rand bit [31:0] data;

        bit [31:0] rdata;
        bit [1:0]  resp;

        constraint addr_c {
            addr inside {4'h0, 4'h4, 4'h8, 4'hC};
        }

        constraint data_c {
            if (dir == WRITE && addr == 4'h4) {
                data[31] == 1'b1; // Start 비트 1 강제

                data[7:0] dist {
                    8'h00 := 10,  // 00이 나올 가중치 10
                    8'hFF := 10,  // FF가 나올 가중치 10
                    8'h55 := 10,  // 55가 나올 가중치 10
                    8'hAA := 10,  // AA가 나올 가중치 10
                    [8'h01:8'hFE] :/ 60  // 나머지 254개 숫자들은 다 합쳐서 가중치 60
                };
            }
        }
        function new(string name = "axi_seq_item");
            super.new(name);
        endfunction
    endclass

`endif

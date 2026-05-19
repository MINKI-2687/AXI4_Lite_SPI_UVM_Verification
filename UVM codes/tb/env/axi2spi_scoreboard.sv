`ifndef AXI2SPI_SCOREBOARD_SV
    `define AXI2SPI_SCOREBOARD_SV

    class axi2spi_scoreboard extends uvm_scoreboard;
        `uvm_component_utils(axi2spi_scoreboard)

        // AXI와 SPI의 속도 차이(100MHz vs 1MHz)를 극복하기 위한 버퍼(FIFO)
        uvm_tlm_analysis_fifo #(axi_seq_item) axi_fifo;
        uvm_tlm_analysis_fifo #(spi_seq_item) spi_fifo;

        int pass_cnt = 0;
        int fail_cnt = 0;

        function new(string name = "axi2spi_scoreboard", uvm_component parent);
            super.new(name, parent);
        endfunction

        virtual function void build_phase(uvm_phase phase);
            super.build_phase(phase);
            axi_fifo = new("axi_fifo", this);
            spi_fifo = new("spi_fifo", this);
        endfunction

        virtual task run_phase(uvm_phase phase);
            axi_seq_item a_item;
            spi_seq_item s_item;

            // SPI 가짜 센서가 보내준 MISO 데이터를 잠시 기억해 둘 변수
            bit [7:0] expected_rdata;

            forever begin
                // 1. AXI 쪽에서 데이터가 들어올 때까지 대기
                axi_fifo.get(a_item);

                //  AXI WRITE 동작일 때 (TX 레지스터 0x4)
                if (a_item.dir == axi_seq_item::WRITE && a_item.addr == 4'h4) begin

                    // 쓰기 동작은 SPI 통신을 유발하므로, SPI FIFO에서 데이터를 꺼냄
                    spi_fifo.get(s_item);

                    // 1) Write 비교: AXI가 보낸 데이터 vs SPI가 내뿜은 MOSI 데이터
                    if (a_item.data[7:0] == s_item.mosi_data) begin
                        pass_cnt++;
                        `uvm_info("SCB",
                            $sformatf("[PASS] WRITE: AXI(0x%0h) == SPI_MOSI(0x%0h)",
                                a_item.data[7:0], s_item.mosi_data), UVM_NONE)
                    end else begin
                        fail_cnt++;
                        `uvm_error("SCB",
                            $sformatf("[FAIL] WRITE: AXI(0x%0h) != SPI_MOSI(0x%0h)",
                                a_item.data[7:0], s_item.mosi_data))
                    end

                    // 2) Read를 위한 준비: SPI가 이때 뱉어준 MISO 데이터를 기억
                    expected_rdata = s_item.miso_data;
                end

                // AXI READ 동작일 때 (RX 레지스터 0x8)
                else if (a_item.dir == axi_seq_item::READ && a_item.addr == 4'h8) begin

                    if (a_item.rdata[9] == 1'b1) begin
                        `uvm_info("SCB", "Waiting for SPI to finish (busy=1)...", UVM_HIGH)
                    end else begin
                        // 3) Read 비교: AXI가 읽어온 데이터 vs 아까 기억해 둔 MISO 데이터
                        if (a_item.rdata[7:0] == expected_rdata) begin
                            pass_cnt++;
                            `uvm_info("SCB",
                                $sformatf("[PASS] READ : AXI_RX(0x%0h) == Expected_MISO(0x%0h)",
                                    a_item.rdata[7:0], expected_rdata), UVM_NONE)
                        end else begin
                            fail_cnt++;
                            `uvm_error("SCB",
                                $sformatf("[FAIL] READ : AXI_RX(0x%0h) != Expected_MISO(0x%0h)",
                                    a_item.rdata[7:0], expected_rdata))
                        end
                    end
                end
            end
        endtask

        // 2. Report Phase 추가 (시뮬레이션 종료 시 출력)
        virtual function void report_phase(uvm_phase phase);
            super.report_phase(phase);
            `uvm_info("SCB", "\n=======================================", UVM_NONE)
            `uvm_info("SCB", "===== AXI2SPI Scoreboard Summary =====", UVM_NONE)
            `uvm_info("SCB", $sformatf("  Total checks : %0d", pass_cnt + fail_cnt), UVM_NONE)
            `uvm_info("SCB", $sformatf("  Pass         : %0d", pass_cnt), UVM_NONE)
            `uvm_info("SCB", $sformatf("  Fail         : %0d", fail_cnt), UVM_NONE)
            `uvm_info("SCB", "=======================================\n", UVM_NONE)

            if (fail_cnt > 0) `uvm_error("SCB", "TEST FAILED!")
            else              `uvm_info("SCB", "TEST PASSED!", UVM_NONE)
        endfunction
    endclass

`endif

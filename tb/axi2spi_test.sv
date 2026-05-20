`ifndef AXI2SPI_TEST_SV
    `define AXI2SPI_TEST_SV

    class axi2spi_test extends uvm_test;
        `uvm_component_utils(axi2spi_test)

        axi2spi_env env;

        function new(string name = "axi2spi_test", uvm_component parent);
            super.new(name, parent);
        endfunction

        // 1단계: 검증 환경(Env) 생성
        virtual function void build_phase(uvm_phase phase);
            super.build_phase(phase);
            env = axi2spi_env::type_id::create("env", this);
        endfunction

        // 2단계: 실제 시나리오 실행
        virtual task run_phase(uvm_phase phase);
            // 실행할 시퀀스 선언
            //axi_write_seq seq;
            //seq = axi_write_seq::type_id::create("seq");
            //axi_read_seq seq;
            //seq = axi_read_seq::type_id::create("seq");
            //axi_write_read_seq seq;
            //seq = axi_write_read_seq::type_id::create("seq");
            axi_random_loop_seq axi_seq;
            spi_dummy_seq       spi_seq;

            axi_seq = axi_random_loop_seq::type_id::create("axi_seq");
            spi_seq = spi_dummy_seq::type_id::create("spi_seq");


            // 시뮬레이션 종료 방지 (Objection Raise)
            phase.raise_objection(this);

            `uvm_info("TEST", "Starting AXI to SPI Protocol Translation Test", UVM_LOW)

            fork
                spi_seq.start(env.m_spi_agent.sequencer);
            join_none

            // 하드웨어 리셋 기간 동안 잠시 대기
            #100;
            axi_seq.start(env.m_axi_agent.sequencer);
            #1000;
            phase.drop_objection(this);
        endtask
    endclass

`endif

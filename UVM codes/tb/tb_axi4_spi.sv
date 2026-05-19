`timescale 1ns / 1ps
`include "uvm_macros.svh"
import uvm_pkg::*;
import test_pkg::*;

module tb_axi4_spi;

    // 1. 전역 신호 선언 (Clock & Reset)
    logic clk;
    logic reset_n;

    // 2. 인터페이스 인스턴스화
    axi_if #(4, 32) vif_axi (.clk(clk), .reset_n(reset_n));
    spi_if          vif_spi ();

    // 3. DUT (Design Under Test) 인스턴스화 및 핀 맵핑
    SPI_Master_v1_0 #(
        .C_S00_AXI_DATA_WIDTH(32),
        .C_S00_AXI_ADDR_WIDTH(4)
    ) dut (
        // Global Signals
        .s00_axi_aclk    (clk),
        .s00_axi_aresetn (reset_n),
        // AXI AW Channel
        .s00_axi_awaddr  (vif_axi.awaddr),
        .s00_axi_awprot  (vif_axi.awprot),
        .s00_axi_awvalid (vif_axi.awvalid),
        .s00_axi_awready (vif_axi.awready),
        // AXI W Channel
        .s00_axi_wdata   (vif_axi.wdata),
        .s00_axi_wstrb   (vif_axi.wstrb),
        .s00_axi_wvalid  (vif_axi.wvalid),
        .s00_axi_wready  (vif_axi.wready),
        // AXI B Channel
        .s00_axi_bresp   (vif_axi.bresp),
        .s00_axi_bvalid  (vif_axi.bvalid),
        .s00_axi_bready  (vif_axi.bready),
        // AXI AR Channel
        .s00_axi_araddr  (vif_axi.araddr),
        .s00_axi_arprot  (vif_axi.arprot),
        .s00_axi_arvalid (vif_axi.arvalid),
        .s00_axi_arready (vif_axi.arready),
        // AXI R Channel
        .s00_axi_rdata   (vif_axi.rdata),
        .s00_axi_rresp   (vif_axi.rresp),
        .s00_axi_rvalid  (vif_axi.rvalid),
        .s00_axi_rready  (vif_axi.rready),
        // SPI Physical Ports
        .sclk            (vif_spi.sclk),
        .mosi            (vif_spi.mosi),
        .miso            (vif_spi.miso),
        .cs_n            (vif_spi.cs_n)
    );
    // 4. 클럭(Clock) 및 리셋(Reset) 생성 로직
    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    initial begin
        reset_n = 1'b0;
        #25;
        reset_n = 1'b1;
    end
    // 5. UVM Config DB 등록 및 디버깅용 파형 덤프
    initial begin
        uvm_config_db#(virtual axi_if)::set(null, "*", "vif_axi", vif_axi);
        uvm_config_db#(virtual spi_if)::set(null, "*", "vif_spi", vif_spi);
        $fsdbDumpfile("novas.fsdb");
        $fsdbDumpvars(0, tb_axi4_spi);
        run_test("axi2spi_test");
    end
endmodule

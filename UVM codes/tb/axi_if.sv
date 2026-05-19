interface axi_if #(
    parameter ADDR_WIDTH = 4,
    parameter DATA_WIDTH = 32
) (
    input logic clk,
    input logic reset_n
);
    // 1. Write Address Channel (AW)
    logic [ADDR_WIDTH-1:0] awaddr;
    logic [2:0]            awprot;
    logic                  awvalid;
    logic                  awready;
    // 2. Write Data Channel (W)
    logic [DATA_WIDTH-1:0] wdata;
    logic [(DATA_WIDTH/8)-1:0] wstrb;
    logic                     wvalid;
    logic wready;
    // 3. Write Response Channel (B)
    logic [1:0] bresp;
    logic bvalid;
    logic bready;
    // 4. Read Address Channel (AR)
    logic [ADDR_WIDTH-1:0] araddr;
    logic [2:0] arprot;
    logic arvalid;
    logic arready;
    // 5. Read Data Channel (R)
    logic [DATA_WIDTH-1:0] rdata;
    logic [1:0] rresp;
    logic rvalid;
    logic rready;
endinterface

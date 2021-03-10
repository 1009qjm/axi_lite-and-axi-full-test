`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/03/10 10:05:58
// Design Name: 
// Module Name: top
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module top(
input logic ACLK,
input logic ARESETn,
//写地址通道
input logic axilite_AWVALID,
input logic [31:0] axilite_AWADDR, 
input logic [2:0] axilite_AWPROT, 
output logic axilite_AWREADY,
//写数据通道
input logic axilite_WVALID,
input logic [31:0] axilite_WDATA, 
input logic [3:0] axilite_WSTRB,
output logic axilite_WREADY,
//写响应通道
input logic axilite_BREADY,
output logic axilite_BVALID,
output logic [1:0] axilite_BRESP,
//读地址通道
input logic axilite_ARVALID,
input logic [31:0] axilite_ARADDR, 
input logic [2:0] axilite_ARPROT, 
output logic axilite_ARREADY,
//读数据通道
input logic axilite_RREADY,
output logic axilite_RVALID,
output logic [31:0] axilite_RDATA, 
output logic [1:0] axilite_RRESP,
//其他
output logic busy,                           //主机往从机写数据时，busy为高，直至数据被写入寄存器
/****************************************************************************************************************************************/
//AXI FULL MASTER
//写地址通道信号
output logic axifull_AWVALID,           
output logic [31:0] axifull_AWADDR,
output logic [7:0] axifull_AWLEN,
output logic axifull_AWID,              //dont care
output logic [2:0] axifull_AWSIZE,            //dont care
output logic [1:0] axifull_AWBURST,           //dont care
output logic axifull_AWLOCK,            //dont care
output logic [3:0] axifull_AWCACHE,           //dont care
output logic [2:0] axifull_AWPROT,            //dont care
output logic [3:0] axifull_AWQOS,             //dont care
output logic axifull_AWUSER,            //dont care
input logic axifull_AWREADY,
//写数据通道信号
output logic [63:0] axifull_WDATA,
output logic [7:0] axifull_WSTRB,
output logic axifull_WLAST,
output logic axifull_WUSER,             //dont care
output logic axifull_WVALID,
input logic axifull_WREADY,
//写应答通道信号
output logic axifull_BREADY,
input logic axifull_BID,                //dont care
input logic [1:0] axifull_BRESP,
input logic axifull_BUSER,              //dont care
input logic axifull_BVALID,
//读地址通道信号
output logic axifull_ARID,               //dont care
output logic [31:0] axifull_ARADDR,
output logic [7:0] axifull_ARLEN,
output logic [2:0] axifull_ARSIZE,            //dont care
output logic [1:0] axifull_ARBURST,           //dont care
output logic axifull_ARLOCK,            //dont care
output logic [3:0] axifull_ARCACHE,           //dont care
output logic [2:0] axifull_ARPROT,            //dont care
output logic [3:0] axifull_ARQOS,             //dont care
output logic axifull_ARUSER,            //done care
output logic axifull_ARVALID,       
input logic axifull_ARREADY,
//读数据通道
output logic axifull_RREADY,
input logic axifull_RID,                //dont care
input logic [63:0] axifull_RDATA,   
input logic [1:0] axifull_RRESP,              //dont care   
input logic axifull_RLAST,          
input logic axifull_RUSER,              //dont care
input logic axifull_RVALID,
//其他
output logic done
);

logic [31:0] rd_base_addr;
logic [31:0] wr_base_addr;
logic [31:0] start_signal;
logic [31:0] start_signal_ff;
logic [31:0] done_signal;
logic start;

//start
always_ff@(posedge ACLK,negedge ARESETn)
if(!ARESETn)
    start<=0;
else if(start_signal[0]&&~start_signal_ff[0])          //上升沿
    start<=1;
else 
    start<=0;
//start_signnal_ff
always_ff@(posedge ACLK,negedge ARESETn)
if(!ARESETn)
    start_signal_ff<=0;
else 
    start_signal_ff<=start_signal;
//例化
axi_lite_slave U(   //AXI Lite从机
//全局信号
.ACLK(ACLK),
.ARESETn(ARESETn),
//写地址通道
.AWVALID(axilite_AWVALID),
.AWADDR(axilite_AWADDR), 
.AWPROT(axilite_AWPROT), 
.AWREADY(axilite_AWREADY),
//写数据通道
.WVALID(axilite_WVALID),
.WDATA(axilite_WDATA), 
.WSTRB(axilite_WSTRB),
.WREADY(axilite_WREADY),
//写响应通道
.BREADY(axilite_BREADY),
.BVALID(axilite_BVALID),
.BRESP(axilite_BRESP),
//读地址通道
.ARVALID(axilite_ARVALID),
.ARADDR(axilite_ARADDR), 
.ARPROT(axilite_ARPROT), 
.ARREADY(axilite_ARREADY),
//读数据通道
.RREADY(axilite_RREADY),
.RVALID(axilite_RVALID),
.RDATA(axilite_RDATA), 
.RRESP(axilite_RRESP),
//其他
.rd_base_addr(rd_base_addr),
.wr_base_addr(wr_base_addr),
.done_signal(done_signal),
.start_signal(start_signal),
.busy(busy)                      //主机往从机写数据时，busy为高，直至数据被写入寄存器
);
//************************************************************************************************************//
axi_full_master V(
//全局信号
.ACLK(ACLK),
.ARESETn(ARESETn),
//写地址通道信号
.AWVALID(axifull_AWVALID),           
.AWADDR(axifull_AWADDR),
.AWLEN(axifull_AWLEN),
.AWID(axifull_AWID),              //dont care
.AWSIZE(axifull_AWSIZE),       //dont care
.AWBURST(axifull_AWBURST),      //dont care
.AWLOCK(axifull_AWLOCK),            //dont care
.AWCACHE(axifull_AWCACHE),      //dont care
.AWPROT(axifull_AWPROT),       //dont care
.AWQOS(axifull_AWQOS),        //dont care
.AWUSER(axifull_AWUSER),            //dont care
.AWREADY(axifull_AWREADY),
//写数据通道信号
.WDATA(axifull_WDATA),
.WSTRB(axifull_WSTRB),
.WLAST(axifull_WLAST),
.WUSER(axifull_WUSER),             //dont care
.WVALID(axifull_WVALID),
.WREADY(axifull_WREADY),
//写应答通道信号
.BREADY(axifull_BREADY),
.BID(axifull_BID),                //dont care
.BRESP(axifull_BRESP),
.BUSER(axifull_BUSER),              //dont care
.BVALID(axifull_BVALID),
//读地址通道信号
.ARID(axifull_ARID),              //dont care
.ARADDR(axifull_ARADDR),
.ARLEN(axifull_ARLEN),
.ARSIZE(axifull_ARSIZE),       //dont care
.ARBURST(axifull_ARBURST),      //dont care
.ARLOCK(axifull_ARLOCK),       //dont care
.ARCACHE(axifull_ARCACHE),      //dont care
.ARPROT(axifull_ARPROT),       //dont care
.ARQOS(axifull_ARQOS),        //dont care
.ARUSER(axifull_ARUSER),            //done care
.ARVALID(axifull_ARVALID),       
.ARREADY(axifull_ARREADY),
//读数据通道
.RREADY(axifull_RREADY),
.RID(axifull_RID),                //dont care
.RDATA(axifull_RDATA),   
.RRESP(axifull_RRESP),         //dont care   
.RLAST(axifull_RLAST),          
.RUSER(axifull_RUSER),              //dont care
.RVALID(axifull_RVALID),
//其他
.start(start),
.wr_base_addr(wr_base_addr),
.rd_base_addr(rd_base_addr),
.done(done)
);
endmodule

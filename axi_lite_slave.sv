`timescale 1ns / 1ps
//
// Company: 
// Engineer: 
// 
// Create Date: 2021/03/08 22:32:21
// Design Name: 
// Module Name: axi_lite_slave
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
//


module axi_lite_slave(   //AXI Lite从机
//全局信号
input logic ACLK,
input logic ARESETn,
//写地址通道
input logic AWVALID,
input logic [31:0]AWADDR, 
input logic [2:0]AWPROT, 
output logic AWREADY,
//写数据通道
input logic WVALID,
input logic [31:0] WDATA, 
input logic [3:0] WSTRB,
output logic WREADY,
//写响应通道
input logic BREADY,
output logic BVALID,
output logic [1:0] BRESP,
//读地址通道
input logic ARVALID,
input logic [31:0] ARADDR, 
input logic [2:0] ARPROT, 
output logic ARREADY,
//读数据通道
input logic RREADY,
output logic RVALID,
output logic [31:0] RDATA, 
output logic [1:0] RRESP,
//其他
output logic [31:0] rd_base_addr,
output logic [31:0] wr_base_addr,
output logic [31:0] done_signal,
output logic [31:0] start_signal,
output logic busy                      //主机往从机写数据时，busy为高，直至数据被写入寄存器
    );

parameter N=4;                         //四个寄存器

logic [31:0] DataReg [0:N-1];              //DataReg 0存放start信号,1存放done信号,2存放写起始地址,3存放读起始地址

logic [31:0]rd_addr;             
logic [31:0]wr_addr;
logic [31:0]rd_data;
logic [31:0]wr_data;
logic [1:0] wr_reg_sel;
logic [1:0] rd_reg_sel;
logic wr_en;

assign wr_reg_sel=wr_addr[3:2];
assign rd_reg_sel=rd_addr[3:2];

assign rd_base_addr=DataReg[3];
assign wr_base_addr=DataReg[2];
assign start_signal=DataReg[0];
assign done_signal=DataReg[1]; 

//初始化寄存器
initial 
begin
    for(int i=0;i<N;i++)
        DataReg[i]=0;    
end
//wr_en
always_ff@(posedge ACLK,negedge ARESETn)
if(!ARESETn)
    wr_en<=0;
else if(WVALID&&WREADY&&AWVALID&&AWREADY)
    wr_en<=1;                            //此时写数据地址和写数据均被暂存，可以进行写入
else 
    wr_en<=0;
//busy
always_ff@(posedge ACLK,negedge ARESETn)
if(!ARESETn)
    busy<=0;
else if(AWVALID||WVALID)
    busy<=1;
else if(wr_en)
    busy<=0;
//响应来自主机的写请求
//写地址通道
//AWREADY
always_ff@(posedge ACLK,negedge ARESETn)
if(!ARESETn)
    AWREADY<=0;
else if(AWVALID&&WVALID&&~AWREADY)                        //写地址和写数据均有效时才拉高
    AWREADY<=1;
else if(AWVALID&&AWREADY&&WVALID)                         //写地址通道数据传输结束
    AWREADY<=0;
//wr_addr
always_ff@(posedge ACLK,negedge ARESETn)
if(!ARESETn)
    wr_addr<=0;
else if(AWVALID&&AWREADY)
    wr_addr<=AWADDR;
//写数据通道
//wr_data
always_ff@(posedge ACLK,negedge ARESETn)
if(!ARESETn)
    wr_data<=0;
else if(WVALID&&WREADY)
    wr_data<=WDATA;
//WREADY
always_ff@(posedge ACLK,negedge ARESETn)
if(!ARESETn)
    WREADY<=0;
else if(WVALID&&AWVALID&&~WREADY)
    WREADY<=1;
else if(WVALID&&WREADY&&AWVALID)
    WREADY<=0;
//将数据写入寄存器
always_ff@(posedge ACLK)
if(wr_en)
    DataReg[wr_reg_sel]<=wr_data;
//写响应通道
//BVALID
always_ff@(posedge ACLK,negedge ARESETn)
if(!ARESETn)
    BVALID<=0;
else if(WVALID&&WREADY)
    BVALID<=1;
else if(BVALID&&BREADY&&BRESP==2'b00)
    BVALID<=0;
//BRESP
always_comb 
begin
    BRESP=2'b00;                      //OKEY    
end
//响应来自主机的读请求
//读地址通道
//ARREADY
always_ff@(posedge ACLK,negedge ARESETn)
if(!ARESETn)
    ARREADY<=0;
else if(ARVALID&&~ARREADY)
    ARREADY<=1;
else if(ARVALID&&ARREADY)         //读地址通道数据接受完毕
    ARREADY<=0;
//rd_addr
always_ff@(posedge ACLK,negedge ARESETn)
if(!ARESETn)
    rd_addr<=0;
else if(ARVALID&&ARREADY)           //数据有效，存储地址
    rd_addr<=ARADDR;
//读数据通道
//RVALID
always_ff@(posedge ACLK,negedge ARESETn)
if(!ARESETn)
    RVALID<=0;
else if(ARREADY&&ARVALID)                //读地址通道结束，拉高RVALID发送数据
    RVALID<=1;
else if(RVALID&&RREADY)                  //数据发送完毕
    RVALID<=0;
//RRESP
always_comb
begin
    RRESP=2'b00;
end
//RDATA
always_comb 
begin
    if(RVALID)
        RDATA=DataReg[rd_reg_sel];
    else
        RDATA=32'd0;    
end
endmodule


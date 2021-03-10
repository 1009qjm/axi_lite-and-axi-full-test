`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/03/08 15:26:05
// Design Name: 
// Module Name: PL_DDR_Test
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

/*
本程序功能为:从start_addr地址开始处连续读取32个数据至buffer，然后分别将其加1，写回原地址处
*/

module axi_full_master(
//全局信号
input logic ACLK,
input logic ARESETn,
//写地址通道信号
output logic AWVALID,           
output logic [31:0]AWADDR,
output logic [7:0]AWLEN,
output logic AWID,              //dont care
output logic [2:0]AWSIZE,       //dont care
output logic [1:0]AWBURST,      //dont care
output logic AWLOCK,            //dont care
output logic [3:0]AWCACHE,      //dont care
output logic [2:0]AWPROT,       //dont care
output logic [3:0]AWQOS,        //dont care
output logic AWUSER,            //dont care
input logic AWREADY,
//写数据通道信号
output logic [63:0]WDATA,
output logic [7:0]WSTRB,
output logic WLAST,
output logic WUSER,             //dont care
output logic WVALID,
input logic WREADY,
//写应答通道信号
output logic BREADY,
input logic BID,                //dont care
input logic [1:0]BRESP,
input logic BUSER,              //dont care
input logic BVALID,
//读地址通道信号
output logic ARID,              //dont care
output logic [31:0]ARADDR,
output logic [7:0]ARLEN,
output logic [2:0]ARSIZE,       //dont care
output logic [1:0]ARBURST,      //dont care
output logic ARLOCK,            //dont care
output logic [3:0]ARCACHE,      //dont care
output logic [2:0]ARPROT,       //dont care
output logic [3:0]ARQOS,        //dont care
output logic ARUSER,            //done care
output logic ARVALID,       
input logic ARREADY,
//读数据通道
output logic RREADY,
input logic RID,                //dont care
input logic [63:0]RDATA,   
input logic [1:0]RRESP,         //dont care   
input logic RLAST,          
input logic RUSER,              //dont care
input logic RVALID,
//其他
input logic start,
input logic [31:0] wr_base_addr,
input logic [31:0] rd_base_addr,
output logic done
    );

assign AWID = 1'b0;
assign AWSIZE  = 3'b011;
assign AWBURST = 2'b01;
assign AWLOCK  = 1'b0;
assign AWCACHE = 4'b0011;
assign AWPROT = 3'b000;
assign AWQOS = 4'b0000;
assign AWUSER = 1'b1;
assign WUSER = 1'b1;

assign ARID = 1'b0;
assign ARSIZE = 3'b011;
assign ARBURST = 2'b01;
assign ARLOCK = 1'b0;
assign ARCACHE = 4'b0011;
assign ARPROT = 3'b000;
assign ARQOS = 4'b0000;
assign ARUSER = 1'b1;

//计数器
logic [9:0]wr_cnt;
logic [9:0]rd_cnt;
//中间信号
logic rd_done;
logic wr_done;
logic read_start;
logic write_start;
//与PS交互的信号
logic test_start;                   //start
logic test_done;                    //done
logic [31:0] rd_base_addr_r;        //rd_base_addr
logic [31:0] wr_base_addr_r;        //wr_base_addr
//固定
logic [9:0] test_len;            //=31,即突发传输长度32
logic [63:0] data_buffer [0:31];

enum {IDLE,READ,WRITE,DONE} State,NextState;
//*************************************************************************//
//test_len
always_ff@(posedge ACLK,negedge ARESETn)
if(!ARESETn)
    test_len<=31;
//test_start
always_ff@(posedge ACLK,negedge ARESETn)
if(!ARESETn)
    test_start<=0;
else
    test_start<=start;
//wr_base_addr_r
always_ff@(posedge ACLK,negedge ARESETn)
if(!ARESETn)
    wr_base_addr_r<=0;
else
    wr_base_addr_r<=wr_base_addr;
//rd_base_addr_r
always_ff@(posedge ACLK,negedge ARESETn)
if(!ARESETn)
    rd_base_addr_r<=0;
else
    rd_base_addr_r<=rd_base_addr;
//done
always_ff@(posedge ACLK,negedge ARESETn)
if(!ARESETn)
    done<=0;
else 
    done<=test_done;
//***********************************************************************//
//FSM
always_ff@(posedge ACLK,negedge ARESETn)
begin
    if(!ARESETn)
        State<=IDLE;
    else
        State<=NextState;
end
//FSM
always@(*)
case(State)
    IDLE:if(test_start)
             NextState=READ;
         else
             NextState=IDLE;
    READ:if(rd_done)
             NextState=WRITE;
         else
             NextState=READ;
    WRITE:if(wr_done)
             NextState=DONE;
          else
             NextState=WRITE;
    DONE:NextState=IDLE;
    default:NextState=IDLE;
endcase
//读地址通道
always_comb
   read_start=test_start;
//ARVALID
always_ff@(posedge ACLK,negedge ARESETn)
if(!ARESETn)
    ARVALID<=1'b0;
else if(NextState==READ&&read_start)                      //read_start为一个宽一个周期的脉冲
    ARVALID<=1'b1;
else if(ARVALID==1'b1&&ARREADY==1'b1)                     //读通道数据传输完成
    ARVALID<=1'b0;
//ARADDR
always_ff@(posedge ACLK,negedge ARESETn)
if(!ARESETn)
    ARADDR<=32'd0;
else if(NextState==READ&&read_start)
    ARADDR<=rd_base_addr_r;
//ARLEN
always_ff@(posedge ACLK,negedge ARESETn)
if(!ARESETn)
   ARLEN<=8'd0;
else if(NextState==READ&&read_start)
   ARLEN<=test_len;
//读数据通道
//rd_cnt
always_ff@(posedge ACLK,negedge ARESETn)
if(!ARESETn)
    rd_cnt<=10'd0;
else if(RVALID&&RREADY)      //完成一个数据的读取，计数器加1
    if(RLAST)
        rd_cnt<=0;
    else
        rd_cnt<=rd_cnt+1'b1;
//data_buffer
always_ff@(posedge ACLK,negedge ARESETn)
if(!ARESETn)
    for(int i=0;i<32;i++)
        data_buffer[i]<=32'd0;
else if(RVALID&&RREADY)
    data_buffer[rd_cnt]<=RDATA;
//RREADY
always_ff@(posedge ACLK,negedge ARESETn)
if(!ARESETn)
    RREADY<=0;
else if(RVALID&&~RREADY)
    RREADY<=1;
else if(RVALID&&RREADY&&RLAST)                       //最后一个数据读取完成
    RREADY<=0;
//rd_done
always_ff@(posedge ACLK,negedge ARESETn)
if(!ARESETn)
    rd_done<=0;
else if(RLAST)
    rd_done<=1;
else 
    rd_done<=0;
//写地址通道
//write_start
always_comb 
begin
    write_start=rd_done;    
end
//AWVALID
always_ff@(posedge ACLK,negedge ARESETn)
if(!ARESETn)
   AWVALID<=0;
else if(NextState==WRITE&&write_start)
   AWVALID<=1;
else if(AWVALID&&AWREADY)                         //写地址通道传输完成
   AWVALID<=0;
//AWADDR
always_ff@(posedge ACLK,negedge ARESETn)
if(!ARESETn)
   AWADDR<=32'd0;
else if(NextState==WRITE&&write_start)
   AWADDR<=wr_base_addr_r;
//AWLEN
always_ff@(posedge ACLK,negedge ARESETn)
if(!ARESETn)
   AWLEN<=8'd0;
else if(NextState==WRITE&&write_start)
   AWLEN<=test_len;                                      //写突发传输长度为32
//写数据通道
//wr_cnt
always_ff@(posedge ACLK,negedge ARESETn)
if(!ARESETn)
    wr_cnt<=10'd0;
else if(WVALID&&WREADY)                         //完成一个数据的写入，计数器加1
    if(WLAST)
        wr_cnt<=0;
    else
        wr_cnt<=wr_cnt+1;
//WVALID
always_ff@(posedge ACLK,negedge ARESETn)
if(!ARESETn)
    WVALID<=0;
else if(AWVALID&&AWREADY)                      //写地址通道传输完成，开始写数据
    WVALID<=1;
else if(WLAST&&WVALID&&WREADY)                 //最后一个数据传输完成
    WVALID<=0;
//WSTRB
always_ff@(posedge ACLK,negedge ARESETn)                  //
if(!ARESETn)
    WSTRB<=8'd0;
else if(AWVALID&&AWREADY)                
    WSTRB<=8'hff;
//WDATA
always_comb 
begin
   if(WVALID&&WREADY)                                  //此时写入数据有效
       WDATA=data_buffer[wr_cnt]+1;    
   else
       WDATA=0;
end
//WLAST
always_ff@(posedge ACLK,negedge ARESETn)
if(!ARESETn)
   WLAST<=0;
else if(wr_cnt==test_len-1&&WVALID&&WREADY)                           //31-1=30
   WLAST<=1;
else if(WLAST&&WVALID&&WREADY)                                        //写数据结束
   WLAST<=0;
//写响应通道
//BREAY
always_ff@(posedge ACLK,negedge ARESETn)
if(!ARESETn)
   BREADY<=0;
else if(AWVALID&&AWREADY)
   BREADY<=1;
else if(BVALID&&BRESP==2'b00)                      //BRESP=OKEY
   BREADY<=0;
//wr_done
always_comb 
begin
    if(BREADY&&BVALID&&BRESP==2'b00)
        wr_done=1;
    else
        wr_done=0;    
end
//test_done
always_comb
    test_done=wr_done;

endmodule

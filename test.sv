`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/03/09 22:20:51
// Design Name: 
// Module Name: test
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


module test;
logic ACLK;
logic ARESETn;
//AXI Lite信号定义
//写地址通道
logic axilite_AWVALID;
logic [31:0] axilite_AWADDR; 
logic [2:0] axilite_AWPROT; 
logic axilite_AWREADY;
//写数据通道
logic axilite_WVALID;
logic [31:0] axilite_WDATA; 
logic [3:0] axilite_WSTRB;
logic axilite_WREADY;
//写响应通道
logic axilite_BREADY;
logic axilite_BVALID;
logic [1:0] axilite_BRESP;
//读地址通道
logic axilite_ARVALID;
logic [31:0] axilite_ARADDR; 
logic [2:0] axilite_ARPROT; 
logic axilite_ARREADY;
//读数据通道
logic axilite_RREADY;
logic axilite_RVALID;
logic [31:0] axilite_RDATA; 
logic [1:0] axilite_RRESP;
//AXI Full信号定义
//写地址通道
logic axifull_AWVALID;
logic axifull_AWID;
logic [2:0] axifull_AWSIZE;
logic axifull_AWUSER;
logic [3:0]axifull_AWCACHE;
logic [1:0]axifull_AWBURST;
logic axifull_AWLOCK;
logic [2:0] axifull_AWPROT;
logic [3:0] axifull_AWQOS;
logic [31:0] axifull_AWADDR;
logic [7:0] axifull_AWLEN;                  //突发传输长度，实际长度为AWLEN+1
logic axifull_AWREADY;
//写数据通道
logic axifull_WUSER;
logic [63:0] axifull_WDATA;
logic axifull_WVALID;
logic [7:0] axifull_WSTRB;                //dont care
logic axifull_WLAST;
logic axifull_WREADY;
//写响应通道
logic axifull_BID;
logic axifull_BUSER;
logic axifull_BVALID;
logic axifull_BREADY;
logic [1:0] axifull_BRESP;
//读数据通道
logic axifull_ARID;
logic [2:0] axifull_ARSIZE;
logic axifull_ARUSER;
logic [3:0]axifull_ARCACHE;
logic [1:0]axifull_ARBURST;
logic axifull_ARLOCK;
logic [2:0] axifull_ARPROT;
logic [3:0] axifull_ARQOS;
logic [63:0] axifull_RDATA;
logic axifull_RVALID;
logic axifull_RREADY;
logic axifull_RLAST;
//读地址通道
logic axifull_RID;
logic axifull_RUSER;
logic [1:0] axifull_RRESP;
logic [31:0] axifull_ARADDR;
logic [7:0] axifull_ARLEN;
logic axifull_ARVALID;
logic axifull_ARREADY;
//
logic busy;
logic done;
//
logic start_config;                          //配置读起始地址、写起始地址，最后写start信号
logic test_done;                             //表明一次测试完成

logic [63:0] mem [0:1023];                   //模拟DDR
logic [31:0] rd_base_addr;                   //本次测试的读起始地址,写入axilite_slave
logic [31:0] wr_base_addr;                   //本次测试的写起始地址,写入axilite_salve
logic [31:0] start_signal;                   //本次测试的开始信号,写入axilite_slave
logic [31:0] done_signal;                    //本次测试的结束信号,从axilite_slave读取

logic write_rd_addr_done;                    //配置读起始地址完毕
logic write_wr_addr_done;                    //配置写起始地址完毕
logic write_start_done;                      //配置开始信号完毕
logic [9:0]count;                            //计数器,以区分当前是在配置什么寄存器

logic [31:0] wr_addr;                       //axifull从机接受主机的写请求，锁存写起始地址
logic [31:0] rd_addr;                       //axifull从机接受主机的读请求，锁存读起始地址
logic [9:0] wr_len;                         //axifull从机接受主机的写请求，锁存写突发长度
logic [9:0] rd_len;                         //axifull从机接受主机的读请求, 锁存读突发长度
logic [9:0] wr_cnt;                         //axifull从机接受主机的写请求,记录写入数据个数，即从机接收数据个数
logic [9:0] rd_cnt;                         //axifull从机接受主机的读请求,记录读取数据个数，即从机发送数据个数
//test_done
assign test_done=done;
//count
always_ff@(posedge ACLK,negedge ARESETn)
if(!ARESETn)
    count<=0;
else if(axilite_BRESP==2'b00&&axilite_BREADY&&axilite_BVALID)             //1次配置完成，count++
    count<=count+1;                                       
//start_config
initial begin
    start_config=0;
    #20
    start_config=1;
    #10
    start_config=0;
end
//ACLK
initial begin
    ACLK=0;
    forever begin
        #5 ACLK=~ACLK;
    end
end
//ARESETn
initial begin
    ARESETn=0;
    #10
    ARESETn=1;
end
//mem
initial begin
    for(int i=0;i<1024;i++)
       mem[i]=i;
end
//rd_base_addr
initial begin
    rd_base_addr=32'd0;
end
//wr_base_addr
initial begin
    wr_base_addr=32'd32;
end
//start_signal
initial begin
    start_signal=32'd1;
end
//done_signal

//先写读起始地址,再写写起始地址，最后写start
//写地址通道
//AWVALID
always_ff@(posedge ACLK,negedge ARESETn)
if(!ARESETn)
    axilite_AWVALID<=0;
else if(start_config||write_rd_addr_done||write_wr_addr_done)
    axilite_AWVALID<=1;
else if(axilite_AWVALID&&axilite_AWREADY)
    axilite_AWVALID<=0;
//AWADDR
always_ff@(posedge ACLK,negedge ARESETn)                           //0号寄存器：start,1号寄存器：done,2号寄存器：写起始地址,3号寄存器：读起始地址
if(!ARESETn)
    axilite_AWADDR<=0;
else if(start_config)
    axilite_AWADDR<=32'd12;                //12/4=3,3号寄存器,配置读起始地址
else if(write_rd_addr_done)
    axilite_AWADDR<=32'd8;                 //8/4=2,2号寄存器,配置写起始地址
else if(write_wr_addr_done)
    axilite_AWADDR<=32'd0;                 //0/4=0,0号寄存器,配置开始信号
//AWPROT
always_comb 
begin
    axilite_AWPROT=3'b000;    
end
//写数据通道
//WDATA
always_ff@(posedge ACLK,negedge ARESETn)
if(!ARESETn)
    axilite_WDATA<=0;
else if(start_config)
    axilite_WDATA<=rd_base_addr;
else if(write_rd_addr_done)
    axilite_WDATA<=wr_base_addr;
else if(write_wr_addr_done)
    axilite_WDATA<=start_signal;
//WVALID
always_ff@(posedge ACLK,negedge ARESETn)
if(!ARESETn)
    axilite_WVALID<=0;
else if(start_config||write_rd_addr_done||write_wr_addr_done)
    axilite_WVALID<=1;
else if(axilite_WVALID&&axilite_WREADY)
    axilite_WVALID<=0;
//WSTRB
always_ff@(posedge ACLK,negedge ARESETn)
if(!ARESETn)
   axilite_WSTRB<=0;
else if(start_config||write_rd_addr_done||write_wr_addr_done)
   axilite_WSTRB<=4'b1111;
//write_rd_addr_done,write_rd_addr_done,write_start_done
always_ff@(posedge ACLK,negedge ARESETn)
if(!ARESETn)
begin
    write_rd_addr_done<=0;
    write_wr_addr_done<=0;
    write_start_done<=0;
end
else if(axilite_BRESP==2'b00&&axilite_BVALID&&axilite_BREADY)
case(count)
    0:write_rd_addr_done<=1;
    1:write_wr_addr_done<=1;
    2:write_start_done<=1;
    default:;
endcase
else
begin
    write_rd_addr_done<=0;
    write_wr_addr_done<=0;
    write_start_done<=0;
end
//写响应通道
//BREADY
always_ff@(posedge ACLK,negedge ARESETn)
if(!ARESETn)
    axilite_BREADY<=0;
else if(axilite_AWREADY&&axilite_AWVALID)
    axilite_BREADY<=1;
else if(axilite_BREADY&&axilite_BVALID&&axilite_BRESP==2'b00)                     //
    axilite_BREADY<=0;

/**********************************************************************************************************************************************
**********************************************************************************************************************************************/
//axifull从机
//写地址通道
//axifull_AWREADY
always_ff@(posedge ACLK,negedge ARESETn)
if(!ARESETn)
    axifull_AWREADY<=0;
else if(axifull_AWVALID&&~axifull_AWREADY)
    axifull_AWREADY<=1;
else if(axifull_AWREADY&&axifull_AWVALID)                        //读地址通道完成
    axifull_AWREADY<=0;
//wr_adrr
always_ff@(posedge ACLK,negedge ARESETn)
if(!ARESETn)
    wr_addr<=0;
else if(axifull_AWREADY&&axifull_AWVALID)                        //锁存写起始地址
    wr_addr<=axifull_AWADDR;
//wr_len
always_ff@(posedge ACLK,negedge ARESETn)
if(!ARESETn)
    wr_len<=0;
else if(axifull_AWVALID&&axifull_AWREADY)
    wr_len<=axifull_AWLEN;
//wr_cnt
always_ff@(posedge ACLK,negedge ARESETn)
if(!ARESETn)
    wr_cnt<=0;
else if(axifull_WREADY&&axifull_WVALID)
    if(axifull_WLAST)
        wr_cnt<=0;
    else
        wr_cnt<=wr_cnt+1;
//写数据通道
//mem
always_ff@(posedge ACLK,negedge ARESETn)
if(!ARESETn)
    ;
else if(axifull_WVALID&&axifull_WREADY)
    mem[wr_addr+wr_cnt]<=axifull_WDATA;
//WREAY
always_ff@(posedge ACLK,negedge ARESETn)
if(!ARESETn)
    axifull_WREADY<=0;
else if(axifull_AWVALID&&axifull_AWREADY)
    axifull_WREADY<=1;
else if(axifull_WVALID&&axifull_WREADY&&axifull_WLAST)
    axifull_WREADY<=0;
//写响应通道
//BRESP
always_ff@(posedge ACLK,negedge ARESETn)
if(!ARESETn)
    axifull_BRESP<=2'b01;
else if(axifull_WLAST&&axifull_WVALID&&axifull_WREADY)
    axifull_BRESP<=2'b00;
else if(axifull_BRESP==2'b00&&axifull_BVALID&&axifull_BREADY)
    axifull_BRESP<=2'b01;
//BVALID
always_ff@(posedge ACLK,negedge ARESETn)
if(!ARESETn)
    axifull_BVALID<=0;
else if(axifull_WLAST&&axifull_WREADY&&axifull_WVALID)
    axifull_BVALID<=1;
else if(axifull_BVALID&&axifull_BRESP==2'b00&&axifull_BREADY)
    axifull_BVALID<=0;
//读地址通道
//axifull_ARREADY
always_ff@(posedge ACLK,negedge ARESETn)
if(!ARESETn)
    axifull_ARREADY<=0;
else if(axifull_ARVALID&&~axifull_ARREADY)
    axifull_ARREADY<=1;
else if(axifull_ARREADY&&axifull_ARVALID)                    //读地址通道结束
    axifull_ARREADY<=0;
//rd_addr
always_ff@(posedge ACLK,negedge ARESETn)
if(!ARESETn)
    rd_addr<=0;
else if(axifull_ARREADY&&axifull_ARVALID)                   //锁存读起始地址
    rd_addr<=axifull_ARADDR;
//rd_len
always_ff@(posedge ACLK,negedge ARESETn)
if(!ARESETn)
    rd_len<=0;
else if(axifull_ARREADY&&axifull_ARVALID)
    rd_len<=axifull_ARLEN;
//读数据通道
//rd_cnt
always_ff@(posedge ACLK,negedge ARESETn)
if(!ARESETn)
    rd_cnt<=0;
else if(axifull_RVALID&&axifull_RREADY)
    if(axifull_RLAST)
        rd_cnt<=0;
    else 
        rd_cnt<=rd_cnt+1;
//RVALID
always_ff@(posedge ACLK,negedge ARESETn)
if(!ARESETn)
    axifull_RVALID<=0;
else if(axifull_ARREADY&&axifull_ARVALID)            //读地址通道结束即开始发送读数据
    axifull_RVALID<=1;
else if(axifull_RVALID&&axifull_RREADY&&axifull_RLAST)
    axifull_RVALID<=0;
//RDATA
always_comb
begin
    if(axifull_RVALID)
        axifull_RDATA=mem[rd_addr+rd_cnt];
    else
        axifull_RDATA=0;
end
//RLAST
always_ff@(posedge ACLK,negedge ARESETn)
if(!ARESETn)
    axifull_RLAST<=0;
else if(rd_cnt==rd_len-1&&axifull_RREADY&&axifull_RVALID)                      //倒数第二个数据发送并被接收，则RLAST拉高
    axifull_RLAST<=1; 
else if(axifull_RLAST&&axifull_RREADY&&axifull_RVALID)                         //最后一个数据发送并被接收,RLAST拉低
    axifull_RLAST<=0;

/***************************************************************************************************************************************/
//例化
top U(.*);
/* 
top U(
 ACLK,
 ARESETn,
//写地址通道
 axilite_AWVALID,
 axilite_AWADDR, 
 axilite_AWPROT, 
 axilite_AWREADY,
//写数据通道
 axilite_WVALID,
 axilite_WDATA, 
 axilite_WSTRB,
 axilite_WREADY,
//写响应通道
 axilite_BREADY,
 axilite_BVALID,
 axilite_BRESP,
//读地址通道
 axilite_ARVALID,
 axilite_ARADDR, 
 axilite_ARPROT, 
 axilite_ARREADY,
//读数据通道
 axilite_RREADY,
 axilite_RVALID,
 axilite_RDATA, 
 axilite_RRESP,
//其他
 busy,                           //主机往从机写数据时，busy为高，直至数据被写入寄存器
/****************************************************************************************************************************************/
/*
//AXI FULL MASTER
//写地址通道信号
 axifull_AWVALID,           
 axifull_AWADDR,
 axifull_AWLEN,
 axifull_AWID,              //dont care
 axifull_AWSIZE,            //dont care
 axifull_AWBURST,           //dont care
 axifull_AWLOCK,            //dont care
 axifull_AWCACHE,           //dont care
 axifull_AWPROT,            //dont care
 axifull_AWQOS,             //dont care
 axifull_AWUSER,            //dont care
 axifull_AWREADY,
//写数据通道信号
 axifull_WDATA,
 axifull_WSTRB,
 axifull_WLAST,
 axifull_WUSER,             //dont care
 axifull_WVALID,
 axifull_WREADY,
//写应答通道信号
 axifull_BREADY,
 axifull_BID,                //dont care
 axifull_BRESP,
 axifull_BUSER,              //dont care
 axifull_BVALID,
//读地址通道信号
 axifull_ARID,               //dont care
 axifull_ARADDR,
 axifull_ARLEN,
 axifull_ARSIZE,            //dont care
 axifull_ARBURST,           //dont care
 axifull_ARLOCK,            //dont care
 axifull_ARCACHE,           //dont care
 axifull_ARPROT,            //dont care
 axifull_ARQOS,             //dont care
 axifull_ARUSER,            //done care
 axifull_ARVALID,       
 axifull_ARREADY,
//读数据通道
 axifull_RREADY,
 axifull_RID,                //dont care
 axifull_RDATA,   
 axifull_RRESP,              //dont care   
 axifull_RLAST,          
 axifull_RUSER,              //dont care
 axifull_RVALID,
//其他
 done
);
*/
endmodule

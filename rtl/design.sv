`timescale 1ns / 1ps
package parameters;
localparam ADDR_WIDTH=32;// address and data width depending upon the RV32I processor 
localparam DATA_WIDTH=32;//as both(data and address fields) are 32 bit wide
localparam UART_base_address=32'h40000000;
localparam SPI_base_address=32'h40001000;
localparam TIMER_base_address=32'h40002000;
localparam GPIO_base_address=32'h40003000;
endpackage
/*interface apb_protocol(input bit PCLK, PRESETn);// this interface creates the set of signals
import parameters::*;
logic [DATA_WIDTH-1:0] PRDATA,CPU_WDATA,CPU_RDATA,PWDATA,uart_prdata,spi_prdata,timer_prdata,gpio_prdata;// used between APB protocol and the peripherals
bit write_req,read_req;                       // peripherals to be used in this module are UART,SPI,TIMER,GPIO
bit PSEL1,PSEL2,PSEL3,PSEL4,PENABLE,PWRITE,PREADY;//PSEL1=UART, PSEL2=SPI, PSEL3=TIMER , PSEL4=GPIO
logic[ADDR_WIDTH-1:0]CPU_ADDR,PADDR;
bit uart_pready,spi_pready,timer_pready,gpio_pready;
// modports for master
modport apb_master(input PRDATA,CPU_WDATA,
output PSEL1,PSEL2,PSEL3,PSEL4,PENABLE,PWRITE,
input PREADY,
output PWDATA,CPU_RDATA,
output PADDR,
input PRESETn,PCLK,
input CPU_ADDR,
input write_req,read_req);
//modport for slaves(peripeherals)// all the input and output signals are reversed in master and slave components.
modport uart_slave1(input PCLK,PRESETn,
input PSEL1,PENABLE,PWRITE,
input PWDATA,
input PADDR,
output uart_prdata,
output uart_pready);
//SPI
modport spi_slave2(input PCLK,PRESETn,
input PSEL2,PENABLE,PWRITE,
input PWDATA,
input PADDR,
output spi_prdata,
output spi_pready);
//TIMER
modport timer_slave3(input PCLK,PRESETn,
input PSEL3,PENABLE,PWRITE,
input PWDATA,
input PADDR,
output timer_prdata,
output timer_pready);
//GPIO
modport gpio_slave4(input PCLK,PRESETn,
input PSEL4,PENABLE,PWRITE,
input PWDATA,
input PADDR,
output gpio_prdata,
output gpio_pready);
modport multiplexer(input uart_pready,uart_prdata,
spi_pready,spi_prdata,
timer_pready,timer_prdata,
gpio_pready,gpio_prdata,
output PREADY,PRDATA,
input PSEL1,PSEL2,PSEL3,PSEL4
);
endinterface:apb_protocol// end of interface for the apb protocol( master and slaves(uart,spi,timer,gpio).*/
module apb_master_fsm(apb_interface.apb_master apb);
import parameters::*;
//localparam S0=2'b00;//IDLE
//localparam S1=2'b01;//SETUP
//localparam S2=2'b10;//ACCESS
typedef enum logic[1:0]{S0_IDLE,S1_SETUP,S2_ACCESS}states_t;
states_t state,next_state;
logic [DATA_WIDTH-1:0]WDATA;
logic[ADDR_WIDTH-1:0]ADDR;
bit write_req_reg,read_req_reg;
always_ff @(posedge apb.PCLK or negedge apb.PRESETn)begin
if(!apb.PRESETn)// when the reset is asserted the fsm goes back to IDLE state.
state<=S0_IDLE;
else
state<=next_state;// otherwise next state is assigned to present state.
end
always_ff @(posedge apb.PCLK or negedge apb.PRESETn)begin:present_state_assgn// this always block assigns the value of the next state to the present state.
if(!(apb.PRESETn))begin
WDATA<=32'h0;
ADDR<=32'h0;
write_req_reg<=1'b0;
read_req_reg<=1'b0;
apb.CPU_RDATA<=32'h0;
end
else begin
if(state==S0_IDLE)begin// to read the signas set by the CPU when the FSM has been in IDLE state for one or more clock cycles.
if(apb.write_req||apb.read_req)begin
write_req_reg<=apb.write_req;
read_req_reg<=apb.read_req;
WDATA<=apb.CPU_WDATA;
ADDR<=apb.CPU_ADDR;
end
end
else if(state==S2_ACCESS && apb.PREADY )begin// to read signals from the CPU for back to back transitions
if(apb.write_req||apb.read_req)begin//checks if the state was in ACCESS for last cycle (as there is a ONE cycle latency for 
write_req_reg<=apb.write_req;// reading state signal) and sees if there is any read or wrrite request signal asserted by the CPU.and stores it in the
read_req_reg<=apb.read_req;// internal registers.
WDATA<=apb.CPU_WDATA;
ADDR<=apb.CPU_ADDR;
end
end
if(state==S2_ACCESS)begin // to read the PRDATA value and feed it to the CPU when all PSEL,PENABLE and PREADY are assereted
if(read_req_reg && apb.PREADY)
apb.CPU_RDATA<=apb.PRDATA;
end
if ( state==S2_ACCESS && apb.PREADY && !(apb.write_req || apb.read_req))begin
write_req_reg<='0;// to clear all the internal register once the transfer is done and there is no further
read_req_reg<='0;// transfer to happen.
WDATA<='0;
ADDR<='0;
end
end
end:present_state_assgn
always_comb begin:master_output_var_assgn
apb.PSEL1='0;
apb.PSEL2='0;// default values if there is a stuck fault in the comb block,
apb.PSEL3='0;// values to which comb block can go to if there is an error.
apb.PSEL4='0;
apb.PENABLE='0;
apb.PWRITE='0;
apb.PADDR='0;
apb.PWDATA='0;
case(state)
S0_IDLE:begin//IDLE state have select and enable lines as low
apb.PSEL1='0;
apb.PSEL2='0;
apb.PSEL3='0;
apb.PSEL4='0;
apb.PENABLE='0;
apb.PWRITE='1;
apb.PADDR='0;
apb.PWDATA='0;
end
S1_SETUP:begin// SETUP state enables the select lines dependin upon the CPU_ADDR
apb.PSEL1=(ADDR[31:12]==20'h40000);
apb.PSEL2=(ADDR[31:12]==20'h40001);
apb.PSEL3=(ADDR[31:12]==20'h40002);
apb.PSEL4=(ADDR[31:12]==20'h40003);
apb.PENABLE='0;
apb.PADDR=ADDR;
if(write_req_reg)begin
apb.PWRITE=1'b1;
apb.PWDATA=WDATA;
end
else if(read_req_reg)begin
apb.PWRITE='0;
end
else
apb.PWRITE=1'b1;
end
S2_ACCESS:begin// SETUP state enables the select lines dependin upon the CPU_ADDR
apb.PSEL1=(ADDR[31:12]==20'h40000);
apb.PSEL2=(ADDR[31:12]==20'h40001);
apb.PSEL3=(ADDR[31:12]==20'h40002);
apb.PSEL4=(ADDR[31:12]==20'h40003);
apb.PENABLE=1'b1;
apb.PADDR=ADDR;
if(write_req_reg)begin
apb.PWRITE=1'b1;
apb.PWDATA=WDATA;
end
else if(read_req_reg)begin
apb.PWRITE='0;
end
else
apb.PWRITE=1'b1;

end
endcase
end:master_output_var_assgn
// NEXT STATE ASSIGNMENTS
always_comb  begin:next_state_assignments
next_state=state;
case(state)
S0_IDLE:begin
if((apb.write_req || apb.read_req))
next_state=S1_SETUP;
else
next_state=S0_IDLE;
end
S1_SETUP:begin
next_state=S2_ACCESS;
end
S2_ACCESS:begin
if(apb.PREADY)begin
if((apb.write_req || apb.read_req))
next_state=S1_SETUP;
else begin
next_state=S0_IDLE;
end
end
else
next_state=S2_ACCESS;
end
endcase
end:next_state_assignments
endmodule
module mux_pready_prdata(apb_interface.multiplexer apb_mux);
always_comb begin
apb_mux.PREADY='0;
apb_mux.PRDATA='0;
case(1'b1)
apb_mux.PSEL1:begin
apb_mux.PREADY=apb_mux.uart_pready;
apb_mux.PRDATA=apb_mux.uart_prdata;
end
apb_mux.PSEL2:begin
apb_mux.PREADY=apb_mux.spi_pready;
apb_mux.PRDATA=apb_mux.spi_prdata;
end
apb_mux.PSEL3:begin
apb_mux.PREADY=apb_mux.timer_pready;
apb_mux.PRDATA=apb_mux.timer_prdata;
end
apb_mux.PSEL4:begin
apb_mux.PREADY=apb_mux.gpio_pready;
apb_mux.PRDATA=apb_mux.gpio_prdata;
end
endcase
end
endmodule:mux_pready_prdata
module uart_peripheral( apb_interface.uart_slave1 uart_s);
//output logic Tx,
//input logic Rx);
localparam Tx_DATA_REG=32'h40000000;
localparam Rx_DATA_REG=32'h40000004;
localparam STATUS_REG=32'h40000008;
localparam CONTROL_REG=32'h4000000C;
localparam BAUD_RATE_REG=32'h40000010;
localparam oversampling_factor=5'd16;
logic [31:0]tx_data_reg,rx_data_reg,status_reg,control_reg,baud_rate_reg;
baud_tick_generator b_t_g(uart_s.PCLK,uart_s.PRESETn,baud_rate_reg,control_reg,reset_baud_ticks,baud_tick,baud_period_tick,half_baud_period_tick);
uart_tx tx_block(uart_s.PCLK,uart_s.PRESETn,baud_tick,baud_period_tick,tx_data_Reg,control_reg,status_reg,reset_baud_ticks,uart_s.Tx);
uart_rx rx_block(uart_s.PCLK,uart_s.PRESETn,baud_tick,baud_period_tick,half_baud_period_tick,uart_s.Rx,control_reg,rx_data_reg,status_reg,reset_baud_ticks);
always_ff @(posedge uart_s.PCLK or negedge uart_s.PRESETn)begin
if(!uart_s.PRESETn)begin
tx_data_reg<='0;
rx_data_reg<='0;
status_reg<='0;
control_reg<='0;
baud_rate_reg<='0;
uart_s.uart_prdata<='0;
//uart_s.uart_pready<='0;
end
else 
begin
if(uart_s.PSEL1 && uart_s.PENABLE )begin 
if(uart_s.PWRITE)begin
case(uart_s.PADDR)
Tx_DATA_REG:tx_data_reg<=uart_s.PWDATA;
CONTROL_REG:control_reg<=uart_s.PWDATA;
BAUD_RATE_REG:baud_rate_reg<=uart_s.PWDATA;
default:;
endcase
end
// setting of prdata
else begin
case(uart_s.PADDR)
Tx_DATA_REG:uart_s.uart_prdata<=tx_data_reg;
CONTROL_REG:uart_s.uart_prdata<=control_reg;
BAUD_RATE_REG:uart_s.uart_prdata<=baud_rate_reg;
Rx_DATA_REG:uart_s.uart_prdata<=rx_data_reg;
STATUS_REG:uart_s.uart_prdata<=status_reg;
default:;
endcase
end
end
end
if(status_reg[0])
control_reg<='0;
end
assign uart_s.uart_pready=1'b1;
endmodule
// baud tick generator module
module baud_tick_generator(input pclk,preset,
input logic[31:0] baud_rate_r,
input logic[31:0]control_reg,
input logic reset_baud_ticks,
output logic baud_tick, baud_period_tick,half_baud_period_tick);
localparam int oversampling_factor=16;
logic [31:0]count_val_1;
logic[4:0]count_val_2,count_val_3;
always_ff @(posedge pclk or negedge preset)begin:baud_tick_generator
if(!preset)begin
baud_tick<='0;
count_val_1<='0;
end
else if(/*control_reg[1] ||*/ reset_baud_ticks)begin
baud_tick<='0;
count_val_1<='0;
end
else begin
if(count_val_1+1== baud_rate_r)begin
baud_tick<=1'b1;
count_val_1<='0;
end
else begin
count_val_1<=count_val_1+1;
baud_tick<='0;
end
end
end:baud_tick_generator
always_ff @(posedge pclk or negedge preset)begin:complete_baud_tick_period
if(!preset)begin
count_val_2<='0;
baud_period_tick<='0;
end
else if(/*control_reg[1] ||*/ reset_baud_ticks)begin
baud_period_tick<='0;
count_val_2<='0;
end
else begin
if(baud_tick)begin
if(count_val_2+1==oversampling_factor)begin
baud_period_tick<=1'b1;
count_val_2<='0;
end
else begin
count_val_2<=count_val_2+1;
baud_period_tick<='0;
end
end
else 
baud_period_tick<='0;
end
end:complete_baud_tick_period
always_ff @(posedge pclk or negedge preset)begin: half_baud_tick_period
if(!preset)begin
half_baud_period_tick<='0;
count_val_3<='0;
end
else if(reset_baud_ticks/*||control_reg[1]*/)begin
count_val_3<='0;
half_baud_period_tick<='0;
end
else begin
if(baud_tick) begin
if(count_val_3+1==oversampling_factor/2)begin
half_baud_period_tick<=1'b1;
count_val_3<='0;
end
else begin
count_val_3<=count_val_3+1;
half_baud_period_tick<='0;
end
end
else 
half_baud_period_tick<='0;
end
end: half_baud_tick_period
endmodule
// module for the Transmission part of the UART
module uart_tx(input logic pclk,preset,baud_tick,baud_period_tick,
input logic[7:0]tx_data_reg,
input logic[31:0]control_reg,
output logic[31:0]status_reg,
output logic reset_baud_ticks,
output logic Tx);
localparam S0=2'b00;//IDLE
localparam S1=2'b01;//START_BIT
localparam S2=2'b10;//DATA_BITS
localparam S3=2'b11;//STOP_BIT
localparam oversampling_factor=5'd16;
logic [7:0]tx_shift_reg;
logic[2:0]bit_cnt;
logic[1:0]state,next_state;
logic tx_start;
assign tx_start=control_reg[1];
//FSM for transmission logic(tx)
always_ff@(posedge pclk or negedge preset)begin
if(!preset)
state<=S0;
else begin
state<=next_state;
end
end
always_ff@(posedge pclk or negedge preset)begin:output_var_assignments
if(!preset)begin
Tx<=1'b1;
status_reg<='0;
bit_cnt<='0;
tx_shift_reg<='0;
reset_baud_ticks<='0;
end
else begin
case(state)
S0:begin 
Tx<=1'b1;
reset_baud_ticks<=1'b1;
end
S1:begin 
reset_baud_ticks<='0;
Tx<='0;
status_reg[0]<=1'b1;
tx_shift_reg<=tx_data_reg;
end
S2:begin
Tx<=tx_shift_reg[0];
if(baud_period_tick)begin
tx_shift_reg<=tx_shift_reg>>1;
bit_cnt<=bit_cnt+1;
end
end
S3:begin
Tx<=1'b1;if(baud_period_tick)begin
status_reg[0]<='0;
bit_cnt<='0;
end
end
endcase
end
end:output_var_assignments
//next_state assignment
always_comb begin:next_state_assignment
next_state=state;
case(state)
S0:begin
if(tx_start)
next_state=S1;
else
next_state=S0;
end
S1:begin
if(baud_period_tick)
next_state=S2;
else next_state=S1;
end
S2:begin
if(bit_cnt==3'd7 && baud_period_tick==1'b1 )
next_state=S3;
else
next_state=S2;
end
S3:begin
if( baud_period_tick)
next_state=S0;
else
next_state=S3;
end
endcase
end:next_state_assignment
endmodule
// module for the reciever part of the UART
module uart_rx(input logic pclk,preset,baud_tick,baud_period_tick,half_baud_period_tick,
input logic Rx,
input logic[31:0] control_reg,
output logic[7:0] rx_data_reg,
output logic[31:0]status_reg,
output logic reset_baud_ticks);//the reset baud tick should be high for only one system clock cycle.
localparam S0=2'b00;//IDLE
localparam S1=2'b01;//START_DETECT
localparam S2=2'b10;//DATA_RECIEVE
localparam S3=2'b11;//STOP_CHECK
localparam oversampling_factor=5'd16;
logic [7:0]rx_shift_reg,bit_cnt;
logic[1:0]state,next_state;
always_ff@(posedge pclk or negedge preset)begin
if(!preset)
state<=S0;
else
state<=next_state;
end
// output_variable assignments.
always_ff@(posedge pclk or negedge preset)begin
if(!preset)begin
bit_cnt<=8'b0;
rx_shift_reg<=8'b0;
rx_data_reg<=8'd0;
status_reg[1]<=1'b0;
end
else begin
case(state)
S0:;
S1:begin
end
S2:begin
if(baud_period_tick)begin
bit_cnt<=bit_cnt+1;
rx_shift_reg<={Rx,rx_shift_reg[7:1]};
end
end
S3:begin
if(baud_period_tick && Rx==1'b1)begin
rx_data_reg<=rx_shift_reg;
status_reg[1]<=1'b1;
bit_cnt<=8'd0;
end
end
endcase
end
end
always_comb begin: next_state_assignment
next_state=state;
case(state)
S0:begin
if(Rx==1'b0)begin
next_state=S1;
reset_baud_ticks=1'b1;
end
else begin
next_state=S0;
reset_baud_ticks<='0;
end
end
S1:begin
if(Rx==1'b0 && half_baud_period_tick)begin
next_state=S2;
reset_baud_ticks=1'b1;
end
else if(half_baud_period_tick && Rx!=1'b0)begin
next_state=S0;
reset_baud_ticks='0;
end
else begin
next_state=S1;
reset_baud_ticks='0;
end
end
S2:begin
reset_baud_ticks=1'b0;
if(bit_cnt==8'd7 && baud_period_tick)begin
next_state=S3;
end
else
next_state=S2;
end
S3:begin
if( baud_period_tick)
next_state=S0;
else
next_state=S3;
end
endcase
end: next_state_assignment
endmodule
module spi_peripheral(apb_interface.spi_slave2 spi_s,
//input logic MISO,
//output logic MOSI,
output logic[2:0] CS,// only four slave peripherals at 000,001,010,011.
output logic SCLK);
localparam CONTROL_REG=32'h40001000;
localparam STATUS_REG=32'h40001004;
localparam BAUD_DIV_REG=32'h40001008;
localparam TX_DATA_REG=32'h4000100C;
localparam RX_DATA_REG=32'h40001010;
localparam CS_CONTROL_REG=32'h40001014;
localparam S0=3'b000;// IDLE State
localparam S1=3'b001;// LOAD state
localparam S2=3'b010;// SHIFT state
localparam S3=3'b011;// DONE state
logic[31:0] control_reg,status_reg,baud_div_reg,tx_data_reg,rx_data_reg,cs_control_reg;
logic[2:0] state,next_state;
logic[7:0]tx_shift_reg,rx_shift_reg,count_val;
logic[3:0]bit_cnt;
assign spi_s.spi_pready=1'b1;
always_ff @(posedge spi_s.PCLK or negedge spi_s.PRESETn)begin:internal_register_assignments
if(!spi_s.PRESETn)begin
control_reg<='0;
//status_reg<='0;
baud_div_reg<='0;
tx_data_reg<='0;
//rx_data_reg<='0;
cs_control_reg<='0;
spi_s.spi_prdata<='0;
//spi_s.spi_pready<='0;
end
else begin
if(state==S1)begin
control_reg[0]<=1'b0;
end
if(spi_s.PSEL2 && spi_s.PENABLE )begin
if(spi_s.PWRITE)begin
case(spi_s.PADDR)
CONTROL_REG:control_reg<=spi_s.PWDATA;
BAUD_DIV_REG:baud_div_reg<=spi_s.PWDATA;
TX_DATA_REG:tx_data_reg<=spi_s.PWDATA;
CS_CONTROL_REG:cs_control_reg<=spi_s.PWDATA;
endcase
end
else begin
case(spi_s.PADDR)
CONTROL_REG:spi_s.spi_prdata<=control_reg;
STATUS_REG:spi_s.spi_prdata<=status_reg;
RX_DATA_REG:spi_s.spi_prdata<=rx_data_reg;
BAUD_DIV_REG:spi_s.spi_prdata<=baud_div_reg;
TX_DATA_REG:spi_s.spi_prdata<=tx_data_reg;
CS_CONTROL_REG:spi_s.spi_prdata<=cs_control_reg;
endcase
end
end
end
end:internal_register_assignments
always_ff@(posedge spi_s.PCLK or negedge spi_s.PRESETn)begin
if(!spi_s.PRESETn)begin
state<=S0;
end
else 
state<=next_state;
end
always_ff @(posedge spi_s.PCLK or negedge spi_s.PRESETn)begin: output_var_and_SCLK_assignment
if(!spi_s.PRESETn)begin
spi_s.MOSI<='0;
CS<=3'b100;
SCLK<='0;
bit_cnt<='0;
tx_shift_reg<='0;
rx_shift_reg<='0;
count_val<='0;
status_reg<='0;//busy
//spi_s.spi_pready<=1'b0;
end
else begin
case(state)
S0:begin
//spi_s.spi_pready<=1'b1;
status_reg[0]<='0;//busy
status_reg[1]<='0;//transfer_done
status_reg[2]<='0;//rx_data_available ,all three bits are cleared when the reset is set.
CS<=3'b100;
if(control_reg[2])
SCLK<=1'b1;// CPOL=1, then idle clock is high
else
SCLK<=1'b0;//CPOL=0, idle clock is low.
end
S1:begin
//spi_s.spi_pready<=1'b0;
CS<=cs_control_reg[1:0];
status_reg[0]<=1'b1;// transfer begins when control_bit(tx_start) is set.
tx_shift_reg<=tx_data_reg[7:0];
bit_cnt<='0;
count_val<=8'd1;
if(control_reg[2])
SCLK<=1'b1;
else
SCLK<='0;
end
S2:begin
//status_reg[0]<=1'b1;
if(count_val==baud_div_reg[7:0])begin
count_val<=8'b1;
SCLK<=~SCLK;
end
else
count_val<=count_val+1;
//SCLK genertaion complete-------------------------------------------
//recieving and transmitting bits------------------------------------
if(count_val==baud_div_reg[7:0])begin
if((control_reg[2]&& control_reg[3]) || (!control_reg[2] && (!control_reg[3]))) begin
if(SCLK)begin//falling edge and data changin
spi_s.MOSI<=tx_shift_reg[0];
tx_shift_reg<={1'b0,tx_shift_reg[7:1]};
end
else begin// rising edge and data sampling
rx_shift_reg<={spi_s.MISO,rx_shift_reg[7:1]};
bit_cnt<=bit_cnt+1;
end
end
if((!control_reg[2]&& control_reg[3]) || (control_reg[2] && (!control_reg[3]))) begin
if(SCLK)begin// rising edge and data sampling
rx_shift_reg<={spi_s.MISO,rx_shift_reg[7:1]};
end
else begin
spi_s.MOSI<=tx_shift_reg[0];
tx_shift_reg<={1'b0,tx_shift_reg[7:1]};
bit_cnt<=bit_cnt+1;
end
end
end
end
S3:begin
status_reg[1]<=1'b1;
status_reg[2]<=1'b1;
status_reg[0]<=1'b0;
rx_data_reg<=rx_shift_reg;
if(control_reg[2])
SCLK<=1'b1;
else 
SCLK<='0;
end
endcase
end
end: output_var_and_SCLK_assignment
always_comb begin
next_state=state;
case(state)
S0:begin
if (control_reg[0])
next_state=S1;
else next_state=S0;
end
S1:begin
next_state=S2;
end
S2:begin
if(bit_cnt==4'd8)
next_state=S3;
else next_state=S2;
end
S3:begin
next_state=S0;
end
default:next_state=S0;
endcase
end
endmodule
module gpio_peripheral(apb_interface.gpio_slave4 gpio_s,
input logic[31:0] gpio_in,
output logic[31:0] gpio_out);
localparam DATA_OUT_REG=32'h40003000;// address of DATA_OUT_REG GPIO base address + 0x00hw
localparam DATA_IN_REG=32'h40003004;//address of DATA_IN_REG GPIO base address +0x04h
localparam DIRECTION_REG=32'h40003008;//address of DIRECTION_REGISTER GPIO base address + 0x08h
logic [31:0]direction_reg;
assign gpio_s.gpio_pready=1'b1;
always_comb begin:combinational_block// procedural block to set the output signals to the gpio peripherals
//gpio_s.gpio_pready=1'b0;
gpio_s.gpio_prdata=32'h0;
/*if(gpio_s.PSEL4)// sets the PREADY signal whenever the GPIO peripheral is selected.
//gpio_s.gpio_pready=1'b1;
else
//gpio_s.gpio_pready=1'b0;// else the PREADY signal is cleared*/
if(gpio_s.PSEL4 && gpio_s.PENABLE)begin
if(!gpio_s.PWRITE)begin// if the APB master gets in the ACCESS phase and if the WRITE is signal is clear then the value of 
case(gpio_s.PADDR)    // PRDATA is filled by the desired register depending upon the value of the PADDR given by the master.
DATA_OUT_REG:gpio_s.gpio_prdata=gpio_out;
DIRECTION_REG:gpio_s.gpio_prdata=direction_reg;
DATA_IN_REG:gpio_s.gpio_prdata=gpio_in;
default: begin
gpio_s.gpio_prdata=32'h0;
end
endcase
end
end
end: combinational_block
always_ff @(posedge gpio_s.PCLK or negedge gpio_s.PRESETn)begin:sequential_block
if(!gpio_s.PRESETn)begin
gpio_out<=32'h0;
direction_reg<=32'h0;
end
else begin
if(gpio_s.PENABLE && gpio_s.PSEL4 && gpio_s.PWRITE)begin
case(gpio_s.PADDR)
DATA_OUT_REG: gpio_out<=gpio_s.PWDATA;
DIRECTION_REG: direction_reg<=gpio_s.PWDATA;
default:begin
end
endcase
end
end
end:sequential_block
endmodule
module timer_peripheral(apb_protocol.timer_slave3 timer_s);
//output logic irq);
localparam CONTROL_REG=32'h40002000;
localparam COUNT_REG=32'h40002004;
localparam PRESCALER_REG=32'h40002008;
localparam COMPARE_REG=32'h4000200C;
localparam STATUS_REG=32'h40002010;
localparam IRQ_CLEAR_REG=32'h40002014;
localparam clock_frequency=8'd100;//in MegaHertz. (system clock)(PCLK)
localparam S0=2'b00;//IDLE
localparam S1=2'b01;//COUNT
localparam S2=2'b10;//STOP
logic[1:0] state,next_state;
logic [31:0] control_reg,count_reg,prescaler_reg,compare_reg,status_reg;
logic[31:0]prescaler_val;
logic match_occ;
assign timer_s.timer_pready=1'b1;
always_ff @(posedge timer_s.PCLK or negedge timer_s.PRESETn)begin:sequential_block
if (!timer_s.PRESETn)begin
control_reg<='0;
prescaler_reg<='0;
compare_reg<='0;
status_reg<='0;
timer_s.irq<='0;
end
else
if(count_reg+1==compare_reg)begin
status_reg[0]<=1'b1;
timer_s.irq<=control_reg[1] ;
end
else begin
status_reg[0]<=1'b0;
end
if(timer_s.PSEL3 && timer_s.PENABLE && timer_s.PWRITE)begin
case(timer_S.PADDR)
CONTROL_REG:control_reg<=timer_s.PWDATA;
PRESCALER_REG:prescaler_reg<=timer_s.PWDATA;
COMPARE_REG:compare_reg<=timer_s.PWDATA;
IRQ_CLEAR_REG:begin
if(timer_s.PWDATA[0])begin
timer_s.irq<=1'b0;
end
end
endcase
end
else if(timer_s.PSEL3 && timer_s.PENABLE && !timer_s.PWRITE)begin
case(timer_s.PADDR)
STATUS_REG:timer_s.timer_prdata<=status_reg;
COUNT_REG:timer_s.timer_prdata<=count_reg;
default:;
endcase
end
end:sequential_block
//FSM
always_ff @(posedge timer_s.PCLK or negedge timer_s.PRESETn)begin
if(!timer_s.PRESETn)begin
state<=S0;
prescaler_val<='0;
count_reg<='0;
end
else  begin
state<=next_state;
case(state)
S0:begin
prescaler_val<='0;
count_reg<='0;
match_occ<='0;
//status_reg<='0;
end
S1:begin
if(control_reg[0])begin
if(prescaler_val==prescaler_reg)begin
count_reg<=count_reg+1;
prescaler_val<='0;
if(count_reg+1==compare_reg)begin
match_occ<=1'b1;
//status_reg[0]<=1'b1;
prescaler_val<='0;
if(control_reg[2])
count_reg<='0;
end
else begin
match_occ<='0;
end
end
else begin
prescaler_val<=prescaler_val+1;
end
end
end
S2:;
endcase
end
end
//next_state assignments;
always_comb begin
next_state=state;
case(state)
S0:begin
if(control_reg[0])
next_state=S1;
else next_state=S0;
end
S1:begin
if(control_reg[0]==0)
next_state=S0;
else if(match_occ=='0)
next_state=S1;
else begin
if(control_reg[2])
next_state=S1;
else next_state=S2;
end
end
S2:if(control_reg[2])
next_state=S1;
else if(control_reg[0]=='0)begin
next_state=S0;
end
else
next_state=S2;
endcase
end
endmodule
module top_dut(output logic[2:0]CS,
output logic SCLK,
input logic[31:0] gpio_in,
output logic[31:0] gpio_out,
apb_interface.apb_master apb,
apb_interface.multiplexer apb_mux,
apb_interface.uart_slave1 uart_s,
apb_interface.spi_slave2 spi_s,
apb_interface.gpio_slave4 gpio_s,
apb_interface.timer_slave3 timer_s);
apb_master_fsm apb_m_fsm(.apb(apb));
mux_pready_prdata mux_pready_prdata(.apb_mux(apb_mux));
uart_peripheral u1(.uart_s(uart_s));
spi_peripheral spi_1(.spi_s(spi_s),.CS(CS),.SCLK(SCLK));
gpio_peripheral gpio_1(.gpio_s(gpio_s),.gpio_in(gpio_in),.gpio_out(gpio_out));
timer_peripheral timer_1(.timer_s(timer_s));
endmodule

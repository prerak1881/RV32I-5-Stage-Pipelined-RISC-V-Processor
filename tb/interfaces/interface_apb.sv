package parameters;
localparam ADDR_WIDTH=32;// address and data width depending upon the RV32I processor 
localparam DATA_WIDTH=32;//as both(data and address fields) are 32 bit wide
localparam UART_base_address=32'h40000000;
localparam SPI_base_address=32'h40001000;
localparam TIMER_base_address=32'h40002000;
localparam GPIO_base_address=32'h40003000;
endpackage
interface apb_interface(input bit PCLK, PRESETn);
import parameters::*;
logic [DATA_WIDTH-1:0] PRDATA,CPU_WDATA,CPU_RDATA,PWDATA,uart_prdata,spi_prdata,timer_prdata,gpio_prdata;// used between APB protocol and the peripherals
logic write_req,read_req;                       // peripherals to be used in this module are UART,SPI,TIMER,GPIO
logic PSEL1,PSEL2,PSEL3,PSEL4,PENABLE,PWRITE,PREADY;//PSEL1=UART, PSEL2=SPI, PSEL3=TIMER , PSEL4=GPIO
logic[ADDR_WIDTH-1:0]CPU_ADDR,PADDR;
logic Rx,Tx;
logic MOSI,MISO,SCLK;
logic irq;
logic[DATA_WIDTH-1:0]gpio_in,gpio_out;
logic uart_pready,spi_pready,timer_pready,gpio_pready;
//for DUT
modport apb_master(input PRDATA,CPU_WDATA,
output PSEL1,PSEL2,PSEL3,PSEL4,PENABLE,PWRITE,
input PREADY,
output PWDATA,CPU_RDATA,
output PADDR,
input PRESETn,PCLK,
input CPU_ADDR,
input write_req,read_req);
modport uart_slave1(input PCLK,PRESETn,
input PSEL1,PENABLE,PWRITE,
input PWDATA,
input PADDR,
output uart_prdata,
output uart_pready,
input Rx,output Tx);
//SPI
modport spi_slave2(input PCLK,PRESETn,
input PSEL2,PENABLE,PWRITE,
input PWDATA,
input PADDR,
output spi_prdata,
output spi_pready,MOSI,
input MISO);
//TIMER
modport timer_slave3(input PCLK,PRESETn,
input PSEL3,PENABLE,PWRITE,
input PWDATA,
input PADDR,
output timer_prdata,
output timer_pready,irq);
//GPIO
modport gpio_slave4(input PCLK,PRESETn,
input PSEL4,PENABLE,PWRITE,
input PWDATA,
input PADDR,
output gpio_prdata,
output gpio_pready);
//mux
modport multiplexer(input uart_pready,uart_prdata,
spi_pready,spi_prdata,
timer_pready,timer_prdata,
gpio_pready,gpio_prdata,
output PREADY,PRDATA,
input PSEL1,PSEL2,PSEL3,PSEL4
);
//for my testbench
clocking drv_cb @(posedge PCLK);
output CPU_RDATA,CPU_WDATA,CPU_ADDR,write_req,read_req;
input PREADY,PENABLE,PSEL1,PSEL2,PSEL3,PSEL4;
endclocking
clocking mon_cb@(posedge PCLK);
input PRDATA,PWDATA,write_req,read_req,CPU_RDATA,CPU_WDATA,CPU_ADDR,
PSEL1,PSEL2,PSEL3,PSEL4,PENABLE,PWRITE,PREADY,PADDR;
endclocking
clocking drv_uart_cb @(posedge PCLK);
output Rx;
output PSEL1,PENABLE,PWRITE,PWDATA,PADDR;
input uart_pready;
endclocking
clocking mon_uart_cb@(posedge PCLK);
input PSEL1,PENABLE,PWRITE,PWDATA,PADDR,uart_pready,uart_prdata,Tx,Rx,write_req,read_req;
endclocking
clocking drv_spi_cb@(posedge PCLK);
input SCLK;
output MISO;
output PSEL2,PENABLE,PWRITE,PWDATA,PADDR;
endclocking
clocking mon_spi_cb@(posedge PCLK);
input PSEL2,PENABLE,PWRITE,PWDATA,PADDR,uart_pready,uart_prdata,MISO,MOSI,SCLK;
endclocking
clocking drv_timer_cb@(posedge PCLK);
input timer_pready,timer_prdata,PSEL3,PENABLE;
endclocking
clocking mon_timer_cb@(posedge PCLK);
input PSEL3,PENABLE,PWRITE,PWDATA,PADDR,timer_pready,timer_prdata,irq;
endclocking
clocking mon_gpio_cb@(posedge PCLK);
input PSEL4,PENABLE,PWRITE,PWDATA,PADDR,gpio_prdata,gpio_pready,gpio_out;
endclocking
clocking drv_gpio_cb@(posedge PCLK);
output gpio_in;
endclocking
modport mp_driver(clocking drv_cb);
modport mp_monitor(clocking mon_cb);
modport mp_driver_uart(clocking drv_uart_cb);
modport mp_monitor_uart(clocking mon_uart_cb);
modport mp_driver_spi(clocking drv_spi_cb,input PCLK);
modport mp_monitor_spi(clocking mon_spi_cb,input PCLK);
modport mp_driver_timer(clocking mon_timer_cb);
modport mp_monitor_timer(clocking mon_timer_cb);
modport mp_gpio_driver(clocking drv_gpio_cb);
modport mp_gpio_monitor(clocking mon_gpio_cb);
endinterface

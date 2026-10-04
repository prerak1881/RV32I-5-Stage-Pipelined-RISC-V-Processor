`uvm_analysis_imp_decl(_apb)
`uvm_analysis_imp_decl(_uart_tx)
`uvm_analysis_imp_decl(_uart_rx)
`uvm_analysis_imp_decl(_spi_tx)
`uvm_analysis_imp_decl(_spi_rx)
`uvm_analysis_imp_decl(_timer)
`uvm_analysis_imp_decl(_gpio)

class scoreboard extends uvm_scoreboard;
parameter ADDR_WIDTH=32;
parameter DATA_WIDTH=32;
`uvm_component_utils(scoreboard)
function new(string name="scoreboard",uvm_component parent=null);
super.new(name,parent);
endfunction

uvm_analysis_imp_apb#(apb_sequence_item, scoreboard)imp_apb;
uvm_analysis_imp_uart#(uart_sequence_item, scoreboard)imp_uart_tx;
uvm_analysis_imp_uart#(uart_sequence_item, scoreboard)imp_uart_rx;
uvm_analysis_imp_spi#(spi_sequence_item, scoreboard)imp_spi_tx;
uvm_analysis_imp_spi#(spi_sequence_item, scoreboard)imp_spi_rx;
uvm_analysis_imp_timer#(timer_sequence_item, scoreboard)imp_timer;
uvm_analysis_imp_gpio#(gpio_sequence_item, scoreboard)imp_gpio;

virtual function void build_phase(uvm_phase phase);
super.build_phase(phase);
imp_apb=new("imp_apb",this);
imp_uart_tx=new("imp_uart_tx",this);
imp_uart_rx=new("imp_uart_rx",this);
imp_spi_tx=new("imp_spi_tx",this);
imp_spi_rx=new("imp_spi_rx",this);
imp_timer=new("imp_timer",this);
imp_gpio=new("imp_gpio",this);
endfunction

virtual task run_phase(uvm_phase phase);
super.run_phase(phase);

function void write_apb(apb_sequence_item apb_item);
compare(apb_item.CPU_ADDR,apb_item.PADDR);
if(apb_item.PWRITE)
compare(apb_item.CPU_WDATA,apb_item.PWDATA);
else
compare(apb_item.CPU_RDATA,apb_item.PRDATA);
case(apb_item.PADDR[31:12])
20'h40000:begin
    if(apb_item.PSEL1==1)
    $display("SCB, pass, PSEL(1) is asserted")
    else
    $display("SCB, fail PSEL(1) is not asserted")
    end//UART
20'h40001:begin
    if(apb_item.PSEL2==1)
    $display("SCB, pass, PSEL(2) is asserted")
    else
    $display("SCB, fail PSEL(2) is not asserted")
    end//SPI
20'h40002:begin
    if(apb_item.PSEL3==1)
    $display("SCB, pass, PSEL(3) is asserted")
    else
    $display("SCB, fail PSEL(3) is not asserted")
    end//timer
20'h40003:begin
    if(apb_item.PSEL4==1)
    $display("SCB, pass, PSEL(4) is asserted")
    else
    $display("SCB, fail PSEL(4) is not asserted")
    end//GPIO
endcase
endfunction

function void write_uart_tx(uart_sequence_item uart_tx_item);
compare(uart_tx_item.local_tx_data_reg,uart_tx_item.actual_tx_data_reg);
endfunction

function void write_uart_tx(uart_sequence_item uart_rx_item);
compare(uart_rx_item.local_rx_data_reg,uart_rx_item.actual_rx_data_reg);
endfunction

function void write_spi_tx(spi_sequence_item spi_tx_item);
compare(spi_tx_item.local_tx_data_reg,spi_tx_item.actual_tx_data_reg);
endfunction

function void write_spi_rx(spi_sequence_item spi_rx_item);
compare(spi_rx_item.local_rx_data_reg,spi_rx_item.actual_rx_data_reg);
endfunction

function void write_timer(timer_sequence_item timer_item);
compare(timer_item.local_control_reg,timer_item.local_compare_reg);
endfunction

/*function void write_gpio(gpio_sequence_item gpio_item)
endfunction*/

endtask

task compare(logic[DATA_WIDTH-1:0]a,logic[DATA_WIDTH-1:0]b);
if(a==b)begin
    $display("SCB match passes, actual_val=%h , expected_val=%h",a,b);
end
else begin
    $display("SCB match failed, actual_val=%h , expected_val=%h",a,b);
end
endtask
endclass

class apb_sequence extends uvm_sequence#(apb_sequence_item);
`uvm_object_utils(apb_sequence)
function new(string name="apb_sequence");
super.new(name);
endfunction
apb_sequence_item req;
logic[1:0]peripheral_access;
parameter DATA_WIDTH=32;

reg_block_uart reg_m_uart;
reg_block_spi reg_m_spi;
reg_block_gpio reg_m_gpio;
reg_block_timer reg_m_timer;
uvm_status_e status;
uvm_reg_data_t data;
virtual task body();
assert(std::randomize(peripheral_access))
case(peripheral_access)
2'b00:begin
write_data('h40000000);//tx data reg
reg_m_uart.tx_data_reg_rm.mirror(status);
write_data('h40000010);//baud data reg
reg_m_uart.baud_rate_reg_rm_data_reg_rm.mirror(status);
write_data('h4000000C);//control reg
reg_m_uart.control_reg_rm_data_reg_rm.mirror(status);
do begin
    reg_m_uart.status_reg_rm.read(status,data);
end
while(data[0]==1'b1);
read_data('h40000008);//status reg
read_data('h40000004);//rx data reg
end//UART;
2'b01:begin
    write_reg(32'h4000100C);// tx data reg
    reg_m_spi.tx_data_reg_rm.mirror(status);
write_reg(32'h40001008);//baud div reg
reg_m_spi.baud_rate_reg_rm_data_reg_rm.mirror(status);
write_reg(32'h40001014);//CS control reg
reg_m_spi.cs_control_reg_rm.mirror(status);
write_reg(32'h40001000);//control reg
reg_m_spi.control_reg_rm_data_reg_rm.mirror(status);
do begin
    reg_m_spi.status_reg_rm.read(status,data);
end
while(data[0]==1'b1);
read_reg(32'h40001004);//status reg
read_reg(32'h40001010);//rx data reg
    end//SPI
2'b10:begin//Timer_peri
write_reg(32'h4000200C);//compare reg
reg_m_timer.compare_reg_rm.mirror(status);
write_reg(32'h40002008);//prescaler reg
reg_m_timer.prescaler_reg_rm.mirror(status);
write_reg(32'h40002000);//control reg
reg_m_timer.control_reg_rm.mirror(status);
do begin
    reg_m_timer.status_reg_rm.read(status,data);
end
while(data[0]==1'b0);
read_reg(32'h40002010);//status reg
#20;
write_reg(32'h40002014);//irq clear flag reg
reg_m_timer.irq_clear_reg_rm.mirror(status);
end//Timer
2'b11:begin//GPIO_peri
write_reg(32'h40003008);// direction reg
reg_m_gpio.direction_reg_rm.mirror(status);
write_reg(32'h40003000);// data out reg
reg_m_gpio.data_out_reg_rm.mirror(status);
read_reg(32'h40003004);// data in reg
end//GPIO
endcase
endtask

task wrtie_data(logic[DATA_WIDTH-1:0] addr);
start_item(req);
req.CPU_ADDR=addr;
if(addr=='h4000000C || addr=='h40001000 || addr=='h40002000 )begin
    case(addr)
    'h4000000C:req.CPU_WDATA=32'd3;//UART
    'h40001000:req.CPU_WDATA=32'd3;//SPI
    'h40002000:req.CPU_WDATA=32'd15;//TIMER
    endcase
end
else
req.randomize();
req.write_req=1;
req.read_req=0;
finish_item(req);
endtask

task read_data(logic[DATA_WIDTH-1:0] addr);
start_item(req);
req.CPU_ADDR=addr;
req.write_req=0;
req.read_req=1;
finish_item(req);
endtask
endclass

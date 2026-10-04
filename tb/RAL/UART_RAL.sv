class tx_data_reg extends uvm_reg;
`uvm_object_utils(tx_data_reg)
uvm_reg_field tx_data;
function new(string name="tx_data_reg");
super.new(name);
endfunction
function void build();
tx_data=uvm_reg_field::type_id::create("tx_data");
tx_data.configure(this,8,0,"RW",0,1'h0,1,1,1);
endfunction
endclass

class rx_data_reg extends uvm_reg;
`uvm_object_utils(rx_data_reg)
uvm_reg_field rx_data;
function new(string name="rx_data_reg");
super.new(name);
endfunction
function void build();
rx_data=uvm_reg_field::type_id::create("rx_data");
rx_data.configure(this,8,0,"RO",0,1'h0,1,1,1);
endfunction
endclass

class status_reg extends uvm_reg;
`uvm_object_utils(status_reg)
uvm_reg_field tx_busy;
uvm_reg_field rx_valid;
function new(string name="status_reg");
super.new(name);
endfunction
function void build();
tx_busy=uvm_reg_field::type_id::create("tx_busy");
rx_valid=uvm_reg_field::type_id::create("rx_valid");
tx_busy.configure(this,1,0,"RO",0,1'h0,1,1,1);
rx_valid.configure(this,1,1,"RO",0,1'h0,1,1,1);
endfunction
endclass

class control_reg extends uvm_reg;
`uvm_object_utils(control_reg)
uvm_reg_field uart_enable;
uvm_reg_field tx_start;
function new(string name="control_reg");
super.new(name);
endfunction
function void build();
uart_enable=uvm_reg_field::type_id::create("uart_enable");
tx_start=uvm_reg_field::type_id::create("tx_start");
tx_busy.configure(this,1,0,"RW",0,1'h0,1,1,1);
rx_valid.configure(this,1,1,"RW",0,1'h0,1,1,1);
endfunction
endclass

class baud_rate_reg extends uvm_reg;
`uvm_object_utils(baud_rate_reg)
uvm_reg_field baud_rate;
function new(string name="baud_rate_reg");
super.new(name);
endfunction
function void build();
baud_rate=uvm_reg_field::type_id::create("baud_rate");
baud_rate.configure(this,8,0,"RW",0,1'h0,1,1,1);
endfunction
endclass
// reg block
class reg_block_uart extends uvm_reg_block;
`uvm_object_utils(reg_block_uart)
function new(string name="reg_block_uart");
super.new(name);
endfunction

tx_data_reg tx_data_reg_rm;
rx_data_reg rx_data_reg_rm;
control_reg control_reg_rm;
status_reg status_reg_rm;
baud_rate_reg baud_rate_reg_rm;

function void build();
default_map=create_map("",'h40000000,4,UVM_LITTLE_ENDIAN,0);

tx_data_reg_rm=tx_data_Reg::type_id::create("tx_data_reg_rm");
rx_data_reg_rm=tx_data_Reg::type_id::create("rx_data_reg_rm");
control_reg_rm=tx_data_Reg::type_id::create("control_reg_rm");
baud_rate_reg_rm=tx_data_Reg::type_id::create("baud_rate_reg_rm");
status_reg_rm=tx_data_Reg::type_id::create("status_reg_rm");

tx_data_reg_rm.configure(this,null,"");
rx_data_reg_rm.configure(this,null,"");
control_reg_rm.configure(this,null,"");
baud_rate_reg_rm.configure(this,null,"");
status_reg_rm.configure(this,null,"");

tx_data_reg_rm.build();
rx_data_reg_rm.build();
control_reg_rm.build();
baud_rate_reg_rm.build();
status_reg_rm.build();

default_map.add_reg(tx_data_reg_rm,'h00,"RW");
default_map.add_reg(rx_data_reg_rm,'h04,"RO");
default_map.add_reg(control_reg_rm,'h0C,"RW");
default_map.add_reg(baud_rate_reg_rm,'h10,"RW");
default_map.add_reg(status_reg_rm,'h08,"RO");
lock_model();
endfunction
endclass
// adapter
class adapter extends uvm_reg_adapter;
`uvm_object_utils(adapter)
function new(string name="adapter");
super.new(name);
endfunction

function apb_sequence_item reg2bus(const ref uvm_reg_bus_op rw);
apb_sequence_item apb_item;
apb_item.CPU_ADDR=rw.addr;
apb_item.CPU_WDATA=rw.data;
apb_item.write_req=rw.kind;
apb_item.read_req=!rw.kind;
endfunction

function void bus2reg(uvm_sequence_item item,ref uvm_reg_bus_op rw);
apb_sequence_item apb_item;
if(!($cast(apb_item,item)))
`uvm_fatal("casting failed_UART","from the genreal item to apb sequence item")
rw.addr=apb_item.CPU_ADDR;
if(apb_item.write_req)begin
    rw.data=apb_item.CPU_WDATA;
    rw.kind=UVM_WRITE;
end
else if(apb_item.read_req)begin
    rw.kind=UVM_READ;
    rw.data=apb_item.CPU_RDATA;
end
endfunction
endclass

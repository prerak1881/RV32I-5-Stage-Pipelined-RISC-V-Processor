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
uvm_reg_field spi_busy;
uvm_reg_field transf_done;
uvm_reg_field rx_valid;
function new(string name="status_reg");
super.new(name);
endfunction
function void build();
spi_busy=uvm_reg_field::type_id::create("spi_busy");
rx_valid=uvm_reg_field::type_id::create("rx_valid");
transf_done=uvm_reg_field::type_id::create("transf_done");
spi_busy.configure(this,1,0,"RO",0,1'h0,1,1,1);
transf_done.configure(this,1,1,"RO",0,1'h0,1,1,1);
rx_valid.configure(this,1,2,"RO",0,1'h0,1,1,1);
endfunction
endclass

class control_reg extends uvm_reg;
`uvm_object_utils(control_reg)
uvm_reg_field spi_enable;
uvm_reg_field start_trnsf;
uvm_reg_field cpol;
uvm_reg_field cpha;
function new(string name="control_reg");
super.new(name);
endfunction
function void build();
spi_enable=uvm_reg_field::type_id::create("uart_enable");
start_trnsf=uvm_reg_field::type_id::create("start_trnsf");
cpol=uvm_reg_field::type_id::create("cpol");
cpha=uvm_reg_field::tpe_id::create("cpha");
tx_busy.configure(this,1,0,"RW",0,1'h0,1,1,1);
rx_valid.configure(this,1,1,"RW",0,1'h0,1,1,1);
cpol.configure(this,1,2,"RW",0,1'h0,1,1,1);
cpha.configure(this,1,3,"RW",0,1'h0,1,1,1);
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

class cs_control_reg extends uvm_reg;
`uvm_object_utils(cs_control_reg)
function new(string name="cs_control_reg");
super.new(name);
endfunction
uvm_reg_field cs_control;

function void build();
cs_control=uvm_reg_field::type_id::create("cs_control");
cs_control.configure(this,3,0,"RW",0,1'h0,1,1,1);
endfunction
endclass

class reg_block_spi extends uvm_reg_block;
`uvm_object_utils(reg_model_spi)
function new(string name="reg_model_spi");
super.new(name);
endfunction

tx_data_reg tx_data_reg_rm;
rx_data_reg rx_data_reg_rm;
control_reg control_reg_rm;
status_reg status_reg_rm;
baud_rate_reg baud_rate_reg_rm;
cs_control_reg cs_control_reg_rm;

function void build();
default_map=create_map("",'h40001000,4,UVM_LITTLE_ENDIAN,0);

tx_data_reg_rm=tx_data_reg::type_id::create("tx_data_reg_rm");
rx_data_reg_rm=rx_data_reg::type_id::create("rx_data_reg_rm");
control_reg_rm=control_reg::type_id::create("control_reg_rm");
status_reg_rm=status_reg::type_id::create("status_reg");
baud_rate_reg_rm=baud_rate_reg::type_id::create("baud_rate_reg_rm");
cs_control_reg_rm=cs_control_reg::type_id::create("cs_control_reg_rm");

tx_data_reg_rm.configure(this,null,"");
rx_data_reg_rm.configure(this,null,"");
control_reg_rm.configure(this,null,"");
status_reg_rm.configure(this,null,"");
baud_rate_reg_rm.configure(this,null,"");
cs_control_reg_rm.configure(this,null,"");

tx_data_reg_rm.build();
rx_data_reg_rm.build();
control_reg_rm.build();
status_reg_rm.build();
baud_rate_reg_rm.build();
cs_control_reg_rm.build();

default_map.add_reg(tx_data_reg_rm,'h0C,"RW");
default_map.add_reg(rx_data_reg_rm,'h10,"RO");
default_map.add_reg(control_reg_rm,'h00,"RW");
default_map.add_reg(status_reg_rm,'h04,"RO");
default_map.add_reg(baud_rate_reg_rm,'h08,"RW");
default_map.add_reg(cs_control_reg_rm,'h14,"RW");
lock_model();
endfunction

endclass
//adapter
class spi_adapter extends uvm_reg_adapter;
`uvm_object_utils(spi_adapter)
function new(string name="spi_adapter");
super.new(name);
endfunction

function void bus2reg(uvm_sequence_item item, ref uvm_reg_bus_op rw);
apb_sequence_item apb_item;
if(!($cast(apb_item,item)))
`uvm_fatal("casting failed_SPI","could not cast the general item to apb sequence item")

rw.kind=apb_item.write_req;
rw.addr=apb_item.PADDR;
rw.data=apb_item.PWDATA;
endfunction
endclass

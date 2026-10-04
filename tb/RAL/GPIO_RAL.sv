class data_in_reg extends uvm_reg;
`uvm_object_utils(data_in)
function new(string name="data_in_reg");
super.new(name);
endfunction
uvm_reg_field data_input;

function void build();
data_input=uvm_reg_field::tpe_id::create("data_input");
data_input.configure(this,32,0,"RW",0,1'h0,1,1,1);
endfunction
endclass

class data_out_reg extends uvm_reg;
`uvm_object_utils(data_out_reg)
function new(string name="data_out_reg");
super.new(name);
endfunction
uvm_reg_field data_output;

function void build();
data_output=uvm_reg_field::tpe_id::create("data_output");
data_output.configure(this,32,0,"RW",0,1'h0,1,1,1);
endfunction
endclass

class direction_reg extends uvm_reg;
`uvm_object_utils(direction_reg)
function new(string name="direction_reg");
super.new(name);
endfunction
uvm_reg_field direction_val;

function void build();
direction_val=uvm_reg_field::tpe_id::create("direction_val");
direction_val.configure(this,32,0,"RW",0,1'h0,1,1,1);
endfunction
endclass

class reg_block_gpio extends uvm_reg_block;
`uvm_object_utils(reg_block_gpio)
function new(string name="reg_block_gpio");
super.new(name);
endfunction

data_in_reg data_in_reg_rm;
data_out_reg data_out_reg_rm;
direction_reg direction_reg_rm;

function void build();
default_map=create_map("",'h40003000,4,UVM_LITTLE_ENDIAN,0);

data_in_reg_rm=data_in_reg::type_id::create("data_in_reg_rm");
data_out_reg_rm=data_out_reg::type_id::create("data_out_reg_rm");
direction_reg_rm=direction_reg::type_id::create("direction_reg_rm");

data_in_reg_rm.configure(this,null,"");
data_out_reg_rm.configure(this,null,"");
direction_reg_rm.configure(this,null,"");

data_in_reg_rm.build();
data_out_reg_rm.build();
direction_reg_rm.build();

default_map.add_reg(data_in_reg_rm,'h00,"RO");
default_map.add_reg(data_out_reg_rm,'h04,"RW");
default_map.add_reg(direction_reg_rm,'h08,"RW");
lock_model();
endfunction
endclass

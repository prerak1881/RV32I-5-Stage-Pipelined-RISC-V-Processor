class control_reg extends uvm_reg;
`uvm_object_utils(control_reg)
function new(String name="control_reg");
super.new(name);
endfunction

uvm_reg_field enable;
uvm_reg_field irq_enable;
uvm_reg_field periodic;
uvm_reg_field up_down_select;

function void build();
enable=uvm_reg_field::type_id::create("enable");
irq_enable=uvm_reg_field::type_id::create("irq_enable");
periodic=uvm_reg_field::type_id::create("periodic");
up_down_select=uvm_reg_field::type_id::create("up_down_select");

enable.configure(this,1,0,"RW",0,1'h0,1,1,1);
irq_enable.configure(this,1,1,"RW",0,1'h0,1,1,1);
periodic.configure(this,1,2,"RW",0,1'h0,1,1,1);
up_down_select.configure(this,1,3,"RW",0,1'h0,1,1,1);
endfunction
endclass

class count_register extends uvm_reg;
`uvm_object_utils(count_register)
function new(string name="count_register");
super.new(name);
endfunction

uvm_reg_field count_val;

function void build();
count_val=uvm_reg_field::type_id::create("count_val");
count_val.configure(this,26,0,"RO",0,1'h0,1,1,1);

endfunction
endclass

class compare_register extends uvm_reg;
`uvm_object_utils(count_register)
function new(string name="compare_register");
super.new(name);
endfunction

uvm_reg_field compare_val;

function void build();
compare_val=uvm_reg_field::type_id::create("compare_val");
compare_val.configure(this,26,0,"RW",0,1'h0,1,1,1);

endfunction
endclass

class prescaler_register extends uvm_reg;
`uvm_object_utils(prescaler_register)
function new(string name="prescaler_register");
super.new(name);
endfunction

uvm_reg_field prescaler_val;

function void build();
prescaler_val=uvm_reg_field::type_id::create("prescaler_val");
prescaler_val.configure(this,26,0,"RW",0,1'h0,1,1,1);

endfunction
endclass

class status_register extends uvm_reg;
`uvm_object_utils(status_register)
function new(string name="status_register");
super.new(name);
endfunction

uvm_reg_field timer_match;
uvm_reg_field timer_oberflow;

function void build();
timer_match=uvm_reg_field::type_id::create("timer_match");
timer_overflow=uvm_reg_field::type_id::create("timer_overflow");

timer_match.configure(this,1,0,"RO",0,1'h0,1,1,1);
timer_overflow.configure(this,1,1,"RO",0,1'h0,1,1,1);
endfunction
endclass

class irq_clear_register extends uvm_reg;
`uvm_object_utils(irq_clear_register)
function new(string name="irq_clear_register");
super.new(name);
endfunction

uvm_reg_field clear_match;
uvm_reg_field clear_overflow;

function void build();
clear_match=uvm_reg_field::type_id::create("clear_match");
clear_overflow=uvm_reg_field::type_id::create("clear_overflow");

clear_match_match.configure(this,1,0,"RW",0,1'h0,1,1,1);
clear_overflow.configure(this,1,1,"RW",0,1'h0,1,1,1);
endfunction
endclass

class reg_block_timer extends uvm_reg_block;
`uvm_object_utils(reg_model_timer)
function new(string name="reg_model_timer");
super.new(name);
endfunction

control_reg control_reg_rm;
count_register count_reg_rm;
compare_register compare_reg_rm;
prescaler_register prescaler_reg_rm;
status_reg status_reg_rm;
irq_clear_register irq_clear_reg_rm;

function void build();
default_map=create_map("",'h40003000,4,UVM_LITTLE_ENDIAN,0);

control_reg_rm=control_reg::type_id::create("control_reg_rm");
count_reg_rm=count_register::type_id::create("count_reg_rm");
compare_reg_rm=compare_register::type_id::create("compare_reg_rm");
prescaler_reg_rm=prescaler_register::type_id::create("prescaler_reg_rm");
status_reg_rm=status_reg::type_id::create("status_reg_rm");
irq_clear_reg_rm=irq_clear_register::type_id::create("irq_clear_reg_rm");

control_reg_rm.configure(this,null,"");
count_reg_rm.configure(this,null,"");
compare_reg_rm.configure(this,null,"");
prescaler_reg_rm.configure(this,null,"");
status_reg_rm.configure(this,null,"");
irq_clear_reg_rm.configure(this,null,"");

control_reg_rm.build();
count_reg_rm.build();
compare_reg_rm.build();
prescaler_reg_rm.build();
status_reg_rm.build();
irq_clear_reg_rm.build();

default_map.add_reg(control_reg_rm,'h00,"RW");
default_map.add_reg(count_reg_rm,'h04,"RO");
default_map.add_reg(compare_reg_rm,'h0C,"RW");
default_map.add_reg(prescaler_reg_rm,'h08,"RW");
default_map.add_reg(status_reg_rm,'h10,"RO");
default_map.add_reg(irq_clear_reg_rm,'h14,"RW");
lock_model();
endfunction
endclass

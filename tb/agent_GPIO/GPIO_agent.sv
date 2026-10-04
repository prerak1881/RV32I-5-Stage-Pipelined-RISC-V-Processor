class gpio_sequence_item extends uvm_sequence_item;
`uvm_object_utils(gpio_sequence_item)
function new(string name="gpio_sequence_item");
super.new(name);
endfunction

parameter DATA_WIDTH=32;
rand logic[DATA_WIDTH-1:0] gpio_in;
logic[DATA_WIDTH-1:0]local_data_in_reg,local_direction_reg,local_data_out_reg;
endclass

class gpio_driver extends uvm_driver#(gpio_sequence_item);
`uvm_component_utils(gpio_driver)
function new(string name="gpio_driver",uvm_component parent =null);
super.new(name,parent);
endfunction

virtual apb_interface.mp_gpio_driver gpio_drv_if;

virtual function void build_phase(uvm_phase phase);
super.build_phase(phase);
if(!(uvm_config_db#(virtual apb_interface.mp_gpio_driver)::get(null,"","gpio_drv_if",gpio_drv_if)))
`uvm_fatal("GPIO_DRV","could not get the desired interface from the config db")

endfunction

virtual task run_phase(uvm_phase phase);
super.run_phase(phase);
forever begin
    seq_item_port.get_next_item(req);
    gpio_drv_if.drv_gpio_cb.gpio_in<=req.gpio_in;
    @(gpio_drv_if.drv_gpio_cb);
    seq_item_port.item_done();
end
endtask
endclass

class gpio_monitor extends uvm_monitor;
`uvm_component_utils(gpio_monitor)
function new(string name="gpio_monitor",uvm_component parent=null);
super.new(name,parent);
endfunction

virtual apb_interface.mp_gpio_monitor gpio_mon_if;
uvm_analysis_port#(gpio_sequence_item)ap;

virtual function void build_phase(uvm_phase phase);
super.build_phase(phase);

if(!(uvm_config_db#(virtual apb_interface.mp_gpio_monitor)::get(null,"","gpio_mon_if",gpio_mon_if)))
`uvm_fatal("GPIO_MON","could not get the desired interface from the config db")
ap=new();
endfunction

virtual task run_phase(uvm_phase phase);
gpio_sequence_item gpio_item;
super.run_phase(phase);
forever begin
    gpio_item=gpio_sequence_item::type_id::create("gpio_item");
    while(!(gpio_mon_if.mon_gpio_cb.PSEL4 &&  gpio_mon_if.mon_gpio_cb.gpio_pready))
    @(gpio_mon_if.mon_gpio_cb);
    case(gpio_mon_if.mon_gpio_cb.PADDR[7:0])
    8'h04:gpio_item.local_data_in_reg=gpio_mon_if.mon_gpio_cb.gpio_prdata;//dat_in_reg
    endcase
    ap.write(gpio_item)
end
endtask
endclass

class gpio_agent extends uvm_agent;
`uvm_component_utils(gpio_agent)
function new(string name="gpio_agent",uvm_component parent=null);
super.new(name,parent);
endfunction

gpio_driver gpio_drv;
gpio_monitor gpio_mon;
uvm_sequencer#(gpio_sequence_item)gpio_seqr;

virtual function void build_phase(uvm_phase phase);
super.build_phase(phase);
gpio_mon=gpio_monitor::type_id::create("gpio_mon",this);
if(get_is_active()==UVM_ACTIVE)begin
    gpio_drv=gpio_driver::type_id::create("gpio_drv",this);
    gpio_seqr=uvm_sequencer#(gpio_sequence_item)::type_id::create("gpio_seqr",this);
end
endfunction

virtual function void connect_phase(uvm_phase phase);
if(get_is_active()==UVM_ACTIVE)begin
    gpio_drv.seq_item_port.connect(gpio_seqr.seq_item_export);
end
endfunction
endclass
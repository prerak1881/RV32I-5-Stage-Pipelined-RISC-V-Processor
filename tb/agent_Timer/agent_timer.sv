class timer_sequence_item extends uvm_sequence_item;
`uvm_object_utils(timer_sequence_item)
parameter DATA_WIDTH=32;
logic irq;
logic[DATA_WIDTH-1:0]local_count_reg,local_compare_reg,local_status_reg,local_control_reg,local_prescaler_reg,local_irq_clear_reg;
endclass

class timer_driver extends uvm_driver;
`uvm_component_utils(timer_driver)
function new(string name="timer_driver",uvm_component parent=null);
super.new(name,parent);
endfunction

virtual apb_interface.mp_driver_timer timer_drv_if;

virtual function void build_phase(uvm_phase phase);
super.build_phase(phase);
if(!(uvm_config_db#(virtual apb_interface.mp_driver_timer)::get(this,"","timer_drv_if",timer_drv_if)))
`uvm_fatal("TIMER_DRV","could not get the desired interface from config db")
endfunction

virtual task run_phase(uvm_phase);
super.run_phase(phase);
forever begin
    seq_item_port.get_next_item(req);
    while(!(timer_drv_if.drv_timer_cb.PSEL3 && timer_drv_if.drv_timer_cb.PENABLE && timer_drv_if.drv_timer_cb.timer_pready));
    seq_item_port.item_done();
end
endtask
endclass

class timer_monitor extends uvm_monitor ;
`uvm_component_utils (timer_monitor)
function new(string name="timer_monitor",uvm_component parent=null);
super.new(name,parent);
endfunction

parameter DATA_WIDTH=32;
logic[DATA_WIDTH-1:0]count_reg_mirror,compare_reg_mirror,status_reg_mirror,control_reg_mirror,prescaler_reg_mirror,irq_clear_reg_mirror;
virtual apb_interface.mp_monitor_timer timer_mon_if;
uvm_analysis_port#(timer_sequence_item)ap;

virtual function void build_phase(uvm_phase phase);
super.build_phase(phase);
if(!(uvm_config_db#(virtual apb_interface.mp_monitor_timer)::get(null,"","timer_mon_if",timer_mon_if)))
`uvm_fatal("Timer_MON","could not get the desired interface from the config db")
ap=new();
endfunction

virtual task run_phase(uvm_phase phase);
timer_sequence_item timer_item;
super.run_phase(phase);
forever begin
while(!(timer_mon_if.PSEL3 && timer_mon_if.PENABLE && timer_mon_if.timer_pready));
case(timer_mon_if.PADDR[7:0])
8'h00:control_reg_mirror=timer_mon_if.mon_timer_cb.PWDATA;
8'h04:;
8'h08:prescaler_reg_mirror=timer_mon_if.mon_timer_cb.PWDATA;
8'h0C:compare_reg_mirror=timer_mon_if.mon_timer_cb.PWDATA;
8'h10:;
8'h14:irq_clear_reg_mirror=timer_mon_if.mon_timer_cb.PWDATA;
endcase
end

forever begin
    timer_item=timer_sequence_item::type_id::create("timer_item");
    wait(control_reg_mirror[0]==1);
     timer_item.local_count_reg='0;
    timer_item.local_compare_reg=compare_reg_mirror;
    timer_item.local_prescaler_reg=prescaler_reg_mirror;
    timer_item.local_control_reg=control_reg_mirror;
    while(timer_mon_if.irq==0)begin
        timer_item.local_count_reg++;
        @(timer_mon_if.mon_timer_cb);
    end
    ap.write(timer_item);
    timer_item.local_irq_clear_reg=irq_clear_reg_mirror;
end
endtask
endclass

class timer_agent extends uvm_agent;
`uvm_component_utils(timer_agent)
function new(string name="timer_agent",uvm_component parent=null);
super.new(name,parent);
endfunction

timer_driver timer_drv;
timer_monitor timer_mon;
uvm_sequencer#(timer_sequence_item) timer_seqr;

virtual function void build_phase(uvm_phase phase);
super.build_phase(phase);
timer_drv=timer_driver::type_id::create("timer_drv",this);
timer_mon=timer_monitor::type_id::create("timer_mon",this);
timer_seqr=uvm_sequencer#(timer_sequence_item)::type_id::create("timer_seqr");
endfunction

virtual function void connect_phase(uvm_phase phase);
super.connect_phase(phase);
if(get_is_active()==UVM_ACTIVE)
timer_drv.seq_item_port.connect(timer_seqr.seq_item_export);
endfunction
endclass

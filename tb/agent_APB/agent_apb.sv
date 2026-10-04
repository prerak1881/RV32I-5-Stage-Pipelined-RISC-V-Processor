//sequence_item
class apb_sequence_item extends uvm_sequence_item;
parameter ADDR_WIDTH=32;
parameter DATA_WIDTH=32;
`uvm_object_utils(apb_sequence_item)
logic [ADDR_WIDTH-1:0]CPU_ADDR;
logic [ADDR_WIDTH-1:0]PADDR;
rand logic[DATA_WIDTH-1:0]CPU_WDATA;
logic[DATA_WIDTH-1:0]CPU_RDATA,PWDATA,PRDATA;
logic write_req,read_req;
logic PWRITE,PSEL1,PSEL2,PSEL3,PSEL4,PENABLE;
//rand logic[1:0]peripheral_access;
function new(string name="apb_sequence_item");
super.new(name);
endfunction
endclass
// driver class
class apb_driver extends uvm_driver#(apb_sequence_item);
`uvm_component_utils(apb_driver)
virtual apb_interface.mp_driver apb_drv_if;

function new(string name="apb_driver", uvm_component parent=null);
super.new(name,this);
endfunction

virtual function void build_phase(uvm_phase phase);
super.build_phase(phase);
if(!uvm_config_db#(virtual apb_interface.mp_driver)::get(null,"","apb_drv_if",apb_drv_if))
`uvm_fatal("APB_DRV","could not get the desired interface from the database")
endfunction

virtual task run_phase(uvm_phase phase);
super.run_phase(phase);
forever begin
    $display("the APB DRV is waiting for item");
seq_item_port.get_next_item(req);
$display("the APB DRV sequence item");
apb_drv_if.drv_cb.CPU_ADDR<=req.CPU_ADDR;
apb_drv_if.drv_cb.CPU_WDATA<=req.CPU_DATA;
apb_drv_if.drv_cb.write_req<=req.write_req;
apb_drv_if.drv_cb.read_req<=req.read_req;
while(!(apb_drv_if.drv_cb.PENABLE && apb_drv_if.drv_cb.PREADY && (apb_drv_if.drv_cb.PSEL1 ||apb_drv_if.drv_cb.PSEL2|| apb_drv_if.drv_cb.PSEL3||apb_drv_if.drv_cb.PSEL4 )))
@(apb_drv_if.drv_cb);
$display("the APB DRV is done driving the DUT signals");
seq_item_port.item_done();
end
endtask
endclass
//monitor class
class apb_monitor extends uvm_monitor;
`uvm_component_utils(apb_monitor)

virtual apb_interface.mp_monitor apb_mon_if;
uvm_analysis_port #(apb_sequence_item)ap;
apb_sequence_item apb_item;

function new(string name="apb_monitor",uvm_component parent=null);
super.new(name,parent);
endfunction

virtual function void build_phase(uvm_phase phase);
super.build_phase(phase);
if(!(uvm_config_db#(virtual apb_interface.mp_monitor):: get(this,"","apb_mon_if",apb_mon_if)))
`uvm_fatal("APB_MON","could not get the desired interface from the config database")
ap=new();
endfunction

virtual task run_phase(uvm_phase phase);
super.run_phase(phase);
forever begin
apb_item=apb_sequence_item::type_id::create("apb_item",this);
$display("the APB MON is waiting for the new apb_item");
while(!(apb_mon_if.mon_cb.PENABLE && apb_mon_if.mon_cb.PREADY && (apb_mon_if.mon_cb.PSEL1 ||apb_mon_if.mon_cb.PSEL2|| apb_mon_if.mon_cb.PSEL3||apb_mon_if.mon_cb.PSEL4 )))
@(apb_mon_if.mon_cb);
$display("the APB MON got the new apb_item");
req.CPU_ADDR=apb_mon_if.mon_cb.CPU_ADDR;
req.CPU_WDATA=apb_mon_if.mon_cb.CPU_WDATA;
req.CPU_RDATA=apb_mon_if.mon_cb.CPU_RDATA;
req.PWDATA=apb_mon_if.mon_cb.PWDATA;
req.PADDR=apb_mon_if.mon_cb.PADDR;
req.PRDATA=apb_mon_if.mon_cb.PRDATA;
req.write_req=apb_mon_if.mon_cb.write_req;
req.read_req=apb_mon_if.mon_cb.read_req;
req.PSEL1=apb_mon_if.mon_cb.PSEL1;
req.PSEL2=apb_mon_if.mon_cb.PSEL2;
req.PSEL3=apb_mon_if.mon_cb.PSEL3;
req.PSEL4=apb_mon_if.mon_cb.PSEL4;
req.PENABLE=apb_mon_if.mon_cb.PENABLE;
req.PWRITE=apb_mon_if.mon_cb.PWRITE;
ap.write(req);
$display("the APB MON put the new apb_item into the analysis port");
end
endtask
endclass
//agent class
class apb_agent extends uvm_agent;
`uvm_component_utils(apb_agent)

function new(string name="apb_agent",uvm_component parent=null);
super.new(name,parent);
endfunction

//apb_sequence_item apb_item;
apb_driver apb_drv;
apb_monitor apb_mon;
uvm_sequencer#(apb_sequence_item) apb_seqr;

virtual function void build_phase(uvm_phase phase);
super.build_phase(phase);
//apb_item=apb_sequence_item::type_id::create("apb_item");
apb_mon=apb_monitor::type_id::create("apb_mon",this);
if(get_is_active()==UVM_ACTIVE)begin
    apb_drv=apb_driver::type_id::create("apb_drv",this);
    apb_seqr=uvm_sequencer#(apb_sequence_item)::type_id::create("apb_seqr",this);
end
endfunction

virtual function void connect_phase(uvm_phase phase);
super.connect_phase(phase);
if(get_is_active()==UVM_ACTIVE)begin
    apb_drv.seq_item_port.connect(apb_seqr.seq_item_export);
end
endfunction
endclass

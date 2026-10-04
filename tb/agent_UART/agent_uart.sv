//`uvm_analysis_imp_decl(_drv)
//`uvm_analysis_imp_decl(_mon)
class uart_sequence_item extends uvm_sequence_item;
`uvm_object_utils(uart_sequence_item)
function new(string name="uart_Sequence_item");
super.new(name);
endfunction
parameter DATA_WIDTH=32;
rand logic Rx;
logic Tx;
logic [DATA_WIDTH-1:0]local_tx_data_reg,local_rx_data_reg,local_status_reg,local_baud_div_reg,local_control_reg;
logic[DATA_WIDTH-1:0]actual_tx_data_reg,actual_rx_data_reg,actual_status_reg;
endclass
//driver class
class uart_driver extends uvm_driver#(uart_sequence_item);
`uvm_component_utils(uart_driver)
virtual apb_interface.mp_driver_uart uart_drv_if;
reg_block_uart reg_m_uart;
logic[DATA_WIDTH-1:0] baud_rate_val;
parameter int oversampling_factor=16;

function new(string name="uart_driver",uvm_component parent=null);
super.new(name,parent);
endfunction

virtual function void build_phase(uvm_phase phase);
super.build_phase(phase);
if(!uvm_config_db#(virtual apb_interface.mp_driver_uart)::get(null,"","uart_drv_if",uart_drv_if))
`uvm_fatal("UART_DRV","could not get the desired interface from the config db")
endfunction

virtual task run_phase(uvm_phase phase);
super.run_phase(phase);
forever begin
    wait(reg_m_uart.control_reg_rm[0]==1);
    seq_item_port.get_next_item(req);
    uart_drv_if.drv_uart_cb.Rx<=req.Rx;
    repeat(reg_m_uart.baud_rate_reg_rm*oversampling_factor)
    @(uart_drv_if.drv_uart_cb)
    seq_item_port.item_done();
end
endtask
endclass
//monitor class
class uart_monitor extends uvm_monitor;
`uvm_component_utils(uart_monitor)
parameter DATA_WIDTH=32;
parameter int oversampling_factor=16;

function new(string name="uart_monitor",uvm_component parent=null);
super.new(name,parent);
endfunction

virtual apb_interface.mp_monitor_uart uart_mon_if;
uvm_analysis_port#(uart_sequence_item)ap_tx;
uvm_analysis_port#(uart_sequence_item)ap_rx;
uart_sequence_item uart_tx_item;
uart_sequence_item uart_rx_item;
logic[DATA_WIDTH-1:0]tx_data_reg_mirror,control_reg_mirror,bad_div_mirror;

virtual function void build_phase(uvm_phase phase);
super.build_phase(phase);
if(!uvm_config_db#(virtual apb_interface.mp_monitor_uart)::get(null,"","uart_mon_if",uart_mon_if))
`uvm_fatal("UART_MON","could not get the desired interface from config db")
endfunction

virtual task run_phase(uvm_phase phase);
uart_sequence_item uart_item;
super.run_phase(phase);
forever begin
    while(!(uart_mon_if.mon_cb.PENABLE && uart_mon_if.mon_cb.PREADY && uart_mon_if.mon_cb.PSEL1))
    @(uart_mon_if.mon_cb);
    if(uart_mon_if.mon_cb.write_req)begin
        case(mon_uart_if.mon_cb.PADDR)
        32'h40000000:tx_data_reg_mirror<=uart_mon_if.mon_cb.PWDATA;
        32'h4000000C:control_reg_mirror<=uart_mon_if.mon_cb.PWDATA;
        32'h40000010:baud_div_mirror<=uart_mon_if.mon_cb.PWDATA;
        endcase
    end
end

forever begin// forever block for tx data reg
uart_tx_item=uart_sequence_item::type_id::create("uart_tx_item");

uart_tx_item.local_tx_data_reg<=tx_data_reg_mirror;
uart_tx_item.local_control_reg<=control_reg_mirror;
uart_tx_item.local_baud_div_reg<=baud_div_mirror;

wait(uart_tx_item.local_control_reg[0]==1)
uart_tx_item.local_status_reg[0]=1'b1;
repeat((uart_tx_item.local_baud_div_reg*oversampling_factor*3)/2)
@(mon_uart_if.mon_cb);
//uart_item.actual_tx_data_reg[0]<=mon_uart_if.mon_cb.Tx;
for(int i=0;i<8;i++)begin
uart_tx_item.actual_tx_data_reg={mon_uart_if.mon_cb.Tx,uart_tx_item.actual_tx_data_reg[7:1]};
repeat(uart_tx_item.local_baud_div_reg*oversampling_factor)
@(mon_uart_if.mon_cb);
end
if(mon_uart_if.mon_cb.Tx==0)begin
    uart_tx_item.local_status_reg[0]=1'b0;
ap_tx.write(uart_tx_item);
end
end

forever begin// forever block for rx data reg.
uart_rx_item=uart_sequence_item::type_id::create("uart_rx_item");

uart_rx_item.local_tx_data_reg<=tx_data_reg_mirror;
uart_rx_item.local_control_reg<=control_reg_mirror;
uart_rx_item.local_baud_div_reg<=baud_div_mirror;


wait(uart_rx_item.local_control_reg[0]==1)
repeat((uart_rx_item.local_baud_div_reg*oversampling_factor*3)/2)
@(mon_uart_if.mon_cb);
//uart_item.actual_tx_data_reg[0]<=mon_uart_if.mon_cb.Tx;
for(int i=0;i<8;i++)begin
uart_rx_item.actual_rx_data_reg={mon_uart_if.mon_cb.Rx,uart_rx_item.actual_rx_data_reg[7:1]};
repeat(uart_rx_item.local_baud_div_reg*oversampling_factor)
@(mon_uart_if.mon_cb);
end
if(mon_uart_if.mon_cb.Rx==0)begin
    uart_rx_item.local_rx_data_reg<=mon_uart_if.mon_cb_uart_prdata;
ap_rx.write(uart_rx_item);
end
end
endtask
endclass
//agent class
class uart_agent extends uvm_agent;
`uvm_component_utils(uart_agent)
function new(string name="uart_agent",uvm_component parent= null);
super.new(name,parent);
endfunction

uart_driver uart_drv;
uart_monitor uart_mon;
uvm_sequencer#(uart_sequence_item) uart_seqr;

virtual function void build_phase(uvm_phase phase);
super.build_phase(phase);
uart_mon=uart_monitor::type_id::create("uart_mon",this);
if(get_is_active()==UVM_ACTIVE)begin
    uart_drv=uart_driver::type_id::create("uart_drv",this);
    uart_seqr=uvm_sequencer#(uart_sequence_item)::type_id::create("uvm_seqr",this);
end
endfunction

virtual function void connect_phase(uvm_phase phase);
super.connect_phase(phase);
if(get_is_active()==UVM_ACTIVE)
uart_drv.seq_item_port.connect(uart_seqr.seq_item_export);
endfunction


endclass


class spi_sequence_item extends uvm_sequence_item;
`uvm_object_utils(spi_sequence_item)
function new(string name="spi_sequence_item");
super.new(name);
endfunction
parameter DATA_WIDTH=32;
rand logic MISO;
logic MOSI,SCLK;
logic[DATA_WIDTH-1:0]local_tx_data_reg,local_control_reg,local_baud_div_reg,local_rx_data_reg,local_status_reg;
logic[DATA_WIDTH-1:0]actual_tx_data_reg,actual_status_reg,actual_rx_data_reg;
endclass
//driver class
class spi_driver extends uvm_driver#(spi_sequence_item);
`uvm_component_utils(spi_driver);
function new(string name="spi_driver",uvm_component parent =null);
super.new(name,parent);
endfunction

virtual apb_interface.mp_driver_spi spi_drv_if;
reg_block_spi reg_m_spi;

virtual function void build_phase(uvm_phase phase);
super.build_phase(phase);
if(!uvm_config_db#(virtual apb_interface.mp_driver_spi)::get(null,"","spi_drv_if",spi_drv_if))
`uvm_fatal("SPI_DRV","could not get the desired interface from the config db")
endfunction

virtual task run_phase(uvm_phase phase);
super.run_phase(phase);
forever begin
    wait(reg_m_spi.control_reg_rm[0]==1);
    seq_item_port.get_next_item(req);
    case({reg_m_spi.control_reg_rm[1],reg_m_spi.control_reg_rm[2]})
    2'b00:begin
        wait(spi_drv_if.drv_spi_cb.SCLK==0);
        spi_drv_if.drv_spi_cb.MISO<=req.MISO;
        @(posedge spi_drv_if.drv_spi_cb.SCLK);
    end
    2'b01:begin
        wait(spi_drv_if.drv_spi_cb.SCLK==1);
        spi_drv_if.drv_spi_cb.MISO<=req.MISO;
        @(negedge spi_drv_if.drv_spi_cb.SCLK);
    end
    2'b10:begin
        wait(spi_drv_if.drv_spi_cb.SCLK==1);
        spi_drv_if.drv_spi_cb.MISO<=req.MISO;
        @(negedge spi_drv_if.drv_spi_cb.SCLK);
    end
    2'b11:begin
        wait(spi_drv_if.drv_spi_cb.SCLK==0);
        spi_drv_if.drv_spi_cb.MISO<=req.MISO;
        @(posedge spi_drv_if.drv_spi_cb.SCLK);
    end
    endcase
    seq_item_port.item_done();
end
endtask
endclass
//monitor class
class spi_monitor extends uvm_monitor;
`uvm_component_utils(spi_monitor)

function new(string name="spi_driver",uvm_component parent=null);
super.new(name,parent);
endfunction

parameter DATA_WIDTH=32;
virtual apb_interface.mp_monitor_spi spi_mon_if;
uvm_analysis_port#(spi_sequence_item)ap_MISO;
uvm_analysis_port#(spi_sequence_item)ap_MOSI;
spi_sequence_item spi_item_miso;
spi_sequence_item spi_item_mosi;
logic [DATA_WIDTH-1:0]tx_data_reg_mirror,control_reg_mirror,baud_div_mirror;

virtual function void build_phase(uvm_phase phase);
super.build_phase(phase);
ap_MSIO=new();
ap_MOSI=new();
if(!uvm_config_db#(virtual apb_interface.mp_monitor_uart)::get(null,"","spi_mon_if",spi_mon_if))
`uvm_fatal("SPI_MON","could not get the desired interface from the config db")
endfunction

virtual task run_phase(uvm_phase phase);
super.run_phase(phase);
forever begin//mirror forever block.
while(!(spi_mon_if.mon_spi_cb.PENABLE && spi_mon_if.mon_spi_cb.PREADY && spi_mon_if.mon_spi_cb.PSEL2))
    @(spi_mon_if.mon_cb);
    if(uart_mon_if.mon_spi_cb.write_req)begin
        case(spi_mon_if.mon_cb.PADDR)
        32'h40010000:tx_data_reg_mirror<=spi_mon_if.mon_spi_cb.PWDATA;
        32'h4001000C:control_reg_mirror<=spi_mon_if.mon_spi_cb.PWDATA;
        32'h40010010:baud_div_mirror<=spi_mon_if.mon_spi_cb.PWDATA;
        endcase
    end
end

forever begin// miso block // sampled bit
spi_item_miso=spi_sequence_item::type_id::create("spi_item_miso",this);

spi_item_miso.local_tx_data_reg<=tx_data_reg_mirror;
spi_item_miso.local_control_reg<=control_reg_mirror;
spi_item_miso.local_baud_div_reg<=baud_div_mirror;

wait(control_reg_mirror[0]==1);
for(int i=0;i<8;i++)begin
case({control_reg_mirror[1],control_reg_mirror[2]})
2'b00: begin
    @(posedge spi_mon_if.mon_spi_cb);
    spi_item_miso.actual_tx_data_reg<={spi_mon_if.mon_spi_cb.MOSI,spi_item_miso.actual_tx_data_reg[7:1]};
end
2'b01:begin
    @(negedge spi_mon_if.mon_spi_cb);
    spi_item_miso.actual_tx_data_reg<={spi_mon_if.mon_spi_cb.MOSI,spi_item_miso.actual_tx_data_reg[7:1]};
end
2'b10:begin
    @(negedge spi_mon_if.mon_spi_cb);
    spi_item_miso.actual_tx_data_reg<={spi_mon_if.mon_spi_cb.MOSI,spi_item_miso.actual_tx_data_reg[7:1]};
end
2'b11:begin
    @(posedge spi_mon_if.mon_spi_cb);
    spi_item_miso.actual_tx_data_reg<={spi_mon_if.mon_spi_cb.MOSI,spi_item_miso.actual_tx_data_reg[7:1]};
end
endcase
end
ap_MISO.write(spi_item_miso);
end

forever begin// mosi block // change bit
spi_item_mosi=spi_sequence_item::type_id::create("spi_item_mosi",this);

spi_item_mosi.local_tx_data_reg<=tx_data_reg_mirror;
spi_item_mosi.local_control_reg<=control_reg_mirror;
spi_item_mosi.local_baud_div_reg<=baud_div_mirror;
wait(control_reg_mirror[0]==1);
for(int i=0;i<8;i++)begin
case({control_reg_mirror[1],control_reg_mirror[2]})
2'b00: begin
    @(negedge spi_mon_if.mon_spi_cb);
    spi_item_mosi.actual_tx_data_reg<={spi_mon_if.mon_spi_cb.MOSI,spi_item_mosi.actual_tx_data_reg[7:1]};
end
2'b01:begin
    @(posedge spi_mon_if.mon_spi_cb);
    spi_item_mosi.actual_tx_data_reg<={spi_mon_if.mon_spi_cb.MOSI,spi_item_mosi.actual_tx_data_reg[7:1]};
end
2'b10:begin
    @(posedge spi_mon_if.mon_spi_cb);
    spi_item_mosi.actual_tx_data_reg<={spi_mon_if.mon_spi_cb.MOSI,spi_item_mosi.actual_tx_data_reg[7:1]};
end
2'b11:begin
    @(negedge spi_mon_if.mon_spi_cb);
    spi_item_mosi.actual_tx_data_reg<={spi_mon_if.mon_spi_cb.MOSI,spi_item_mosi.actual_tx_data_reg[7:1]};
end
endcase
end
ap_MOSI.write(spi_item_mosi);
end
endtask
endclass
// agent class
class spi_agent extends uvm_agent;
`uvm_component_utils(spi_agent)
function new(string name="spi_agent",uvm_component parent=null);
super.new(name,parent);
endfunction

spi_monitor spi_mon;
spi_driver spi_drv;
uvm_sequencer#(spi_sequence_item) spi_seqr;

virtual function void build_phase(uvm_phase phase);
super.build_phase(phase);
spi_mon=spi_monitor::type_id::create("spi_mon",this);
if(get_is_active()==UVM_ACTIVE)begin
    spi_drv=spi_driver::type_id::create("spi_drv",this);
    spi_seqr=uvm_sequence_item#(spi_sequence_item)::type_id::create("spi_seqr",this);
end
endfunction

virtual function void connect_phase(uvm_phase phase);
super.connect_phase(phase);
if(get_is_active()==UVM_ACTIVE)begin
    spi_drv.seq_item_port.connect(spi_seqr.seq_item_export);
end
endfunction
endclass

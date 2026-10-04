class peri_env extends uvm_env;
`uvm_component_utils(peri_env)

function new(string name="peri_env",uvm_componen parent=null);
super.new(name,parent);
endfunction
//agents
apb_agent apb_agent;
gpio_agent gpio_agent;
spi_agent spi_agent;
timer_agent timer_agent;
uart_agent uart_agent;
//RAL
reg_block_uart reg_m_uart;
reg_block_spi reg_m_spi;
reg_block_timer reg_m_timer;
reg_block_gpio reg_m_gpio;
//scoreboard
scoreboard scb;
//adapter and predictor
adapter adapt;
uvm_reg_predictor#(apb_sequence_item) pred;

virtual function void build_phase(uvm_phase phase);
super.build_phase(phase);

apb_agent=apb_agent::type_id::create("apb_agent",this);
gpio_agent=gpio_agent::type_id::create("gpio_agent",this);
spi_agent=spi_agent::type_id::create("spi_agent",this);
timer_agent=timer_agent::type_id::create("timer_agent",this);
uart_agent=uart_agent::type_id::create("uart_agent",this);

reg_m_uart=reg_block_uart::type_id::create("reg_m_uart");
reg_m_uart.build();
reg_m_uart.lock_model();
reg_m_spi=reg_block_spi::type_id::create("reg_m_spi");
reg_m_spi.build();
reg_m_spi.lock_model();
reg_m_timer=reg_block_timer::type_id::create("reg_m_timer");
reg_m_timer.build();
reg_m_timer.lock_model();
reg_m_gpio=reg_block_gpio::type_id::create("reg_m_gpio");
reg_m_gpio.build();
reg_m_gpio.lock_model();

scb=scoreboard::type_id::create("scoreboard",this);

adapt=adapter::type_id::create("adapt");
pred=uvm_reg_predictor#(apb_sequence_item)::type_id::create("pred");
endfunction

virtual function void connect_phase(uvm_phase phase);
super.connect_phase(phase);
//monitor connections to the scoreboard
apb_agent.apb_mon.ap.connect(scb.imp_apb);
uart_agent.uart_mon.ap_tx.connect(scb.imp_uart_tx);
uart_agent.uart_mon.ap_rx.connect(scb.imp_uart_rx);
spi_agent.spi_mon.ap_MISO.connect(scb.imp_spi_tx);
spi_agent.spi_mon.ap_MOSI.connect(scb.imp_spi_rx);
timer_agent.timer_mon.ap.connect(scb.imp_timer);
gpio_agent.gpio_agent.ap.connect(scb.imp_gpio);
//RAL connections
reg_m_uart.default_map.set_sequencer(apb_agent.apb_seqr,adapt);
reg_m_spi.default_map.set_sequencer(apb_agent.apb_seqr,adapt);
reg_m_timer.default_map.set_sequencer(apb_agent.apb_seqr,adapt);
reg_m_gpio.default_map.set_sequencer(apb_agent.apb_seqr,adapt);
apb_agent.apb_mon.ap.connect(pred.bus_in);
pred.adapter=adapt;
endfunction
endclass

class peri_test extends uvm_test;
`uvm_object_utils(peri_test)
function new(string name="peri_test");
super.new(name);
endfunction

peri_env env;

virtual function void build_phase(uvm_phase phase);
super.build_phase(phase);
env=peri_env::type_id::build("env,this");
endfunction

virtual function void end_of_elaboration_phase(uvm_phase phase);
super.end_of_elaboration_phase(phase);
uvm_top.print_topology();
endfunction

virtual task run_phase(uvm_phase phase);
apb_sequence apb_seq;
uart_sequence uart_seq;
spi_sequence spi_seq;
gpio_sequence gpio_seq;
super.run_phase(phase);

apb_seq=apb_sequence::type_id::create("apb_seq");
uart_seq=uart_sequence::type_id::create("uart_seq");
spi_seq=spi_sequence::type_id::create("spi_seq");
gpio_seq=gpio_sequence::type_id::create("gpio_seq");

apb_seq.reg_m_uart=env.reg_m_uart;
apb_seq.reg_m_spi=env.reg_m_spi;
apb_seq.reg_m_timer=env.reg_m_timer;
apb_seq.reg_m_gpio=env.reg_m_gpio;

phase.raise_objection(this);
fork
apb_seq.start(env.apb_agent.apb_seqr);
uart_seq.start(env.uart_agent.uart_seqr);
spi_seq.start(env.spi_agent.spi_seqr);
gpio_seq.start(env.gpio_agent.gpio_seqr);
join
phase.drop_objection(this);
endtask
endclass
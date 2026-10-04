package  peri_pkg;
import uvm_pkg::*;
`include "uvm_macros.svh"
//agents
`include "../agent_APB/agent_apb.sv"
`include "../agent_GPIO/GPIO_agent.sv"
`include "../agent_SPI/agent_spi.sv"
`include "../agent_TIMER/agent_timer.sv"
`include "../agent_UART/agent_uart.sv"
//RALs
`include "../RAL/GPIO_RAL.sv"
`include "../RAL/SPI_RAL.sv"
`include "../RAL/TIMER_RAL.sv"
`include "../RAL/UART_RAL.sv"
//scorebaord
`include "../scoreboard/scorebaord.sv"
//environment
`include "../environment/env.sv"
//sequences
`include "../sequences/apb_sequence.sv"
`include "../sequences/gpio_sequence.sv"
`include "../sequences/spi_sequence.sv"
`include "../sequences/uart_sequence.sv"
//tests
`include "../tests/peri_test.sv"
endpackage
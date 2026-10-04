class gpio_sequence extends uvm_sequence#(gpio_sequence_item);
`uvm_object_utils(gpio_sequence)

function new(string name="gpio_sequence");
super.new(name);
endfunction

gpio_sequence_item gpio_item;
virtual task body();
start_item(gpio_item);
gpio_item.randomize();
finish_item(gpio_item);
endtask
endclass

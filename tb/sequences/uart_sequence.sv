class uart_sequence extends uvm_sequence#(uart_sequence_item);
`uvm_object_utils(uart_sequence)
function new(string name="uart_sequence");
super.new(name);
endfunction

uart_sequence_item uart_item;

virtual task body();
int num_of_bits=10;
for(int i=0;i<num_of_bits;i++)begin
if(i==0)begin
start_item(uart_item);
uart_item.Rx=0;
finish_item(uart_item);
end
else if(i==9)begin
start_item(uart_item);
uart_item.Rx=1;
finish_item(uart_item);
end
else begin
    start_item(uart_item);
    uart_item.randomize();
    finish_item(uart_item);
end
end
endtask;
endclass

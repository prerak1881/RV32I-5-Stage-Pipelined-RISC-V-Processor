class spi_sequence extends uvm_sequence#(spi_sequence_item);
`uvm_object_utils(spi_sequence)

function new(string name="spi_sequence");
super.new(name);
endfunction

int num_of_bits=8;
spi_sequence_item spi_item;

virtual task body();
for (int i=0;i<num_of_bits;i++)begin
    start_item(spi_item);
    spi_item.randomize();
    finish_item(spi_item);
end
endtask

endclass

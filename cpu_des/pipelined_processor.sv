`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 26.06.2026 21:15:45
// Design Name: 
// Module Name: top_cpu
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
module alu_des(input logic [3:0]alu_control,
input logic[31:0]rs1_val,rs2_val,
output logic[31:0]alu_res,
output logic zero,greater);
initial begin
case(alu_control)
4'b0000:alu_res=rs1_val+rs2_val;//ADD
4'b0001:alu_res=rs1_val-rs2_val;//SUB
4'b0010:alu_res=rs1_val&rs2_val;//AND
4'b0011:alu_res=rs1_val | rs2_val;//OR
4'b0100:alu_res=rs1_val<<rs2_val;//sll logical shift left
4'b0101:alu_res=rs1_val>>>rs2_val;//sra arithematic shift right
4'b0110:alu_res=rs1_val>>rs2_val;//srl logical shift right
4'b0111:alu_res=rs1_val^rs2_val;//xor 
4'b1000:begin// slt (set if less than)
if(rs1_val<rs2_val)
alu_res=32'd1;
else
alu_res=32'd0;
end
4'b1001:begin// beq 
if(rs1_val==rs2_val)
zero=1'b1;
else if(rs1_val!=rs2_val)
zero=1'b0;
end
4'b1010:begin// bne
if(rs1_val!=rs2_val)
zero=1'b0;
else 
zero=1'b1;
end
4'b1011:begin// bge
if(rs1_val>=rs2_val)
greater=1'b1;
else
greater=1'b0;
end
4'b1100:begin//blt
if(rs1_val<rs2_val)
greater=1'b0;
else
greater<=1'b1;
end
default:begin
alu_res=32'b0;
zero=1'b0;
greater=1'b0;
end
endcase
end
endmodule
module top_cpu(input PCLK, 
output logic[31:0]CPU_ADDR,CPU_WDATA,
input logic[31:0]CPU_RDATA,
input logic PENABLE,PREADY,
output logic write_req,read_req);
logic [31:0]PC;
logic [31:0]REG_FILE[32];    //32 registers of 32 bits each
logic [7:0]inst_memory[1024];// 1 KB of instruction memory(1024) addresses 
logic[7:0]data_memory[1024]; // 1KB of data memory
logic[31:0] instruction,target_address;// target_address to be calculated in the execute staage itself
logic[11:0]imm;
logic[6:0]funct7,opcode;
logic[2:0]funct3;
logic[4:0]rs1,rs2,rd;
logic [31:0] rs1_val,rs2_val;
logic zero,greater;
logic [31:0]alu_input2;
typedef struct{
logic [31:0]pc;
logic regdest,regwrite,alusrc,branch,pcsrc,memread,memwrite,memtoreg;// PCSrc is driven by the result of ALU zero and branch controlsignal
logic [4:0]rd,rs1,rs2,write_reg;                                         //PcSrc alone is not a control signal.
//logic [4:0]write_register_val;
logic[31:0]immediate;
logic [31:0]rs1_val,rs2_val,alu_result,mem_result;                        // writing all the structure variables in lowercase 
logic[3:0]alu_control;
logic [1:0] forwardA,forwardB;
}stored_values;                                                // Inside the combinational blocks we will use Uppercase.
stored_values IF_ID;
stored_values ID_EX;
stored_values EX_MEM;
stored_values MEM_WB;
initial begin
IF_ID='{default:0};
ID_EX='{default:0};
EX_MEM='{default:0};
MEM_WB='{default:0};
end
logic stall_IF,stall_ID,stall_EX,stall_MEM;


//alu instantiaton
alu_des a1(ID_EX.alu_control,ID_EX.rs1_val,alu_input2,ID_EX.alu_result,zero,greater);
//Instruction Fetch stage


always_ff @(posedge PCLK)begin:IF_STAGE
instruction[7:0]<=inst_memory[PC];
instruction[15:8]<=inst_memory[PC+1];
instruction[23:16]<=inst_memory[PC+2];
instruction[31:24]<=inst_memory[PC+3];
end:IF_STAGE
always_comb begin
case(ID_EX.branch)
1'b1:begin
PC<=IF_ID.pc+target_address;
end
1'b0:PC<=PC+4;
endcase
end


//Instruction Decode stage
always_ff@(posedge PCLK)begin:ID_STAGE
opcode<=instruction[6:0];
IF_ID.pc<=PC;
end:ID_STAGE
always_comb begin
if(ID_EX.branch)begin
IF_ID='{default:0};
end
case(opcode)// assignment of funct7,funct3, rs,rd values 
7'b0110011:begin// R-type format.
funct7=instruction[31:25];
IF_ID.rs2=instruction[24:20];
IF_ID.rs1=instruction[19:15];
funct3=instruction[14:12];
IF_ID.rd=instruction[11:7];
IF_ID.rs1_val=REG_FILE[IF_ID.rs1];
IF_ID.rs2_val=REG_FILE[IF_ID.rs2];
IF_ID.write_reg=IF_ID.rd;
end
7'b0010011:begin// I-type format.
imm=instruction[31:20];
IF_ID.immediate={{20{imm[11]}},imm};
IF_ID.rs1=instruction[19:15];
IF_ID.rs1_val=REG_FILE[IF_ID.rs1];
funct3=instruction[14:12];
IF_ID.rd=instruction[11:7];
IF_ID.write_reg=IF_ID.rd;
end
7'b0000011:begin//I-type format (load instruction only)(lw)
imm=instruction[31:20];
IF_ID.immediate={{20{imm[11]}},imm};
IF_ID.rs1=instruction[19:15];
IF_ID.rs1_val=REG_FILE[IF_ID.rs1];
funct3=instruction[14:12];
IF_ID.rd=instruction[11:7];
IF_ID.write_reg=IF_ID.rd;
end
7'b0100011:begin// S-type format (store instruction only)(sw)
imm={instruction[31:25],instruction[11:6]};
IF_ID.immediate={{20{imm[11]}},imm};
IF_ID.rs2=instruction[24:20];
IF_ID.rs1=instruction[19:15];
funct3=instruction[14:12];
IF_ID.rs1_val=REG_FILE[IF_ID.rs1];
IF_ID.rs2_val=REG_FILE[IF_ID.rs2];
end
7'b1100011:begin // B-type format
imm={instruction[31],instruction[7],instruction[30:25],instruction[11:8]};
IF_ID.immediate={{20{imm[11]}},imm};
IF_ID.immediate=IF_ID.immediate<<1;
IF_ID.rs2=instruction[24:20];
IF_ID.rs1=instruction[19:15];
funct3=instruction[14:12];
target_address=IF_ID.immediate;
IF_ID.rs1_val=REG_FILE[IF_ID.rs1];
IF_ID.rs2_val=REG_FILE[IF_ID.rs2];
end
endcase
case(opcode)// control signal assignments.
7'b0110011:begin//R-type format
IF_ID.regdest=1'b1;
IF_ID.regwrite=1'b1;
IF_ID.alusrc=1'b0;
IF_ID.pcsrc=1'b0;
IF_ID.memread=1'b0;
IF_ID.memwrite=1'b0;
IF_ID.memtoreg=1'b0;
if(funct7==7'b0000000)begin
if (funct3==3'b000)      //ADD
IF_ID.alu_control=4'b0000;
else if (funct3==3'b111) //AND
IF_ID.alu_control=4'b0010;
else if (funct3==3'b110) //OR
IF_ID.alu_control=4'b0011;
else if (funct3==3'b001) //sll
IF_ID.alu_control=4'b0100;
else if (funct3==3'b010) //slt
IF_ID.alu_control=4'b1000;
else if (funct3==3'b101) //srl
IF_ID.alu_control=4'b0110;
else if (funct3==3'b100) //xor
IF_ID.alu_control=4'b0111;
end
else if (funct7==7'b0100000)begin
if(funct3==3'b000)       //or
IF_ID.alu_control=4'b0001;
else if (funct3==3'b101) //sra
IF_ID.alu_control=4'b0101;
end
end
7'b0010011:begin// I-type format
IF_ID.regdest=1'b0;
IF_ID.regwrite=1'b1;
IF_ID.alusrc=1'b1;
IF_ID.pcsrc=1'b0;
IF_ID.memread=1'b0;
IF_ID.memwrite=1'b0;
IF_ID.memtoreg=1'b0;
if(funct3==3'b000)
IF_ID.alu_control=4'b0000;
else if(funct3==3'b100)
IF_ID.alu_control=4'b0111;
end
7'b0000011:begin// lw instruction
IF_ID.regdest=1'b0;
IF_ID.regwrite=1'b1;
IF_ID.alusrc=1'b1;
IF_ID.pcsrc=1'b0;
IF_ID.memread=1'b1;
IF_ID.memwrite=1'b0;
IF_ID.memtoreg=1'b1;
end
7'b0100011:begin// sw instruction
IF_ID.regdest=1'b0;
IF_ID.regwrite=1'b0;
IF_ID.alusrc=1'b1;
IF_ID.pcsrc=1'b0;
IF_ID.memread=1'b0;
IF_ID.memwrite=1'b1;
IF_ID.memtoreg=1'b0;
end
7'b1100011:begin// branch instruction
IF_ID.regdest=1'b0;
IF_ID.regwrite=1'b0;
IF_ID.alusrc=1'b0;
IF_ID.pcsrc=1'b1;
IF_ID.memread=1'b0;
IF_ID.memwrite=1'b0;
IF_ID.memtoreg=1'b0;
end
endcase

end


//Execution Stage
always_ff@(posedge PCLK)begin:EX_STAGE
//ID_EX.rs1_val<=IF_ID.rs1_val;
//ID_EX.rs2_val<=IF_ID.rs2_val;
//ID_EX.forwardA<=ID_EX.branch?0:IF_ID.forwardA;
//ID_EX.forwardB<=ID_EX.branch?0:IF_ID.forwardB;
ID_EX.write_reg<=ID_EX.branch?0:IF_ID.write_reg;
ID_EX.pc<=ID_EX.branch?ID_EX.branch:IF_ID.pc;
ID_EX.immediate<=ID_EX.branch?ID_EX.branch:IF_ID.immediate;
ID_EX.alu_control<=ID_EX.branch?0:IF_ID.alu_control;
ID_EX.rs1<=ID_EX.branch?0:IF_ID.rs1;
ID_EX.rs2<=ID_EX.branch?0:IF_ID.rs2;
ID_EX.rd<=ID_EX.branch?0:IF_ID.rd;
ID_EX.regdest<=ID_EX.branch?0:IF_ID.regdest;
ID_EX.regwrite<=ID_EX.branch?0:IF_ID.regwrite;
ID_EX.alusrc<=ID_EX.branch?0:IF_ID.alusrc;
ID_EX.branch<=ID_EX.branch?0:IF_ID.branch;
ID_EX.memread<=ID_EX.branch?0:IF_ID.memread;
ID_EX.memwrite<=ID_EX.branch?0:IF_ID.memwrite;
ID_EX.memtoreg<=ID_EX.branch?0:IF_ID.memtoreg;
end:EX_STAGE

always_comb begin
if(EX_MEM.regwrite)begin
if(EX_MEM.rd==ID_EX.rs1)
ID_EX.forwardA=2'b10;
if (EX_MEM.rd==ID_EX.rs2)
ID_EX.forwardB=2'b10;
end
if(MEM_WB.regwrite)begin
if((EX_MEM.rd!=ID_EX.rs1) & (MEM_WB.rd==ID_EX.rs1)) 
ID_EX.forwardA=2'b01;
if((EX_MEM.rd!=ID_EX.rs2) & (MEM_WB.rd==ID_EX.rs2)) 
ID_EX.forwardB=2'b01;
end
case(ID_EX.forwardA)
2'b10:begin
ID_EX.rs1_val=ID_EX.branch?0:EX_MEM.alu_result;
end
2'b01:begin
if(MEM_WB.memtoreg)
ID_EX.rs1_val=ID_EX.branch?0:MEM_WB.mem_result;
else
ID_EX.rs1_val=ID_EX.branch?0:MEM_WB.alu_result;
end
default:begin
ID_EX.rs1_val=ID_EX.branch?0:REG_FILE[ID_EX.rs1];
end
endcase
case(ID_EX.forwardB)
2'b10:begin
ID_EX.rs2_val=ID_EX.branch?0:EX_MEM.alu_result;
end
2'b01:begin
if(MEM_WB.memtoreg)
ID_EX.rs2_val=ID_EX.branch?0:MEM_WB.mem_result;
else
ID_EX.rs2_val=ID_EX.branch?0:MEM_WB.alu_result;
end
default:begin
ID_EX.rs2_val=ID_EX.branch?0:REG_FILE[ID_EX.rs2];
end
endcase
if(ID_EX.alusrc)
alu_input2=ID_EX.immediate;
else
alu_input2=ID_EX.rs2_val;
if(ID_EX.alu_control== 4'b0100 || ID_EX.alu_control== 4'b0101 ||ID_EX.alu_control== 4'b0110)
alu_input2=alu_input2 && 32'd31;
if(ID_EX.alu_control==4'b1001 && zero==1'b1 && IF_ID.pcsrc==1'b1)
ID_EX.branch=1'b1;
else
ID_EX.branch=1'b0;
if(ID_EX.alu_control==4'b1010 && zero==1'b0 && IF_ID.pcsrc==1'b1)
ID_EX.branch=1'b1;
else
ID_EX.branch=1'b0;
if(ID_EX.alu_control==4'b1011 && greater==1'b1 && IF_ID.pcsrc==1'b1)
ID_EX.branch=1'b1;
else
ID_EX.branch=1'b0;
if(ID_EX.alu_control==4'b1100 && greater==1'b0 && IF_ID.pcsrc==1'b1)
ID_EX.branch=1'b1;
else
ID_EX.branch=1'b0;
end


//Memory Management stage
always_ff@(posedge PCLK)begin:MEM_STAGE
EX_MEM<=ID_EX;
if(ID_EX.alu_result[31:12]==20'h40000 || 20'h40001 || 20'h40002 || 20'h40003)begin
CPU_ADDR<=ID_EX.alu_result;
if(ID_EX.memwrite)begin//SW
read_req<=1;
write_req<=0;
if(PENABLE && PREADY)begin
data_memory[ID_EX.alu_result]<=CPU_RDATA;
stall_ID<=0;
stall_IF<=0;
stall_EX<=0;
stall_MEM<=0;
end
else begin
stall_ID<=1;
stall_IF<=1;
stall_EX<=1;
stall_MEM<=1;
end
end
else if (ID_EX.memread)begin//LW
read_req<=0;
write_req<=1;
CPU_WDATA<=data_memory[ID_EX.alu_result];
if(PENABLE && PREADY)begin
stall_ID<=0;
stall_IF<=0;
stall_EX<=0;
stall_MEM<=0;
end
else begin
stall_ID<=1;
stall_IF<=1;
stall_EX<=1;
stall_MEM<=1;
end
end
end
else begin
stall_ID<=0;
stall_IF<=0;
stall_EX<=0;
stall_MEM<=0;
if(ID_EX.memread)
EX_MEM.mem_result<=data_memory[ID_EX.alu_result];//LW
else if(ID_EX.memwrite)
data_memory[ID_EX.alu_result]<=REG_FILE[ID_EX.rd];//SW
end
end:MEM_STAGE


//Write Back stage
always_ff@(posedge PCLK)begin:WB_STAGE
end:WB_STAGE
endmodule

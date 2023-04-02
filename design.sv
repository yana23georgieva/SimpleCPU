// Code your design here

`timescale 1ps/1ps

module async_mem_2port(input WE0, WE1,
                       input[3:0] WrData0, WrData1,
                       input[5:0] Addr0, Addr1,
                       output[3:0] RdData0, RdData1);
  reg[3:0]mem[1:16];
  
  always@(*) begin
    if(WE0)
      mem[Addr0] = WrData0; 
    if(WE1)
      mem[Addr1] = WrData1;
  end
  
  assign RdData0 = mem[Addr0];
  
  assign RdData1 = mem[Addr1];
  
endmodule

module sync_mem_2port(input WE0, WE1,
                      input clk,
                      input[3:0] WrData0, WrData1,
                      input[5:0] Addr0, Addr1,
                      output[3:0] RdData0, RdData1);
  
  wire we_sync0, we_sync1;
  wire[3:0] wrData_sync0, wrData_sync1;
  wire[5:0] addr_sync0, addr_sync1;
  
  flipFlop#(1) ff1(.clk(clk), .DataIn(WE0), .DataOut(we_sync0));
  flipFlop#(4) ff2(.clk(clk), .DataIn(WrData0), .DataOut(wrData_sync0));
  flipFlop#(6) ff3(.clk(clk), .DataIn(Addr0), .DataOut(addr_sync0));
  
  flipFlop#(1) ff1_1(.clk(clk), .DataIn(WE1), .DataOut(we_sync1));
  flipFlop#(4) ff2_1(.clk(clk), .DataIn(WrData1), .DataOut(wrData_sync1));
  flipFlop#(6) ff3_1(.clk(clk), .DataIn(Addr1), .DataOut(addr_sync1));

  async_mem_2port a1(.WE0(we_sync0), .WE1(we_sync1), .WrData0(wrData_sync0), 
                     .WrData1(wrData_sync1), .Addr0(addr_sync0),
                     .Addr1(addr_sync1), .RdData0(RdData0),
                     .RdData1(RdData1));
  
endmodule

module ALU(input[5:0] ALU_IN0, 
           input[2:0] CMD_ID_S3, 
           input[5:0] ALU_IN1,
           output reg[5:0] ALU_OUT);

// ALU Execution
always@(*)
	begin
	case (CMD_ID_S3)
      3'b000: ALU_OUT = ALU_IN1 + 1;
      3'b001: ALU_OUT = ALU_IN1 - 1;
      3'b010: ALU_OUT = ~ALU_IN1;
      3'b011: ALU_OUT = &ALU_IN1;
      3'b100: ALU_OUT = |ALU_IN1;
      3'b101: ALU_OUT = ALU_IN0 + ALU_IN1;
      3'b110: ALU_OUT = ALU_IN0 - ALU_IN1;
      default: ALU_OUT = 3'b111;
	endcase
	end
endmodule

module coproc(input clk, reset,
              input[5:0] instr, // op1_id
              input[5:0] op0_id,
              input [2:0] cmd_id);
  
  wire[5:0] S1_instr, addrs1_sync, addrs2_sync, addrs3_sync, addrs4_sync;
  wire[5:0] mem_out_sync0, mem_out_sync1, mem_out1, mem_out0, result_reg, mem_out_sync_increment;
  wire[2:0] cmd1_out, cmd2_out, cmd3_out, cmd4_out;

  //Stage 1
  flipFlop_reset#(6) ff1(.clk(clk), .reset(reset), .DataIn(instr), .DataOut(S1_instr));
  flipFlop_reset#(6) addrs1(.clk(clk), .reset(reset), .DataIn(instr), .DataOut(addrs1_sync));
  flipFlop_reset#(3) cmd1(.clk(clk), .reset(reset), .DataIn(cmd_id), .DataOut(cmd1_out));
  
  //Stage 2
  //sync_mem_2port sm(.WE0(1'b0), .WE1(1'b0), .clk(clk), .WrData0(4'b0),
  //                  .WrData1(result_reg), .Addr0(S1_instr), 
  //                  .Addr1(addrs4_sync), .RdData0(mem_out1), 
  //                  .RdData1(mem_out0/*not conected*/));
  
  REGFILE3P REGFILE3P_instance(
// PORT0 OP0 inputs and outputs
    .ADDR0(op0_id), 
    .WD0(6'b0),
    .WE0(0),
    .RD0(mem_out0),

// PORT1 OP1 inputs and outputs
    .ADDR1(instr),
    .WD1(6'b0),
    .WE1(0),
    .RD1(mem_out1),

// WRITE BACK PORT
    .ADDRWB(addrs4_sync), 
    .WDWB(result_reg), 
    .WEWB(1'b1),
    .RDWB(),
    .clk(clk),
    .reset(reset));
  
  flipFlop_reset#(6) addrs2(.clk(clk), .reset(reset), .DataIn(addrs1_sync), .DataOut(addrs2_sync));
  flipFlop_reset#(3) cmd2(.clk(clk), .reset(reset), .DataIn(cmd1_out), .DataOut(cmd2_out));
  
  //Addrs1 == Addrs4
  wire[5:0] depend_s1s4, depend_s2s4, depend_s3s4, wb_reg;
  wire addrs1s4;
  
  flipFlop_reset#(1) addrs1s4reg(.clk(clk), .reset(reset), .DataIn(addrs1_sync == addrs4_sync), .DataOut(addrs1s4));

  assign depend_s1s4 = (addrs1s4 == 1)?wb_reg:mem_out1;
  
  flipFlop_reset#(6) addrs1s4mux(.clk(clk), .reset(reset), .DataIn(result_reg), .DataOut(wb_reg));
  
  //Addrs2 == Addrs4
  assign depend_s2s4 = (addrs2_sync == addrs4_sync)?result_reg:depend_s1s4;
  
  
  //Stage 3
  flipFlop_reset#(6) ff2(.clk(clk), .reset(reset), .DataIn(depend_s2s4), .DataOut(mem_out_sync1));
  flipFlop_reset#(6) addrs3(.clk(clk), .reset(reset), .DataIn(addrs2_sync), .DataOut(addrs3_sync));
  flipFlop_reset#(3) cmd3(.clk(clk), .reset(reset), .DataIn(cmd2_out), .DataOut(cmd3_out));
  
  flipFlop_reset#(6) ffmout0(.clk(clk), .reset(reset), .DataIn(mem_out0), .DataOut(mem_out_sync0));
  
  //Addrs3 == Addrs4
  assign depend_s3s4 = (addrs3_sync == addrs4_sync)?result_reg:mem_out_sync1;
  
  //Stage 4
  //assign mem_out_sync_increment = depend_s3s4 + 1;
  wire [5:0] RdData_sync_increment;
  
  ALU my_alu(.ALU_IN0(mem_out_sync0), 
    		 .ALU_IN1(depend_s3s4), 
             .CMD_ID_S3(cmd3_out), 
             .ALU_OUT(RdData_sync_increment));
  
  flipFlop_reset#(6) ff3(.clk(clk), .reset(reset), .DataIn(mem_out_sync_increment), .DataOut(result_reg));
  flipFlop_reset#(6) addrs4(.clk(clk), .reset(reset), .DataIn(addrs3_sync), .DataOut(addrs4_sync));
  flipFlop_reset#(3) cmd4(.clk(clk), .reset(reset), .DataIn(cmd3_out), .DataOut(cmd4_out));
  
  flipFlop_reset#(6) S4_result_reg(.clk(clk), .reset(reset), .DataIn(RdData_sync_increment), .DataOut(result_reg));
endmodule
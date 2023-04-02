// Code your testbench here
// or browse Examples

`timescale 1ps/1ps

module tb();
  
  reg WE, clk, reset, start;
  reg[14:0] WrData, RdData;
  reg[5:0] DataOut;
  
  counter16 u_counter16(.clk(clk),
                        .reset(reset),
                        .start(start),
                        .DataOut(DataOut));
  
  sync_mem u_sync_mem(.WE(WE),
                      .clk(clk),
                      .WrData(WrData),
                      .Addr(DataOut),
                      .RdData(RdData));
  
  coproc u_coproc(.clk(clk),
                  .reset(reset),
                  .instr(RdData[5:0]),
                  .op0_id(RdData[11:6]),
                  .cmd_id(RdData[14:12]));
  
  initial begin
    clk = 1'b0;
    forever #20 clk = ~clk;
  end
  
 initial begin
   $readmemb("instruction.mem", u_sync_mem.a1.mem, 1, 16);
   $readmemb("two_sync_mem_init.init", u_coproc.REGFILE3P_instance.MEM, 1, 63);
   #50
    WE=1'b0;
   	reset=1'b0;
   #50
   	reset=1'b1;
   	start=1'b1;
   #700
   	$finish;
 end
  
  initial begin
    $dumpfile("dump.vcd");
    $dumpvars();
  end
  
endmodule
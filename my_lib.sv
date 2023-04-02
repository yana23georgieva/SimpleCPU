// Code your design here

`timescale 1ps/1ps

module async_mem(input WE,
                 input[14:0] WrData,
                 input[5:0] Addr,
                 output[14:0] RdData);
  reg[14:0]mem[1:16];
  
  always@(*) begin
    if(WE)
      mem[Addr] = WrData; 
  end
  
  assign RdData = !WE?mem[Addr]:15'b0;
  
endmodule

module flipFlop #(parameter SIZE=1) (input clk,
                                     input[SIZE - 1:0] DataIn,
                                     output reg[SIZE - 1:0] DataOut);
  always@(posedge clk) begin
    DataOut <= DataIn;
  end
endmodule

module sync_mem(input WE,
                input clk,
                input[14:0] WrData,
                input[5:0] Addr,
                output[14:0] RdData);
  
  wire we_sync;
  wire[14:0] wrData_sync;
  wire[5:0] addr_sync;
  flipFlop#(1) ff1(.clk(clk), .DataIn(WE), .DataOut(we_sync));
  flipFlop#(15) ff2(.clk(clk), .DataIn(WrData), .DataOut(wrData_sync));
  flipFlop#(6) ff3(.clk(clk), .DataIn(Addr), .DataOut(addr_sync));
  
  async_mem a1(.WE(we_sync), .WrData(wrData_sync), .Addr(addr_sync), .RdData(RdData));
  
endmodule

module flipFlop_reset #(parameter SIZE=1) (input clk, reset,
                                           input[SIZE - 1:0] DataIn,
                                           output reg[SIZE - 1:0] DataOut);
  
  always@(posedge clk or negedge reset) begin
    if(~reset) begin
      DataOut <= 0;
    end
    else begin
    	DataOut <= DataIn;
    end
  end
endmodule

module counter16 (input clk,
                 input reset,
                 input start,
                 output reg[5:0] DataOut);
  
  always@(posedge clk or negedge reset) begin
    if(~reset || DataOut == 6'b010000) begin
      DataOut <= 6'b1;
    end
    else if(start) begin
    	DataOut <= DataOut + 1;
    end
    else
      DataOut <= DataOut;
  end
endmodule

module REGFILE3P (
// PORT0 OP0 inputs and outputs
  input[5:0] ADDR0, 
  input[5:0] WD0,
  input WE0,
  output[5:0] RD0,

// PORT1 OP1 inputs and outputs
  input[5:0] ADDR1,
  input[5:0] WD1, 
  input WE1,
  output[5:0] RD1,

// WRITE BACK PORT
  input[5:0] ADDRWB, 
  input[5:0] WDWB, 
  input WEWB,
  output[5:0] RDWB,

// Common ports
  input clk,
  input reset);

  reg [5:0] MEM [1:63]; // Register File Memory

// Port 0
  reg[5:0] ADDR0_reg; 
  reg WD0_reg, WE0_reg;

// Port 1
  reg[5:0] ADDR1_reg;
  reg WD1_reg, WE1_reg;

// WB Port
  reg[5:0] ADDRWB_reg;
  reg[5:0] WDWB_reg;
  reg WEWB_reg;
  always@(posedge clk or negedge reset)
begin
  if(~reset) begin 
    // Port 0
    ADDR0_reg <= 1;
    WD0_reg <= 0;
    WE0_reg <= 0;
    // Port 1
    ADDR1_reg <= 1;
    WD1_reg <= 0;
    WE1_reg <= 0;
    // WB Port
    ADDRWB_reg <= 1;
    WDWB_reg <= 0;
    WEWB_reg <= 0;
  end
  else begin
    // Port 0
    ADDR0_reg <= ADDR0;
    WD0_reg <= WD0;
    WE0_reg <= WE0;
    // Port 1
    ADDR1_reg <= ADDR1;
    WD1_reg <= WD1;
    WE1_reg <= WE1;
    // WB Port
    ADDRWB_reg <= ADDRWB;
    WDWB_reg <= WDWB;
    WEWB_reg <= WEWB;
  end
end

  // Port 0 read
  assign RD0 = MEM[ADDR0_reg];

  // Port 1 read
  assign RD1 = MEM[ADDR1_reg];

  // WB Port
  always@(*) begin
    if (WEWB_reg==1'b1) 
      MEM[ADDRWB_reg] = WDWB_reg;
  end

endmodule
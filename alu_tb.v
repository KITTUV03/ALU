`define WIDTH 8
`define VALID_M 2
`define OPERATION 4

module tb;
    reg CLK;
    reg RST;
    reg [`VALID_M-1:0] INP_VALID;
	reg  MODE; 
    reg [`OPERATION-1:0] CMD; 
	reg CE;
    reg [`WIDTH-1:0] OPA;
    reg [`WIDTH-1:0] OPB;
    reg CIN;
    wire ERR; 
    wire [2*`WIDTH-1:0] RES; 
	wire OFLOW;
	wire COUT;
	wire G; 
	wire L;
	wire E;
  
  ALU_DESIGN dut(CLK,RST,INP_VALID,MODE,CMD,CE,OPA,OPB,CIN,ERR,RES,OFLOW,COUT,G,L,E);
  
// //     ALU dut(OPA,OPB,CIN,CLK,RST,CE,MODE,INP_VALID,CMD,RES,OFLOW,COUT,G,L,E,ERR);

  
//     alu dut(.clk(CLK),.rst(RST),.inp_valid(INP_VALID),.mode(MODE),.cmd(CMD),.ce(CE),.opa(OPA),.opb(OPB),.cin(CIN),.err(ERR),.res(RES),.oflow(OFLOW),.cout(COUT),.G(G),.L(L),.E(E));
  
  
  initial begin
    CLK=1'b0;
    forever #5 CLK=~CLK;
  end
  
  task arithmetic_inputs;
    MODE = 1'b1;
    CE=1'b1;
    RST = 1'b0;
    INP_VALID = 2'b11;
    
    for(int i=0;i<14;i++) begin
     //       OPA = $urandom();
      OPA = 10;
//       OPB = $urandom();
            OPB = 5;
      CMD = i;
      CIN = $urandom();
      @(posedge CLK);
    end
    
  endtask
  
   task logic_inputs;
    MODE = 1'b0;
    CE=1'b1;
    RST = 1'b0;
    INP_VALID = 2'b11;
    
    for(int i=0;i<14;i++) begin
//       OPA = $urandom();
      OPA = 10;
//       OPB = $urandom();
      OPB = 5;
      CMD = i;
      CIN = $urandom();
      @(posedge CLK);
    end
    
  endtask
  
  task reset;
    RST=1'b1;
    repeat(2)
      @(posedge CLK);
    
    RST=1'b0;
  endtask
  
  
  
  task multiplication;
    MODE = 1'b1;
    CE=1'b1;
    RST = 1'b0;
    INP_VALID = 2'b11;
    CMD = 9;
    OPA = 10;
    OPB = 5;
      CIN = $urandom();
    repeat(2) 
      @(posedge CLK);
    OPA=8;
    OPB=9;
    repeat(3) 
      @(posedge CLK);
    
  endtask
  
  initial begin
    reset;
    arithmetic_inputs;
    logic_inputs;
    multiplication;
    repeat(3)
      @(posedge CLK);
    $finish;
  end
  
  initial begin
    $dumpfile("dump.vcd");
    $dumpvars;
  end
  
endmodule

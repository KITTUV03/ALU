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
	integer i;
  
  ALU_DESIGN dut(CLK,RST,INP_VALID,MODE,CMD,CE,OPA,OPB,CIN,ERR,RES,OFLOW,COUT,G,L,E);
  
//     ALU2 dut(CLK, RST, MODE, CE,INP_VALID, CMD, OPA, OPB, CIN, RES,OFLOW, COUT, G, L, E, ERR);

  
//     vijay dut(.clk(CLK),.rst(RST),.inp_valid(INP_VALID),.mode(MODE),.cmd(CMD),.ce(CE),.opa(OPA),.opb(OPB),.cin(CIN),.err(ERR),.res(RES),.oflow(OFLOW),.cout(COUT),.g(G),.l(L),.e(E));
  
  
  initial begin
    CLK=1'b0;
    forever #5 CLK=~CLK;
  end
  
  task arithmetic_inputs;
    begin
    MODE = 1'b1;
    CE=1'b1;
    RST = 1'b0;
    INP_VALID = 2'b11;
    
    for(i=0;i<14;i=i+1) begin
//             @(negedge CLK);

     //       OPA = $urandom();
      OPA = 10;
//       OPB = $urandom();
            OPB = 5;
      CMD = i;
      CIN = $urandom();
       @(negedge CLK);
    end
    end
  endtask
  
   task logic_inputs;
     begin
    MODE = 1'b0;
    CE=1'b1;
    RST = 1'b0;
    INP_VALID = 2'b11;
    
    for( i=0;i<14;i=i+1) begin
//       @(negedge CLK);
//       OPA = $urandom();
      OPA = 10;
//       OPB = $urandom();
      OPB = 5;
      CMD = i;
      CIN = $urandom();
             @(negedge CLK);

    end
     end
    
  endtask
  
  task reset;
    begin
    RST=1'b1;
    repeat(2)
      @(negedge CLK);
    
    RST=1'b0;
    end
  endtask
  
  
  
  task multiplication;
    begin
    MODE = 1'b1;
    CE=1'b1;
    RST = 1'b0;
    INP_VALID = 2'b11;
    CMD = 9;
    OPA = 10;
    OPB = 5;
    CIN = $urandom();
    repeat(2) 
      @(negedge CLK);
    OPA=8;
    OPB=9;
    repeat(3) 
      @(negedge CLK);
    end
  endtask
  
  initial begin
    reset;
    arithmetic_inputs;
     logic_inputs;
    multiplication;
    repeat(3)
      @(negedge CLK);
    $finish;
  end
  
  
  
endmodule

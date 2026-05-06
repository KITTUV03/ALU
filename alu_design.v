`define VALID_M 2
`define OPERATION 4
`define NONE 3'b000

`define V_NONE      2'b00
`define V_A         2'b01
`define V_B         2'b10
`define V_BOTH      2'b11

`define ADD         4'h0
`define SUB         4'h1
`define ADD_CIN     4'h2
`define SUB_CIN     4'h3
`define INC_A       4'h4
`define DEC_A       4'h5
`define INC_B       4'h6
`define DEC_B       4'h7
`define CMP         4'h8
`define MUL_INC     4'h9
`define MUL_SHL     4'hA
`define SADD        4'hB
`define SSUB        4'hC

`define AND         4'h0
`define NAND        4'h1
`define OR          4'h2
`define NOR         4'h3
`define XOR         4'h4
`define XNOR        4'h5
`define NOT_A       4'h6
`define NOT_B       4'h7
`define SHR1_A      4'h8
`define SHL1_A      4'h9
`define SHR1_B      4'hA
`define SHL1_B      4'hB
`define ROL_A_B     4'hC
`define ROR_A_B     4'hD

module ALU_DESIGN #(parameter WIDTH = 8)
  (
    input CLK,
    input RST,
    input [`VALID_M-1:0] INP_VALID,
    input  MODE, 
    input [`OPERATION-1:0] CMD, 
    input CE,
    input [WIDTH-1:0] OPA,
    input [WIDTH-1:0] OPB,
    input CIN,
    output reg ERR, 
    output reg [2*WIDTH-1:0] RES, 
    output reg OFLOW,
    output reg COUT,
    output reg G, 
    output reg L,
    output reg E
  );
  
  reg [`OPERATION-1:0] prev_cmd;
  reg [1:0]              count;
  reg [WIDTH-1:0]       latch_a, latch_b;   
  reg [2*WIDTH-1:0]     mul_result;          
  reg signed [2*WIDTH-1:0]  signed_result;

  always @(posedge CLK or posedge RST) begin
    if (RST) begin
      ERR        <= 0;
      RES        <= 0;
      OFLOW      <= 0;
      COUT       <= 0;
      G          <= 0;
      L          <= 0;
      E          <= 0;
      count      <= 0;
      latch_a    <= 0;
      latch_b    <= 0;
	  prev_cmd <= 0;
      mul_result <= 0;
    end

    else begin
      if (CE) begin
        if (MODE) begin
          case(CMD)

            `ADD: 
              begin
                {COUT,RES[7:0]}     <= (INP_VALID == `V_BOTH) ? (OPA + OPB) : RES;
                 RES                <= (INP_VALID == `V_BOTH) ? (OPA + OPB) : RES;
                OFLOW   <= 0;
                {G,L,E} <= `NONE;
                ERR     <= ~(INP_VALID == `V_BOTH);
              end
            
            `SUB:
              begin
                RES     <= (INP_VALID == `V_BOTH) ? (OPA - OPB) : RES;
                COUT    <= 0;
                OFLOW   <= (OPB > OPA);
                {G,L,E} <= `NONE;
                ERR     <= ~(INP_VALID == `V_BOTH);
              end
            
            `ADD_CIN: 
              begin
               {COUT,RES[7:0]}     <= (INP_VALID == `V_BOTH) ? (OPA + OPB + CIN) : RES;
                RES     <= (INP_VALID == `V_BOTH) ? (OPA + OPB + CIN) : RES;

                OFLOW   <= COUT;
                {G,L,E} <= `NONE;
                ERR     <= ~(INP_VALID == `V_BOTH);
              end
            
            `SUB_CIN: 
              begin
                RES     <= (INP_VALID == `V_BOTH) ? (OPA - OPB - CIN) : RES;
                COUT    <= 0;
                OFLOW   <= ((OPB + CIN) > OPA);
                {G,L,E} <= `NONE;
                ERR     <= ~(INP_VALID == `V_BOTH);
              end
            
            `INC_A: 
              begin
                RES     <= (INP_VALID == `V_BOTH || INP_VALID == `V_A) ? OPA+1 : RES;
                COUT    <= 1'b0;
                OFLOW   <= 1'b0;
                {G,L,E} <= `NONE;
                ERR     <= ~(INP_VALID == `V_BOTH || INP_VALID == `V_A);
              end
            
            `DEC_A: 
              begin
                RES     <= (INP_VALID == `V_BOTH || INP_VALID == `V_A) ? OPA-1 : RES;
                COUT    <= 1'b0;
                OFLOW   <= 1'b0;
                {G,L,E} <= `NONE;
                ERR     <= ~(INP_VALID == `V_BOTH || INP_VALID == `V_A);
              end
            
            `INC_B: 
              begin
                RES     <= (INP_VALID == `V_BOTH || INP_VALID == `V_B) ? OPB+1 : RES;
                COUT    <= 1'b0;
                OFLOW   <= 1'b0;
                {G,L,E} <= `NONE;
                ERR     <= ~(INP_VALID == `V_BOTH || INP_VALID == `V_B);
              end
            
            `DEC_B: 
              begin
                RES     <= (INP_VALID == `V_BOTH || INP_VALID == `V_B) ? OPB-1 : RES;
                COUT    <= 1'b0;
                OFLOW   <= 1'b0;
                {G,L,E} <= `NONE;
                ERR     <= ~(INP_VALID == `V_BOTH || INP_VALID == `V_B);
              end
            
            `CMP:
              begin
                RES     <= 0;
                COUT    <= 1'b0;
                OFLOW   <= 1'b0;
                {G,L,E} <= {(OPA > OPB),(OPA < OPB),(OPA == OPB)};
                ERR     <= ~(INP_VALID == `V_BOTH);
              end

           `MUL_INC:
                begin	
                  COUT    <= 1'b0;
                  OFLOW   <= 1'b0;
                  {G,L,E} <= `NONE;
                  ERR     <= ~(INP_VALID == `V_BOTH);

                  if (prev_cmd != `MUL_INC)
                    begin
                   	 count      <= 2'd1;
                    
                      if (INP_VALID == `V_BOTH) begin
                          latch_a    <= OPA + 1'b1;
                          latch_b    <= OPB + 1'b1;
                          mul_result <= (OPA + 1'b1) * (OPB + 1'b1);
                        
                    end 
                      
                      else begin
                     	 mul_result <= 0;
                      end
                      
                    RES <= RES;
                  end
                  
                  else if (count == 2'd2) begin
                    RES <= mul_result;
                    if (INP_VALID == `V_BOTH) begin
                      latch_a    <= OPA + 1'b1;
                      latch_b    <= OPB + 1'b1;
                      mul_result <= (OPA + 1'b1) * (OPB + 1'b1);
                    end else begin
                      mul_result <= 0;
                    end
                    count <= 2'd1; // restart
                  end
                  else begin
                    count <= count + 1'b1;
                    RES   <= RES;
                  end

                  prev_cmd <= `MUL_INC;
                end

              `MUL_SHL:
                begin
                  COUT    <= 1'b0;
                  OFLOW   <= 1'b0;
                  {G,L,E} <= `NONE;
                  ERR     <= ~(INP_VALID == `V_BOTH);

                  if (prev_cmd != `MUL_SHL) begin
                    count <= 2'd1;
                    if (INP_VALID == `V_BOTH) begin
                      latch_a    <= OPA << 1;
                      mul_result <= (OPA << 1) * OPB;
                    end else begin
                      mul_result <= 0;
                    end
                    RES <= RES;
                  end
                  else if (count == 2'd2) begin
                    RES <= mul_result;
                    if (INP_VALID == `V_BOTH) begin
                      latch_a    <= OPA << 1;
                      mul_result <= (OPA << 1) * OPB;
                    end else begin
                      mul_result <= 0;
                    end
                    count <= 2'd1;//RE
                  end
                  else begin
                    count <= count + 1'b1;
                    RES   <= RES;
                  end

                  prev_cmd <= `MUL_SHL;
                end
            
            
            `SADD:
              begin
                if (INP_VALID == `V_BOTH) begin
                  signed_result  = $signed({1'b0, OPA}) + $signed({1'b0, OPB});
                  COUT          <= signed_result[WIDTH];
                  RES           <= {{WIDTH{signed_result[WIDTH-1]}}, signed_result[WIDTH-1:0]};
                  OFLOW         <= (OPA[WIDTH-1] == OPB[WIDTH-1]) &&
                                   (signed_result[WIDTH-1] != OPA[WIDTH-1]);
                  G             <= ($signed(OPA) >  $signed(OPB));
                  L             <= ($signed(OPA) <  $signed(OPB));
                  E             <= ($signed(OPA) == $signed(OPB));
                end else begin
                  RES     <= 0;
                  COUT    <= 1'b0;
                  OFLOW   <= 1'b0;
                  {G,L,E} <= `NONE;
                end
                ERR <= ~(INP_VALID == `V_BOTH);
              end

            `SSUB:
              begin
                if (INP_VALID == `V_BOTH) begin
                  signed_result  = $signed({1'b0, OPA}) - $signed({1'b0, OPB});
                  COUT          <= signed_result[WIDTH];
                  RES           <= {{WIDTH{signed_result[WIDTH-1]}}, signed_result[WIDTH-1:0]};
                  OFLOW         <= (OPA[WIDTH-1] != OPB[WIDTH-1]) &&
                                   (signed_result[WIDTH-1] != OPA[WIDTH-1]);
                  G             <= ($signed(OPA) >  $signed(OPB));
                  L             <= ($signed(OPA) <  $signed(OPB));
                  E             <= ($signed(OPA) == $signed(OPB));
                end else begin
                  RES     <= 0;
                  COUT    <= 1'b0;
                  OFLOW   <= 1'b0;
                  {G,L,E} <= `NONE;
                end
                ERR <= ~(INP_VALID == `V_BOTH);
              end

            default: begin
              RES     <= 0;
              COUT    <= 1'b0;
              OFLOW   <= 1'b0;
              {G,L,E} <= `NONE;
            end

          endcase
        end

        else begin
          case(CMD)
              
            `AND: 
              begin
                RES[WIDTH-1:0]     <= (INP_VALID == `V_BOTH) ? (OPA & OPB)  : 0;
                OFLOW   <= 1'b0;  
                COUT <= 1'b0;  
                {G,L,E} <= `NONE;
                ERR     <= ~(INP_VALID == `V_BOTH);
              end
              
            `NAND:
              begin
                RES[WIDTH-1:0]      <= (INP_VALID == `V_BOTH) ? ~(OPA & OPB) : 0;
                OFLOW   <= 1'b0;  
                COUT <= 1'b0;  
                {G,L,E} <= `NONE;
                ERR     <= ~(INP_VALID == `V_BOTH);
              end
              
            `OR:
              begin
                RES[WIDTH-1:0]      <= (INP_VALID == `V_BOTH) ? (OPA | OPB)  : 0;
                OFLOW   <= 1'b0;  COUT <= 1'b0;  
                {G,L,E} <= `NONE;
                ERR     <= ~(INP_VALID == `V_BOTH);
              end
              
            `NOR:
              begin
               RES[WIDTH-1:0]    <= (INP_VALID == `V_BOTH) ? ~(OPA | OPB) : 0;
                OFLOW   <= 1'b0;  COUT <= 1'b0;  
                {G,L,E} <= `NONE;
                ERR     <= ~(INP_VALID == `V_BOTH);
              end
              
            `XOR:
              begin
               RES[WIDTH-1:0]    <= (INP_VALID == `V_BOTH) ? (OPA ^ OPB)  : 0;
                OFLOW   <= 1'b0;  COUT <= 1'b0;  
                {G,L,E} <= `NONE;
                ERR     <= ~(INP_VALID == `V_BOTH);
              end
             
            `XNOR:
              begin
               RES[WIDTH-1:0]    <= (INP_VALID == `V_BOTH) ? ~(OPA ^ OPB) : 0;
                OFLOW   <= 1'b0;  COUT <= 1'b0;  
                {G,L,E} <= `NONE;
                ERR     <= ~(INP_VALID == `V_BOTH);
              end
              
            `NOT_A:
              begin
                RES[WIDTH-1:0]      <= (INP_VALID == `V_BOTH || INP_VALID == `V_A) ? ~OPA : 0;
                OFLOW   <= 1'b0;  COUT <= 1'b0;  
                {G,L,E} <= `NONE;
                ERR     <= ~(INP_VALID == `V_BOTH || INP_VALID == `V_A);
              end
              
            `NOT_B:
              begin
              RES[WIDTH-1:0]  <= (INP_VALID == `V_BOTH || INP_VALID == `V_B) ? ~OPB : 0;
                OFLOW   <= 1'b0;  COUT <= 1'b0;  {G,L,E} <= `NONE;
                ERR     <= ~(INP_VALID == `V_BOTH || INP_VALID == `V_B);
              end
              
            `SHR1_A:
              begin
               RES[WIDTH-1:0]     <= (INP_VALID == `V_BOTH || INP_VALID == `V_A) ? (OPA >> 1) : 0;
                OFLOW   <= 1'b0;  COUT <= 1'b0;  {G,L,E} <= `NONE;
                ERR     <= ~(INP_VALID == `V_BOTH || INP_VALID == `V_A);
              end
              
            `SHL1_A:
              begin
                RES[WIDTH-1:0]      <= (INP_VALID == `V_BOTH || INP_VALID == `V_A) ? (OPA << 1) : 0;
                OFLOW   <= 1'b0;  COUT <= 1'b0;  
                {G,L,E} <= `NONE;
                ERR     <= ~(INP_VALID == `V_BOTH || INP_VALID == `V_A);
              end
                
            `SHR1_B:
              begin
                RES[WIDTH-1:0]    <= (INP_VALID == `V_BOTH || INP_VALID == `V_B) ? (OPB >> 1) : 0;
                OFLOW   <= 1'b0;  COUT <= 1'b0;  
                {G,L,E} <= `NONE;
                ERR     <= ~(INP_VALID == `V_BOTH || INP_VALID == `V_B);
              end
              
            `SHL1_B:
              begin
                RES[WIDTH-1:0]      <= (INP_VALID == `V_BOTH || INP_VALID == `V_B) ? (OPB << 1) : 0;
                OFLOW   <= 1'b0;  COUT <= 1'b0;  
                {G,L,E} <= `NONE;
                ERR     <= ~(INP_VALID == `V_BOTH || INP_VALID == `V_B);
              end
             
            `ROL_A_B:
              begin
                case(OPB[2:0])
                  `NONE : RES <= (INP_VALID == `V_BOTH) ? OPA                                       : 0;
                  3'b001 : RES <= (INP_VALID == `V_BOTH) ? {OPA[WIDTH-2:0], OPA[WIDTH-1]}          : 0; 
                 3'b010 : RES <= (INP_VALID == `V_BOTH) ? {OPA[WIDTH-3:0], OPA[WIDTH-1:WIDTH-2]} : 0;
                  3'b011 : RES <= (INP_VALID == `V_BOTH) ? {OPA[WIDTH-4:0], OPA[WIDTH-1:WIDTH-3]} : 0;
                  3'b100 : RES <= (INP_VALID == `V_BOTH) ? {OPA[WIDTH-5:0], OPA[WIDTH-1:WIDTH-4]} : 0;
                  3'b101 : RES <= (INP_VALID == `V_BOTH) ? {OPA[WIDTH-6:0], OPA[WIDTH-1:WIDTH-5]} : 0;
                  3'b110 : RES <= (INP_VALID == `V_BOTH) ? {OPA[WIDTH-7:0], OPA[WIDTH-1:WIDTH-6]} : 0;
                 3'b111 : RES <= (INP_VALID == `V_BOTH) ? {OPA[WIDTH-8],   OPA[WIDTH-1:WIDTH-7]} : 0;
                endcase
                OFLOW <= 1'b0;  COUT <= 1'b0;  
                {G,L,E} <= `NONE;
                ERR   <= !(OPB[7:4] == 0);
              end
              
            `ROR_A_B:
              begin
                case(OPB[2:0])
                  `NONE : RES <= (INP_VALID == `V_BOTH) ? OPA                                          : 0;
                  3'b001 : RES <= (INP_VALID == `V_BOTH) ? {OPA[WIDTH-8],   OPA[WIDTH-1:1]}           : 0; 
                  3'b010 : RES <= (INP_VALID == `V_BOTH) ? {OPA[WIDTH-7:WIDTH-8], OPA[WIDTH-1:2]}    : 0;
                   3'b011 : RES <= (INP_VALID == `V_BOTH) ? {OPA[WIDTH-6:WIDTH-8], OPA[WIDTH-1:3]}    : 0;
                  3'b100 : RES <= (INP_VALID == `V_BOTH) ? {OPA[WIDTH-5:WIDTH-8], OPA[WIDTH-1:4]}    : 0;
                   3'b101 : RES <= (INP_VALID == `V_BOTH) ? {OPA[WIDTH-4:WIDTH-8], OPA[WIDTH-1:5]}    : 0;
                   3'b110 : RES <= (INP_VALID == `V_BOTH) ? {OPA[WIDTH-3:WIDTH-8], OPA[WIDTH-1:6]}    : 0;
                  3'b111 : RES <= (INP_VALID == `V_BOTH) ? {OPA[WIDTH-2:WIDTH-8], OPA[WIDTH-1:7]}    : 0;
                endcase
                OFLOW <= 1'b0; 
                COUT <= 1'b0; 
                {G,L,E} <= `NONE;
                ERR   <= !(OPB[7:4] == 0);
              end
             
            default: begin
              RES     <= 0;
              COUT    <= 1'b0;
              OFLOW   <= 1'b0;
              {G,L,E} <= `NONE;
            end
              
          endcase
        end
      end
        
      else begin
        RES     <= RES;
        OFLOW   <= OFLOW;
        COUT    <= COUT;
        {G,L,E} <= {G,L,E};
        ERR     <= ERR;
      end
        
    end
  end
    
endmodule

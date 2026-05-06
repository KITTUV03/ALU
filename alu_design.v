/***************************************************************
* 
*   K     K   IIIIIII  TTTTTTT  TTTTTTT  U     U
*   K   K       I         T        T     U     U
*   K K         I         T        T     U     U
*   KK          I         T        T     U     U
*   K K         I         T        T     U     U
*   K   K       I         T        T     U     U
*   K     K   IIIIIII     T        T      UUUUU
*
***************************************************************/

/***************************************************************
*  Author        : Kittu Patel
*  Company       : Mirafra Software Technologies Pvt. Ltd.
*  Project Name  : Parameterized ALU Design
*
*  Description   :
*  This project implements a parameterized Arithmetic Logic Unit
*  (ALU) supporting both arithmetic and logical operations.
*  Features include:
*    - Arithmetic ops: ADD, SUB, ADD with CIN, SUB with CIN
*    - Increment/Decrement operations
*    - Comparison (G, L, E flags)
*    - Signed operations with overflow detection
*    - Logical ops: AND, OR, XOR, NOT, shifts, rotate
*    - Pipelined multiplication operations:
*         • MUL_INC  : (OPA+1)*(OPB+1)
*         • MUL_SHL  : (OPA<<1)*OPB
*    - Valid signal based input control
*    - Clock enable (CE) based operation
*
*  Start Date    : [04-05-2026]
*  End Date      : [05-05-2026]
*
*  Notes         :
*  - Supports parameterized data width
*  - Suitable for ASIC/FPGA design and UVM verification
***************************************************************/




`define VALID_M    2
`define OPERATION  4
`define NONE       3'b000
`define V_NONE     2'b00
`define V_A        2'b01
`define V_B        2'b10
`define V_BOTH     2'b11

`define ADD        4'h0
`define SUB        4'h1
`define ADD_CIN    4'h2
`define SUB_CIN    4'h3
`define INC_A      4'h4
`define DEC_A      4'h5
`define INC_B      4'h6
`define DEC_B      4'h7
`define CMP        4'h8
`define MUL_INC    4'h9
`define MUL_SHL    4'hA
`define SADD       4'hB
`define SSUB       4'hC

`define AND        4'h0
`define NAND       4'h1
`define OR         4'h2
`define NOR        4'h3
`define XOR        4'h4
`define XNOR       4'h5
`define NOT_A      4'h6
`define NOT_B      4'h7
`define SHR1_A     4'h8
`define SHL1_A     4'h9
`define SHR1_B     4'hA
`define SHL1_B     4'hB
`define ROL_A_B    4'hC
`define ROR_A_B    4'hD


module ALU_DESIGN #(parameter WIDTH = 8)
(
    input                    CLK,
    input                    RST,
    input  [`VALID_M-1:0]    INP_VALID,
    input                    MODE,
    input  [`OPERATION-1:0]  CMD,
    input                    CE,
    input  [WIDTH-1:0]       OPA,
    input  [WIDTH-1:0]       OPB,
    input                    CIN,

    output reg               ERR,
    output reg [2*WIDTH-1:0] RES,
    output reg               OFLOW,
    output reg               COUT,
    output reg               G,
    output reg               L,
    output reg               E
);
  
    

    reg signed [2*WIDTH-1:0] signed_result;

    reg [2*WIDTH-1:0] mulinc_s1, mulshl_s1;
    reg               mulinc_v1, mulshl_v1;
  
  `define wid $clog2(WIDTH)

  always @(posedge CLK or posedge RST) begin
    if (RST) begin
        RES <= 0; ERR <= 0;
        OFLOW <= 0; COUT <= 0;
        G <= 0; L <= 0; E <= 0;

        mulinc_s1 <= 0; mulinc_v1 <= 0;
        mulshl_s1 <= 0; mulshl_v1 <= 0;
    end

    else if (CE) begin

        ERR   <= 0;
        OFLOW <= 0;
        COUT  <= 0;
        {G,L,E} <= `NONE;

     
      if (mulinc_v1 && CMD == `MUL_INC) begin
            RES <= mulinc_s1;
            mulinc_v1 <= 0;   // clear AFTER use
        end 
      else if (mulshl_v1 && CMD == `MUL_SHL) begin
            RES <= mulshl_s1;
            mulshl_v1 <= 0;   // clear AFTER use
        end 

      
        else begin

          if (MODE) begin
              case (CMD)
                  
                    `ADD: begin
                        {COUT,RES[WIDTH-1:0]} <= (INP_VALID==`V_BOTH) ? (OPA+OPB) : {COUT,RES[WIDTH-1:0]};
                        RES     <= (INP_VALID==`V_BOTH) ? (OPA+OPB) : RES;
                        OFLOW   <= 0;  {G,L,E} <= `NONE;
                        ERR     <= ~(INP_VALID==`V_BOTH);
                    end

                    `SUB: begin
                        RES     <= (INP_VALID==`V_BOTH) ? (OPA-OPB) : RES;
                        COUT    <= 0;  
                        OFLOW   <= (OPB > OPA);
                        {G,L,E} <= `NONE;
                        ERR     <= ~(INP_VALID==`V_BOTH);
                    end

                    `ADD_CIN: begin
                        {COUT,RES[WIDTH-1:0]} <= (INP_VALID==`V_BOTH) ? (OPA+OPB+CIN) : {COUT,RES[WIDTH-1:0]};
                        RES     <= (INP_VALID==`V_BOTH) ? (OPA+OPB+CIN) : RES;
                        OFLOW   <= 0;  {G,L,E} <= `NONE;
                        ERR     <= ~(INP_VALID==`V_BOTH);
                    end

                    `SUB_CIN: begin
                        RES     <= (INP_VALID==`V_BOTH) ? (OPA-OPB-CIN) : RES;
                      COUT    <= 0;  
                      OFLOW <= ({1'b0,OPA} < ({1'b0,OPB} + CIN));  
                                              
                      {G,L,E} <= `NONE;
                        ERR     <= ~(INP_VALID==`V_BOTH);
                    end

                    `INC_A: begin
                        RES  <= (INP_VALID==`V_BOTH||INP_VALID==`V_A) ? OPA+1 : RES;
                        COUT <= 0;  OFLOW <= 0;  {G,L,E} <= `NONE;
                        ERR  <= ~(INP_VALID==`V_BOTH||INP_VALID==`V_A);
                    end

                    `DEC_A: begin
                        RES  <= (INP_VALID==`V_BOTH||INP_VALID==`V_A) ? OPA-1 : RES;
                        COUT <= 0;  OFLOW <= 0;  {G,L,E} <= `NONE;
                        ERR  <= ~(INP_VALID==`V_BOTH||INP_VALID==`V_A);
                    end

                    `INC_B: begin
                        RES  <= (INP_VALID==`V_BOTH||INP_VALID==`V_B) ? OPB+1 : RES;
                        COUT <= 0;  OFLOW <= 0;  {G,L,E} <= `NONE;
                        ERR  <= ~(INP_VALID==`V_BOTH||INP_VALID==`V_B);
                    end

                    `DEC_B: begin
                        RES  <= (INP_VALID==`V_BOTH||INP_VALID==`V_B) ? OPB-1 : RES;
                        COUT <= 0;  OFLOW <= 0;  {G,L,E} <= `NONE;
                        ERR  <= ~(INP_VALID==`V_BOTH||INP_VALID==`V_B);
                    end

                    `CMP: begin
                        RES     <= 0;
                        COUT    <= 0;  OFLOW <= 0;
                        {G,L,E} <= {(OPA>OPB),(OPA<OPB),(OPA==OPB)};
                        ERR     <= ~(INP_VALID==`V_BOTH);
                    end

                    `MUL_INC: begin
                      if(CMD == `MUL_INC)
                        begin
                      if (INP_VALID==`V_BOTH) begin
                            mulinc_s1 <= (OPA+1)*(OPB+1);
                            mulinc_v1 <= 1;
                        end else ERR <= 1;
                    end
                  else
                    begin
                      RES <= 0;
                    end
                    end

                    `MUL_SHL: begin
                        if (INP_VALID==`V_BOTH) begin
                            mulshl_s1 <= (OPA<<1)*OPB;
                            mulshl_v1 <= 1;
                        end else ERR <= 1;
                    end
                  
                  
                    `SADD: begin
                        if (INP_VALID == `V_BOTH) begin
                            signed_result = $signed({1'b0,OPA}) + $signed({1'b0,OPB});
                            COUT  <= signed_result[WIDTH];
                            RES   <= {{WIDTH{signed_result[WIDTH-1]}},signed_result[WIDTH-1:0]};
                            OFLOW <= (OPA[WIDTH-1]==OPB[WIDTH-1]) &&
                                     (signed_result[WIDTH-1]!=OPA[WIDTH-1]);
                            G <= ($signed(OPA) >  $signed(OPB));
                            L <= ($signed(OPA) <  $signed(OPB));
                            E <= ($signed(OPA) == $signed(OPB));
                        end else begin
                            RES<=0; COUT<=0; OFLOW<=0; {G,L,E}<=`NONE;
                        end
                        ERR <= ~(INP_VALID==`V_BOTH);
                    end

                    `SSUB: begin
                        if (INP_VALID == `V_BOTH) begin
                            signed_result = $signed({1'b0,OPA}) - $signed({1'b0,OPB});
                            COUT  <= signed_result[WIDTH];
                            RES   <= {{WIDTH{signed_result[WIDTH-1]}},signed_result[WIDTH-1:0]};
                            OFLOW <= (OPA[WIDTH-1]!=OPB[WIDTH-1]) &&
                                     (signed_result[WIDTH-1]!=OPA[WIDTH-1]);
                            G <= ($signed(OPA) >  $signed(OPB));
                            L <= ($signed(OPA) <  $signed(OPB));
                            E <= ($signed(OPA) == $signed(OPB));
                        end else begin
                            RES<=0; COUT<=0; OFLOW<=0; {G,L,E}<=`NONE;
                        end
                        ERR <= ~(INP_VALID==`V_BOTH);
                    end

                    default:
                      begin
                        RES<=0; COUT<=0; OFLOW<=0; {G,L,E}<=`NONE;
                    end


                endcase
            end

            else begin
              case (CMD)
                     `AND:    begin RES[WIDTH-1:0]<=(INP_VALID==`V_BOTH)?(OPA&OPB)  :0;OFLOW<=0;COUT<=0;{G,L,E}<=`NONE;ERR<=~(INP_VALID==`V_BOTH);end
                    `NAND:   begin RES[WIDTH-1:0]<=(INP_VALID==`V_BOTH)?~(OPA&OPB) :0;OFLOW<=0;COUT<=0;{G,L,E}<=`NONE;ERR<=~(INP_VALID==`V_BOTH);end
                    `OR:     begin RES[WIDTH-1:0]<=(INP_VALID==`V_BOTH)?(OPA|OPB)  :0;OFLOW<=0;COUT<=0;{G,L,E}<=`NONE;ERR<=~(INP_VALID==`V_BOTH);end
                    `NOR:    begin RES[WIDTH-1:0]<=(INP_VALID==`V_BOTH)?~(OPA|OPB) :0;OFLOW<=0;COUT<=0;{G,L,E}<=`NONE;ERR<=~(INP_VALID==`V_BOTH);end
                    `XOR:    begin RES[WIDTH-1:0]<=(INP_VALID==`V_BOTH)?(OPA^OPB)  :0;OFLOW<=0;COUT<=0;{G,L,E}<=`NONE;ERR<=~(INP_VALID==`V_BOTH);end
                    `XNOR:   begin RES[WIDTH-1:0]<=(INP_VALID==`V_BOTH)?~(OPA^OPB) :0;OFLOW<=0;COUT<=0;{G,L,E}<=`NONE;ERR<=~(INP_VALID==`V_BOTH);end
                    `NOT_A:  begin RES[WIDTH-1:0]<=(INP_VALID==`V_BOTH||INP_VALID==`V_A)?~OPA  :0;OFLOW<=0;COUT<=0;{G,L,E}<=`NONE;ERR<=~(INP_VALID==`V_BOTH||INP_VALID==`V_A);end
                    `NOT_B:  begin RES[WIDTH-1:0]<=(INP_VALID==`V_BOTH||INP_VALID==`V_B)?~OPB  :0;OFLOW<=0;COUT<=0;{G,L,E}<=`NONE;ERR<=~(INP_VALID==`V_BOTH||INP_VALID==`V_B);end
                    `SHR1_A: begin RES[WIDTH-1:0]<=(INP_VALID==`V_BOTH||INP_VALID==`V_A)?OPA>>1:0;OFLOW<=0;COUT<=0;{G,L,E}<=`NONE;ERR<=~(INP_VALID==`V_BOTH||INP_VALID==`V_A);end
                    `SHL1_A: begin RES[WIDTH-1:0]<=(INP_VALID==`V_BOTH||INP_VALID==`V_A)?OPA<<1:0;OFLOW<=0;COUT<=0;{G,L,E}<=`NONE;ERR<=~(INP_VALID==`V_BOTH||INP_VALID==`V_A);end
                    `SHR1_B: begin RES[WIDTH-1:0]<=(INP_VALID==`V_BOTH||INP_VALID==`V_B)?OPB>>1:0;OFLOW<=0;COUT<=0;{G,L,E}<=`NONE;ERR<=~(INP_VALID==`V_BOTH||INP_VALID==`V_B);end
                    `SHL1_B: begin RES[WIDTH-1:0]<=(INP_VALID==`V_BOTH||INP_VALID==`V_B)?OPB<<1:0;OFLOW<=0;COUT<=0;{G,L,E}<=`NONE;ERR<=~(INP_VALID==`V_BOTH||INP_VALID==`V_B);end

                `ROL_A_B: begin
                        if (INP_VALID == `V_BOTH) begin
                            if (|OPB[WIDTH-1:`wid]) begin
                                ERR <= 1;  
                            end else begin
                                RES[WIDTH-1:0] <= (OPA << OPB[`wid-1:0]) | (OPA >> (WIDTH - OPB[`wid-1:0]));
                                RES[2*WIDTH-1:WIDTH] <= 0;
                                ERR <= 0;
                            end
                        end else begin
                            RES <= 0;
                            ERR <= 1;
                        end
                        OFLOW <= 0;
                        COUT  <= 0;
                        {G,L,E} <= `NONE;
                    end
                  
                  

                `ROR_A_B: begin
                    if (INP_VALID == `V_BOTH) begin
                        if (|OPB[WIDTH-1:`wid]) begin
                            ERR <= 1;
                        end else begin
                            RES[WIDTH-1:0] <= (OPA >> OPB[`wid-1:0]) | (OPA << (WIDTH - OPB[`wid-1:0]));
                            RES[2*WIDTH-1:WIDTH] <= 0;
                            ERR <= 0;
                        end
                    end else begin
                        RES <= 0;
                        ERR <= 1;
                    end
                    OFLOW <= 0;
                    COUT  <= 0;
                    {G,L,E} <= `NONE;
                end
                  
                  
                                    default: begin
                        RES<=0; COUT<=0; OFLOW<=0; {G,L,E}<=`NONE;
                    end
                endcase
            end

        end
    end
end
endmodule

    



 //100 % Code Coverage Achieved

// /***************************************************************
// * 
// *   K     K   IIIIIII  TTTTTTT  TTTTTTT  U     U
// *   K   K       I         T        T     U     U
// *   K K         I         T        T     U     U
// *   KK          I         T        T     U     U
// *   K K         I         T        T     U     U
// *   K   K       I         T        T     U     U
// *   K     K   IIIIIII     T        T      UUUUU
// *
// ***************************************************************/

// /***************************************************************
// *  Author        : Kittu Patel
// *  Company       : Mirafra Software Technologies Pvt. Ltd.
// *  Project Name  : Parameterized ALU Design
// *
// *  Description   :
// *  This project implements a parameterized Arithmetic Logic Unit
// *  (ALU) supporting both arithmetic and logical operations.
// *  Features include:
// *    - Arithmetic ops: ADD, SUB, ADD with CIN, SUB with CIN
// *    - Increment/Decrement operations
// *    - Comparison (G, L, E flags)
// *    - Signed operations with overflow detection
// *    - Logical ops: AND, OR, XOR, NOT, shifts, rotate
// *    - Pipelined multiplication operations:
// *         \u2022 MUL_INC  : (OPA+1)*(OPB+1)
// *         \u2022 MUL_SHL  : (OPA<<1)*OPB
// *    - Valid signal based input control
// *    - Clock enable (CE) based operation
// *
// *  Start Date    : [04-05-2026]
// *  End Date      : [05-05-2026]
// *
// *  Notes         :
// *  - Supports parameterized data width
// *  - Suitable for ASIC/FPGA design and UVM verification
// ***************************************************************/
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

   
    reg  [`VALID_M-1:0]   r_INP_VALID;
    reg                   r_MODE;
    reg  [`OPERATION-1:0] r_CMD;
    reg  [WIDTH-1:0]      r_OPA;
    reg  [WIDTH-1:0]      r_OPB;
    reg                   r_CIN;

   

    localparam WID = $clog2(WIDTH);

    reg signed [WIDTH:0] signed_result;

    reg [2*WIDTH-1:0] temp_sum;

    reg [WIDTH:0] rot_amt;

    
  reg [2*WIDTH-1:0] mul_pipe_res_1;
  reg [2*WIDTH-1:0] mul_pipe_res_2;

    reg               mul_pipe_valid;
    reg               mul_pipe_valid_1;


    
always @(posedge CLK or posedge RST)
begin

  
    if(RST)
    begin

        r_INP_VALID <= 0;
        r_MODE      <= 0;
        r_CMD       <= 0;
        r_OPA       <= 0;
        r_OPB       <= 0;
        r_CIN       <= 0;

        RES         <= 0;
        ERR         <= 0;
        OFLOW       <= 0;
        COUT        <= 0;

        G <= 0;
        L <= 0;
        E <= 0;

        mul_pipe_res_1 <= 0;
        mul_pipe_res_2 <= 0;

        mul_pipe_valid   <= 0;
        mul_pipe_valid_1 <= 0;

    end

   

    else if(CE)
    begin


        r_INP_VALID <= INP_VALID;
        r_MODE      <= MODE;
        r_CMD       <= CMD;
        r_OPA       <= OPA;
        r_OPB       <= OPB;
        r_CIN       <= CIN;

      

        ERR     <= 0;
        OFLOW   <= 0;
        COUT    <= 0;

        {G,L,E} <= `NONE;

        
      if(mul_pipe_valid && r_CMD == `MUL_INC)
        begin

            RES <= mul_pipe_res_1;

            mul_pipe_valid <= 0;

        end

       

      else if(mul_pipe_valid_1 && r_CMD == `MUL_SHL)
        begin

            RES <= mul_pipe_res_2;

            mul_pipe_valid_1 <= 0;

        end


            else
            begin

               

                if(r_MODE)
                begin

                    case(r_CMD)

                       
                        `ADD:
                        begin

                            if(r_INP_VALID == `V_BOTH)
                            begin

                                temp_sum = r_OPA + r_OPB;

                                COUT <= temp_sum[WIDTH];

                                RES <= temp_sum;
                                

                            end

                            else
                                ERR <= 1;

                        end

                        `SUB:
                        begin

                            if(r_INP_VALID == `V_BOTH)
                            begin

                              RES <= ({8'h00,r_OPA} - {8'h00,r_OPB});
                               OFLOW <= (r_OPB > r_OPA);

                            end

                            else begin
                                ERR <= 1;
                                OFLOW <= 0;
                            end


                        end

                      
                        `ADD_CIN:
                        begin

                            if(r_INP_VALID == `V_BOTH)
                            begin

                                temp_sum = r_OPA + r_OPB + r_CIN;

                                COUT <= temp_sum[WIDTH];

                                RES <= temp_sum;
                              
                                OFLOW <= 0;
                               
                            end

                            else begin
                                ERR <= 1;
                                OFLOW <= 0;
                            end

                        end

                        `SUB_CIN:
                        begin

                            if(r_INP_VALID == `V_BOTH)
                            begin

                                RES <=
                                {{WIDTH{1'b0}},r_OPA} -
                                {{WIDTH{1'b0}},r_OPB} -
                                r_CIN;

                                OFLOW <=
                                ({1'b0,r_OPA} <
                                ({1'b0,r_OPB}+r_CIN));

                            end

                            else begin
                                ERR <= 1;
                          OFLOW <=
                                ({1'b0,r_OPA} <
                                ({1'b0,r_OPB}+r_CIN));
                            end
                        end

                        
                        `INC_A:
                        begin

                            if(r_INP_VALID == `V_BOTH ||
                               r_INP_VALID == `V_A)

                                RES <= r_OPA + 1'b1;

                            else
                                ERR <= 1;

                        end

                        `DEC_A:
                        begin

                            if(r_INP_VALID == `V_BOTH ||
                               r_INP_VALID == `V_A)

                                RES <= r_OPA - 1'b1;

                            else
                                ERR <= 1;

                        end

                        `INC_B:
                        begin

                            if(r_INP_VALID == `V_BOTH ||
                               r_INP_VALID == `V_B)

                                RES <= r_OPB + 1'b1;

                            else
                                ERR <= 1;

                        end

                       

                        `DEC_B:
                        begin

                            if(r_INP_VALID == `V_BOTH ||
                               r_INP_VALID == `V_B)

                                RES <= r_OPB - 1'b1;

                            else
                                ERR <= 1;

                        end


                        `CMP:
                        begin

                            if(r_INP_VALID == `V_BOTH)
                            begin

                                RES <= 0;

                                G <= (r_OPA > r_OPB);
                                L <= (r_OPA < r_OPB);
                                E <= (r_OPA == r_OPB);

                            end

                            else
                                ERR <= 1;
                                 RES <= 0;
 

                        end

                        

                        `MUL_INC:
                        begin

                            if(r_INP_VALID == `V_BOTH)
                            begin

                                mul_pipe_res_1 <=
                                (r_OPA + 1) * (r_OPB + 1);

                                mul_pipe_valid <= 1;

                                RES <= {2*WIDTH{1'bx}};

                            end

                            else
                                ERR <= 1;
                                RES <= {2*WIDTH{1'bx}};

                        end

                        

                        `MUL_SHL:
                        begin

                            if(r_INP_VALID == `V_BOTH)
                            begin

                                mul_pipe_res_2 <=
                                (r_OPA << 1) * r_OPB;

                                mul_pipe_valid_1 <= 1;

                                RES <= {2*WIDTH{1'bx}};

                            end

                            else
                                ERR <= 1;
                           RES <= {2*WIDTH{1'bx}};

                        end

                        

                        `SADD:
                        begin

                            if(r_INP_VALID == `V_BOTH)
                            begin

                                signed_result =
                                $signed({1'b0,r_OPA}) +
                                $signed({1'b0,r_OPB});

                                RES <=
                                {{WIDTH{signed_result[WIDTH-1]}},
                                  signed_result[WIDTH-1:0]};

                                OFLOW <=
                                (r_OPA[WIDTH-1] ==
                                 r_OPB[WIDTH-1]) &&

                                (signed_result[WIDTH-1] !=
                                 r_OPA[WIDTH-1]);

                                COUT <= 0;

                                G <=
                                ($signed(r_OPA) >
                                 $signed(r_OPB));

                                L <=
                                ($signed(r_OPA) <
                                 $signed(r_OPB));

                                E <=
                                ($signed(r_OPA) ==
                                 $signed(r_OPB));

                            end

                            else begin
                                ERR <= 1;
                                RES <= {2*WIDTH{1'bx}};
                            end
                               

                        end

                        

                        `SSUB:
                        begin

                            if(r_INP_VALID == `V_BOTH)
                            begin

                                signed_result =
                                $signed({1'b0,r_OPA}) -
                                $signed({1'b0,r_OPB});

                               RES   <= {{WIDTH{signed_result[WIDTH-1]}},signed_result[WIDTH-1:0]};

                                OFLOW <=
                                (r_OPA[WIDTH-1] !=
                                 r_OPB[WIDTH-1]) &&

                                (signed_result[WIDTH-1] !=
                                 r_OPA[WIDTH-1]);

                                COUT <= 0;

                                G <=
                                ($signed(r_OPA) >
                                 $signed(r_OPB));

                                L <=
                                ($signed(r_OPA) <
                                 $signed(r_OPB));

                                E <=
                                ($signed(r_OPA) ==
                                 $signed(r_OPB));

                            end

                            else begin
                                ERR <= 1;
                                 RES <= {2*WIDTH{1'bx}};
                             end
                        end

                        default:
                        begin

                            RES <= 0;
                            ERR <= 1;

                        end

                    endcase

                end

                // =================================================
                // LOGIC MODE
                // =================================================

                else
                begin

                    case(r_CMD)

                        `AND:
                        begin

                          if(r_INP_VALID == `V_BOTH) begin
                              RES[WIDTH-1:0] <= (r_OPA & r_OPB);
                          end

                            else begin
                                ERR <= 1;
                                RES <= 0;
                            end

                        end

                        `NAND:
                        begin

                            if(r_INP_VALID == `V_BOTH)
                                RES[WIDTH-1:0] <= ~(r_OPA & r_OPB);

                            else begin
                                ERR <= 1;
                                RES <= 0;
                            end


                        end

                        `OR:
                        begin

                            if(r_INP_VALID == `V_BOTH)
                                RES[WIDTH-1:0] <= r_OPA | r_OPB;

                            else begin
                                ERR <= 1;
                                RES <= 0;
                            end

                        end

                        `NOR:
                        begin

                            if(r_INP_VALID == `V_BOTH)
                                RES[WIDTH-1:0] <= ~(r_OPA | r_OPB);

                            else begin
                                ERR <= 1;
                                RES <= 0;
                            end

                        end

                        `XOR:
                        begin

                            if(r_INP_VALID == `V_BOTH)
                                RES[WIDTH-1:0] <= r_OPA ^ r_OPB;

                            else begin
                                ERR <= 1;
                               RES <= 0;
                            end
                        end

                        `XNOR:
                        begin

                            if(r_INP_VALID == `V_BOTH)
                                RES[WIDTH-1:0] <= ~(r_OPA ^ r_OPB);

                            else begin
                                ERR <= 1;
                                 RES <= 0;
                            end


                        end

                        `NOT_A:
                        begin

                            if(r_INP_VALID == `V_BOTH ||
                               r_INP_VALID == `V_A)

                                RES[WIDTH-1:0] <= ~r_OPA;

                            else begin
                                ERR <= 1;
                                RES <= 0;
                            end

                        end

                        `NOT_B:
                        begin

                            if(r_INP_VALID == `V_BOTH ||
                               r_INP_VALID == `V_B)

                                RES[WIDTH-1:0] <= ~r_OPB;

                            else begin
                                ERR <= 1;
                                RES <= 0;
                            end


                        end

                        `SHR1_A:
                        begin

                            if(r_INP_VALID == `V_BOTH ||
                               r_INP_VALID == `V_A)

                                RES[WIDTH-1:0] <= r_OPA >> 1;

                            else begin
                                ERR <= 1;
                                RES <= 0;
                            end


                        end

                        `SHL1_A:
                        begin

                            if(r_INP_VALID == `V_BOTH ||
                               r_INP_VALID == `V_A)

                                RES[WIDTH-1:0] <= r_OPA << 1;

                            else begin
                                ERR <= 1;
                                RES <= 0;
                            end


                        end

                        `SHR1_B:
                        begin

                            if(r_INP_VALID == `V_BOTH ||
                               r_INP_VALID == `V_B)

                                RES[WIDTH-1:0] <= r_OPB >> 1;

                            else begin
                                ERR <= 1;
                                RES <= 0;
                            end


                        end

                        `SHL1_B:
                        begin

                            if(r_INP_VALID == `V_BOTH ||
                               r_INP_VALID == `V_B)

                                RES[WIDTH-1:0] <= r_OPB << 1;

                            else begin
                                ERR <= 1;
                                RES <= 0;
                            end


                        end

                        // --------------------------------------------
                        // ROL
                        // --------------------------------------------

                      
                          `ROL_A_B: begin
                            rot_amt = r_OPB[WID-1:0];

                            if (|r_OPB[WIDTH-1:WID+1]) begin
                                ERR <= 1;
                                RES <= 0;
                            end

                            else
                                ERR <= 0;

                            RES[WIDTH-1:0] <=
                                (r_OPA << rot_amt) |
                                (r_OPA >> (WIDTH - rot_amt));

                            RES[2*WIDTH-1:WIDTH] <= 0;

                            OFLOW <= 0;
                            COUT  <= 0;
                                {G,L,E} <= `NONE;
                        end


                           `ROR_A_B: begin

                                rot_amt = r_OPB[WID-1:0];

                             if (|r_OPB[WIDTH-1:WID+1]) begin
                                    ERR <= 1;
                                    RES <= 0;
                             end

                                else

                                RES[WIDTH-1:0] <=
                                    (r_OPA >> rot_amt) |
                                    (r_OPA << (WIDTH - rot_amt));

                                RES[2*WIDTH-1:WIDTH] <= 0;

                                OFLOW <= 0;
                                COUT  <= 0;
                                {G,L,E} <= `NONE;
                            end



                        default:
                        begin

                            RES <= {2*WIDTH{1'bx}};
                            ERR <= 1;

                        end

                    endcase
                  

                end
              

            end

        end
     

    end
  

endmodule

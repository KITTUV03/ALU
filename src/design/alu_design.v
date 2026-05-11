

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
    reg        [WIDTH:0]     rot_amt;

    reg signed [2*WIDTH-1:0] signed_result;
    reg [2*WIDTH-1:0] mulinc_s1, mulshl_s1;
    reg               mulinc_v1, mulshl_v1;

    always @(posedge CLK or posedge RST) begin
        if (RST) begin
            r_INP_VALID <= 0;
            r_MODE      <= 0;
            r_CMD       <= 0;
            r_OPA       <= 0;
            r_OPB       <= 0;
            r_CIN       <= 0;

            RES   <= 0; ERR   <= 0;
            OFLOW <= 0; COUT  <= 0;
            G <= 0; L <= 0; E <= 0;

            mulinc_s1 <= 0; mulinc_v1 <= 0;
            mulshl_s1 <= 0; mulshl_v1 <= 0;
        end

        else if (CE) begin

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

            if (mulinc_v1 && r_CMD == `MUL_INC) begin
                RES       <= mulinc_s1;
                mulinc_v1 <= 0;
            end
            else if (mulshl_v1 && r_CMD == `MUL_SHL) begin
                RES       <= mulshl_s1;
                mulshl_v1 <= 0;
            end

            else begin

                if (r_MODE) begin
                    case (r_CMD)
                        `ADD: begin
                            {COUT, RES[WIDTH-1:0]} <= (r_INP_VALID==`V_BOTH) ? (r_OPA + r_OPB) : {COUT, RES[WIDTH-1:0]};
                            RES   <= (r_INP_VALID==`V_BOTH) ? (r_OPA + r_OPB) : RES;
                            ERR   <= ~(r_INP_VALID==`V_BOTH);
                        end

                        `SUB: begin
                            RES   <= (r_INP_VALID==`V_BOTH) ? (r_OPA - r_OPB) : RES;
                            OFLOW <= (r_OPB > r_OPA);
                            ERR   <= ~(r_INP_VALID==`V_BOTH);
                        end

                        `ADD_CIN: begin
                            {COUT, RES[WIDTH-1:0]} <= (r_INP_VALID==`V_BOTH) ? (r_OPA + r_OPB + r_CIN) : {COUT, RES[WIDTH-1:0]};
                            RES   <= (r_INP_VALID==`V_BOTH) ? (r_OPA + r_OPB + r_CIN) : RES;
                            ERR   <= ~(r_INP_VALID==`V_BOTH);
                        end

                        `SUB_CIN: begin
                            RES   <= (r_INP_VALID==`V_BOTH) ? (r_OPA - r_OPB - r_CIN) : RES;
                            OFLOW <= ({1'b0,r_OPA} < ({1'b0,r_OPB} + r_CIN));
                            ERR   <= ~(r_INP_VALID==`V_BOTH);
                        end

                        `INC_A: begin
                            RES <= (r_INP_VALID==`V_BOTH || r_INP_VALID==`V_A) ? r_OPA+1 : RES;
                            ERR <= ~(r_INP_VALID==`V_BOTH || r_INP_VALID==`V_A);
                        end

                        `DEC_A: begin
                            RES <= (r_INP_VALID==`V_BOTH || r_INP_VALID==`V_A) ? r_OPA-1 : RES;
                            ERR <= ~(r_INP_VALID==`V_BOTH || r_INP_VALID==`V_A);
                        end

                        `INC_B: begin
                            RES <= (r_INP_VALID==`V_BOTH || r_INP_VALID==`V_B) ? r_OPB+1 : RES;
                            ERR <= ~(r_INP_VALID==`V_BOTH || r_INP_VALID==`V_B);
                        end

                        `DEC_B: begin
                            RES <= (r_INP_VALID==`V_BOTH || r_INP_VALID==`V_B) ? r_OPB-1 : RES;
                            ERR <= ~(r_INP_VALID==`V_BOTH || r_INP_VALID==`V_B);
                        end

                        `CMP: begin
                            RES     <= 0;
                            {G,L,E} <= {(r_OPA>r_OPB),(r_OPA<r_OPB),(r_OPA==r_OPB)};
                            ERR     <= ~(r_INP_VALID==`V_BOTH);
                        end

                        `MUL_INC: begin
                            if (r_INP_VALID==`V_BOTH) begin
                            ERR <= 0;

                                mulinc_s1 <= (r_OPA+1)*(r_OPB+1);
                                mulinc_v1 <= 1;
                              RES   <= {(2*WIDTH){1'b0}};
                            end else ERR <= 1;
                        end

                        `MUL_SHL: begin
                            if (r_INP_VALID==`V_BOTH) begin
                                ERR <= 0;
                                mulshl_s1 <= (r_OPA<<1)*r_OPB;
                                mulshl_v1 <= 1;
                              RES   <= {(2*WIDTH){1'b0}};

                            end else ERR <= 1;
                        end

                        `SADD: begin
                            if (r_INP_VALID == `V_BOTH) begin
                                signed_result = $signed({1'b0,r_OPA}) + $signed({1'b0,r_OPB});
                                RES   <= {{WIDTH{signed_result[WIDTH-1]}},signed_result[WIDTH-1:0]};
                                OFLOW <= (r_OPA[WIDTH-1]==r_OPB[WIDTH-1]) &&
                                         (signed_result[WIDTH-1]!=r_OPA[WIDTH-1]);
                                G <= ($signed(r_OPA) >  $signed(r_OPB));
                                L <= ($signed(r_OPA) <  $signed(r_OPB));
                                E <= ($signed(r_OPA) == $signed(r_OPB));
                            end else begin
                                RES<=0; COUT<=0; OFLOW<=0; {G,L,E}<=`NONE;
                            end
                            ERR <= ~(r_INP_VALID==`V_BOTH);
                        end

                        `SSUB: begin
                            if (r_INP_VALID == `V_BOTH) begin
                                signed_result = $signed({1'b0,r_OPA}) - $signed({1'b0,r_OPB});
                                RES   <= {{WIDTH{signed_result[WIDTH-1]}},signed_result[WIDTH-1:0]};
                                OFLOW <= (r_OPA[WIDTH-1]!=r_OPB[WIDTH-1]) &&
                                         (signed_result[WIDTH-1]!=r_OPA[WIDTH-1]);
                                G <= ($signed(r_OPA) >  $signed(r_OPB));
                                L <= ($signed(r_OPA) <  $signed(r_OPB));
                                E <= ($signed(r_OPA) == $signed(r_OPB));
                            end else begin
                                RES<=0; COUT<=0; OFLOW<=0; {G,L,E}<=`NONE;
                            end
                            ERR <= ~(r_INP_VALID==`V_BOTH);
                        end

                        default: begin
                            RES<=0; COUT<=0; OFLOW<=0; {G,L,E}<=`NONE;
                            ERR <=1;

                        end 

                    endcase
                end

                else begin
                    case (r_CMD)
                        `AND:    begin RES[WIDTH-1:0]<=(r_INP_VALID==`V_BOTH)?(r_OPA&r_OPB)  :0; RES[2*WIDTH-1:WIDTH]<=0; OFLOW<=0;COUT<=0;{G,L,E}<=`NONE;ERR<=~(r_INP_VALID==`V_BOTH);end
                        `NAND:   begin RES[WIDTH-1:0]<=(r_INP_VALID==`V_BOTH)?~(r_OPA&r_OPB) :0; RES[2*WIDTH-1:WIDTH]<=0; OFLOW<=0;COUT<=0;{G,L,E}<=`NONE;ERR<=~(r_INP_VALID==`V_BOTH);end
                        `OR:     begin RES[WIDTH-1:0]<=(r_INP_VALID==`V_BOTH)?(r_OPA|r_OPB)  :0; RES[2*WIDTH-1:WIDTH]<=0; OFLOW<=0;COUT<=0;{G,L,E}<=`NONE;ERR<=~(r_INP_VALID==`V_BOTH);end
                        `NOR:    begin RES[WIDTH-1:0]<=(r_INP_VALID==`V_BOTH)?~(r_OPA|r_OPB) :0; RES[2*WIDTH-1:WIDTH]<=0; OFLOW<=0;COUT<=0;{G,L,E}<=`NONE;ERR<=~(r_INP_VALID==`V_BOTH);end
                        `XOR:    begin RES[WIDTH-1:0]<=(r_INP_VALID==`V_BOTH)?(r_OPA^r_OPB)  :0; RES[2*WIDTH-1:WIDTH]<=0; OFLOW<=0;COUT<=0;{G,L,E}<=`NONE;ERR<=~(r_INP_VALID==`V_BOTH);end
                        `XNOR:   begin RES[WIDTH-1:0]<=(r_INP_VALID==`V_BOTH)?~(r_OPA^r_OPB) :0; RES[2*WIDTH-1:WIDTH]<=0; OFLOW<=0;COUT<=0;{G,L,E}<=`NONE;ERR<=~(r_INP_VALID==`V_BOTH);end
                        `NOT_A:  begin RES[WIDTH-1:0]<=(r_INP_VALID==`V_BOTH||r_INP_VALID==`V_A)?~r_OPA  :0; RES[2*WIDTH-1:WIDTH]<=0; OFLOW<=0;COUT<=0;{G,L,E}<=`NONE;ERR<=~(r_INP_VALID==`V_BOTH||r_INP_VALID==`V_A);end
                        `NOT_B:  begin RES[WIDTH-1:0]<=(r_INP_VALID==`V_BOTH||r_INP_VALID==`V_B)?~r_OPB  :0; RES[2*WIDTH-1:WIDTH]<=0; OFLOW<=0;COUT<=0;{G,L,E}<=`NONE;ERR<=~(r_INP_VALID==`V_BOTH||r_INP_VALID==`V_B);end
                        `SHR1_A: begin RES[WIDTH-1:0]<=(r_INP_VALID==`V_BOTH||r_INP_VALID==`V_A)?r_OPA>>1:0; RES[2*WIDTH-1:WIDTH]<=0; OFLOW<=0;COUT<=0;{G,L,E}<=`NONE;ERR<=~(r_INP_VALID==`V_BOTH||r_INP_VALID==`V_A);end
                        `SHL1_A: begin RES[WIDTH-1:0]<=(r_INP_VALID==`V_BOTH||r_INP_VALID==`V_A)?r_OPA<<1:0; RES[2*WIDTH-1:WIDTH]<=0; OFLOW<=0;COUT<=0;{G,L,E}<=`NONE;ERR<=~(r_INP_VALID==`V_BOTH||r_INP_VALID==`V_A);end
                        `SHR1_B: begin RES[WIDTH-1:0]<=(r_INP_VALID==`V_BOTH||r_INP_VALID==`V_B)?r_OPB>>1:0; RES[2*WIDTH-1:WIDTH]<=0; OFLOW<=0;COUT<=0;{G,L,E}<=`NONE;ERR<=~(r_INP_VALID==`V_BOTH||r_INP_VALID==`V_B);end
                        `SHL1_B: begin RES[WIDTH-1:0]<=(r_INP_VALID==`V_BOTH||r_INP_VALID==`V_B)?r_OPB<<1:0; RES[2*WIDTH-1:WIDTH]<=0; OFLOW<=0;COUT<=0;{G,L,E}<=`NONE;ERR<=~(r_INP_VALID==`V_BOTH||r_INP_VALID==`V_B);end

                       
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



                        default: begin
                            RES<=0; COUT<=0; OFLOW<=0; {G,L,E}<=`NONE;
                            ERR <=1;
                        end
                    endcase
                end 
            end
        end
    end
endmodule
   

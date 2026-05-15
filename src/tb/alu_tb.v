

/*****************************************************************************************
*
*    KK    KK   IIIIIII   TTTTTTTTTTT   TTTTTTTTTTT   UUU     UUU
*    KK   KK       III          TTT           TTT      UUU     UUU
*    KK KK         III          TTT           TTT      UUU     UUU
*    KKKK          III          TTT           TTT      UUU     UUU
*    KK KK         III          TTT           TTT      UUU     UUU
*    KK   KK       III          TTT           TTT      UUU     UUU
*    KK    KK   IIIIIII         TTT           TTT       UUUUUUUUU
*
*----------------------------------------------------------------------------------------
*                               ALU VERIFICATION TESTBENCH
*----------------------------------------------------------------------------------------
*
*  Project Name : PARAMETERIZED ALU VERIFICATION
*  File Name    : alu_tb.v
*  Type         : Verilog Testbench
*
*  Description  :
*  This testbench verifies arithmetic and logical functionality of the ALU.
*  It includes:
*
*      -> Arithmetic operation testing
*      -> Logical operation testing
*      -> Signed arithmetic validation
*      -> Overflow verification
*      -> Rotation operation checking
*      -> Invalid and unknown input testing
*      -> Clock enable verification
*      -> Multiplication pipeline validation
*      -> Functional and code coverage support
*
*----------------------------------------------------------------------------------------
*  Developed By : Kittu Patel
*----------------------------------------------------------------------------------------
*
*****************************************************************************************/
// `include "alu_design.v"
`define WIDTH            8
`define VALID_M          2
`define OPERATION        4
`define CLOCK_DELAY      @(posedge CLK)
`define ARITH_MAX_CMD    12
`define LOGIC_MAX_CMD    13
`define WID              3


`define RAND_RANGE(max,min) (($unsigned($random) % ((max)-(min)+1)) + (min))
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

module tb;

    parameter WIDTH = 8;

    reg                    CLK;
    reg                    RST;
    reg  [`VALID_M-1:0]    INP_VALID;
    reg                    MODE;
    reg  [`OPERATION-1:0]  CMD;
    reg                    CE;
    reg  [`WIDTH-1:0]      OPA;
    reg  [`WIDTH-1:0]      OPB;
    reg  [`WIDTH-1:0]      temp;
    reg                    CIN;

    wire                   ERR;
    wire [2*`WIDTH-1:0]    RES;
    wire                   OFLOW;
    wire                   COUT;
    wire                   G, L, E;

    reg  [2*`WIDTH-1:0]    EXP_RES;
    reg                    EXP_ERR;
    reg                    EXP_OFLOW;
    reg                    EXP_COUT;
    reg                    EXP_G, EXP_L, EXP_E;

    reg  [`VALID_M-1:0]    r_INP_VALID;
    reg                    r_MODE;
    reg  [`OPERATION-1:0]  r_CMD;
    reg  [`WIDTH-1:0]      r_OPA;
    reg  [`WIDTH-1:0]      r_OPB;
    reg                    r_CIN;
    reg                    r_CE;

  reg  [2*`WIDTH-1:0]    mul_s1_res_1;
  reg  [2*`WIDTH-1:0]    mul_s1_res_2;

    reg                    mul_s1_valid;
    reg                    mul_s1_valid_1;

    reg  [`OPERATION-1:0]  mul_s1_cmd;

    reg signed [2*`WIDTH-1:0] ref_signed;
    reg        [`WIDTH:0]     rot_amt;

    integer pass_cnt, fail_cnt;
    integer cmd_i;


    ALU_DESIGN  dut (
        .CLK      (CLK),
        .RST      (RST),
        .INP_VALID(INP_VALID),
        .MODE     (MODE),
        .CMD      (CMD),
        .CE       (CE),
        .OPA      (OPA),
        .OPB      (OPB),
        .CIN      (CIN),
        .ERR      (ERR),
        .RES      (RES),
        .OFLOW    (OFLOW),
        .COUT     (COUT),
        .G        (G),
        .L        (L),
        .E        (E)
    );

    initial
    begin
        CLK = 1'b0;
        forever
        begin
            #5 CLK = ~CLK;
        end
    end



    task reset;
    begin
        RST = 1'b1;
        repeat(2)
        begin
            `CLOCK_DELAY;
        end
        RST = 1'b0;
    end
    endtask

  
  

    task valid_arithmetic_inputs;
    begin
        MODE      = 1'b1;
        CE        = 1'b1;
        RST       = 1'b0;
        INP_VALID = `V_BOTH;

        // Low range
        repeat(30)
        begin
            OPA = `RAND_RANGE(35,  0);
            OPB = `RAND_RANGE(35,  0);
            CMD = `RAND_RANGE(`ARITH_MAX_CMD, 0);
            CIN = $random;
            `CLOCK_DELAY;
        end

        // Mid range
        repeat(30)
        begin
            OPA = `RAND_RANGE(100, 36);
            OPB = `RAND_RANGE(100, 36);
            CMD = `RAND_RANGE(`ARITH_MAX_CMD, 0);
            CIN = $random;
            `CLOCK_DELAY;
        end

        // High range
        repeat(30)
        begin
            OPA = `RAND_RANGE(253, 101);
            OPB = `RAND_RANGE(253, 101);
            CMD = `RAND_RANGE(`ARITH_MAX_CMD, 0);
            CIN = $random;
            `CLOCK_DELAY;
        end

        // Walk every command at boundary values
        for(cmd_i = 0; cmd_i <= `ARITH_MAX_CMD; cmd_i = cmd_i + 1)
        begin
            OPA = `RAND_RANGE(255, 254);
            OPB = `RAND_RANGE(255, 254);
            CMD = cmd_i;
            CIN = $random;
            `CLOCK_DELAY;
        end

        // Walk every command at zero
        for(cmd_i = 0; cmd_i <= `ARITH_MAX_CMD; cmd_i = cmd_i + 1)
        begin
            OPA = 0;
            OPB = 0;
            CMD = cmd_i;
            CIN = $random;
            `CLOCK_DELAY;
        end

        // OPA == OPB corner
        repeat(10)
        begin
            OPA = `RAND_RANGE(255, 0);
            OPB = OPA;
            CMD = `RAND_RANGE(`ARITH_MAX_CMD, 0);
            CIN = $random;
            `CLOCK_DELAY;
        end

        // SUB / SSUB underflow corner (OPA < OPB)
        repeat(10)
        begin
            OPB = `RAND_RANGE(255, 1);
            OPA = `RAND_RANGE(OPB-1, 0);
            CMD = `SUB;
            CIN = $random;
            `CLOCK_DELAY;
            CMD = `SSUB;
            `CLOCK_DELAY;
        end

        //Overflow
        repeat(10)
        begin
        OPA = `RAND_RANGE(0,255);
        OPB = OPA;
        CMD = `SADD;
	CIN = $random;
        `CLOCK_DELAY;
        end

        // ADD_CIN / SUB_CIN with CIN=1
        repeat(10)
        begin
            OPA = `RAND_RANGE(255, 0);
            OPB = `RAND_RANGE(255, 0);
            CIN = 1'b1;
            CMD = `ADD_CIN;
            `CLOCK_DELAY;
            CMD = `SUB_CIN;
            `CLOCK_DELAY;
        end
    end
    endtask


    task valid_logic_inputs;
    begin
        MODE      = 1'b0;
        CE        = 1'b1;
        RST       = 1'b0;
        INP_VALID = `V_BOTH;

        // Low range
        repeat(30)
        begin
            OPA = `RAND_RANGE(15,  0);
            OPB = `RAND_RANGE(15,  0);
            CMD = `RAND_RANGE(`LOGIC_MAX_CMD, 0);
            CIN = $random;
            `CLOCK_DELAY;
        end

        // Mid range
        repeat(30)
        begin
            OPA = `RAND_RANGE(100, 36);
            OPB = `RAND_RANGE(100, 36);
            CMD = `RAND_RANGE(`LOGIC_MAX_CMD, 0);
            CIN = $random;
            `CLOCK_DELAY;
        end

        // High range
        repeat(30)
        begin
            OPA = `RAND_RANGE(253, 101);
            OPB = `RAND_RANGE(253, 101);
            CMD = `RAND_RANGE(`LOGIC_MAX_CMD, 0);
            CIN = $random;
            `CLOCK_DELAY;
        end

        // Walk every command at boundary values
        for(cmd_i = 0; cmd_i <= `LOGIC_MAX_CMD; cmd_i = cmd_i + 1)
        begin
            OPA = `RAND_RANGE(255, 254);
            OPB = `RAND_RANGE(255, 254);
            CMD = cmd_i;
            CIN = $random;
            `CLOCK_DELAY;
        end

        // Walk every command at zero
        for(cmd_i = 0; cmd_i <= `LOGIC_MAX_CMD; cmd_i = cmd_i + 1)
        begin
            OPA = 0;
            OPB = 0;
            CMD = cmd_i;
            CIN = $random;
            `CLOCK_DELAY;
        end

        // OPA == OPB corner
        repeat(10)
        begin
            OPA = `RAND_RANGE(255, 0);
            OPB = OPA;
            CMD = `RAND_RANGE(`LOGIC_MAX_CMD, 0);
            CIN = $random;
            `CLOCK_DELAY;
        end

        // Rotate boundary: large OPB values (should trigger ERR)
        repeat(10)
        begin
            OPA = `RAND_RANGE(255, 100);
            OPB = `RAND_RANGE(255,   0);
            CMD = `RAND_RANGE(13,   12);   // ROL_A_B / ROR_A_B
            CIN = $random;
            `CLOCK_DELAY;
        end
    end
    endtask


    task unknown_input;
    begin
        CE        = 1'b1;
        RST       = 1'b0;
        INP_VALID = `V_BOTH;
        OPA[7:4]  = 4'bxxxx;
        OPB[7:4]  = 4'bxxxx;

        repeat(30)
        begin
            MODE     = $random;
            OPA[3:0] = $random;
            OPB[3:0] = $random;
            CMD      = `RAND_RANGE(`LOGIC_MAX_CMD, 0);
            CIN      = $random;
            `CLOCK_DELAY;
        end
    end
    endtask


    task invalid_input;
    begin
        CE  = 1'b1;
        RST = 1'b0;
        
      repeat (5) begin
         for(cmd_i = 0; cmd_i <= `ARITH_MAX_CMD; cmd_i = cmd_i + 1)
        begin
            OPA = `RAND_RANGE(0,255);
            MODE = 1;
            OPB = `RAND_RANGE(0,255);
            CMD = cmd_i;
            CIN = $random;
            INP_VALID = $random;
            `CLOCK_DELAY;
        end
      end

	 repeat (4) begin
         for(cmd_i = 0; cmd_i <= `LOGIC_MAX_CMD; cmd_i = cmd_i + 1)
        begin
            OPA = `RAND_RANGE(0,255);
            MODE = 0;
            OPB = `RAND_RANGE(0,255);
            CMD = cmd_i;
            CIN = $random;
            INP_VALID = $random;
            `CLOCK_DELAY;
        end
      end

     CMD = 9;
     INP_VALID = 2'b00;
     `CLOCK_DELAY;
     CMD = 10;
     INP_VALID = 2'b00;
     `CLOCK_DELAY;

    end
    endtask


    task clock_enable;
    begin
        RST = 1'b0;

        repeat(20)
        begin
            CE        = $random;
            MODE      = $random;
            OPA       = $random;
            OPB       = $random;
            CMD       = `RAND_RANGE(`LOGIC_MAX_CMD, 0);
            CIN       = $random;
            INP_VALID = $random;
            `CLOCK_DELAY;
        end
    end
    endtask

    task multiplication;

    begin
        repeat(80)
        begin
            RST       = 1'b0;
            INP_VALID = `V_BOTH;
            MODE      = 1'b1;
            CE        = 1'b1;
            OPA       = $random;
            OPB       = $random;

            CMD       = `RAND_RANGE(10, 9);   // Generates only 9 or 10

            CIN       = $random;

            repeat(2)
            begin
                `CLOCK_DELAY;
            end
        end
    end
    endtask

 task direct_cases;
    begin
      repeat(20)
        begin
            RST       = 1'b0;
            INP_VALID = `V_BOTH;
            MODE      = 1'b1;
            CE        = 1'b1;
            OPA       = $random;
            OPB       = $random;
            CMD       = `RAND_RANGE(7,10);   // MUL_INC or MUL_SHL
            CIN       = $random;
            repeat(1)
            begin
                `CLOCK_DELAY;
            end
        end

       repeat (15) begin
        MODE = 1;
        INP_VALID = `V_BOTH;
        CE = 1'b1;
        OPA = $random;
        OPB = $random;
        CMD = 8;
        `CLOCK_DELAY;
       end

      repeat(3) begin
      MODE = 1;
        INP_VALID = `V_NONE;
        CE = 1'b1;
        OPA = $random;
        OPB = $random;
        CMD = 11;
        `CLOCK_DELAY;
end
    end
    endtask



    always @(posedge CLK or posedge RST) begin
        if (RST) begin
            r_INP_VALID  <= 0;
            r_MODE       <= 0;
            r_CMD        <= 0;
            r_OPA        <= 0;
            r_OPB        <= 0;
            r_CIN        <= 0;
            r_CE         <= 0;
        end else begin
            r_INP_VALID  <= INP_VALID;
            r_MODE       <= MODE;
            r_CMD        <= CMD;
            r_OPA        <= OPA;
            r_OPB        <= OPB;
            r_CIN        <= CIN;
            r_CE         <= CE;
        end
    end

    always @(posedge CLK or posedge RST) begin
        if (RST) begin
            EXP_RES      <= 0;
            EXP_ERR      <= 0;
            EXP_OFLOW    <= 0;
            EXP_COUT     <= 0;
            EXP_G        <= 0;
            EXP_L        <= 0;
            EXP_E        <= 0;
            mul_s1_res_1   <= 0;
            mul_s1_res_2   <= 0;
            mul_s1_valid <= 0;
            mul_s1_valid_1 <= 0;
            mul_s1_cmd   <= 0;
        end else if (r_CE) begin
            EXP_RES    <= 0;
            EXP_ERR    <= 0;
            EXP_OFLOW  <= 0;
            EXP_COUT   <= 0;

            {EXP_G,EXP_L,EXP_E} <= `NONE;

            
          if(mul_s1_valid && r_CMD == `MUL_INC)
        begin

            EXP_RES <= mul_s1_res_1;

            mul_s1_valid <= 0;

        end

        // ====================================================
        // PIPELINE RESULT : MUL_SHL
        // ====================================================

          else if(mul_s1_valid_1 && r_CMD == `MUL_SHL)
        begin

            EXP_RES <= mul_s1_res_2;

            mul_s1_valid_1 <= 0;

        end
          
            
      else begin
        EXP_ERR <= 0;
                 if (r_MODE) begin
                    case (r_CMD)
                    
                        `ADD: begin
                            {EXP_COUT, EXP_RES[`WIDTH-1:0]} <=
                                (r_INP_VALID==`V_BOTH) ? (r_OPA + r_OPB)
                                                       : {EXP_COUT, EXP_RES[`WIDTH-1:0]};

                          EXP_RES <= (r_INP_VALID==`V_BOTH) ? (r_OPA + r_OPB)
                                                       : EXP_RES;
//                             EXP_RES[2*`WIDTH-1:`WIDTH] <= 0;
                            EXP_OFLOW <= 0;
                            {EXP_G, EXP_L, EXP_E} <= `NONE;
                          EXP_ERR <= !(r_INP_VALID ==`V_BOTH);
                          
                          if(!(r_INP_VALID == `V_BOTH ))
                             begin
                               EXP_COUT <= 0;
                               EXP_RES  <= EXP_RES;
                             end
                          
                        end

                        `SUB: begin
                            EXP_RES   <= (r_INP_VALID==`V_BOTH) ? ({8'h00,r_OPA} - {8'h00,r_OPB}) : EXP_RES;
                            EXP_OFLOW <= (r_OPB > r_OPA);
                            EXP_COUT  <= 0;
                            {EXP_G, EXP_L, EXP_E} <= `NONE;
                            EXP_ERR <= ~(r_INP_VALID==`V_BOTH);
                          
                           if(!(r_INP_VALID == `V_BOTH ))
                             begin
                               EXP_OFLOW <= 0;
                             end
                        end

                        `ADD_CIN: begin
                            {EXP_COUT, EXP_RES[`WIDTH-1:0]} <=
                                (r_INP_VALID==`V_BOTH) ? (r_OPA + r_OPB + r_CIN)
                                                       : {EXP_COUT, EXP_RES[`WIDTH-1:0]};

                          EXP_RES <= (r_INP_VALID==`V_BOTH) ? (r_OPA + r_OPB + r_CIN)
                                                       : EXP_RES;

                          EXP_OFLOW <= 0;
                            {EXP_G, EXP_L, EXP_E} <= `NONE;
                            EXP_ERR <= ~(r_INP_VALID==`V_BOTH);
                        end

                        `SUB_CIN: begin
                            EXP_RES   <= (r_INP_VALID==`V_BOTH) ? (r_OPA - r_OPB - r_CIN) : EXP_RES;
                            EXP_OFLOW <= ({1'b0,r_OPA} < ({1'b0,r_OPB} + r_CIN));
                            EXP_COUT  <= 0;
                            {EXP_G, EXP_L, EXP_E} <= `NONE;
                            EXP_ERR <= ~(r_INP_VALID==`V_BOTH);
                        end

                                         `INC_A: begin
                                           EXP_RES <= (r_INP_VALID==`V_BOTH || r_INP_VALID==`V_A)
                                               ? (r_OPA + 1'b1)
                                               : EXP_RES;

                        EXP_ERR   <= ~(r_INP_VALID==`V_BOTH || r_INP_VALID==`V_A);
                        EXP_COUT  <= 0;
                        EXP_OFLOW <= 0;
                        {EXP_G, EXP_L, EXP_E} <= `NONE;
                    end

                         
                        `DEC_A: begin
                          EXP_RES <= (r_INP_VALID==`V_BOTH || r_INP_VALID==`V_A) ? (r_OPA-1'b1) : EXP_RES;
                            EXP_ERR   <= ~(r_INP_VALID==`V_BOTH || r_INP_VALID==`V_A);
                            EXP_COUT  <= 0;
                            EXP_OFLOW <= 0;
                            {EXP_G, EXP_L, EXP_E} <= `NONE;
                        end

                        `INC_B: begin
                          EXP_RES  <= (r_INP_VALID==`V_BOTH || r_INP_VALID==`V_B) ? (r_OPB+1) : EXP_RES;
                            EXP_ERR   <= ~(r_INP_VALID==`V_BOTH || r_INP_VALID==`V_B);
                            EXP_COUT  <= 0;
                            EXP_OFLOW <= 0;
                            {EXP_G, EXP_L, EXP_E} <= `NONE;
                        end

                        `DEC_B: begin
                          EXP_RES  <= (r_INP_VALID==`V_BOTH || r_INP_VALID==`V_B) ? (r_OPB-1'b1) : EXP_RES;
                            EXP_ERR   <= ~(r_INP_VALID==`V_BOTH || r_INP_VALID==`V_B);
                            EXP_COUT  <= 0;
                            EXP_OFLOW <= 0;
                            {EXP_G, EXP_L, EXP_E} <= `NONE;
                        end

                        `CMP: begin
                            EXP_RES   <= 0;
                            EXP_COUT  <= 0;
                            EXP_OFLOW <= 0;
                           {EXP_G, EXP_L, EXP_E} <= {(r_OPA>r_OPB),(r_OPA<r_OPB),(r_OPA==r_OPB)};
                          if(~(r_INP_VALID==`V_BOTH)) begin
                            {EXP_G, EXP_L, EXP_E} <= `NONE;
                            EXP_ERR   <= 1;
                          end
                          
                        end

                        `MUL_INC: begin
                            if (r_INP_VALID==`V_BOTH) begin
                                mul_s1_res_1   <= (r_OPA+1)*(r_OPB+1);
                                mul_s1_valid <= 1;
                                mul_s1_cmd   <= `MUL_INC;
                              {EXP_G,EXP_L,EXP_E} <= `NONE;
                              EXP_RES <= {2*`WIDTH{1'bx}};  
                              EXP_COUT  <= 0;
                              EXP_OFLOW <= 0;//chnage

 
                            end else begin
                                EXP_ERR <= 1;
                              EXP_RES <= {2*`WIDTH{1'bx}};
                              EXP_COUT  <= 0;
                              EXP_OFLOW <= 0;//chnage


                            end
                        end

                        `MUL_SHL: begin

                            if (r_INP_VALID==`V_BOTH) begin
                                mul_s1_res_2   <= (r_OPA<<1)*r_OPB;
                                mul_s1_valid_1 <= 1;
                                mul_s1_cmd   <= `MUL_SHL;
                                {EXP_G,EXP_L,EXP_E} <= `NONE;
                              EXP_RES <= {2*`WIDTH{1'bx}}; //chnage
                              EXP_COUT  <= 0;
                              EXP_OFLOW <= 0;//chnage

                                end else begin
                                EXP_ERR <= 1;
                                  EXP_RES <= {2*`WIDTH{1'bx}};
                                  EXP_COUT  <= 0;
                              EXP_OFLOW <= 0;//chnage


                            end
                        end

                        `SADD: begin
                            if (r_INP_VALID==`V_BOTH) begin
                                ref_signed = $signed({1'b0,r_OPA}) + $signed({1'b0,r_OPB});
                                EXP_COUT  <= 0;
                                EXP_RES   <= {{`WIDTH{ref_signed[`WIDTH-1]}}, ref_signed[`WIDTH-1:0]};
                                EXP_OFLOW <= (r_OPA[`WIDTH-1]==r_OPB[`WIDTH-1]) &&
                                             (ref_signed[`WIDTH-1]!=r_OPA[`WIDTH-1]);
                                EXP_G     <= ($signed(r_OPA) >  $signed(r_OPB));
                                EXP_L     <= ($signed(r_OPA) <  $signed(r_OPB));
                                EXP_E     <= ($signed(r_OPA) == $signed(r_OPB));
                            end else begin
                                EXP_RES   <= {2*`WIDTH{1'bx}};;
                                EXP_COUT  <= 0;
                                EXP_OFLOW <= 0;
                                {EXP_G, EXP_L, EXP_E} <= `NONE;
                            end
                            EXP_ERR <= ~(r_INP_VALID==`V_BOTH);
                        end

                        `SSUB: begin
                            if (r_INP_VALID==`V_BOTH) begin
                                ref_signed = $signed({1'b0,r_OPA}) - $signed({1'b0,r_OPB});
                                EXP_COUT  <= 0;
                                EXP_RES   <= {{`WIDTH{ref_signed[`WIDTH-1]}}, ref_signed[`WIDTH-1:0]};
                                EXP_OFLOW <= (r_OPA[`WIDTH-1]!=r_OPB[`WIDTH-1]) &&
                                             (ref_signed[`WIDTH-1]!=r_OPA[`WIDTH-1]);
                                EXP_G     <= ($signed(r_OPA) >  $signed(r_OPB));
                                EXP_L     <= ($signed(r_OPA) <  $signed(r_OPB));
                                EXP_E     <= ($signed(r_OPA) == $signed(r_OPB));
                            end else begin
                                EXP_RES   <= {2*`WIDTH{1'bx}};;
                                EXP_COUT  <= 0;
                                EXP_OFLOW <= 0;
                                {EXP_G, EXP_L, EXP_E} <= `NONE;
                            end
                            EXP_ERR <= ~(r_INP_VALID==`V_BOTH);
                        end

                        default: begin
                            EXP_RES   <= 0;
                            EXP_COUT  <= 0;
                            EXP_ERR   <= 1;

                            EXP_OFLOW <= 0;
                            {EXP_G, EXP_L, EXP_E} <= `NONE;
                        end

                    endcase

                end else begin

                    case (r_CMD)
                      `AND:
                        begin

                          if(r_INP_VALID == `V_BOTH) begin
                              EXP_RES[WIDTH-1:0] <= (r_OPA & r_OPB);
                          end

                            else begin
                                EXP_ERR <= 1;
                                EXP_RES <= 0;
                            end

                        end
                      
                      
                        `NAND: begin
                            EXP_RES[`WIDTH-1:0]        <= (r_INP_VALID==`V_BOTH) ? ~(r_OPA & r_OPB) : 0;
                            EXP_RES[2*`WIDTH-1:`WIDTH] <= 0;
                            EXP_OFLOW <= 0; EXP_COUT <= 0; {EXP_G,EXP_L,EXP_E} <= `NONE;
                            EXP_ERR   <= ~(r_INP_VALID==`V_BOTH);
                        end

                        `OR: begin
                            EXP_RES[`WIDTH-1:0]        <= (r_INP_VALID==`V_BOTH) ? (r_OPA | r_OPB) : 0;
                            EXP_RES[2*`WIDTH-1:`WIDTH] <= 0;
                            EXP_OFLOW <= 0; EXP_COUT <= 0; {EXP_G,EXP_L,EXP_E} <= `NONE;
                            EXP_ERR   <= ~(r_INP_VALID==`V_BOTH);
                        end

                        `NOR: begin
                            EXP_RES[`WIDTH-1:0]        <= (r_INP_VALID==`V_BOTH) ? ~(r_OPA | r_OPB) : 0;
                            EXP_RES[2*`WIDTH-1:`WIDTH] <= 0;
                            EXP_OFLOW <= 0; EXP_COUT <= 0; {EXP_G,EXP_L,EXP_E} <= `NONE;
                            EXP_ERR   <= ~(r_INP_VALID==`V_BOTH);
                        end

                        `XOR: begin
                            EXP_RES[`WIDTH-1:0]        <= (r_INP_VALID==`V_BOTH) ? (r_OPA ^ r_OPB) : 0;
                            EXP_RES[2*`WIDTH-1:`WIDTH] <= 0;
                            EXP_OFLOW <= 0; EXP_COUT <= 0; {EXP_G,EXP_L,EXP_E} <= `NONE;
                            EXP_ERR   <= ~(r_INP_VALID==`V_BOTH);
                        end

                        `XNOR: begin
                            EXP_RES[`WIDTH-1:0]        <= (r_INP_VALID==`V_BOTH) ? ~(r_OPA ^ r_OPB) : 0;
                            EXP_RES[2*`WIDTH-1:`WIDTH] <= 0;
                            EXP_OFLOW <= 0; EXP_COUT <= 0; {EXP_G,EXP_L,EXP_E} <= `NONE;
                            EXP_ERR   <= ~(r_INP_VALID==`V_BOTH);
                        end

                        `NOT_A: begin
                            EXP_RES[`WIDTH-1:0]        <= (r_INP_VALID==`V_BOTH||r_INP_VALID==`V_A) ? ~r_OPA : 0;
                            EXP_RES[2*`WIDTH-1:`WIDTH] <= 0;
                            EXP_OFLOW <= 0; EXP_COUT <= 0; {EXP_G,EXP_L,EXP_E} <= `NONE;
                            EXP_ERR   <= ~(r_INP_VALID==`V_BOTH||r_INP_VALID==`V_A);
                        end

                        `NOT_B: begin
                            EXP_RES[`WIDTH-1:0]        <= (r_INP_VALID==`V_BOTH||r_INP_VALID==`V_B) ? ~r_OPB : 0;
                            EXP_RES[2*`WIDTH-1:`WIDTH] <= 0;
                            EXP_OFLOW <= 0; EXP_COUT <= 0; {EXP_G,EXP_L,EXP_E} <= `NONE;
                            EXP_ERR   <= ~(r_INP_VALID==`V_BOTH||r_INP_VALID==`V_B);
                        end

                        `SHR1_A: begin
                            EXP_RES[`WIDTH-1:0]        <= (r_INP_VALID==`V_BOTH||r_INP_VALID==`V_A) ? r_OPA>>1 : 0;
                            EXP_RES[2*`WIDTH-1:`WIDTH] <= 0;
                            EXP_OFLOW <= 0; EXP_COUT <= 0; {EXP_G,EXP_L,EXP_E} <= `NONE;
                            EXP_ERR   <= ~(r_INP_VALID==`V_BOTH||r_INP_VALID==`V_A);
                        end

                        `SHL1_A: begin
                            EXP_RES[`WIDTH-1:0]        <= (r_INP_VALID==`V_BOTH||r_INP_VALID==`V_A) ? r_OPA<<1 : 0;
                            EXP_RES[2*`WIDTH-1:`WIDTH] <= 0;
                            EXP_OFLOW <= 0; EXP_COUT <= 0; {EXP_G,EXP_L,EXP_E} <= `NONE;
                            EXP_ERR   <= ~(r_INP_VALID==`V_BOTH||r_INP_VALID==`V_A);
                        end

                        `SHR1_B: begin
                            EXP_RES[`WIDTH-1:0]        <= (r_INP_VALID==`V_BOTH||r_INP_VALID==`V_B) ? r_OPB>>1 : 0;
                            EXP_RES[2*`WIDTH-1:`WIDTH] <= 0;
                            EXP_OFLOW <= 0; EXP_COUT <= 0; {EXP_G,EXP_L,EXP_E} <= `NONE;
                            EXP_ERR   <= ~(r_INP_VALID==`V_BOTH||r_INP_VALID==`V_B);
                        end

                        `SHL1_B: begin
                            EXP_RES[`WIDTH-1:0]        <= (r_INP_VALID==`V_BOTH||r_INP_VALID==`V_B) ? r_OPB<<1 : 0;
                            EXP_RES[2*`WIDTH-1:`WIDTH] <= 0;
                            EXP_OFLOW <= 0; EXP_COUT <= 0; {EXP_G,EXP_L,EXP_E} <= `NONE;
                            EXP_ERR   <= ~(r_INP_VALID==`V_BOTH||r_INP_VALID==`V_B);
                        end


                          `ROL_A_B: begin
                            rot_amt = r_OPB[`WID-1:0];

                            if (|r_OPB[`WIDTH-1:`WID+1]) begin
                                EXP_ERR <= 1;
                                EXP_RES <= 0;
                            end

                            else
                                EXP_ERR <= 0;

                            EXP_RES[`WIDTH-1:0] <=
                                (r_OPA << rot_amt) |
                                (r_OPA >> (`WIDTH - rot_amt));

                            EXP_RES[2*`WIDTH-1:`WIDTH] <= 0;

                            EXP_OFLOW <= 0;
                            EXP_COUT  <= 0;
                                {EXP_G,EXP_L,EXP_E} <= `NONE;
                        end


                          `ROR_A_B:
                      begin

                          rot_amt = r_OPB[`WID-1:0];

                          if(|r_OPB[`WIDTH-1:`WID+1])
                          begin

                              EXP_ERR <= 1;
                              EXP_RES <= 0;

                          end

                          else
                          begin

                              EXP_ERR <= 0;

                              EXP_RES[`WIDTH-1:0] <=
                                  (r_OPA >> rot_amt) |
                                  (r_OPA << (`WIDTH - rot_amt));

                              EXP_RES[2*`WIDTH-1:`WIDTH] <= 0;

                          end

                          EXP_OFLOW <= 0;
                          EXP_COUT  <= 0;

                          {EXP_G,EXP_L,EXP_E} <= `NONE;

                      end

                        default: begin
                            EXP_RES   <=  {2*WIDTH{1'bx}};;
                            EXP_COUT  <= 0;
                            EXP_OFLOW <= 0;
                            EXP_ERR   <= 1;
                            {EXP_G, EXP_L, EXP_E} <= `NONE;
                        end

                    endcase
                end
            end
        end
//      
    end

   always @(negedge CLK)
     begin
       if (!RST && r_CE)
     begin
     //  #1;

       if (RES !== EXP_RES)
    $display("%-6s  @%0t | MODE=%b CMD=%02h OPA=%3d OPB=%3d | RES=%0d  EXP_RES=%0d",
             "FAIL", $time, r_MODE, r_CMD, r_OPA, r_OPB, RES, EXP_RES);
else
    $display("%-6s  @%0t | MODE=%b CMD=%02h OPA=%3d OPB=%3d | RES=%0d",
             "PASS", $time, r_MODE, r_CMD, r_OPA, r_OPB, RES);

if (ERR !== EXP_ERR)
    $display("FAIL_ERR    @%0t | ERR=%b  EXP_ERR=%b",   $time, ERR,   EXP_ERR);

if (OFLOW !== EXP_OFLOW)
    $display("FAIL_OFLOW  @%0t | OFLOW=%b EXP_OFLOW=%b",$time, OFLOW, EXP_OFLOW);

if (COUT !== EXP_COUT)
    $display("FAIL_COUT   @%0t | COUT=%b  EXP_COUT=%b", $time, COUT,  EXP_COUT);

if ({G,L,E} !== {EXP_G,EXP_L,EXP_E})
    $display("FAIL_GLE    @%0t | GLE=%b%b%b EXP=%b%b%b",
             $time, G,L,E, EXP_G,EXP_L,EXP_E);

if (RES     === EXP_RES   &&
    ERR     === EXP_ERR   &&
    OFLOW   === EXP_OFLOW &&
    COUT    === EXP_COUT  &&
    {G,L,E} === {EXP_G,EXP_L,EXP_E})
    pass_cnt = pass_cnt + 1;
else
    fail_cnt = fail_cnt + 1;

end

end

    initial begin
        pass_cnt = 0;
        fail_cnt = 0;
        reset;
		valid_logic_inputs;
        valid_arithmetic_inputs;
        //  unknown_input;
        clock_enable;
        invalid_input;
        reset;
        multiplication;
      direct_cases;


      repeat(3) `CLOCK_DELAY;

        $display("=================================================");
        $display("  SIMULATION COMPLETE");
        $display("  PASS : %0d", pass_cnt);
        $display("  FAIL : %0d", fail_cnt);
        $display("=================================================");

        $finish;
    end



    initial begin
        $dumpfile("dump.vcd");
        $dumpvars;
    end
                     
endmodule

/*****************************************************************************************
*
*----------------------------------------------------------------------------------------
*                               END OF TESTBENCH
*----------------------------------------------------------------------------------------
*
*  Verification completed successfully.
*
*  Generated By :
*
*      KK    KK   IIIIIII   TTTTTTTTTTT   TTTTTTTTTTT   UUU     UUU
*      KK   KK       III          TTT           TTT      UUU     UUU
*      KK KK         III          TTT           TTT      UUU     UUU
*      KKKK          III          TTT           TTT      UUU     UUU
*      KK KK         III          TTT           TTT      UUU     UUU
*      KK   KK       III          TTT           TTT      UUU     UUU
*      KK    KK   IIIIIII         TTT           TTT       UUUUUUUUU
*
*                              K I T T U   P A T E L
*
*****************************************************************************************/
                                                                           
     

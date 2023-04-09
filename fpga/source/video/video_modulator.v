//`default_nettype none

module video_modulator(
    input  wire        clk,

    input  wire  [3:0] r,
    input  wire  [3:0] g,
    input  wire  [3:0] b,

    input  wire        color_burst,
    input  wire        active,
    input  wire        sync_n_in,

    output reg   [5:0] luma,
    output reg   [5:0] chroma);

    parameter Y_R = 27; // 38; //  0.299
    parameter Y_G = 53; // 75; //  0.587
    parameter Y_B = 10; // 14; //  0.114

    parameter I_R = 76; //  0.5959
    parameter I_G = 35; // -0.2746 (since this should be -35, *after* multiplication the result is negated)
    parameter I_B = 41; // -0.3213 (since this should be -41, *after* multiplication the result is negated)

    parameter Q_R = 27; //  0.2115
    parameter Q_G = 66; // -0.5227 (since this should be -66, *after* multiplication the result is negated)
    parameter Q_B = 40; //  0.3112

    // We set up two DSPs for 4 of the 9 multiplications

    wire [15:0] y_g_16, i_g_16;
    wire [15:0] y_r_16, i_r_16;
    
    // We use one DSP for two 8x8 unsigned multiplications
    video_modulator_mult_u8xu8_pair video_modulator_mult_ig_yg (
        .clk(clk),
        
        // i_g = I_G * g
        .input_1a_8(I_G[7:0]),
        .input_1b_8({4'b0000, g}),
        .output_1_16(i_g_16),
        
        // y_g = Y_G * g
        .input_2a_8(Y_G[7:0]),
        .input_2b_8({4'b0000, g}),
        .output_2_16(y_g_16)
    );
    
    // We use another DSP for two 8x8 unsigned multiplications
    video_modulator_mult_u8xu8_pair video_modulator_mult_yr_ir (
        .clk(clk),
        
        // y_r = Y_R * r
        .input_1a_8(Y_R[7:0]),
        .input_1b_8({4'b0000, r}),
        .output_1_16(y_r_16),
        
        // i_r = I_R * r
        .input_2a_8(I_R[7:0]),
        .input_2b_8({4'b0000, r}),
        .output_2_16(i_r_16)
    );
    
    // We need these five differently shifted values to replace the remaining multiplications by additions
    
    wire [4:0] g_times_2  = { g, 1'b0 };
    wire [9:0] g_times_64 = { g, 6'b000000 };

    wire [4:0] b_times_2  = { b, 1'b0 };
    wire [6:0] b_times_8  = { b, 3'b000 };
    wire [8:0] b_times_32 = { b, 5'b00000 };
    
    // We put together all the 9 multiplication results (all unsigned so far)

    wire [11:0] y_r, y_g, y_b;
    wire [11:0] i_r, i_g, i_b;
    wire [11:0] q_r, q_g, q_b;
    
    assign y_r = y_r_16[11:0];           // y_r = Y_R * r
    assign y_g = y_g_16[11:0];           // y_g = Y_G * g
    assign y_b = b_times_8 + b_times_2;  // y_b = Y_B * b and since Y_B is 10 (8+2): y_b = 8*b + 2*b
    
    assign q_r = y_r;                    // q_r = Q_R * r and since Q_R is Y_R: q_r = y_r
    assign q_g = g_times_64 + g_times_2; // q_g = Q_G * g and since Q_G is 66 (64+2): q_g = 64*g + 2*g
    assign q_b = b_times_32 + b_times_8; // q_b = Q_B * b and since Q_B is 40 (32+8): q_b = 32*b + 8*b

    assign i_r = i_r_16[11:0];           // i_r = I_R * r
    assign i_g = i_g_16[11:0];           // i_g = I_G * g
    assign i_b = q_b + b;                // i_b = I_B * b and since I_B is 41 (32+8+1): i_b = q_b + 1*b
    
    reg signed [11:0] y_s;
    reg signed [11:0] i_s;
    reg signed [11:0] q_s;
    
    always @(posedge clk) begin
        
        case ({active, color_burst})
            2'b00: begin
                y_s <= (sync_n_in == 0) ? 12'd0 : 12'd544;
                i_s <= 0;
                q_s <= 0;
            end
            2'b01: begin
                y_s <= (sync_n_in == 0) ? 12'd0 : 12'd544;
                i_s <= (I_R * 5'd9) - (I_G * 5'd9) - (I_B * 5'd0);
                q_s <= (Q_R * 5'd9) - (Q_G * 5'd9) + (Q_B * 5'd0);
            end
            2'b10: begin
                y_s <= y_r + y_g + y_b + (128 + 512);
                i_s <= i_r - i_g - i_b;                 // Effectively negating i_g and i_b here
                q_s <= q_r - q_g + q_b;                 // Effectively negating q_g here
            end
            2'b11: begin
                y_s <= (Y_R * 5'd9) + (Y_G * 5'd9) + (Y_B * 5'd0) + (128 + 512);
                i_s <= (I_R * 5'd9) - (I_G * 5'd9) - (I_B * 5'd0);
                q_s <= (Q_R * 5'd9) - (Q_G * 5'd9) + (Q_B * 5'd0);
            end
        endcase
        
    end

    // Color burst frequency: 315/88 MHz = 3579545 Hz
    reg  [23:0] phase_accum_r = 0;
    always @(posedge clk) phase_accum_r <= phase_accum_r + 24'd2402192;

    wire [7:0] sinval;
    video_modulator_sinlut sinlut(
        .clk(clk),
        .phase(phase_accum_r[23:15]),
        .value(sinval));

    wire [7:0] cosval;
    video_modulator_coslut coslut(
        .clk(clk),
        .phase(phase_accum_r[23:15]),
        .value(cosval));

    wire signed [7:0] sinval_s = sinval;
    wire signed [7:0] cosval_s = cosval;

    wire signed [7:0] i8_s = i_s[11:4];
    wire signed [7:0] q8_s = q_s[11:4];

    reg         [7:0] lum;
    reg signed [13:0] chroma_s;

    always @(posedge clk) begin
        if (y_s < 0)
            lum <= 0;
        else if (y_s >= 2047)
            lum <= 255;
        else
            lum <= y_s[10:3];
            
        chroma_s <= (cosval_s * i8_s) + (sinval_s * q8_s);
    end

    always @(posedge clk) begin
        luma   <= lum[7:2];
        chroma <= chroma_s[13:8] + 6'd32;
    end

endmodule

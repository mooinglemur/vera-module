//`default_nettype none

module psg(
    input  wire        rst,
    input  wire        clk,

    // PSG interface
    input  wire  [5:0] attr_addr,
    input  wire  [7:0] attr_wrdata,
    input  wire        attr_write,

    input  wire        next_sample,

    // Audio output
    output wire [15:0] left_audio,
    output wire [15:0] right_audio) /* synthesis syn_hier = "hard" */;

    //////////////////////////////////////////////////////////////////////////
    // Audio attribute RAM
    //////////////////////////////////////////////////////////////////////////
    reg   [2:0] cur_channel_byte_r;
    reg   [3:0] cur_channel_r;
    wire  [7:0] attr_rddata;

    dpram #(.ADDR_WIDTH(6), .DATA_WIDTH(8)) audio_attr_ram(
        .rd_clk(clk),
        .rd_addr({cur_channel_r, cur_channel_byte_r[1:0]}),
        .rd_data(attr_rddata),

        .wr_clk(clk),
        .wr_addr(attr_addr),
        .wr_data(attr_wrdata),
        .wr_en(attr_write));


    reg  [31:0] cur_channel_attr_r;

    wire [15:0] cur_freq       = cur_channel_attr_r[15:0];
    wire  [5:0] cur_volume     = cur_channel_attr_r[21:16];
    wire        cur_left_en    = cur_channel_attr_r[22];
    wire        cur_right_en   = cur_channel_attr_r[23];
    wire  [5:0] cur_pulsewidth = cur_channel_attr_r[29:24];
    wire  [1:0] cur_waveform   = cur_channel_attr_r[31:30];

    // Logarithmic volume conversion (0.5dB per step)
    reg [5:0] cur_volume_log;
    always @* case (cur_volume)
        6'd0:  cur_volume_log = 6'd0;
        6'd1:  cur_volume_log = 6'd1;
        6'd2:  cur_volume_log = 6'd1;
        6'd3:  cur_volume_log = 6'd1;
        6'd4:  cur_volume_log = 6'd2;
        6'd5:  cur_volume_log = 6'd2;
        6'd6:  cur_volume_log = 6'd2;
        6'd7:  cur_volume_log = 6'd2;
        6'd8:  cur_volume_log = 6'd2;
        6'd9:  cur_volume_log = 6'd2;
        6'd10: cur_volume_log = 6'd2;
        6'd11: cur_volume_log = 6'd3;
        6'd12: cur_volume_log = 6'd3;
        6'd13: cur_volume_log = 6'd3;
        6'd14: cur_volume_log = 6'd3;
        6'd15: cur_volume_log = 6'd3;
        6'd16: cur_volume_log = 6'd4;
        6'd17: cur_volume_log = 6'd4;
        6'd18: cur_volume_log = 6'd4;
        6'd19: cur_volume_log = 6'd4;
        6'd20: cur_volume_log = 6'd5;
        6'd21: cur_volume_log = 6'd5;
        6'd22: cur_volume_log = 6'd5;
        6'd23: cur_volume_log = 6'd6;
        6'd24: cur_volume_log = 6'd6;
        6'd25: cur_volume_log = 6'd7;
        6'd26: cur_volume_log = 6'd7;
        6'd27: cur_volume_log = 6'd7;
        6'd28: cur_volume_log = 6'd8;
        6'd29: cur_volume_log = 6'd8;
        6'd30: cur_volume_log = 6'd9;
        6'd31: cur_volume_log = 6'd9;
        6'd32: cur_volume_log = 6'd10;
        6'd33: cur_volume_log = 6'd11;
        6'd34: cur_volume_log = 6'd11;
        6'd35: cur_volume_log = 6'd12;
        6'd36: cur_volume_log = 6'd13;
        6'd37: cur_volume_log = 6'd14;
        6'd38: cur_volume_log = 6'd14;
        6'd39: cur_volume_log = 6'd15;
        6'd40: cur_volume_log = 6'd16;
        6'd41: cur_volume_log = 6'd17;
        6'd42: cur_volume_log = 6'd18;
        6'd43: cur_volume_log = 6'd19;
        6'd44: cur_volume_log = 6'd21;
        6'd45: cur_volume_log = 6'd22;
        6'd46: cur_volume_log = 6'd23;
        6'd47: cur_volume_log = 6'd25;
        6'd48: cur_volume_log = 6'd26;
        6'd49: cur_volume_log = 6'd28;
        6'd50: cur_volume_log = 6'd29;
        6'd51: cur_volume_log = 6'd31;
        6'd52: cur_volume_log = 6'd33;
        6'd53: cur_volume_log = 6'd35;
        6'd54: cur_volume_log = 6'd37;
        6'd55: cur_volume_log = 6'd39;
        6'd56: cur_volume_log = 6'd42;
        6'd57: cur_volume_log = 6'd44;
        6'd58: cur_volume_log = 6'd47;
        6'd59: cur_volume_log = 6'd50;
        6'd60: cur_volume_log = 6'd52;
        6'd61: cur_volume_log = 6'd56;
        6'd62: cur_volume_log = 6'd59;
        6'd63: cur_volume_log = 6'd63;
    endcase

    //////////////////////////////////////////////////////////////////////////
    // Noise generator
    //////////////////////////////////////////////////////////////////////////
    reg [15:0] lfsr_r;
    reg [5:0] noise_value_r;
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            lfsr_r        <= 16'd1;
            noise_value_r <= 6'd0;
        end else begin
            lfsr_r        <= {lfsr_r[14:0], lfsr_r[1] ^ lfsr_r[2] ^ lfsr_r[4] ^ lfsr_r[15]};
            noise_value_r <= {noise_value_r[4:0], lfsr_r[0]};
        end
    end

    //////////////////////////////////////////////////////////////////////////
    // Working data RAM
    //////////////////////////////////////////////////////////////////////////
    wire [22:0] cur_working_data;

    wire  [5:0] cur_noise = cur_working_data[22:17];
    wire [16:0] cur_phase = cur_working_data[16:0];

    wire [16:0] new_phase = (cur_left_en | cur_right_en) ? (cur_phase + cur_freq) : 17'd0;

    wire        do_noise_sample = cur_phase[16] && !new_phase[16];
    wire  [5:0] new_noise = do_noise_sample ? noise_value_r : cur_noise;

    reg   [3:0] working_data_wridx_r;
    wire [22:0] working_data_wrdata = {new_noise, new_phase};
    reg         working_data_wren_r;

    dpram #(.ADDR_WIDTH(4), .DATA_WIDTH(23)) working_data_ram(
        .rd_clk(clk),
        .rd_addr(cur_channel_r),
        .rd_data(cur_working_data),

        .wr_clk(clk),
        .wr_addr(working_data_wridx_r),
        .wr_data(working_data_wrdata),
        .wr_en(working_data_wren_r));

    //////////////////////////////////////////////////////////////////////////
    // Signal generation
    //////////////////////////////////////////////////////////////////////////
    wire [5:0] signal_pw       = (cur_phase[16:10] > {1'b0, cur_pulsewidth}) ? 6'd0 : 6'd63;
    wire [5:0] signal_saw      = cur_phase[16:11];
    wire [5:0] signal_triangle = cur_phase[16] ? ~cur_phase[15:10] : cur_phase[15:10];
    wire [5:0] signal_noise    = cur_noise;

    reg [5:0] signal;
    always @* case (cur_waveform)
        2'b00: signal = signal_pw;
        2'b01: signal = signal_saw;
        2'b10: signal = signal_triangle;
        2'b11: signal = signal_noise;
    endcase

    wire signed  [5:0] signed_signal = signal ^ 6'h20;
    wire signed  [6:0] signed_volume = {1'b0, cur_volume_log};
    wire signed [11:0] scaled_signal = signed_signal * signed_volume;

    //////////////////////////////////////////////////////////////////////////
    // Audio generator state machine
    //////////////////////////////////////////////////////////////////////////
    reg signed [15:0] left_sample_r, right_sample_r;
    reg signed [15:0] left_accum_r,  right_accum_r;

    parameter
        IDLE     = 3'b00,
        FETCH_CH = 3'b01,
        CALC_CH  = 3'b10;

    reg [1:0] state_r;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            cur_channel_r  <= 0;
            left_sample_r  <= 0;
            right_sample_r <= 0;
            left_accum_r   <= 0;
            right_accum_r  <= 0;
            state_r        <= IDLE;

            working_data_wridx_r <= 0;
            working_data_wren_r  <= 0;

            cur_channel_byte_r <= 0;
            cur_channel_attr_r <= 0;

        end else begin
            working_data_wren_r <= 0;

            case (state_r)
                IDLE: begin
                    left_sample_r  <= left_accum_r;
                    right_sample_r <= right_accum_r;

                    if (next_sample) begin
                        state_r            <= FETCH_CH;
                        cur_channel_r      <= 0;
                        cur_channel_byte_r <= 0;
                        left_accum_r       <= 0;
                        right_accum_r      <= 0;
                    end
                end

                FETCH_CH: begin
                    if (cur_channel_byte_r == 'd4) begin
                        state_r <= CALC_CH;
                    end

                    cur_channel_attr_r <= {attr_rddata, cur_channel_attr_r[31:8]};
                    cur_channel_byte_r <= cur_channel_byte_r + 3'd1;
                end

                CALC_CH: begin
                    if (cur_left_en)  left_accum_r  <= left_accum_r  + scaled_signal;
                    if (cur_right_en) right_accum_r <= right_accum_r + scaled_signal;

                    working_data_wridx_r <= cur_channel_r;
                    working_data_wren_r  <= 1;

                    if (cur_channel_r == 'd15) begin
                        state_r <= IDLE;
                    end else begin
                        state_r            <= FETCH_CH;
                    end

                    cur_channel_byte_r <= 0;
                    cur_channel_r <= cur_channel_r + 4'd1;
                end
            endcase
        end
    end

    assign left_audio  = left_sample_r;
    assign right_audio = right_sample_r;

endmodule

//`default_nettype none

module addr_data(
    input  wire        reset,
    input  wire        clk,

    input wire         do_read,
    input wire         do_write,
    input wire   [4:0] access_addr,
    input wire   [7:0] write_data,
    input wire   [7:0] vram_rddata,
    
    input wire         vram_addr_select,
    input wire   [5:0] dc_select,

    output wire [16:0] vram_addr_0,
    output wire [16:0] vram_addr_1,
    output wire  [3:0] vram_addr_incr_0,
    output wire  [3:0] vram_addr_incr_1,
    output wire        vram_addr_decr_0,
    output wire        vram_addr_decr_1,
    output wire  [7:0] vram_data0,
    output wire  [7:0] vram_data1,

    output wire [16:0] ib_addr,
    output wire  [7:0] ib_wrdata,
    output wire        ib_write,
    output wire        ib_do_access,

    output wire  [1:0] fx_addr1_mode
    );

    //////////////////////////////////////////////////////////////////////////
    // Bus accessible registers
    //////////////////////////////////////////////////////////////////////////

    reg [16:0] vram_addr_0_r,                 vram_addr_0_next;
    reg [16:0] vram_addr_1_r,                 vram_addr_1_next;
    reg  [3:0] vram_addr_incr_0_r,            vram_addr_incr_0_next;
    reg  [3:0] vram_addr_incr_1_r,            vram_addr_incr_1_next;
    reg        vram_addr_decr_0_r,            vram_addr_decr_0_next;
    reg        vram_addr_decr_1_r,            vram_addr_decr_1_next;
    reg  [7:0] vram_data0_r,                  vram_data0_next;
    reg  [7:0] vram_data1_r,                  vram_data1_next;
    
    assign vram_addr_0 = vram_addr_0_r;
    assign vram_addr_1 = vram_addr_1_r;
    assign vram_addr_incr_0 = vram_addr_incr_0_r;
    assign vram_addr_incr_1 = vram_addr_incr_1_r;
    assign vram_addr_decr_0 = vram_addr_decr_0_r;
    assign vram_addr_decr_1 = vram_addr_decr_1_r;
    assign vram_data0 = vram_data0_r;
    assign vram_data1 = vram_data1_r;

    reg  [16:0] ib_addr_r,                   ib_addr_next;
    reg   [7:0] ib_wrdata_r,                 ib_wrdata_next;
    reg         ib_write_r,                  ib_write_next;
    reg         ib_do_access_r,              ib_do_access_next;

    assign ib_addr = ib_addr_r;
    assign ib_wrdata = ib_wrdata_r;
    assign ib_write = ib_write_r;
    assign ib_do_access = ib_do_access_r;
    
    parameter
        MODE_NORMAL      = 2'b00,
        MODE_LINE_DRAW   = 2'b01,
        
        ADDR0_UNTOUCHED  = 2'b00,
        ADDR0_SET        = 2'b01,
        ADDR0_INCR_0     = 2'b10,
        
        ADDR1_UNTOUCHED  = 3'b000,
        ADDR1_INCR_1     = 3'b001,
        ADDR1_SET        = 3'b111;


    reg  [1:0] fx_addr1_mode_r,               fx_addr1_mode_next;

    assign fx_addr1_mode = fx_addr1_mode_r;

    //////////////////////////////////////////////////////////////////////////
    // Address incrementers
    //////////////////////////////////////////////////////////////////////////
    
    reg signed [10:0] incr_decr_0;
    always @* case ({vram_addr_decr_0_r, vram_addr_incr_0_r})
        5'h00: incr_decr_0 = 11'd0;
        5'h01: incr_decr_0 = 11'd1;
        5'h02: incr_decr_0 = 11'd2;
        5'h03: incr_decr_0 = 11'd4;
        5'h04: incr_decr_0 = 11'd8;
        5'h05: incr_decr_0 = 11'd16;
        5'h06: incr_decr_0 = 11'd32;
        5'h07: incr_decr_0 = 11'd64;
        5'h08: incr_decr_0 = 11'd128;
        5'h09: incr_decr_0 = 11'd256;
        5'h0A: incr_decr_0 = 11'd512;
        5'h0B: incr_decr_0 = 11'd40;
        5'h0C: incr_decr_0 = 11'd80;
        5'h0D: incr_decr_0 = 11'd160;
        5'h0E: incr_decr_0 = 11'd320;
        5'h0F: incr_decr_0 = 11'd640;
        5'h10: incr_decr_0 = -11'd0;
        5'h11: incr_decr_0 = -11'd1;
        5'h12: incr_decr_0 = -11'd2;
        5'h13: incr_decr_0 = -11'd4;
        5'h14: incr_decr_0 = -11'd8;
        5'h15: incr_decr_0 = -11'd16;
        5'h16: incr_decr_0 = -11'd32;
        5'h17: incr_decr_0 = -11'd64;
        5'h18: incr_decr_0 = -11'd128;
        5'h19: incr_decr_0 = -11'd256;
        5'h1A: incr_decr_0 = -11'd512;
        5'h1B: incr_decr_0 = -11'd40;
        5'h1C: incr_decr_0 = -11'd80;
        5'h1D: incr_decr_0 = -11'd160;
        5'h1E: incr_decr_0 = -11'd320;
        5'h1F: incr_decr_0 = -11'd640;
    endcase

    reg  signed [10:0] incr_decr_1;
    always @* case ({vram_addr_decr_1_r, vram_addr_incr_1_r})
        5'h00: incr_decr_1 = 11'd0;
        5'h01: incr_decr_1 = 11'd1;
        5'h02: incr_decr_1 = 11'd2;
        5'h03: incr_decr_1 = 11'd4;
        5'h04: incr_decr_1 = 11'd8;
        5'h05: incr_decr_1 = 11'd16;
        5'h06: incr_decr_1 = 11'd32;
        5'h07: incr_decr_1 = 11'd64;
        5'h08: incr_decr_1 = 11'd128;
        5'h09: incr_decr_1 = 11'd256;
        5'h0A: incr_decr_1 = 11'd512;
        5'h0B: incr_decr_1 = 11'd40;
        5'h0C: incr_decr_1 = 11'd80;
        5'h0D: incr_decr_1 = 11'd160;
        5'h0E: incr_decr_1 = 11'd320;
        5'h0F: incr_decr_1 = 11'd640;
        5'h10: incr_decr_1 = -11'd0;
        5'h11: incr_decr_1 = -11'd1;
        5'h12: incr_decr_1 = -11'd2;
        5'h13: incr_decr_1 = -11'd4;
        5'h14: incr_decr_1 = -11'd8;
        5'h15: incr_decr_1 = -11'd16;
        5'h16: incr_decr_1 = -11'd32;
        5'h17: incr_decr_1 = -11'd64;
        5'h18: incr_decr_1 = -11'd128;
        5'h19: incr_decr_1 = -11'd256;
        5'h1A: incr_decr_1 = -11'd512;
        5'h1B: incr_decr_1 = -11'd40;
        5'h1C: incr_decr_1 = -11'd80;
        5'h1D: incr_decr_1 = -11'd160;
        5'h1E: incr_decr_1 = -11'd320;
        5'h1F: incr_decr_1 = -11'd640;
    endcase

    // Note: we are sign extending here, since it might be a negative number
    wire [16:0] vram_addr_0_incr_decr_0  = vram_addr_0_r + { {6{incr_decr_0[10]}}, incr_decr_0};
    wire [16:0] vram_addr_1_incr_decr_1  = vram_addr_1_r + { {6{incr_decr_1[10]}}, incr_decr_1};

    //////////////////////////////////////////////////////////////////////////
    // Internal registers
    //////////////////////////////////////////////////////////////////////////

    reg         save_result_r;
    reg         save_result_port_r;

    reg         fetch_ahead_r,  fetch_ahead_next;
    reg         fetch_ahead_port_r,  fetch_ahead_port_next;
    
    reg  [16:0] vram_addr_0_untouched_or_set;
    reg         vram_addr_0_untouched_or_set_bit16;
    reg   [7:0] vram_addr_0_untouched_or_set_high, vram_addr_0_untouched_or_set_low;
        
    reg  [16:0] vram_addr_1_untouched_or_set;
    reg         vram_addr_1_untouched_or_set_bit16;
    reg   [7:0] vram_addr_1_untouched_or_set_high, vram_addr_1_untouched_or_set_low;
    
    reg  [1:0]  fx_vram_addr_0_needs_to_be_changed;
    reg  [2:0]  fx_vram_addr_1_needs_to_be_changed;
    always @* begin
        // vram_addr_0_next                 = vram_addr_0_r;
        // vram_addr_1_next                 = vram_addr_1_r;
        vram_addr_incr_0_next            = vram_addr_incr_0_r;
        vram_addr_incr_1_next            = vram_addr_incr_1_r;
        vram_addr_decr_0_next            = vram_addr_decr_0_r;
        vram_addr_decr_1_next            = vram_addr_decr_1_r;
        vram_data0_next                  = vram_data0_r;
        vram_data1_next                  = vram_data1_r;
        
        fx_addr1_mode_next               = fx_addr1_mode_r;

        fx_vram_addr_0_needs_to_be_changed  = 0;
        fx_vram_addr_1_needs_to_be_changed  = 0;

        ib_addr_next                     = ib_addr_r;
        ib_wrdata_next                   = ib_wrdata_r;
        ib_write_next                    = ib_write_r;
        ib_do_access_next                = 0;

        fetch_ahead_port_next            = fetch_ahead_port_r;
        fetch_ahead_next                 = 0;

        //////////////////////////////////////////////////////////////////////////
        // Save the result coming from VRAM reads
        //////////////////////////////////////////////////////////////////////////

        if (save_result_r && !save_result_port_r) begin
            vram_data0_next = vram_rddata;
        end
        if (save_result_r && save_result_port_r) begin
            vram_data1_next = vram_rddata;
        end

        //////////////////////////////////////////////////////////////////////////
        // Writes to addresses 00, 01 and 02 (ADDRx_L, ADDRx_M, ADDRx_H)
        //////////////////////////////////////////////////////////////////////////

        if (do_write && access_addr == 5'h00 && vram_addr_select) begin
            vram_addr_1_untouched_or_set_low = write_data;
        end else begin
            vram_addr_1_untouched_or_set_low = vram_addr_1_r[7:0];
        end
        if (do_write && access_addr == 5'h00 && !vram_addr_select) begin
            vram_addr_0_untouched_or_set_low = write_data;
        end else begin
            vram_addr_0_untouched_or_set_low = vram_addr_0_r[7:0];
        end
        
        if (do_write && access_addr == 5'h01 && vram_addr_select) begin
            vram_addr_1_untouched_or_set_high = write_data;
        end else begin
            vram_addr_1_untouched_or_set_high = vram_addr_1_r[15:8];
        end
        if (do_write && access_addr == 5'h01 && !vram_addr_select) begin
            vram_addr_0_untouched_or_set_high = write_data;
        end else begin
            vram_addr_0_untouched_or_set_high = vram_addr_0_r[15:8];
        end
        
        if (do_write && access_addr == 5'h02 && vram_addr_select) begin
            vram_addr_1_untouched_or_set_bit16 = write_data[0];
            vram_addr_incr_1_next = write_data[7:4];
            vram_addr_decr_1_next = write_data[3];
        end else begin
            vram_addr_1_untouched_or_set_bit16 = vram_addr_1_r[16];
        end
        if (do_write && access_addr == 5'h02 && !vram_addr_select) begin
            vram_addr_0_untouched_or_set_bit16 = write_data[0];
            vram_addr_incr_0_next = write_data[7:4];
            vram_addr_decr_0_next = write_data[3];
        end else begin
            vram_addr_0_untouched_or_set_bit16 = vram_addr_0_r[16];
        end

        vram_addr_0_untouched_or_set = { vram_addr_0_untouched_or_set_bit16, vram_addr_0_untouched_or_set_high, vram_addr_0_untouched_or_set_low};
        vram_addr_1_untouched_or_set = { vram_addr_1_untouched_or_set_bit16, vram_addr_1_untouched_or_set_high, vram_addr_1_untouched_or_set_low};


        //////////////////////////////////////////////////////////////////////////
        // ADDR0 control logic and assignment
        //////////////////////////////////////////////////////////////////////////

        if (do_write && (access_addr == 5'h00 || access_addr == 5'h01 || access_addr == 5'h02) && !vram_addr_select) begin
            fx_vram_addr_0_needs_to_be_changed = ADDR0_SET;
        end else if ((do_write || do_read) && access_addr == 5'h03) begin
            fx_vram_addr_0_needs_to_be_changed = ADDR0_INCR_0;
        end

        if (fx_vram_addr_0_needs_to_be_changed == ADDR0_INCR_0) begin
            vram_addr_0_next = vram_addr_0_incr_decr_0;
        end else begin
            vram_addr_0_next = vram_addr_0_untouched_or_set;
        end

        //////////////////////////////////////////////////////////////////////////
        // Reads from and writes to addresses 03 and 04 (DATA0 and DATA1)
        //////////////////////////////////////////////////////////////////////////


        if ((do_write || do_read) && (access_addr == 5'h03 || access_addr == 5'h04)) begin
            ib_write_next  = do_write;
        end

        if (do_write && (access_addr == 5'h03 || access_addr == 5'h04)) begin
            ib_wrdata_next = write_data;
            ib_addr_next = access_addr == 5'h03 ? vram_addr_0_r : vram_addr_1_r;
            ib_do_access_next = 1;
        end

        //////////////////////////////////////////////////////////////////////////
        // Writes to addresses 09, 0A, 0B and 0C (DCSEL = 2,3,4,5 and 6)
        //////////////////////////////////////////////////////////////////////////
        
        if (do_write && access_addr == 5'h09 && dc_select == 2) begin
            fx_addr1_mode_next = write_data[1:0];
        end

        //////////////////////////////////////////////////////////////////////////
        // ADDR1 control logic and assignment
        //////////////////////////////////////////////////////////////////////////

        if (do_write && (access_addr == 5'h00 || access_addr == 5'h01 || access_addr == 5'h02) && vram_addr_select) begin
            fx_vram_addr_1_needs_to_be_changed = ADDR1_SET;
        end else if ((do_write || do_read) && access_addr == 5'h04 && fx_addr1_mode_r == MODE_NORMAL) begin
            // in normal addr1-mode we do a "normal" increment
            fx_vram_addr_1_needs_to_be_changed = ADDR1_INCR_1;  // addr_1 needs to be set with vram_addr_1_incr_decr_1
        end

        case (fx_vram_addr_1_needs_to_be_changed)
            ADDR1_INCR_1: begin
                // We increment addr1 with its own incrementer 
                vram_addr_1_next = vram_addr_1_incr_decr_1;
            end
            default: begin  // ADDR1_UNTOUCHED, ADDR1_SET (and the unused values)
                // We leave addr1 unchanged, unless just externally/explcitly set
                vram_addr_1_next = vram_addr_1_untouched_or_set;
            end

        endcase

        //////////////////////////////////////////////////////////////////////////
        // Determination of what to fetch ahead
        //////////////////////////////////////////////////////////////////////////

        if (fx_vram_addr_0_needs_to_be_changed) begin
            fetch_ahead_port_next = 0;
            fetch_ahead_next = 1;
        end else if (fx_vram_addr_1_needs_to_be_changed) begin
            fetch_ahead_next = 1;
            fetch_ahead_port_next = 1;
        end
          
        //////////////////////////////////////////////////////////////////////////
        // Executing the fetch ahead
        //////////////////////////////////////////////////////////////////////////
          
        if (fetch_ahead_r) begin
            ib_addr_next      = fetch_ahead_port_r ? vram_addr_1_r : vram_addr_0_r;
            ib_write_next     = 0;
            ib_do_access_next = 1;
        end

    end

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            vram_addr_0_r                 <= 0;
            vram_addr_1_r                 <= 0;
            vram_addr_incr_0_r            <= 0;
            vram_addr_incr_1_r            <= 0;
            vram_addr_decr_0_r            <= 0;
            vram_addr_decr_1_r            <= 0;
            vram_data0_r                  <= 0;
            vram_data1_r                  <= 0;

            fx_addr1_mode_r               <= 0;

            ib_addr_r                     <= 0;
            ib_wrdata_r                   <= 0;
            ib_do_access_r                <= 0;
            ib_write_r                    <= 0;

            fetch_ahead_r                 <= 0;
            fetch_ahead_port_r            <= 0;

            save_result_r                 <= 0;
            save_result_port_r            <= 0;
        end else begin
            vram_addr_0_r                 <= vram_addr_0_next;
            vram_addr_1_r                 <= vram_addr_1_next;
            vram_addr_incr_0_r            <= vram_addr_incr_0_next;
            vram_addr_incr_1_r            <= vram_addr_incr_1_next;
            vram_addr_decr_0_r            <= vram_addr_decr_0_next;
            vram_addr_decr_1_r            <= vram_addr_decr_1_next;
            vram_data0_r                  <= vram_data0_next;
            vram_data1_r                  <= vram_data1_next;

            fx_addr1_mode_r               <= fx_addr1_mode_next;
            ib_addr_r                     <= ib_addr_next;
            ib_wrdata_r                   <= ib_wrdata_next;
            ib_do_access_r                <= ib_do_access_next;
            ib_write_r                    <= ib_write_next;

            fetch_ahead_r                 <= fetch_ahead_next;
            fetch_ahead_port_r            <= fetch_ahead_port_next;

            save_result_r                 <= ib_do_access_r && !ib_write_r;
            save_result_port_r            <= fetch_ahead_port_r;
        end
    end
    
endmodule


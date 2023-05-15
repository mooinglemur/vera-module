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
    output wire        ib_do_access
    );

    reg [16:0] vram_addr_0_r,                 vram_addr_0_next;
    reg [16:0] vram_addr_1_r,                 vram_addr_1_next;
    reg  [3:0] vram_addr_incr_0_r,            vram_addr_incr_0_next;
    reg  [3:0] vram_addr_incr_1_r,            vram_addr_incr_1_next;
    reg        vram_addr_decr_0_r,            vram_addr_decr_0_next;
    reg        vram_addr_decr_1_r,            vram_addr_decr_1_next;
    reg  [7:0] vram_data0_r,                  vram_data0_next;
    reg  [7:0] vram_data1_r,                  vram_data1_next;

    // Decode increment value
    wire [3:0] incr_regval = (access_addr == 5'h03) ? vram_addr_incr_0_r : vram_addr_incr_1_r;
    reg [9:0] increment;
    always @* case (incr_regval)
        4'h0: increment = 'd0;
        4'h1: increment = 'd1;
        4'h2: increment = 'd2;
        4'h3: increment = 'd4;
        4'h4: increment = 'd8;
        4'h5: increment = 'd16;
        4'h6: increment = 'd32;
        4'h7: increment = 'd64;
        4'h8: increment = 'd128;
        4'h9: increment = 'd256;
        4'hA: increment = 'd512;
        4'hB: increment = 'd40;
        4'hC: increment = 'd80;
        4'hD: increment = 'd160;
        4'hE: increment = 'd320;
        4'hF: increment = 'd640;
    endcase

    reg [16:0] ib_addr_r,      ib_addr_next;
    reg  [7:0] ib_wrdata_r,    ib_wrdata_next;
    reg        ib_write_r,     ib_write_next;
    reg        ib_do_access_r, ib_do_access_next;

    reg        save_result_r;
    reg        save_result_port_r;

    reg        fetch_ahead_r,  fetch_ahead_next;
    reg        fetch_ahead_port_r,  fetch_ahead_port_next;
    
    assign vram_addr_0 = vram_addr_0_r;
    assign vram_addr_1 = vram_addr_1_r;
    assign vram_addr_incr_0 = vram_addr_incr_0_r;
    assign vram_addr_incr_1 = vram_addr_incr_1_r;
    assign vram_addr_decr_0 = vram_addr_decr_0_r;
    assign vram_addr_decr_1 = vram_addr_decr_1_r;
    assign vram_data0 = vram_data0_r;
    assign vram_data1 = vram_data1_r;

    assign ib_addr = ib_addr_r;
    assign ib_wrdata = ib_wrdata_r;
    assign ib_write = ib_write_r;
    assign ib_do_access = ib_do_access_r;
    

    wire [16:0] vram_addr             = (access_addr == 5'h03) ? vram_addr_0_r : vram_addr_1_r;
    wire        vram_addr_decr        = (access_addr == 5'h03) ? vram_addr_decr_0_r : vram_addr_decr_1_r;
    wire [16:0] vram_addr_incremented = vram_addr + increment;
    wire [16:0] vram_addr_decremented = vram_addr - increment;
    wire [16:0] vram_addr_new         = vram_addr_decr ? vram_addr_decremented : vram_addr_incremented;

    always @* begin
        vram_addr_0_next                 = vram_addr_0_r;
        vram_addr_1_next                 = vram_addr_1_r;
        vram_addr_incr_0_next            = vram_addr_incr_0_r;
        vram_addr_incr_1_next            = vram_addr_incr_1_r;
        vram_addr_decr_0_next            = vram_addr_decr_0_r;
        vram_addr_decr_1_next            = vram_addr_decr_1_r;
        vram_data0_next                  = vram_data0_r;
        vram_data1_next                  = vram_data1_r;
        
        ib_addr_next                     = ib_addr_r;
        ib_wrdata_next                   = ib_wrdata_r;
        ib_write_next                    = ib_write_r;
        ib_do_access_next                = 0;

        fetch_ahead_port_next            = fetch_ahead_port_r;
        fetch_ahead_next                 = 0;

        if (save_result_r) begin
            if (!save_result_port_r) begin
                vram_data0_next = vram_rddata;
            end else begin
                vram_data1_next = vram_rddata;
            end
        end
        
        if (do_write && access_addr == 5'h00) begin
            if (vram_addr_select) begin
                vram_addr_1_next[7:0] = write_data;
            end else begin
                vram_addr_0_next[7:0] = write_data;
            end

            fetch_ahead_port_next = vram_addr_select;
            fetch_ahead_next = 1;
        end
        if (do_write && access_addr == 5'h01) begin
            if (vram_addr_select) begin
                vram_addr_1_next[15:8] = write_data;
            end else begin
                vram_addr_0_next[15:8] = write_data;
            end

            fetch_ahead_port_next = vram_addr_select;
            fetch_ahead_next = 1;
        end
        if (do_write && access_addr == 5'h02) begin
            if (vram_addr_select) begin
                vram_addr_incr_1_next = write_data[7:4];
                vram_addr_decr_1_next = write_data[3];
                vram_addr_1_next[16]  = write_data[0];
            end else begin
                vram_addr_incr_0_next = write_data[7:4];
                vram_addr_decr_0_next = write_data[3];
                vram_addr_0_next[16]  = write_data[0];
            end

            fetch_ahead_port_next = vram_addr_select;
            fetch_ahead_next = 1;
        end
        if ((do_write || do_read) && (access_addr == 5'h03 || access_addr == 5'h04)) begin
            ib_wrdata_next = write_data;
            ib_write_next  = do_write;

            if (do_write) begin
                ib_addr_next = access_addr == 5'h03 ? vram_addr_0_r : vram_addr_1_r;
                ib_do_access_next = 1;
            end

            if (access_addr == 5'h03) begin
                fetch_ahead_port_next = 0;
                vram_addr_0_next = vram_addr_new;
            end else begin
                fetch_ahead_port_next = 1;
                vram_addr_1_next = vram_addr_new;
            end
            fetch_ahead_next = 1;
        end
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


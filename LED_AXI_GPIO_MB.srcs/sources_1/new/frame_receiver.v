`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 19.10.2026 17:24:38
// Design Name: 
// Module Name: frame_receiver
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module frame_receiver (
    input  wire        aclk,
    input  wire        aresetn,

    // Control from MicroBlaze
    input  wire        start,

    // External 8-bit pixel stream
    input  wire [7:0]  pixel_data,
    input  wire        pixel_valid,
    output wire        pixel_ready,

    // AXI4-Stream master to AXI DMA S_AXIS_S2MM
    output wire [31:0] m_axis_tdata,
    output wire        m_axis_tvalid,
    input  wire        m_axis_tready,
    output wire        m_axis_tlast,
    output wire [3:0]  m_axis_tkeep
);

    localparam FRAME_PIXELS = 64000;
    localparam FRAME_WORDS  = 16000;

    // FIFO: 1024 words x 32 bits
    localparam FIFO_DEPTH = 1024;
    localparam PTR_WIDTH  = 10;
    localparam CNT_WIDTH  = 11;

    reg [31:0] fifo_mem [0:FIFO_DEPTH-1];

    reg [PTR_WIDTH-1:0] wr_ptr;
    reg [PTR_WIDTH-1:0] rd_ptr;
    reg [CNT_WIDTH-1:0] fifo_count;

    reg        active;
    reg [15:0] pixel_count;
    reg [13:0] sent_words;

    // Pack four 8-bit pixels into one 32-bit word
    reg [31:0] pack_reg;
    reg [1:0]  pack_count;

    wire fifo_pop;
    wire pixel_accept;
    wire fifo_push;

    assign m_axis_tvalid = (fifo_count != 0);
    assign m_axis_tdata  = fifo_mem[rd_ptr];
    assign m_axis_tkeep  = 4'b1111;

    assign m_axis_tlast =
        m_axis_tvalid && (sent_words == FRAME_WORDS - 1);

    assign fifo_pop = m_axis_tvalid && m_axis_tready;

    // Accept a pixel only when the receiver is active.
    // If the FIFO is full, a pixel completing a word must wait
    // unless a word is simultaneously removed from the FIFO.
    assign pixel_ready =
        active &&
        ((pack_count != 2'd3) ||
         (fifo_count < FIFO_DEPTH) ||
         fifo_pop);

    assign pixel_accept = pixel_valid && pixel_ready;
    assign fifo_push = pixel_accept && (pack_count == 2'd3);

    always @(posedge aclk) begin
        if (!aresetn) begin
            wr_ptr      <= 0;
            rd_ptr      <= 0;
            fifo_count  <= 0;
            active      <= 0;
            pixel_count <= 0;
            sent_words  <= 0;
            pack_reg    <= 0;
            pack_count  <= 0;
        end else begin

            // Start a new frame only when the previous frame
            // has been completely drained from the FIFO.
            if (start && !active && (fifo_count == 0)) begin
                active      <= 1'b1;
                pixel_count <= 0;
                sent_words  <= 0;
                pack_count  <= 0;
                pack_reg    <= 0;
            end

            // Receive pixels and pack four bytes per word.
            if (pixel_accept) begin
                case (pack_count)
                    2'd0: begin
                        pack_reg[7:0] <= pixel_data;
                        pack_count    <= 2'd1;
                    end

                    2'd1: begin
                        pack_reg[15:8] <= pixel_data;
                        pack_count     <= 2'd2;
                    end

                    2'd2: begin
                        pack_reg[23:16] <= pixel_data;
                        pack_count      <= 2'd3;
                    end

                    2'd3: begin
                        pack_reg[31:24] <= pixel_data;
                        pack_count      <= 2'd0;
                    end
                endcase

                if (pixel_count == FRAME_PIXELS - 1) begin
                    active      <= 1'b0;
                    pixel_count <= 0;
                    pack_count  <= 0;
                end else begin
                    pixel_count <= pixel_count + 1'b1;
                end
            end

            // Write each completed 32-bit word to the FIFO.
            if (fifo_push) begin
                fifo_mem[wr_ptr] <=
                    {pixel_data, pack_reg[23:0]};

                wr_ptr <= wr_ptr + 1'b1;
            end

            // AXI4-Stream handshake: transfer only when both
            // TVALID and TREADY are high.
            if (fifo_pop) begin
                rd_ptr <= rd_ptr + 1'b1;
     if (sent_words == FRAME_WORDS - 1)
                    sent_words <= 0;
                else
                    sent_words <= sent_words + 1'b1;
            end

            // Update FIFO occupancy, including simultaneous
            // read and write operations.
            case ({fifo_push, fifo_pop})
                2'b10: fifo_count <= fifo_count + 1'b1;
                2'b01: fifo_count <= fifo_count - 1'b1;
                default: fifo_count <= fifo_count;
            endcase
        end
    end

endmodule
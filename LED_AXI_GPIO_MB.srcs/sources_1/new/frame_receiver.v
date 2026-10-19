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
    input  wire        start,

    output reg  [31:0] m_axis_tdata,
    output reg         m_axis_tvalid,
    input  wire        m_axis_tready,
    output reg         m_axis_tlast,
    output wire [3:0]  m_axis_tkeep
);

    // 320 x 200 pixels, 4 pixels packed into each 32-bit word
    localparam FRAME_WORDS = 16000;

    reg [13:0] word_count;
    reg        active;

    assign m_axis_tkeep = 4'b1111;

    always @(posedge aclk) begin
        if (!aresetn) begin
            word_count    <= 14'd0;
            active        <= 1'b0;
            m_axis_tdata  <= 32'd0;
            m_axis_tvalid <= 1'b0;
            m_axis_tlast  <= 1'b0;
        end else begin
            if (start && !active && !m_axis_tvalid) begin
                active        <= 1'b1;
                word_count    <= 14'd0;
                m_axis_tdata  <= 32'd0;
                m_axis_tvalid <= 1'b1;
                m_axis_tlast  <= 1'b0;
            end

            if (m_axis_tvalid && m_axis_tready) begin
                if (word_count == FRAME_WORDS - 1) begin
                    m_axis_tvalid <= 1'b0;
                    m_axis_tlast  <= 1'b0;
                    active        <= 1'b0;
                    word_count    <= 14'd0;
                end else begin
                    word_count    <= word_count + 1'b1;
                    m_axis_tdata  <= word_count + 1'b1;
                    m_axis_tlast  <= (word_count == FRAME_WORDS - 2);
                end
            end
        end
    end

endmodule

`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 20.10.2026 15:16:30
// Design Name: 
// Module Name: tb_frame_receiver
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
// `timescale 1ns / 1ps

`timescale 1ns / 1ps

module tb_frame_receiver;

    localparam FRAME_PIXELS = 320 * 200;
    localparam FRAME_WORDS  = FRAME_PIXELS / 4;

    reg aclk = 0;
    reg aresetn = 0;
    reg start = 0;

    reg [7:0] pixel_data = 0;
    reg pixel_valid = 0;
    wire pixel_ready;

    wire [31:0] m_axis_tdata;
    wire m_axis_tvalid;
    reg m_axis_tready = 1;
    wire m_axis_tlast;
    wire [3:0] m_axis_tkeep;

    integer sent_pixels = 0;
    integer received_words = 0;
    integer errors = 0;
    reg [31:0] expected_word;

    always #5 aclk = ~aclk;

    frame_receiver dut (
        .aclk(aclk),
        .aresetn(aresetn),
        .start(start),
        .pixel_data(pixel_data),
        .pixel_valid(pixel_valid),
        .pixel_ready(pixel_ready),
        .m_axis_tdata(m_axis_tdata),
        .m_axis_tvalid(m_axis_tvalid),
        .m_axis_tready(m_axis_tready),
        .m_axis_tlast(m_axis_tlast),
        .m_axis_tkeep(m_axis_tkeep)
    );

    initial begin
        repeat (5) @(negedge aclk);
        aresetn = 1;

        repeat (2) @(negedge aclk);
        start = 1;
        @(negedge aclk);
        start = 0;

        while (sent_pixels < FRAME_PIXELS) begin
            @(negedge aclk);
            if (pixel_ready) begin
                pixel_valid = 1;
                pixel_data = sent_pixels % 256;
            end else begin
                pixel_valid = 0;
            end

            @(posedge aclk);
            if (pixel_valid && pixel_ready)
                sent_pixels = sent_pixels + 1;
        end

        @(negedge aclk);
        pixel_valid = 0;
    end

    always @(posedge aclk) begin
        if (aresetn && m_axis_tvalid && m_axis_tready) begin

            expected_word =
                (((received_words*4 + 3) & 255) << 24) |
                (((received_words*4 + 2) & 255) << 16) |
                (((received_words*4 + 1) & 255) << 8)  |
                ((received_words*4) & 255);

            if (m_axis_tdata !== expected_word) begin
                $display("DATA ERROR word=%0d got=%h expected=%h",
                         received_words, m_axis_tdata, expected_word);
                errors = errors + 1;
            end

            if (m_axis_tkeep !== 4'b1111) begin
                $display("TKEEP ERROR word=%0d keep=%b",
                         received_words, m_axis_tkeep);
                errors = errors + 1;
            end

            if (m_axis_tlast !== (received_words == FRAME_WORDS-1)) begin
                $display("TLAST ERROR word=%0d tlast=%b",
                         received_words, m_axis_tlast);
                errors = errors + 1;
            end

            received_words = received_words + 1;

            if (received_words == FRAME_WORDS) begin
                if (errors == 0)
                    $display("PASS: %0d pixels, %0d words, TLAST OK",
                             sent_pixels, received_words);
                else
                    $display("FAIL: %0d errors", errors);

                $finish;
            end
        end
    end

    initial begin
        #2000000;
        $display("TIMEOUT: pixels=%0d words=%0d errors=%0d",
                 sent_pixels, received_words, errors);
        $finish;
    end

endmodule
//////////////////////////////////////////////////////////////////////////////////




`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/11/2020 01:56:00 PM
// Design Name: 
// Module Name: axis_file_loader
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


module axis_file_loader #
(
    parameter filename = "data.bin",
    parameter data_width = 8,
    parameter delay_tic = 100
)
(
        input axis_aclk,
        input axis_aresetn,
        output reg m_axis_tvalid,
        input m_axis_tready,
        output reg[8*data_width-1:0] m_axis_tdata,
        output reg[data_width-1:0] m_axis_tkeep,
        output m_axis_tlast,
        input cfg_prepared
    );

    integer data_file = 0,rv,i=0;
    reg eof = 0;
    reg [7:0] buffer;
    reg [63:0] tdata_buf[0:1];
    reg [7:0] tkeep_buf[0:1];

    localparam IDLE = 0;
    localparam WAIT = 1;
    localparam OPEN_FILE = 2;
    localparam XFER = 3;
    localparam XFER_LAST = 4;

    integer state;
    always @(posedge axis_aclk) begin
        if (!axis_aresetn)
            state <= IDLE;
        else
        case (state)
            IDLE:
                state <= WAIT;
            WAIT:
            if(delay_tic == tic)
                state <= OPEN_FILE;
            OPEN_FILE:
            begin
                data_file = $fopen(filename,"rb");
                for (i = 0;i<data_width;i=i+1) begin
                    rv = $fread(buffer,data_file);
                    if(rv == 1) begin
                        tkeep_buf[0][i] = 1;
                        tdata_buf[0][8*i+7-:8] = buffer;
                    end else begin
                        tkeep_buf[0][i] = 0;
                        tdata_buf[0][8*i+7-:8] = 0;
                    end
                end
                state <= XFER;
            end
            XFER:
            begin
                for (i = 0;i<data_width;i=i+1) begin
                    rv = $fread(buffer,data_file);
                    tdata_buf[0][8*i+7-:8] = buffer;
                    if(rv == 1)
                        tkeep_buf[0][i] = 1;
                    else
                        tkeep_buf[0][i] = 0;
                end
                if($feof(data_file))
                    state <= XFER_LAST;
            end
            XFER_LAST:
            begin
                state <= IDLE;
                $fclose(data_file);
            end
            default:
                state <= IDLE;
        endcase
    end

    reg[31:0] tic;
    wire tic_enb = state == WAIT ? 1 : 0;
    wire tic_clr = state == XFER ? 1 : 0;

    always @(posedge axis_aclk) begin
        if (!axis_aresetn || tic_clr)
            tic <= 0;
        else if (tic_enb) 
            tic <= tic + 1;
    end

    // initial begin
    //     data_file = $fopen(filename,"rb");
    //     @(posedge cfg_prepared);
    //     # delay_ns;
    //     @(posedge axis_aclk);
    //     while (!$feof(data_file)) begin
    //         @(posedge axis_aclk);
    //         state = XFER;
    //         tdata_buf[0] = 0;
    //         tkeep_buf[0] = 0;
    //         for (i = 0;i < data_width;i = i+1) begin
    //             rv = $fread(buffer,data_file);
    //             tdata_buf[0][8*i+7-:8] = buffer;
    //             if(rv == 1)
    //                 tkeep_buf[0][i] = 1;
    //         end
    //     end
    //     state = XFER_LAST;
    //     @(posedge axis_aclk);
    //     state = IDLE;
    //     $fclose(data_file);
    // end

    assign m_axis_tlast = state == XFER_LAST ? 1 : 0;
    wire output_enb = state == XFER || state == XFER_LAST;
    always @(posedge axis_aclk) begin
        if (!axis_aresetn) begin
            m_axis_tdata <= 0;
            m_axis_tkeep <= 0;
        end else if (output_enb) begin
            m_axis_tdata <= tdata_buf[1];
            m_axis_tkeep <= tkeep_buf[1];
        end
    end

    always @(posedge axis_aclk) begin
        if (!axis_aresetn) begin
            tdata_buf[1] <= 0;
            tkeep_buf[1] <= 0;
            m_axis_tvalid <= 0;
        end else begin
            tdata_buf[1] <= tdata_buf[0];
            tkeep_buf[1] <= tkeep_buf[0];
            m_axis_tvalid <= state == XFER ? 1 : 0;
        end
    end

endmodule

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
    parameter data_file_name = "data.bin",
    parameter result_file_name = "result.bin",
    parameter data_width = 8
)
(
        input axis_aclk,
        input axis_aresetn,
        output m_axis_tvalid,
        input m_axis_tready,
        output [8*data_width-1:0] m_axis_tdata,
        output [data_width-1:0] m_axis_tkeep,
        output m_axis_tlast,
        input cfg_prepared
    );


    reg m_axis_tvalid_buf = 0;
    reg [8*data_width-1:0] m_axis_tdata_buf = 0;
    reg [data_width-1:0] m_axis_tkeep_buf = 0;
    reg m_axis_tlast_buf = 0;

    assign m_axis_tvalid = m_axis_tvalid_buf;
    assign m_axis_tdata = m_axis_tdata_buf;
    assign m_axis_tkeep = m_axis_tkeep_buf;
    assign m_axis_tlast = m_axis_tlast_buf;

    integer data_file = 0,result_file = 0,rv,i=0,j=0;
    reg [8*data_width-1:0] data_file_buffer = 0,result_file_buffer = 0;

    initial begin
        data_file = $fopen(data_file_name,"rb");
        if (!data_file) begin
            $display("data_file handle was NULL");
        end else begin
            $display("normal!");
        end
        @(posedge cfg_prepared);
        @(posedge axis_aclk);
        m_axis_tvalid_buf = 1;
        while (!$feof(data_file)) begin
            rv = $fread(data_file_buffer,data_file);
            //write address
            if(m_axis_tready)begin
                m_axis_tdata_buf = 0;
                m_axis_tkeep_buf = 8'h00;
                for (i = 0;i<rv;i=i+1) begin
                    m_axis_tkeep_buf[i] = 1;
                    m_axis_tdata_buf[8*i+7-:8] = data_file_buffer[8*data_width-1-8*i-:8];
                end
                if($feof(data_file))begin
                    m_axis_tlast_buf = 1;
                end else begin
                    m_axis_tlast_buf = 0;
                end
                @(posedge axis_aclk);
            end else begin
                @(posedge m_axis_tready);
            end
        end
        $fclose(data_file);
        m_axis_tvalid_buf = 0;
    end

endmodule

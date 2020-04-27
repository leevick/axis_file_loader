`timescale 1ns / 1ps

module axis_file_loader_tb();

reg clk = 0;
reg rst = 1;
wire rst_n;
reg cfg_prepared = 0;

assign rst_n = !rst;

axis_file_loader loader_inst
(
    .axis_aclk(clk),
    .axis_aresetn(rst_n),
    .m_axis_tvalid(),
    .m_axis_tready(1'b1),
    .m_axis_tdata(),
    .m_axis_tkeep(),
    .m_axis_tlast(),
    .cfg_prepared(cfg_prepared)
);

always begin
   #5 clk = !clk;
end

initial begin
    #100 rst = !rst;
    @(posedge clk);
    cfg_prepared = 1;
    @(posedge clk);
    cfg_prepared = 0;
end

endmodule // axis_file_loader_tb
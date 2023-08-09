`include "include.v"	 

module tb #(
    parameter data_widght = 8
);

reg i_clk;
reg o_clk;
reg rstn;
reg [data_widght-1:0] i_data;
reg i_valid;
wire busy;
wire o_valid;
wire [data_widght-1:0] o_data;

reg [data_widght-1:0] expected [99:0];
reg [data_widght-1:0] result [99:0];
reg [data_widght-1:0] ref_data;
integer o_count, i_count;

`ifdef sync_2phase
cdc_2phase_hs 
`else
cdc_4phase_hs
`endif 
#(.data_widght(data_widght)) dut (
    .i_clk(i_clk), 
    .o_clk(o_clk), 
    .i_rstn(rstn),
    .o_rstn(rstn),
    .i_data(i_data),
    .i_valid(i_valid),
    .busy(busy),
    .o_valid(o_valid),
    .o_data(o_data)
);

always #5 i_clk = ~i_clk;
always #13 o_clk = ~o_clk;

integer i;

task send_data();
begin
    ref_data = $random;
    @(posedge i_clk);
    i_valid <= 1;
    i_data  <= ref_data;
    @(posedge i_clk);
    i_valid <= 0;
end
endtask

initial begin
    `ifdef sync_2phase
    $dumpfile("sync_2p.vcd");
    `else
    $dumpfile("sync_4p.vcd");
    `endif 
    $dumpvars(0,tb);
    i_count = 0;
    o_count = 0;
    i_clk = 0;
    o_clk = 0;
    rstn = 1;
    #1 rstn = 0;
    #2 rstn = 1;
    for (i = 0; i < 100; i = i+1) begin
        send_data();
    end
    $stop;
end

always @(posedge i_clk) begin
    if(~busy & i_valid) begin
        expected[i_count] <= i_data;
        i_count = i_count + 1;
    end
end

always @(posedge o_valid) begin
    #1 result[o_count] = o_data;
    #1 if(result[o_count] != expected[o_count]) begin
        $display("expected = %d     result = %d failed at time %t",expected[o_count], result[o_count], $time);
    end 
    else begin
        $display("expected = %d     result = %d",expected[o_count], result[o_count]);
    end

    #1 o_count = o_count + 1;
end

endmodule
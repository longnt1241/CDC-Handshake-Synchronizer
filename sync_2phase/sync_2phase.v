module cdc_2phase_hs #(
    parameter data_widght = 8
) (
    input i_clk,
    input o_clk,
    input i_rstn,
    input o_rstn,
    input [data_widght-1:0] i_data,
    input i_valid,
    output wire busy,
    output reg o_valid,
    output reg [data_widght-1:0] o_data
);
localparam idle = 1'b0, s_wait = 1'b1;

reg ack, ackSync0, ackSync1;
reg req, reqSync0, reqSync1;
reg state, next_state;
reg [data_widght-1:0] data_sync;

assign busy = state;

//REQ FSM
always @(posedge i_clk or negedge i_rstn) begin
    if(~i_rstn) begin
        state <= idle;
        ackSync0 <= 0;
        ackSync1 <= 0;
        req <= 0;
    end
    else begin
        state <= next_state;
        ackSync0 <= ack;
        ackSync1 <= ackSync0;
    end
end

always @(posedge i_clk) begin
    if(~busy & i_valid) begin
        data_sync <= i_data;
        req <= ~req;
    end
end

always @* begin
    next_state = state;
    case (state)
        idle: begin
            if(i_valid) begin
                next_state = s_wait;
            end
        end 
        s_wait: begin
            if(~(ackSync1 ^ req)) begin
                next_state = idle;
            end
        end
        default: next_state = idle;
    endcase
end

//ACK logic
always @(posedge o_clk or negedge o_rstn) begin
    if(~o_rstn) begin
        reqSync0 <= 0;
        reqSync1 <= 0;
    end
    else begin
        reqSync0 <= req;
        reqSync1 <= reqSync0;
    end
end

always @(posedge o_clk or negedge o_rstn) begin
    if(~o_rstn) begin
        ack <= 0;
        o_valid <= 0;
    end
    else if(reqSync1 ^ ack) begin
        ack <= ~ack;
        o_data <= data_sync;
        o_valid <= 1;
    end
    else begin
        o_valid <= 0;
    end
end

endmodule
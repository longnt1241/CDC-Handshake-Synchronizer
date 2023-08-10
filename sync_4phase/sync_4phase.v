module cdc_4phase_hs #(
    parameter data_widght = 8
) (
    input i_clk,
    input o_clk,
    input i_rstn,
    input o_rstn,
    input [data_widght-1:0] i_data,
    input i_valid,
    output reg busy,
    output reg o_valid,
    output reg [data_widght-1:0] o_data
);
localparam idle = 2'b00, s_wait0 = 2'b01, s_wait1 = 2'b11;

reg req, reqSync0, reqSync1;
reg [1:0] state_req, next_state_req;
reg [data_widght-1:0] data_sync;

always @(posedge i_clk or negedge i_rstn) begin
    if (~i_rstn) begin
        state_req <= idle;
        ackSync0 <= 0;
        ackSync1 <= 0;
    end
    else begin
        ackSync0 <= ack;
        ackSync1 <= ackSync0;
        state_req <= next_state_req;
    end
end

//REQ FSM
always @(posedge i_clk) begin
    if(~busy & i_valid) begin
        data_sync <= i_data;
    end
end

always @* begin
    next_state_req = state_req;
    busy = 1;
    case (state_req)
        idle: begin
            busy = 0;
            req = 0;
            if(i_valid) begin
                next_state_req = s_wait0;
            end
        end 
        s_wait0: begin
            req = 1;
            if(ackSync1) begin
                next_state_req = s_wait1;
            end
        end
        s_wait1: begin
            req = 0;
            if(~ackSync1) begin
                next_state_req = idle;
            end
        end
        default: next_state_req = idle;
    endcase
end

//ACK FSM
localparam idle_a = 1'b0, s_wait_a = 1'b1;
reg ack, ackSync0, ackSync1;
reg state_ack, next_state_ack;

always @(posedge o_clk or negedge o_rstn) begin
    if(~o_rstn) begin
        reqSync0 <= 0;
        reqSync1 <= 0;
        state_ack <= idle_a;
        o_valid <= 0;
    end
    else begin
        reqSync0 <= req;
        reqSync1 <= reqSync0;
        state_ack <= next_state_ack;
    end

    if(reqSync1) begin
        o_data <= data_sync;
    end

    if(state_ack == idle_a & next_state_ack == s_wait_a) begin
        o_valid <= 1;
    end
    else begin
        o_valid <= 0;
    end
end

always @* begin
    next_state_ack = state_ack;
    case (state_ack)
        idle_a: begin
            ack = 0;
            if(reqSync1) begin
                next_state_ack = s_wait_a;
            end
        end 
        s_wait_a: begin
            ack = 1;
            if (~reqSync1) begin
                next_state_ack = idle_a;
            end
        end
        default: next_state_ack = idle_a;
    endcase
end
endmodule
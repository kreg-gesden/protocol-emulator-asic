/*
 * Copyright (c) 2026 Kreg Gesden
 * SPDX-License-Identifier: Apache-2.0
*/

`default_nettype none

typedef enum logic [1:0] {
    IDLE = 2'b00,
    START = 2'b01,
    DATA = 2'b10,
    STOP = 2'b11
} State;

module ShiftRegister (
    input  logic       clk,
    input  logic       rst_l,
    input  logic       en,
    input  logic       sh_en,
    input  logic [7:0] d_in,
    output logic [7:0] d_out
);

    logic [7:0] d_shifted;

    assign d_shifted = d_out >> 1;

    always_ff @(posedge clk or negedge rst_l) begin
        if (!rst_l) begin
            d_out <= 8'd0;
        end
        else if (en) begin
            if (sh_en) begin
                d_out <= d_shifted;
            end
            else begin
                d_out <= d_in;
            end
        end
    end

endmodule

module Countdown (
    input  logic clk,
    input  logic rst_l,
    input  logic en,
    input  logic clr,
    output logic done
);

    logic [7:0] count;

    assign done = count == 8'd8;

    always_ff @(posedge clk or negedge rst_l) begin
        if (!rst_l || clr) begin
            count <= 8'd0;
        end
        else if (en) begin
            count <= count + 8'd1;
        end
    end

endmodule

module design (
    input  logic       clk,
    input  logic       rst_l,
    input  logic [7:0] d_in,
    input  logic       valid,
    output logic       ready,
    output logic       d_out
);

    logic done;
    logic [7:0] shift_out;

    logic sr_en, sr_sh_en;
    logic cd_en, cd_clr;

    ShiftRegister shiftregister (.clk, .rst_l, .en(sr_en), .sh_en(sr_sh_en),
        .d_in(), .d_out(shift_out));
    Countdown countdown (.clk, .rst_l, .en(cd_en), .clr(cd_clr), .done);

    State state, next_state;
    
    always_ff @(posedge clk or negedge rst_l) begin
        if (!rst_l) begin
            state <= IDLE;
        end
        else begin
            state <= next_state;
        end
    end

    // next state
    always_comb begin
        case (state)
            IDLE: next_state = (valid) ? START : IDLE;
            START: next_state = DATA;
            DATA: next_state = (done) ? STOP : DATA;
            STOP: next_state = IDLE;
            default: next_state = 2'bxx;
        endcase
    end

    // outputs
    always_comb begin
        case (state)
            IDLE: begin
                d_out = 1'b1;
                ready = 1'b1;
                sr_en = 1'b0;
                sr_sh_en = 1'b0;
                cd_en = 1'b0;
                cd_clr = 1'b0;
            end
            START: begin
                d_out = 1'b0;
                ready = 1'b0;
                sr_en = 1'b1;
                sr_sh_en = 1'b1;
                cd_en = 1'b1;
                cd_clr = 1'b0;
            end
            DATA: begin
                d_out = shift_out[0];
                ready = 1'b0;
                sr_en = 1'b1;
                sr_sh_en = 1'b1;
                cd_en = 1'b1;
                cd_clr = 1'b0;
            end
            STOP: begin
                d_out = 1'b1;
                ready = 1'b0;
                sr_en = 1'b0;
                sr_sh_en = 1'b0;
                cd_en = 1'b0;
                cd_clr = 1'b1;
            end
            default: begin
                d_out = 1'bx;
                ready = 1'bx;
                sr_en = 1'bx;
                sr_sh_en = 1'bx;
            end
        endcase
    end
endmodule

module top (
    input  wire [7:0] ui_in,    // Data
    output wire [7:0] uo_out,   // uo_out[0] is TX
    input  wire [7:0] uio_in,   // uio_in[0] is ready 
    output wire [7:0] uio_out,  // uio_out[1] is valid
    output wire [7:0] uio_oe,   // uio_oe[0] = 0, uio_oe[1] = 1
    input  wire       ena,      // always 1 when the design is powered, so you can ignore it
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);


endmodule

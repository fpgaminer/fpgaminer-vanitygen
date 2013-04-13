/*
*
* Copyright (c) 2013 fpgaminer@bitcoin-mining.com
*
*
*
* This program is free software: you can redistribute it and/or modify
* it under the terms of the GNU General Public License as published by
* the Free Software Foundation, either version 3 of the License, or
* (at your option) any later version.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
* GNU General Public License for more details.
*
* You should have received a copy of the GNU General Public License
* along with this program.  If not, see <http://www.gnu.org/licenses/>.
* 
*/

module ff_mul (
	input clk,
	input reset,
	input [255:0] rx_a,
	input [255:0] rx_b,
	output tx_done,
	output [255:0] tx_c
);

	wire mul_done;
	wire [511:0] mul_result;

	bn_mul uut (
		.clk (clk),
		.reset (reset),
		.rx_a (rx_a),
		.rx_b (rx_b),
		.tx_done (mul_done),
		.tx_r (mul_result)
	);

	reg reduce_reset = 1'b1;

	ff_reduce_secp256k1 uut2 (
		.clk (clk),
		.reset (reset | reduce_reset),
		.rx_a (mul_result),
		.tx_done (tx_done),
		.tx_a (tx_c)
	);


	always @ (posedge clk)
	begin
		if (reset)
			reduce_reset <= 1'b1;
		else if (mul_done)
			reduce_reset <= 1'b0;
	end

endmodule


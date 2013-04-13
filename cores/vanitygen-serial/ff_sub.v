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

module ff_sub (
	input clk,
	input reset,
	input [255:0] rx_a,
	input [255:0] rx_b,
	input [255:0] rx_p,
	output reg tx_done = 1'b0,
	output reg [255:0] tx_a = 256'd0
);

	reg carry;

	always @ (posedge clk)
	begin
		if (!tx_done)
		begin
			if (carry)
				tx_a <= tx_a + rx_p;
			tx_done <= 1'b1;
		end

		if (reset)
		begin
			{carry, tx_a} <= rx_a - rx_b;
			tx_done <= 1'b0;
		end
	end

endmodule

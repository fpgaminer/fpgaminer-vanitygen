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

// Find a^-1 mod p, using Euclidean Inversion.
// TODO: We can save power by halting calculations when done goes high.
// TODO: We can save more power by disabling other calculations when not needed
// (like x_adder).
module ff_inv (
	input clk,
	input reset,
	input [255:0] rx_a,
	input [255:0] rx_p,

	output reg tx_done,
	output reg [255:0] tx_a
);

	reg [255:0] u, v, x, y;
	reg x_carry, y_carry;

	wire u_even = u[0] == 1'b0;
	wire v_even = v[0] == 1'b0;
	wire [256:0] u_minus_v = {1'b0, u} - {1'b0, v};
	wire [256:0] v_minus_u = {1'b0, v} - {1'b0, u};
	reg [256:0] x_adder, y_adder;


	always @ (*)
	begin
		if (x_carry || y_carry)
		begin
			x_adder = x + rx_p;
			y_adder = y + rx_p;
		end
		else if (u_even || v_even)
		begin
			x_adder = x + rx_p;
			y_adder = y + rx_p;
		end
		else
		begin
			x_adder = x - y;
			y_adder = y - x;
		end
	end


	always @ (posedge clk)
	begin
		// We are finished if u or v are equal to 1.
		// Latch result.
		if (u == 256'd1 && !tx_done)
		begin
			tx_done <= 1'b1;
			tx_a <= x;
		end
		else if (v == 256'd1 && !tx_done)
		begin
			tx_done <= 1'b1;
			tx_a <= y;
		end

		if (x_carry || y_carry)
		begin
			x <= x_carry ? x_adder[255:0] : x;
			y <= y_carry ? y_adder[255:0] : y;
			x_carry <= 1'b0;
			y_carry <= 1'b0;
		end
		else if (u_even || v_even)
		begin
			if (u_even)
			begin
				u <= u >> 1;
				if (x[0] == 1'b0)
					x <= x >> 1;
				else
					x <= x_adder[256:1];
			end

			if (v_even)
			begin
				v <= v >> 1;
				if (y[0] == 1'b0)
					y <= y >> 1;
				else
					y <= y_adder[256:1];
			end
		end
		else
		begin
			if (u_minus_v[256] == 1'b0)	// if u >= v
			begin
				u <= u_minus_v;
				x <= x_adder[255:0];
				x_carry <= x_adder[256];
			end
			else
			begin
				v <= v_minus_u;
				y <= y_adder[255:0];
				y_carry <= y_adder[256];
			end
		end

		// Restart calculations with new inputs
		if (reset)
		begin
			u <= rx_a;
			v <= rx_p;
			x <= 256'd1;
			y <= 256'd0;
			x_carry <= 1'b0;
			y_carry <= 1'b0;
			tx_done <= 1'b0;
		end
	end

endmodule

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

module ff_reduce_secp256k1 (
	input clk,
	input reset,
	input [511:0] rx_a,
	output reg tx_done,
	output reg [255:0] tx_a
);

	reg [3:0] cnt;
	reg [259:0] s;
	reg [32:0] s1;
	reg [64:0] k;
	wire [34:0] k11 = {s1, 2'd0} + {s1, 1'd0} + s1;
	wire [255:0] c1 = rx_a[511:256];
	reg [255:0] other;
	wire [260:0] s_minus_p = s - 256'hFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFC2F;


	always @ (*)
	begin
		if (cnt == 0)
			other <= {c1[223:0], 32'd0};
		else if (cnt == 1)
			other <= {c1[246:0], 9'd0};
		else if (cnt == 2)
			other <= {c1[247:0], 8'd0};
		else if (cnt == 3)
			other <= {c1[248:0], 7'd0};
		else if (cnt == 4)
			other <= {c1[249:0], 6'd0};
		else if (cnt == 5)
			other <= {c1[251:0], 4'd0};
		else if (cnt == 6)
			other <= c1;
		else if (cnt == 7)
			other <= k;
		else
			other <= k;
	end

	always @ (posedge clk)
	begin
		cnt <= cnt + 1;
		s <= s + other;

		if (cnt == 8)
		begin
			cnt <= cnt;
			s <= s_minus_p;

			if (s_minus_p[260] && !tx_done)
			begin
				tx_done <= 1'b1;
				tx_a <= s[255:0];
			end
		end

		s1 <= c1[255:252] + c1[255:250] + c1[255:249] + c1[255:248] + c1[255:247] + c1[255:224];
		k <= {s1, 32'd0} + {k11, 7'd0} + {s1, 6'd0} + {s1, 4'd0} + s1;

		if (reset)
		begin
			cnt <= 0;
			tx_done <= 1'b0;

			s <= rx_a[255:0];
		end
	end

endmodule

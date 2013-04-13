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

/* Calculates the hash of the given public key.
* Will use the compressed public key.
*/
module address_hash (
	input clk,
	input rx_reset,
	input [255:0] rx_x,
	input [255:0] rx_y,
	output tx_done,
	output [159:0] tx_hash
);
	
	reg ripe_reset = 1'b1;
	wire sha_done;
	wire [255:0] sha_hash;

	sha256 sha256_blk (
		.clk (clk),
		.rx_reset (rx_reset),
		.rx_public_key ({7'h1, rx_y[0], rx_x}),
		.tx_done (sha_done),
		.tx_hash (sha_hash)
	);

	ripemd160 ripemd160_blk (
		.clk (clk),
		.rx_reset (rx_reset | ripe_reset),
		.rx_hash (sha_hash),
		.tx_done (tx_done),
		.tx_hash (tx_hash)
	);

	always @ (posedge clk)
	begin
		if (rx_reset)
			ripe_reset <= 1'b1;
		else if (sha_done)
			ripe_reset <= 1'b0;
	end

endmodule

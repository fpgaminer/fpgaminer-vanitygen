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

/* 
* This top level module implements Bitcoin vanity address generation.
*/
module fpgaminer_vanitygen_top (
	input clk
);

	//*****************************************************************************
	// Clock Generation
	//*****************************************************************************
	wire mining_clk;

	clk_pll clk_pll_blk (
		.rx_clk (clk),
		.tx_mining_clk (mining_clk)
	);


	//*****************************************************************************
	// External Input
	//*****************************************************************************
	wire reset;
	wire [255:0] a, b;
	wire [159:0] vanity_min, vanity_max;

	virtual_wire # (.OUTPUT_WIDTH (256), .INSTANCE_ID ("A")) a_vw (.clk (mining_clk), .rx_input (), .tx_output (a));
	virtual_wire # (.OUTPUT_WIDTH (256), .INSTANCE_ID ("B")) b_vw (.clk (mining_clk), .rx_input (), .tx_output (b));
	virtual_wire # (.OUTPUT_WIDTH (160), .INSTANCE_ID ("MIN")) min_vw (.clk (mining_clk), .rx_input (), .tx_output (vanity_min));
	virtual_wire # (.OUTPUT_WIDTH (160), .INSTANCE_ID ("MAX")) max_vw (.clk (mining_clk), .rx_input (), .tx_output (vanity_max));
	virtual_wire # (.OUTPUT_WIDTH (1), .INSTANCE_ID ("RST")) reset_vw (.clk (mining_clk), .rx_input (), .tx_output (reset));


	//*****************************************************************************
	// Public Key Adder
	//*****************************************************************************
	reg adder_reset;
	reg [255:0] x, y;
	reg [63:0] cnt;
	wire adder_done;
	wire [255:0] adder_x, adder_y;


	public_key_adder adder_blk (
		.clk (mining_clk),
		.reset (adder_reset),
		.rx_x (x),
		.rx_y (y),
		.tx_done (adder_done),
		.tx_x (adder_x),
		.tx_y (adder_y)
	);


	//*****************************************************************************
	// Hasher
	//*****************************************************************************
	wire hash_done;
	wire [159:0] hash_hash;

	address_hash hash_blk (
		.clk (mining_clk),
		.rx_reset (adder_done),
		.rx_x (adder_x),
		.rx_y (adder_y),
		.tx_done (hash_done),
		.tx_hash (hash_hash)
	);


	//*****************************************************************************
	// Compare
	//*****************************************************************************
	wire vanity_match;
	reg old_vanity_match = 1'b0;
	reg [63:0] vanity_matched_cnt = 64'd0;

	vanity_compare vanity_compare_blk (
		.clk (mining_clk),
		.rx_reset (hash_done),
		.rx_min (vanity_min),
		.rx_max (vanity_max),
		.rx_hash (hash_hash),
		.tx_match (vanity_match)
	);


	//*****************************************************************************
	// External Output
	//*****************************************************************************
	virtual_wire # (.INPUT_WIDTH (1), .INSTANCE_ID ("DONE")) done_vw (.clk (mining_clk), .rx_input (adder_done), .tx_output ());
	virtual_wire # (.INPUT_WIDTH (256), .INSTANCE_ID ("TXX")) adder_x_vw (.clk (mining_clk), .rx_input (adder_x), .tx_output ());
	virtual_wire # (.INPUT_WIDTH (256), .INSTANCE_ID ("TXY")) adder_y_vw (.clk (mining_clk), .rx_input (adder_y), .tx_output ());
	virtual_wire # (.INPUT_WIDTH (1), .INSTANCE_ID ("HDNE")) hash_done_vw (.clk (mining_clk), .rx_input (hash_done), .tx_output ());
	virtual_wire # (.INPUT_WIDTH (160), .INSTANCE_ID ("HASH")) hash_vw (.clk (mining_clk), .rx_input (hash_hash), .tx_output ());
	virtual_wire # (.INPUT_WIDTH (64), .INSTANCE_ID ("MTCH")) matched_vw (.clk (mining_clk), .rx_input (vanity_matched_cnt), .tx_output ());


	always @ (posedge mining_clk)
	begin
		old_vanity_match <= vanity_match;
		adder_reset <= 1'b0;

		if (adder_done && !adder_reset)
		begin
			cnt <= cnt + 64'd1;
			adder_reset <= 1'b1;
			x <= adder_x;
			y <= adder_y;
		end

		if (~old_vanity_match && vanity_match)
		begin
			vanity_matched_cnt <= cnt;
		end

		if (reset)
		begin
			cnt <= 64'd0;
			x <= a;
			y <= b;
			adder_reset <= 1'b1;
		end
	end

endmodule

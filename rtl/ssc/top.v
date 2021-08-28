`timescale 1 ns / 1 ps
`default_nettype none

module top(
	// bus interface
	input clk_16m,

	input [11:0] addr_in,
	inout [7:0] data,

	input fclk,
	input q3,

	input rw,
	input _iostrobe,
	input _iosel,
	input _devsel,
	input _reset,

	input btn,
	output _en245,

	inout _nmi,
	inout _irq,
	inout _inh,
	inout _rdy
);

	SB_WARMBOOT warmboot_inst (
		.S1(1'b0),
		.S0(1'b0),
		.BOOT(~btn)
	);

	assign _nmi = 1'bz;
	assign _irq = 1'bz;
	assign _inh = 1'bz;
	assign _rdy = 1'bz;

	wire rom_out = 1'b1;

	wire [7:0] data_in;
	wire [7:0] data_out;
	SB_IO #(
		.PIN_TYPE(6'b 1010_01)
	) sram_data_pins [7:0] (
		.PACKAGE_PIN(data),
		.OUTPUT_ENABLE(rom_out),
		.D_OUT_0(data_out),
		.D_IN_0(data_in)
	);

endmodule
// vim: ts=2 sw=2 sts=2 sr noet

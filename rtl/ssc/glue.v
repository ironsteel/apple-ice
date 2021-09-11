`default_nettype none

module glue(
	input clock,
	input reset_n,
	input [11:00] addr,
	input rw,
	input devsel_n,
	input iosel_n,
	input io_strobe_n,
	input a3,
	input a8,
	input a9,
	input a10,
	input a11,

  output latch_ce_n,
	output roma8,
	output roma9,
	output roma10,
	output romen_n,
	output phi2,
	output d0,
	output c8
);

assign phi2 = ~devsel_n;

reg c8en = 1'b0;

//wire c8en = c8en & ~a8 & ~a9 & ~a10 & ~a11 & io_strobe_n & reset_n | ~iosel_n;
//
wire histrobe = ~io_strobe_n & (addr == 12'hfff);

always @(posedge clock) begin
	c8en <= ~a8 & ~a9 & ~a10 & ~a11 & io_strobe_n & reset_n | ~iosel_n;
end

assign c8 = c8en;

//assign romen_n = ~(c8en & ~io_strobe_n & rw | ~iosel_n & rw);

assign roma8 = a8 | ~a11;
assign roma9 = a9 | ~a11;
assign roma10 = a10 | ~a11;

reg romExpansionActive;
always @(posedge clock) begin
	if (histrobe)
		romExpansionActive <= 0;
	else 
		romExpansionActive <= 1;
end

assign romen_n = ~(~iosel_n || (romExpansionActive && ~io_strobe_n));



assign d0 = rw & ~devsel_n * ~a3;

assign latch_ce_n = ~devsel_n | ~iosel_n | ~io_strobe_n;
endmodule
// vim: ts=2 sw=2 sts=2 sr noet

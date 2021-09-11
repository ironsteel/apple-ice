`default_nettype none
module codeROM (
	input wire [10:0] addr,
	input wire clk,
	input wire reset,
	output reg [7:0] dout
);

reg [7:0] rom_data[0:2047];

initial $readmemh("rom/ssc.mem", rom_data);

always @(posedge clk) begin
	if (reset)
		dout <= 8'b0;
	else
		dout <= rom_data[addr];
end

endmodule
// vim: ts=2 sw=2 sts=2 sr noet

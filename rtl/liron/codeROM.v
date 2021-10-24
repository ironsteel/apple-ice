`timescale 1 ns / 1 ps
module codeROM (
	input wire [11:0] Address,
	input wire clk,
	input wire Reset,
	output reg [7:0] Q
);


reg [7:0] rom_data[0:4095];

initial $readmemh("rom-full-4k.mem", rom_data);

always @(posedge clk) begin
	if (Reset)
		Q <= 8'b0;
	else
		Q <= rom_data[Address];
end

endmodule

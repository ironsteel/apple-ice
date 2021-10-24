module addrDecoder(
	 input [11:0] addr,
	 //input _devsel, // 16 bytes (for IWM)
	 input fclk,
	 input _iostrobe, // shared 2K space
	 input _iosel, // card-specific 256 bytes
	 input _reset,
	 output _romoe, // 0 if the card's ROM should drive its output right now
	 output reg romExpansionActive // 1 if the Yellowstone card's ROM is the currently selected slot ROM
    );

	wire histrobe = ~_iostrobe & (addr == 12'hFFF);

	always @(posedge fclk) begin
		if (histrobe)
			romExpansionActive <= 0;
		else
			romExpansionActive <= 1;
	end

	assign _romoe = ~(~_iosel || (romExpansionActive && ~_iostrobe));

endmodule

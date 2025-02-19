module downloader (	

	// new SPI interface
    //input SPI_DO,
    //input SPI_DI,
    //input SPI_SCK,
    //input SPI_SS2,
    //input SPI_SS3,
    //input SPI_SS4,
	
	input ioctl_download,  // signal indicating an active rom download
	input wire [7:0]  ioctl_index,     // 0=rom download, 1=prg dowload
    input wire [24:0] ioctl_addr,
    input wire [7:0]  ioctl_dout,
	input ioctl_wr,

	input 			  clk,
	input             clk_ena,
	output reg        wr,
	output reg [24:0] addr,
	output reg [7:0]  data,

	output reg        downloading,   // signal indicating an active download
	output            ROM_done       // indicates the ROM has already been loaded at boot up	
);

wire        dio_dowloading;
wire [7:0]  dio_index;      
wire        dio_wr;
wire [24:0] dio_addr;
wire [7:0]  dio_data;

assign dio_dowloading = ioctl_download;
assign dio_index = ioctl_index;      
assign dio_wr = ioctl_wr;
assign dio_addr = ioctl_addr;
assign dio_data = ioctl_dout;

/*
data_io data_io (
	.clk_sys ( clk      ),
	.clkref_n( ~clk_ena ),  // keep this to zero
	
	// io controller spi interface
	.SPI_SCK( SPI_SCK ),
	.SPI_SS2( SPI_SS2 ),
	.SPI_SS4( SPI_SS4 ),
	.SPI_DI ( SPI_DI  ),
	.SPI_DO ( SPI_DO  ), 	  
	
	.ioctl_download ( dio_dowloading ),  // signal indicating an active rom download
	.ioctl_index    ( dio_index      ),  // 0=rom download, 1=prg dowload
    .ioctl_addr     ( dio_addr       ),
    .ioctl_dout     ( dio_data       ),
	.ioctl_wr       ( dio_wr         )
);
*/

assign ROM_done = ROM_loaded;

reg ROM_loaded = 0;

reg dio_dowloading_old = 0;
reg [2:0] state = 0;   

// state = 0  paused or downloading data
// state = 1  writing low byte pointer
// state = 2  writing high byte pointer
// state = 3  end

wire [5:0] menu_index = dio_index[5:0];
wire [1:0] extension_index = dio_index[7:6];

wire is_rom_download = dio_index == BOOT_INDEX || dio_index == ROM_INDEX;
wire is_prg_download = dio_index == PRG_INDEX;

parameter BOOT_INDEX = 0;
parameter PRG_INDEX  = 2;
parameter ROM_INDEX  = 3;


parameter ROM_START_ADDR;   // start of ROM 
parameter PRG_START_ADDR;   // start of BASIC program in free RAM
parameter PTR_PROGND;       // PROGND: pointer to end of basic program

wire [24:0] PRG_END_ADDR     = PRG_START_ADDR + dio_addr; // TODO substitute with file lenght
wire [24:0] PTR_PROGND_VALUE = PRG_END_ADDR + 1;          // points to the byte after the BASIC program


always @(posedge clk) begin	
	
	// detect change in dio_dowloading
	dio_dowloading_old <= dio_dowloading;	
		
	if(dio_dowloading == 1) begin
	   // main downloading, save into ROM (*.rom) or RAM (*.prg)
		downloading <= 1;
		wr          <= ioctl_wr;
		data        <= ioctl_dout;
		state       <= 0;
		
		if(is_rom_download) begin
			addr <= ROM_START_ADDR + ioctl_addr;
		//	$display("ROM Download: ioctl_addr=%h addr=%h data=%h time=%t", 
		//		ioctl_addr, ROM_START_ADDR + ioctl_addr, ioctl_dout, $time);
		end
		else if(is_prg_download) begin
			addr <= PRG_START_ADDR + ioctl_addr;
		end
		//$display("downloading");		
	end
	else if(dio_dowloading_old == 1 && dio_dowloading == 0) begin
		// main download done		
		if(is_prg_download) state <= 1;  // continue writing PTR_PROGND pointer
		else                state <= 3;  // no further steps for ROM 
		
		wr <= 0; // don't write anthing in this clock cycle			
		$display("download done");
	end 
	else if(dio_dowloading == 0 && dio_dowloading_old == 0) begin
		if(state == 1) begin
			// write low byte 			
			wr    <= 1;
			addr  <= PTR_PROGND;
			data  <= PTR_PROGND_VALUE[ 7:0];
			state <= 2;		
			$display("writing low byte");	
		end
		if(state == 2) begin
			// write hi byte			
			wr    <= 1;
			addr  <= PTR_PROGND+1;
			data  <= PTR_PROGND_VALUE[15:8];
			state <= 3;			
			$display("writing hi byte");
		end
		if(state == 3) begin
			// turn off writing so that ram reloads cpu values while cpu is still waiting
			wr    <= 0;			
			state <= 4;
			if(is_rom_download) ROM_loaded <= 1;
			//$display("state 3");
		end		
		if(state == 4) begin
			// one extra cpu cycle to allow ram to settle to cpu values while cpu is still waiting
			state <= 5;			
			//$display("state 4");
		end		
		if(state == 5) begin
			// turn off dowload
			downloading <= 0;			
			state       <= 0;		
			//$display("state 5");	
		end		
	end	
end

endmodule


`define Wait 3'b000
`define Clear 3'b001
`define GetA 3'b010
`define GetB 3'b011
`define Step1 3'b010
`define Step2 3'b011
`define Step3 3'b110
`define Step4 3'b111

module fun(clk,reset,s,in,op,out,done);
	input clk,reset,s;
	input [7:0] in;
	input [1:0] op;
	output [15:0] out;
	output done;

	reg[15:0] out;
	reg done;

	reg loada,Asel;
	reg[15:0] A;
	wire[15:0] Ashift = {A[15:1],1'b0};
	wire[15:0] Ain = {8'b0,in};
	
	
	reg loadb,Bsel;
	reg[8:0] B;
	wire[8:0] Bshift = {1'b0,B[15:1]};
	wire[8:0] Bin = in;

	
	reg[1:0] outsel;
	reg loadout;
	reg[15:0]next_out;

	reg[2:0] next_state;
	wire[2:0] next_state_reset = reset ? `Wait : next_state;
	reg[2:0] present_state;

	always@(posedge clk)begin
		if(loada)A = Asel ? Ashift : Ain;
		if(loadb)B = Bsel ? Bshift : Bin;
		if(loadout) out = next_out;
	end
	
	always@(*)begin
		case(outsel)
		2'b01: next_out = A+out;
		2'b10: next_out = 16'b0;
		2'b11: next_out = out;
		default: next_out = 16'bx;
		endcase
	end

	//fsm
	always@(posedge clk)
		present_state = next_state_reset; 
	always@(*)begin
		casex({present_state,s,op,B[0]})
		{`Wait,1'b0,2'bxx,1'bx}: {next_state,Asel,Bsel,loada,loadb,loadout,outsel,done} = {`Wait,7'b0,1'b1};
		{`Wait,1'b1,2'b00,1'bx}: {next_state,Asel,Bsel,loada,loadb,loadout,outsel,done} = {`Clear,7'b0,1'b1};
		{`Wait,1'b1,2'b01,1'bx}: {next_state,Asel,Bsel,loada,loadb,loadout,outsel,done} = {`GetA,7'b0,1'b1};
		{`Wait,1'b1,2'b10,1'bx}: {next_state,Asel,Bsel,loada,loadb,loadout,outsel,done} = {`GetB,7'b0,1'b1};
		{`Wait,1'b1,2'b11,1'b1}: {next_state,Asel,Bsel,loada,loadb,loadout,outsel,done} = {`GetA,7'b0,1'b1};
		{`Wait,1'b1,2'b11,1'b0}: {next_state,Asel,Bsel,loada,loadb,loadout,outsel,done} = {`Step2,7'b0,1'b1};
		
		{`Clear,1'bx,2'bxx,1'bx}: {next_state,Asel,Bsel,loada,loadb,loadout,outsel,done} = {`Wait,4'b0,1'b1,2'b10,1'b0};

		{`GetA,1'bx,2'b11,1'b1}: {next_state,Asel,Bsel,loada,loadb,loadout,outsel,done} = {`Step1,1'b0,1'b0,1'b1,1'b0,1'b0,2'b00,1'b0};
		{`GetA,1'bx,2'bxx,1'bx}: {next_state,Asel,Bsel,loada,loadb,loadout,outsel,done} = {`Wait,1'b0,1'b0,1'b1,1'b0,1'b0,2'b00,1'b0};

		{`GetB,1'bx,2'bxx,1'bx}: {next_state,Asel,Bsel,loada,loadb,loadout,outsel,done} = {`Wait,1'b0,1'b0,1'b0,1'b1,1'b0,2'b00,1'b0};
		
		{`Step1,1'bx,2'bxx,1'bx}: {next_state,Asel,Bsel,loada,loadb,loadout,outsel,done} = {`Step3,1'b0,1'b0,1'b0,1'b0,1'b1,2'b01,1'b0};

		{`Step2,1'bx,2'bxx,1'bx}: {next_state,Asel,Bsel,loada,loadb,loadout,outsel,done} = {`Step3,1'b0,1'b0,1'b0,1'b0,1'b0,2'b11,1'b0};
		
		{`Step3,1'bx,2'bxx,1'bx}: {next_state,Asel,Bsel,loada,loadb,loadout,outsel,done} = {`Step4,1'b1,1'b0,1'b1,1'b0,1'b0,2'b00,1'b0};
		
		{`Step4,1'bx,2'bxx,1'bx}: {next_state,Asel,Bsel,loada,loadb,loadout,outsel,done} = {`Wait,1'b0,1'b1,1'b0,1'b1,1'b0,2'b00,1'b0};

		default: {next_state,Asel,Bsel,loada,loadb,loadout,outsel,done} = {11'bx};
		endcase
	end
endmodule

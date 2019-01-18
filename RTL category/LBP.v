
`timescale 1ns/10ps
module LBP ( clk, reset, gray_addr, gray_req, gray_ready, gray_data, lbp_addr, lbp_valid, lbp_data, finish);
input   	clk;
input   	reset;
output  [13:0] 	gray_addr;
output         	gray_req;
input   	gray_ready;
input   [7:0] 	gray_data;
output  [13:0] 	lbp_addr;
output  	lbp_valid;
output  [9:2] 	lbp_data;
output  	finish;
//====================================================================
reg [13:0] 	gray_addr ;
wire         gray_req ;
wire         lbp_valid ;
wire [13:0]  point ;
reg  [9:2] 	lbp_data;
reg  [13:0] 	lbp_addr;
wire         finish ;

///////////////////////
///Define somethings///
///////////////////////
reg [1:0] state_Next ;
reg [1:0] state_Now ; 

reg [3:0] counter ;
//wire [13:0] point1 , point0 , point2 , point3 , point4 , point5 , point6 , point7 ;
reg [7:0] threshold ;
//reg [9:2] temp_lbp ;
reg [6:0] x , y ;
wire[6:0] a,b,c,d;

wire pix_lbp ;

///////////////////////
//////Parameter////////
///////////////////////
parameter READ = 2'b00 ;
parameter OUT  = 2'b01 ;
parameter FIN = 2'b11 ;

///////////////////////
////////Design/////////
///////////////////////

assign point = {y,x} ;

assign a = x-7'd1 ;
assign b = x+7'd1 ;
assign c = y-7'd1 ;
assign d = y+7'd1 ;

//assign point0 = point - 14'd129 ;
//assign point0 = {c,a} ;
//assign point1 = point - 14'd128 ;
//assign point1 = {c,x} ;
//assign point2 = point - 14'd127 ;
//assign point2 = {c,b} ;
//assign point3 = point - 14'd1 ;
//assign point3 = {y,a} ;
//assign point7 = point + 14'd129 ;
//assign point7 = {d,b} ;
//assign point6 = point + 14'd128 ;
//assign point6 = {d,x} ;
//assign point5 = point + 14'd127 ;
//assign point5 = {d,a} ;

//assign point4 = point + 14'd1 ;
//assign point4 = {y,b} ;

assign pix_lbp = (gray_data>=threshold)  ;///////////////////////////////////////////////////////////////////

always@(posedge clk or posedge reset)                         //state_Now
begin
	if(reset)
		state_Now <= READ ;
	else
		state_Now <= state_Next ;
end

always@(*)                                                   //state_Next
begin
	case(state_Now)
		READ:if(counter==4'd9)
				state_Next = OUT ;
			 else
			    state_Next = READ ;
		
		OUT: if({y,b}==14'd16255)
				state_Next = FIN ;
			else 
				state_Next = READ ;

				
		FIN: 	state_Next = FIN ;

		default : state_Next = READ ;
		
	endcase
end

assign gray_req = (state_Now==READ) ? ((gray_ready==1'b1) ? 1 : 0 ): 0 ;
assign lbp_valid = (state_Now==OUT)  ;///////////////////////////////////////////////////////////////////////////
assign finish = (state_Now==FIN)   ;

/*
always@(*)                                                   //control signal
begin
	case(state_Now)
		READ: begin 
			  if(gray_ready)
				begin gray_req = 1 ; lbp_valid = 0 ; finish = 0 ; end
			  else
				begin gray_req = 0 ; lbp_valid = 0 ; finish = 0 ; end
			  end
			  
		OUT:    begin gray_req = 0 ; lbp_valid = 1 ; finish = 0 ; end
		
			 
		FIN:	begin gray_req = 0 ; lbp_valid = 0 ; finish = 1 ; end

		default:begin gray_req = 0 ; lbp_valid = 0 ; finish = 0 ; end
	endcase
end
*/

always@(posedge clk or posedge reset)                   ////////////////////////  point
begin
	if(reset)
//		point <= 14'd129 ;
		begin x<=7'd1 ; y <=7'd1 ; end
	else if(lbp_valid)
		begin
			if(&b)
			//	point <= point + 14'd3 ;
			begin	y <= y + 7'd1 ; x <= 7'd1 ; end
			else
			//	point <= point4 ;
				x <= x + 7'd1 ;
		end
end

always@(posedge clk or posedge reset)                   ////////////////////////  counter
begin
	if(reset)
		counter <= 4'd0 ;
	else if(gray_req)
		begin
			if(counter==4'd9)
				counter <= 4'd0 ;
			else
				counter <= counter + 4'd1 ;
		end
end

always@(posedge clk)                   ////////////////////////  gray_addr
begin
	if(gray_req)
	begin
		if(counter==4'd0)
			gray_addr <= {y,x} ;
		else if(counter==4'd1)
			gray_addr <= {c,a}  ;
		else if(counter==4'd2)
			gray_addr <= {c,x} ;
		else if(counter==4'd3)
			gray_addr <= {c,b}  ;
		else if(counter==4'd4)
			gray_addr <= {y,a} ;
		else if(counter==4'd5)
			gray_addr <= {y,b} ;
		else if(counter==4'd6)
			gray_addr <= {d,a} ;
		else if(counter==4'd7)
			gray_addr <= {d,x}  ;
		else if(counter==4'd8)
			gray_addr <= {d,b} ;
	end
end

always@(posedge clk)                   ////////////////////////  threshold
begin
	if(gray_req)
	begin
		if(counter==4'd1)
			threshold <= gray_data ;
	end	
end

always@(posedge clk)                   ////////////////////////  temp_lbp
begin
	if(gray_req)
	begin
		if(counter>=4'd2)
			lbp_data[counter] <= pix_lbp ;
/*	    else if(counter==4'd3)
			temp_lbp[1] <= pix_lbp ;
		else if(counter==4'd4)
			temp_lbp[2] <= pix_lbp ;			
		else if(counter==4'd5)
			temp_lbp[3] <= pix_lbp ;
		else if(counter==4'd6)
			temp_lbp[4] <=  pix_lbp ;			
		else if(counter==4'd7)
			temp_lbp[5] <=  pix_lbp ;			
		else if(counter==4'd8)
			temp_lbp[6] <=  pix_lbp ;
		else if(counter==4'd9)
			temp_lbp[7] <=  pix_lbp ;			
*/	end
end

always@(posedge clk)                   ////////////////////////  lbp_addr
begin
		lbp_addr <= point ;
end

/*
always@(posedge clk)                   ////////////////////////  lbp_data
begin
	if(counter==4'd10)
		lbp_data <= temp_lbp ;
end
*/

//====================================================================


endmodule

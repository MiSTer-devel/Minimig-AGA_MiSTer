//This is the playfield engine.
//It takes the raw bitplane data and generates a
//single or dual playfield
//it also generated the nplayfield valid data signals which are needed
//by the main video priority logic in Denise


module denise_playfields
(
	input 	[6:1] bpldata,	   		//raw bitplane data in
	input 	dblpf,		   			//double playfield select
	input	[6:0] bplcon2,			//bplcon2 (playfields priority)
	output	reg [2:1] nplayfield,	//playfield 1,2 valid data
	output	reg [5:0] plfdata		//playfield data out
);

//local signals
wire pf2pri;						//playfield 2 priority over playfield 1
wire [2:0] pf2p;					//playfield 2 priority code

assign pf2pri = bplcon2[6];
assign pf2p = bplcon2[5:3];

//generate playfield 1,2 data valid signals
always @(*)
begin
	if (dblpf) //dual playfield
	begin
		if (bpldata[5] || bpldata[3] || bpldata[1]) //detect data valid for playfield 1
			nplayfield[1] = 1;
		else
			nplayfield[1] = 0;
			
		if (bpldata[6] || bpldata[4] || bpldata[2]) //detect data valid for playfield 2
			nplayfield[2] = 1;
		else
			nplayfield[2] = 0;	
	end
	else //single playfield is always playfield 2
	begin
		nplayfield[1] = 0;
		if (bpldata[6:1]!=6'b000000)
			nplayfield[2] = 1;
		else
			nplayfield[2] = 0;	
	end
end

//playfield 1 and 2 priority logic
always @(*)
begin
	if (dblpf) //dual playfield
	begin
		if (pf2pri) //playfield 2 (2,4,6) has priority
		begin
			if (nplayfield[2])
				plfdata[5:0] = {3'b001,bpldata[6],bpldata[4],bpldata[2]};
			else if (nplayfield[1])
				plfdata[5:0] = {3'b000,bpldata[5],bpldata[3],bpldata[1]};
			else //both planes transparant, select background color
				plfdata[5:0] = 6'b000000;
		end
		else //playfield 1 (1,3,5) has priority
		begin
			if (nplayfield[1])
				plfdata[5:0] = {3'b000,bpldata[5],bpldata[3],bpldata[1]};
			else if (nplayfield[2])
				plfdata[5:0] = {3'b001,bpldata[6],bpldata[4],bpldata[2]};
			else //both planes transparant, select background color
				plfdata[5:0] = 6'b000000;
		end
	end
	else //normal single playfield (playfield 2 only)
	//OCS/ECS undocumented feature when bpu=5 and pf2pri>5 (Swiv score display)
		if (pf2p>5 && bpldata[5])
			plfdata[5:0] = {6'b010000};
		else
			plfdata[5:0] = bpldata[6:1];
end


endmodule


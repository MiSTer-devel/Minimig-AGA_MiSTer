//This module maps physical 512KB blocks of every memory chip to different memory ranges in Amiga


module minimig_bankmapper
(
	input	chip0,				// chip ram select: 1st 512 KB block
	input	chip1,				// chip ram select: 2nd 512 KB block
	input	chip2,				// chip ram select: 3rd 512 KB block
	input	chip3,				// chip ram select: 4th 512 KB block
	input	slow0,				// slow ram select: 1st 512 KB block 
	input	slow1,				// slow ram select: 2nd 512 KB block 
	input	slow2,				// slow ram select: 3rd 512 KB block 
	input	kick,				// Kickstart ROM address range select
  input kick1mb,    // 1MB Kickstart 'upper' half
	input	cart,				// Action Reply memory range select
	input	aron,				// Action Reply enable
  input ecs,        // ECS chipset enable
	input	[3:0] memory_config,// memory configuration
	output	reg [7:0] bank		// bank select
);


always @(*)
begin
  case ({aron,memory_config})
    5'b0_0000 : bank = {  kick, kick1mb,  1'b0,  1'b0,   1'b0,  1'b0,          1'b0, chip3 | chip2 | chip1 | chip0 }; // 0.5M CHIP
    5'b0_0001 : bank = {  kick, kick1mb,  1'b0,  1'b0,   1'b0,  1'b0, chip3 | chip1,                 chip2 | chip0 }; // 1.0M CHIP
    5'b0_0010 : bank = {  kick, kick1mb,  1'b0,  1'b0,   1'b0, chip2,         chip1,                         chip0 }; // 1.5M CHIP
    5'b0_0011 : bank = {  kick, kick1mb,  1'b0,  1'b0,  chip3, chip2,         chip1,                         chip0 }; // 2.0M CHIP
    5'b0_0100 : bank = {  kick, kick1mb,  1'b0, slow0,   1'b0,  1'b0,          1'b0, chip0 | (chip1 & !ecs) | chip2 | (chip3 & !ecs) }; // 0.5M CHIP + 0.5MB SLOW
    5'b0_0101 : bank = {  kick, kick1mb,  1'b0, slow0,   1'b0,  1'b0, chip3 | chip1,                 chip2 | chip0 }; // 1.0M CHIP + 0.5MB SLOW
    5'b0_0110 : bank = {  kick, kick1mb,  1'b0, slow0,   1'b0, chip2,         chip1,                         chip0 }; // 1.5M CHIP + 0.5MB SLOW
    5'b0_0111 : bank = {  kick, kick1mb,  1'b0, slow0,  chip3, chip2,         chip1,                         chip0 }; // 2.0M CHIP + 0.5MB SLOW
    5'b0_1000 : bank = {  kick, kick1mb, slow1, slow0,   1'b0,  1'b0,          1'b0, chip3 | chip2 | chip1 | chip0 }; // 0.5M CHIP + 1.0MB SLOW
    5'b0_1001 : bank = {  kick, kick1mb, slow1, slow0,   1'b0,  1'b0, chip3 | chip1,                 chip2 | chip0 }; // 1.0M CHIP + 1.0MB SLOW
    5'b0_1010 : bank = {  kick, kick1mb, slow1, slow0,   1'b0, chip2,         chip1,                         chip0 }; // 1.5M CHIP + 1.0MB SLOW
    5'b0_1011 : bank = {  kick, kick1mb, slow1, slow0,  chip3, chip2,         chip1,                         chip0 }; // 2.0M CHIP + 1.0MB SLOW
    5'b0_1100 : bank = {  kick, kick1mb, slow1, slow0,   1'b0,  1'b0,          1'b0, chip3 | chip2 | chip1 | chip0 }; // 0.5M CHIP + 1.5MB SLOW
    5'b0_1101 : bank = {  kick, kick1mb, slow1, slow0,   1'b0,  1'b0, chip3 | chip1,                 chip2 | chip0 }; // 1.0M CHIP + 1.5MB SLOW
    5'b0_1110 : bank = {  kick, kick1mb, slow1, slow0,   1'b0, chip2,         chip1,                         chip0 }; // 1.5M CHIP + 1.5MB SLOW
    5'b0_1111 : bank = {  kick, kick1mb, slow1, slow0,  chip3, chip2,         chip1,                         chip0 }; // 2.0M CHIP + 1.5MB SLOW
   
    5'b1_0000 : bank = {  kick, kick1mb, cart,   1'b0,   1'b0,  1'b0,  1'b0, chip0 | chip1 | chip2 | chip3 }; // 0.5M CHIP
    5'b1_0001 : bank = {  kick, kick1mb, cart,   1'b0,   1'b0,  1'b0, chip1 | chip3, chip0 | chip2 }; // 1.0M CHIP
    5'b1_0010 : bank = {  kick, kick1mb, cart,   1'b0,   1'b0, chip2, chip1, chip0 }; // 1.5M CHIP
    5'b1_0011 : bank = {  kick, kick1mb, cart,   1'b0,  chip3, chip2, chip1, chip0 }; // 2.0M CHIP
    5'b1_0100 : bank = {  kick, kick1mb, cart,  slow0,   1'b0,  1'b0, 1'b0, chip0 | (chip1 & !ecs) | chip2 | (chip3 & !ecs) }; // 0.5M CHIP + 0.5MB SLOW
    5'b1_0101 : bank = {  kick, kick1mb, cart,  slow0,   1'b0,  1'b0, chip1 | chip3, chip0 | chip2 }; // 1.0M CHIP + 0.5MB SLOW
    5'b1_0110 : bank = {  kick, kick1mb, cart,  slow0,   1'b0, chip2, chip1, chip0 }; // 1.5M CHIP + 0.5MB SLOW
    5'b1_0111 : bank = {  kick, kick1mb, cart,  slow0,  chip3, chip2, chip1, chip0 }; // 2.0M CHIP + 0.5MB SLOW
    5'b1_1000 : bank = {  kick, kick1mb, cart,  slow0,   1'b0,  1'b0,  1'b0, chip0 | chip1 | chip2 | chip3 }; // 0.5M CHIP + 1.0MB SLOW
    5'b1_1001 : bank = {  kick, kick1mb, cart,  slow0,   1'b0,  1'b0, chip1 | chip3, chip0 | chip2 }; // 1.0M CHIP + 1.0MB SLOW
    5'b1_1010 : bank = {  kick, kick1mb, cart,  slow0,   1'b0, chip2, chip1, chip0 }; // 1.5M CHIP + 1.0MB SLOW
    5'b1_1011 : bank = {  kick, kick1mb, cart,  slow0,  chip3, chip2, chip1, chip0 }; // 2.0M CHIP + 1.0MB SLOW
    5'b1_1100 : bank = {  kick, kick1mb, cart,  slow0,   1'b0,  1'b0, 1'b0, chip0 | chip1 | chip2 | chip3 }; // 0.5M CHIP + 1.5MB SLOW
    5'b1_1101 : bank = {  kick, kick1mb, cart,  slow0,   1'b0,  1'b0, chip1 | chip3, chip0 | chip2 }; // 1.0M CHIP + 1.5MB SLOW
    5'b1_1110 : bank = {  kick, kick1mb, cart,  slow0,   1'b0, chip2, chip1, chip0 }; // 1.5M CHIP + 1.5MB SLOW
    5'b1_1111 : bank = {  kick, kick1mb, cart,  slow0,  chip3, chip2, chip1, chip0 }; // 2.0M CHIP + 1.5MB SLOW
  endcase
end


endmodule


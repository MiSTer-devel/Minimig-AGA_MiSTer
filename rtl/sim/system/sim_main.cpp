// The Minimig full-system simulation's driver: the clocks (clk_114 and
// clk_sys, 4:1, through pll_sim.sv), Main's side of the HPS bus (hps_io and
// hps_ext take the commands as Main's spi_uio_cmd sends them), the SDRAM
// loaded with a test ROM at $F80000 (and optionally an Action Replay image at
// $A80000, as Main's UploadActionReplay puts it there), and the test
// programs' mailbox: the CPU's chip bus writes to $F00000 (nothing decodes
// it):
//   +0  result: $600D0000+n pass, $BAD00000+n fail (ends the run)
//   +4  a character      +8  a long word, printed in hex
//   +12 a time mark n; mark 4 presses the freeze key (Help, $5F) as Main
//       sends a key (UIO_KEYBOARD)
//
//   Vtb_top --rom FILE [--ar FILE | --hrt FILE] [--cpu N] [--ms T]
//           [--quiet] [--bustrace] [--readtrace N]
//     --cpu: Main's CPU byte (0 the 68000, fx68k; 3 the 68020, TG68K)
//     --ar:  the Action Replay at $A80000 (status bit 55, memory bit 6: the
//            cartridge)
//     --hrt: HRTmon at $A10000 (memory bit 6)

#include "Vtb_top.h"
#include "Vtb_top___024root.h"
#include "verilated.h"
#include "svdpi.h"
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <vector>
#include <string>

extern "C" void sdram_poke16(unsigned int waddr, unsigned int data);
extern "C" unsigned int sdram_peek16(unsigned int waddr);

static Vtb_top *top;
static uint64_t halfstep = 0;           // clk_114 half periods
static const double CLK114_HZ = 113.5e6;
static double sim_ms() { return halfstep / (2.0 * CLK114_HZ) * 1000.0; }

struct Mailbox {
	uint16_t hi = 0;
	int result = -1;
} mbox;

static bool key_pending = false;
static bool bustrace = false;
static int readtrace = 0;
static void monitor();

// one clk_114 half period; clk_sys rises with every fourth clk_114 rise
static void step_half()
{
	auto *r = top->rootp;
	int phase = halfstep % 8;
	r->tb_top__DOT__emu__DOT__pll__DOT__c114 = !(phase & 1);
	r->tb_top__DOT__emu__DOT__pll__DOT__csys = (phase < 4);
	top->clk_50 = (halfstep / 2) & 1;
	top->eval();
	halfstep++;
	if (phase == 0) monitor();
}

static void sys_cycles(int n) { for (int i = 0; i < n * 8; i++) step_half(); }

// Main's spi_uio_cmd: io_enable (uio), one strobe per 16-bit word
static void uio_cmd(const std::vector<uint16_t> &w)
{
	top->hps_uio = 1;
	sys_cycles(2);
	for (uint16_t x : w) {
		top->hps_din = x;
		top->hps_strobe = 1;
		sys_cycles(1);
		top->hps_strobe = 0;
		sys_cycles(3);
	}
	top->hps_uio = 0;
	sys_cycles(4);
}

static void sdram_scope() { svSetScope(svGetScopeFromName("TOP.tb_top.sdram")); }

// an image at a CPU address; the SDRAM holds 8 MB: minimig_sram_bridge (and
// the CPU's fast paths) keep address bits 22-1, so $F80000 is 0x780000 and
// $A80000 0x280000, where Main's uploads land too
static bool load(const char *file, uint32_t cpu_addr, uint32_t max)
{
	uint32_t byte_addr = cpu_addr & 0x7FFFFF;
	FILE *f = fopen(file, "rb");
	if (!f) { perror(file); return false; }
	std::vector<uint8_t> b(max, 0xFF);
	size_t n = fread(b.data(), 1, max, f);
	fclose(f);
	sdram_scope();
	for (size_t i = 0; i < n; i += 2)
		sdram_poke16((byte_addr + i) >> 1, (b[i] << 8) | b[i + 1]);
	printf("[load] %s: %zu bytes at %06X (SDRAM %06X)\n", file, n, cpu_addr, byte_addr);
	return true;
}

static void monitor()
{
	if (top->mon_rd && readtrace > 0) {
		readtrace--;
		printf("%10.4f ms  R %06X %04X%s\n", sim_ms(), top->mon_addr << 1, top->mon_rdata,
		       top->mon_long ? (" long, second " + std::to_string(top->mon_rdata2)).c_str() : "");
	}
	if (!top->mon_wr) return;
	uint32_t a = top->mon_addr << 1;
	if (bustrace) printf("%10.4f ms  W %06X %04X %c%c\n", sim_ms(), a, top->mon_data,
	                     (top->mon_ds & 2) ? 'U' : '-', (top->mon_ds & 1) ? 'L' : '-');
	if ((a & 0xFFFFF0) != 0xF00000) return;
	if (!(a & 2)) { mbox.hi = top->mon_data; return; }
	uint32_t v = ((uint32_t)mbox.hi << 16) | top->mon_data;
	switch ((a >> 2) & 3) {
	case 0:
		printf("[mailbox] %.4f ms result %08X\n", sim_ms(), v);
		mbox.result = ((v & 0xFFFF0000) == 0x600D0000) ? 0 : 1;
		break;
	case 1: putchar(v & 0xFF); fflush(stdout); break;
	case 2: printf("%08X\n", v); fflush(stdout); break;
	case 3:
		printf("[mark] %u at %.6f ms\n", v, sim_ms()); fflush(stdout);
		if (v == 4) key_pending = true;
		break;
	}
}

int main(int argc, char **argv)
{
	Verilated::commandArgs(argc, argv);
	// (fx68k's unique case statements see its uninitialised registers before
	// reset; the checks are the simulator's, Quartus ignores them)
	Verilated::assertOn(false);
	top = new Vtb_top;

	const char *rom = nullptr, *ar = nullptr, *hrt = nullptr;
	double run_ms = 300;
	int cpu = 0;
	bool quiet = false;
	for (int i = 1; i < argc; i++) {
		std::string a = argv[i];
		auto next = [&]() { return (i + 1 < argc) ? argv[++i] : (char *)""; };
		if (a == "--rom") rom = next();
		else if (a == "--ar") ar = next();
		else if (a == "--hrt") hrt = next();
		else if (a == "--cpu") cpu = atoi(next());
		else if (a == "--ms") run_ms = atof(next());
		else if (a == "--quiet") quiet = true;
		else if (a == "--bustrace") bustrace = true;
		else if (a == "--readtrace") readtrace = atoi(next());
	}
	if (!rom) { fprintf(stderr, "usage: %s --rom FILE [--ar FILE] [--cpu N] [--ms T] [--quiet]\n", argv[0]); return 2; }

	top->reset = 1;
	top->hps_uio = 0; top->hps_fpga = 0; top->hps_strobe = 0; top->hps_din = 0;
	sys_cycles(64);
	if (!load(rom, 0xF80000, 0x80000)) return 2;
	if (ar && !load(ar, 0xA80000, 0x80000)) return 2;
	if (hrt && !load(hrt, 0xA10000, 0x70000)) return 2;
	top->reset = 0;
	sys_cycles(256);

	// Main's ApplyConfiguration: halt, the configuration, the status (the
	// cartridge's type before its image), reset, run
	uio_cmd({0xF1, 0x04});                                  // halt
	uio_cmd({0xF3, 0x10});                                  // chipset: AGA
	uio_cmd({0xF4, (uint16_t)cpu});                         // CPU
	uio_cmd({0xF5, (uint16_t)(0x03 | ((ar || hrt) ? 0x40 : 0))});   // 2 MB chip RAM, the cartridge
	uio_cmd({0xF7, 0x00});                                  // floppy
	uio_cmd({0xF8, 0x00});                                  // no hard disks
	uint16_t st[8] = {0};
	if (ar) st[3] |= 1 << (55 - 48);                        // status bit 55: the Action Replay
	uio_cmd({0x1E, st[0], st[1], st[2], st[3], st[4], st[5], st[6], st[7]});
	uio_cmd({0xF1, 0x07});                                  // halt, CPU reset, user reset
	sys_cycles(1000);
	uio_cmd({0xF1, 0x00});                                  // run

	uint64_t end_half = halfstep + (uint64_t)(run_ms / 1000.0 * 2.0 * CLK114_HZ);
	uint64_t next_report = halfstep;
	while (halfstep < end_half && mbox.result < 0) {
		step_half();
		if (key_pending) {
			key_pending = false;
			printf("[key] the freeze key at %.4f ms\n", sim_ms());
			uio_cmd({0x05, 0x5F});                          // Help pressed
			sys_cycles(4000);
			uio_cmd({0x05, 0xDF});                          // released
		}
		if (!quiet && halfstep >= next_report) {
			printf("[sim] %.1f ms  cpu_rst %d reset_d %d halt %d  AS %d addr %06X state %d  cachecfg %d turbo %d\n", sim_ms(),
			       top->dbg_cpu_rst, top->dbg_reset_d, top->dbg_cpuhlt, top->dbg_chip_as, top->dbg_chip_addr << 1, top->dbg_cpu_state,
			       top->dbg_cachecfg, top->dbg_turbo);
			fflush(stdout);
			next_report = halfstep + (uint64_t)(0.01 * 2.0 * CLK114_HZ);   // every 10 ms
		}
	}
	printf("[sim] end at %.3f ms\n", sim_ms());
	top->final();
	delete top;
	return mbox.result < 0 ? 3 : mbox.result;
}

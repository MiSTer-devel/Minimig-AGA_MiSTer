void ShiftFpga(unsigned char data);
unsigned char ConfigureFpga(void);
void SendFile(fileTYPE *file);
char BootPrint(const char *text);
char BootUpload(fileTYPE *file, unsigned char base, unsigned char size);
void BootExit(void);
void ClearMemory(unsigned long base, unsigned long size);
unsigned char GetFPGAStatus(void);

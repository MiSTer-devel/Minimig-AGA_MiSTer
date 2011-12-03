#ifndef BOOT_H_INCLUDED
#define BOOT_H_INCLUDED

// Enable / Disable boot debug output
//#define BOOT_DEBUG

void FatalError(unsigned char code);

unsigned char ConfigureFpga(const unsigned char *FPGAFileName);

char UploadKickstart(const unsigned char *name);
char UploadActionReplay(const unsigned char *name);

void SendFile(struct fileTYPE *file);
char BootPrint(const char* text);
char BootUpload(struct fileTYPE *file, unsigned char base, unsigned char size);
void BootExit(void);
void ClearMemory(unsigned char base, unsigned char size);

void SendBootFPGACommand(unsigned char cmd, unsigned char p1, unsigned char p2);

#endif /*BOOT_H_INCLUDED*/

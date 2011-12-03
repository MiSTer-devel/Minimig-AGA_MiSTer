#ifndef FILEBROWSER_H_
#define FILEBROWSER_H_

// Enable Disable file browser debuging
//#define FILEBROWSER_DEBUG

#define		DIRSIZE				8					// size of directory display window

extern unsigned char dirptr;						// pointer into directory array
extern bdata struct fileTYPE directory[DIRSIZE];	// directory array 

void ScrollDir(const unsigned char *type, unsigned char mode);
void PrintDir(void);

#endif /*FILEBROWSER_H_*/

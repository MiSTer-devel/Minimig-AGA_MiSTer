/*******************************************************************************
 CompList V1.0 - Written by Alastair M. Robinson in 1998.

 Tiny little shell utility to create a compilation script for VBCC according
 to those files which have the archive bit cleared.
 The script is sent to StdOut, normally to be redirected to a file in t:
 When executed, the script will compile the appropriate files, and if
 successful, set their archive bit so they'll be skipped in future until
 they're saved again!  Useful for machines which have no battery-backed clock,
 and hence can't use the traditional Make tools.

 CompList >t:BuildScript vc -c %s -o Obj/%s%s
 Execute t:BuildScript

 will call vc for all files which have changed since the last build, placing
 the resulting object files in the Obj directory.
 Link them together with something like

 join Obj/(#?.o|#?.lib) to Prog.o
 PhxLnk vlib:Startup.o vlib:vc.lib vlib:amiga.lib Prog.o to a.out

 Compiled with the totally brilliant VBCC.

 vc CompList.c -o CompList

 Public Domain
*******************************************************************************/

#include <stdio.h>

#include <utility/tagitem.h>
#include <dos/dos.h>

#include <clib/dos_protos.h>
#include <clib/exec_protos.h>

void halt() = "\tillegal\n";

int main()
{
  LONG *Args[]={0,0};
  BOOL result=FALSE;
  struct RDArgs* rd;
  char pattern[]="(#?.c|#?.s)";
  struct FileInfoBlock* fib=0;
  BPTR lock;
  char tokenstring[130];
  char *namebuffer;

    if (rd=ReadArgs("VCOPTIONS/F/A",(LONG *)&Args[0],NULL))
    {
      if (fib = AllocDosObjectTags(DOS_FIB,TAG_DONE))
      {
        if (ParsePatternNoCase(pattern,tokenstring,128) != -1);
        {
          if (lock=Lock("",ACCESS_READ))
          {
            if (Examine(lock,fib))
            {
              do
              {
                if(!(fib->fib_Protection & FIBF_ARCHIVE) && (fib->fib_DirEntryType)<0 && MatchPatternNoCase(tokenstring,fib->fib_FileName))
                {
                  if(namebuffer=(char *)malloc(strlen(fib->fib_FileName)+2))
                  {
                    strcpy(namebuffer,fib->fib_FileName);
                    namebuffer[strlen(namebuffer)-2]=0;
                    printf("Echo \"Compiling %s.....\"\n",fib->fib_FileName);
                    printf((char *)Args[0],fib->fib_FileName,namebuffer,".o");
                    printf("\n");
                    printf("if not warn\nprotect %s +a\nendif\n",(fib->fib_FileName));
                    free(namebuffer); namebuffer=NULL;
                  }
                }
              } while(ExNext(lock,fib));
              result=TRUE;
            }
            UnLock(lock);
          }
        }
        FreeDosObject(DOS_FIB,fib);
      }
      FreeArgs(rd);
    }
  if(result=FALSE)
    PrintFault(IoErr(),"Error");
  return(0);
}


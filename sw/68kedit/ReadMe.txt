        68000 Editor And Front End Assembler & Simulator
                       v5.1 - By Greg Colley

  
About the Program
-----------------

The 68000 Editor can Edit files as well as send the files to the Assembler & 
Simulator, it was made by Greg Colley in Delphi 3. The program is designed to be
 able to edit 68000 files and assemble and simulate them in a Windows 
environment.

Drag & Drop
-----------
You can now drag and drop files into the editor, and they will load up, you can 
also set *.x68 files you open with the editor.

Parameters
----------
If you want to run the program so it opens and saves files in a specified 
directory just add "/D C:\Path\To\files" to the Parameters of the commend line.


    e.g.    
    Editor68K.exe /D C:\Path\To\x68\Files

Now Every time you save or open your files it will save and open then to this 
directory. Your editor ini file will also be stored in this folder so you can 
easily save your personal settings.

Errors / Bugs
-------------
1. If the Edit68K.ini file is made read only then you will get an error when 
   trying to save the options. Also some times if you install the editor into a 
   folder with a long file name on some computers it does not save the ini file,
   to combat this problem just install the editor into C:\68000\.

2. If you get an error saying "Bad Commend of File Name" when you assemble or 
   simulate your files then you will need to edit  the batch files. 
   (please note : You will get this error on the first time you run this program
    if you don't let the install  program to re-boot your computer. This is 
    because the install program has to add a line to your autoexec.bat 
    "SET PATH=C:\path\to\program\files" so your operating system knows where the
    files are when it calls them in DOS.) If you re-start your computer and you 
    still get this error then you will have to either edit your autoexec.bat and
    put in the path to where the program was installed to. Or edit the batch 
    files in the program directory.

3. The replace all button does not work in the replace dialog

4. If you set the editors parameter to "/d c:\" you will get an error when trying
   to save the editor options.

5. The editor, and other programs that go with the 68000 editor does not like long
   file names for some strange reason, guess it's Windows 95. Anyway to over come
   this problem try putting all you files in folder with 8 characters or less. 
   also try not to save you files with long file name, this may cause problems too.
   I'm working on how to over come this problem.

If you find any bugs in this program then please could you take the time to fill 
out the bug report form on our web site at :
http://xrmx.simplenet.com/programs/68000

Acknowledgements
----------------
The DOS cross assembler and simulator were created at Teesside Polytechnic for 
teaching purposes. Their authors are Paul Lambert and Eric Pearson. The 
Polytechnic has agreed to allow PWS-Kent  Publishers Ltd. to distribute these 
programs as part of the Instructor's Handbook. More information can be found 
in the "readme.txt" file.

Disclaimer: THIS SOFTWARE IS PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND. THE
 ENTIRE RISK OF THE USE OF THE SOFTWARE IS ASSUMED BY YOU.


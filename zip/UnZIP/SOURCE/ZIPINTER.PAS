unit ZipInter;   {Interface to DLL info-unz.dll}

interface

uses WinTypes,WinProcs,packdefs;

{PackMethod:      supported by unzipfile
  0:   stored             x
  1:   shrunk             x
  2..5:reduced            x
  6:   imploded           x
  7:   tokenized    (format does not exist)
  8:   deflated           x
}

{**************************** DLL Version ****************************}

function GetUnzipDllVersion:word; {$ifdef win32}stdcall;{$endif}
{Hi byte=number before period, Lo byte=number after period}
{Later versions will be downward compatible}

{******************** ZIP central directory access *******************}

{The following 3 functions can be called in a loop to retreive all
 the files in the given zip file.
 Use these functions similar to findfirst and findnext:

 Example:
 var r:tziprec;

 rc:=GetFirstInZip(zipname,r);
 while rc=zip_ok do
   DosomethingWithData(r);
   rc:=GetNextInZip(r);
 end;
 closezipfile(r);
 case rc of
   zip_FileError:messagebox(hwindow,'Error reading ZIP file!',zipname,mb_ok);
   zip_InternalError:messagebox(hwindow,'Internal error in ZIP file!',zipname,mb_ok);
 end;
}

function GetFirstInZip(zipfilename:pchar;var zprec:tPackRec):integer; {$ifdef win32}stdcall;{$endif}
{zipfilename: filename of zip file}
{zprec:       record, will be filled with zipfile data}

function GetNextInZip(var Zprec:tPackrec):integer;{$ifdef win32}stdcall;{$endif}
{zprec:       record, will be filled with zipfile data,
 do not change the 'internal' field received from previous calls!}

procedure CloseZipFile(var Zprec:tPackrec);{$ifdef win32}stdcall;{$endif}
{Call after last GetNextInZip call to free buffer}

{********************* Test if file is a ZIP file ********************}

function isZip(filename:pchar):boolean;{$ifdef win32}stdcall;{$endif}
{Tests if given file is a zip file (only test for PK#3#4 at the beginning)}

{***************** Get Unzip Methods supported by DLL ****************}
{Currently (version 0.1) these are stored (0), imploded (6) and deflated (8)}

function GetSupportedMethods:longint;{$ifdef win32}stdcall;{$endif}
{Method 0 supported -> bit 0 = 1,
 Method 8 supported -> bit 8 = 1,
 etc.}

{********************* unzip a file from ZIP-file ********************}

function unzipfile(in_name:pchar;out_name:pchar;attr:word;offset:longint;
  hFileAction:hwnd;cm_index:integer):integer; {$ifdef win32}stdcall;{$endif}
{usage:
 in_name:      name of zip file with full path
 out_name:     desired name for out file
 offset:       header position of desired file in zipfile, found in tZiprec
 hFileAction:  handle to dialog box showing advance of decompression (optional),
               or zero when only keyboard shall be checked
 cm_index:     - if hfileaction<>0 : notification code sent in a wm_command
                 message to the dialog to update percent-bar
               - if hfileaction=0  : virtual key code of key the user must press
                 to interrupt unzipping, i.e. vk_escape

 Return value: one of the above unzip_xxx codes

 Example for handling the cm_index message in a progress dialog:

 unzipfile(......,cm_showpercent);

 ...

 procedure TFileActionDialog.wmcommand(var msg:tmessage);
 var ppercent:^word;
 begin
   TDialog.WMCommand(msg);
   if msg.wparam=cm_showpercent then begin
     ppercent:=pointer(lparam);
     if ppercent<>nil then begin
       if (ppercent^>=0) and (ppercent^<=100) then
         SetProgressBar(ppercent^);
       if UserPressedAbort then
         ppercent^:=$ffff
       else
         ppercent^:=0;
       end;
     end;
   end;
 end;
}

function unzipfiletomemory(in_name:pchar;out_buf:pchar;var buf_size:longint;
  offset:longint;hFileAction:word;cm_index:integer):integer;{$ifdef win32}stdcall;{$endif}
{usage:
 in_name:      name of zip file with full path
 out_buf:      buffer to recieve unpacked file
 buf_size:     size of buffer to recieve unpacked file
 offset:       header position of desired file in zipfile
 hFileAction:  handle to dialog box showing advance of decompression (optional)
 cm_index:     notification code sent in a wm_command message to the dialog
               to update percent-bar
 Return value: one of the above unzip_xxx codes
}

function UnzipTestIntegrity(in_name:pchar;offset:longint;
  hFileAction:word;cm_index:integer;var crc:longint):integer;{$ifdef win32}stdcall;{$endif}
{usage:
 in_name:      name of zip file with full path
 offset:       header position of desired file in zipfile
 hFileAction:  handle to dialog box showing advance of decompression (optional)
 cm_index:     notification code sent in a wm_command message to the dialog
               to update percent-bar
 crc:          Returns the CRC of the file, compares itself with CRC stored in header
 Return value: one of the above unzip_xxx codes
}

{*********************************************************************}

implementation

{$ifdef win32}
function GetUnzipDllVersion; external 'UNZIPD32' index 1;
function GetFirstInZip; external 'UNZIPD32' index 2;
function GetNextInZip; external 'UNZIPD32' index 3;
procedure CloseZipFile; external 'UNZIPD32' index 4;
function isZip; external 'UNZIPD32' index 5;
function GetSupportedMethods; external 'UNZIPD32' index 6;
function unzipfile; external 'UNZIPD32' index 7;
function unzipfiletomemory;  external 'UNZIPD32' index 8;
function UnzipTestIntegrity; external 'UNZIPD32' index 9;
{$else}
function GetUnzipDllVersion; external 'UNZIPDLL' index 1;
function GetFirstInZip; external 'UNZIPDLL' index 2;
function GetNextInZip; external 'UNZIPDLL' index 3;
procedure CloseZipFile; external 'UNZIPDLL' index 4;
function isZip; external 'UNZIPDLL' index 5;
function GetSupportedMethods; external 'UNZIPDLL' index 6;
function unzipfile; external 'UNZIPDLL' index 7;
function unzipfiletomemory;  external 'UNZIPDLL' index 8;
function UnzipTestIntegrity; external 'UNZIPDLL' index 9;
{$endif}

end.

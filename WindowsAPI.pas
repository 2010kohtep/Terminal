unit WindowsAPI;

{$I Default.inc}

interface

type
 PImageDataDirectory = ^TImageDataDirectory;
 _IMAGE_DATA_DIRECTORY = record
   VirtualAddress: LongWord;
   Size: LongWord;
 end;
 TImageDataDirectory = _IMAGE_DATA_DIRECTORY;

 PImageOptionalHeader = ^TImageOptionalHeader;
 _IMAGE_OPTIONAL_HEADER = packed record
   { Standard fields. }
   Magic: Word;
   MajorLinkerVersion: Byte;
   MinorLinkerVersion: Byte;
   SizeOfCode: LongWord;
   SizeOfInitializedData: LongWord;
   SizeOfUninitializedData: LongWord;
   AddressOfEntryPoint: LongWord;
   BaseOfCode: LongWord;
   BaseOfData: LongWord;
   { NT additional fields. }
   ImageBase: LongWord;
   SectionAlignment: LongWord;
   FileAlignment: LongWord;
   MajorOperatingSystemVersion: Word;
   MinorOperatingSystemVersion: Word;
   MajorImageVersion: Word;
   MinorImageVersion: Word;
   MajorSubsystemVersion: Word;
   MinorSubsystemVersion: Word;
   Win32VersionValue: LongWord;
   SizeOfImage: LongWord;
   SizeOfHeaders: LongWord;
   CheckSum: LongWord;
   Subsystem: Word;
   DllCharacteristics: Word;
   SizeOfStackReserve: LongWord;
   SizeOfStackCommit: LongWord;
   SizeOfHeapReserve: LongWord;
   SizeOfHeapCommit: LongWord;
   LoaderFlags: LongWord;
   NumberOfRvaAndSizes: LongWord;
   DataDirectory: packed array[0..{IMAGE_NUMBEROF_DIRECTORY_ENTRIES-1}15] of TImageDataDirectory;
 end;
 TImageOptionalHeader = _IMAGE_OPTIONAL_HEADER;

 PImageFileHeader = ^TImageFileHeader;
 _IMAGE_FILE_HEADER = packed record
   Machine: Word;
   NumberOfSections: Word;
   TimeDateStamp: LongWord;
   PointerToSymbolTable: LongWord;
   NumberOfSymbols: LongWord;
   SizeOfOptionalHeader: Word;
   Characteristics: Word;
 end;
 TImageFileHeader = _IMAGE_FILE_HEADER;

 PImageDosHeader = ^TImageDosHeader;
   {EXTERNALSYM _IMAGE_DOS_HEADER}
 _IMAGE_DOS_HEADER = packed record      { DOS .EXE header                  }
     e_magic: Word;                     { Magic number                     }
     e_cblp: Word;                      { Bytes on last page of file       }
     e_cp: Word;                        { Pages in file                    }
     e_crlc: Word;                      { Relocations                      }
     e_cparhdr: Word;                   { Size of header in paragraphs     }
     e_minalloc: Word;                  { Minimum extra paragraphs needed  }
     e_maxalloc: Word;                  { Maximum extra paragraphs needed  }
     e_ss: Word;                        { Initial (relative) SS value      }
     e_sp: Word;                        { Initial SP value                 }
     e_csum: Word;                      { Checksum                         }
     e_ip: Word;                        { Initial IP value                 }
     e_cs: Word;                        { Initial (relative) CS value      }
     e_lfarlc: Word;                    { File address of relocation table }
     e_ovno: Word;                      { Overlay number                   }
     e_res: array [0..3] of Word;       { Reserved words                   }
     e_oemid: Word;                     { OEM identifier (for e_oeminfo)   }
     e_oeminfo: Word;                   { OEM information; e_oemid specific}
     e_res2: array [0..9] of Word;      { Reserved words                   }
     _lfanew: LongInt;                  { File address of new exe header   }
 end;
 TImageDosHeader = _IMAGE_DOS_HEADER;

 PImageNtHeaders = ^TImageNtHeaders;
 _IMAGE_NT_HEADERS = packed record
   Signature: LongWord;
   FileHeader: TImageFileHeader;
   OptionalHeader: TImageOptionalHeader;
 end;
 TImageNtHeaders = _IMAGE_NT_HEADERS;

type
  POverlapped = ^_OVERLAPPED;
  _OVERLAPPED = record
    Internal: LongWord;
    InternalHigh: LongWord;
    Offset: LongWord;
    OffsetHigh: LongWord;
    hEvent: LongWord;
  end;

  PSecurityAttributes = ^_SECURITY_ATTRIBUTES;
  _SECURITY_ATTRIBUTES = record
    nLength: LongWord;
    lpSecurityDescriptor: Pointer;
    bInheritHandle: Boolean;
  end;

const
 kernel32 = 'kernel32.dll';
 user32 = 'user32.dll';

 PAGE_NOACCESS = 1;
 PAGE_READONLY = 2;
 PAGE_READWRITE = 4;
 PAGE_WRITECOPY = 8;
 PAGE_EXECUTE = $10;
 PAGE_EXECUTE_READ = $20;
 PAGE_EXECUTE_READWRITE = $40;
 PAGE_EXECUTE_WRITECOPY = $80;

 HWND_DESKTOP = 0;

 MB_OK = $00000000;
 MB_OKCANCEL = $00000001;
 MB_ABORTRETRYIGNORE = $00000002;
 MB_YESNOCANCEL = $00000003;
 MB_YESNO = $00000004;
 MB_RETRYCANCEL = $00000005;

 MB_ICONHAND = $00000010;
 MB_ICONQUESTION = $00000020;
 MB_ICONEXCLAMATION = $00000030;
 MB_ICONASTERISK = $00000040;
 MB_USERICON = $00000080;
 MB_ICONWARNING                 = MB_ICONEXCLAMATION;
 MB_ICONERROR                   = MB_ICONHAND;
 MB_ICONINFORMATION             = MB_ICONASTERISK;
 MB_ICONSTOP                    = MB_ICONHAND;

 MB_DEFBUTTON1 = $00000000;
 MB_DEFBUTTON2 = $00000100;
 MB_DEFBUTTON3 = $00000200;
 MB_DEFBUTTON4 = $00000300;

 MB_APPLMODAL = $00000000;
 MB_SYSTEMMODAL = $00001000;
 MB_TASKMODAL = $00002000;
 MB_HELP = $00004000;                          { Help Button }

 MB_NOFOCUS = $00008000;
 MB_SETFOREGROUND = $00010000;
 MB_DEFAULT_DESKTOP_ONLY = $00020000;

 MB_TOPMOST = $00040000;
 MB_RIGHT = $00080000;
 MB_RTLREADING = $00100000;

 MB_SERVICE_NOTIFICATION = $00200000;
 MB_SERVICE_NOTIFICATION_NT3X = $00040000;

 MB_TYPEMASK = $0000000F;
 MB_ICONMASK = $000000F0;
 MB_DEFMASK = $00000F00;
 MB_MODEMASK = $00003000;
 MB_MISCMASK = $0000C000;

 DLL_PROCESS_ATTACH = 1;
 DLL_THREAD_ATTACH = 2;
 DLL_THREAD_DETACH = 3;
 DLL_PROCESS_DETACH = 0;

 ERROR_INVALID_PARAMETER = 87;
 ERROR_HANDLE_EOF = 38;
 FILE_CURRENT = 1;
 OPEN_EXISTING = 3;
 GENERIC_READ = LongWord($80000000);

function GetTickCount: LongWord; external kernel32;
function VirtualProtect(lpAddress: Pointer; dwSize, flNewProtect: LongWord; lpflOldProtect: Pointer): Boolean; stdcall; external kernel32;
function VirtualProtectEx(hProcess: LongWord; lpAddress: Pointer; dwSize, flNewProtect: LongWord; lpflOldProtect: Pointer): Boolean; stdcall; external kernel32;
function GetModuleHandle(lpModuleName: PChar): LongWord; stdcall; external kernel32 name 'GetModuleHandleA';
function VirtualAlloc(lpvAddress: Pointer; dwSize, flAllocationType, flProtect: LongWord): Pointer; stdcall; external kernel32;
function CreateThread(lpThreadAttributes: Pointer; dwStackSize: LongWord; lpStartAddress: Pointer; lpParameter: Pointer; dwCreationFlags: LongWord; var lpThreadId: LongWord): LongWord; stdcall; external kernel32 name 'CreateThread';
procedure Sleep(dwMilliseconds: LongWord); stdcall; external kernel32;
function MessageBox(hWnd: LongWord; lpText, lpCaption: PChar; uType: LongWord): Integer; stdcall; external user32 name 'MessageBoxA';
function CreateMutex(lpMutexAttributes: Pointer; bInitialOwner: Integer; lpName: PChar): LongWord; stdcall; external kernel32 name 'CreateMutexA';
function GetLastError: LongWord; external kernel32;

function GetCurrentProcess: LongWord; external kernel32;
function DisableThreadLibraryCalls(Module: LongWord): Boolean; stdcall; external kernel32;
function CloseHandle(hObject: LongWord): Boolean; stdcall; external kernel32;
procedure ExitProcess(uExitCode: LongWord); stdcall; external kernel32;

function GetProcessHeap: LongWord; stdcall; external kernel32;
function HeapAlloc(hHeap: LongWord; dwFlags, dwBytes: LongWord): Pointer; stdcall; external kernel32;
function HeapReAlloc(hHeap: LongWord; dwFlags: LongWord; lpMem: Pointer; dwBytes: LongWord): Pointer; stdcall; external kernel32;
function HeapFree(hHeap: LongWord; dwFlags: LongWord; lpMem: Pointer): Boolean; stdcall; external kernel32;

function LoadLibrary(lpLibFileName: PChar): LongWord; stdcall; external kernel32 name 'LoadLibraryA';

procedure SetLastError(dwErrCode: LongWord); stdcall; external kernel32 name 'SetLastError';
function ReadFile(hFile: LongWord; var Buffer; nNumberOfBytesToRead: LongWord; var lpNumberOfBytesRead: LongWord; lpOverlapped: POverlapped): Boolean; stdcall; external kernel32 name 'ReadFile';
function SetFilePointer(hFile: LongWord; lDistanceToMove: LongInt; lpDistanceToMoveHigh: Pointer; dwMoveMethod: LongWord): LongWord; stdcall; external kernel32 name 'SetFilePointer';
function CreateFile(lpFileName: PChar; dwDesiredAccess, dwShareMode: LongWord; lpSecurityAttributes: PSecurityAttributes; dwCreationDisposition, dwFlagsAndAttributes: LongWord; hTemplateFile: LongWord): LongWord; stdcall; external kernel32 name 'CreateFileA';

type
  POFStruct = ^TOFStruct;
  _OFSTRUCT = record
    cBytes: Byte;
    fFixedDisk: Byte;
    nErrCode: Word;
    Reserved1: Word;
    Reserved2: Word;
    szPathName: array[0..127] of CHAR;
  end;
  TOFStruct = _OFSTRUCT;
  OFSTRUCT = _OFSTRUCT;

function ReadLine(h: LongWord; var Buffer; Size: LongWord): Boolean;
function OpenFile(const lpFileName: PChar; var lpReOpenBuff: TOFStruct; uStyle: LongWord): LongWord; stdcall; external kernel32;

// non winapi))

const
 URLMON_OPTION_USERAGENT         = $10000001;

function UrlMkSetSessionOption(dwOption: LongWord; pBuffer: Pointer; dwBufferLength, dwReserved: LongWord): LongWord; stdcall; external 'URLMON.DLL' name 'UrlMkSetSessionOption';

implementation

function ReadLine(h: LongWord; var Buffer; Size: LongWord): Boolean;
asm
 test edx, edx
 jnz @GoodBuffer
  push ERROR_INVALID_PARAMETER
  call SetLastError
  xor eax, eax
  ret

@GoodBuffer:
 push edi
 push 0   // allocate CharsReaded variable
 push edx // save two first function arguments
 push eax // -:-

 push 0
 push esp
 add [esp], 12
 push ecx
 push edx
 push eax
 call ReadFile

 pop ecx // ecx = h
 pop edx // edx = Buffer
 pop edi // edi = CharsReaded

 test edi, edi
 jz @A3

 test eax, eax
 jnz @SuccessfullyReaded
@A3:
  pop edi
  push ERROR_HANDLE_EOF
  call SetLastError
  xor eax, eax
  ret

@SuccessfullyReaded:
 push esi // counter
 or esi, -1

@Loop:
 inc esi
 cmp byte ptr [edx+esi], 13 // \r
 jne @NotCR
  mov byte ptr [edx+esi], 0

  mov eax, esi
  inc eax
  cmp eax, edi
  jae @A
  cmp byte ptr [edx+esi+1], 10 // \n
  jne @A
   inc esi
@A:
  jmp @Break
@NotCR:
 cmp byte ptr [edx+esi], 0
  je @Break

 cmp byte ptr [edx+esi], 10 // \n
  jne @Loop

 mov byte ptr [edx+esi], 0
@Break:

 cmp esi, edi
 jl @A1
  mov byte ptr [edx+esi], 0
  jmp @A2
@A1:
 inc esi
@A2:

 sub esi, edi
 push FILE_CURRENT
 push 0
 push esi
 push ecx
 call SetFilePointer

 xor eax, eax
 inc eax

 pop esi
 pop edi
end;

end.

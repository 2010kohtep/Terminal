unit Memory;

{$I Default.inc}

interface

procedure ReplaceMemory(Address, Pattern: Pointer; Size: LongWord);

function memcpy(Dest, Source: Pointer; Len: LongInt): Pointer;
function malloc(Size: LongInt): Pointer;
function calloc(Size: LongInt): Pointer;
function realloc(P: Pointer; Size: LongInt): Pointer;
function freemem(P: Pointer): Boolean;
function zeromem(P: Pointer; Size: LongInt): Pointer; stdcall;

procedure WriteByteToAddr; {raw}

function VirtualProtect_Internal: Boolean; 

var
 ReservedESP: LongWord = 0;

implementation

uses
 WindowsAPI, CvarDef;

{
 -- RAW FUNCTION

 EDI - Destination
 ESI - Source
 ECX - Length
}
procedure memcpy_Internal; assembler;
asm
 mov eax, ecx
 and eax, 0011b
 shr ecx, 2
 rep movsd
 mov ecx, eax
 rep movsb
end;

function memcpy(Dest, Source: Pointer; Len: LongInt): Pointer;
asm
 push eax
 push edi
 push esi

 mov edi, Dest
 mov esi, Source
 mov ecx, Len
 call memcpy_Internal

 pop esi
 pop edi
 pop eax
end;

// not checked
procedure ReplaceMemory(Address, Pattern: Pointer; Size: LongWord);
asm
 test eax, eax
 jz @Exit
 test edx, edx
 jz @Exit
 test ecx, ecx
 jz @Exit

 push 0
 push esi
 push PAGE_READWRITE
 push ecx
 push eax
 call VirtualProtect

 xchg eax, edx
 call memcpy

 push esp
 push ecx
 push edx
 call VirtualProtect

@Exit:
end;

{
 -- RAW FUNCTION

 ESI - Addr
 EBX - Byte
}
procedure WriteByteToAddr; assembler;
asm
 push 0 // load Protection
 push esp
 push PAGE_EXECUTE_READWRITE
 push 1
 push esi
 call VirtualProtect

 mov byte ptr [esi], bl

 push esp
 push [esp+4]
 push 1
 push esi
 call VirtualProtect

 pop eax

 ret
end;

function malloc(Size: LongInt): Pointer;
asm
 {push 4
 push 1000h
 push eax
 push 0
 call VirtualAlloc}
 push eax
 push 0
 push [ProcessHeap]
 call HeapAlloc
end;

function calloc(Size: LongInt): Pointer;
asm
 push eax
 push eax

 call malloc

 mov [esp], eax
 call zeromem
end;

function realloc(P: Pointer; Size: LongInt): Pointer;
asm
 push edx
 push eax
 push 0
 push [ProcessHeap]
 call HeapReAlloc
end;

function freemem(P: Pointer): Boolean;
asm
 push eax
 push 0
 push [ProcessHeap]
 call HeapFree
end;

{
function zeromem(P: Pointer; Size: LongInt): Pointer;
asm
 push eax

 push edi
 mov edi, eax
 xchg edx, ecx
 xor eax, eax
 rep stosd
 pop edi

 pop eax
 push eax



 pop eax
end;
}

function zeromem(P: Pointer; Size: LongInt): Pointer; stdcall;
asm
 pushad

 mov edi, P
 mov edx, Size
 xor eax, eax
 mov ecx, edx
 shr ecx, 2
 mov ebx, ecx
 shl ebx, 2
 sub edx, ebx
 rep stosd
 mov ecx, edx
 rep stosb

 popad
end;

function VirtualProtect_Internal({lpAddress: Pointer; dwSize, flNewProtect: LongWord; lpflOldProtect: Pointer}): Boolean; {stdcall;}
asm
 lea edx, [WindowsAPI.VirtualProtect]
 mov edx, dword ptr [edx+2]
 mov edx, [edx]
 add edx, 5

 mov edi, edi
 push ebp
 mov ebp, esp

 jmp edx
end;

end.

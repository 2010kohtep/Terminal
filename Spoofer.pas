unit Spoofer;

{$I Default.inc}

interface

uses
 MemSearch, Strings, Memory,
 CvarDef, HLSDK;

function RevHash(S: PChar): LongInt;
function Bruteforce: Boolean;

function Spoofer_CustomEmu(P: Pointer; SteamID: LongInt): Pointer;
function Spoofer_OldRevEmu(P: Pointer; SteamID: LongInt): Pointer;
function Spoofer_SteamEmu(P: Pointer; SteamID: LongInt): Pointer;
function Spoofer_AVSMP(P: Pointer; SteamID: LongInt): Pointer;

var
 EmusArray: array[0..3] of Pointer = (@Spoofer_OldRevEmu, @Spoofer_SteamEmu, @Spoofer_AVSMP, @Spoofer_CustomEmu);
 EmusSize: array[0..3] of LongWord = (10, 768, 28, 206);

implementation

const
 RevDic: array[0..36] of Char = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ'#0;

var
 RevTreasure: LongWord = 123;
 RevDicLen: LongInt;
 RevInputLen: LongInt;
 RevInput: array[0..7] of Char = '0000000';

function RevHash(S: PChar): LongInt;
asm
 push ebx
 push esi

 xor ebx, ebx
 mov edx, 4E67C6A7h
@Loop:
  cmp byte ptr [eax], 0
   jz @Finish

  mov ecx, edx
  mov esi, edx
  shr ecx, 2
  shl esi, 5

  mov bl, byte ptr [eax]
  add ecx, esi
  add ecx, ebx
  xor edx, ecx

  inc eax
 jnz @Loop
 
@Finish:
 mov eax, edx
 pop esi
 pop ebx
end;

function ScanLast3(PrevHash: LongWord): Boolean;
asm
 
end;

function ScanNext(Index: LongInt; PrevHash: LongWord): Boolean;
asm
 // esi - RevDicLen
 // edi - Index
 // ebx - PrevHash
 // esp - RevDic
 // ebp - <TempVar>
 push esi
 push edi
 push ebx
 push ebp
 mov [ReservedESP], esp

 mov edi, eax
 mov ebx, edx
 mov esp, offset RevDic
 mov esi, [RevDicLen]
 dec esi

 xor ecx, ecx
@Loop:
  xor eax, eax
  
  mov ebp, ebx
  mov edx, ebx
  shr ebp, 2
  shl edx, 5
  add ebp, edx
  mov al, byte ptr [esp+ecx]
  add ebp, eax

  mov edx, dword ptr [RevInputLen]
  sub edx, 3
  mov eax, edi
  inc eax
  cmp eax, edx

  mov edx, ebp
  jae @A1
   call ScanNext
   jmp @A2
@A1:
   xchg eax, edx
   call ScanLast3
@A2:
  test eax, eax
  jz @A3
   mov eax, offset RevInput
   mov edx, offset RevDic
   add edx, ecx
   mov dl, byte ptr [edx]
   mov byte ptr [eax], dl

   xor eax, eax
   inc eax
   jmp @Finish

@A3:
  inc ecx
  cmp ecx, esi
 jb @Loop

 xor eax, eax
@Finish:
 mov esp, [ReservedESP]
 pop ebp
 pop ebx
 pop edi
 pop esi
end;

function Bruteforce: Boolean;
asm
 // edi - RevInputLen
 // esi - RevInput
 push esi
 push edi

 mov eax, offset RevDic
 call StrLen
 mov [RevDicLen], eax

 mov esi, offset RevInput
 mov eax, esi
 call StrLen
 mov [RevInputLen], eax

 sub eax, 7
 jns @AboveThanZero
  xor eax, eax

@AboveThanZero:
 mov byte ptr [eax+esi], 0

 mov eax, esi
 call RevHash

 mov edx, eax
 mov eax, edi
 call ScanNext

 pop edi
 pop esi
end;

function Spoofer_RevEmu(P: Pointer; SteamID: LongInt): Pointer;
asm
 mov [eax], 4Ah
 mov [eax+4], edx
 mov [eax+8], 726576h
 mov [eax+12], 0
 shr edx, 1
 mov [eax+16], edx
 mov [eax+20], 01001001h

 push eax

 

 pop eax

 // ...
end;

// Size = 10
function Spoofer_OldRevEmu(P: Pointer; SteamID: LongInt): Pointer;
asm
 mov word ptr [eax], 0FFFFh
 xor edx, 0C9710266h
 mov [eax+4], edx
end;

// Size = 768
function Spoofer_SteamEmu(P: Pointer; SteamID: LongInt): Pointer;
asm
 mov [eax+80], -1
 mov [eax+84], edx
end;

// Size = 28
function Spoofer_AVSMP(P: Pointer; SteamID: LongInt): Pointer;
asm
 mov [eax], 20
 shl edx, 1
 add eax, 12
 mov [eax], edx

 push edx // because "push 0" opcode needs 2 bytes
 mov edx, [cl_steamid_prefix]
 fld dword ptr [edx].cvar_t.Value
 fistp dword ptr [esp]
 pop edx

 dec edx
 jnz @DontNeedPrefix
  inc [eax]

@DontNeedPrefix:
end;

function Spoofer_CustomEmu(P: Pointer; SteamID: LongInt): Pointer;
asm
 shl edx, 1
 inc dl
 mov dword ptr [eax], 14h
 mov dword ptr [eax+12], edx // steamid
 mov dword ptr [eax+16], 01100001h
 mov dword ptr [eax+20], 55B64849h // ticket creation date (27 Jul 2015)
 mov dword ptr [eax+24], 0B2h
 mov dword ptr [eax+28], 32h
 mov dword ptr [eax+32], 4
 mov dword ptr [eax+36], edx // steamid
 mov dword ptr [eax+40], 01100001h
 mov dword ptr [eax+64], 55CE1986h // ticket expiration date (14 august, 2015)
end;

end.

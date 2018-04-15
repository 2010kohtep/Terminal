unit MemSearch;

{$I Default.inc}

interface

uses
 WindowsAPI, MsgAPI, CvarDef, ConsoleAPI, HLSDK, Common, Memory;

function AbsoluteToRel(BaseAddr, RelativeAddr: LongWord): LongWord; deprecated;
function Absolute(Addr: Pointer): LongWord; deprecated;
function Relative(Addr, NewFunc: LongWord): LongWord;
function Bounds: Boolean; deprecated;

function GetModuleSize(Address: LongWord): LongWord;

function CompareMemory(Address, Pattern: Pointer; Size: LongWord): Boolean; deprecated;

{function FindPattern: Pointer; assembler deprecated;}
procedure FindBytePattern(StartBase, EndBase: LongWord; Pattern: Pointer; PatternSize: LongWord); stdcall;
procedure FindAllRefCallAddr_Internal;
function FindAllRefCallAddr(BaseStart, BaseSize: LongWord; Func: Pointer): Pointer; stdcall;

function FindNextByte(Address: Pointer; Value: Byte; Offset: LongInt): Pointer;

procedure PatchByte(Addr: Pointer; B, B2: Byte);

procedure Fix_VirtualProtect;

procedure GetRendererInfo;
procedure GetClientInfo;

function FindEngineAndClient: Boolean;
function Initialized: Boolean;
procedure FindStudio;

procedure Patch_CL_ConnectionlessPacket;
function Find_UserMsgBase: Boolean;

procedure Find_CL_SendConnectPacket;
procedure Find_Steam_GSInitiateGameConnection; deprecated;
procedure Find_NET_SendPacket;
procedure Find_CL_CanUseHTTPDownload;
procedure Find_GameUI007;
procedure Find_cls_servername;
procedure Find__snprintf;
procedure Find_s_connection_challenge;
procedure Find_LocalInfo;
procedure Find_NET_StringToAddr;
procedure Find_SVCBase;
procedure Find_MSGInterface;
procedure Find_CL_GetCDKeyHash;
procedure Find_CmdBase;
procedure Find_PlayingDemo;
procedure Find_DemoHandler; // and cbuf_addtext!
procedure Find_Cmd_TokenizeString;
procedure Find_Cmd_Args;
procedure Find_IsSafeFileToDownload;
procedure Find_DemoCheckPath;
procedure Find_CL_CheckCommandBounds;
procedure Patch_CL_CheckCommandBounds;

implementation

uses
 Funcs;

const
 MAX_SEARCH_ATTEMPTS = 64;

function AbsoluteToRel(BaseAddr, RelativeAddr: LongWord): LongWord;
asm
 lea eax, [eax+edx+4]
end;

function Absolute(Addr: Pointer): LongWord;
asm
 add eax, [eax]
 add eax, 4
end;

function Relative(Addr, NewFunc: LongWord): LongWord;
asm
 xchg eax, edx
 add edx, 5
 sub eax, edx
end;

{
 -- RAW FUNCTION
 
 EAX - Address
 EDX - LowBound
 ECX - HighBound
 EBX - Align
}
function Bounds: Boolean;
asm
 cmp eax, edx
 jl @Bad
 cmp eax, ecx
 jg @Bad
 // cmp byte ptr [Align], 0
 test ebx, ecx
 jz @Exit
 and eax, $F
 jng @Exit

@Bad:
 xor eax, eax
 inc eax
 ret

@Exit:
 xor eax, eax
end;

function GetModuleSize(Address: LongWord): LongWord;
asm
 add eax, dword ptr [eax.TImageDosHeader._lfanew]
 mov eax, dword ptr [eax.TImageNtHeaders.OptionalHeader.SizeOfImage]
end;

// not checked
function CompareMemory(Address, Pattern: Pointer; Size: LongWord): Boolean;
asm
 push ebx

 test eax, eax
 jz @False
 test edx, edx
 jz @False
 test ecx, ecx
 jz @False

@Loop:
  mov bl, byte ptr [edx]
  cmp bl, byte ptr [eax]
  je @EndLoop
  sub bl, $FF
  jne @False

@EndLoop:
  inc eax
  inc edx
  dec ecx
 jnz @Loop

 xor eax, eax
 inc eax
 pop ebx
 ret

@False:
 xor eax, eax
 pop ebx
end;

{
 -- RAW FUNCTION

 EAX - Start address
 EBX - End address
 EDX - Pattern
 ECX - Pattern size
 ESI - Offset
}
{function FindPattern: Pointer; assembler;
asm
 test eax, eax
 jz @NotFound
 test ebx, ebx
 jz @NotFound
 test edx, edx
 jz @NotFound
 test ecx, ecx
 jz @NotFound

 sub ebx, ecx
 dec ebx

@Loop:
  push eax
  push edx
  push ecx
  call CompareMemory
  test eax, eax
  jnz @Found

  pop ecx
  pop edx
  pop eax

  inc eax
  cmp eax, ebx
  ja @NotFound
 jmp @Loop

@Found:
 pop ecx
 pop edx
 pop eax

 add eax, esi
 ret

@NotFound:
 xor eax, eax
end;}

procedure FindBytePattern(StartBase, EndBase: LongWord; Pattern: Pointer; PatternSize: LongWord); stdcall;
asm
 push edi
 push esi
 push ebx

 mov edi, [StartBase]
 mov edx, [EndBase]
 mov eax, [Pattern]
 mov al, [eax]
 inc [Pattern]
 dec [PatternSize]

@Next:
 mov ecx, edx
 repne scasb
 jne @NotFound

 mov edx, ecx
 mov ecx, [PatternSize]
 mov esi, [Pattern]
 mov ebx, edi

@Cont:
 repe cmpsb
 je @Found

 cmp byte ptr [esi - 1], 0FFh
 je @Cont

 mov edi, ebx
 jmp @Next

@NotFound:
 xor ebx, ebx
 inc ebx

@Found:
 lea eax, [ebx - 1]
 pop ebx
 pop esi
 pop edi
end;

// ==============================
// ** RAW (probably) **
//
// Result:
//  > eax - ref amount is found
//  > stack (1 eax = 1 push) - all ref addresses 
// Args:
//  > edi - start
//  > edx - address
//  > ecx - size
// Registers gonna be spoiled:
//  > ebx - internal variable
//  > esi - return address
//  > ebp - ref counter
// ==============================
procedure FindAllRefCallAddr_Internal;
asm
 pop esi

 xor ebp, ebp

 sub edx, 4
 mov al, 0E8h

@Loop:
  repne scasb
  jne @Break

  mov ebx, edx
  sub ebx, edi
  cmp dword ptr [edi], ebx
  jne @NotFound
   dec edi
   push edi
   inc ebp

@NotFound:
  add edi, 4
  sub ecx, 4
 jmp @Loop

@Break:
 xchg ebp, eax
 jmp esi
end;

function FindAllRefCallAddr(BaseStart, BaseSize: LongWord; Func: Pointer): Pointer; stdcall;
asm
 pushad

 mov edi, [BaseStart]
 mov ecx, [BaseSize]
 mov edx, [Func]
 call FindAllRefCallAddr_Internal

 mov edi, eax // ref count
 
 mov eax, 8
 call calloc

 mov ebx, eax // result pointer
 mov dword ptr [ebx], edi // save ref count to result

 mov edx, ebx

 lea eax, [edi*4]
 call calloc
 xchg esi, eax
@Loop:
  dec edi
  js @Break

  pop [esi]
  add esi, type Pointer
 jmp @Loop

@Break:
 mov dword ptr [ebx+4], esi
 popad
end;
{procedure FindAllRefCallAddr(Start, Size, Address: LongWord); cdecl;
asm
 sub edx, 4
 mov al, 0E8h

@Loop:
  repne scasb
  jne @NotFound

  mov ebx, edx
  sub ebx, edi
  cmp dword ptr [edi], ebx
  je @Found

  add edi, 4
  sub ecx, 4
 jmp @Loop

@NotFound:
 xor edi, edi
 inc edi

@Found:
 lea eax, [edi - 1]
end;}

// not checked
function FindNextByte(Address: Pointer; Value: Byte; Offset: LongInt): Pointer;
asm
 test eax, eax
 jz @NotFound

 push ebx
 mov ebx, MAX_SEARCH_ATTEMPTS
@Loop:
  cmp dl, byte ptr [eax]
  je @Found

  inc eax
  dec ebx
 jnz @Loop

 xor eax, eax

@Found:
 pop ebx
 ret

@NotFound:
 xor eax, eax
end;

// not checked
procedure PatchByte(Addr: Pointer; B, B2: Byte);
const
 sPatchByteError: PChar = 'PatchByte: Current address is not consists needed required byte.';
asm
 test eax, eax
 jz @Bad

 cmp cl, 0FFh
 jne @SkipByteCheck
 cmp cl, byte ptr [edx]
 je @SkipByteCheck

 mov eax, sPatchByteError
 jmp RaiseError

@SkipByteCheck:
 push esp
 push esp
 push PAGE_EXECUTE_READWRITE
 push 1
 push eax
 call VirtualProtect

 mov byte ptr [eax], cl

 push [esp]
 push 1
 push eax
 call VirtualProtect

@Bad:
end;

procedure Fix_VirtualProtect;
asm
 lea edx, [WindowsAPI.VirtualProtect]
 mov edx, [edx+2]
 mov edx, [edx]
 mov al, byte ptr [edx]
 cmp al, 0E9h

 jne @Exit
  mov [edx], 0FF8B55ECh
  inc edx
  mov byte ptr [edx], 8Bh

@Exit:
end;

procedure GetRendererInfo;
const
 sHW: PChar = 'hw.dll';
 sSW: PChar = 'sw.dll';
 sError: PChar = 'Invalid module handle.';
 sRendererBadSize: PChar = 'Failed to determine the renderer module size; using pre-defined constants.';
asm
@TryHW:
 push sHW
 call GetModuleHandle
 test eax, eax
 jnz @GoodHW

@TrySW:
 push sSW
 call GetModuleHandle
 test eax, eax
 jnz @GoodSW

@TrySteam:
 push 0
 call GetModuleHandle
 test eax, eax
 jnz @GoodSteam

 push sError
 jmp RaiseError

@GoodHW:
 mov byte ptr [RendererType], 2
 jmp @Success

@GoodSW:
 mov byte ptr [RendererType], 1
 jmp @Success

@GoodSteam:
 mov byte ptr [RendererType], 0

@Success:
 mov dword ptr [HLBase], eax
 call GetModuleSize

 test eax, eax
 jnz @WriteGoodDLLSize
  push sRendererBadSize
  call Print

  cmp byte ptr [RendererType], 0
  je @SetSizeSteam

  cmp byte ptr [RendererType], 1
  je @SetSizeSW

  cmp byte ptr [RendererType], 2
  je @SetSizeHW

@SetSizeSteam:
  mov [HLBaseSize], 2116000h
  jmp @SetProtocol

@SetSizeHW:
  mov [HLBaseSize], 122A000h
  jmp @SetProtocol

@SetSizeSW:
  mov [HLBaseSize], 0B53000h
  jmp @SetProtocol
  
@WriteGoodDLLSize:
 mov dword ptr [HLBaseSize], eax

@SetProtocol:
 cmp byte ptr [RendererType], 0
 je @Skip
  inc [Protocol]

@Skip:
 mov eax, dword ptr [HLBase]
 add eax, [HLBaseSize]
 dec eax
 mov [HLBaseEnd], eax 
end;

procedure GetClientInfo;
const
 sDLLName: PChar = 'client.dll';
 sClientFindError: PChar = 'Failed to find client module.';
asm
 push sDLLName
 call GetModuleHandle
 test eax, eax
 jnz @GoodDLL
  mov eax, sClientFindError
  jmp RaiseError

@GoodDLL:
 mov [CLBase], eax
 call GetModuleSize
 test eax, eax
 jnz @GoodSize
  mov eax, 159000h
  
@GoodSize:
 mov [CLBaseSize], eax

 add eax, [CLBaseSize]
 dec eax
 mov [CLBaseEnd], eax
end;

function FindEngineAndClient: Boolean;
const
 sEngineString: PChar = 'ScreenShake';
asm
 push ebx
 push esi

 push 11
 push sEngineString
 push [HLBaseSize]
 push [HLBase]
 call FindBytePattern

 test eax, eax
 jz @Exit

 mov edx, offset Pattern_Engine
 add edx, 14
 mov [edx], eax

 push 19
 push offset Pattern_Engine
 push [HLBaseSize]
 push [HLBase]
 call FindBytePattern

 test eax, eax
 jz @Exit

 add eax, 13
 mov edx, eax

 add eax, 6
 add eax, [eax]
 add eax, 4
 mov [HookServerMsg], eax

 mov eax, edx
 add eax, 26
 mov byte ptr [ClientVersion], al

 mov eax, edx
 mov eax, [eax+28]
 mov [PEngine], eax

 mov eax, edx
 mov eax, [eax+34]
 mov [PClient], eax

 xor eax, eax
 inc eax

@Exit:
 pop esi
 pop ebx
end;

function Initialized: Boolean;
asm
 mov ecx, PClient // start
 lea edx, [eax+type exporttable_t-9] // end

 jmp @SkipFirstInc

@Loop:
  inc ecx

@SkipFirstInc:
  test ecx, 3
 jnbe @Loop

 xor eax, eax

 cmp [ecx], 1
 jle @NotInited
  inc eax

@NotInited:
end;

procedure FindStudio;
const
 sStudioString: PChar = 'Couldn''t get client .dll studio model rendering interface.';
asm
 push ebx
 push edi
 push esi

 push 58
 push sStudioString
 push [HLBaseSize]
 push [HLBase]
 call FindBytePattern

 mov edx, offset Pattern_Studio
 mov [edx+8], eax

 push 20
 push offset Pattern_Studio
 push [HLBaseSize]
 push [HLBase]
 call FindBytePattern
 sub eax, 13

 mov edx, eax
 mov al, [eax+10]
 mov byte ptr [StudioVersion], al

 mov eax, [edx]
 mov [PStudio], eax

 mov eax, edx
 mov eax, [eax+5]
 mov [PStudioInterface], eax

 pop esi
 pop edi
 pop ebx
end;

procedure Patch_CL_ConnectionlessPacket;
const
 Pattern: array[0..9] of Byte = ($75, $FF,
                                 $83, $EC, $14,
                                 $B9, $05, $00, $00, $00);
 sErrorStr: PChar = 'Failed to patch CL_ConnectionlessPacket.';
asm
 push ebx
 push esi
 push edi

 push 10
 push offset @Pattern
 push [HLBaseSize]
 push [HLBase]
 call FindBytePattern

 test eax, eax
 jnz @GoodByte

@Error:
  mov eax, sErrorStr
  jmp RaiseError

@GoodByte:
 cmp byte ptr [eax], 75h
 jne @Error

 mov esi, eax
 mov ebx, 0EBh
 call WriteByteToAddr

 pop edi
 pop esi
 pop ebx

 ret

@Pattern:
 db 75h, 0FFh
 db 83h, 0ECh, 14h
 db 0B9h, 05, 00, 00, 00
end;

function Find_UserMsgBase: Boolean;
const
 Pattern: array[0..1] of Byte = ($8B, $35);
asm
 push type Pattern
 push offset Pattern
 push [HLBaseEnd]
 push [HookServerMsg]
 call FindBytePattern
 add eax, 2

 mov eax, [eax]
 mov eax, [eax]
 mov [UserMsgBase], eax
end;

procedure Find_CL_SendConnectPacket;
const
 sSearchError: PChar = 'Failed to find CL_SendConnectPacket pointer.';
 Pattern: array[0..14] of Byte = ($83, $C4, $0C,
                                  $88, $1D, $FF, $FF, $FF, $FF,
                                  $C6, $05, $FF, $FF, $FF, $FF);
asm
 push type Pattern
 push offset Pattern
 push [HLBaseSize]
 push [HLBase]
 call FindBytePattern

 test eax, eax
 jnz @GoodByte
  mov eax, sSearchError
  jmp RaiseError

@GoodByte:
 add eax, 17
 add eax, [eax]
 add eax, 4

 mov [CvarDef.CL_SendConnectPacket], eax
end;

procedure Find_Steam_GSInitiateGameConnection;
const
 Pattern: array[0..15] of Byte = ($52,
                                  $8B, $15, $FF, $FF, $FF, $FF,
                                  $51,
                                  $50,
                                  $A1, $FF, $FF, $FF, $FF,
                                  $52,
                                  $50);
asm
 push type Pattern
 push offset Pattern
 push [HLBaseEnd]
 push [HLBase]
 call FindBytePattern

 add eax, 27
 cmp byte ptr [eax], 0E8h
 je @GoodByte
  inc eax

@GoodByte:
 inc eax

 add eax, [eax]
 add eax, 4
end;

procedure Find_NET_SendPacket;
const
 sSearchError: PChar = 'Failed to find NET_SendPacket pointer.';
 Pattern: array[0..6] of Byte = ($52,
                                 $50,
                                 $0F3, $A5,
                                 $06A, $01,
                                 $E8);
asm
 push type Pattern
 push offset Pattern
 push [HLBaseEnd]
 push [HLBase]
 call FindBytePattern

 test eax, eax
 jnz @GoodByte
  mov eax, sSearchError
  jmp RaiseError

@GoodByte:
 add eax, 7
 add eax, [eax]
 add eax, 4
 mov [CvarDef.NET_SendPacket], eax
end;

procedure Find_CL_CanUseHTTPDownload;
const
 sSearchError: PChar = 'Failed to find CL_CanUseHTTPDownload pointer!';
 Pattern: array[0..9] of Byte = ($A1, $FF, $FF, $FF, $FF,
                                   $85, $C0,
                                   $75, $52,
                                   $E8);
asm
 push type Pattern
 push offset Pattern
 push [HLBaseEnd]
 push [HLBase]
 call FindBytePattern

 test eax, eax
 jnz @GoodPattern
  mov eax, sSearchError
  jmp RaiseError

@GoodPattern:
 add eax, 10
 add eax, [eax]
 add eax, 4

 mov [CvarDef.CL_CanUseHTTPDownload], eax
end;

{procedure Find_cls_servername;
asm
 mov eax, [CL_CanUseHTTPDownload]
 add eax, 14

 cmp byte ptr [eax], 68h
 je @GoodByte
  mov eax, offset @SearchError
  jmp RaiseError

@GoodByte:
 inc eax
 mov eax, [eax]
 mov [cls_servername], eax

 ret
@SearchError:
 db 'Failed to find cls_servername pointer!',0
end;}

procedure Find_GameUI007;
const
 sSearchError: PChar = 'Failed to find GameUI007 pointer!';
 Pattern: array[0..0] of Byte = ($E8);
asm
 mov eax, [CvarDef.CL_SendConnectPacket]
 add eax, 43

 push type Pattern
 push offset Pattern
 push [HLBaseSize]
 push eax
 call FindBytePattern

 test eax, eax
  jz @Error

@Found:
 cmp byte ptr [eax], 0E8h
 je @GoodByte
@Error:
  mov eax, sSearchError
  jmp RaiseError

@GoodByte:
 inc eax
 add eax, [eax]
 add eax, 4

 cmp byte ptr [eax], 8Bh
 je @SecondGoodByte
 cmp byte ptr [eax], 55h
 je @SoftwareMode
  mov eax, sSearchError
  jmp RaiseError

@SoftwareMode:
 add eax, 3
@SecondGoodByte:
 add eax, 2
 mov eax, [eax]

 mov edx, eax
 add edx, type Pointer
 mov edx, [edx]
 mov [CvarDef.GameConsole003], edx

 mov eax, [eax]
 mov [CvarDef.GameUI007], eax
end;

procedure Find_cls_servername;
const
 sSearchError: PChar = 'Failed to find cls_servername pointer!';
 Pattern: array[0..6] of Byte = ($68, $03, $01, $00, $00,
                                 $50,
                                 $68);
asm
 push type Pattern
 push offset Pattern
 push [HLBaseSize]
 push [HLBase]
 call FindBytePattern

 test eax, eax
 jnz @GoodByte
  mov eax, sSearchError
  jmp RaiseError

@GoodByte:
 add eax, 7
 mov eax, [eax]
 mov [CvarDef.cls_servername], eax
end;

procedure Find__snprintf;
const
 sSearchError: PChar = 'Failed to find _snprintf pointer.';
 Pattern: array[0..3] of Byte = ($6A, $0A,
                                 $51,
                                 $E8);
asm
 push type Pattern
 push offset Pattern
 push [HLBaseSize]
 push [HLBase]
 call FindBytePattern

 test eax, eax
 jnz @GoodByte
  mov eax, sSearchError
  jmp RaiseError

@GoodByte:
 add eax, 4
 add eax, [eax]
 add eax, 4

 mov [CvarDef._snprintf], eax
end;

procedure Find_s_connection_challenge;
const
 sSearchError: PChar = 'Failed to find s_connection_challenge pointer.';
 Pattern: array[0..14] of Byte = ($6A, $01,
                                 $E8, $FF, $FF, $FF, $FF,
                                 $50,
                                 $E8, $FF, $FF, $FF, $FF,
                                 $53,
                                 $A3);
asm
 push type Pattern
 push offset Pattern
 push [HLBaseSize]
 push [HLBase]
 call FindBytePattern

 test eax, eax
 jz @Error

@Found:
 add eax, 14
 cmp byte ptr [eax], 0A3h
 je @GoodByte
@Error:
  mov eax, sSearchError
  jmp RaiseError

@GoodByte:
 inc eax
 mov eax, [eax]
 mov [CvarDef.s_connection_challenge], eax
end;

procedure Find_LocalInfo;
const
 sSearchError: PChar = 'Failed to find LocalInfo pointer.';
 Pattern: array[0..4] of Byte = ($3C, $5C,
                                 $75, $05, $BE);
asm
 push type Pattern
 push offset Pattern
 push [HLBaseSize]
 push [HLBase]
 call FindBytePattern

 test eax, eax
 jz @Error

@Found:
 sub eax, 11
 cmp byte ptr [eax], 0A0h
 je @GoodByte
@Error:
  mov eax, sSearchError
  jmp RaiseError

@GoodByte:
 inc eax
 mov eax, [eax]
 mov [CvarDef.LocalInfo], eax
end;

procedure Find_NET_StringToAddr;
const
 sSearchError: PChar = 'Failed to find NET_StringToAddr pointer.';
 Pattern: array[0..9] of Byte = ($E8, $FF, $FF, $FF, $FF,
                                 $83, $C4, $38,
                                 $85, $C0);
asm
 push type Pattern
 push offset Pattern
 push [HLBaseSize]
 push [HLBase]
 call FindBytePattern

 test eax, eax
 jnz @Found
  mov eax, sSearchError
  jmp RaiseError
  
@Found:
 inc eax
 add eax, [eax]
 add eax, 4

 mov [CvarDef.NET_StringToAddr], eax
end;

procedure Find_SVCBase;
const
 sSearchError: PChar = 'Failed to find SVCBase pointer.';
 Pattern: array[0..5] of Byte = ($83, $C4, $04,
                                 $33, $F6,
                                 $BF);
asm
 push type Pattern
 push offset Pattern
 push [HLBaseSize]
 push [HLBase]
 call FindBytePattern

 test eax, eax
 jnz @Found
@Error:
  mov eax, sSearchError
  jmp RaiseError

@Found:
 add eax, 5
 cmp byte ptr [eax], 0BFh
 jne @Error
 inc eax

 mov edx, eax
 mov eax, [eax]
 sub eax, type Pointer
 mov [CvarDef.SVCBase], eax

 add edx, 17
 mov edx, [edx]

 mov [CvarDef.SVCBase_End], edx

 sub edx, eax
 mov eax, edx

 mov ecx, type server_msg_t
 cdq
 div ecx

 mov [CvarDef.SVCCount], eax
end;

procedure Find_MSGInterface;
const
 sErrorText: PChar = 'SVCBase is not found yet.';
 sErrorStuffText: PChar = 'Failed to find MSG_ReadString pointer.';
 sErrorLightStyle: PChar = 'Failed to find MSG_ReadByte pointer.';
 sErrorReadCount: PChar = 'Failed to find MSG_ReadCount pointer.';
asm
 cmp [CvarDef.SVCBase], 0
 jnz @GoodSVCBase
  mov eax, sErrorText
  jmp RaiseError
  
@GoodSVCBase:
 mov eax, HLSDK.SVC_STUFFTEXT
 mov ecx, [CvarDef.SVCBase]

 lea eax, [eax + eax * 2]
 lea ecx, [ecx + eax * 4 + 8] 

 push esi
 mov esi, ecx

 mov eax, [ecx]
 inc eax

 cmp byte ptr [eax], 0E8h
 je @GoodB1
  mov eax, sErrorStuffText
  jmp RaiseError
  
@GoodB1:
 inc eax
 add eax, [eax]
 add eax, 4

 mov [CvarDef.MSG_ReadString], eax

 add esi, 36 // svc_lightstyle.Callback
 mov eax, [esi]

 add eax, 2
 cmp byte ptr [eax], 0E8h
 je @GoodB2
  mov eax, sErrorStuffText
  jmp RaiseError

@GoodB2:
 inc eax
 add eax, [eax]
 add eax, 4

 mov [CvarDef.MSG_ReadByte], eax

 add eax, 41
 cmp word ptr [eax], 0D89h
 je @GoodB3
  mov eax, sErrorReadCount
  jmp RaiseError
  
@GoodB3:
 add eax, 2
 mov eax, [eax]
 mov [CvarDef.MSG_ReadCount], eax

 pop esi
end;

procedure Find_CL_GetCDKeyHash;
const
 Pattern: array[0..6] of Byte = ($C6, $05, $FF, $FF, $FF, $FF, $02);
 sSearchError: PChar = 'Failed to find CL_GetCDKeyHash pointer.';
asm
 push type Pattern
 push offset Pattern
 push [HLBaseSize]
 push [CvarDef.CL_SendConnectPacket]
 call FindBytePattern

 test eax, eax
 jnz @GoodByte
  mov eax, sSearchError
  jmp RaiseError

@GoodByte:
 add eax, 8
 add eax, [eax]
 add eax, 4
 mov [CvarDef.CL_GetCDKeyHash], eax
end;

procedure Find_CmdBase;
const
 Pattern: array[0..3] of Byte = ($F3, $AB,
                                 $89, $15);
 sSearchError: PChar = 'Failed to find CmdBase pointer.';
asm
 push type Pattern
 push offset Pattern
 push [HLBaseSize]
 push [HLBase]
 call FindBytePattern

 test eax, eax
 jnz @GoodByte
  mov eax, sSearchError
  jmp RaiseError

@GoodByte:
 add eax, 4
 mov eax, [eax]
 mov [CvarDef.CmdBase], eax
end;

procedure Find_PlayingDemo;
const
 Pattern: array[0..11] of Byte = ($33, $FF,
                                  $3B, $C7,
                                  $0F, $85, $FF, $FF, $FF, $FF,
                                  $39, $3D);
 sSearchError: PChar = 'Failed to find PlayingDemo pointer.';
asm
 push type Pattern
 push offset Pattern
 push [HLBaseSize]
 push [HLBase]
 call FindBytePattern

 test eax, eax
 jnz @GoodByte
  mov eax, sSearchError
  jmp RaiseError

@GoodByte:
 add eax, 12
 mov eax, [eax]
 mov [CvarDef.PlayingDemo], eax
end;

procedure Find_DemoHandler;
const
 Pattern: array[0..5] of Byte = ($51,
                                 $57,
                                 $6A, $40,
                                 $52,
                                 $E8);
 sSearchError: PChar = 'Failed to find MSGID_COMMAND handler.';
asm
 push type Pattern
 push offset Pattern
 push [HLBaseSize]
 push [HLBase]
 call FindBytePattern

 test eax, eax
 jnz @GoodByte
  mov eax, sSearchError
  jmp RaiseError

@GoodByte:
 add eax, 14
 cmp byte ptr [eax], 0E8h
 je @NoNeedToFixOffset
  inc eax

 cmp byte ptr [eax], 0E8h
 je @AnotherGoodByte
  mov eax, sSearchError
  jmp RaiseError

@NoNeedToFixOffset:
@AnotherGoodByte:
 inc eax
 mov [CvarDef.DemoCmdsHandler], eax
 add eax, [eax]
 add eax, 4
 mov [CvarDef.CBuf_AddText], eax
end;

procedure Find_Cmd_TokenizeString;
const
 Pattern: array[0..13] of Byte = ($A3, $FF, $FF, $FF, $FF,
                                  $E8, $FF, $FF, $FF, $FF,
                                  $83, $C4, $04, $E8);
 sSearchError: PChar = 'Failed to find Cmd_TokenizeString pointer.';
asm
 push type Pattern
 push offset Pattern
 push [HLBaseSize]
 push [HLBase]
 call FindBytePattern

 test eax, eax
 jnz @GoodByte
  mov eax, sSearchError
  jmp RaiseError

@GoodByte:
 add eax, 6
 add eax, [eax]
 add eax, 4
 mov [CvarDef.Cmd_TokenizeString], eax
end;

procedure Find_Cmd_Args;
const
 Pattern: array[0..4] of Byte = ($66, $89, $4F, $FF,
                                 $E8);
 sSearchError: PChar = 'Failed to find Cmd_Args pointer.';
asm
 push type Pattern
 push offset Pattern
 push [HLBaseSize]
 push [HLBase]
 call FindBytePattern

 test eax, eax
 jnz @GoodByte
  mov eax, sSearchError
  jmp RaiseError

@GoodByte:
 add eax, 5
 add eax, [eax]
 add eax, 4
 mov [CvarDef.Cmd_Args], eax
end;

procedure Find_IsSafeFileToDownload;
const
 Pattern: array[0..7] of Byte = ($56,
                                 $0F, $85, $FF, $FF, $FF, $FF,
                                 $E8);
 sSearchError: PChar = 'Failed to find IsSafeFileToDownload pointer.';
asm
 push type Pattern
 push offset Pattern
 push [HLBaseSize]
 push [HLBase]
 call FindBytePattern

 test eax, eax
 jnz @GoodByte
  mov eax, sSearchError
  jmp RaiseError

@GoodByte:
 sub eax, 9
 add eax, [eax]
 add eax, 4
 mov [CvarDef.IsSafeFileToDownload], eax
end;

procedure Find_DemoCheckPath;
const
 Pattern: array[0..13] of Byte = ($81, $C4, $18, $03, $00, $00,
                                 $C3, $68, $FF, $FF, $FF, $FF,
                                 $6A, $01);
 sSearchError: PChar = 'Failed to find Demo_Record_f pointer.';
asm
 push type Pattern
 push offset Pattern
 push [HLBaseSize]
 push [HLBase]
 call FindBytePattern

 test eax, eax
 jnz @GoodByte
  mov eax, sSearchError
  jmp RaiseError

@GoodByte:
 add eax, 15
 mov [CvarDef.DemoCheckPath], eax
end;

procedure Find_CL_CheckCommandBounds;
const
 Pattern: array[0..10] of Byte = ($56,
                                  $E8, $FF, $FF, $FF, $FF,
                                  $8A, $FF, $FF, $FF, $FF);
 sSearchError: PChar = 'Failed to find CL_CheckCommandBounds pointer.';
asm
 push type Pattern
 push offset Pattern
 push [HLBaseSize]
 push [HLBase]
 call FindBytePattern

 test eax, eax
 jnz @GoodByte
  mov eax, sSearchError
  jmp RaiseError

@GoodByte:
 add eax, [eax+2]
 add eax, 6
 mov [CvarDef.CL_CheckCommandBounds], eax
end;

procedure Patch_CL_CheckCommandBounds;
const
 LowUpdateRate: array[0..1] of Byte = ($74, $23);
 HighpdateRate: array[0..1] of Byte = ($75, $23);
 sPatchError: PChar = 'Failed to patch CL_CheckCommandBounds pointer.';
asm
 push edi

 mov edi, [CvarDef.CL_CheckCommandBounds]

 push type LowUpdateRate
 push offset LowUpdateRate
 push [HLBaseSize]
 push edi
 call FindBytePattern

 test eax, eax
 jnz @Good1
  mov eax, sPatchError
  jmp RaiseError
  
@Good1:
 mov edi, eax

 push esp
 push esp
 push PAGE_EXECUTE_READWRITE
 push 1
 push edi
 call VirtualProtect

 mov byte ptr [edi], 0EBh

 push [esp]
 push 1
 push edi
 call VirtualProtect

 pop edi
end;

{API}

function GetRendererLibBase: LongWord;
asm
 mov eax, [CvarDef.HLBase]
end;

function GetRendererLibSize: LongWord;
asm
 mov eax, [CvarDef.HLBaseSize]
end;

function GetRendererLibEnd: LongWord;
asm
 mov eax, [CvarDef.HLBaseSize]
end;

function GetClientLibBase: LongWord;
asm
 mov eax, [CvarDef.CLBase]
end;

function GetClientLibSize: LongWord;
asm
 mov eax, [CvarDef.CLBaseSize]
end;

function GetClientLibEnd: LongWord;
asm
 mov eax, [CvarDef.CLBaseEnd]
end;

function GetOrigEnginePtr: LongWord;
asm
 mov eax, offset CvarDef.Engine
end;

function GetSVCBasePtr: LongWord;
asm
 mov eax, [CvarDef.SVCBase]
end;

{/API}

exports
 FindBytePattern name 'FindBytePattern',
 FindAllRefCallAddr name 'FindAllRefCallAddr',

 // Renderer funcs
 GetRendererLibBase,
 GetRendererLibSize,
 GetRendererLibEnd,

 // Engine funcs
 GetOrigEnginePtr,
 GetSVCBasePtr;

end.

unit Hooks;

{$I Default.inc}

interface

uses
 CvarDef, Memory, MemSearch, Funcs, WindowsAPI, HLSDK, MsgAPI, Common;

function HookServerMsgByIndex(Index: LongWord; Callback: TCallback): TCallback;
function HookServerMsgByName(Name: PChar; Callback: Pointer): Pointer;

procedure Hook_CL_SendConnectPacket;
procedure Hook_DemoHandler;
procedure Hook_DemoCheckPath;

implementation

function HookServerMsgByIndex(Index: LongWord; Callback: TCallback): TCallback;
const
 sErrorText1: PChar = 'HookServerMsgByIndex: Invalid message index.';
 sErrorText2: PChar = 'HookServerMsgByIndex: Invalid callback.';
asm
 cmp eax, [CvarDef.SVCCount]
 jnae @GoodIndex
  mov eax, sErrorText1
  jmp RaiseError

@GoodIndex:
 test edx, edx
 jnz @GoodCallback
  mov eax, sErrorText2
  jmp RaiseError

@GoodCallback:
 mov ecx, [CvarDef.SVCBase]

 lea eax, [eax + eax * 2]
 lea ecx, [ecx + eax * 4 + 8]

 mov eax, [ecx]
 mov [ecx], edx
end;

function HookServerMsgByName(Name: PChar; Callback: Pointer): Pointer;
const
 sErrorText1: PChar = 'HookServerMsgByName: Invalid message name.';
 sErrorText2: PChar = 'HookServerMsgByName: Invalid callback.';
 sErrorText3: PChar = 'HookServerMsgByName: Failed to find "%s" message pointer.';
asm
 test eax, eax
 jnz @GoodName
  mov eax, sErrorText1
  jmp RaiseError

@GoodName:
 test edx, edx
 jnz @GoodCallback
  mov eax, sErrorText2
  jmp RaiseError

@GoodCallback:
 push edx
 push eax

 call ServerMsgByName
 test eax, eax
 jnz @MessageIsFound
  mov eax, 96
  call malloc

  mov edx, sErrorText3
  mov ecx, 37
  call memcpy

  push eax
  call _snprintf
  // don't need to clear stack because fatal error is cumin'

  jmp RaiseError
@MessageIsFound:
 pop edx
 pop edx

 mov ecx, [eax].server_msg_t.Callback
 mov ecx, [ecx]

 mov [eax].server_msg_t.Callback, edx
 
 mov eax, ecx
end;

procedure Hook_CL_SendConnectPacket;
asm
 pushad

 mov edi, [HLBase]
 mov edx, [CvarDef.CL_SendConnectPacket]
 mov ecx, [HLBaseSize]
 call FindAllRefCallAddr_Internal

 mov edi, offset CL_SendConnectPacket_Our
 xchg esi, eax
@Loop:
 dec esi
 js @Break

 pop ebp

{ mov edi, offset DemoFilter
 mov ebp, [CvarDef.DemoCmdsHandler]
 sub edi, ebp
 sub edi, 4}

 mov ebx, edi
 sub ebx, ebp
 sub ebx, 5

 push esp
 push esp
 push PAGE_EXECUTE_READWRITE
 push 5
 push ebp
 call VirtualProtect_Internal

 mov dword ptr [ebp+1], ebx

 push PAGE_EXECUTE_READWRITE
 push 5
 push ebp
 call VirtualProtect_Internal

 jmp @Loop
@Break:

 popad
end;

{procedure Hook_CL_SendConnectPacket;
asm
 push ebx

 mov eax, 14 + 5
 call malloc

 mov ebx, [CvarDef.CL_SendConnectPacket]

 mov edx, ebx
 mov ecx, 14
 call memcpy

 mov edx, ebx
 sub edx, eax
 sub edx, 5

 mov byte ptr [eax+14], 0E9h
 mov dword ptr [eax+15], edx

 push esp
 push esp
 push PAGE_EXECUTE_READWRITE
 push 5
 push ebx
 call VirtualProtect_Internal

 mov eax, offset CL_SendConnectPacket_Our
 mov edx, eax
 sub edx, ebx
 sub edx, 5

 mov byte ptr [ebx], 0E9h
 mov dword ptr [ebx+1], edx

 push esp
 push [esp+4]
 push 5
 push ebx
 call VirtualProtect_Internal

 pop ebx
 pop ebx
end;}

procedure Hook_DemoHandler;
asm
 push esi
 push edi

 mov esi, offset DemoFilter
 mov edi, [CvarDef.DemoCmdsHandler]

 push esp
 push esp
 push PAGE_EXECUTE_READWRITE
 push type Pointer
 push edi
 call VirtualProtect_Internal
 //call VirtualProtect

 sub esi, edi
 sub esi, 4

 mov dword ptr [edi], esi

 push [esp]
 push type Pointer
 push edi
 call VirtualProtect_Internal

 pop edi
 pop esi
end;

procedure Hook_DemoCheckPath;
const
 Pattern: array[0..2] of Byte = ($51,
                                 $52,
                                 $E8);
 sErrorText: PChar = 'Failed to patch demo name pattern.';
asm
 push edi
 push esi

 mov edi, [CvarDef.DemoCheckPath]
 mov esi, offset DemoCheckPath_Our
 sub esi, edi
 sub esi, 4

 push esp
 push esp
 push PAGE_EXECUTE_READWRITE
 push type Pointer
 push edi
 call VirtualProtect_Internal

 mov dword ptr [edi], esi

 push [esp]
 push PAGE_EXECUTE_READWRITE
 push type Pointer
 push edi
 call VirtualProtect_Internal
 pop eax

 push type Pattern
 push offset Pattern
 push [HLBaseSize]
 push edi
 call FindBytePattern

 test eax, eax
 jnz @GoodByte
  mov eax, sErrorText
  jmp RaiseError

@GoodByte:
 lea esi, [eax+2]

 push esp
 push esp
 push PAGE_EXECUTE_READWRITE
 push 5
 push esi
 call VirtualProtect_Internal

 mov byte ptr [esi], 90h
 mov dword ptr [esi+1], 90909090h

 push [esp]
 push PAGE_EXECUTE_READWRITE
 push 5
 push esi
 call VirtualProtect_Internal
 pop eax

 pop esi
 pop edi
end;

exports
 HookServerMsgByIndex,
 HookServerMsgByName;

end.

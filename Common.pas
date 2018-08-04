unit Common;

{$I Default.inc}

interface

uses
 CvarDef, HLSDK, Strings, MsgAPI, WindowsAPI, Memory;

procedure atoi; assembler;
procedure COM_ShowConsole;
function UserMsgByName(Name: PChar): user_msg_s;
function HookUserMessage(Name: PChar; Callback: TUserMsgHook): TUserMsgHook;
function ServerMsgByName(Name: PChar): server_msg_s;
procedure MSG_SaveReadCount;
procedure MSG_RestoreReadCount;
// procedure LoadBlackList;
procedure IsBadCmdLite; assembler;

procedure Cmd_Inject;
procedure Cmd_Test;
procedure Cmd_HTTP_Open;
// procedure Cmd_Blacklist;

implementation

{ -- RAW FUNCTION

  ECX - String
}
procedure atoi; assembler;
asm
 xor eax, eax
 xor edx, edx

@Loop:
  mov dl, byte ptr [ecx]
  test dl, dl
   jz @Ret

  sub dl, '0'
  cmp dl, 9
   ja @Invalid
  imul eax, eax, 10
   jo @Invalid
  add eax, edx
  inc ecx
 jmp @Loop

@Invalid:
 xor eax, eax
@Ret:
end;

procedure COM_ShowConsole;
asm
 mov ecx, [GameConsole003]
 mov eax, [ecx]

 call eax.VGameConsole003.IsConsoleVisible
 dec al
 jz @Exit

 push offset @Cmd
 call dword ptr [Engine.ClientCmd]
 pop eax

@Exit:
 ret

@Cmd:
 db 'toggleconsole',0
end;

function UserMsgByName(Name: PChar): user_msg_s;
asm
 cmp [UserMsgBase], 0
 jne @GoodUserMsgBase
  xor eax, eax
  ret

@GoodUserMsgBase:
 push edi // NameStr
 push esi // NameLen
 mov edi, eax
 call StrLen
 mov esi, eax

 mov edx, [UserMsgBase]
@Loop:
 cmp [edx.user_msg_t.Next], 0 // Result.Next
 je @ResultFalse

 mov eax, edi
 add edx, 8
 mov ecx, esi
 call StrLComp
 
 cmp eax, 0
 je @ResultTrue

 add edx, 16
 mov edx, [edx]
 jmp @Loop

@ResultTrue:
 sub edx, 8
 mov eax, edx
 pop esi
 pop edi
 ret

@ResultFalse:
 xor eax, eax

@Exit:
 pop esi
 pop edi
 ret
end;

function HookUserMessage(Name: PChar; Callback: TUserMsgHook): TUserMsgHook;
const
 sInvalidCallback: PChar = 'HookUserMessage: Invalid callback.';
 sFailedToFind: PChar = 'Failed to find message pointer.';
asm
 test edx, edx
 jnz @GoodCallback
  mov eax, sInvalidCallback
  jmp RaiseError

@GoodCallback:
 push edx
 call UserMsgByName
 test eax, eax
 jnz @GoodAddr
  mov eax, sFailedToFind
  jmp RaiseError
 
@GoodAddr:
 pop edx
 mov ecx, [eax].user_msg_t.Callback
 mov [eax].user_msg_t.Callback, edx
 xchg ecx, eax
end;

function ServerMsgByName(Name: PChar): server_msg_s;
asm
 push esi
 push edi
 push ebx

 mov ebx, eax
 mov esi, [CvarDef.SVCCount]
 mov edi, [CvarDef.SVCBase]
@Loop:
  mov eax, ebx
  mov edx, [edi].server_msg_t.Name
  call StrComp

  test eax, eax
  jne @NotValid
   mov eax, edi
   jmp @Finish

@NotValid:
  dec esi
 jnz @Loop

 xor eax, eax
@Finish:
 pop ebx
 pop edi
 pop esi
end;

procedure MSG_SaveReadCount;
asm
 mov eax, CvarDef.MSG_ReadCount
 push [eax]
 pop [CvarDef.SavedReadCount]
end;

procedure MSG_RestoreReadCount;
asm
 push CvarDef.SavedReadCount
 mov eax, [CvarDef.MSG_ReadCount]
 pop [eax]
end;

{procedure LoadBlackList;
const
 sLoadedCmds: PChar = 'Loaded %i blacklisted commands.'#10;
 BlackListName: PChar = 'blacklist.txt';
asm
 push ebp // cmds loaded
 xor ebp, ebp

 push 0
 push 0
 push OPEN_EXISTING
 push 0
 push 0
 push GENERIC_READ
 push BlackListName
 call CreateFile

 test eax, eax
  js @Exit

 push esi
 push edi
 push ebx

 mov edi, eax // edi = h
 mov esi, offset BlackListCmds
@Loop:
  mov eax, 255
  call malloc
  mov ebx, eax

  mov edx, eax
  mov eax, edi
  mov ecx, 255
  call ReadLine

  test eax, eax
   jz @Break

  cmp byte ptr [ebx], '/' // is comment
   je @Loop

  cmp byte ptr [ebx], 0 // is empty string
   je @Loop

  mov eax, 8
  call calloc

  mov [esi], ebx
  mov [esi+4], eax
  mov esi, eax

  inc ebp
 jmp @Loop

@Break:
 push edi
 call CloseHandle

 pop ebx
 pop edi
 pop esi
@Exit:
 push ebp
 push sLoadedCmds
 call Engine.Con_PrintF
 add esp, 8

 pop ebp
end;}

{
 -- RAW FUNCTION
 Call convension: register

 Result: 0 - BadCmd, -1 - GoodCmd
}
procedure IsBadCmdLite; assembler;
type
 TCmd = record
   Cmd: PChar;
   Len: LongInt;
 end;
const
 BadCmdPrefixes: array[0..16] of TCmd =
 (
  (Cmd: '_'; Len: 1),
  (Cmd: 'gl_'; Len: 3),
  (Cmd: 'm_'; Len: 2),
  (Cmd: 'r_'; Len: 2),
  (Cmd: 'hud_'; Len: 4),
  (Cmd: 'cl_'; Len: 3),
  (Cmd: 'host_'; Len: 5),
  (Cmd: 'voice_'; Len: 6),
  (Cmd: 'scr_'; Len: 4),
  (Cmd: 'dem_'; Len: 4),
  (Cmd: 'fps_'; Len: 4),
  (Cmd: 'ex_'; Len: 3),
  (Cmd: 'sys_'; Len: 4),
  (Cmd: 'motd'; Len: 4),
  (Cmd: 'con_'; Len: 4),
  (Cmd: 'net_'; Len: 4),
  (Cmd: nil; Len: 0)
 );
 BadCmds: array[0..33] of PChar =
 ('cd',
  'alias',
  'startmovie',
  'viewdemo',
  'playdemo',
  'exec',
  'rate',
  'developer',
  'writecfg',
  'connect',
  //'reconnect',
  'retry',
  'bind',
  'timerefresh',
  'screenshot',
  'snapshot',
  'unbind',
  'unbindall',
  'quit',
  'exit',
  'sensitivity',
  'mp3volume',
  'texgamma',
  'hideradar',
  'bottomcolor',
  'topcolor',
  'fastsprites',
  'mp3',
  'spk',
  'speak',
  'volume',
  'clear',
  'messagemode',
  'hideconsole',
  nil);
asm
 push edi
 push esi

 call LowerCase
 mov edi, eax

 mov esi, offset BadCmdPrefixes
@Loop:
  mov edx, [esi]
  test edx, edx
  jz @Break

  mov eax, edi
  mov ecx, [esi+4]
  call StrLComp

  test eax, eax
  jz @Exit

@Passed:
  add esi, 8
 jmp @Loop

@Break:
 mov esi, offset BadCmds
@Loop2:
  mov edx, [esi]
  test edx, edx
  je @GoodCmd

  mov eax, edi
  call StrComp

  test eax, eax
  jz @Exit

@Passed2:
  add esi, 4
 jmp @Loop2

@GoodCmd:
 or eax, -1
@Exit:
 pop esi
 pop edi
end;

procedure Cmd_Inject;
const
 Info: PChar = 'Syntax: inject <LibName>'#10;
 Info2: PChar = 'LoadLibraryA(): %i'#10;
asm
 call Engine.Cmd_Argc
 dec eax
 jnz @GoodSyntax
  push Info
  call Engine.Con_PrintF
  pop eax
  ret
  
@GoodSyntax:
 push 1
 call Engine.Cmd_Argv
 pop edx

 push eax
 call LoadLibrary

 push eax
 push Info2
 call Engine.Con_PrintF
 add esp, 8
end;

procedure Cmd_Test;
const
 S1: PChar = '- DAMN SON, WHERE''D YOU FIND THIS?';
 S2: PChar = '- IN "KANTIR INDUSTRIES" SHOP, OF COURSE!';
 S3: PChar = '%s'#10'%s'#10;
asm
 push S2
 push S1
 push S3
 call Engine.Con_PrintF
 add esp, 12
end;

procedure Cmd_HTTP_Open;
const
 sMOTD: PChar = 'MOTD';
 sArgs: PChar = 'Syntax: http_open <URL/HTML>'#10;
 sLinkIsTooLong: PChar = 'Long URLs is not implemented yet.';
asm
 call [Engine.Cmd_Argc]
 cmp eax, 1
 jne @ShowArgs
  push sArgs
  call [Engine.Con_PrintF]
  pop eax
 ret

@ShowArgs:
 push esi
 push edi

 push 1
 call [Engine.Cmd_Argv]
 pop edx
 mov esi, eax

 call StrLen
 cmp eax, 60
 jle @GoodLink
  push sLinkIsTooLong
  call [Engine.Con_PrintF]
  pop eax

  pop esi
  pop edi
 ret

@GoodLink:
 mov edi, eax
 mov eax, 60
 call calloc

 mov byte ptr [eax], 1
 inc eax
 mov edx, esi
 mov ecx, edi
 call memcpy

 dec eax
 inc edi

 push eax
 push edi
 push sMOTD
 call SVC_MOTD_Orig
 add esp, 12

 pop esi
 pop edi
end;

end.


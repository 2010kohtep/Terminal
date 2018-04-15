unit MSGs;

{$I Default.inc}

interface

uses
 CvarDef, Strings, Common, HLSDK;

function SVC_MOTD(Name: PChar; Size: LongInt; Buffer: Pointer): LongInt; cdecl;
procedure SVC_StuffText;
procedure SVC_Director;

implementation

function SVC_MOTD(Name: PChar; Size: LongInt; Buffer: Pointer): LongInt; cdecl;
const
 sMOTDBlocked: PChar = '[%s] MOTD has been blocked.'#10;
asm
 push 0
 mov ecx, [cl_disablemotd]
 fld dword ptr [ecx].cvar_t.Value
 fistp dword ptr [esp]
 pop edx

 test edx, edx
 jnz @NeedToBlock
  pop ebp
  jmp SVC_MOTD_Orig

@NeedToBlock:
 mov eax, [Buffer]
 movzx eax, byte ptr [eax]
 dec eax
 jnz @Exit
  mov eax, [CvarDef.Name]
  push eax
  push sMOTDBlocked
  call Engine.Con_PrintF
  add esp, 8

@Exit:
 xor eax, eax
end;

procedure SVC_StuffText;
const
 sNotBlocked: PChar = '[%s] "%s": Not blocked'#10;
 sBlocked: PChar = '[%s] "%s": Blocked'#10;
asm
 call [CvarDef.MSG_ReadString]
 cmp byte ptr [eax], 0
 jne @NotEmptyStr
  ret

@NotEmptyStr:
 {push eax
 mov dl, 10
 mov cl, 0
 call ReplaceChar
 pop eax}

 cmp byte ptr [eax], '_'
 jne @NotDprotoCmd
  push eax
  push [CvarDef.Name]
  push sNotBlocked
  call [Engine.Con_PrintF]
  add esp, 8
  call [Engine.ClientCmd]
  pop eax
 ret

@NotDprotoCmd:
 push ebx
 push esi
 push edi
 push ebp

 mov esi, eax // esi = cur cmds pointer
 mov dl, ';'
 call StrScan
 test eax, eax
  jz @SingleCmd

 xor ebp, ebp // not zero = last cmd
 xor ebx, ebx // SubCommand
 mov edi, esi
@Loop:
  cmp byte ptr [edi], ' '
  jne @NotSpace
   inc edi
   jmp @Loop

@NotSpace:
  cmp byte ptr [edi], 10
  jne @NotEndYet
  cmp byte ptr [edi], 0
  jne @NotEndYet
   inc ebp
   jmp @ZeroTerminated

@NotEndYet:
  cmp byte ptr [edi], '"'
  jne @NotQuote
   not ebx

@NotQuote:
  test ebx, ebx
  jz @NotQuote2
   inc edi
   jmp @Loop

@NotQuote2:
  cmp byte ptr [edi], ';'
  jne @NotSeparatedCmdHere
   mov byte ptr [edi], 0
@ZeroTerminated:
@CheckCmd:
   push esi
   call [CvarDef.Cmd_TokenizeString]
   pop edx

   push 0
   call [Engine.Cmd_Argv]
   pop edx

   cmp byte ptr [eax], 0
   je @EmptyCmd

   call IsBadCmdLite
   test eax, eax
   jnz @NotBlocked

@Blocked:
    push esi
    push [CvarDef.Name]
    push sBlocked
    call [Engine.Con_PrintF]
    add esp, 12

    test ebp, ebp
    jnz @Exit

    inc edi
    mov esi, edi

    jmp @Loop
@NotBlocked:
    push esi
    push [CvarDef.Name]
    push sNotBlocked
    call [Engine.Con_PrintF]
    add esp, 8
    //call [Engine.ClientCmd]
    call [CvarDef.CBuf_AddText]
    pop eax

    test ebp, ebp
    jnz @Exit

    inc edi
    mov esi, edi
    jmp @Loop

@EmptyCmd:
@NotSeparatedCmdHere:
@IsSubCmd:
  inc edi
 jmp @Loop
 // multicmd handler here

@SingleCmd:
 push esi
 call [CvarDef.Cmd_TokenizeString]
 pop edx

 push 0
 call [Engine.Cmd_Argv]
 pop edx

 call IsBadCmdLite
 test eax, eax
 jz @Blocked2

@NotBlocked2:
  push esi
  push [CvarDef.Name]
  push sNotBlocked
  call [Engine.Con_PrintF]
  add esp, 8
  //call [Engine.ClientCmd]
  call [CvarDef.CBuf_AddText]
  pop eax

  pop ebp
  pop edi
  pop esi
  pop ebx

 ret
@Blocked2:
 push esi
 push [CvarDef.Name]
 push sBlocked
 call [Engine.Con_PrintF]
 add esp, 12

@Exit:
 pop ebp
 pop edi
 pop esi
 pop ebx
end;

procedure SVC_Director;
const
 sCmdIsBlocked: PChar = '[%s] "%s" (Director): Blocked'#10;
asm
 push esi

 call MSG_SaveReadCount
 call [CvarDef.MSG_ReadByte]
 mov esi, eax

 call [CvarDef.MSG_ReadByte]
 cmp eax, 10

 je @IsDirector
  call MSG_RestoreReadCount
  pop esi
  jmp SVC_Director_Orig

@IsDirector:
 call [CvarDef.MSG_ReadString]

 push edi
 mov edi, eax

 mov dl, 10
 mov cl, 0
 call ReplaceChar

 push edi
 push Name
 push sCmdIsBlocked
 call Engine.Con_PrintF
 add esp, 12

 call MSG_RestoreReadCount
 inc esi
 mov eax, [CvarDef.MSG_ReadCount]
 add [eax], esi

 pop edi
 pop esi
end;

end.

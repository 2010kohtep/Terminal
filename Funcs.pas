unit Funcs;

{$I Default.inc}

interface

uses
 CvarDef, Strings, Memory, WindowsAPI, Spoofer, HLSDK, Common;

procedure CL_SendConnectPacket_Our;
procedure DemoFilter(Text: PChar);
procedure DemoCheckPath_Our;

implementation

procedure CL_SendConnectPacket_Our;
const
 localhost: PChar = 'localhost';
 sI: PChar = '%i';
 ConnectPacket: PChar = '%c%c%c%cconnect %i %i "\prot\%i\unique\-1\raw\steam\cdkey\%s" "%s"'#10;
asm
 mov ecx, [cl_steamid_value]
 mov ecx, [ecx].cvar_t.Data
 call atoi
 dec eax
 jns @NeedToSpoof
  jmp CvarDef.CL_SendConnectPacket

@NeedToSpoof:
 push esi

 mov eax, CvarDef.cls_servername
 mov esi, eax
 mov edx, Localhost
 mov ecx, 5
 call StrLComp
 dec eax
 jz @IsNotLocalStr
  mov eax, CvarDef.cls_servername
  mov edx, Localhost
  mov ecx, 10
  call memcpy

@IsNotLocalStr:
 sub esp, 20

 push esp
 push esi
 call [CvarDef.NET_StringToAddr]
 add esp, 8

 {test eax, eax
 jnz @GoodStrToAddr
  mov ecx, [CvarDef.GameUI007]
  mov eax, [ecx]
  push 1
  push CDkey
  call eax.VGameUI007.ContinueProgressBar

  pop esi
  ret}

@GoodStrToAddr:
 mov eax, 800h
 mov esi, eax
 call calloc

 push CvarDef.LocalInfo

 push eax
 call CvarDef.CL_GetCDKeyHash
 mov ecx, eax
 pop eax

 push ecx
 push 3

 mov edx, s_connection_challenge
 push [edx]
 push 48

 or ecx, -1
 push ecx
 push ecx
 push ecx
 push ecx

 push ConnectPacket
 push esi
 push eax

 mov esi, eax // save connect packet pointer to esi

 call [CvarDef._snprintf]
 add esp, 30h

 push eax // save cpacket length
 add eax, esi
 push eax

 // bad getting method with float
 {Get SteamID from variable}
{push edx
 mov ecx, [cl_steamid_value]
 fld dword ptr [ecx].cvar_t.Value
 fistp dword ptr [esp]
 pop edx // edx is number from "cl_steamid_value" now}

 mov ecx, [cl_steamid_value]
 mov ecx, [ecx].cvar_t.Data
 call atoi
 mov edx, eax
 pop eax

 {Get EmulatorID from variable}
 push ecx
 mov ecx, [cl_steamid_emu]
 fld dword ptr [ecx].cvar_t.Value
 fistp dword ptr [esp]
 pop ecx

 push ebp
 push ebx

 lea ebp, [EmusArray]
 lea ebx, [ebp+ecx*4]
 call [ebx]

 pop ebx
 pop ebp

 pop edx
 {Get EmulatorID length}
 lea eax, [EmusSize]
 lea ecx, [eax+ecx*4]
 //add edx, [ecx] // certificate size
 add edx, 206

 //push esp // netaddr
 push esi
 push edx
 push 0
 call CvarDef.NET_SendPacket
 add esp, 20h

 pop esi
end;

procedure DemoFilter(Text: PChar);
const
 sDFBlocked: PChar = '[%s] (Demo) "%s": Blocked'#10;
 sDFNotBlocked: PChar = '[%s] (Demo) "%s": Not blocked'#10;
asm
 push -1
 mov edx, [dem_filtercmd]
 fld dword ptr [edx].cvar_t.Value
 fistp dword ptr [esp]
 pop edx
 dec edx
 js @FilterIsDisabled

 push ebx
 push esi
 push edi
 push ebp

 mov esi, [esp+20] // esi = cur cmds pointer
 mov dl, ';'
 call StrScan
 test eax, eax
  jz @SingleCmd

 xor ebp, ebp // not zero = last cmd
 xor ebx, ebx // SubCommand
 mov edi, esi
@Loop:
  cmp byte ptr [edi], 0
  jne @NotEndYet
   inc ebp
   jmp @ZeroTerminated

@NotEndYet:
  cmp byte ptr [edi], '"'
  jne @NotQuote
   not ebx

@NotQuote:
  cmp byte ptr [edi], ';'
  jne @NotSeparatedCmdHere

  test ebx, ebx
  jnz @IsSubCmd
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
   jnz @NotBlockedMP

@Blocked2:
    push esi
    push [CvarDef.Name]
    push sDFBlocked
    call [Engine.Con_PrintF]
    add esp, 12

    test ebp, ebp
    jnz @Exit

    inc edi
    mov esi, edi

    jmp @Loop
@NotBlockedMP:
    push esi
    push [CvarDef.Name]
    push sDFNotBlocked
    call [Engine.Con_PrintF]
    add esp, 8
    call [Engine.ClientCmd]
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
 jz @Blocked

@NotBlocked:
 push esi
 push [CvarDef.Name]
 push sDFNotBlocked
 call [Engine.Con_PrintF]
 add esp, 12

 pop ebp
 pop edi
 pop esi
 pop ebx
@FilterIsDisabled:
 jmp [CvarDef.CBuf_AddText]

@Blocked:
 push esi
 push [CvarDef.Name]
 push sDFBlocked
 call [Engine.Con_PrintF]
 add esp, 12

@Exit:
 pop ebp
 pop edi
 pop esi
 pop ebx
end;

procedure DemoCheckPath_Our;
const
 sStr: PChar = '%s/%s';
asm
 push esi

 push 1
 call [Engine.Cmd_Argv]
 pop edx

 push eax // demoname

 mov eax, 255
 call calloc
 mov esi, eax

 mov edx, [CvarDef.dem_directory]
 push [edx].cvar_t.Data // demodir
 push sStr // format
 push 255 // max len
 push esi // dest
 call _snprintf
 add esp, 16

 xchg eax, esi
 pop edx
 pop esi
end;

end.

library Project1;

{$I Default.inc}

uses
  HLSDK in 'HLSDK.pas',
  MemSearch in 'MemSearch.pas',
  MsgAPI in 'MsgAPI.pas',
  CvarDef in 'CvarDef.pas',
  ConsoleAPI in 'ConsoleAPI.pas',
  WindowsAPI in 'WindowsAPI.pas',
  PascalTypes in 'PascalTypes.pas',
  Common in 'Common.pas',
  ExportFuncs in 'ExportFuncs.pas',
  Strings in 'Strings.pas',
  Funcs in 'Funcs.pas',
  Spoofer in 'Spoofer.pas',
  Hooks in 'Hooks.pas',
  MSGs in 'MSGs.pas',
  Memory in 'Memory.pas';

function HUD_Redraw{(Time: Single; Intermission: LongInt)}: LongInt; {cdecl;}
asm
 jmp Client.HUD_Redraw
end;

procedure Cmd_DumpAllCVars;
const
 sStr: PChar = 'alias "%s" "%s"'#10;
asm
 push esi
 push edi
 mov esi, dword ptr [CVarBase]

@Loop:
  mov edi, [esi]
  push [edi+4]
  push [edi]
  push sStr
  call [Engine.Con_PrintF]
  add esp, 12

  cmp dword ptr [edi+16], 0
  je @Break

  mov esi, edi
  add esi, 16
 jmp @Loop
@Break:

 pop edi
 pop esi
end;

procedure FindAllStuff;
asm 
 call Find_UserMsgBase
 call Find_SVCBase
 call Find_MSGInterface
 call Find_CL_SendConnectPacket
 call Find_NET_SendPacket
 call Find_GameUI007
 call Find__snprintf

 call Find_s_connection_challenge
 call Find_cls_servername
 call Find_LocalInfo
 call Find_NET_StringToAddr
 call Find_CL_GetCDKeyHash

 call Find_CmdBase
 call Find_DemoHandler
 call Find_Cmd_TokenizeString

 call Find_CL_CheckCommandBounds

 push [CvarDef.CL_SendConnectPacket]
 push [HLBaseSize]
 push [HLBase]
 call FindAllRefCallAddr
end;

procedure HookAllStuff;
const
 sMOTD: PChar = 'MOTD';
asm
 // hook functions
 call Hook_CL_SendConnectPacket
 call Hook_DemoHandler
 //call Hook_DemoCheckPath

 // hook events
 mov eax, sMOTD
 mov edx, offset SVC_MOTD
 call HookUserMessage
 mov [CvarDef.SVC_MOTD_Orig], eax

 // hook svc packets
 {mov eax, HLSDK.SVC_STUFFTEXT
 mov edx, offset SVC_STUFFTEXT
 call HookServerMsgByIndex
 mov [CvarDef.SVC_StuffText_Orig], eax}

 mov eax, HLSDK.SVC_DIRECTOR
 mov edx, offset SVC_Director
 call HookServerMsgByIndex
 mov [CvarDef.SVC_Director_Orig], eax
end;

procedure PatchAllStuff;
asm
 call Patch_CL_CheckCommandBounds
 // call Fix_VirtualProtect
 // call Patch_CL_ConnectionlessPacket
end;

procedure RegisterCmdStuff;
const
 sDumpCVars: PChar = 'dump_cvars';
 sSteamIDValue: PChar = 'cl_steamid_value';
 sSteamIDPrefix: PChar = 'cl_steamid_prefix';
 sSteamIDEmu: PChar = 'cl_steamid_emu';
 sDemoProtect: PChar = 'dem_filtercmd';
 sCL_DisableMOTD: PChar = 'cl_disablemotd';
 sDemoDirectory: PChar = 'dem_directory';
 sDemDir: PChar = 'demo';
 sHTTPOpen: PChar = 'http_open';
 sInject: PChar = 'inject';
 sTest: PChar = 'test';

 s0: PChar = '0';
 s1: PChar = '1';
asm
 push esi
 xor esi, esi

 push offset Cmd_HTTP_Open
 push sHTTPOpen
 call Engine.AddCommand
 add esp, 8

 {push esi
 push sDemDir
 push sDemoDirectory
 call Engine.RegisterVariable
 add esp, 12
 mov [CvarDef.dem_directory], eax}

 push esi
 push s1
 push sDemoProtect
 call Engine.RegisterVariable
 add esp, 12
 mov [CvarDef.dem_filtercmd], eax

 push esi
 push s0
 push sSteamIDValue
 call Engine.RegisterVariable
 add esp, 12
 mov [CvarDef.cl_steamid_value], eax

 push esi
 push s1
 push sSteamIDEmu
 call Engine.RegisterVariable
 add esp, 12
 mov [CvarDef.cl_steamid_emu], eax

 push esi
 push s1
 push sSteamIDPrefix
 call Engine.RegisterVariable
 add esp, 12
 mov [CvarDef.cl_steamid_prefix], eax

 { // fat method of randomization
 rdtsc
 ror edx, 16
 xor eax, edx
 shr eax, 1}

 push s0
 push sSteamIDValue
 call Engine.CVar_Set
 add esp, 8

 push esi
 push s1
 push sCL_DisableMOTD
 call Engine.RegisterVariable
 add esp, 12
 mov [CvarDef.cl_disablemotd], eax

 push offset Cmd_Inject
 push sInject
 call Engine.AddCommand
 add esp, 8

 push offset Cmd_Test
 push sTest
 call Engine.AddCommand
 add esp, 8

 pop esi
end;

procedure HUD_Frame{(Time: Double); cdecl;};
const
 sDumpCVars: PChar = 'dump_cvars';
 sStartMessage: PChar = '-- %s %s | 2010kohtep'#10;
 sStartDesc: PChar = '-- GoldSource Engine protection system.'#10;
asm
 cmp [NotFirstFrame], 0
 je @Exit
  dec [NotFirstFrame]

 mov eax, 2E2DDh
 add eax, [HLBase]
 mov eax, [eax]
 mov dword ptr [CVarBase], eax

 {push offset Cmd_DumpAllCVars
 push sDumpCVars
 call Engine.AddCommand
 add esp, 8}

  call FindAllStuff
  call PatchAllStuff
  call HookAllStuff
  call RegisterCmdStuff

  push Version
  push Name
  push sStartMessage
  call Engine.Con_PrintF
  add esp, 12

  push sStartDesc
  call Engine.Con_PrintF
  pop eax

  call COM_ShowConsole
@Exit:
 jmp [Client.HUD_Frame]
end;

function HUD_Key_Event{(Down, KeyNum: LongInt; Binding: PChar)}: LongInt; {cdecl;}
asm
 jmp [Client.HUD_Key_Event]
end;

procedure Main;
const
 EngineNotFoundStr: PChar = 'Couldn''t find default scanning pattern.';
asm
 call FindEngineAndClient
 test eax, eax
 jnz @EngineIsFound
  mov eax, offset EngineNotFoundStr
  jmp RaiseError

@EngineIsFound:
@WaitForInit:
  call Initialized
  test eax, eax
  jnz @Inited

  push 100
  call Sleep
 jmp @WaitForInit

@Inited:
 call FindStudio

 mov eax, offset Engine
 mov edx, PEngine
 mov ecx, type Engine
 call memcpy

 mov eax, offset Studio
 mov edx, [PStudio]
 mov ecx, type Studio
 call memcpy

 mov eax, offset Client
 mov edx, [PClient]
 mov ecx, type Client
 call memcpy

 call [Studio.IsHardware]
 mov byte ptr [IsHW], al

 mov eax, [PClient]
 add eax, 12
 mov [eax], offset HUD_Redraw

 mov eax, [PClient]
 add eax, 132
 mov [eax], offset HUD_Frame

 mov eax, [PClient]
 add eax, 136
 mov [eax], offset HUD_Key_Event
end;

asm
 cmp [ebp+0Ch], DLL_PROCESS_ATTACH
 jne @Exit

 mov eax, [ebp+8]
 mov [ProtBase], eax

 push eax
 call DisableThreadLibraryCalls

 call GetProcessHeap
 mov [ProcessHeap], eax

 call GetCurrentProcess
 mov [HLExe], eax

 call GetRendererInfo

 xor ecx, ecx
 push ecx
 push ecx
 push ecx
 push offset Main
 push ecx
 push ecx
 call CreateThread

@Exit:
 xor eax, eax
 inc eax

 add esp, 03Ch
 pop ebp
 ret
end.

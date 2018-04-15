unit CvarDef;

{$I Default.inc}

interface

uses
 HLSDK, CSSDK, PascalTypes;

const
 DEFAULT_PROTOCOL = 47;

 Name: PChar = 'Terminal';
 Version: PChar = '0.1.5 Alpha';

var 
 Pattern_Engine: array[0..18] of Byte = (
 $E8, $FF, $FF, $FF, $FF,
 $83, $C4, $04,
 $68, $FF, $FF, $FF, $FF,
 $68, $00, $00, $00, $00,
 $E8);

 Pattern_Studio: array[1..20] of Byte =
 ($83, $C4, $0C,
  $85, $C0,
  $75, $FF,
  $68, $00, $00, $00, $00,
  $E8, $FF, $FF, $FF, $FF,
  $83, $C4, $04);

var
 HLBase: LongWord = 0;
 HLBaseEnd: LongWord = 0;
 HLBaseSize: LongWord = 0;

 CLBase: LongWord = 0;
 CLBaseEnd: LongWord = 0;
 CLBaseSize: LongWord = 0;

 ProtBase: LongWord = 0;
 HLExe: LongWord = 0;
 
 RendererType: Byte = 0;

 Protocol: LongWord = DEFAULT_PROTOCOL;

 HookServerMsg: function(Name: PChar; const Callback: TUserMsgHook): LongInt; cdecl = nil;
 UserMsgBase: user_msg_s = nil;

 Engine: cl_enginefuncs_t;
 PEngine: ^cl_enginefuncs_t = nil;

 EngineVersion: LongWord = ENGINE_INTERFACE_VERSION;

 Studio: engine_studio_api_t;
 PStudio: ^engine_studio_api_t = nil;
 StudioVersion: LongWord = STUDIO_INTERFACE_VERSION;
 PStudioInterface: r_studio_interface_s = nil;

 Client: exporttable_t;
 PClient: ^exporttable_t = nil;
 ClientVersion: LongWord = CLDLL_INTERFACE_VERSION;

 MainThread: LongWord = 0;
 ProcessHeap: Pointer = nil;

 IsInitialited: LongInt = -1;
 IsHW: Boolean = False;

 NotFirstFrame: Boolean = True;
 Addr0001: Pointer = nil;

 CL_SendConnectPacket: procedure; cdecl = nil;
 NET_SendPacket: HLSDK.NET_SendPacket = nil;
 CL_CanUseHTTPDownload: procedure; cdecl = nil;
 cls_servername: PChar = nil;
 GameUI007: PVGameUI007 = nil;
 GameConsole003: PGameConsole003 = nil;

 s_connection_challenge: PLongWord = nil;
 LocalInfo: PPChar = nil;

 _snprintf: function(Dest: PChar; Size: LongInt; Format: PChar; Args: PChar): LongInt; cdecl varargs = nil;

 cl_steamid_value: cvar_s = nil;
 cl_steamid_prefix: cvar_s = nil;
 cl_steamid_emu: cvar_s = nil;
 cl_disablemotd: cvar_s = nil;
 dem_filtercmd: cvar_s = nil;
 dem_directory: cvar_s = nil;
 http_useragent: cvar_s = nil;

 NET_StringToAddr: function(Str: PChar; Addr: Pointer): Boolean; cdecl = nil;
 SVCBase: server_msg_array_s = nil;
 SVCBase_End: Pointer = nil;
 SVCCount: LongWord = 0;

 SVC_MOTD_Orig: TCallback = nil;
 SVC_StuffText_Orig: TCallback = nil;
 SVC_Director_Orig: TCallback = nil;

 MSG_ReadString: HLSDK.MSG_ReadString = nil;
 MSG_ReadByte: HLSDK.MSG_ReadByte = nil;

 MSG_ReadCount: PLongWord = nil;
 SavedReadCount: LongWord = 0;

 CL_GetCDKeyHash: function: PChar; cdecl = nil;

 CmdBase: cmd_s = nil;
 CVarBase: cvar_s = nil;

 PlayingDemo: PLongWord = nil;
 DemoCmdsHandler: Pointer = nil;
 CBuf_AddText: HLSDK.CBuf_AddText = nil;
 Cmd_TokenizeString: HLSDK.Cmd_TokenizeString = nil;
 Cmd_Args: HLSDK.Cmd_Args = nil;
 IsSafeFileToDownload: HLSDK.IsValidFile = nil;
 DemoCheckPath: Pointer = nil;
 CL_CheckCommandBounds: HLSDK.CL_CheckCommandBounds = nil;

implementation

end.

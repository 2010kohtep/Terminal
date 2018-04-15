unit MsgAPI;

{$I Default.inc}

interface

uses
 WindowsAPI, CvarDef, Memory;

procedure RaiseError(Msg: PChar);
procedure RaiseInfo(Msg: PChar);
procedure ShowPointer(P: Pointer);

implementation

procedure RaiseError(Msg: PChar);
const
 sError: PChar = 'Error';
asm
 push MB_ICONHAND or MB_SYSTEMMODAL
 push sError
 push Msg
 push HWND_DESKTOP
 call MessageBox

 push 0
 call ExitProcess
end;

procedure RaiseInfo(Msg: PChar);
const
 sInfo: PChar = 'Info';
asm
 push MB_ICONINFORMATION or MB_SYSTEMMODAL
 push sInfo
 push Msg
 push HWND_DESKTOP
 call MessageBox
end;

procedure ShowPointer(P: Pointer);
const
 Str: PChar = '0x%08x';
asm
 push esi

 mov esi, eax
 sub esi, [CvarDef.HLBase]

 mov eax, 11
 call calloc

 push esi
 mov esi, eax
 push Str
 push 11
 push eax
 call _snprintf
 add esp, 16

 mov eax, esi
 call RaiseInfo

 pop esi
end;

end.

unit ConsoleAPI;

{$I Default.inc}

interface

procedure Print(Msg: PChar); stdcall;

implementation

procedure Print(Msg: PChar); stdcall;
asm
 ret 4
end;

end.

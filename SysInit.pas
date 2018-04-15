unit SysInit;

interface

procedure _InitExe;
procedure _halt0;
procedure _InitLib (Context: PInitContext);

var
 ModuleIsLib: Boolean;
 TlsIndex: Integer = -1;
 TlsLast: Byte;

const
PtrToNil: Pointer = nil;

implementation

procedure _InitLib (Context: PInitContext);
asm

end;

procedure _InitExe;
asm

end;

procedure _halt0;
asm

end;

end.
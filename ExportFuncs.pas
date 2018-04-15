unit ExportFuncs;

{$I Default.inc}

interface

uses
 MsgAPI;

implementation

function RIB_Main: LongInt;
asm
 xor eax, eax
 inc eax
end;

exports
 RIB_Main name '_RIB_Main@20';

end.

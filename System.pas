unit System;

interface

procedure _HandleFinally;

type
 TGUID = record
  D1: LongWord;
  D2: Word;
  D3: Word;
  D4: array [0..7] of Byte;
end;

type
 HRESULT = LongWord;

 PInitContext = ^TInitContext;
 TInitContext = record
  OuterContext: PInitContext;
  ExcFrame: Pointer;
  InitTable: Pointer;
  InitCount: LongInt;
  Module: Pointer;
  DLLSaveEBP: Pointer;
  DLLSaveEBX: Pointer;
  DLLSaveESI: Pointer;
  DLLSaveEDI: Pointer;
  ExitProcessTLS: procedure;
  DLLInitState: Byte;
end;

implementation

procedure _HandleFinally;
asm

end;

end.
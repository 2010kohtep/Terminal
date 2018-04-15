unit Strings;

{$I Default.inc}

interface

function StrLen(Str: PChar): LongInt;
function StrLComp(Str1, Str2: PChar; MaxLen: LongWord): LongInt;
function StrComp(const Str1, Str2: PChar): Integer;

procedure ReplaceChar(Str: PChar; Ch1, Ch2: Char);
function StrScan(Str: PChar; Ch: Char): PChar;
function LowerCase(S: PChar): PChar;
function UpperCase(S: PChar): PChar;
function IsValidMD5(P: PChar): Boolean;

implementation

function StrLen(Str: PChar): LongInt;
asm
 push edi

 xor ecx, ecx
 mov edi, eax
 not ecx
 xor al, al
 cld
 repne scasb
 not ecx
 lea eax, [ecx - 1]

 pop edi
end;

// Result: 1 - identical, 0 - different
function StrLComp(Str1, Str2: PChar; MaxLen: LongWord): LongInt;
asm
 push ebx
 push esi

 mov esi, edx
 sub eax, esi
 je @Exit
 add ecx, esi

@Loop:
 cmp ecx, esi
 je @Zero
 movzx ebx, [eax+esi]
 cmp bl, [esi]
 jne @SetResult
 inc esi
 jnz @Loop

@Zero:
 xor eax, eax
 pop esi
 pop ebx
 ret

@SetResult:
 xor eax, eax
 inc eax

@Exit:
 pop esi
 pop ebx
end;

function StrComp(const Str1, Str2: PChar): Integer; assembler;
asm
 push edi
 push esi
 mov edi, edx
 mov esi, eax
 mov ecx, 0FFFFFFFFH
 xor eax, eax
 repne scasb
 not ecx
 mov edi, edx
 xor edx, edx
 repe cmpsb
 mov al, [esi-1]
 mov dl, [edi-1]
 sub eax, edx
 pop esi
 pop edi
end;

procedure ReplaceChar(Str: PChar; Ch1, Ch2: Char);
asm
 test eax, eax
 jz @Finish

@Loop:
  cmp [eax], 0
  je @Finish
  
  cmp byte ptr [eax], dl
  jne @BadChar
   mov byte ptr [eax], cl
   ret

@BadChar:
  inc eax
 jnz @Loop

@Finish:
end;

function StrScan(Str: PChar; Ch: Char): PChar;
asm
 test eax, eax
 jz @Exit
 cmp byte ptr [eax], 0
 je @BadResult

@Loop:
  inc eax
  cmp byte ptr [eax], 0
  je @BadResult

  cmp byte ptr [eax], dl
  je @Exit
 jmp @Loop

@BadResult:
 xor eax, eax
@Exit:
end;

function LowerCase(S: PChar): PChar;
asm
 test eax, eax
  jz @Exit

 mov edx, eax
@Loop:
  mov cl, byte ptr [edx]
  cmp cl, 0
   je @Exit

  sub cl, 'A'
  cmp cl, 'Z' - 'A'
  ja @NotLetter
   or byte ptr [edx], 00100000b

@NotLetter:
  inc edx

 jmp @Loop
@Exit:
end;

function UpperCase(S: PChar): PChar;
asm
 test eax, eax
  jz @Exit

 mov edx, eax
@Loop:
  cmp byte ptr [edx], 0
   je @Exit

  cmp byte ptr [edx], ' '
  je @ItsSpace
   btc [edx], 5

@ItsSpace:
  inc edx
 jmp @Loop

@Exit:
end;

function IsValidMD5(P: PChar): Boolean;
asm
 push eax
 call StrLen
 pop edx

 cmp eax, 32
 jne @BadHash

@Loop:
  mov cl, byte ptr [edx]
  cmp cl, 0
  je @Break

  sub cl, 'A'
  cmp cl, 'Z' - 'A'

  ja @BadHash

  inc edx
 jmp @Loop

@Break:
 or eax, -1
 ret

@BadHash:
 xor eax, eax
end;

end.

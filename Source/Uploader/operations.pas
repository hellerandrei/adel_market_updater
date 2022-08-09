unit operations;

interface

uses
  system.NetEncoding,
  system.Classes,
  system.SysUtils,
  Windows,
  Main
;

function Base64Encode(Source: String): String;
function GetFileVersion(const FileName: String): String;
function GetMyVersion:string;
function URLEncode(const S: string): string;

implementation



function Base64Encode(Source: String): String;
var
  Encoder : TBase64Encoding;
Begin
  Encoder :=  TBase64Encoding.Create;
  try

    Result := Encoder.Encode(Source);
  finally
    Encoder.FreeInstance;
  end;
End;


function GetMyVersion:string;
type
  TVerInfo=packed record
    Nevazhno: array[0..47] of byte; // ненужные нам 48 байт
    Minor,Major,Build,Release: word; // а тут версия
  end;
var
  s:TResourceStream;
  v:TVerInfo;
begin
  result:='';
  try
    s:=TResourceStream.Create(HInstance,'#1',RT_VERSION); // достаём ресурс
    if s.Size>0 then begin
      s.Read(v,SizeOf(v)); // читаем нужные нам байты
      result:=IntToStr(v.Major)+'.'+IntToStr(v.Minor)+'.'+ // вот и версия...
              IntToStr(v.Release)+'.'+IntToStr(v.Build);
    end;
  s.Free;
  except; end;
end;



function URLEncode(const S: string): string;
var
  i, idx, len: Integer;

  function DigitToHex( Digit: Integer ): Char;
  begin
    case Digit of
      0..9: Result := Chr(Digit + Ord('0'));
      10..15: Result := Chr(Digit - 10 + Ord('A'));
      else
        Result := '0';
    end;
  end;

begin

  len := 0;
  for i := 1 to Length(S) do
    if ((S[i] >= '0') and (S[i] <= '9')) or
    ((S[i] >= 'A') and (S[i] <= 'Z')) or
    ((S[i] >= 'a') and (S[i] <= 'z')) or (S[i] = ' ') or
    (S[i] = '_') or (S[i] = '*') or (S[i] = '-') or (S[i] = '.') then
      len := len + 1
    else
      len := len + 3;

  SetLength(Result, len);
  idx := 1;
  for i := 1 to Length(S) do
    if S[i] = ' ' then
    begin
    Result[idx] := '+';
    idx := idx + 1;
    end
    else if ((S[i] >= '0') and (S[i] <= '9')) or
            ((S[i] >= 'A') and (S[i] <= 'Z')) or
            ((S[i] >= 'a') and (S[i] <= 'z')) or
            (S[i] = '_') or (S[i] = '*') or (S[i] = '-') or (S[i] = '.') then
    begin
      Result[idx] := S[i];
      idx := idx + 1;
    end
    else
    begin
      Result[idx] := '%';
      Result[idx + 1] := DigitToHex(Ord(S[i]) div 16);
      Result[idx + 2] := DigitToHex(Ord(S[i]) mod 16);
      idx := idx + 3;
    end;
end;

function GetFileVersion(const FileName: String): String;
var
  InfoSize, Wnd: DWORD;
  VerBuf: Pointer;
  FI: PVSFixedFileInfo;
  VerSize: DWORD;
begin
  Result := '';
  InfoSize := GetFileVersionInfoSize(PChar(FileName), Wnd);
  if InfoSize <> 0 then
  begin
    GetMem(VerBuf, InfoSize);
    try
      if GetFileVersionInfo(PChar(FileName), Wnd, InfoSize, VerBuf) then
        if VerQueryValue(VerBuf, '\', Pointer(FI), VerSize) then
          Begin
           Result :=
                      IntToStr(FI.dwFileVersionMS shr 16) + '.' +
                      IntToStr(FI.dwFileVersionMS and $FFFF) + '.'+
                      IntToStr(FI.dwFileVersionLS shr 16) + '.'+
                      IntToStr(FI.dwFileVersionLS and $FFFF);

           SBuild := IntToStr(FI.dwFileVersionLS and $FFFF);
          End;
     finally
        FreeMem(VerBuf);
     end;
  end;
end;


end.

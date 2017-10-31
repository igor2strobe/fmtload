unit Sys_AnsiOem;

interface

uses Windows,
   StringListUnicodeSupport,
   classes;

function ListEncodeToAnsi(lst: tstrings): tstringlist;

function Is1CStrings_CodedByOEM(lst: tstrings):bool;

function Encode1CStringsToAnsi(lst: tstrings): bool;

implementation
uses
  SysUtils;

function ListEncodetoAnsi(lst: tstrings): tstringlist;
var
  str: StringListUnicodeSupport.tstringlist;
  TmpStream: TMemoryStream;
begin
  result := nil;
  if assigned(lst) and (lst.count >0) then
  try
    TmpStream := TMemoryStream.Create;
    lst.SaveToStream(TmpStream);
    TmpStream.Position := 0;
    Str := StringListUnicodeSupport.TStringList.Create;
    Str.LoadFromStream( TmpStream);
    result := Str;
  finally
    TmpStream.Free;
  end;
end;

function Is1CStrings_CodedByOEM(lst: tstrings): bool;
var
  k: integer;
begin
  result := FALSE;
  if assigned(lst) and (lst.count >1) and (trim(lst[0]) ='1CClientBankExchange') then
   for k := 1 to lst.count-1 do begin
     if pos(AnsiUpperCase('=Windows'), AnsiUpperCase(lst[k])) >0 then
        break;
     if pos(AnsiUpperCase('=DOS'), AnsiUpperCase(lst[k])) >0 then begin
        result := TRUE;
        exit;
     end;
   end;
end;

function Encode1CStringsToAnsi(lst: tstrings): bool;
var
  k: integer;
begin
  result := FALSE;
  if assigned(lst) and (lst.count >2) and (trim(lst[0]) ='1CClientBankExchange') then
   for k := 1 to lst.count-1 do begin
     if pos('=WINDOWS', AnsiUpperCase(lst[k])) >0 then
        break;
     if pos('=DOS', AnsiUpperCase(lst[k])) >0 then begin
        result := TRUE;
        lst[k] := copy( lst[k],1,pos('=',lst[k])) + 'WINDOWS';
        break;
     end;
   end;
  if result then
   for k := 1 to lst.count-1 do
     oemToChar( pchar(lst[k]), pchar(lst[k]));
end;

end.



unit sys_StrConv;
//
//
//
interface
uses Windows;

function str2int(s:string): integer;
function str2float(s:string): double;

function nvl2i(const aInt: Integer; const aDefault: Integer): integer;
function nvl2n(const aNum: Double; const aDefault: Double;
                                             const aPrec:Double=0.0001): Double;

function IsDateStr(const s: string): bool;
function str2date(const s: string; const fmts: string=''): tdatetime;
function str2datetime(s: string; const fmts: string=''): tdatetime;
function Date2Str(const aDate: TDateTime; const fmt: string ='DD.MM.YYYY'): String;
function Date2StrReversed(const dt: tdatetime; const fmt: string =''): string;

function xmlStrback(s: string): string;
function xmlStr(const s: string): string;
function xmlString2date(const s: string): tdatetime; //2013-02-01
function xmlStr2Date( const aValue: AnsiString): TDateTime;


implementation
uses SysUtils,StrUtils,rxStrUtils;

function str2int(s:string): integer;
begin
  try
    s := ansireplacestr(s,' ','');
    while pos('0',s)=1 do
      s := copy(s,2,length(s));
    result := strtoint(s);
  except on EConvertError do
    result := 0;
  end;
end;


function str2float(s:string): double;
var
  i: integer;
begin
  result := 0;
  s := ansiReplaceStr(s,' ','');
  if Length(S) >0 then
  begin
    if (Pos('.',s) >0) or (Pos(',',S) >0) then
    begin
      i := nvl2I(pos('.',s), Pos(',',s));
      if (I >0) and (S[i] <>DecimalSeparator) then
        S[i] := DecimalSeparator;
    end;

    try
      result := strToFloat(S);
    except
      result := 0.0;
    end;
  end;
end;

function nvl2i(const aInt: Integer; const aDefault: Integer): integer;
begin
  if aInt <>0 then
    Result := aInt
  else Result := aDefault;
end;

function nvl2n(const aNum: Double; const aDefault: Double;
  const aPrec:Double=0.0001): Double;
begin
  if Abs(aNum) <aPrec then
    Result := aDefault
  else result := aNum;
end;

function IsDateStr(const s: string): bool;
begin
  result := (length(s) >0) and (s[1] in DigitChars) and (str2date(s) >0);
end;

function str2date(const s: string; const fmts: string=''): tdatetime;
var
  savDateFmt: string;
begin
  try
    if fmts<>'' then begin
      savDateFmt := ShortDateFormat;
      ShortDateFormat := fmts;
    end;
    result := strToDate(s);
  except
    if fmts <>'' then
      ShortDateFormat := savDateFmt;
    result := 0;
  end;
end;

function Date2Str(const aDate: TDateTime; const fmt: string ='DD.MM.YYYY'): String;
var
  tmpFmt: String;
begin
  SetLength(result, 0);
  if aDate >1 then
  try
    tmpFmt := SysUtils.ShortDateFormat;//system
    SysUtils.ShortDateFormat := fmt;
    try
      result := DateToStr(aDate);
    except
    end;
  finally
    SysUtils.ShortDateFormat := tmpFmt;
  end;
end;


function str2datetime(s: string; const fmts: string=''): tdatetime;
var
  savDateFmt: string;
begin
  try
    result := str2Date(s,fmts);
    if result =0 then begin
      if fmts <>'' then begin
        savDateFmt := ShortDateFormat;
        ShortDateFormat := fmts;
      end;
      result := strToDateTime(s);
    end;
  except
    if fmts<>'' then
      ShortDateFormat := savDateFmt;
    result := 0;
  end;
end;


// строка вида "yyyymmdd" из указанной даты
function Date2StrReversed(const dt: tdatetime; const fmt: string =''): string;
var
  ds: string;
begin
  SetLength(result,0);
  try
    ds := date2str(dt,fmt);
    if length(Ds) >1 then
      result := copy(ds, 7,4) + copy(ds,4,2) + copy(ds,1,2); // yyyymmdd
  except on EConvertError do
  end;
end;


function xmlString2Date(const s: string): tdatetime; //2013-02-01
var
  vs: string;
begin
  Result := 0;
  vs := xmlstr(s);
  if Length(vs) >0 then
    result := str2date(vs);
end;

function  XMLStr2Date( const aValue: AnsiString): TDateTime;
begin
  result := Str2Date(aValue);
  if result =0 then
    result := Str2Date(xmlstr(aValue));
end;


function xmlstr(const s: string): string;
begin
  SetLength(Result,0);
  if Length(s) =10 then
    result := copy(s,9,2) + dateSeparator + copy(s,6,2) + dateSeparator + copy(s,1,4);
end;

function xmlstrback(s: string): string;
begin
  result := date2StrReversed( xmlString2Date(s));
end;

end.

unit Sys_iStrUtils;
//
//
//
interface
uses Windows, Classes;



// ora nvl for string
function nvlStr(const aValue: string; const aDefault: string): string;
function nvl2s( const vbool: bool; const aStr1, aStr2: string): string;

// Pos дл€ поиска подстроки в строке справа налево
function posr(const substr: string; const s: string): integer;
//
//function str2int(s:string): integer;
//function str2float(s:string): double;

function GetNumberLength(const v: string): integer;
//function GetStrMaskValue(const mask,v: string; const aPos: integer=1): string;

function ReplaceFileExt( const fname, newExt: string): string;

// добавить к aStr сообщение aMsg с разделителем LineFeed
function LogStr(aMsg: String; var aStr: String; const LineFeed: String =#13#10): String;

 // последний/первый символ строки
function  lchar(var s: string; const ch: char; const isTruncate: bool=FALSE): bool;
function  fchar(var s: string; const ch: char; const isTruncate: bool=FALSE): bool;

// удалить двойные пробелы
function  PurgeStringBlank(const s: string; const IsTrimmed: bool=FALSE): string;

// суперпозици€ Trim(4),TrimRigth(),TrimLeft()
function  TrimStr(const s: string; const param: word =0): String;

// отделить от строки часть ƒќ разделител€
function  GrepSepString(var s: string; const sep: string=';'; const Param: word=0): string;
// Param=Value
// значение параметра Value
function  GetStrParamValue(const s: string; const sep: string='='; const Param: word=0): string;
function  GetStrKeyName(const s: string; const sep: string='='; const Param: word=0): string;

// содержание подстроки в строке
function  IsSubStr( substr: string; s: string; const Param: word=0): integer;
function  IsSubStrArr(const subsArr: array of string; s: string;
                     var idx: integer; const Param: word=0): integer;

//
function  IsDirectoryName(var dirname: string; const Forced: bool=FALSE): bool;


function  LoadListFromFile(const fname: string; var sMsg: string;
                           const iParam: word =0): tstringlist;

// строку с разделител€ми в StringList
function  PutStrToStringList(s: string; const chSep: char=';'): TStringlist;
//
const
  mpNoCase = $01;


implementation
uses
  sysUtils, StrUtils,rxStrUtils,
  Sys_StrConv;

// ora nvl for string
function nvlStr(const aValue: string; const aDefault: string): string;
begin
  if (aValue ='') then
    result := aDefault
  else result := aValue;
end;

function nvl2s( const vbool: bool; const aStr1, aStr2: string): string;
begin
  if vBool then
   result := aStr1
  else result := aStr2;
end;


function posr(const substr: string; const s: string): integer;
var
  i: integer;
  rs: string;
begin
  result := 0;
  rs     := '';
  if length(s) >0 then
  for i := length(s) downto 1 do begin
    rs := rs + s[i];
    result := pos(substr, rs);
    if result >0 then begin
      result := length(s) -result;
      break;
    end;
  end;
end;



function GetNumberLength(const v: string): integer;
var
  jcode: integer;
begin
  result  := 0;
  jcode := str2int(v);
  while jcode >0 do begin
    jcode := jcode div 10;
    inc(result);
  end;
end;

function ReplaceFileExt( const fname, newExt: string): string;
var
  s: string;
begin
  s := ExtractFileExt(fname);
  if length(s) >1 then
    result := copy(fname, 1, pos(s, fname)-1)+ newExt
  else result := fname + newExt;
end;


// содержание подстроки в строке
function IsSubStr( substr: string; s: string; const Param: word=0): integer;
begin
  if Param >0 then
    result := pos( ansiUpperCase(substr), ansiUpperCase(s))
  else
    result := pos( substr,s);
end;

function IsSubStrArr(const subsArr: array of string; s: string;
                     var idx: integer; const Param: word=0): integer;
var
  k: integer;
begin
  result := 0;
  for k := idx to High(subsArr) do
  if Length( subsArr[k]) >0 then begin
    result := IsSubStr( subsArr[k], s, Param);
    if result >0 then begin
      idx := k;
      break
    end;
  end;
end;


function LogStr(aMsg: String; var aStr: String; const LineFeed: String =#13#10): String;
begin
  result := aStr;
  if Length(aMsg) =0 then Exit
  else
  if length(aStr) =0 then
    aStr := aMsg
  else aStr := aStr + LineFeed + aMsg;
end;



// последний/первый символ строки
function lchar(var s: string; const ch: char; const isTruncate: bool=FALSE): bool;
begin
  result := (length(s) >0) and (s[length(s)]=ch);
  if result and isTruncate then
    s := copy(s,1, length(s)-1);
end;

function fchar(var s: string; const ch: char; const isTruncate: bool=FALSE): bool;
begin
  result := (length(s) >0) and (s[1]=ch);
  if result and isTruncate then
    s := copy(s,2, length(s)-1);
end;

// удалить двойные пробелы
function  PurgeStringBlank(const s: string; const IsTrimmed: bool=FALSE): string;
begin
  SetLength(result,0);
  if Length(s) =0 then exit;
  
  while pos('  ',s) >0 do
   result := ansiReplaceStr(s, '  ',' ');

  if IsTrimmed then
    result := Trim(result);
end;

// суперпозици€ Trim(4),TrimRigth(2),TrimLeft(2) and Copy(0)
function  TrimStr(const s: string; const param: word =0): String;
begin
  if Param =0 then
    result := S
  else
  if Param and $04=$04 then
    result := Trim(s)
  else
  if Param and $02=$02 then
    result := TrimRight(s)
  else
  if Param and $01=$01 then
    result := TrimLeft(s)
  else
    result := '';
end;

// отделить из строки часть ƒќ разделител€
function GrepSepString(var s: string; const sep: string=';'; const Param: word=0): string;
var
  iPos: integer;
begin
  SetLength(result, 0);
  if Length(s) =0 then
    exit
  else begin
    iPos := IsSubstr( sep,s,param);
    if iPos >0 then begin
      result := copy(s, 1, pred(ipos));
      s := copy( s, Succ(pos(sep,s)), Length(s));
    end
    else begin
      result := copy(s,1,Length(s));
      s := '';
    end;
    Result := TrimStr(result, Param);
  end;
end;


function  GetStrParamValue(const s: string; const sep: string='='; const Param: word=0): string;
var
  iPos: integer;
begin
  SetLength(result, 0);
  if Length(s) >0 then
  begin
    iPos := IsSubStr( sep, s,1);
    if iPos >0 then begin
      Inc(iPos,Length(Sep));
      result := TrimStr(Copy(s, iPos, Length(s)), Param);
    end
    else result := s;
  end;
end;

function  GetStrKeyName(const s: string; const sep: string='='; const Param: word=0): string;
begin
  SetLength(result, 0);
  if Length(s) >0 then
  begin
    if (Length(sep) =0) or (IsSubStr(sep, s, 1) =0) then
      result := TrimStr(s, param)
    else result := TrimStr( Copy(s,1, pred(IsSubStr( sep,s))), Param);
  end;
end;

function GetStrMaskValue(const mask,v: string; const aPos: integer=1): string;
begin
  if (IsSubstr(mask,v,1) =aPos) or (aPos =-1) then
    result := trim(copy(v, Succ(Length(mask)), Length(v)))
  else result := v;
end;


function  IsDirectoryName(var dirname: string; const Forced: bool=FALSE): bool;
var
  tdir: string;
begin
  result := FALSE;
  if length( dirname) =0 then exit;
  tdir := dirname;
  if lchar(dirname,'\') then
    lchar(tdir,'\',TRUE)
  else dirname := dirname+'\';
  result := directoryExists(tdir);
  if Forced and (not result) then
    if CreateDir(tdir) then
      result := TRUE
    else
      raise Exception.Create('Cannot create '+tdir);
end;


function LoadListFromFile(const fName: String; var sMsg: string;
                          const iParam: word =0): TStringList;
var
  tList: TStringList;
begin
  result := nil;
  SetLength(sMsg,0);

    tList  := TStringList.Create;
    if assigned(tList) then
    try
      tList.LoadFromFile(fName);
      if tList.Count =0  then
      begin
        if iParam and $02=$02 then
          sMsg := format('%s: doesn''t contain text data',[fname]);
        tList.Free;
       end
      else
        result := tList;
    except
      sMsg := format('%s: error due to file reading ',[fname]);
      tList.Free;
    end;
end;



function PutStrToStringList(s: string; const chSep: char=';'): TStringlist;
begin
  result := nil;
  if length(s) =0 then exit;
  result := TStringList.Create;

  while length(s) >0 do
  begin
    if pos( chSep, s) >0 then
    begin
      result.Add(copy(s, 1, pos(chSep,s)-1));
      s := copy(s, pos(chSep,s)+1, length(s));
     end
    else begin
      result.Add(s);
      s := '';
    end;
  end;
end;


end.

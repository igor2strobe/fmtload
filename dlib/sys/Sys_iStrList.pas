unit Sys_iStrList;
// операции со списками строк
// i.ilmovski@gmail.com
interface
uses Classes,Windows;

type
  SectionMask =record
    sBeginMask,
    sEndMask: string;
  end;

// удаляет строки с номера iPos пока не найдется строка, содержащая маску sMask
{function PurgeListByMask( const sMask: string; Lst: TStrings;
               const IsClrMask:bool=FALSE; const iPos: integer =0): integer;}

// возвращает номер строки из aList и значение rValue для параметра aParamName
function MatchListParamValue(aList: TStrings;
                             var rValue: String;  // значение параметра
                             const aParamName: String;        // параметр
                             const aMaskValues: array of string;// возможные значения если <>''
            const options: word =$0; const MaxLinesCount: Integer =0): integer;

// извлекает и возвращает в lSection часть aList в промежутке aBeginMask:aEndMask
function GetStringsSection(var aList: TStringList; const aBeginMask,aEndMask: String;
                    var lSection: TStringList; const Options: word=0): integer;

// возвращает в aValues значения параметров sParams, значения проверяются по sMask
function ExtractParamListValues( aList: TStringList; const sParams,sMasks: String;
                                out aValues, errMsg: String): integer;

// безопасно получить строку из списка ~Safe(List[i])
function GetStringsItemSafe(const List: TStrings; const i: integer): String;

// обратная операция от TStrings[i].Text
function StrToStringList(const S: String): TStringList;
function StrAsListLineCount(const S: String): integer;

// получить значение S[i]( когда S ~ TStrings.Text) в виде строки
function GetStringListValueIdx(const S: String; const i: integer): string;

procedure SepStrToStrArray(s: string; out sva: array of string;const Delim:string=';');
//procedure String2StringArray(const s: String; out sout:array of string;
  //                           const Delims: Char = [';']);


// значение из TStrings ~"Param=Value"
function GetParamListValueId( const lStr, lParams: string; const idx: integer): String;
function GetParamListValueStr( const lStr: string; const aParams: array of string): String;
function GetParamListValue( aList: TStringList; const aParams: array of string): String;

implementation
uses SysUtils, rxStrUtils,
  Sys_iStrUtils;

{function PurgeListByMask( const sMask: string; Lst: TStrings;
               const IsClrMask:bool=FALSE; const iPos: integer =0): integer;
begin
  result := 0;
  if assigned(Lst) and (Lst.count >0) and (length(sMask) >0) then
  begin
    while (Lst.count >0) and (pos( sMask, Lst[iPos]) =0) do
      Lst.delete(iPos);

    if (Lst.count >0) and IsClrMask then
      Lst.delete(iPos);

    result := Lst.count;
  end;
end;}


function ExtractParamListValues( aList: TStringList; const sParams,sMasks: String;
                                out aValues, errMsg: String): integer;
var
  j,i,newLen: integer;
  strMask,sErr,rValue: String;
  arrMask: array of string;
  prmList,maskList,valList: TStringList;
begin
  result := 0;
  SetLength(errMsg, 0);
  try
    prmList  := TStringList.Create;
    maskList := TStringList.Create;
    valList  := TStringList.Create;

    prmList.Text  := sParams;
    maskList.Text := sMasks;
    i := 0; J := 0;
    while (aList.Count >i) and (prmList.Count >j) do
    begin
      if Trim(aList[i]) ='' then
        aList.delete(i)
      else begin
        SetLength(sErr,0);
        strMask := TrimStr(GetStringsItemSafe(maskList,j),$04);
        newLen  := 0;
        repeat
          inc(newLen);
          SetLength(arrMask, newLen);
          arrMask[ High(arrMask)] := GrepSepString(strMask);
        until Length(strMask) =0;

        case MatchListParamValue(aList,rValue,prmList[j],arrMask,$0,prmList.Count) of
           -1: sErr := format('Не определен искомый параметр ''%s''',[prmList[j]]);
           -2: sErr := format('значение "%s" найдено как "%s"',[prmList[j],rValue]);
           -4: begin
                 valList.Add('');
                 Inc(j);
               end
           else begin  // параметр найден в исходном тексте
              valList.Add(rValue);
              aList.Delete(i);
              inc(j);
            end;
        end;
        SetLength(arrMask,0);
        errMsg := nvl2s(Length(errMsg) >0, errMsg+#13#10+sErr, sErr);
      end;
    end;
    result := valList.Count;
    aValues := valList.Text;
  finally
    valList.Free;
    maskList.Free;
    prmList.Free;
  end;
end;


// GetStringsSection
function GetStringsSection(var aList: TStringList; const aBeginMask,aEndMask: String;
                           var lSection: TStringList; const options: word=0): integer;
var
  i,iBegin,iEnd: integer;

  function GetListPoint(const aMask: string): integer;
  var j: integer;
  begin
    result := -1;
{   if pos('=', aMask) =0 then
      result := aList.IndexOf(aMask)
    else}
    for j := 0 to aList.Count -1 do
    if IsSubStr(aMask, aList[j]) =1 then begin
      result := j;
      break;
    end;
  end;
begin
  result := -1;
  if assigned(aList) and (aList.Count >0) and (Length(aBeginMask) >0) then begin
    iBegin := GetListPoint(aBeginMask);
    iEnd   := GetListPoint(aEndMask);
    if iEnd <0 then iEnd := aList.Count-1;

    if (iBegin >=0) and (iEnd >=0) and (iBegin <=iEnd) then
    begin
      if not assigned(lSection) then
        lSection := TStringList.Create;

      for i := iBegin to iEnd do
        if Options and $01=$01 then
        begin
          lSection.Add(aList[iBegin]);
          aList.Delete(iBegin);
         end
        else
          lSection.Add(aList[i]);

      result := lSection.Count;
    end;
  end;
end;

// возвращает номер строки из aList и значение rValue для параметра aParamName
function MatchListParamValue( aList: TStrings; var rValue: String;
                   const aParamName: String;
                   const aMaskValues: array of string;
            const options: word =$0; const MaxLinesCount: Integer =0): integer;
var
  i,k, iMaskPos,iEqPos,maxDeepCount: integer;
begin
  result := -1;
  if assigned(aList) and (Length(aParamName) >0) then
  begin
    SetLength(rValue,0);
    i := 0;
    result := -4;
    if MaxLinesCount <=0 then
      maxDeepCount := aList.Count else maxDeepCount := MaxLinesCount;
    while i <maxDeepCount do
    begin
      iMaskPos := IsSubStr( aParamName, aList[i], 1);
      if iMaskPos >0 then
      begin
        iEqPos := Pos('=',aList[i]);
        if iEqPos = 0 then   // "ПростоСтрокаИдентификатор"
        begin
          rValue := aParamName;
          result := i;
         end
        else begin                          // "параметр=значение"
          rValue := TrimStr( Copy(aList[i], Succ(iEqPos), Length(aList[i])),$02);

          for k := 0 to High(aMaskValues) do
          begin
            if Length(aMaskValues[k]) =0 then
              result := i
            else
            if options and $02 =$02 then begin
              if AnsiCompareStr(rValue,aMaskValues[k]) =0 then
               result := i
             end
            else
            if CompareText(rValue,aMaskValues[k]) =0 then
              result := i;
            if result >=0 then break;
          end;

          if (Length(aMaskValues[k]) >0) and (CompareText(rValue,aMaskValues[k]) <>0) then
            result := -2;
        end;
        if options and $10 =$10 then
          aList.Delete(i);

        Exit;
      end;
      inc(i);
    end;
   end;
end;


// безопасно получить строку из списка ~Safe(List[i])
function GetStringsItemSafe( const List: TStrings; const i: integer): String;
begin
  SetLength(result, 0);
  if assigned(List) then
  try
    if i <List.Count then
      result := List[i];
  except
  end;
end;

// строку с разделителями -> массив строк
procedure SepStrToStrArray(s: string; out sva: array of string;const Delim: string=';');
var
  nLen: Cardinal;
begin
  nLen  := 0;
  if Length(s) >0 then
  repeat
    inc(nLen);
//    SetLength(sva, nLen);
    sva[ High(sva)] := GrepSepString(s,Delim);
  until Length(s) =0;
end;

{procedure String2StringArray(const s: String; out sout:array of string;
                               const Delims: TSysCharSet = [';']);
var
  i, nLen: integer;
  sDelimiter: String;
begin
  nLen := WordCount(s, Delims);

  if nLen >0 then begin
    SetLength(sout, nLen);
    for i:=0 to nLen -1 do
     sout[i] := GrepSepString(s);
  end;
end;}

// обратная операция от TStrings[i].Text
function StrToStringList(const S: String): TStringList;
var
  Lst: TStringList;
begin
  result := nil;
  if Length(S) >0 then
  try
    Lst := TStringList.Create;
    Lst.Text := S;
    result := Lst;
  except
  end;
end;

function StrAsListLineCount(const S: String): integer;
var
  Lst: TStringList;
begin
  result := 0;
  try
    Lst := StrToStringList(S);
    if assigned(Lst) then
      result := Lst.Count;
  finally
    Lst.Free;
  end;
end;

// получить значение S[i]( когда S ~ TStrings.Text) в виде строки
function GetStringListValueIdx(const S: String; const i: integer): string;
var
  Lst: TStringList;
begin
  result := '';
  if Length(S) >0 then
  try
    Lst := StrToStringList(S);
    result := GetStringsItemSafe(Lst, i);
  finally
    Lst.Free;
  end;
end;


// значение из TStrings ~"Param=Value" по номеру строки
function GetParamListValueId( const lStr, lParams: string; const Idx: integer): String;
var sParam: String;
  lstParam: TStringList;
begin
  result := '';
  if Length(lStr) >0 then
  try
    lstParam := StrToStringList(lParams);
    if not assigned(lstParam) then exit;
    if Idx <lstParam.Count then begin
      sParam := GetStringsItemSafe(lstParam, idx);
      if Length(sParam) >0 then
        result := GetParamListValueStr(lStr, [sParam]);
    end;
  finally
    lstParam.Free;
  end;
end;


function GetParamListValueStr( const lStr: string; const aParams: array of string): String;
var
//rValue: string;
//k: integer;
  Lst: TStringList;
begin
  result := '';
  if Length(lStr) >0 then
  try
    Lst := StrToStringList(lStr);
    result := GetParamListValue( Lst, aParams);
{   for k := 0 to High(aParams) do
    if Length(aParams[k]) =0 then exit
    else
    if MatchListParamValue(Lst, rValue, aParams[k], ['']) >=0 then begin
      result := rValue;
      break;
    end;}
  finally
    Lst.Free;
  end;
end;

function GetParamListValue( aList: TStringList; const aParams: array of string): String;
var
  k: integer;
begin
  SetLength(result, 0);
  if assigned( aList) and (aList.Count >0) then
  for k := 0 to High(aParams) do
  if (Length(aParams[k]) >0) and (MatchListParamValue(aList,result,aParams[k],['']) >=0) then
    break;
end;

end.

unit fmtCurrNameSvc;

interface

function CurrFNameTranslate(const aFName,aCurrStr: string;
 const aAgentID: integer =0): String;


implementation
uses SysUtils,
 Sys_iStrUtils;

function CurrFNameTranslate(const aFName,aCurrStr: string;
                             const aAgentID: integer =0): String;
var
  sExt,sLeftName: String;
begin
  Result := '';
  if Length(aFName) >0 then
  begin
    Result := aFName;
    sExt   := ExtractFileExt(aFName);
    sLeftName := Copy(aFName,1,Length(aFName) - Length(sExt));
    if aAgentID =0 then
      result := sLeftName + '.' + nvlstr(aCurrStr,'*') + sExt
    else
      result := sLeftName + '.' + nvlstr(aCurrStr,'*') + '.'+IntToStr(aAgentID);
  end;
end;

end.

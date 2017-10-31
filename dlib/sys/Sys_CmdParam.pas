unit Sys_CmdParam;

interface
uses Windows;

type
  InputStrParams = array[0..11] of shortstring;

function GrepCommandParams(var iprm: inputStrParams;
                           const ConfigDel: array of string): integer;

var
  sysMainExePath: string;

implementation
uses
  rxStrUtils,SysUtils,
  Sys_StrConv,Sys_iStrUtils;

function GrepCommandParams(var iprm: inputStrParams;
                           const ConfigDel: array of string): integer;
var
  s: string;
  i,idpos,ips: integer;
begin
  fillchar(iprm, sizeof(iprm),0);
  ips := 0;
  sysMainExePath := ExtractFilePath(paramstr(0));

  for i := 1 to paramCount do
  begin
    s := Trim(paramStr(i));
    if (npos('-',s,1) =1) or (npos('/',s,1) =1) then
      s := Trim(Copy(s,2,Length(s)));

    if result =0 then
      result := str2Int(s);

    if IsSubStrArr(ConfigDel, s, idpos, $01) >0 then begin
      iprm[idpos] := trim( paramstr(i+1));
      inc(idpos);
     end
    else
    if (s <>iprm[0]) and (str2int(s) =0) then begin
      inc(ips);
      iprm[ips] := s;
    end;
  end;
  if ExtractFilePath(iPrm[0]) ='' then
    iPrm[0] := sysMainExePath + iPrm[0];
end;


end.

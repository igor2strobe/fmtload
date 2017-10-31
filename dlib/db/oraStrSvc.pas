unit oraStrSvc;

interface
uses Windows, Classes,
{$ifdef DOA}
  Oracle,
{$else}
  Ora,
{$endif}
 IniFiles;


function GetStrConnectbyIniFile(const aIniFile: TIniFile; const aSectName: string;
                                 const aListIdx: integer =0): String;

function IsConnectStringValid(const aStr: string): bool;  // user/psw@instance

function GetConnectParamFromString(aStr: string; var sMsg: String;
                                    var vUsr,vPsw,vDB: String): integer;

function MatchConfigParams( const aStr: string; var vUsr,vPsw,vDB: String): integer;


function  GetOraSessionUserString({$ifdef DOA} const oSess: TOracleSession;
                                  {$else} const oraSess: TOraSession; {$endif}
                             const OfflineStr: String ='Отключен'): String;

function GetSchemaString( s: string): string;

implementation
uses
  SysUtils, Sys_iStrUtils;

const
  paramMask: array [0..2] of string = ('USER','PASSWORD','DATABASE');

function GetStrConnectbyIniFile(const aIniFile: TIniFile; const aSectName: string;
                                 const aListIdx: integer =0): String;
var
  tList: TStringList;

  ConnectStr: string;
begin
  SetLength(result,0);
  if not assigned(aIniFile) then exit;

  tList := TStringList.Create;
  if Assigned(tList) then
  try
    aIniFile.ReadSectionValues(aSectName, tList);
    if tList.Count =0 then
      result := GetStrParamValue(tList[0])
    else result := GetStrParamValue(tList[aListIdx]);
    if not IsConnectStringValid( result) then
     SetLength(result, 0);
  finally
    tList.free;
  end;
end;

function  IsOraConnectParams(const aUsr,aPsw,aDb: string): bool;
begin
  Result := (length(aUsr) >0) and (Length(aPsw) >0) and (Length(aDb) >0);
end;

function  IsConnectStringValid(const aStr: string): bool;  // user/psw@instance
begin
  result := (length(aStr) >5) and (pos('/',aStr) >1) and (pos('@',aStr) >3);
end;

function GetConnectParamFromString( aStr: string; var sMsg: String;
                                    var vUsr,vPsw,vDB: String): integer;
var
  sStrConnect: string;
  iAt, iSlash: integer;
const
  sConnect = 'connection parameter line ';
begin
  result := -2;
  if Length(aStr) =0 then
    LogStr(sConnect +'is empty', sMsg);
  aStr := GetStrParamValue(aStr);

  if not IsConnectStringValid(aStr) then
    LogStr(sConnect +'is invalid', sMsg)
  else
  try
    iAt    := pos('@',aStr);
    if iAt <1 then
      LogStr(sConnect+'hasn''t TNS service name delemeter (@-sign)',sMsg)
    else vDb := copy(aStr, Succ(iAt), Length(aStr));

    iSlash := pos('/',aStr);
    if iSlash <2 then
      LogStr(sConnect+'hasn''t password delemeter (/-sign)',sMsg)
    else vUsr := copy(aStr, 1, Pred(iSlash));

    vPsw := copy(aStr, iSlash+1, iAt-1-iSlash);
    result := Abs(integer(not IsOraConnectParams(vUsr, vPsw, vDb)));
  except
    result := -4;
    LogStr('Error due to parsing '+sConnect,sMsg);
  end;
end;

function MatchConfigParams(const aStr: string; var vUsr,vPsw,vDB: String): integer;
var
  i: integer;
  sParam: string;
begin
  sParam := AnsiUpperCase( GetStrKeyName(aStr));
  for i := 0 to 2 do
   if Pos(paramMask[i],sParam) =1 then
   case i of
     0: vUsr := GetStrParamValue(aStr);
     1: vPsw := GetStrParamValue(aStr);
     2: vDB  := GetStrParamValue(aStr);
   end;

  result := Abs( not integer(IsOraConnectParams(vUsr, vPsw, vDb)));
end;


function  GetOraSessionUserString({$ifdef DOA} const oraSess: TOracleSession;
                                 {$else} const oraSess: TOraSession; {$endif}
                                 const OfflineStr: String ='Отключен'): String;
begin
  SetLength(result, 0);
  if assigned(oraSess) then
  with oraSess do
{$ifdef DOA}
   result := nvl2s( Connected, LogonUsername+'@'+LogonDatabase, OfflineStr);
{$else}
   result := nvl2s( Connected, Username+'@'+Server, OfflineStr);
{$endif}
end;


function GetSchemaString( s: string): string;
begin
  SetLength(result, 0);
  if Length(s) =0 then Exit;
  s := GetStrParamValue(s);

  if IsConnectStringValid(s) then
    result := Copy(s, 1, Pred(pos('/',s))) + copy(s,pos('@',s),length(s))
  else result := s;
end;


end.

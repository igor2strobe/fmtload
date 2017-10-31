unit oraLogin;

interface

uses
  Classes, Windows,
 {$ifdef DOA}
  Oracle, OracleData;
 {$else}
  Ora;
 {$endif}


function OpenOraConnectByConnectStr({$ifdef DOA} oraSess: TOracleSession;
                            {$else} oraSess: TOraSession;
                            {$endif}
                           var sMsg: string; const aConnectStr: string): integer;

function OpenOraConnectByParam( {$ifdef DOA} oraSess: TOracleSession;
                       {$else} orSess: TOraSession; {$endif}
                       var sMsg: string;
                       const vUsr,vPsw,vDb: string): integer;

implementation
uses SysUtils, Controls,
 {$ifdef DOA}
 {$else}
  OraError,
 {$endif}
  Sys_iStrUtils,
  oraStrSvc;


{function oraConnectByStrODAC( orSess: TOraSession; var sMsg: string;
                              const Args: array of const): integer;
var
  vs, vUsr,vPsw,vDB: String;
  i: integer;
begin
  result := -2;
  for i := 0 to High(Args) do
  with Args[i] do begin
    case VType of
      vtString     : vs := VString^;
      vtAnsiString : vs := string( VAnsiString);
    end;

    if IsStrConnectFormat(vs) then
      result := MatchStrConnectFormat(vS, vUsr,vPsw,vDB)
    else
      result := MatchConfigParams( vS, vUsr,vPsw,vDB);
    if result =0 then
      result := oraConnectEx( orSess, sMsg, vUsr,vPsw,vDb);
  end;
end;} // oraConnectByStrODAC()



function OpenOraConnectByConnectStr({$ifdef DOA} oraSess: TOracleSession;
                             {$else} oraSess: TOraSession;
                             {$endif}
                             var sMsg: string; const aConnectStr: String): integer;
var
  vUsr,vPsw,vDB: String;
begin
  result := GetConnectParamFromString(aConnectStr, sMsg, vUsr,vPsw,vDB);
  if result <>0 then
    result := MatchConfigParams( aConnectStr, vUsr,vPsw,vDB);

  if result =0 then
   result := OpenOraConnectByParam( oraSess, sMsg, vUsr,vPsw,vDb)
end;


function OpenOraConnectByParam( {$ifdef DOA} oraSess: TOracleSession;
                       {$else} orSess: TOraSession; {$endif}
                       var sMsg: string;
                       const vUsr,vPsw,vDb: string): integer;

var
 {$ifdef DOA}
  cursorSave: TCursor;
 {$endif}
  errCode: integer;
  errMsg: String;
begin
  result := -2;
 {$ifdef DOA}
  with oraSess as TOracleSession do
  try
    CursorSave := Cursor;
    Cursor     := crSQLWait;
 {$else}
  with orSess as TOraSession do
 {$endif}
    try
      if Connected then
        Connected := FALSE;
 {$ifdef DOA}
      LogonUserName := vUsr;
      LogonPassword := vPsw;
      LogonDatabase := vDb;
 {$else}
      Username := vUsr;
      Password := vPsw;
      Server   := vDb;
 {$endif}
      SetLength(errMsg, 0);
      errCode := 0;
      Connected := TRUE;
      result := 0;

 {$ifdef DOA}
    except on E:EOracleError do begin
       result := -1;
       errCode := EOracleError(E).ErrorCode;
       errMsg  := E.Message;
 {$else}
    except on E:EOraError do begin
       result := -1;
       errCode := EOraError(E).ErrorCode;
       errMsg  := E.Message;
 {$endif}

    case errCode of
           0: sMsg := 'database parameters missed.';
        1017: sMsg := 'invalid database/password for <'+vDB+'>';
       12535: sMsg := 'TNS Listener not found';
       06550: begin
                smsg := format('%d: logon script missed',[ErrCode]);
                result := 1;
              end;
        else
          sMsg := '<'+nvlstr(vDb,'Name is indefinite or')+'> unavailable';
    end;
    if result <0 then
      LogStr( format('%s'#13+'err code: %d', [errMsg, ErrCode]),sMsg);
    end;
  end;
 {$ifdef DOA}
  finally
    Cursor := CursorSave;
  end;
 {$endif}
end;

end.



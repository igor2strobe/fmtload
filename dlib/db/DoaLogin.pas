unit doalogin;

interface
 uses Classes, Windows,
   IniFiles,
   Oracle, OracleData;

 type
   TLoginDef = record //for backword compatibilty
     User,
     Passw,
     Database,
     Key,
     IPMask: string;
   end;

// function DOAConnect(var oraSession: TOracleSession; const errstr: string=''): integer;
function  DOA_ConnectEx( oraSess: ToracleSession; var smsg: string;
                        const user,passw,dbname: string): integer;

function  DOA_ParamConnect( oraSess: TOracleSession; var sMsg: string;
                            const Args: array of const): integer;

function  doaIniConnect( var oraSess: TOracleSession; var sMsg: string;
                          ini: TCustomIniFile; const sSection: string): integer;

procedure CloseSession( const aSess: TOracleSession;
                         const aForcedCommit: bool=TRUE);

function  GetOraSessionParam(const oSess: TOracleSession;
                             const OfflineStr: String ='Отключен'): String;

function  ViewConnectionStr( s: string): string;  // user@instance
//function  ViewConnectStr( s: string): string; // user/password@instance -> user@instance

implementation
 uses Controls,SysUtils,
  oraStrSvc,Sys_iStrUtils;


function  DOA_ParamConnect( oraSess: TOracleSession; var sMsg: string;
                            const Args: array of const): integer;
var
  vs,vUser, vPassw, vDataBase: string;
  i: integer;

  function MatchConnectStr(v: string): integer;
  var
    va: string;
  begin
    v := GetStrParamValue(v);
    vDatabase := copy(v, pos('@',v)+1, length(v));
    vUser := copy(v, 1, pos('/',v)-1);
    va := copy(v, pos('/',v)+1, length(v));
    vPassw := copy(va, 1, pos('@',va)-1);
    result := integer(length(vUser) >0);
  end;

  function MatchConfigParams( const v: string): integer;
  begin
    if pos('USER=', ansiUpperCase(v)) >0 then
      vUser := copy(v, pos('=',v)+1, length(v))
    else
    if (pos('DATABASE=', ansiUpperCase(v)) >0) or
       (pos('DB=', ansiUpperCase(v)) >0)  then
      vDatabase := copy(v, pos('=',v)+1, length(v))
    else
    if (pos('PASSWORD=', ansiUpperCase(v)) >0) or
       (pos('PASSW=', ansiUpperCase(v)) >0) then
      vPassw := copy(v, pos('=',v)+1, length(v));
    result := integer(length(vUser) >0);
  end;

begin
  result := -2;
  for i := 0 to High(Args) do
  with Args[i] do begin
    case VType of
      vtString     : vs := VString^;
      vtAnsiString : vs := string( VAnsiString);
    end;

    if IsConnectStringValid(vs) then begin
      MatchConnectStr(vs);
      break;
     end
    else
      MatchConfigParams( vs);
  end;

  if (vUser <>'') and (vPassw <>'') and (vDatabase <>'') then
    result := DOA_ConnectEx( oraSess, sMsg, vUser,vPassw,vDatabase);
end;//


function  doaIniConnect( var oraSess: TOracleSession; var sMsg: string;
                          ini: TCustomIniFile; const sSection: string): integer;
var
  vs,vUser, vPassw, vDataBase: string;
  tList: TStringList;
  i: integer;
begin
  result := -2;
  if trim(sSection) ='' then begin
    sMsg := 'Не объявлены параметры соединения с БД';
    exit
   end
  else
  if assigned(ini) then
  try
    tList := TStringList.Create;
    Ini.ReadSectionValues(sSection, tList);

    case tList.Count of
     0: sMsg := sMsg + ' в секции настроек "' + sSection + '"';
     1: if IsConnectStringValid( tList[0]) then
          result := doa_ParamConnect( oraSess, sMsg, [tList[0]]);
    else begin
       for i := 0 to tList.Count -1 do begin
         vs := tList[i];

         if pos('USER=', ansiUpperCase(vs)) >0 then
           vUser := copy(vs, pos('=',vs)+1, length(vs))
         else
         if (pos('DATABASE=', ansiUpperCase(vs)) >0) or
            (pos('DB=', ansiUpperCase(vs)) >0)  then
           vDatabase := copy(vs, pos('=',vs)+1, length(vs))
         else
         if (pos('PASSWORD=', ansiUpperCase(vs)) >0) or
            (pos('PASSW=', ansiUpperCase(vs)) >0) then
           vPassw := copy(vs, pos('=',vs)+1, length(vs));
       end;
       if (vUser <>'') and (vPassw <>'') and (vDatabase <>'') then
        result := DOA_ConnectEx( oraSess, sMsg, vUser,vPassw,vDatabase);
     end;
    end;
  finally
    tList.free;
  end;
end;


function DOA_ConnectEx( oraSess: TOracleSession; var sMsg: string;
                        const user,passw,dbname: string): integer;
var
  cursorSave: TCursor;
begin
  result := -2;
  with OraSess as TOracleSession do
  try
    CursorSave := Cursor;
    Cursor     := crSQLWait;
    try
      if Connected then
        Connected := FALSE;

      LogonUserName := user;
      LogonPassword := passw;
      LogonDatabase := dbname;

      Connected := TRUE;
      result := 0;
    except on E:EOracleError do begin
       result := -1;
       case EORACLEError(E).ErrorCode of
           0: sMsg := 'database parameters missed.';
        1017: sMsg := 'invalid parameters for <'+LogonDataBase+'>.';
       12535: sMsg := 'TNS Listener not found.';
       06550: begin
                smsg := format('%d: отсутствует входной скрипт',[EORACLEError(E).ErrorCode]);
                result := 1;
              end;
        else
         if LogonDataBase<>'' then
           smsg := '<'+LogonDatabase+'> unavailable.'
       end;
       if result <0 then
         sMsg := sMsg + format('%s'#13+'err code: %d', [E.Message, EORACLEError(E).ErrorCode]);
      end;
    end;
  finally
    Cursor := CursorSave;
  end;
end;


{function IsOracleConnectFormat(const v: string): bool; // user/psw@instance
begin

end;}


function  GetOraSessionParam(const oSess: TOracleSession;
                             const OfflineStr: String ='Отключен'): String;
begin
  SetLength(result, 0);
  if assigned(oSess) then
  with oSess do
   result := nvl2s( Connected, LogonUsername+'@'+LogonDatabase, OfflineStr);
end;

function ViewConnectionStr( s: string): string;
begin
  SetLength(result, 0);
  if Length(s) =0 then Exit;
  s := GetStrParamValue(s);

  if IsConnectStringValid(s) then
    result := Copy(s, 1, Pred(pos('/',s))) + copy(s,pos('@',s),length(s))
  else
    result := s;
end;

procedure CloseSession(const aSess: TOracleSession; const aForcedCommit: bool=TRUE);
begin
  if aSess.Connected then
  try
    if aForcedCommit then
      aSess.Commit;
  finally
    aSess.Connected := FALSE;
  end;
end;

{function GetUserLoginValues(var Login, DefLogin: TLoginDef; const isDefault: bool=TRUE): integer;
 begin
    result := -1;
    fillchar(Login, Sizeof(TLoginDef), 0);
    with Login do begin
       if isDefault then begin
           User     := DefLogin.User;
           Passw    := DefLogin.passw;
           Database := DefLogin.DataBase;
        end;

       if ((Length(User) >0) and (Length(Passw) >0)) OR (AnsiUpperCase(Trim(User))='ADMIN') then
          result := 0;
    end;
 end;


 function DOAConnect;
 var
   DefaultLogin: TLoginDef;
 begin
   with dm do
   try
	DefaultLogin.User     := ReadProfileText(_Default_, _Name_, _Empty_);
	DefaultLogin.Passw    := ReadProfileText(_Default_, _Code_, _Empty_);
        DefaultLogin.Database := ReadProfileText(_Default_, _Base_, _Empty_);
        DefaultLogin.key      := _Copyright_;
	DES.Key               := _Copyright_;

        if defaultLogin.User =_Empty_ then begin
           if errstr='' then
              messageDlg('Unknown login data.'^M'Connection aborted.',mtError,[mbOk],0)
           else
              messageDlg(errstr,mtError,[mbOk],0);
           result := -1
         end
	else
          ConnectUser( DefaultLogin); // Подключаемся к БД из ИНИ-файла
    finally
        application.ProcessMessages;
        result := integer( not OracleSession.Connected);
        application.ProcessMessages;
    end;  //try
 end;}

end.

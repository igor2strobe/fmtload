unit dmodsvc;

interface
uses SysUtils, Windows,
{$ifdef DOA}Oracle, OracleData,
{$else} Ora,
{$endif}
  oraLogin,
  datamodule;


function GetSessUserName({$ifdef DOA}
                           orSess: TOracleSession
                         {$else}
                           orSess: TOraSession
                         {$endif}): String;

function GetSessDatabase({$ifdef DOA}
                           orSess: TOracleSession
                         {$else}
                           orSess: TOraSession{$endif}): String;

function InitOraQuery({$ifdef DOA}
                       const oraSess: TOracleSession; var oraQuery: TOracleQuery;
                      {$else}
                       const aSess: TOraSession; var aQuery: TOraQuery;
                      {$endif}
                       const aPkgName, aProcName, aQueryStr: string;
                       const IsDisconnected: BOOL=False): integer;

implementation


function GetSessUserName;
begin
  SetLength(Result, 0);
  if not Assigned(orSess) then exit;
{$ifdef DOA}
  result := orSess.logonUserName;
{$else}
  result := orSess.UserName;
{$endif}
end;

function GetSessDatabase;
begin
  SetLength(Result, 0);
  if not Assigned(orSess) then exit;
{$ifdef DOA}
  result := orSess.logonDatabase;
{$else}
   result := orSess.Server;
{$endif}
end;

function InitOraQuery;
begin
  Result := -2;
  if (not assigned(aSess)) and (not IsDisconnected) then Exit;
  try
    if not Assigned(aQuery) then
    begin
{$ifdef DOA}
      aQuery := TOracleQuery.Create(nil);
{$else}
      aQuery := TOraQuery.Create(nil);
{$endif}
      aQuery.Session := aSess;
    end;
    if (Length(aPkgName) >0) and (aQuery.SQL.Count =0) then
    begin
      aQuery.SQL.Add('BEGIN');
      aQuery.SQL.Add(' '+aPkgName + aProcName +'('+aQueryStr+');');
      aQuery.SQL.Add('END;');
    end;
    Result := 0;
  except
    Result := -1;
  end;
end;


end.

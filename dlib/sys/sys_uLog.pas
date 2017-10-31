unit Sys_uLog;

interface
uses Classes, Windows, SysUtils;

type
  TMessageType = (mtpError,mtpWarning,mtpMessage);

type
  TDataLog = class(TStringList)// AddObject
    function AddLogFile( const afName: string; iLevel: word): integer;
  end;

{  TStorage =class(THandleStream)
    private
      FSFname: string;
    public
      FHandle: THandle;
    procedure HandleClose();
    constructor Create(const aFileName: string);
  end;}

procedure AddToLog(const LogFName: TFileName; aMessage: string; aMessType: TMessageType = mtpMessage);

function  CreateWriteStream(const aFileName: string; var h: THandle): THandleStream;
procedure WriteLog(const aFileName, aMsg: string);
function  GetSysDate : TDateTime;

implementation
uses
  dbTables;


// запись в файл протокола
//-----------------------------------------------------------------------------

function CreateWriteStream(const aFileName: string; var h: THandle): THandleStream;
begin
  result := nil;
  try
    H := CreateFile( PChar(aFileName), GENERIC_WRITE,
                      FILE_SHARE_READ or FILE_SHARE_WRITE, nil,
                      OPEN_ALWAYS, FILE_ATTRIBUTE_NORMAL, 0);
    if H <>INVALID_HANDLE_VALUE then
    try
      result := THandleStream.Create( H);
    except
      CloseHandle(H);
    end;
  except
    h := 0;
  end;
end;

procedure WriteLog(const aFileName, aMsg: string);
var
  Handle : THandle;
  S : TStream;
begin
  if Length(aFileName) <2 then exit;

  Handle := CreateFile ( PChar(aFileName), GENERIC_WRITE,
      FILE_SHARE_READ or FILE_SHARE_WRITE, nil, OPEN_ALWAYS, FILE_ATTRIBUTE_NORMAL, 0);
  if Handle <> INVALID_HANDLE_VALUE then
  try
    S := THandleStream.Create( Handle);
    try
      S.Position := S.Size;
      S.Write( PChar(aMsg + #13#10)^, Length(aMsg) + 2);
    finally
      S.Free;
    end;
  finally
    CloseHandle(Handle);
  end;
end;


function GetSysDate: TDateTime;
var
  queGetSysDate: TQuery;
begin
  result := Now;
{ queGetSysDate := FQI.CreateQuery;
  with queGetSysDate do
  try
    Close;
    SQL.Text := 'select sysdate from dual';
    Open;
    result := FieldByName('SysDate').asDateTime;
  finally
    FQI.FreeQuery(queGetSysDate);
  end;}
end;

procedure AddToLog(const LogFName: TFileName; aMessage: string; aMessType: TMessageType = mtpMessage);
var
  sMsg : string;
begin
  sMsg := TimeToStr(GetSysDate)+' '+ aMessage;
  writeLog(LogFName, sMsg);
{ with redtLog do
  begin
    case aMessType of
      mtError:
        begin
          SelAttributes.Color := clRed;
          SelAttributes.Style := [fsBold];
        end;
      mtWarning :
        begin
          SelAttributes.Color := clOlive;
          SelAttributes.Style := [fsBold];
        end;
      mtMessage :
        begin
          SelAttributes.Color := clBlack;
          SelAttributes.Style := [];
        end;
    end;
    Application.ProcessMessages;
    Lines.Add(Format('%s %s',[TimeToStr(Time), aMessage]));
    SendMessage(redtLog.Handle, EM_SCROLL, SB_LINEDOWN, 0);
    redtLog.Perform(EM_SCROLLCARET, 0, 0);
    SelAttributes.Color := Font.Color;
    SelAttributes.Style := [];
  end;}
end;

{ TDataLog }

function TDataLog.AddLogFile(const afName: string; iLevel: word): integer;
begin
  result := IndexOF(afName);
  if result <0 then
    result := AddObject( afName, Pointer(iLevel));
end;

{ TStorage }
{
procedure TStorage.HandleClose();
begin
  CloseHandle(FHandle);
end;


constructor TStorage.Create(const aFileName: string);
begin
  try
    FHandle := CreateFile( PChar(aFileName), GENERIC_WRITE,
                     FILE_SHARE_READ or FILE_SHARE_WRITE, nil,
                      OPEN_ALWAYS, FILE_ATTRIBUTE_NORMAL, 0);
    if FHandle <>INVALID_HANDLE_VALUE then
    try
      inherited Create( FHandle);
      FSFname := aFileName;
    except
      CloseHandle(FHandle);
      Fail;
    end;
  except
    Fail;
  end;
end;}


end.

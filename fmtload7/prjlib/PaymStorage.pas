unit paymStorage;

interface
uses Windows, Classes, SysUtils;

type
  TFileLogStream =class(THandleStream)

    constructor Create( const aFileName: String; const isOpen:bool=FALSE); overload;
    destructor  Destroy; override;
  end;

  TStreamStorage =class
  private
    FStream: TStream;
    FOwn: Boolean;
    procedure SetStream(const aStream: TStream);

    procedure WriteBuffer(const aStr: WideString); overload;
    procedure WriteBufferText(const aParam, aStr: AnsiString;
                  const IsOptional: bool =FALSE);

    procedure ReadBuffer(out aStr: WideString); overload;
    procedure ReadBufferText(out aParam,aStr: AnsiString);

    procedure ReadBuffer(var ABuffer; ABufferSize: Integer); overload;
    procedure WriteBuffer(const ABuffer; ABufferSize: Integer); overload;
  public
    constructor Create(const AStream: TStream = nil; const AOwn: Boolean = True);
    destructor Destroy; override;
    property Stream: TStream read FStream write SetStream;
    property Own: Boolean read FOwn write FOwn;

//  procedure Write(const AData: TBankAccnt);
    procedure WriteText(const aParam,aValue: ansiString; const IsForced: bool=TRUE);
    procedure WriteTextLn(const aParam,aValue: ansiString);
    function  ReadText( aParam: ansiString): String;
    function  ReadBufferList(var aList: TStringList): integer;

//  procedure Read(out AData: TBankAccnt);
    function  EoS: Boolean;
  end;


implementation

uses
  Sys_iStrUtils;

const
  lf: packed array[0..1] of char = #13#10;
  rOptional: bool = TRUE;


{ TStatementStorage }

constructor TStreamStorage.Create(const AStream: TStream;  const AOwn: Boolean);
begin
  inherited Create;
  FStream := AStream;
  FOwn := AOwn;
end;

destructor TStreamStorage.Destroy;
begin
  if FOwn and assigned(FStream) then
    FStream.Free
  else
    FStream := nil;
  inherited Destroy;
end;

procedure TStreamStorage.SetStream(const aStream: TStream);
begin
  if assigned(FStream) and FOwn then
    FreeAndNil(FStream);
  FStream := aStream;
  FOwn := False;
end;

function TStreamStorage.EoS: Boolean;
begin
  Assert(Assigned(FStream));
  Result := (FStream.Position >= FStream.Size);
end;

procedure TStreamStorage.ReadBuffer(out aStr: WideString);
var
  len: longint;
  W: WideString;
begin
  SetLength(W, 0);

  if (not EoS) then begin
    ReadBuffer( Len, SizeOf(Len));

    if (Len >0) then begin
      SetLength(W, Len);
      ReadBuffer( W[1], Length(W)*SizeOf(W[1]));
    end;
  end;
  aStr := W;
end;

procedure TStreamStorage.ReadBufferText(out aParam,aStr: AnsiString);
var
  w: AnsiString;
  wCh,wC2: AnsiChar;
begin
  wC2 := #0;
  while FStream.Position < FStream.Size do
  begin
    if wCh <>#0 then wC2 := wCh;    // predecessor saving
    ReadBuffer( wCh, SizeOf(wCh));
    case wCh of
       #0: begin
             aStr := '';
             break;
           end;
      #10: if wC2 =#13 then begin   // eol
             aStr := W;
             break;
           end;
      '=': if Length(W) >0 then begin
             aParam := W;
             SetLength(W, 0);
            end
           else
            break;
     else begin
         SetLength(W, Length(W) +SizeOf(W[1]));
         W := W + wCh;
       end;
    end;
  end;
end;

function TStreamStorage.ReadText(aParam: ansiString): String;
var
  aStr: AnsiString;
begin
  result := aStr;
end;

{procedure TStreamStorage.Read(out AData: TBankAccnt);
begin
  Assert(Assigned(FStream));
  ReadBuffer(AData.Signature, SizeOf(AData.Signature));
  ReadBuffer(AData.Size, SizeOf(AData.Size));
  ReadBuffer(AData.Comment);
  ReadBuffer(AData.CRC, SizeOf(AData.CRC));
end;}

procedure TStreamStorage.WriteBuffer(const AStr: WideString);
var
  Len: LongInt;
begin
  Len := Length(AStr);
  writeBuffer( Len, sizeOf(Len));
  if Len >0 then
    WriteBuffer( aStr[1], Length(aStr) * SizeOf(aStr[1]));
end;


procedure TStreamStorage.WriteBufferText(const aParam,aStr: AnsiString;
            const IsOptional: bool =FALSE);
var
  S: AnsiString;
begin
  if Length(aParam) =0 then Exit;
  S := aParam;

  if Length(aStr) =0 then begin
    if not IsOptional then
     S := S + '='
    else exit;
   end
  else begin
    if (Length(S) >0) and (S[Length(S)] ='=') then
      S := Copy(S,1, Pred(Length(S)));
    if aStr <>#0 then
      S := format('%s=%s',[S, aStr]);
  end;

  if Length(S) >0 then
    WriteBuffer( S[1], Length(S) * SizeOf(S[1]));
  WriteBuffer( lf, SizeOf(lf));
end;


{
procedure TStreamStorage.Write(const aData: TBankAccnt);
begin
  Assert(Assigned(FStream));

  WriteBuffer(AData.FAccntID, sizeof(AData.FAccntID));
  WriteBuffer(AData.FCurrID, sizeof(AData.FCurrID));
  WriteBuffer(AData.CurrCode, sizeof(AData.CurrCode));
  WriteBuffer(AData.CurrCh);    // ISO символьный код валюты
  WriteBuffer(AData.FAccount);  // номер счета  FAcntName: string;  // наименование счета
end;}

procedure TStreamStorage.WriteText(const aParam,aValue: ansiString;
   const IsForced: bool=TRUE);
begin
  WriteBufferText(aParam, aValue, (not IsForced) or (Length(aValue) >0));
end;

procedure TStreamStorage.WriteTextLn(const aParam, aValue: ansiString);
begin
  WriteBufferText(aParam, aValue, Length(aValue) =0);
end;

procedure TStreamStorage.ReadBuffer(var ABuffer; ABufferSize: Integer);
begin
  FStream.ReadBuffer(ABuffer, ABufferSize);
end;

function TStreamStorage.ReadBufferList(var aList: TStringList): integer;
var
  aStr: String;
begin
  result := 0;
  FStream.Seek(0,0);
  if FStream.Size >0 then
  try
    SetLength(aStr, FStream.Size);
    FStream.ReadBuffer( pointer(aStr)^, Length(aStr));
    if assigned(aList) then
      aList.Clear
    else aList := TStringList.Create;
    aList.Text := aStr;
    result := aList.Count;
  finally
  end;
end;

procedure TStreamStorage.WriteBuffer(const ABuffer; ABufferSize: Integer);
begin
  FStream.WriteBuffer(ABuffer, ABufferSize);
end;

{ TFileLogStream }

constructor TFileLogStream.Create(const aFileName: String; const isOpen:bool=FALSE);
var
  H: THandle;
begin
  if isOpen then
    H := CreateFile(PChar(aFileName), GENERIC_READ or GENERIC_WRITE,
                    FILE_SHARE_READ or FILE_SHARE_WRITE, nil,
                     OPEN_ALWAYS, FILE_ATTRIBUTE_NORMAL, 0)
  else
    H := CreateFile( PChar(aFileName), GENERIC_WRITE,
                    FILE_SHARE_READ or FILE_SHARE_WRITE, nil,
                     CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, 0);
  if H <>INVALID_HANDLE_VALUE then
  try
    inherited Create(H);
  except
    CloseHandle(H);
    Fail;
  end;
end;

destructor TFileLogStream.Destroy;
begin
  if FHandle >= 0 then
    FileClose(FHandle);
  inherited ;
end;




end.

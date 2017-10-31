unit sys_ifiles;

interface
uses Windows;

  function MoveFileWithStamp(const aFileSrc, aPath: string): LongInt;
//function CopyFileByPath( sFileSrc, sPath: string; const IsMove: bool=FALSE): Longint;

//function FileNameTimeStamp(aFileName: string): String;

implementation
uses SysUtils,FileUtil,rxStrUtils,
 Sys_iStrUtils,sys_StrConv;

const
  TStampMask ='YYYYMMDD_hhmmss';


function ParseFileNameByStamp(const aFileName: string; var aStamp,aFName,aFExt: String): integer;
var
  bra: integer;
  sStamp: String;
begin
  result := -1;
  aStamp := '';
  SetLength(aFExt,0);
  aFName := aFileName;
  bra := Pos('.',aFileName);
  if bra =0 then
    Exit;

  sStamp := Copy(aFileName,1,Pred(bra));
  if (Length(sStamp) =Length(TStampMask)) and (sStamp[9] ='_') then
  begin
     aStamp := sStamp;
     aFName := Copy(aFileName,Succ(bra),Length(aFileName));
   end
  else
    aFName := sStamp;

  aFExt := ExtractFileExt(aFileName);
  if Succ(bra) =Length(aFileName)-PosR('.',aFileName) then begin // single dot
    Result := 0;
    Exit;
   end
  else
    result := 1;
end;

function ParseFileNameByStamp2(const aFileName: string; aFName,aStamp,aFExt: String): integer;
var
  bra,ket: integer;
begin
  result := -1;
  aFName := aFileName;
  aStamp := '';
  bra := Pos('.',aFileName);
  if bra =0 then begin
    SetLength(aFExt,0);
    Exit;
  end;
  aFExt := ExtractFileExt(aFileName);
  ket := PosR('.',aFileName);
  aFName := Copy(aFileName,1,Pred(ket));
  Result := 0;
  if bra =ket then Exit;
  ket := PosR('.',aFName);
  aStamp := Copy(aFName,Succ(ket),Length(aFName));
  if Length(aStamp) =Length(TStampMask) then begin
    aFName := Copy(aFName,1,Pred(ket));
    Result := 1;
   end
  else
    aStamp := '';
end;

{function GetFileNameTimeStamp(var aFileName: string): String;
var
  bra,ket: integer;
  Vs,sCopyName: String;
begin
  SetLength(result,0);
  if Length(aFileName) <(Length(TStampMask)+2) then Exit;
  bra := Pos('.',aFileName);
  if bra <2 then exit;
  sCopyName := Copy(aFileName,1,Pred(bra));
  Vs := Copy(aFileName,Succ(bra),Length(aFileName));
  ket := nvl2i(Pos('.',Vs),Length(vs));
  aFileName := sCopyName + Copy(aFileName,Succ(ket),Length(aFileName));
  result := Copy(vs,1,Pred(ket));
end;}

function GetFileNameTimeStampDT(aFileName: string; const aDTStamp: TDateTime): String;
var
  vs,vFPath,vStamp,vFName,vFExt: string;
begin
  DateTimeToString(vs,TStampMask, aDTStamp);
  vFPath := ExtractFilePath(aFileName);

  if ParseFileNameByStamp(ExtractFileName(aFileName),vStamp,vFName,vFExt) <0 then
    Result := vFPath+Format('%s.%s',[vs,vFName])
  else
    Result := vFPath+Format('%s.%s%s',[vs,vFName,vFExt]);
end;

function ResetFileNameTimeStamp(aFileName: string): String;
var
  iFAge: integer;
  sNewName: String;
begin
  SetLength(result,0);
  iFAge := FileAge(aFileName);
  if iFAge <0 then Exit;
  Result := aFileName;
  sNewName := GetFileNameTimeStampDT(aFileName, FileDateToDateTime(iFAge));
  if (sNewName <>aFileName) and RenameFile(aFileName,sNewName) then
    result := sNewName;
end;


function MoveFileWithStamp(const aFileSrc, aPath: string): LongInt;
var
  vPath,sFromName,sNewName,sFromPath: string;
begin
  Result := -2;
  sFromName := ResetFileNameTimeStamp(aFileSrc);
  vPath := aPath;
  if IsDirectoryName( vPath, TRUE) then
  try // move to new location
    sFromPath := ExtractFilePath(sFromName);
    FileUtil.MoveFile( sFromName, vPath+ ExtractFileName( sFromName));
    result := 0;
//  if RenameFile(sFromName,aPath+ExtractFileName(sFromName)) then
//    Result := CopyFileByPath(sNewName,ExtractFilePath(sNewName)+sPath,TRUE);
  except
    Result := -1;
  end;
end;

function CopyFileByPath( sFileSrc, sPath: string; const IsMove: bool=FALSE): Longint;
var
  sv: string;
begin
  result := -2;
  if not FileExists(sFileSrc) then exit;
  while Length(sPath) >0 do
  begin
    sv := GrepSepString( sPath, ';',$4);
    if IsDirectoryName( sv, TRUE) and (ExtractFilePath( sFileSrc) <>sv) then
    try
      if isMove then
        FileUtil.MoveFile( sFileSrc, sv + ExtractFileName( sFileSrc))
      else
        FileUtil.CopyFile( sFileSrc, sv + ExtractFileName( sFileSrc), nil);
      result := 0;
    except
      result := -1;
      break;
    end;
  end;
end;

end.

unit winInetFiles;

interface
uses WinInet;

implementation
 
function DownloadFile(const Url: string): string;
var
  NetHandle: HINTERNET;
  UrlHandle: HINTERNET;
  Buffer: array[0..1024] of Char;
  BytesRead: dWord;
begin
  Result := '';
  NetHandle := InternetOpen('Delphi 5.x', INTERNET_OPEN_TYPE_PRECONFIG, nil, nil, 0);
  if Assigned(NetHandle) then 
  begin
    UrlHandle := InternetOpenUrl(NetHandle, PChar(Url), nil, 0, INTERNET_FLAG_RELOAD, 0);
    if Assigned(UrlHandle) then
    begin
      FillChar(Buffer, SizeOf(Buffer), 0);
      repeat
        Result := Result + Buffer;
        FillChar(Buffer, SizeOf(Buffer), 0);
        InternetReadFile(UrlHandle, @Buffer, SizeOf(Buffer), BytesRead);
      until BytesRead = 0;
      InternetCloseHandle(UrlHandle);
    end
    else
      raise Exception.CreateFmt('Cannot open URL %s', [Url]);
      InternetCloseHandle(NetHandle);
  end
  else
    raise Exception.Create('Unable to initialize Wininet');
end;

end.

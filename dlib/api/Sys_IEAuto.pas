unit Sys_IEAuto;

interface
uses Windows, Classes, SysUtils,
  ActiveX, MSHTML_TLB, Shdocvw_tlb;

type
  TObjectFromLResult = function(LRESULT: lResult; const IID: TIID;
                                WPARAM: wParam; out pObject): HRESULT; stdcall;

  TIE8Browser =class(TObject)
   private
     hInst: HWND;
     FWnd,
     FWndChild: HWND;
     FIE8: iwebbrowser2;
     FStatus: integer;
     pDoc: IHTMLDocument2;
     FList: TStringList;
     ObjectFromLresult: TObjectFromLresult;
     FOwnWebBrowser: bool;
     function    FGetIEFromHWND(WHandle: HWND; var IE: IWebbrowser2): HRESULT;
   published
     procedure   DumpTextToFile(const FName: string);
   public
     function    GetIE8TextFromHTML: TStrings;
     function    GetContentText: TStrings;
     procedure   OpenFile(const localFName: string);

     constructor CreateFromFile(const URL: string; const IsVisible: bool=TRUE);
     constructor CreateEmpty(const IsForced: bool=FALSE);
     destructor  Destroy;
  end;


implementation
uses dialogs, Variants,OLECtrls;


{unction TIE8Browser.WB_GetHTMLCode: Boolean;
var ps: IPersistStreamInit;
      ss: TStringStream;
      sa: IStream;
      s: string;
      Load:TStringList;
begin
try
Load:=TStringList.Create;
ps := WebBrowser1.Document as IPersistStreamInit;
s := '';
ss := TStringStream.Create(s);
try
sa := TStreamAdapter.Create(ss, soReference) as IStream;
Result := Succeeded(ps.Save(sa, True));
if Result then
Load.Add(ss.Datastring);
browserHTML:=Load.Text;
Load.Clear;
Load.free;
finally
ss.Free;
end;
except
end;
end;}



constructor TIE8Browser.CreateEmpty;
begin
  try
    inherited Create;
    hInst := LoadLibrary('Oleacc.dll');
    @ObjectFromLresult := GetProcAddress(hInst, 'ObjectFromLresult');
    if @ObjectFromLresult =nil then begin
      FreeLibrary(hInst);
      Fail
     end
    else begin
      if IsForced and ( FindWindow('IEFrame', nil) =0) then begin
        FIE8 := CoInternetExplorer.Create;
        FOwnWebBrowser := TRUE;
        FIE8.Visible := TRUE;
      end;
      FWnd := FindWindow('IEFrame', nil);
      if FWnd =0 then begin //No running instance of Internet Explorer so stop!
        FreeLibrary(hInst);
        Fail
       end
      else begin
        FWndChild := FindWindowEX(FWnd , 0, 'Frame Tab', nil);
        FWnd := FindWindowEX(FWndChild, 0, 'TabWindowClass', nil);
        FWnd := FindWindowEX(FWnd, 0, 'Shell DocObject View', nil);
        FWnd := FindWindowEX(FWnd, 0, 'Internet Explorer_Server', nil);
        if FWnd <>0 then
          FList := TStringList.Create;
        FStatus := integer( assigned(FList));
        FOwnWebBrowser := FALSE;
      end;
    end;
  except on e:Exception do
    begin
      showMessage('GetIE8 ' + e.Message);
    end;
  end;
end;

constructor TIE8Browser.CreateFromFile(const URL: string; const IsVisible: bool=TRUE);
begin
  inherited Create;
  hInst := LoadLibrary('Oleacc.dll');
  @ObjectFromLresult := GetProcAddress(hInst, 'ObjectFromLresult');
  if @ObjectFromLresult =nil then begin
    FreeLibrary(hInst);
    Fail
  end;

  if not assigned(FIE8) then begin
    FIE8 := CoInternetExplorer.Create;
    FOwnWebBrowser := TRUE;
  end;
  if IsVisible then
    FIE8.Visible := TRUE;
  OpenFile( URL);
end;


procedure TIE8Browser.OpenFile;
begin
  FIE8.Navigate( localFName, EmptyParam, EmptyParam, EmptyParam, EmptyParam);
end;


{procedure TIE8Browser.Button2Click(Sender: TObject);
var Winds: IShellWindows;
    IEWB: IWebBrowser2;
    i: integer;
    Doc: IHtmlDocument2;
begin
  Memo.Clear;
  Winds := CoShellWindows.Create;
  for i:=0 to Winds.Count-1 do
  if (Winds.Item(i) as IWEbBrowser2).Document <>nil then
  begin
    IEWB:=Winds.Item(i) as IWEbBrowser2;
    if IEWB.Document.QueryInterface(IhtmlDocument2, Doc)= S_OK
     then Memo.Lines.Add(Doc.url);
  end;
end;}

function TIE8Browser.GetIE8TextFromHTML(): TStrings;
var
  s: string;
begin
  FList.Clear;
{$ifdef DebugIE}
  showMessage('LoadIE8Text() entrance...');
{$endif}
  if (FStatus >0) and (FWnd <>0) and
    (FGetIEFromHWnd(FWnd, FIE8) =0) and (pDoc<>nil) {and (pDoc.ReadyState =pchar('complete'))} then begin
      s := pDoc.Body.innerText;  // Get Document text
{$ifdef DebugIE}
  showMessage('FGetIEFromHWnd() has done, TextList making');
{$endif}
      while length(s) >0 do begin
        if pos(#13#10, s) >1 then begin
          FList.Add( copy(s, 1, pos(#13#10, s)-1));
          s := copy(s, pos(#13#10, s)+2, length(s));
         end
        else begin
          FList.Add( s);
          break;
        end;
      end;
    end;
  result := FList;
end;


function TIE8Browser.GetContentText: TStrings;
begin
  result := FList;
end;

procedure TIE8Browser.DumpTextToFile(const FName: string);
begin
  GetContentText.SaveToFile( FName);
end;

function TIE8Browser.FGetIEFromHWND(WHandle: HWND; var IE: IWebbrowser2): HRESULT;
var
  lRes: Cardinal;
  MSG: Integer;
begin
{$ifdef DebugIE}
  showMessage('enter FGetIEFromHWND()...');
{$endif}
  if @ObjectFromLresult <> nil then
  begin
    MSG := RegisterWindowMessage('WM_HTML_GETOBJECT');
    SendMessageTimeOut(WHandle, MSG, 0, 0, SMTO_ABORTIFHUNG, 1000, lRes);
    Result := ObjectFromLresult(lRes, IHTMLDocument2, 0, pDoc);
{$ifdef DebugIE}
  showMessage(format('FGetIEFromHWND.ObjectFromLresult()... =%d',[result]));
{$endif}
    if Result = S_OK then begin
      (pDoc.parentWindow as IServiceprovider).QueryService(IWebbrowserApp,
                                                              IWebbrowser2, IE);
      FStatus := 4;
    end;
  end;
{$ifdef DebugIE}
  showMessage(format('exit FGetIEFromHWND()...=%d',[FStatus]));
{$endif}
end;


destructor TIE8Browser.Destroy;
begin
  if FOwnWebBrowser and (not VarIsEmpty(FIE8)) then
    FIE8 := nil;
  try
    if assigned(FList) then
      FList.Free;
  finally
    FreeLibrary(hInst);
  end;
end;

end.

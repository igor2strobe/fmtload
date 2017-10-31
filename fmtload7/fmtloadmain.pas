unit fmtloadmain;

interface

uses
  Sharemem,
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ComCtrls, ToolWin, SpeedBar, ExtCtrls, ImgList, Menus,
  PaymClass,
//xmlStatement,
  PaymMDIntrface,
  ActnList, StdCtrls, Grids, DBGrids, RXDBCtrl, dxBar, dxBarExtItems,
  cxStyles, cxCustomData, cxGraphics, cxFilter, cxData, cxDataStorage,
  cxEdit, DB, cxDBData, cxGridLevel, cxClasses, cxControls,
  cxGridCustomView, cxGridCustomTableView, cxGridTableView,
  cxGridDBTableView, cxGrid, cxCheckBox, StdActns, RXSplit, RXCtrls,
  Buttons, cxLookAndFeelPainters, cxButtons;

type
  TMainForm = class(TForm)
    StatusBar1: TStatusBar;
    ImageList1: TImageList;
    mnDataSources: TPopupMenu;
    mlFileSelectLoad: TMenuItem;
    N1: TMenuItem;
    mlDataSrcParam: TMenuItem;
    ActionList1: TActionList;
    acConnectDB: TAction;
    pgControl: TPageControl;
    TabSheet1: TTabSheet;
    TabSheet2: TTabSheet;
    Panel2: TPanel;
    tviewAcnt: TTreeView;
    TabSheet3: TTabSheet;
    memLog: TMemo;
    actDataSrcSelect: TAction;
    dlgOpenSrc: TOpenDialog;
    SysTimer: TTimer;
    acDataSrcParam: TAction;
    actDataSrcAdd: TAction;
    dxBarManager1: TdxBarManager;
    dxbrpmnConnect: TdxBarPopupMenu;
    dxbrlstmConnections: TdxBarListItem;
    cxGridViewRepository1: TcxGridViewRepository;
    cxGrid1: TcxGrid;
    lvSrcActive: TcxGridLevel;
    lvSrcClosed: TcxGridLevel;
    tvDSrcActive: TcxGridDBTableView;
    tvDSrcClosed: TcxGridDBTableView;
    tvDSrcActiveName: TcxGridDBColumn;
    tvDSrcActiveDriver: TcxGridDBColumn;
    tvDSrcActiveCheck: TcxGridDBColumn;
    pnDetail: TPanel;
    pnlDataSrcCaption: TPanel;
    Splitter: TSplitter;
    tvDSrcClosedCol1: TcxGridDBColumn;
    tvDSrcClosedCol2: TcxGridDBColumn;
    dxBarMRUListItem: TdxBarMRUListItem;
    actFileSelectLoad: TAction;
    miDataFolderLoad: TMenuItem;
    actDataFolderLoad: TAction;
    fmtMainPopupMenu: TdxBarPopupMenu;
    dxBarButtonExit: TdxBarLargeButton;
    FileExit: TFileExit;
    Action1: TAction;
    dxBarSubItemFile: TdxBarSubItem;
    dxBarButtonTestDrive1: TdxBarButton;
    dxBarSubItemOption: TdxBarSubItem;
    dxBarSubItem1: TdxBarSubItem;
    dxBarSubItem2: TdxBarSubItem;
    actModuleUpdate: TAction;
    dxBarSubItemHelp: TdxBarSubItem;
    dxBarButtonHistory: TdxBarButton;
    dxBarButton1: TdxBarButton;
    actAboutForm: TAction;
    miDataSrcAdd: TMenuItem;
    actDataSrcErase: TAction;
    miDataSrcErase: TMenuItem;
    mniN2: TMenuItem;
    lstcbFileNames: TRxCheckListBox;
    pnlInicator: TPanel;
    rxspltr1: TRxSplitter;
    actDoLoadFiles: TAction;
    btnLoadFromList: TcxButton;
    btnClearFList: TcxButton;
    procedure acConnectDBExecute(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure actDataSrcSelectExecute(Sender: TObject);
    procedure SysTimerTimer(Sender: TObject);
    procedure pgControlChange(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure acDataSrcParamExecute(Sender: TObject);
    procedure actDataSrcAddExecute(Sender: TObject);
    procedure tvDSrcActiveCheckPropertiesChange(Sender: TObject);
    procedure cxGrid1ActiveTabChanged(Sender: TcxCustomGrid;
      ALevel: TcxGridLevel);
    procedure dxBarMRUListItemClick(Sender: TObject);
    procedure actFileSelectLoadExecute(Sender: TObject);
    procedure actAboutFormExecute(Sender: TObject);
    procedure actDataSrcEraseExecute(Sender: TObject);
    procedure btnLoadFromListClick(Sender: TObject);
    procedure lstcbFileNamesClickCheck(Sender: TObject);
    procedure btnClearFListClick(Sender: TObject);
  private
    FLogTimerCounter: integer;
    FPBar: TProgressBar;
    FCurrFileMask: String;
//  FFileGetMode: integer; // 0: single mode, 1 - multiselect
    { Private declarations }
    procedure ConnectByMenuIdx(const aConnectStrIdx: Integer);
    function  SetupConnectMenu: integer;
    procedure AutoParamDbConnect;
    function  EraseSrcFile( aSrcFName: String): integer;

    function  ConvertSource( var aSrcFileName: String; const agentID: integer): integer;
    function  LoadFromRawTextByName(const aSrcFName: String): TCustStatement;

    function  PreProcessData( aStatement: TCustStatement; const aFSrcName:String): integer;
    function  BuildFileList: integer;
    function  UpdateFileCheckList(): integer;
    function  LoadFileList(const IsTotalsList: bool=TRUE): Integer;

    function  MainStoreData( aStatement: TCustStatement): integer;
    function  GetStatementFromFile(aSrcFName: TFileName): integer;

    procedure btnLoadFromListSet(const aCaption: String ; IsEnabled: boolean;
                    const iTag: integer);
  published
    function  OpenProgressBar(aCount: Integer; aInfo: String): Integer;
    procedure CloseProgressBar(const aPostMsg: String ='');
  public
    function  SetupSrcFileOpenDlg(aDlgFOpen: TOpenDialog; out aSrcFName: String): bool;
    function  LoadSingleStmt( const aLoadMask: String; const IsForClear: bool=FALSE): integer;
    function  FmtLoadSingleFile(aSrcFName: String): integer;
    function  FmtLoadDirectory(const aScanMask: String; const IsForClear: bool=FALSE): Integer;

    { Public declarations }
  end;

var
  MainForm: TMainForm;

implementation

uses fmtLoadAbout,
  datamodule, RxMemDs,
  Sys_uLog,Sys_iStrUtils,Sys_iStrList,Sys_CmdParam,sys_ifiles,sys_StrConv,
  oraStrSvc, dmodsvc, fmtloadDMSVC,
  ConverDLL, PaymStorage, fmtCurrNameSvc,
  fmtlDataSrcParamForm;

{$R *.dfm}


resourcestring
  sAnyFileMask  = 'Все файлы (*.*)|*.*';
//dbgAgentAccCount = '\\\ данные по ID:%d содержат %d счетов';
  sDataFromPathDone   ='По источнику ''%s'' обработка из ''%s'' завершена';

  msgDataSrcPathEmpty ='Не указано расположение данных источника ''%s''';
  msgDataSrcFindMask  ='...поиск файлов данных в ''%s''...';
  errDataPathNotFound =
  'Для источника ''%s'' расположение данных ''%s'' недоступно или не сущeствует';

// over for logging
procedure AddToLogProc( const aMsg: string; const lstLog: TStrings = nil;
   const iLevel: Word =$01);far;
begin
  if not assigned(lstLog) then
    dm.addToLog(aMsg, iLevel, mainForm.memLog.Lines)
  else dm.addToLog(aMsg, iLevel,lstLog);
end;


procedure TMainForm.acConnectDBExecute(Sender: TObject);
begin
  ConnectByMenuIdx( dxbrlstmConnections.itemIndex);
end;

procedure TMainForm.ConnectByMenuIdx(const aConnectStrIdx: integer);
var
  sConnectMenuStr: String;
begin
  SetLength(sConnectMenuStr, 0);
  if dm.OracleConnect(aConnectStrIdx) in [0,1] then  // Ok
  case pgControl.ActivePageIndex of
    0: begin
         sConnectMenuStr := dxbrlstmConnections.Items[aConnectStrIdx];
         cxGrid1ActiveTabChanged(nil, cxGrid1.ActiveLevel);
       end;
  end;
  cxGrid1.Enabled := IsOraConnected(dm.oraSession) and
     (not tvDSrcActive.DataController.DataSource.DataSet.IsEmpty);
  dxbrlstmConnections.Caption :=
   nvl2s(IsOraConnected(dm.oraSession), sConnectMenuStr,'Отключен');
end;

function TMainForm.SetupConnectMenu;
var
  i: integer;
begin
  result := -1;
  with dxbrlstmConnections do
  try
    Items.Clear;
    Items.BeginUpdate;
    if dm.FLogonParams.Count >0 then
    begin
      for i := 0 to dm.FLogonParams.Count-1 do
        Items.Add(GetSchemaString(dm.FLogonParams[i]));
      result := i;
    end;
  finally
    Items.EndUpdate;
  end;
end;

procedure TMainForm.AutoParamDbConnect;
const
  sAutoLogin ='AutoConnect';
begin
//if (abs(integer(dm.CfgParam(sMainSect,sAutoLogin,'FALSE',varBoolean))) >0) or
//  (abs(integer(dm.CfgParam(sMainSect,sAutoLogin,'0',varInteger))) >0) then
  if dm.FStartupOptions and dm.FStartupOptions =$2 then
    ConnectByMenuIdx(0);
end;

procedure TMainForm.FormActivate(Sender: TObject);
begin
  FLogTimerCounter := 2; // ONE sec delay before connecting
//SysTimer.Enabled := TRUE;
end;

procedure TMainForm.FormShow(Sender: TObject);
begin
  dxBarMRUListItem.ItemIndex := dm.FSysIni.ReadInteger(sMainSect,'FileGetMode',0);
  if SetupConnectMenu >1 then
    AutoParamDbConnect;
end;

function TMainForm.FmtLoadSingleFile(aSrcFName: String): integer;
var
  aStmt: TCustStatement;
  sr: TSearchRec;
  origFName: String;
  fresult: LongInt;
begin
  result := -2;
  if (pos('*',aSrcFName) =0) and (pos('?',aSrcFName) =0) then
  begin
    if FileExists(aSrcFName) then
      Result := LoadSingleStmt(aSrcFName)
    else addToLogP(format('файл ''%s'' не найден',[aSrcFName]));
  end;

  if result <0 then
  begin
    origFName := aSrcFName;
    result := ConvertSource(aSrcFName, dm.FCurrAgentID);
    if result >0 then
      Result := FmtLoadDirectory(aSrcFName,TRUE);
{     if FindFirst(aSrcFName, faArchive, Sr) =0 then
      begin
        repeat
          result := LoadSingleStmt(ExtractFilePath(aSrcFName)+sr.Name,2);
          if result <0 then Break;
        until FindNext(sr) <>0;
        FindClose(sr);
      end;}
//  if result =0 then
//    MoveFileWithStamp(origFName,dm.FBackupName);
  end;
end;

function TMainForm.LoadSingleStmt(const aLoadMask: String;
                                 const IsForClear: bool=FALSE): integer;
var
  aStmt: TCustStatement;
begin
  try
    result := -2;
    Cursor := crSQLWait;
    aStmt := LoadFromRawTextByName(aLoadMask);
    if assigned(aStmt) and (PreProcessData(aStmt,aLoadMask) >=0) then
    begin
      result := MainStoreData(aStmt);
      if result >=0 then
      begin
         if IsForClear then
           EraseSrcFile( nvlStr(aLoadMask,aStmt.FSrcName))
         else
         if dm.FBackupName<>'' then
           MoveFileWithStamp(nvlStr(aLoadMask,aStmt.FSrcName),
                   ExtractFilePath(aLoadMask)+ dm.FBackupName);
      end;
    end;
  finally
    FreeAndNil(aStmt);
    Cursor := crDefault;
  end;
end;


procedure TMainForm.actDataSrcSelectExecute(Sender: TObject);
begin
  if dm.FCurrAgentID <=0 then Exit;
  SetLength(FCurrFileMask,0);
  if dxBarMRUListItem.ItemIndex =0 then
    actFileSelectLoadExecute(Sender)  // file open dialog
  else
    FCurrFileMask := Trim(dm.orQryDataSrc[sdbHandlerName]);

  BuildFileList;
end;

procedure TMainForm.SysTimerTimer(Sender: TObject);
begin
  if FLogTimerCounter >0 then
    Dec(FLogTimerCounter);
//SysTimerHandler();
  if FlogTimerCounter =1 then begin
    SysTimer.Enabled := FALSE;
    AutoParamDbConnect;
  end;
end;


procedure TMainForm.pgControlChange(Sender: TObject);
begin
  cxGrid1ActiveTabChanged(nil, cxGrid1.ActiveLevel);
end;


function TMainForm.ConvertSource(var aSrcFileName: String;
                                   const agentID: integer): integer;
var
  LoadDllName,sProcName,ModelName,vExtAccntNames: string;
  DllFunc: TConversionFunc;
  lhDll: THandle;
  lstMatching,lExtNames: TStringList;
  fLogProc: TRemoteLogProc;
const
  errGetProcAddressStr = 'Ошибка определения адреса обработчика ''%s''';
  msgDLLNameInfo       = '/// для конверсии определен DLL-контейнер: ''%s''';
  msgDllReadyInfo      = '/// конвертер ''%s'':%s загружен';
  errDllCallException  = '%s.%s: ошибка в процессе конверсии ''%s''';
  resSrcConversionStr  = '''%s'': %d элементов прочитано';
  xmlMatchesMask: String = 'AS "PrivatBank"'^M+
                           'NORVIK BANKA - Statement'^M+
                           'АО "TRASTA KOMERCBANKA"';
begin
  result := 0;
  sProcName := 'fmtLoads';
  try
    LoadDllName := dm.GetAgentProcLibName( sProcName);
    if Length( LoadDllName) =0 then exit;
    addToLogP(format(msgDllNameInfo,[LoadDllName]),3);

    lhDll := dm.LoadDLLFunc( PChar(LoadDllName));
    if lhDll =0 then
      addToLogP(format('не загружен DLL-контейнер ''%s''',[LoadDllName]))
    else
    begin
      @DllFunc := GetProcAddress(lhDll, PChar(sProcName));
      if not assigned(@DllFunc) then
        addToLogP(format(errGetProcAddressStr,[sProcName]))
      else
      try
        addToLogP(format(msgDllReadyInfo, [LoadDllName,sProcName]),3);
        lExtNames := TStringList.Create;
        if dmGetDataSourceParams(ModelName, lstMatching) >=0 then
        try
          dm.FSysIni.ReadSectionValues('ExtNames', lExtNames);
          fLogProc := AddToLogProc;

          result := DllFunc( AgentID, lstMatching, dm.oraSession, @fLogProc,
                              [aSrcFileName, ModelName, IntToStr(dm.SysLog),
                               lExtNames.Text]);
          if result >0 then
            aSrcFileName := CurrFNameTranslate(aSrcFileName,'',agentID);
        except
          addToLogP(format(errDllCallException,[LoadDllName,sProcName,aSrcFileName]));
        end;
        if result >0 then
          addToLogP(format(resSrcConversionStr,[aSrcFileName,result]),2);
      finally
        lExtNames.Free;
        if Assigned(lstMatching) then
          lstMatching.Free;
      end;
     end;
  finally
    FreeLibrary(lhDll);
  end;
end;

procedure TMainForm.acDataSrcParamExecute(Sender: TObject);
begin
  if Assigned(dm.orQryDataSrc) and (not dm.orQryDataSrc.IsEmpty) then
  try
    frmDataSrcParam := TfrmDataSrcParam.Create(MainForm);
    frmDataSrcParam.SetData(dm.orQryDataSrc, cxGrid1.ActiveLevel.Tag);
    IsNewDataSrcAgentAction := False;
    if frmDataSrcParam.showModal =mrOk then
    begin
      if dm.UpdateDataSourceParam([frmDataSrcParam.edCorrID.Text,
                                   frmDataSrcParam.edDataSourceName.Text,
                                   frmDataSrcParam.edLibraryName.Text,
                                   frmDataSrcParam.edDataSouceFilePath.text,
                                   IntToStr(frmDataSrcParam.rgrpDriverName.ItemIndex),
                                   IntToStr(Integer(frmDataSrcParam.cbHide.Checked))]) <0 then
        AddToLogP('Ошибка сохранения параметров источника данных');
      dm.RefreshSourceDataGrid( memLog.Lines, cxGrid1.ActiveLevel.Tag);
    end;
  finally
    frmDataSrcParam.Free;
  end;
end;

procedure TMainForm.actDataSrcAddExecute(Sender: TObject);
begin
  IsNewDataSrcAgentAction := True; // "New DataSource" selected from menu
  acDataSrcParamExecute(Sender);
end;


function TMainForm.EraseSrcFile(aSrcFName: string): integer;
begin
  aSrcFName := ChangeFileExt(aSrcFName, format('.%d',[dm.FCurrAgentID]));
  if Deletefile(aSrcFName) then
    addToLogP(format('//"%s": завершено, фaйл удален', [aSrcFName]),2);
end;


function TMainForm.PreProcessData;
var
  sAgent: string;
  k: integer;
  fSourced,fChecked: Double;
  PAccnt: TPaymAccount;
const
  sErrNotAssigned  = '/ элемент %d выписки ''%s''[''%s''] не определен';
  sErrHasnotOpers  = '// счет %s выписки ''%s''[''%s''] не содержит операций';
  sAskForcedSaving =  #13#10' значение остатка в данных =%14.2f'#13#10+
                            ' не совпадает с расчетным значением =%14.2f'#13#10+
                            ' Сохранять ли данные принудительно?';
begin   // validate (or create) account
  result := -2;
  if not Assigned(aStatement) then Exit;
  result := 0; k := 0;
  while k <aStatement.Count do
  begin
    if not assigned(aStatement[k]) then
    begin
      aStatement.Delete(k);
      AddToLogP(format(sErrNotAssigned,[k,aStatement.OwnerName,aFSrcName]),1);
     end
    else
    if TPaymAccount(aStatement[k]).Count =0 then
     try
       AddToLogP(format(sErrHasnotOpers, [TPaymAccount(aStatement[k]).spAccount,
                                           aStatement.OwnerName,aFSrcName]),2);
       TPaymAccount(aStatement[k]).Free;
     finally
       aStatement.Delete(k);
     end
    else begin
      PAccnt := TPaymAccount(aStatement[k]);
      PAccnt.OwnerName := nvlstr(PAccnt.OwnerName,aStatement.OwnerName);
      sAgent := format('''%s'':%d ''%s:%s''', [PAccnt.OwnerName,
                          aStatement.AgentID, PAccnt.spAccount,PAccnt.CurrCh]);
      result := dm.GetAccntParams(PAccnt);
      if (dm.DataCheck >0) and (result <0) then begin
        Inc(k);
        Continue;
      end;
      sAgent := sAgent + Format(':%d',[PAccnt.AccountID]);
      result := PAccnt.ConvertToMemdata(dm.mdTemplate, dm.DataLogLevel);
      case result of
        -2: AddToLogP(sAgent+': ошибка создания md-таблицы данных');
        -1: AddToLogP(sAgent+': ошибка заполнения md-таблицы данных');
       else
       begin
         result := PAccnt.Validate(dm.FDataSortStr, dm.DataCheck); // validating&sorting items
         case result of
           0: addToLogP(sAgent+': нет данных md-таблицы');
          -1: addToLogP(sAgent+': oшибка проверки остатков md-таблицы');
          -2: addToLogP(sAgent+': ошибка состояния md-таблицы данных ');
         else // совпадают ли остатки?
           if (dm.DataCheck >1) and (Paccnt.MDStatus(fSourced,fChecked) =0) then
           begin
             sAgent := format(sAgent + sAskForcedSaving, [fSourced,fChecked]);
             AddToLogP(sAgent, 2);
             if MessageDlg(sAgent,mtConfirmation,[mbYes,mbCancel],0) =idYes then
               addToLogP('Принято решение сохранить данные',2)
             else begin
               addToLogP('Принято решение отменить сохранение',2);
               result := -1;
               break;
             end;
           end;
         end;//case =Validate()
       end
      end;//case =ConvertToMemdata()
      Inc(k);
    end;
  end;
end;


function TMainForm.MainStoreData;
begin
  result := dm.StoreOraData(aStatement);
end;


function TMainForm.LoadFromRawTextByName(const aSrcFName: String): TCustStatement;
var
  lstText: TStringList;
  Statement: TCustStatement;
  sMsg,sStatmParamValues: String;
  Param: word;
begin
  result := nil;
  Param  := 0;
  SetLength(sMsg, 0);
  if dm.SysLog >2 then Param := Param or $02;
  try
    Cursor := crHourGlass;
    lstText := LoadListFromFile(aSrcFName, sMsg, Param);

    if not assigned(lstText) then
      AddToLogP(sMsg)
    else
    begin
      addToLogP(format('///"%s": trying to treat as 1CClientBankExchange',[aSrcFName]),3);
      sStatmParamValues := TestValidRawMatch(lstText,sMsg);

      if (Length(sMsg) >0) and (param and $02 =$02) then
        AddToLogP( aSrcFName+': '+sMsg)
      else
      if Length(sStatmParamValues) >0 then
      begin

        if IsValidEmptyStmt(lstText, sMsg) <>0 then
          AddToLogP(aSrcFName+': '+sMsg)
        else
        begin
          Statement := TCustStatement.CreateAtList(lstText, dm.FCurrAgentID,
                                 sStatmParamValues, @AddToLogProc, memLog.Lines);

          if assigned( Statement) then
          begin
            addToLogP(format('///"%s": выписка создана, счетов= %d',
                          [aSrcFName,Statement.Count]),3);
            result := Statement;
           end
          else
          if (Length(sMsg) =0) and (Param and $02 =$02) then
            addToLogP(format('"%s": данные не могут быть распознаны',[aSrcFName]));
         end;
      end;
    end;
  finally
    if assigned(lstText) then
      lstText.Free;
    Cursor := crDefault;
  end;
end;


procedure TMainForm.tvDSrcActiveCheckPropertiesChange(Sender: TObject);
var
  sMsg: String;
const
  msgHasntDriver   = 'не определен обработчик для "%s"';
begin
  try
    cxGrid1.Enabled := False;
    tvDSrcActive.DataController.DataSource.DataSet.DisableControls;
    if dmIsConnectionOk(dm.OraSession) then
    begin
{     sMsg := format(msgHasntDriver,[UpperCase(dm.FCorrName)]);
      AddToLogProc(sMsg,memLog.Lines,3);
      sMsg := sMsg + #13#10' прочитать данные как ' + RawFmtFirst + '?';
      if (dm.DataLogLevel <3) or
        (MessageDlg(sMsg,mtConfirmation,[mbYes,mbCancel],0) =mrYes) then
        dm.FCurrAgentID := dm.orqryDataSrc.fieldByName('UIN_Corr').asInteger;}
      actDataSrcSelectExecute(Sender);
    end;
  finally
    tvDSrcActive.DataController.DataSource.DataSet.EnableControls;
    dm.orqryDataSrc['ChkPoint'] := 0;
    cxGrid1.Enabled := TRUE;
  end;
end;

procedure TMainForm.cxGrid1ActiveTabChanged(Sender: TcxCustomGrid;
  ALevel: TcxGridLevel);
begin
  dm.RefreshSourceDataGrid(memLog.Lines, ALevel.Tag);
  actDataSrcErase.Visible := ALevel.Tag =2;
  actDataSrcAdd.Visible   := ALevel.Tag =1;
end;

procedure TMainForm.dxBarMRUListItemClick(Sender: TObject);
begin
  case dxBarMRUListItem.ItemIndex of
   0:  AddToLogP('выбрана загрузка одиночных файлов',2);
   1:  AddToLogP('выбрана пакетная загрузка файлов',2);
  end;
  dm.FSysIni.WriteInteger(sMainSect,'FileGetMode',dxBarMRUListItem.ItemIndex);
end;

function TMainForm.SetupSrcFileOpenDlg( aDlgFOpen: TOpenDialog;
  out aSrcFName: String): bool;
var
  sFilter: String;
  dbPathStr,dbSrcName,sName,sExt:String;
const
  dbgIDAgent = '/// данные по ID:%d';
begin
  aDlgFOpen.InitialDir := '';
  aDlgFOpen.DefaultExt := '';
  aDlgFOpen.Filter     := '';
  Result := FALSE;
  try
    if dm.orQryDataSrc.IsEmpty then Exit;

    dbPathStr := Trim(dm.orqryDataSrc[sdbHandlerName]);
    dbSrcName := dm.orQryDataSrc[sdbCorrName];
    sFilter   := '';
    while Length(dbPathStr) >0 do
    begin
      sName := GrepSepString(dbPathStr,';',0);
      sExt  := ExtractFileExt(sName);
      if Length(sExt) =0 then Continue;
      sFilter := sFilter + '*'+ sExt +';';

      if Length(aDlgFOpen.DefaultExt) =0 then
        aDlgFOpen.DefaultExt := sExt;
      if Length(aDlgFOpen.InitialDir) =0 then
        aDlgFOpen.InitialDir := ExtractFilePath(sName);
    end;
  finally
    sFilter := sFilter + format('*.%3.3d',[dm.FCurrAgentID]);
    aDlgFOpen.Filter := nvlstr(format('источник ''%s'' (%s)|%s',
             [dbSrcName,sFilter,sFilter]), sAnyFileMask);
  end;
  Result := aDlgFOpen.Execute;
  if result then
  begin
    aSrcFName := aDlgFOpen.FileName;
    if FileExists( aSrcFName) then
      addToLogP(format(dbgIDAgent,[dm.FCurrAgentID]),3);
  end;
end;


procedure TMainForm.actFileSelectLoadExecute(Sender: TObject);
var
  vSrcName: string;
begin
  if SetupSrcFileOpenDlg(dlgOpenSrc,vSrcName) then
    FCurrFileMask := vSrcName;
end;

function TMainForm.FmtLoadDirectory(const aScanMask: String;
                          const IsForClear: bool=FALSE): Integer;
var
  sr: TSearchRec;
  sFilePath: String;
  tResult,eResult: integer;
begin
  result := 0; eResult := 0;
  if FindFirst(aScanMask,faArchive,Sr) =0 then
  try
    sFilePath := ExtractFilePath(aScanMask);
    repeat
      tResult := FmtLoadSingleFile(sFilePath+Sr.Name);
      if tResult <0 then
        eResult := tResult
      else Inc(result, tResult);
    until FindNext(Sr) <>0;
    if eResult <>0 then
      result := eResult;
  finally
    FindClose(Sr);
//  StatusBar1.SimpleText := format(sDataFromPathDone,
//                                  [dm.orQryDataSrc[sdbCorrName],aScanMask]);
  end;
end;


procedure TMainForm.actAboutFormExecute(Sender: TObject);
begin
  with TFmtLoadAboutForm.Create(nil) do
  try
    SetData(dm.FVersInfo.FileVersion);
    ShowModal;
  finally
    Free;
  end;
end;

procedure TMainForm.actDataSrcEraseExecute(Sender: TObject);
begin
  if MessageDlg(format('Желаете удалить источник данных %s[%d]',
    [dm.FCorrName,dm.FCurrAgentID]),mtConfirmation,[mbYes,mbCancel],0) =idYes then
    dm.LogoffDataSource;
end;


function TMainForm.OpenProgressBar(aCount: Integer; aInfo: String): integer;
begin
  Result := 0;
  if aCount >0 then
  try
    StatusBar1.SimplePanel := False;
    StatusBar1.Panels[0].Width := cxGrid1.Width;
    StatusBar1.Panels[1].Text  := aInfo;

    fpbar := TProgressBar.Create(StatusBar1);
    fpbar.Parent := StatusBar1;
    fpbar.Max    := aCount;
    fpbar.Width  := StatusBar1.Panels[0].Width;
    fpbar.Height := StatusBar1.ClientHeight - 2;
    fpbar.Left   := 0;
    fpbar.Top    := 2;
    fpbar.Visible := True;
  except
    if Assigned(fpbar) then
      freeAndNil(fpbar);
    Result := -2;
  end;
end;

procedure TMainForm.CloseProgressBar;
begin
  try
    if Assigned(FPBar) then
      FreeAndNil(FPBar);
  finally
    StatusBar1.Panels[1].Text := '';
    StatusBar1.SimplePanel := True;
    StatusBar1.SimpleText  := aPostMsg;
  end;
end;


function TMainForm.LoadFileList(const IsTotalsList: bool=TRUE): Integer;
var
  j,iStored: Integer;
  vStmt: TCustStatement;
  sr: TSearchRec;
  sSourceFile,vOriginalFName,sSubFName: String;
const
  sMsgFileErased = '//"%s": завершено, фaйл удален';

  function MatchFName(const i: Integer; var vStr: string): bool;
  var
    k: integer;
  begin
    SetLength(vStr,0);
    Result := False;
    if (lstcbFileNames.Items.Count >i) and
      (IsTotalsList or lstcbFileNames.Checked[i]) then
    for k := 0 to dm.FSrcFiles.Count -1 do
      if Pos(lstcbFileNames.Items[i], dm.FSrcFiles[k]) >0 then
      begin
        Result := FileExists(dm.FSrcFiles[k]);
        if result then begin
          vStr := dm.FSrcFiles[k];
          Break;
        end;
      end;
  end;

  function StoreReadyStmt(aStmt: TCustStatement;
     const aStmtFName: String; const isOrigSrcFile: BOOL= True): integer;
  begin
    if assigned(aStmt) then
    try
      Result := PreProcessData(aStmt,aStmtFName);
      if result >=0 then
      begin
        result := MainStoreData(aStmt);
        if result >=0 then
        begin
{         if IsForClear then
            EraseSrcFile( nvlStr(aStmtFName,aStmt.FSrcName))
           else}
          if isOrigSrcFile and (Length(dm.FBackupName) >0) then
            MoveFileWithStamp(nvlStr(aStmtFName,aStmt.FSrcName),
                              ExtractFilePath(aStmtFName)+ dm.FBackupName);
        end;
       end
    finally
      FreeAndNil(aStmt);
    end;
  end;

begin
  Result := -1;
  if dm.FSrcFiles.Count =0 then Exit;

  try
    Cursor := crHourGlass;
    OpenProgressBar(lstcbFileNames.Items.Count,'Чтение файлов данных...');
    j := 0;
    while j <lstcbFileNames.Items.Count do
    begin
      if MatchFName(j,sSourceFile) then
      begin
        vOriginalFName := sSourceFile;
        // block file treatment
        vStmt := LoadFromRawTextByName(sSourceFile);
        if assigned(vStmt) then
          StoreReadyStmt(vStmt,sSourceFile)
        else
        begin
          if ConvertSource(sSourceFile, dm.FCurrAgentID) >=0 then
          begin
            iStored := 0;
            if FindFirst(sSourceFile,faArchive,Sr) =0 then
            try
              repeat
                sSubFName := ExtractFilePath(sSourceFile)+sr.Name;
                vStmt := LoadFromRawTextByName(sSubFName);
                if Assigned(vStmt) then
                  iStored := iStored + StoreReadyStmt(vStmt,sSubFName,False);
                if Deletefile(sSubFName) then
                  addToLogP(format(sMsgFileErased,[sSubFName]),2);
              until FindNext(sr) <>0;
            finally
              FindClose(sr);
              if (iStored >0) and (Length(dm.FBackupName) >0) then
                MoveFileWithStamp(vOriginalFName,
                              ExtractFilePath(vOriginalFName)+dm.FBackupName);
            end;
          end;
        end;
        // block file treatment end
        lstcbFileNames.Items.Delete(j);
       end
      else
      if not IsTotalsList then
        inc(j);
      FPBar.StepIt;
    end;
  finally
    lstcbFileNamesClickCheck(Self);
    CloseProgressBar;
    Cursor := crDefault;
  end;
  btnLoadFromListSet('', lstcbFileNames.Items.Count >0, 0);
//  btnLoadFromList.Enabled := lstcbFileNames.Items.Count >0;
  btnClearFList.Enabled := btnLoadFromList.Enabled;

  StatusBar1.SimpleText := '';
end;

function TMainForm.BuildFileList: integer;
var
  vMsg: string;
begin
  Result := 0;
  SetLength(vMsg,0);
  try
    StatusBar1.SimpleText := 'Собираем список файлов...';
    Result := dm.GetSrcMaskList(FCurrFileMask, lstcbFileNames.Items);
 //   UpdateFileCheckList();
    lstcbFileNamesClickCheck(Self);
  finally
    if Result >0 then
      vMsg := Format('Найдено файлов: %d',[result]);
    AddToLogProc(vMsg);
    StatusBar1.SimpleText := vMsg;
  end;
end;


function  TMainForm.UpdateFileCheckList;
var
  i: integer;
  vFName: string;
begin
  Result := 0;
  if Assigned(dm.FSrcFiles) and (dm.FSrcFiles.Count >0) then
  with lstcbFileNames do
  begin
    Items.BeginUpdate;
    for i := 0 to dm.FSrcFiles.Count -1 do
    begin
      vFName := ExtractFileName(dm.FSrcFiles[i]);
      if Items.IndexOf(vFName) <0 then
      begin
        Items.Add(vFName);
        lstcbFileNames.Checked[Items.Count] := True;
      end;
    end;
    Items.EndUpdate;
    result := Items.Count;
  end;
end;


procedure TMainForm.btnLoadFromListClick(Sender: TObject);
begin
  if lstcbFileNames.Items.Count >0 then
  begin
    LoadFileList(btnLoadFromList.Tag <0);
  end;
  btnLoadFromListSet('', btnLoadFromList.Tag >=0, 0);
//  else btnLoadFromListSet('Прочитано',False,0);
  btnClearFList.Enabled := btnLoadFromList.Enabled;
end;


procedure TMainForm.lstcbFileNamesClickCheck(Sender: TObject);
var
  i: integer;
begin
  btnLoadFromList.Tag := -1;
  for i := 0 to lstcbFileNames.Items.Count -1 do
  begin
  //  lstcbFileNames.Items.BeginUpdate;
      if lstcbFileNames.Checked[i] then
      begin
        btnLoadFromList.Tag := i;
        Break;
      end;
  //  lstcbFileNames.Items.EndUpdate;
  end;

  btnLoadFromListSet('', btnLoadFromList.Tag >= 0, 0);
  btnClearFList.Enabled := btnLoadFromList.Enabled;
end;


procedure TMainForm.btnClearFListClick(Sender: TObject);
begin
  dm.FSrcFiles.Clear;
  lstcbFileNames.Clear;

//  btnLoadFromListSet('Загрузить', False, -1);
  btnLoadFromListSet('', False, -1);
  btnClearFList.Enabled := False;
end;


procedure TMainForm.btnLoadFromListSet(const aCaption: string; IsEnabled: boolean;
            const iTag: integer);
begin
  if Length(aCaption) >0 then
    btnLoadFromList.Caption := aCaption;

  btnLoadFromList.Enabled := IsEnabled;
  btnLoadFromList.Tag := iTag;
end;


function TMainForm.GetStatementFromFile(aSrcFName: TFileName): integer;
var
  lstText: TStringList;
  Statement: TCustStatement;
  sMsg,sStatmHeadValues: String;
  Param: word;
begin
  result := -2;
  lstText := LoadListFromFile(aSrcFName, sMsg, Param);
  addToLogP(format('///"%s": opening as 1CClientBankExchange',[aSrcFName]),3);
  try
    Statement := TCustStatement.Create('',dm.FCurrAgentID, @AddToLogProc,memLog.Lines);
    Statement.LoadFromText(lstText);

  finally
    Statement.Free;
  end

(*    if assigned(aStmt) and (PreProcessData(aStmt,aLoadMask) >=0) then
    begin
      result := MainStoreData(aStmt);
      if result >=0 then
      begin
         if IsForClear then
           EraseSrcFile( nvlStr(aLoadMask,aStmt.FSrcName))
         else
         if dm.FBackupName<>'' then
           MoveFileWithStamp(nvlStr(aLoadMask,aStmt.FSrcName),
                   ExtractFilePath(aLoadMask)+ dm.FBackupName);
      end;
    end;*)
end;

end.


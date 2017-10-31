unit datamodule;

interface

uses
  Sharemem,
  SysUtils, Windows, Classes, IniFiles, Dialogs,
  Graphics, AppEvnts, DB, DBTables,

  Ora, OraLogin,
  ConverDll,PaymClass,
  RxMemDS, RxDBCtrl, RxVerInf, DBAccess, MemDS;

type
 Tdm = class(TDataModule)
//  DES: TEncryption;
    ApplicationEvents: TApplicationEvents;
    mdTemplate: TRxMemoryData;
    OraSession: TOraSession;
    orqryLogon: TOraQuery;
    orqryDataSrc: TOraQuery;
    dsDataSrc: TDataSource;
    orqLockAccounts: TOraQuery;
//  odsLockAccounts: TOracleDataSet;
//  oqAddStatm: TOracleQuery;
//  oqLogon: TOracleQuery;
//  odsAgentGrid: TOraDataSet;
    procedure ApplicationEventsActivate(Sender: TObject);
    procedure ApplicationEventsDeactivate(Sender: TObject);
    procedure DataModuleCreate(Sender: TObject);
    procedure DataModuleDestroy(Sender: TObject);
    procedure OraSessionAfterConnect(Sender: TObject);
    procedure dsDataSrcDataChange(Sender: TObject; Field: TField);
  private
    { Private declarations }
    FSysLog: Word;            // уровень детализации журнала
    FDataLog: Word;           // уровень детализации листинга
    FDataCheck: Word;         // глубина проверки данных
    FConfigLogFName: string;
    FUserMode: Word;       // уровень привилегий пользователя, default =0
    FLogPtr: TStrings;        // указатель на TMemo.Lines
    FDriverList: TStringList;
    FDriverName: String;


    qryAccntAdd: TOraQuery;
    qryBalanceReset: TOraQuery;
    qryAccntParam: TOraQuery;
    qryAccntClear: TOraQuery;
    vDataSrcParamQuery: TOraQuery; // upd/ins datasource

    procedure  DumpVariables(const aOraQuery: TOraQuery; const iLevel: integer =3);

    function  InitVDataSrcParamQuery(const aProcName,aParamStr: String): integer;

    function  AddSourceFileToList(const aFullFName, aViewFName: String;
                        aList: TStrings; const aFStream: TFileStream =nil): integer;
    procedure AddSourceFileToCheckList(const aFName: String; aList: TStrings);
  published
    FSysIni: TIniFile;
    FSrcFiles: TStringList;
    FVersInfo: TVersionInfo;

    function  StatementDataDelete( aStatement: TCustStatement;
                                    const aAgentStr: String): integer;

    function  StoreStatement(aStatement: TCustStatement;
                 const aAgentStr: String; const IsForced: bool=FALSE): integer;
    function  StoreOraData(aStatement: TCustStatement): integer;

    procedure AddToLog( aMsg: string; const iLevel: word =$01; const lstLog: TStrings=nil);
    function  CfgParam(const aSection,aParam,aDefaultStr: String;
                              vType: TVarType): Variant;

 // запрос данных по счету или создание нового
    function  GetAccntParams(aData: TPaymAccount): integer;

    function  MakeDumpStrList(const iLevel: integer): TStringList;
//  function  PurgeDuplicates(var FData: TBankAccnt): integer; // удаление дубликатов

    function  LoadListParams(var lstParam: TStringList; const AgentId: integer): integer;
    function  GetAgentProcLibName(var DllFunctionName: string): string;
    procedure SetLogList(const aList: TStrings);
  public
    { Public declarations }
    FCurrAgentID: integer;
    FCorrName: String;
    FMaxAccnt: integer;

    FDataSortStr: String;
    FOraPKGName: String;
 // ----------------------------------------------------------------------------
    Delta_start_date: tdateTime;
    Delta_add_value: double;
    IsDeltaCheck: bool;
    IsDeltaLogForced: bool;
 // ----------------------------------------------------------------------------
    FStartupOptions: LongWord;
    FBackupName: String;
 // ----------------------------------------------------------------------------
    AppActive: boolean;
    ExclusiveLockFlag: bool;
//  IE8: TIE8Browser;
    FLogonParams: TStringList;
    FExtNameList: TStringList;

   function  RefreshSourceDataGrid( lstLog: TStrings; const aLevelTag: integer): integer;

   function  LoadParams( aCmdParams: array of ShortString): boolean;
   function  OracleConnect(const idConnect: integer): integer;
   function  LoadDLLFunc(const aDLLName: string): THandle;
// function  DefineSourceParams(const srcFName: string; ds: TDataSet; var sProcName: string): integer;
   function  UpdateDataSourceParam(aParam: array of string): integer;
   function  LogoffDataSource: integer;

   function  GetSrcMaskList(aSrcNames: String; aList: TStrings): integer;

   property  SysLog: Word read FSysLog;
   property  DataLogLevel: Word read FDataLog;
   property  DataCheck: word read FDataCheck;
   property  UserMode: Word read FUserMode;
 end;

const
  sMainSect   = 'main';
  sCheckSect  = 'check';
  sdbHandlerName = 'PATH_NAME';
  sdbCorrName    = 'CORR_NAME';

var
  dm: Tdm;


implementation

{$R *.dfm}

uses Forms,StrUtils,RxStrUtils,dbUtils,Variants,
     Sys_iStrUtils, Sys_uLog, Sys_StrConv, Sys_CmdParam,Sys_UMoney,
//   db_RefUtils,db_RxMDUtils,
     OraError,
     fmtloadDMSVC, oraStrSvc, dmodsvc,
     FmtLoadMain,
     PaymMDIntrface,
     Math;

const
  AccountALiveDateStr: shortstring ='31.12.2036';
  _Copyright_:string = 'Copyright (c) 2002 ProScale Holding';
  _Default_ 	= 'Default';
  _delta_       = 'DeltaCheck';
  _delta2       = 'Delta';
  _Name_ 	= 'Name';
  _Code_ 	= 'Code';
  _Base_ 	= 'Base';
  _Empty_	= '';
  VersionNumber :string[10] = 'v01.2';
  VersionDate   :string[10] = '20.08.2013';
  logsection    = 'logging';
  DataDescSection = 'DataDescription';

  sMainSortOrder ='CORR_ACNT_NAME;CA_PAY_DATE;CA_SUMM_DEBT;CA_SUMM_CRED;CA_DOCUMENT;DEBET_CLI_ACNT;CREDIT_CLI_ACNT;DEBET_CLI_NAME;CREDIT_CLI_NAME';

  errDataPathNotFound =
  'для ''%s'' директория ''%s'' недоступна или не сущeствует';

  sUpdPaymAgent_param =':iAgent,:AgentName,:LibName,:DataPath,:DrvName,:iHide,:iRes';

// -----------------------------------------------------------------------------

procedure Tdm.ApplicationEventsActivate(Sender: TObject);
begin
  AppActive := TRUE;
end;


procedure Tdm.ApplicationEventsDeactivate(Sender: TObject);
begin
  AppActive := FALSE;
end;


procedure Tdm.DataModuleCreate(Sender: TObject);
begin
  AppActive := TRUE;
  ExclusiveLockFlag := FALSE;
  FLogonParams := TStringList.Create;
  FDriverList  := TStringList.Create;
  FExtNameList := TStringList.Create;
//  StackList := TStringList.Create;
//  IE8 := TIE8Browser.Create;
  FSrcFiles := TStringList.Create;
end;

procedure Tdm.DataModuleDestroy(Sender: TObject);
begin
//  IE8.Free;
  FExtNameList.Free;
  freeAndNil( FDriverList);
  FreeAndNil( FLogonParams);
  FreeAndNil(qryAccntParam);
  FreeAndNil(qryAccntClear);
  FreeAndNil(qryBalanceReset);
  FreeAndNil(qryAccntAdd);
  if oraSession.Connected then
    oraSession.Connected := FALSE;
  FLogPtr := nil; // отключить вывод в журнал на экране
  FreeAndNil(FVersInfo);
  AddToLog( paramstr(0)+' halted'#13#10 + MakeStr('-',79));
  FreeAndNil(FSrcFiles);
  FreeAndNil(FSysIni);
end;


procedure Tdm.AddToLog( aMsg: string; const iLevel: word=$01; const lstLog: TStrings =nil);
var
  sFileLogName,FExtStr,msgStr: string;
begin
  if length(aMsg) =0 then exit;
  if SysLog >=iLevel then
  begin
    msgStr := DateTimeToStr(GetSysDate)+' '+ aMsg;
    FExtStr := '.'+ Copy(Date2Str(GetSysDate,'yyyymmdd'),5,4) +
                    nvlStr(ExtractFileExt(FConfigLogFName),'.log');
    sFileLogName := ReplaceFileExt(FConfigLogFName,FExtStr);

    sys_uLog.writeLog(sFileLogName, msgStr);
    if assigned(lstLog) then
      lstLog.Add( msgStr)
    else
    if assigned( FLogPtr) then
      TStringList(FLogPtr).Add( msgStr);

    if IsConsole then
      Writeln( StrToOem(aMsg));
  end;
end;


function Tdm.LoadParams;
var
  dummyWord: longWord;
  dummystr: string;
const
  sAutoConnect = 'AutoConnect';

  function IsParamInCommand(const aParamName: String): BOOL;
  var k: integer;
  begin
    Result := FALSE;
    for k := 1 to High(aCmdParams) do
      if SameText(aCmdParams[k],aParamName) then
      begin
        result := True;
        Break;
      end;
  end;

begin
  FSysIni := TIniFile.Create( aCmdParams[0]);
  FVersInfo := TVersionInfo.Create(appFileName);
  if assigned(FSysini) then
  with FSysIni do
  try
    FConfigLogFName := ReadString(logSection, 'ActionsFile',nvlstr(aCmdParams[0],ParamStr(0)));
    AddTolog( ParamStr(0)+' started..');

    FSysLog    := readinteger(logsection,'ActionsLog',
                              integer(readbool(logsection,'actionslog', TRUE)));
    FDataLog   := readinteger(logsection,'DataLog', 0);

    FDataCheck   := readinteger(sCheckSect,'DataCheck', 0);
    FDataSortStr := readString(sCheckSect,'SortOrder', sMainSortOrder);

    IsDeltaCheck := (readInteger(_delta_,'active',0)=1) or (readInteger(_delta2,'active',0)=1);
    IsDeltaLogForced := (readInteger(_delta_,'UpdateAlways',0)=1) or (readInteger(_delta2,'UpdateAlways',0)=1);
    Delta_start_date := readDate(_delta_,'start_date',
                        readDate( _delta2,'start_date', StrToDate('01.12.2011')));
    Delta_add_value := readFloat(_delta_,'delta_add',readFloat(_delta2,'delta_add',0));

    FmaxAccnt   := readInteger(sMainSect,'AccountNum',4);
    FOraPKGName := readString(sMainsect,'PackageName','PKG_FMTLOAD');
    FBackupName := readString(sMainsect,'BackupSubDirName','Backup');
    if AnsiSameText(FBackupName,'NULL') or AnsiSameText(FBackupName,'Empty') or
      AnsiSameText(FBackupName,'0') or AnsiSameText(FBackupName,'False') then
      SetLength(FBackupName,0);
    dummyStr    := readString(sMainsect,'UserMode','');

    if SameText(dummystr,'admin') or IsParamInCommand('admin') then
      FUserMode := FUserMode or $08;
    if SameText(dummystr,'sysdba') or IsParamInCommand('sysdba') then
      FUserMode := FUserMode or $10;

    dummyStr := ReadString( sMainSect, sAutoConnect,'FALSE');
    if SameText(dummyStr,'TRUE') or (Abs(Str2Int(dummyStr)) >0) then
      FStartupOptions := FStartupOptions or $2;

    if FOraPKGName ='' then
      addToLog('Не задано имя пакета функций БД');
    ReadSectionValues('ExtNames', FExtNameList);
    ReadSectionValues('Connect', FLogonParams);
    REadSectionValues('DriverName', FDriverList);
    result := TRUE;

    if FLogonParams.Count =0 then
      addToLog('Не найдены параметры подключения к БД')
    else begin
      FLogonParams.Add('Отключен');
    end;
  except
    addTolog( 'Недопустимое значение параметра настройки');
    result := FALSE;
  end;
end;


function Tdm.OracleConnect(const idConnect: integer): integer;
var
  sLogon,sMsg: string;
begin
  result := -2;
  if FLogonParams.Count <1 then
    addToLog(format('ошибка параметров подключения: %s', [FLogonParams.Text]))
  else
  if idConnect =FLogonParams.Count-1 then // запрос на "отключить"
   try
     addToLog('запрос отключения '+GetOraSessionUserString(OraSession),3);
     oraSession.Connected := FALSE;
     result := 0;
   except
     result := -1;
     addToLog('ошибка отключения '+GetOraSessionUserString(OraSession));
   end
  else begin
    sLogon := FLogonParams[idConnect];

    if not IsConnectStringValid(sLogon) then
      addToLog(format('"%s": строка подключения не соответствует формату',
                 [sLogon]))
    else begin
      Result := OpenOraConnectByConnectStr(OraSession,sMsg,sLogon);
      addToLog(sMsg);
    end;
  end;
end;


{function Tdm.DefineSourceParams(const srcFName: string; ds: TDataSet; var sProcName: string): integer;
begin
  FCurrAgentID := FGetDataSetField( ds, 'CorrID', varInteger);
  result := FCurrAgentID;
  sProcName := FGetDataSetField( ds, 'ProcName', varString) ;
end;}

// -----------------------------------------------------------------------------

// прочитать ВСЕ счета данного клиента из БД для обработки
(*
 // проверить существование счета, если есть - взять UIN -----------------------
 function  Tdm.TestClientAccount(var Hdr: TBankAccountRec;
                                 var Agent: TPayAgentRec): integer;
 var
    NewAcntCount: integer;
 begin
    NewAcntCount := 0;

    with TOracleDataSet.Create(Self), Hdr do
    try
       Session := OracleSession;
       CommitOnPost := FALSE;
       sql.add(' SELECT uin_corr_acnt FROM fin$CORR_PAY_ACNT');
       sql.add(format('WHERE UIN_CORR=%d AND ID_CURRENCY=%d AND ACCOUNT=''%s''',
                         [uin_corr, id_currency, account]));
//     debug := TRUE;
       open;
       if not EOF {or fields[0].AsInteger =0)} then
          UIN_CORR_ACNT := fields[0].asInteger //fieldByName('UIN_CORR_ACNT').asInteger;
       else
       begin // нет такого счета - заводим новый
          period.start_dt := date;
          result := //CreateNewAgentAccount(acHead);
            NewBankAccountHeader(Hdr);

          if result >0 then begin
             inc(NewAcntCount); // счетчик
//              читаем начальные остаток и дату
{	                if (ACNT_Flow_Debt <eps) and (ACNT_Flow_Cred <eps) then
   	                case TheCorr.DataType of
    	               1: InputRestOfAccountMail1(Head, 0);  // MS Access .MDB
  		               2: InputRestOfAccountMail2(Head, 0);  // DBF
		               3: ; // XML
                        4: if FList<> nil then
                             InputRestOfAccountMail4(Head, FList)  // AB LV, Text Files
                          else
                             MessageDlg('Нет данных для оценки входящего остатки ', mtError, [mbOk],0);
                       5: ; // Text
	                end;//case     }
          end;
	end;
   finally
      free;
      result := NewAcntCount;
   end;
 end;


 function Tdm.CheckAccount3( const agentID: integer; const accnt, CurrCh, agentName: shortString;
                             var currID, accntID: integer; var acntName: shortString;
                             const IsShowMsg: integer=1): integer;
 var
    errs: shortString;
 begin
     result := 0;
     if not IsOffline then
     with oraAccntChk do
     try //   fp_account_chk(:agentID, :currCh, :accnt, :ownername, :acntID, :currId, :sname, :flag);
        SetVariable('agentID', agentID);
        SetVariable('CurrCh',  currCh);
        SetVariable('accnt', accnt);
        SetVariable('ownername', agentName);
//        debug := TRUE;
        execute;
        result := GetVariable('flag');
        accntID  := GetVariable('acntID');
        CurrID   := GetVariable('currID');
        acntName := GetVariable('sName');

        if IsShowMsg =1 then
        case result of
         -1: begin
               errs := format('"%s" по %s заблокирован для загрузки.', [accnt, agentName]);
               mainform.memMessages.Lines.add(errs);
               if mainform.cbMessageDlg.Checked then
                  messageDlg(errs, mtError,[mbOk],0);
             end;
         -2: begin
               errs := format('Неизвестный литерал валюты.', [CurrCh ]);
               mainform.memMessages.Lines.add(errs);
               if mainform.cbMessageDlg.Checked then
                  messageDlg(errs, mtError,[mbOk],0);
             end;
        end;
     except
        result := -2;
     end;
     application.processMessages;
 end;


 function Tdm.GetAccountViewName(const agentID, currencyID: integer;
                                  const account: shortString): shortString;
 begin
     result := '';
     with TOracleDataSet.Create(self) do
     try
         Session := OracleSession;
         sql.add('SELECT fr_acntViewNameStr(:agentID, :currID, :str_acnt) from dual');
          declareVariable('agentID', otInteger);
          declareVariable('currID', otInteger);
          declareVariable('str_acnt', otString);
          setVariable('agentID', agentID);
          setVariable('currID', currencyID);
          setVariable('str_acnt', account);
          open;
          if not EOF then
            result := fields[0].asString;
     finally
         free;
     end;
     application.ProcessMessages;
 end;


 function TDm.CheckDBAccount(const agentID, currID: integer;
                             const accnt, acntView: shortString): integer;
 begin
     result := 0;
     with quAccountChk do
     try //   fp_chk_account(:agentID, :currID, :acntStr, :acntView, :acntID);
        SetVariable('agentID', agentID);
        SetVariable('currID',  currID);
        SetVariable('acntStr', accnt);
        SetVariable('acntView', acntView);
        execute;
        result := GetVariable('acntID');
     except
        result := -1;
     end;
     application.processMessages;
 end;


 function  TDM.CheckAccount(var CSD: TComSrcData): integer;
 var
    errs, tmpName: shortString;

    function GetAccountUIN(var AccountName: shortString): integer;
    begin
       result := 0;
       with TOracleDataSet.Create(self), CSD do
       try
          Session := OracleSession;
          CommitOnPost := FALSE;

          sql.add('SELECT uin_corr_acnt, corr_acnt_name');
          sql.add('FROM fin$CORR_PAY_ACNT');
          sql.add(format('WHERE UIN_Corr=%d AND ID_Currency=%d AND Account=''%s''',
                   [AgentID, mHead['fCurrID'], mHead['fAccount']]));
          open;
          if not EOF then
          begin
             result := fields[0].asInteger;
             AccountName := fields[1].asString;
          end;
          application.ProcessMessages;
       finally
          free;
       end;
    end;

 begin
    result := 0;
    tmpName := '';
    with CSD do begin
       mHead['fAccountID'] := GetAccountUIN (tmpName);
       if mHead['fAccountID'] =0 then begin
       // нет такого счета - заводим новый
          mHead['fAccountView'] := format('%s',[ AgentName + ' ' + mHead['fCurrCh']]);
          // подбираем имя счета
              with TOracleDataSet.Create(Self) do
              try
                 Session := OracleSession;
                 CommitOnPost := FALSE;

                 sql.add('SELECT corr_acnt_name FROM');
                 sql.add('( SELECT corr_acnt_name from fin$CORR_PAY_ACNT ');
                 sql.add(format('   WHERE Upper(corr_acnt_name)=Upper(''%s'')',
                         [ mHead.FieldByName('fAccountView').asString ]));
                 sql.add('   ORDER BY corr_acnt_name )');
                 sql.add('WHERE rownum=1');
                 open;
                 if not EOF then
                    mHead['fAccountView'] := fields[0].asString;
                 close;
                 application.ProcessMessages;
              finally
                 free;
              end;


        end
       else
          mHead['fAccountView'] := tmpName;

       if CSD.mHead['fAccountID'] =0 then begin
           //CSD.Period.Start_DT := date;
           //result := NewBankAccountHeader(Hdr);
              sql.clear;

              with TOracleQuery.Create(nil) do  // cоздаем собственно запись счета
              try
                 Session := OracleSession;

                 sql.add('INSERT INTO fin$CORR_PAY_ACNT');
                 sql.add(' (UIN_CORR, ID_CURRENCY, CORR_ACNT_NAME, ACCOUNT,');
                 sql.add(' PRED_VALUE_SUMM, PRED_SESS_DATE, CURR_SESS_DATE, PERIOD_START, PERIOD_END)');
                 sql.add(format('VALUES (%d, %d, ''%s'', ''%s'',',
                           [AgentID, mHead['fCurrID'], mHead['fAccountView'], mHead['fAccount']]));
                 sql.add(format('%f, SYSDATE, SYSDATE,  %f, ''%s'')',
                           [mHead['fInpValue'], mHead['fDateFrom'], AccountALiveDateStr]));
                 try
                    execute;
                    application.ProcessMessages;
                    OracleSession.Commit;
                 except on E:EOracleError do begin
                        OracleSession.Rollback;
                        application.ProcessMessages;
                        errs := format('Ошибка при создании нового счета платежного агента.'^M+
                                       'cчет: "%s"',[ mHead['fAccountView']]);
                        mainForm.memMessages.Lines.Add(errs);
                       if dload.ssOptions and $08=$08 then
                          messageDlg(Errs, mtError, [mbOk],0);
                    end;
                 end;
              finally
                 free;
              end;

              sql.add('SELECT UIN_CORR_ACNT FROM FIN$CORR_PAY_ACNT');
              sql.add(format('WHERE ID_CURRENCY=%d AND ACCOUNT=''%s'' AND UIN_CORR=%d',
                        [ID_Currency, account, UIN_CORR]));
       result := -1;
       open;
       UIN_CORR_ACNT := fields[0].asInteger;
       result := UIN_CORR_ACNT;
    finally
       free;
       application.ProcessMessages;
    end;


          if result >0 then
             inc(result); // счетчик

       end;
    finally
       free;
    end;
 end;

// -----------------------------------------------------------------------------

 function Tdm.GetAgentParams(TDs: TDataSet; var Agent: TPayAgentRec; Forced: bool): bool;
 begin
    result := FALSE;
    fillchar(Agent, SizeOf(TPayAgentRec), 0);

    with TOracleDataSet(TDs), Agent do
    if Active then
    try
         CorrID := fieldbyname('UIN_CORR').asInteger;
         // тут же проверяем - отмечен ли этот агент для платежа
//       if IsItemChecked(CorrID, ListCheck) or Forced then
         begin
            CorrName   := fieldbyname('CORR_NAME').asString;
            DriverName := fieldbyname('DRIVER_NAME').asString;
            LAST_SESS_DATE := fieldbyname('LAST_SESS_DATE').asDateTime;
            PATH_NAME  := fieldbyname('PATH_NAME').asString;
            Entry      := fieldbyname('dll_entry_point').asString;
            Alias      := fieldbyname('ODBC_alias').asString;
         end;
    finally
         result := Tds.Active and (Agent.CorrName <>'');
    end;
 end; *)


function Tdm.InitVDataSrcParamQuery(const aProcName,aParamStr: String): integer;
begin
  result := 0;
  if not assigned(vDataSrcParamQuery) then
  try
    vDataSrcParamQuery := TOraQuery.Create(nil);
    with vDataSrcParamQuery do
    begin
      Session := oraSession;
      sql.add('BEGIN');
      sql.add(' ' + FOraPkgName + aProcName + '(' + aParamStr +');');
      sql.add('END;');
 {$ifdef DOA}
      DeclareVariable('iAgent',    otInteger);
      DeclareVariable('AgentName', otString);
      DeclareVariable('LibName',   otString);
      DeclareVariable('DataPath',  otString);
      DeclareVariable('DrvName',   otString);
      DeclareVariable('iHide',     otInteger);
      DeclareVariable('iRes',      otInteger);
 {$else}
      ParamByName('iAgent').DataType    := ftInteger;
      ParamByName('AgentName').DataType := ftString;
      ParamByName('LibName').DataType   := ftString;
      ParamByName('DataPath').DataType  := ftString;
      ParamByName('DrvName').DataType   := ftString;
      ParamByName('iHide').DataType     := ftInteger;
      ParamByName('iRes').DataType   := ftInteger;
      ParamByName('iRes').ParamType  := ptOutput;
 {$endif}
    end;
    result := 1;
  except
    result := -2;
  end;
end;

// TO-DO fin$corr_external.Last_sess_date contains creation date
function Tdm.UpdateDataSourceParam(aParam: array of string): integer;
const
  procName  = 'UpdPaymAgent';
  sUpdDataSrcCalled = '// Ok: UpdPaymAgent(%s,%s,%s,%s,%s,%s,out %d)';
//UpdPaymAgent(iAgent integer, aAgentName varchar2, aLibName varchar2,
//  aDataPath varchar2, aDrvName varchar2, isHide integer, iRes out integer)
  sLoadDriverNames: array [0..3] of string = ('','Text','XML','HTML');
var
  k: integer;
  sDriverName: string;
begin
  result := 0;
  if not IsOraConnected(oraSession) then exit;
  aParam[4] := sLoadDriverNames[StrToInt(aParam[4])];

  if InitVDataSrcParamQuery(procName, sUpdPaymAgent_param) >=0 then
  try
 {$ifdef DOA}
    ClearVariables;
    vDataSrcParamQuery.SetVariable('iAgent', StrToInt(aParam[0]));
    vDataSrcParamQuery.SetVariable('AgentName', aParam[1]);
    vDataSrcParamQuery.SetVariable('LibName', aParam[2]);
    vDataSrcParamQuery.SetVariable('DataPath', aParam[3]);
    vDataSrcParamQuery.SetVariable('DrvName', aParam[4]);
    vDataSrcParamQuery.SetVariable('iHide', StrToInt(aParam[5]));
 {$else}
    vDataSrcParamQuery.ParamByName('iAgent').AsInteger   := StrToInt(aParam[0]);
    vDataSrcParamQuery.ParamByName('AgentName').AsString := aParam[1];
    vDataSrcParamQuery.ParamByName('LibName').AsString   := aParam[2];
    vDataSrcParamQuery.ParamByName('DataPath').AsString  := aParam[3];
    vDataSrcParamQuery.ParamByName('DrvName').AsString   := aParam[4];
    vDataSrcParamQuery.ParamByName('iHide').asInteger    := StrToInt(aParam[5]);
 {$endif}
    addToLog(format('/// %s query:'#13#10'%s',
                    [procname, vDataSrcParamQuery.SQL.Text]),3);
 {$ifdef debugSQL}
    Debug := TRUE;
 {$endif}
    vDataSrcParamQuery.execute;
 {$ifdef DOA}
    result  := vDataSrcParamQuery.GetVariable('iRes');
 {$else}
    result  := vDataSrcParamQuery.ParamByName('iRes').asInteger;
  {$endif}
    DumpVariables(vDataSrcParamQuery, 3);
    if result <0 then
      addToLog( format('Ошибка выполнения %s',[vDataSrcParamQuery.SQL.Text]))
    else
    begin
      vDataSrcParamQuery.session.Commit;
      addToLog(format(sUpdDataSrcCalled, [aParam[0], aParam[1],
                      aParam[2], aParam[3], aParam[4], aParam[4],result]), 2);
    end;
  except
    result := -8;
    addToLog(format('%s: исключение выполнения'#13#10'%s',
                    [procname,vDataSrcParamQuery.sql.text]));
  end;
end;

// -----------------------------------------------------------------------------
 // прочитать последний текущий баланс из загруженных выписок
(*
 function TDm.Get_LTK_Item_Stamp(AcntID: Cardinal; InStamp: ShortString): double;
 begin
     result  := 0.0;
     with TOracleDataSet.Create(Self) do
     try
        Session := OracleSession;
        sql.add(format('SELECT fpGetLatekoBalance(%d, ''%s'') from dual',[acntID, inStamp]));
        open;
        if not EOF then
           result  := fields[0].asFloat;
     finally
        free;
     end;
     application.ProcessMessages;
 end;

 function Tdm.FGetAccountBalance(const Id_accnt: integer): double;
 begin
   result := 0.0;
   if id_accnt >0 then
   with TOracleDataSet.Create(Self) do
   try
     Session := OracleSession;
     sql.add(format('select CalcExtAcntBalance(%d) from dual',[id_accnt]));
//   debug := true;
     open;
     result  := fields[0].asFloat;
   finally
     free;
   end;
 end;*)

// -----------------------------------------------------------------------------

function  Tdm.RefreshSourceDataGrid( lstLog: TStrings; const aLevelTag: integer): integer;
const
  sqlDataSrcSelect =
  'SELECT ds.*, 0 as ChkPoint'#13#10+
  '  FROM fin$corr_external ds'#13#10+
  ' WHERE ds.agent_flag >0'#13#10+
  '   AND Upper(ds.driver_name) <>''MANUAL'''#13#10;
const
  sAgentConditionStr: array[0..1] of String =
  (' AND agent_flag >1',' AND agent_flag =1');
begin
  result := -2;
  if IsOraConnected(oraSession) then
  with orqryDataSrc do
  try
    Close;
    if SQL.Count =0 then begin
      SQL.Add(sqlDataSrcSelect);
      SQL.Add('');
    end;
    SQL[SQL.Count-1] := sAgentConditionStr[aLevelTag-1];
 {$ifdef debugSQL}
    debug := TRUE;
 {$endif}
    Open;
    result := RecordCount;
  except
    addtoLog(format('ошибка запроса источников данных, ID:%d:%s',
              [fields[0].Value, fields[1].Value]));
    result := -1;
  end;
end;


function  Tdm.CfgParam(const aSection,aParam,aDefaultStr: String;
                             vType: TVarType): Variant;
var
  vbStr: String;
begin
  result := varEmpty;
  if assigned(FSysIni) then
  case vType of
    varInteger:
           result := FSysIni.ReadInteger(aSection, aParam,
                              Str2Int(nvlStr(aDefaultStr,'0')));
    varString:
           result := FSysIni.ReadString(aSection, aParam, aDefaultStr);
    varBoolean:
         begin
           vbStr := FSysIni.ReadString( aSection, aParam,
               BoolToStr(SameText( nvlStr(aDefaultStr,'FALSE'),'TRUE'),TRUE));
           result := SameText(vbStr,'TRUE') or (Abs(Str2Int(vbStr)) >0);
         end;
    else
     result := varNull;
  end;
end;


procedure Tdm.DumpVariables(const aOraQuery: TOraQuery; const iLevel: integer =3);
begin
  dmDumpVariables(dm,aOraQuery,iLevel);
end;


function Tdm.StatementDataDelete(aStatement: TCustStatement; const aAgentStr: String): integer;
begin
  result := dmStatementDataDelete(OraSession,qryAccntClear,aStatement,
                                FOraPkgName,aAgentStr,not OraSession.Connected);
end;

function Tdm.StoreOraData;
begin
  result := dmStoreOraData(OraSession,orqLockAccounts, aStatement,FOraPKGName,
                            Delta_add_value,IsDeltaLogForced, FALSE);
end;


function Tdm.StoreStatement;
begin
  result := dmStatementDataStore(OraSession,qryAccntAdd, qryBalanceReset,
    aStatement,FOraPKGName,aAgentStr, Delta_add_value,IsDeltaLogForced, IsForced);
end;


function Tdm.LoadDLLFunc(const aDLLName: string): THandle;
var
  ErrCode: Integer;
const
  sErrLoadDll ='Ошибка загрузки DLL "%s"';
begin
  result := 0;
  if not FileExists( aDLLName) then
    addToLog( format('Не найден DLL "%s"',[aDllName]))
  else
  try
    result := LoadLibrary(PChar(aDLLName));
    if result <32 then
    begin
      ErrCode := GetLastError;
      result := 0;
      addToLog( format(sErrLoadDLL + #13#10 + 'Код ошибки: %d'#13#10+'%s.',
                     [aDllName, ErrCode, SysErrorMessage(ErrCode)]));
    end;
  except
    addToLog(format(sErrLoadDLL,[aDLLName]));
  end
end;


function Tdm.GetAccntParams;
var
  iProcPrm: LongWord;
begin
  if not OraSession.Connected then iProcPrm := 1 else iProcPrm := 2;
  iProcPrm := iProcPrm or UserMode;
  result := dmGetAccntParams(OraSession,qryAccntParam,aData,FOraPkgName,iProcPrm);
end;


function Tdm.MakeDumpStrList(const iLevel: integer): TStringList;
begin
  if SysLog >=iLevel then
    result := TStringList.Create
  else result := nil;
end;


(*function Tdm.PurgeDuplicates(var FData: TBankAccnt): integer; // удаление дубликатов
var
  twins_open: bool;
  twins_count: integer;
  temp_md: TrxMemoryData;
const
  compare_md: string =
  'CA_DOC_DATE;CA_PAY_DATE;CA_DOCUMENT;CA_SUMM_DEBT;CA_SUMM_CRED;DEBET_CLI_ACNT;CREDIT_CLI_ACNT';
  compare_md2: string =
  'CA_DOC_DATE;CA_PAY_DATE;CA_DOCUMENT;CA_SUMM_DEBT;CA_SUMM_CRED';
begin
  result := 0;
{ if FData.IsEmpty or (FData.RecordCount =1) then Exit;
  temp_md := TrxMemoryData.Create(nil);
  temp_md.CopyStructure( FData);
  if temp_md.LoadFromDataSet(FData, 0, lmCopy) <>FData.RecordCount then
    addToLog( FData.DefineStr +': внутренняя ошибка клонирования данных')
  else
  with FData do
  try
    SortOnFields( FDataSortStr);
    First;
    temp_md.sortOnFields(FDataSortStr);
    temp_md.first;
    twins_open := FALSE;
    while not EoF do begin
      while not temp_md.EoF do begin

        if temp_md.RecNo >RecNo then
        begin
          if DataSetLocateThrough(temp_md, Compare_md,
             VarArrayOf([fieldByName('ca_doc_Date').asDateTime, fieldByName('ca_pay_Date').asDateTime,
                         fieldByName('ca_document').asString,
                         fieldByName('ca_summ_Debt').asFloat, fieldByName('ca_summ_Cred').asFloat,
                         fieldByName('debet_cli_acnt').asString, fieldByName('CREDIT_CLI_ACNT').asString]),[]) then
              begin
               SetStampValue( -1);
               twins_open := TRUE;
              end
             else
             if twins_open then begin
               twins_open := DataSetLocateThrough(temp_md, compare_md2,
                        varArrayOf([FieldByName('ca_doc_Date').asDateTime,
                                    FieldByName('ca_pay_Date').asDateTime,
                                    fieldByName('ca_document').asString,
                                    fieldByName('ca_summ_Debt').asFloat,
                                    fieldByName('ca_summ_Cred').asFloat]),[]);

               if twins_open then SetStampValue( -1);
             end;
        end; //temp_md.RecNo >RecNo
        temp_md.next;
      end;
      next;
    end;

    twins_open := FALSE;  twins_count := 0;  //renumerate lines
    first;
    while not eof do begin
      if FieldByName('stamp').AsInteger =-1 then begin
        resetDocNumber( twins_count);
        inc(twins_count);
        twins_open := TRUE;
       end
      else begin
        if twins_open then begin
          resetDocNumber( twins_count);
          twins_open := FALSE;
        end;
        twins_count := 0;
      end;
      next;
    end;
  except
    result :=-1;
  end;
  FreeAndNil( temp_md);}
end;*)


function Tdm.LoadListParams(var lstParam: TStringList; const AgentId: integer): integer;
begin
  Result := dmLoadListParams(lstParam,AgentId);
end;


function Tdm.GetAgentProcLibName(var DllFunctionName: string): string;
var
  k: integer;
  sValue: string;
begin
  result := Trim(FDriverName);
  if assigned(FDriverList) and (FDriverList.Count >0) and (Length(FCorrName) >0) then
  try
    for k := 0 to FDriverList.Count-1 do
    if SameText(GetStrKeyName(FDriverList[k]), FCorrName) then
    begin
      sValue := GetStrParamValue(FDriverList[k]);
      if AnsiUpperCase(sValue) <>'RAW' then
        result := sValue
      else begin
        result := GrepSepString(sValue,';',$4);
        DllFunctionName := sValue;
      end;
      result := sysMainExePath + result;
      break;
    end;
  except
    result := '';
  end;
end;


procedure Tdm.SetLogList(const aList: TStrings);
begin
  if assigned(aList) then
    FLogPtr := aList;
end;

procedure Tdm.OraSessionAfterConnect(Sender: TObject);
begin
  if (Length(FOraPKGName) >1) and OraSession.Connected then
    dmAfterConnect(OraSession,FOraPKGName,FVersInfo.FileVersion);
end;


procedure Tdm.dsDataSrcDataChange(Sender: TObject; Field: TField);
begin
  dmSetDataSrcParams(TDataSource(Sender).DataSet, FDriverList,
                    FCurrAgentID, FCorrName, FDriverName);
end;

function Tdm.LogoffDataSource: integer;
var
  SrcOffQry: TOraQuery;
const
  sqlDataSourceOff = 'UPDATE fin$corr_external'^M+
                     '   SET agent_flag =0 WHERE uin_corr =%d';
begin
  result := 1;
  if (FCurrAgentID <=0) or (not IsOraConnected(oraSession)) then exit;
  try
    SrcOffQry := TOraQuery.Create(nil);
    SrcOffQry.Session := oraSession;
    SrcOffQry.SQL.Add(format(sqlDataSourceOff,[FCurrAgentID]));
    try
      SrcOffQry.Execute;
      Result := 0;
      AddToLogP(format('Отключен источник данных %s[id:%d]',[FCorrName,FCurrAgentID]),2);
    except
      AddToLogP(format('Ошибка отключения источника %s[id:%d]',[FCorrName,FCurrAgentID]));
      result := -1;
    end;
  finally
    SrcOffQry.Free;
  end;
end;

function Tdm.GetSrcMaskList(aSrcNames: String; aList: TStrings): integer;
var
  sNameMask,sExt,sPath,sFName: String;
  sr: TSearchRec;
  beforeCounts, vNewAdded: Integer;
begin
  result := 0;
  if Length(aSrcNames) =0 then Exit;
  try
    beforeCounts := FSrcFiles.Count;

    while Length(aSrcNames) >0 do
    begin
      sNameMask := GrepSepString(aSrcNames,';',0);
      sPath := ExtractFilePath(sNameMask);
      sExt := ExtractFileExt(sNameMask);
      if not directoryExists(sPath) then
      begin
        addToLogP(format(errDataPathNotFound,[orQryDataSrc[sdbCorrName],sNameMask]));
        Continue;
      end;

      if (Length(sExt) =0) and
        ((pos('*',sNameMask) =0) and (pos('?',sNameMask) =0)) then begin
        if not lchar(sNameMask,'\') then
          sNameMask := sNameMask + '\*.*';
        sNameMask := sNameMask + '*.*' ;
      end;

      if FindFirst(sNameMask,faArchive,Sr) =0 then
      try
        repeat
          vNewAdded := AddSourceFileToList(ExpandFileName(sPath+sr.Name), sr.Name, aList);
          MainForm.lstcbFileNames.Checked[vNewAdded] := True;
        until FindNext(Sr) <>0;
      finally
        SysUtils.FindClose(sr);
      end;

    end;
  finally
    result := FSrcFiles.Count -beforeCounts;
  end;
end;



function Tdm.AddSourceFileToList(const aFullFName, aViewFName: String;
            aList: TStrings; const aFStream: TFileStream =nil): Integer;
begin
  Result := -1;
  if Length(aFullFName) =0 then exit;

  if Assigned(FSrcFiles) and (FSrcFiles.IndexOf(aFullFName) <0) then
    FSrcFiles.AddObject(aFullFName, aFStream);

  if Assigned(aList) then begin
    if aList.IndexOf(aViewFName) <0 then
      aList.Add(aViewFName);
    result := aList.IndexOf(aViewFName);
  end;
end;


procedure Tdm.AddSourceFileToCheckList(const aFName: String;
  aList: TStrings);
var i: integer;
  vFileName: string;
begin
  if Assigned(aList) and (FSrcFiles.Count >0) then
  begin
    aList.BeginUpdate;
    for i := 0 to FSrcFiles.Count -1 do
    begin
      vFileName := ExtractFileName(FSrcFiles[i]);
      if aList.IndexOf(vFileName) <0 then
        aList.Add(vFileName);
    end;
    aList.EndUpdate;
  end;
end;

end.

unit fmtloadDMSVC;

// fmtload datamodule service routines
//
// i.ilmovski@gmail.com, 2008-2016

interface
uses Windows, DB,
{$ifdef DOA}
  Oracle,
{$else}
  Ora,OraError,OraCall,OraClasses,
{$endif}
 PaymClass,
 SysUtils,Classes;

function IsOraConnected({$ifdef DOA}oraSess: TOracleSession
                        {$else} oraSess: TOraSession{$endif}): bool;

procedure dmAfterConnect(aSess: {$ifdef DOA} TOracleSession {$else} TOraSession{$endif};
                         var aPKGName: String; const aVerStr: String);

function dmIsConnectionOk({$ifdef DOA} aSess: TOracleSession
                          {$else}      aSess: TOraSession{$endif}): bool;

procedure dmDumpVariables( dm: TComponent;
                         {$ifdef DOA}const aOraQuery: TOracleQuery;
                         {$else}  const aOraQuery: TOraQuery;{$endif}
                         const iLevel: integer=4);


function dmAccountLockOpen( {$ifdef DOA} oraSess: TOracleSession;
                                         oraQuery: TOracleQuery;
                            {$else} oraSess: TOraSession;
                                    oraQuery: TOraQuery; {$endif}
                                    aStatement: TCustStatement;
                                    const vAgentStr: string;
                                    const IsForced: bool=FALSE): integer;

procedure dmAccountLockClose(var aQuery:{$ifdef DOA} TOracleQuery {$else} TOraQuery {$endif};
                             aStatement: TCustStatement; const IsForced: bool=FALSE);


function dmStatementDataDelete( aSess: {$ifdef DOA} TOracleSession {$else} TOraSession {$endif};
               var aQuery: {$ifdef DOA} TOracleQuery {$else} TOraQuery {$endif};
                  aStatement: TCustStatement; const aPkgName,aAgentStr: String;
                                               const IsForced: bool): integer;

function  dmStatementDataStore(
 aSess: {$ifdef DOA} TOracleSession {$else} TOraSession {$endif};
 var aQuery,aQueryReset: {$ifdef DOA} TOracleQuery {$else} TOraQuery {$endif};
           aStatement: TCustStatement; const aPkgName,aAgentStr: String;
           const aDeltaValue: Double;
           const IsDeltaLogForced: bool; const IsForced: bool=FALSE): integer;

procedure AddToLogP(const aMsg: string; const iLevel: Word =$01);far;

procedure dmSetDataSrcParams( ds: TDataSet; aDriverList: TStrings;
        out aAgentID: integer; out aCorrName: string; out aDriverName: string);


function  dmGetAccntParams(
  aSess: {$ifdef DOA} TORacleSession {$else} TOraSession {$endif};
  var aQuery: {$ifdef DOA} TOracleQuery {$else} TOraQuery {$endif};
  var aAccnt: TPaymAccount; const aPkgName: String; const iProcPrm: Longword
  {const IsForced: bool}): integer;

function dmGetDataSourceParams(out aModelName: String; var aMatchList: TStringList): integer;

// возврат списка для проверки совпадений источника
function dmLoadListParams(var lstParam: TStringList; const AgentId: integer): integer;

function dmStoreOraData(aSess: {$ifdef DOA} TORacleSession {$else} TOraSession {$endif};
                    var aLockQuery: {$ifdef DOA} TOracleQuery {$else} TOraQuery {$endif};
               aStatement: TCustStatement; const aPkgName: String;
              const aDeltaValue: Double; const IsDeltaLogForced: bool;
               const IsForced: bool=FALSE): integer;


const
  DataDescSection = 'DataDescription';

implementation
uses datamodule, DBUtils,
  RxStrUtils, Sys_iStrUtils,
  PaymMDIntrface,
  RxMemDS, dmodsvc, oraStrSvc,
  fmtloadmain;

 {$ifdef DOA}
 {$else}
 {$endif}

const
  msgHasntDriver   = 'не определен обработчик для "%s"';
  msgNotConnected  = ' %s/%s не подключен';


// over for logging
procedure AddToLogP(const aMsg: string; const iLevel: Word =$01);far;
begin
  if (Length(aMsg) >0) and Assigned(dm) then
    TDM(dm).addToLog(aMsg, iLevel, mainForm.memLog.Lines);
end;


function IsOraConnected;
begin
  try
    result := assigned(oraSess) and oraSess.Connected;
  except
    Result := False;
  end;
end;

function dmIsConnectionOk;
begin
  result := IsOraConnected(aSess);
  if (not Result) and (dm.DataLogLevel >2) then
 {$ifdef DOA}
    addToLogP( format(msgNotConnected,[aSess.LogonUserName,aSess.logonDatabase]));
 {$else}
    addToLogP( format(msgNotConnected,[aSess.UserName,aSess.Server]));
 {$endif}
end;

procedure  dmDumpVariables;
var
  sVarName,sVarVal: string;
  tVar: Variant;
  k: integer;
begin
  if not Assigned(dm) then exit;
  if (Tdm(dm).SysLog >=iLevel) and assigned(aOraQuery) and
    (aOraQuery.Params.Count >0) then
  for k := 0 to aOraQuery.Params.Count -1 do
  try
 {$ifdef DOA}
    sVarName := VariableName(k);
    tVar     := GetVariable(sVarName);
    if VarIsEmpty(tVar) or VarIsNull(tVar) then
     sVarVal := ''
    else sVarVal := VarToStr(tVar);
 {$else}
    sVarName := aOraQuery.Params[k].Name;
    sVarVal  := aOraQuery.Params[k].AsString;
 {$endif}
    AddToLogP(format('%s = ''%s''',[sVarName,sVarVal]),iLevel);
  except
    AddToLogP(format('variables dump except on %s',[sVarName]));
  end;
end;


//
procedure InitDeleteDataVariables(var {$ifdef DOA} aQuery: ToracleQuery
                                          {$else}  aQuery: ToraQuery {$endif});
begin
  if Assigned(aQuery) then
  begin
{$ifdef DOA}
    if aQuery.Variables.Count =0 then
    begin
      aQuery.DeclareVariable('sAccnt', otString);
      aQuery.DeclareVariable('StartDT', otDate);
      aQuery.DeclareVariable('EndDT', otDate);
      aQuery.DeclareVariable('Param',otInteger);
      aQuery.DeclareVariable('iOpRes',otInteger);
    end;
 {$else}
    aQuery.ParamByName('sAccnt').DataType  := ftString;
    aQuery.ParamByName('StartDT').DataType := ftDate;
    aQuery.ParamByName('EndDT').DataType   := ftDate;

    aQuery.ParamByName('iOpRes').DataType  := ftInteger;
    aQuery.ParamByName('iOpRes').ParamType := ptOutput;

    aQuery.ParamByName('Param').DataType   := ftInteger;
    aQuery.ParamByName('Param').ParamType  := ptInput;
 {$endif}
  end;
end;

procedure SetupResetAccntQuery(var aQuery: {$ifdef DOA} TOracleQuery
              {$else} ToraQuery {$endif}; const aPaymAccnt: TPaymAccount;
                 const aDeltaValue: Double; const IsDeltaLogForced: bool);
begin
  if Assigned(aQuery) then
 {$ifdef DOA}
    if aQuery.Variables.Count =0 then
    begin
      aQuery.DeclareVariable('iAccnt',    otInteger);
      aQuery.DeclareVariable('StartDate', otDate);
      aQuery.DeclareVariable('OnDate',    otDate);
      aQuery.DeclareVariable('sParam',    otString);
      aQuery.DeclareVariable('vAdd',      otFloat);
      aQuery.DeclareVariable('iForced',   otInteger);
     end
    else begin
      aQuery.SetVariable('iAccnt',    aPaymAccnt.AccountID);
      aQuery.SetVariable('StartDate', aPaymAccnt.StartDt);
      aQuery.SetVariable('OnDate',    aPaymAccnt.EndDt);
      aQuery.SetVariable('sParam', format('%s,[ID:%d]',
                              [aPaymAccnt.ReportName, aPaymAccnt.AccountID]));
      aQuery.SetVariable('vAdd',    aDeltaValue);
      aQuery.SetVariable('iForced', integer(IsDeltaLogForced));
    end;
 {$else}
    begin
      aQuery.ParamByName('iAccnt').DataType    := ftInteger;
      aQuery.ParamByName('StartDate').DataType := ftDate;
      aQuery.ParamByName('OnDate').DataType    := ftDate;
      aQuery.ParamByName('sParam').DataType    := ftString;
      aQuery.ParamByName('vAdd').DataType      := ftFloat;
      aQuery.ParamByName('iForced').DataType   := ftInteger;

      aQuery.ParamByName('iAccnt').asInteger     := aPaymAccnt.AccountID;
      aQuery.ParamByName('StartDate').asDateTime := aPaymAccnt.StartDt;
      aQuery.ParamByName('OnDate').asDateTime    := aPaymAccnt.EndDt;
      aQuery.ParamByName('sParam').asString := format('%s,[ID:%d]',
                              [aPaymAccnt.ReportName, aPaymAccnt.AccountID]);
      aQuery.ParamByName('vAdd').asFloat         := aDeltaValue;
      aQuery.ParamByName('iForced').asInteger    := integer(IsDeltaLogForced);
    end;
 {$endif}
end;

function dmStatementDataDelete;
const
  procName = 'DeleteAccounts4Period';
const
  DeleteAccounts_param =':sAccnt,:StartDT,:EndDT,:iOpRes,:Param';
begin
  result := -2;
  if not IsOraConnected(aSess) then
     result := integer(not IsForced)
  else
  begin
    Result := InitOraQuery(aSess,aQuery,aPkgName,procName,DeleteAccounts_param);
    if result =0 then
    with aQuery do
    try
      InitDeleteDataVariables(aQuery);
 {$ifdef DOA}
      ClearVariables;
      SetVariable('sAccnt', aStatement.AccountsIDLst);
      SetVariable('StartDT',aStatement.StartDate;
      SetVariable('EndDT', aStatement.EndDate);
      SetVariable('Param', 0);
 {$else}
      ParamByName('sAccnt').asString    := aStatement.AccountsIDLst;
      ParamByName('StartDT').AsDateTime := aStatement.StartDate;
      ParamByName('EndDT').AsDateTime   := aStatement.EndDate;
      ParamByName('Param').asInteger    := 0;
 {$endif}
      addToLogP(format('//// %s query:'#13#10'%s', [procname,SQL.Text]),4);
 {$ifdef debugSQL}
      Debug := TRUE;
 {$endif}
      Execute;
 {$ifdef DOA}
      Result := GetVariable('iOpRes);
 {$else}
      result := ParamByName('iOpRes').AsInteger;
 {$endif}
      case result of
       -1: begin
             aStatement.Status := aStatement.Status or $800;
             addToLogP(format('%s: не указаны ID счетов',[aAgentStr]));
           end;
      end;
      dmDumpVariables(dm,aQuery);
 {$ifdef DOA}
    except on E:EOracleError do
 {$else}
    except on E:EOraError do
 {$endif}
      begin
        if aSess.Connected then
          aSess.Rollback;
        aStatement.Status := aStatement.Status or $1000;
        result := -1;
        addToLogP(format('%s'#13#10'%s - ошибка удаления выписок',
                          [E.Message, aAgentStr]));
      end;
    end;
    addToLogP(format('//// StatmentDataDelete()=%d',[result]),4);
  end;
end;//dmStatementDataDelete


function dmAccountLockOpen;
const
  sPaymAccountLock =
   'SELECT A.rowID, A.*, I.RowID, I.*'#13#10 +
   '  FROM fin$Corr_pay_acnt A, fin$corr_pay_items I'#13#10 +
   ' WHERE a.uin_corr_acnt in (:sAcStr)'#13#10 +
   '   AND i.uin_corr_acnt =a.uin_corr_acnt'#13#10+
   '   AND i.ca_pay_date between :dt1 and nvl(:dt2,SYSDATE)'#13#10+
   ' FOR UPDATE NOWAIT';
begin
  result := -3;
  if not IsOraConnected(oraSess) then
     result := integer( not IsForced)
  else begin
    if not assigned(oraQuery) then
    begin
 {$ifdef DOA}
      oraQuery:= TOracleQuery.Create(nil);
 {$else}
      oraQuery:= TOraQuery.Create(nil);
 {$endif}
      oraQuery.Session := oraSess;
      oraQuery.SQL.Add(sPaymAccountLock);
     end
    else begin
      if oraQuery.Active then oraQuery.Close;
      if oraQuery.SQL.Count =0 then
        oraQuery.SQL.Add(sPaymAccountLock);
    end;

    with oraQuery do
    try
 {$ifdef DOA}
      ClearVariables;
      SetVariable('sAcStr', aStatement.AccountsIDLst);
 {$else}
      ParamByName('sAcStr').AsString := aStatement.AccountsIDLst;
      ParamByName('dt1').asDateTime  := aStatement.StartDate;
      ParamByName('dt2').asDateTime  := aStatement.EndDate;
 {$endif}
      addToLogP(format('//// "ora.LockAccounts" query:'#13#10'%s',[SQL.Text]),4);
 {$ifdef debugSQL}
      debug := TRUE;
 {$endif}
      Open;
      result := 0;
 {$ifdef DOA}
    except on E:EOracleError do
 {$else}
    except on E:EOraError do
 {$endif}
      begin
        if E.ErrorCode =54 then begin // уже занято
          result := -1;
          AddToLogP( vAgentStr+' - данные заняты');
        end
        else begin
          result := -2;
          AddToLogP( vAgentStr+' - ошибка при попытке занять данные');
        end;
      end;
    end;
  end;
end;//dmAccountLockOpen


procedure dmAccountLockClose;
var
  sAgent: string;
begin
  sAgent := format('''%s:%d''(id:%s)',
         [aStatement.OwnerName,aStatement.AgentID,aStatement.AccountsIDLst]);
  if IsOraConnected(aQuery.Session) and aQuery.Active then
    aQuery.Close;

  if (IsOraConnected(aQuery.Session) or IsForced) and (aStatement.Status =0) then
  try
    if aQuery.Session.InTransaction then
    begin
      aQuery.Session.Commit;
      addToLogP('// данные '+sAgent+' сохранены',3);
     end
    else addToLogP('// '+sAgent+' - завершено без сохранения',3);
  except
    addToLogP(format('! %s: ошибка COMMIT',[sAgent]));
  end
end;


procedure InitStoreVariables({$ifdef DOA} var aQuery: TOracleQuery
                             {$else} var aQuery: TOraQuery {$endif});
begin
  if Assigned(aQuery) then
 {$ifdef DOA}
  if aQuery.Variables.Count =0 then
  begin
    DeclareVariable('iAccnt', otInteger);
    DeclareVariable('sCurr',  otString);
    DeclareVariable('DocDT',     otDate);
    DeclareVariable('PayDT',     otDate);
    DeclareVariable('sDoc',      otString);
    DeclareVariable('sInfo',     otString);
    DeclareVariable('vDebt',     otFloat);
    DeclareVariable('vCred',     otFloat);
    DeclareVariable('DebtName',  otString);
    DeclareVariable('DebtAcnt',  otString);
    DeclareVariable('debtCode',  otString);
    DeclareVariable('DebtBName', otString);
    DeclareVariable('DebtBCode', otString);
    DeclareVariable('DebtBAcnt', otString);
    DeclareVariable('CredName',  otString);
    DeclareVariable('CredAcnt',  otString);
    DeclareVariable('CredCode',  otString);
    DeclareVariable('CredBName', otString);
    DeclareVariable('CredBCode', otString);
    DeclareVariable('CredBAcnt', otString);
    DeclareVariable('vINPUT',    otFloat);
    DeclareVariable('vOUT',      otFloat);
    DeclareVariable('DC',        otString);
    DeclareVariable('iOpF', otInteger);
  end;
 {$else}
  begin
    aQuery.ParamByName('iAccnt').DataType := ftInteger;
    aQuery.ParamByName('sCurr').DataType := ftString;
    aQuery.ParamByName('DocDT').DataType := ftDate;
    aQuery.ParamByName('PayDT').DataType := ftDate;
    aQuery.ParamByName('sDoc').DataType := ftString;
    aQuery.ParamByName('sInfo').DataType := ftString;
    aQuery.ParamByName('vDebt').DataType := ftFloat;
    aQuery.ParamByName('vCred').DataType := ftFloat;
    aQuery.ParamByName('DebtName').DataType := ftString;
    aQuery.ParamByName('DebtAcnt').DataType := ftString;
    aQuery.ParamByName('debtCode').DataType := ftString;
    aQuery.ParamByName('DebtBName').DataType := ftString;
    aQuery.ParamByName('DebtBCode').DataType := ftString;
    aQuery.ParamByName('DebtBAcnt').DataType := ftString;
    aQuery.ParamByName('CredName').DataType := ftString;
    aQuery.ParamByName('CredAcnt').DataType := ftString;
    aQuery.ParamByName('CredCode').DataType := ftString;
    aQuery.ParamByName('CredBName').DataType := ftString;
    aQuery.ParamByName('CredBCode').DataType := ftString;
    aQuery.ParamByName('CredBAcnt').DataType := ftString;
    aQuery.ParamByName('vINPUT').DataType := ftFloat;
    aQuery.ParamByName('vOUT').DataType := ftFloat;
    aQuery.ParamByName('DC').DataType := ftString;

    aQuery.ParamByName('iOpF').DataType := ftInteger;
    aQuery.ParamByName('iOpF').ParamType  := ptInput;
  end;
 {$endif}
end;


procedure SetupStoreVariables(var{$ifdef DOA} aQuery: TOracleQuery;
                                      {$else} aQuery: TOraQuery; {$endif}
                              const aPaymAccnt: TPaymAccount;
                              const aMD: TDataSet);
begin
 {$ifdef DOA}
   aQuery.SetVariable('iAccnt', aPaymAccnt.AccountID);
   aQuery.SetVariable('sCurr', aPaymAccnt.CurrCh);

   aQuery.SetVariable('DocDT',     aMD.FieldByName('CA_DOC_DATE').asDateTime);
   aQuery.SetVariable('PayDT',     aMD.FieldByName('CA_PAY_DATE').asDateTime);
   aQuery.SetVariable('sDoc',      aMD.FieldByName('CA_DOCUMENT').asString);
   aQuery.SetVariable('sInfo',     aMD.FieldByName('PAY_COMMENT').asString);
   aQuery.SetVariable('vDebt',     aMD.FieldByName('CA_SUMM_DEBT').asFloat);
   aQuery.SetVariable('vCred',     aMD.FieldByName('CA_SUMM_CRED').asFloat);
   aQuery.SetVariable('DebtName',  aMD.FieldByName('DEBET_CLI_NAME').asString );
   aQuery.SetVariable('DebtAcnt',  aMD.FieldByName('DEBET_CLI_ACNT').asString);
   aQuery.SetVariable('debtCode',  aMD.FieldByName('DEBET_CLI_INN').asString);
   aQuery.SetVariable('DebtBName', aMD.FieldByName('DEBET_BANK_NAME').asString);
   aQuery.SetVariable('DebtBCode', aMD.FieldByName('DEBET_BANK_BIC').asString);
   aQuery.SetVariable('DebtBAcnt', aMD.FieldByName('DEBET_BANK_ACNT').asString);
   aQuery.SetVariable('CredName',  aMD.FieldByName('CREDIT_CLI_NAME').asString);
   aQuery.SetVariable('CredAcnt',  aMD.FieldByName('CREDIT_CLI_ACNT').asString);
   aQuery.SetVariable('CredCode',  aMD.FieldByName('CREDIT_CLI_INN').asString);
   aQuery.SetVariable('CredBName', aMD.FieldByName('CREDIT_BANK_NAME').asString);
   aQuery.SetVariable('CredBCode', aMD.FieldByName('CREDIT_BANK_BIC').asString);
   aQuery.SetVariable('CredBAcnt', aMD.FieldByName('CREDIT_BANK_ACNT').asString);
   aQuery.SetVariable('vINPUT',    aMD.FieldByName('INPUT_VALUE').asFloat);
   aQuery.SetVariable('vOUT',      aMD.FieldByName('OUT_VALUE').asFloat);
   aQuery.SetVariable('DC',        aMD.FieldByName('DEB_CRED').asString);
 {$else}
   aQuery.ParamByName('iAccnt').AsInteger := aPaymAccnt.AccountID;
   aQuery.ParamByName('sCurr').AsString   := aPaymAccnt.CurrCh;

   aQuery.ParamByName('DocDT').asDateTime := aMD.FieldByName('CA_DOC_DATE').asDateTime;
   aQuery.ParamByName('PayDT').asDateTime := aMD.FieldByName('CA_PAY_DATE').asDateTime;
   aQuery.ParamByName('sDoc').asString :=  aMD.FieldByName('CA_DOCUMENT').asString;
   aQuery.ParamByName('sInfo').asString := aMD.FieldByName('PAY_COMMENT').asString;
   aQuery.ParamByName('vDebt').asFloat := aMD.FieldByName('CA_SUMM_DEBT').asFloat;
   aQuery.ParamByName('vCred').asFloat := aMD.FieldByName('CA_SUMM_CRED').asFloat;
   aQuery.ParamByName('DebtName').asString := aMD.FieldByName('DEBET_CLI_NAME').asString;
   aQuery.ParamByName('DebtAcnt').asString := aMD.FieldByName('DEBET_CLI_ACNT').asString;
   aQuery.ParamByName('debtCode').asString := aMD.FieldByName('DEBET_CLI_INN').asString;
   aQuery.ParamByName('DebtBName').asString := aMD.FieldByName('DEBET_BANK_NAME').asString;
   aQuery.ParamByName('DebtBCode').asString := aMD.FieldByName('DEBET_BANK_BIC').asString;
   aQuery.ParamByName('DebtBAcnt').asString := aMD.FieldByName('DEBET_BANK_ACNT').asString;
   aQuery.ParamByName('CredName').asString := aMD.FieldByName('CREDIT_CLI_NAME').asString;
   aQuery.ParamByName('CredAcnt').asString := aMD.FieldByName('CREDIT_CLI_ACNT').asString;
   aQuery.ParamByName('CredCode').asString := aMD.FieldByName('CREDIT_CLI_INN').asString;
   aQuery.ParamByName('CredBName').asString := aMD.FieldByName('CREDIT_BANK_NAME').asString;
   aQuery.ParamByName('CredBCode').asString := aMD.FieldByName('CREDIT_BANK_BIC').asString;
   aQuery.ParamByName('CredBAcnt').asString := aMD.FieldByName('CREDIT_BANK_ACNT').asString;
   aQuery.ParamByName('vINPUT').asFloat := aMD.FieldByName('INPUT_VALUE').asFloat;
   aQuery.ParamByName('vOUT').asFloat :=   aMD.FieldByName('OUT_VALUE').asFloat;
   aQuery.ParamByName('DC').AsString := aMD.FieldByName('DEB_CRED').asString;
 {$endif}
end;

function dmStatementAccountReset(var aQuery:{$ifdef DOA} TOracleQuery {$else} TOraQuery {$endif};
                     const  aPaymAccnt: TPaymAccount; const aProcName: String;
                     const aDeltaValue: Double; const IsDeltaLogForced: bool;
                 const isForced: bool=FALSE): integer;
var
  ProcName: string;
const
  ResetAccount_Param =':iAccnt,:StartDate,:onDate,:sParam,:vAdd,:iForced';
begin
  result := -2;
  if Assigned(aQuery) and IsOraConnected(aQuery.Session) then
    with aQuery do
    try
      addToLogP(format('//// %s query:'#13#10'%s',[aProcName,aQuery.SQL.Text]),4);
      SetupResetAccntQuery(aQuery,aPaymAccnt,aDeltaValue,IsDeltaLogForced);
{$ifdef debugSQL}
      debug := TRUE;
{$endif}
      Execute;
      dmDumpVariables(dm,aQuery);
      if aPaymAccnt.accStatus =0 then
      begin
        aQuery.Session.Commit;
        aPaymAccnt.Owner.Status := 1;
        addToLogP(format('счет ''%s'': изменения сохранены',[aPaymAccnt.ReportName]),2);
      end;
      result := 0;
 {$ifdef DOA}
     except on E:EOracleError do
 {$else}
     except on E:EOraError do
 {$endif}
     begin
       if aQuery.Session.Connected then
         aQuery.Session.Rollback;
       result := -1;
       addToLogP(format('%s: ошибка обновления счета: %s',
                       [aPaymAccnt.ReportName,E.Message]));
     end;
    end;
end;


function dmStatementDataStore;
var
  procname,resetQryName: string;
  aPaymAccnt: TPaymAccount;
  iRes,iAccntRes,k,j: integer;
const
  sqlAccntReset =':iAccnt,:StartDate,:onDate,:sParam,:vAdd,:iForced';
  sqlAddStatement =
   ':iAccnt,:sCurr, :DocDT,:PayDT,:sDoc,:sInfo,:vDebt,:vCred,'#13#10+
   ':DebtName,:DebtAcnt,:DebtCode,:DebtBName,:DebtBCode,:DebtBAcnt,'#13#10+
   ':CredName,:CredAcnt,:CredCode,:CredBName,:CredBCode,:CredBAcnt,'#13#10+
   ':vInput,:vOut, :DC, :iOpF';
begin
  result := -2;
  if not IsOraConnected(aSess) then
     result := integer( not IsForced)
  else begin
    Result := -$80;
    if aStatement.Count =0 then exit;
    procName := 'AddAccount';
    resetQryName := 'ResetAccount';
    if (InitOraQuery(aSess,aQuery, aPkgName,procName,sqlAddStatement) =0) and
     (InitOraQuery(aSess,aQueryReset,aPkgName,ResetQryName,sqlAccntReset) =0) then
    with aQuery do
    try
      addToLogP(format('//// %s query:'#13#10'%s',[procName,SQL.Text]),4);
      InitStoreVariables(aQuery);
      Result := 0;
      for j := 0 to aStatement.Count -1 do
      if assigned(aStatement[j]) and (not TPaymAccount(aStatement[j]).isEmpty) and
        assigned(TPaymMD( TPaymAccount(aStatement[j]).MDPort)) then
      begin
        aPaymAccnt := aStatement[j];
        TPaymMD(aPaymAccnt.MDPort).First;

        for k := 0 to TrxMemoryData(aPaymAccnt.MDPort).RecordCount -1 do
        with TPaymMD(aPaymAccnt.MDPort) do
        begin
          SetupStoreVariables(aQuery,aPaymAccnt,aPaymAccnt.MDPort);
 {$ifdef debugSQL}
          debug := TRUE;
 {$endif}
          Execute;
 {$ifdef DOA}
          iRes := GetVariable('iOpF');
 {$else}  iRes := ParamByName('iOpf').asInteger; {$endif}
          with TrxMemoryData(aPaymAccnt.MDPort) do
            AddToLogP( format('//// строка данных %d:%d',[recNo,recordCount]),4);

          dmDumpVariables(dm,aQuery);
          case iRes of
           -1: begin
                 TStatus := TStatus or $1000;
                 result  := -4;
                 aPaymAccnt.NumErr := aPaymAccnt.NumErr +1;
                 addToLogP(format('%s: ошибка cохранения '+RecDumpStr(0),[Procname]));
                 Exit;
               end;
            0: begin
//               TStatus := TStatus or $40;
                 aPaymAccnt.NumUpd := aPaymAccnt.NumUpd +1;
                 addToLogP(format('%s: обновлено '+RecDumpStr(3),[Procname]),3);
               end;
            1: begin
//               TStatus := TStatus or $4;
                 aPaymAccnt.NumAdd := aPaymAccnt.NumAdd +1;
                 addToLogP(format('%s: добавлено '+ RecDumpStr(3),[Procname]),3);
               end;
          end;//case
          TPaymMD(aPaymAccnt.MDPort).Next;
        end;

        if TPaymMD(aPaymAccnt.MDPort).TStatus and $1000 <>$1000 then
          iAccntRes := dmStatementAccountReset(aQueryReset, aPaymAccnt,
             resetQryName, aDeltaValue, IsDeltaLogForced, isForced);
      end;
 {$ifdef DOA}
    except on E:EOracleError do
 {$else}
    except on E:EOraError do
 {$endif}
      begin
        if aSess.Connected then
          aSess.Rollback;
        result := -1;
        addToLogP( format('%s'#13#10'%s - ошибка в данных: %s',
          [E.Message,aAgentStr, TPaymMD(aPaymAccnt.MDPort).RecDumpStr(0)]));
      end;
    end;
    if (iAccntRes =0) and (TPaymMD(aPaymAccnt.MDPort).TStatus and $1000 <>$1000) then
      Result := aPaymAccnt.NumUpd + aPaymAccnt.NumAdd;
    addToLogP(format('//// StatementDataStore()=%d (items)', [result]),4);
  end;
end;


procedure dmSetDataSrcParams( Ds: TDataSet; aDriverList: TStrings;
 out aAgentID: integer; out aCorrName: string; out aDriverName: string);
var
  k: Integer;
begin
  aAgentID    := 0;
  aCorrName   := '';
  aDriverName := '';
  if assigned(Ds) and (not IsDataSetEmpty(Ds)) then
  try
    aCorrName  := Ds.FieldByName('Corr_Name').asString;
    if Length(aCorrName) =0 then exit;
    aAgentID   := DS.fieldByName('UIN_Corr').asInteger;
    aDriverName:= Ds.FieldByName('DLL_ENTRY_POINT').asString;

    if assigned(aDriverList) and (aDriverList.Count >0) then
    for k := 0 to aDriverList.Count-1 do
     if SameText( GetStrKeyName( aDriverList[k]), aCorrName) then
     begin
       if Length(GetStrParamValue(aDriverList[k])) >0 then
         aDriverName := GetStrParamValue(aDriverList[k]);
       break;
     end;
  except
    aAgentID := 0;
    aCorrName    := '';
    aDriverName  := '';
  end;
end;


function dmInitGetAccntParams(
    const aSess: {$ifdef DOA} TOracleSession {$else} TOraSession {$endif};
         var aQuery: {$ifdef DOA} TOracleQuery {$else} TOraQuery {$endif};
                               const aPkgName,aProcName: String;
                               const iProcPrm: Longword): integer;
const
  GetBankAccntID_Param =':iAgentID,:sCurr,:sAccnt,:sOwnerName,:iProcPrm,:iAcntId,:iCurrId,:shortName,:iFlag';
var
  IsForced: BOOL;
begin
  result := -2;
  IsForced := iProcPrm and $1=$1;
  if not IsOraConnected(aSess) then
     result := integer(not IsForced)
  else
  begin
    Result := InitOraQuery(aSess,aQuery,aPkgName,aProcName,GetBankAccntID_Param);
 {$ifdef DOA}
    DeclareVariable('iAgentID', otInteger);
    DeclareVariable('sCurr',  otString);
    DeclareVariable('sAccnt', otString);
    DeclareVariable('sOwnerName', otString);
    DeclareVariable('iProcPrm', otInteger);
    DeclareVariable('iFlag', otInteger);
    DeclareVariable('iAcntID', otInteger);
    DeclareVariable('iCurrID', otInteger);
    DeclareVariable('shortName', otString);
 {$else}
    aQuery.ParamByName('iAgentID').DataType   := ftInteger;
    aQuery.ParamByName('sCurr').DataType      := ftString;
    aQuery.ParamByName('sAccnt').DataType     := ftString;
    aQuery.ParamByName('sOwnerName').DataType := ftString;
    aQuery.ParamByName('iProcPrm').DataType   := ftInteger;

    aQuery.ParamByName('iFlag').DataType      := ftInteger;
    aQuery.ParamByName('iFlag').ParamType     := ptOutput;
    aQuery.ParamByName('iAcntID').DataType    := ftInteger;
    aQuery.ParamByName('iAcntID').ParamType   := ptOutput;
    aQuery.ParamByName('iCurrID').DataType    := ftInteger;
    aQuery.ParamByName('iCurrID').ParamType   := ptOutput;
    aQuery.ParamByName('shortName').DataType  := ftString;
    aQuery.ParamByName('shortName').ParamType := ptOutput;
 {$endif}
  end;
end;

// исполнение запроса БД параметров/создания счета FIN$CORR_PAY_ACNT
function dmOraGetBankAccntID({$ifdef DOA} aQuery: TOracleQuery;
                              {$else}     aQuery: TOraQuery; {$endif}
                              const aProcName: String; aAccnt: TPaymAccount;
                              const iProcPrm: LongWord): Integer;
const
  sErrAccountLocked = '%s: данные %s:''%s:%d'' заняты другим процессом';
  sErrAccountMissed = '%s: не определен индентификатор владельца (iAgentID= %d)';
  sErrAccntNotFound = '%s: не найден счет %s:%d';
  sErrAccntNamError = '%s: в имени счета %s:%d утерян псевдоним владельца';
  sErrNameRefresh   = '%s: ошибка обновления имени счета %s:%d';
  sErrAccountCurr   = '%s: литерал валюты %s';
  sTstAccountCalled = '/// GetBankAccntID(%d,%s,''%s'',''%s'',%d, out %d,%d,''%s'',%d)=%d';
var
  sCurr,sMsg,sViewName,sLog: String;
  iAcntID,iCurrID: integer;
begin
  result := -2;
  if Assigned(aQuery) then
  try
    sCurr  := nvlstr(aAccnt.CurrCh, format('%3.3d', [aAccnt.CurrCode]));
 {$ifdef DOA}
    aQuery.ClearVariables;
    aQuery.SetVariable('iAgentID', aAccnt.Owner.AgentID);
    aQuery.SetVariable('sCurr',  sCurr);
    aQuery.SetVariable('sAccnt', aAccnt.spAccount);
    aQuery.SetVariable('sOwnerName', aAccnt.OwnerName);
    aQuery.SetVariable('iProcPrm', iProcPrm);
 {$else}
    aQuery.ParamByName('iAgentID').asInteger  := aAccnt.Owner.AgentID;
    aQuery.ParamByName('sCurr').asString      := sCurr;
    aQuery.ParamByName('sAccnt').asString     := aAccnt.spAccount;
    aQuery.ParamByName('sOwnerName').asString := aAccnt.OwnerName;
    aQuery.ParamByName('iProcPrm').asInteger  := iProcPrm;
 {$endif}
    addToLogP(format('//// %s ready:'#13#10'%s',[aProcName,aQuery.SQL.Text]),4);

 {$ifdef debugSQL}
    aQuery.Debug := TRUE;
 {$endif}

 {$ifdef DOA}
    aQuery.Execute;
    result  := aQuery.GetVariable('iFlag');
    iAcntID := aQuery.GetVariable('iAcntID');
    iCurrID := aQuery.GetVariable('iCurrID');
    sViewName := aQuery.GetVariable('shortName');
 {$else}
    aQuery.ReturnParams := True;
    aQuery.ExecSQL;
    result  := aQuery.ParamByName('iFlag').asInteger;
    iAcntID := aQuery.ParamByName('iAcntID').asInteger;
    iCurrID := aQuery.ParamByName('iCurrID').asInteger;
    sViewName := aQuery.ParamByName('shortName').asString;
 {$endif}
    dmDumpVariables(dm,aQuery);
    if Result >=0 then begin
      aAccnt.SetAccountID( iAcntID,iCurrID,sViewName);
      sLog := format(sTstAccountCalled,[aAccnt.Owner.AgentID,sCurr,aAccnt.spAccount,
           aAccnt.OwnerName,iProcPrm, iAcntID,iCurrID,sViewName,result,result]);
      addToLogP(sLog,3);
      sMsg := nvlstr(aAccnt.ViewName,aAccnt.spAccount)+' (id:'+ IntToStr(iAcntId)+')';
      if result =0 then
        addToLogP( '/// Проверен '+ sMsg,3)
      else addToLogP( '// Создан '+ sMsg,2);
     end
    else begin
      case result of
       -1: sMsg := format(sErrAccountLocked,
                        [aProcName, aAccnt.spAccount, aAccnt.OwnerName]);
       -3: sMsg := format(sErrAccountMissed,[aProcName,aAccnt.Owner.AgentID]);
       -4: sMsg := format(sErrAccountCurr,[aProcname,sCurr]);
       -5: sMsg := format(sErrAccntNotFound,[aProcname,sViewName,iAcntID]);
       -6: sMsg := format(sErrAccntNamError,[aProcname,sViewName,iAcntID]);
       -7: sMsg := format(sErrNameRefresh,[aProcname,sViewName,iAcntID]);
      else
        sMsg := format('Ошибка вызова GetNewAccountId() %s(%s):%s(Id=%d)',
               [aAccnt.spAccount, sCurr,aAccnt.OwnerName,aAccnt.Owner.AgentID]);
      end;//case
      AddToLogP(sMsg);
    end;
 {$ifdef DOA}
  except on E:EOracleError do
 {$else}
  except on E:EOraError do
 {$endif}
    begin
      result := -8;
      dmDumpVariables(dm,aQuery,1);
      addToLogP(format('exception:'#13#10'%s',[E.Message]));
    end;
  end;
end;


function dmGetAccntParams;
const
  procName = 'GetBankAccntID';
  dbgAccDefine  = '/// запрос параметров счета %s(%d:''%s'')';
begin
  result := dmInitGetAccntParams(aSess,aQuery, aPkgName,procName,iProcPrm);
  if result >=0 then
    result := dmOraGetBankAccntID(aQuery,procName, aAccnt, iProcPrm)
  else addToLogP('ошибка инициализации процедуры InitGetAccntParams()');
end;


function dmGetDataSourceParams(out aModelName: String; var aMatchList: TStringList): integer;
var i: integer;
begin
  result := 0;
  aModelName := dm.CfgParam(DataDescSection,dm.FCorrName,'', varString);
  if Length(aModelName) =0 then
    addToLogP('/// модель данных не определена',2)
  else begin
    result := 0;
    addToLogP(format('/// имя модели внешних данных: "%s"',[aModelName]),3);
    if not assigned(aMatchList) then
      aMatchList := TStringList.Create;
    try
      dm.FSysIni.ReadSection(aModelName, aMatchList);
      if aMatchList.Count =0 then
        addToLogP(format('/// не найден шаблон для данных модели "%s"',[aModelName]),3)
      else
      try
        aMatchList.BeginUpdate;
        for I := 0 to aMatchList.Count - 1 do
          aMatchList[i] := OemToAnsiStr(
                           dm.FSysIni.ReadString(aModelName,aMatchList[I], ''));
      finally
        aMatchList.EndUpdate;
        addToLogP(format('//// для данных модели "%s" найден шаблон:'+
                         #13#10'%s', [aModelName,aMatchList.Text]),4);
      end;
    finally
      result := aMatchList.Count;
    end;
  end;
end;


function dmLoadListParams(var lstParam: TStringList; const AgentId: integer): integer;
begin
  if not assigned(lstParam) then
    lstParam := TStringList.Create
  else lstParam.Clear;

  case AgentId of
    447: begin
           lstParam.add('AS "PrivatBank"');
           lstParam.add('NORVIK BANKA - Statement');
           lstParam.add('АО "TRASTA KOMERCBANKA"');
         end;
  end;//case
  result := lstParam.Count;
end;

function dmStoreOraData(aSess: {$ifdef DOA} TORacleSession {$else} TOraSession {$endif};
                    var aLockQuery: {$ifdef DOA} TOracleQuery {$else} TOraQuery {$endif};
               aStatement: TCustStatement;
               const aPkgName: String;
               const aDeltaValue: Double; const IsDeltaLogForced: bool;
               const IsForced: bool=FALSE): integer;
var
  vAgentStr: string;
begin
  vAgentStr := format('''%s:%d''(id:%s)',
         [aStatement.OwnerName,aStatement.AgentID,aStatement.AccountsIDLst]);

  result := dmAccountLockOpen(aSess,aLockQuery, aStatement,vAgentStr,IsForced);
  addToLogP(format('/// StartTransaction()=%d',[result]),3);
  if (result =0) or IsForced then
  try
//  if aSess.Connected then
    aSess.StartTransaction;

    result := dm.StatementDataDelete(aStatement, vAgentStr);
    if result >=0 then
      result := dm.StoreStatement(aStatement,vAgentStr,IsForced);
  finally
    dmAccountLockClose(aLockQuery,aStatement,IsForced);
  end;
end;

procedure dmAfterConnect;
var
  sCommand,sSessStr: String;
begin
  if Pos('.',aPKGName) >0 then
    aPKGName := aSess.UserName+Copy(aPKGName,Pos('.',aPKGName),Length(aPKGName))
  else aPKGName := aSess.UserName+'.'+aPKGName+'.';

  sCommand := format(' %safter_Logon(''FinPump'',''%s'',''%s'');',
                     [upperCase(aPKGName), GetSessUserName(aSess),aVerStr]);

  with TOraQuery.Create(nil) do
  try
    Session := aSess;
    if SQL.Count =0 then
    begin
      SQL.add('BEGIN');
      sql.add( sCommand);
      sql.add('END;');
     end
    else
     sql[1] := sCommand;
    try
      Execute;
      sSessStr := nvl2S(dm.UserMode and $10=$10,' as "SysDba"',
                           nvl2s(dm.UserMode and $08=$08,' as Admin',''));

      addToLogP(' подключен ' + GetOraSessionUserString(aSess) + sSessStr);
      addToLogP( 'выполнен: "' + sCommand + '"',2);
    except
      addToLogP( format('ошибка выполнения %s',[sCommand]));
    end;
  finally
    Free;
  end;
end;


end.

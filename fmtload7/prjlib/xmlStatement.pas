unit xmlStatement;

interface
uses Windows,Classes,
  XMLIntf,
  PaymClass,
  PaymStorage,
  ConverDll;

type
  TFileSaveAccount =class(TPaymAccount)
  private
    function  MakeCurrFName: String;
  public
    function  SaveToFile(const aFName: String = ''): integer;
  end;

  TXMLTrans =class(TPaymTrans)
  private
    function  GetTransDateStr(const aValue: AnsiString): TDateTime; virtual;
    procedure RefineCorrName(var aName,aAccnt: String);
  public
    constructor Create(const iNode: IXMLNode; const vOwnAccnt: TObject;
                       const DC: String); virtual;
  end;

  TXMLAccount =class(TFileSaveAccount)
  private
  public
    procedure AddXMLTransactions(const iNode: IXMLNode; const sFName: String); virtual;
    procedure AddPayment(aXmlTrans: TXMLTrans);
  end;

  TIfxPmt =class(TPaymTrans)
  public
    constructor Create(const iNode: IXMLNode; const vOwnAccnt: TObject;
                        const aChkNum,aXfer,aPmtId: String); virtual;
  end;

  TIfxStmt =class(TCustStatement)
  private
  public
    constructor Create(const accNode: IXMLNode;
                        const aFName,sAgentName,sAgentAddr: string;
                        const aAgentID: integer;
                        const aLogFn: TRemoteLogProc;
                        const MinAccNoStrLength: integer =10); virtual;
  end;

  TXMLStatement =class(TCustStatement)     // TComponent
  private
    function    XMLAccountCreateEx(const iNode: IXMLNode; const sCurr: String): TXMLAccount;
  public
    function    OpenXMLAccountData(const iAcntNode: IXMLNode): integer;
//  constructor CreateFromFile( const sFName: string; const iAgentID: integer); virtual;
    constructor Create(const iNode,iAcntNode: IXMLNode;
                        const aFName,aHeadValues: string;
                        const aAgentID: integer;
                        const aLogFn: TRemoteLogProc;
                        const MinAccNoStrLength: integer =10); overload;
  end;

function GetXMLNodeAsString(const iNode: IXMLNode;  elemName: string): string;
function XMLNodeExist(const aNode: iXmlNode; const anodeName: String): bool;
//function XMLNodeText(const aNode: iXmlNode; const anodeName: String): String;
function GetChildNode(const iNode: IXMLNode; eNames: array of string): IXMLNode;
function GetChildNodeAsString(iNode: IXMLNode; eNames: array of string): string;

const
  sNodeErr    = '%s: XML-элемент "%s" не найден(или не содержит данных)';
  sAccNoErr   = '%s: XML-элемент "%s" не найден или имеет недопустимый формат';
  sHeadReadErr  = '%s: ошибка чтения заголовка';
  sUnknownSrc = '%s: неизвестный источник выписки "%s"';

implementation

uses SysUtils, StrUtils,Dialogs,
  fmtCurrNameSvc,
  Sys_StrConv,Sys_iStrUtils,Sys_iStrList;


function GetChildNode(const iNode: IXMLNode;
  eNames: array of string): IXMLNode;
var
  k: integer;
  elemName: string;
  eNext: array of string;
begin
  result := nil;
  if not assigned(iNode) then exit;
  elemName := eNames[0];
  if iNode.ChildNodes.IndexOf(elemName) >=0 then
  begin
    if High(eNames) =0 then
      result := iNode.ChildNodes[elemName]
    else
    try
      SetLength(eNext, High(eNames));
      for k := 0 to High(eNext) do
        eNext[k] := eNames[k+1];

      result := GetChildNode(iNode.ChildNodes[elemName],eNext);
    finally
      Finalize(eNext);
    end;
  end;
end;

{function GetChildNodeParam(const iNode: IXMLNode;
  eNames: array of string; const aParam: string =''): IXMLNode;
var
  k,j: integer;
  elemName: string;
  eNext: array of string;
  tNode: iXMLNode;
begin
  result := nil;
  if not assigned(iNode) then exit;
  elemName := eNames[0];

  if High(eNames) =0 then begin
    if iNode.ChildNodes.IndexOf(elemName) >=0 then
      result := iNode.ChildNodes[elemName];
   end
  else begin
    SetLength(eNext, High(eNames));
    for k := 0 to High(eNext) do
      eNext[k] := eNames[k+1];

    if iNode.ChildNodes.IndexOf(elemName) >=0 then begin

      if High(eNames) >1 then
        result := GetChildNodeParam(iNode.ChildNodes[elemName],eNext,aParam)
      else
      for j := 0 to iNode.ChildNodes.Count-1 do
      if Assigned(iNode.ChildNodes[j]) and
        SameText(iNode.ChildNodes[j].Text,elemName) then
      begin
        tNode := iNode.ChildNodes[eNames[1]]; //1
        if Assigned(tNode) and (tNode.ChildNodes.IndexOf(eNames[1]) >=0) then
          for k := 0 to tNode.ChildNodes.Count-1 do
          if Assigned(tNode.ChildNodes[k]) and
          SameText(tNode.ChildNodes[j].Text, aParam) then
            result := tNode;
      end;
    end;
    Finalize(eNext);
  end;
end;}


function GetChildNodeAsString(iNode: IXMLNode; eNames: array of string): string;
var
  nextNode: IXMLNode;
begin
  nextNode := GetChildNode(iNode, eNames);
  if assigned(nextNode) then
    result := nextNode.Text
  else result := '';
end;

function GetXMLNodeAsString(const iNode: IXMLNode;
  elemName: string): string;
begin
  result := '';
  if XMLNodeExist(iNode,elemName) then
    result := iNode.ChildNodes[elemName].Text;
end;

function XMLNodeExist(const aNode: iXmlNode; const anodeName: String): bool;
begin
  result := assigned(aNode) and (aNode.ChildNodes.IndexOf(aNodeName) >=0);
end;

function GetXMLText(const aNode: iXmlNode; nodeNames: array of string): String;
var
  tNode: IXMLNode;
begin
  result := '';
  if Length(nodeNames) =0 then
    tNode := aNode
  else tNode := GetChildNode(aNode, nodeNames);

  if assigned(tNode) and tNode.IsTextElement then
    result := tNode.Text
end;

function ParseIfxNodeDate(const iNode: IXMLNode): TDateTime;
var
  sDateStr: string;
begin
  Result := 0.0;
  if Assigned(iNode) then
  try
    sDateStr := GetXMLText(iNode,['Day']) + DateSeparator+
                GetXMLText(iNode,['Month']) + DateSeparator+
                GetXMLText(iNode,['Year']);
    result := str2Date(sDateStr, 'DD'+DateSeparator+'MM'+DateSeparator+'YYYY');
  except
  end
end;

{ TXMLStatm }

constructor TXMLStatement.Create(const iNode,iAcntNode: IXMLNode;
                                 const aFName,aHeadValues: string;
                                 const aAgentID: integer;
                                 const aLogFn: TRemoteLogProc;
                                 const MinAccNoStrLength: integer =10);
begin
  try
    inherited Create( aFName,aAgentID);
    SetLogFunc(aLogFn, nil);
    FSrcName := aFName;
    AgentID := aAgentID;
    SetLogFunc(aLogFn, nil);
    SetHeaderValues(aHeadValues);

    OwnerName     := GetChildNodeAsString(iNode, ['ClientSet','Name']);
    OwnerAddress  := GetChildNodeAsString(iNode, ['ClientSet','Address']);
    IBAN          := GetXMLNodeAsString( iAcntNode, 'IBAN');
    AccntTypeChar := GetXMLNodeAsString( iAcntNode, 'AccType');
  except
    raise;
  end;
end;

function  TXMLStatement.OpenXMLAccountData(const iAcntNode: IXMLNode): integer;
var
  j: integer;
  sCurr: String;
  xmlCurrAccnt: TXMLAccount;
  nodeCurrStmt: IXMLNode;
begin
  result := 0;
  if assigned(iAcntNode) then
  for j := 0 to iAcntNode.ChildNodes.Count-1 do
    if assigned(iAcntNode.ChildNodes[j]) and
      SameText(iAcntNode.ChildNodes[j].NodeName,'CcyStmt') then
    try
      nodeCurrStmt := iAcntNode.ChildNodes[j];
      sCurr        := GetChildNodeAsString(nodeCurrStmt, ['Ccy']);
      if Length(sCurr) =0 then begin
        addToLog('Не определена валюта счета');
        Continue;
      end;
      if not nodeCurrStmt.HasChildNodes then begin
        addToLog(format('Выписка по счету ''%s'' не содержит операций',[sAccount]));
        Continue;
      end;
      try
        xmlCurrAccnt := XMLAccountCreateEx(nodeCurrStmt, sCurr);
        if assigned(xmlCurrAccnt) then
        begin
          xmlCurrAccnt.AddXMLTransactions( nodeCurrStmt, SrcName);
          Inc(result, xmlCurrAccnt.SaveToFile(FDumpName));
        end;
      finally
        xmlCurrAccnt.Free;
      end;
    except
      AddToLog(Format('Ошибка в процессе обработки .XML данных: %s',[FSrcName]));
    end;
end;


{constructor TXMLStatement.CreateFromFile(const sFName: string;
                                           const iAgentID: integer);
var
  FS: TStreamStorage;
begin
end;}


function TXMLStatement.XMLAccountCreateEx;
var
  vAccount: TXMLAccount;
  sOpenBal,sCloseBal: String;
begin
  result := nil;
  try
    vAccount := TXMLAccount.Create(sAccount,sCurr, OwnerName,BankName);
    if assigned(vAccount) then
    begin
      vAccount.SetOwnerStatement(Self);

      sOpenBal  := GetChildNodeAsString(iNode, ['OpenBal']);
      sCloseBal := nvlstr(GetChildNodeAsString(iNode, ['CloseBal']),
                         GetChildNodeAsString(iNode, ['Extension','AVAILBAL']));
      vAccount.InpValue := Str2Float(sOpenBal);
      vAccount.OutValue := Str2Float(sCloseBal);

      vAccount.DebtOver := Str2Float(GetChildNodeAsString(iNode, ['Extension','SUMDEBIT']));
      vAccount.CredOver := Str2Float(GetChildNodeAsString(iNode, ['Extension','SUMCREDIT']));
      result := vAccount;
    end;
  except
    raise;
  end;
end;

{ TXMLTrans }

constructor TXMLTrans.Create(const iNode: IXMLNode; const vOwnAccnt: TObject;
                              const DC: String);
var
  sCorrName,sCorrAccnt,sCorrBankCode,sCorrBankName: String;
  PmtDate: TDateTime;
begin
  try
    inherited Create('');
    DocDate    := xmlString2Date( nvlStr( iNode.ChildNodes['BookDate'].Text,
                                          iNode.ChildNodes['RegDate'].Text));
    PmtDate    := xmlString2Date(iNode.ChildNodes['ValueDate'].Text);
    DCFlag     := DC;
    BankRef    := iNode.ChildNodes['BankRef'].Text;
    PaymDocNo  := nvlstr(iNode.ChildNodes['DocNo'].Text, BankRef);
    PaymInfo   := nvlstr( iNode.ChildNodes['PmtInfo'].Text, iNode.ChildNodes['TypeName'].Text);
    PaymValStr := iNode.ChildNodes['AccAmt'].Text;
    sCorrAccnt := GetChildNodeAsString( iNode, ['CPartySet','AccNo']);
    sCorrName  := GetChildNodeAsString( iNode, ['CPartySet','AccHolder','Name']);
    RefineCorrName (sCorrName,sCorrAccnt);
//  CurrCh     := GetChildNodeAsString( iNode, ['CPartySet','Ccy']);
    sCorrBankCode := GetChildNodeAsString( iNode, ['CPartySet','BankCode']);
    sCorrBankName := GetChildNodeAsString( iNode, ['CPartySet','BankName']);
    SetPaymAttributes(vOwnAccnt, DocDate,PmtDate,
                      sCorrName,sCorrAccnt, sCorrBankName,sCorrBankCode);
  except
    raise ;
  end;
end;

procedure TXMLTrans.RefineCorrName(var aName,aAccnt: String);
begin
  if (length(aName) <22) or (Length(aAccnt) <>0) then exit;

  if (pos(' ',aName)=22) and (aName[21] in['0'..'9']) then begin
    aAccnt := copy(aName,1,21);
    aName := Trim(Copy(aName, pos(' ',aName)+1,Length(aName)));
  end;
end;

function TXMLTrans.GetTransDateStr(const aValue: AnsiString): TDateTime;
begin
  result := inherited GetTransDateAsString(aValue);
  if result <1 then
    result := xmlString2Date(aValue);
end;


{ TXMLAccount }

procedure TXMLAccount.AddXMLTransactions;
var
  TheXMLTrans: TXmlTrans;
  i: integer;
  DC: string;
begin
  for i:= 0 to iNode.ChildNodes.Count-1 do
  if assigned(iNode.ChildNodes[i]) and (iNode.ChildNodes[i].NodeName ='TrxSet') then
  try
    DC := GetXMLNodeAsString( iNode.childNodes[i], 'CorD');
    if (Length(DC) =1) and ((DC[1] in ['C','D'])) then
    begin
      TheXMLTrans := TxmlTrans.Create(iNode.childNodes[i], Self, DC);
      AddTransaction( TheXMLTrans);
     end
    else
      addToLog(format('%s: неопределенный платежный документ по счету "%s"',
                           [sFName,spAccount]));
  except
    AddToLog(format('%s: ошибка преобразования данных по счету "%s"',[sFName,spAccount]));
  end;
end;

procedure TXMLAccount.AddPayment;
begin

end;


{ TIfxStmt }

constructor TIfxStmt.Create(const accNode: IXMLNode;
  const aFName,sAgentName,sAgentAddr: string; const aAgentID: integer;
  const aLogFn: TRemoteLogProc; const MinAccNoStrLength: integer=10);
var
  sV, sAccNo,sAccCurr, sBalType,sBalValue,sDateStr,sChkNum,sXferId,sPmtid,
   sSWIFT,sBankName,sBankAddr,sNodeName: string;
  nDep,nPost,nStmt,iNode: iXMLNode;
  fBalValue: Double;
  ifxAccount: TPaymAccount;
  ifxPmt: TIfxPmt;
//  sList: TStringList;
//k,j: Integer;
begin
  try
//  sSWIFT := '';
    sBankName := ''; sBankAddr := '';
    nDep := GetChildNode(accNode,['DepAcctId']);
    if not Assigned(nDep) then begin
      addToLog(format(sAccNoErr, [aFName,'DepAcctId']));
     end
    else begin
      sAccNo := GetChildNodeAsString(nDep, ['AcctId']);
      sAccCurr := GetChildNodeAsString(nDep, ['AcctCur']);
//    sSWIFT    := GetChildNodeAsString(nDep, ['BankInfo','BankId']);
      sBankName := GetChildNodeAsString(nDep, ['BankInfo','BranchName']);

      if (Length(sAccNo) >=MinAccNoStrLength) and (Length(sAccCurr) >0) then
      begin
        nPost := GetChildNode(nDep, ['BankInfo','PostAddr']);
        if Assigned(npost) then
          sBankAddr := GetChildNodeAsString(npost, ['Addr1'])+', '+
                       GetChildNodeAsString(npost, ['City'])+', '+
                       GetChildNodeAsString(npost, ['PostalCode'])+', '+
                       GetChildNodeAsString(npost, ['Country']);

        nStmt := GetChildNode(accNode, ['DepAcctStmtRec']);
        if Assigned(nStmt) then
        begin
          inherited Create(aFName,aAgentID);
          SetLogFunc(aLogFn, nil);
          OwnerName     := sAgentName;
          OwnerAddress  := sAgentAddr;
          sAccount      := sAccNo;
          ifxAccount := TFileSaveAccount.Create(sAccNo,sAccCurr,sAgentName,sBankName);
          while nStmt.ChildNodes.Count >0 do begin
            if Assigned(nStmt.ChildNodes[0]) then begin
              if SameText(nStmt.ChildNodes[0].NodeName,'AcctBal') then
              begin
                sBalType := GetXMLText(nStmt.ChildNodes[0],['BalType']);
                sBalValue := GetXMLText(nStmt.ChildNodes[0],['CurAmt','Amt']);
                if SameText(sBalType,'OpeningLedger') then
                  ifxAccount.InpValue := str2float(sBalValue)
                else
                if SameText(sBalType,'ClosingLedger') then
                  ifxAccount.OutValue := str2float(sBalValue);
               end
              else
              if SameText(nStmt.ChildNodes[0].NodeName,'StmtSummAmt') then
              begin
                sBalType := GetXMLText(nStmt.ChildNodes[0],['StmtSummType']);
                sBalValue := GetXMLText(nStmt.ChildNodes[0],['CurAmt','Amt']);
                if SameText(sBalType,'CreditsOnly') then
                  ifxAccount.CredOver := str2float(sBalValue)
                else
                if SameText(sBalType,'DebitsOnly') then
                  ifxAccount.DebtOver := Abs(str2float(sBalValue));
               end
              else
              if SameText(nStmt.ChildNodes[0].NodeName,'StartDt') then
                StartDate := ParseIfxNodeDate(nStmt.ChildNodes[0])
              else
              if SameText(nStmt.ChildNodes[0].NodeName,'EndDt') then
                EndDate := ParseIfxNodeDate(nStmt.ChildNodes[0])
              else
              if SameText(nStmt.ChildNodes[0].NodeName,'DepAcctTrnRec') then
              begin
               sChkNum := GetXMLText(nStmt.ChildNodes[0],['ChkNum']);
               sXferId := GetXMLText(nStmt.ChildNodes[0],['XferId']);
               sPmtId  := GetXMLText(nStmt.ChildNodes[0],['PmtId']);
               iNode := GetChildNode(nStmt.ChildNodes[0],['BankAcctTrnRec']);

               if assigned(iNode) then begin
                 ifxPmt := TIFXPmt.Create(iNode, ifxAccount,sChkNum,sXferId,sPmtId);
                 ifxAccount.AddTransaction(ifxPmt);
               end;
              end;
            end;
            nStmt.ChildNodes.Delete(0);
          end;
          ifxAccount.SetOwnerStatement(Self);
          Add(ifxAccount);
        end;
       end
      else
        AddToLog(format(sAccNoErr,[aFName,'AccNo']));
    end;
  except
    addToLog(format(sHeadReadErr, [aFName]));
    raise;
  end;
end;

{ TIfxPmt }

constructor TIfxPmt.Create(const iNode: IXMLNode;
  const vOwnAccnt: TObject; const aChkNum,aXfer,aPmtId: String);
var
  j: integer;
  sv,sValue,tPmtInfo,sCorrName,sCorrAccnt,sCorrBankCode,sCorrBankName: String;
  PmtDate: TDateTime;
  tAmt: Currency;
begin
  inherited Create;
  sV := '';
  BankRef    := aPmtId;
  PaymDocNo  := nvlstr(aXfer, BankRef);
  try
    while iNode.ChildNodes.Count >0 do begin
      if assigned(iNode.ChildNodes[0]) then begin
        sv := iNode.ChildNodes[0].NodeName;
        if SameText(iNode.ChildNodes[0].NodeName,'PostedDt') then
          PmtDate := ParseIfxNodeDate(iNode.ChildNodes[0])
        else
        if SameText(iNode.ChildNodes[0].NodeName,'OrigDt') then
          DocDate := ParseIfxNodeDate(iNode.ChildNodes[0])
        else
        if SameText(iNode.ChildNodes[0].NodeName,'CurAmt') then begin
          sValue := GetXMLText(iNode.ChildNodes[0],['Amt']);
          tAmt := str2float(sValue);
          PaymValue := abs(tAmt);
          if tAmt >0.001 then  //creds
            DCFlag := 'C'
          else
          if tAmt <-0.001 then
            DCFlag := 'D'
          else begin
            inherited Free;
            Fail;
          end;
         end
        else
        if SameText(iNode.ChildNodes[0].NodeName,'Name') then
          sCorrName := GetXMLText(iNode.ChildNodes[0],[])
        else
        if SameText(iNode.ChildNodes[0].NodeName,'Memo') then
        begin
          tPmtInfo := GetXMLText(iNode.ChildNodes[0],[]);
          if pos(#13#10, tPmtInfo) >0 then
            tPmtInfo := AnsiReplaceStr(tPmtInfo, #13#10,'')
          else tPmtInfo := AnsiReplaceStr(tPmtInfo, #10,'');

          j := Pos(':70:',tPmtInfo);
          if j >0 then
           tPmtInfo := Copy(tPmtInfo, j+4, Length(tPmtInfo));
         end
        else
        if SameText(iNode.ChildNodes[0].NodeName,'CounterpartyInfo') then
        begin
          sCorrAccnt := GetXMLText(iNode.ChildNodes[0], ['DepAcctId','AcctId']);
//        RefineCorrName(sCorrName,sCorrAccnt);
          sCorrBankName := GetXMLText(iNode.ChildNodes[0],
                                    ['DepAcctId','BankInfo','Name']);
          sCorrBankCode := GetXMLText(iNode.ChildNodes[0],
                                    ['DepAcctId','BankInfo','RefInfo','RefId']);
         end
        else
        if SameText(iNode.ChildNodes[0].NodeName,'RefInfo') then
        begin
          if SameText(GetXMLText(iNode.ChildNodes[0],['RefType']),'PaymentName') then
            PaymInfo := GetXMLText(iNode.ChildNodes[0],['RefId'])+': '+tPmtInfo
          else ;
        end;
    //sV := sV + nStmt.ChildNodes[0].NodeName + ', ';
      end;
      iNode.ChildNodes.Delete(0);
    end;
    SetPaymAttributes(vOwnAccnt, DocDate,PmtDate,
                      sCorrName,sCorrAccnt, sCorrBankName,sCorrBankCode);
  except
    Fail;
  end;
end;

{ TFileSaveAccount }

function TFileSaveAccount.MakeCurrFName: String;
begin
  if Assigned(Owner) then
    result := CurrFNameTranslate(Owner.FDumpName, CurrCh)
  else Result := '';
end;

function TFileSaveAccount.SaveToFile(const aFName: String =''): integer;
var
  FS: TStreamStorage;
  sFName: String;
begin
  result := 0;
  sFName := MakeCurrFName;
  if Length(sFName) =0 then Exit;
  FS := TStreamStorage.Create(TFileLogStream.Create( sFName));
  if assigned(FS) then
  try
    if Assigned(Owner) then
    try
      Owner.StoreHeaderAs1CText101(FS);
      result := StoreAccountHeaderAs1CText(FS);
      FS.WriteText(RawFmtLast,#0);
      Result := 1;
    except
      Result := -2;
      addToLog(format(sErrDueSaving +'%s счет ''%s''file:%s',
                  [OwnerName, spAccount, sFName]));
    end;
  finally
    FS.Free;
  end;
end;


end.


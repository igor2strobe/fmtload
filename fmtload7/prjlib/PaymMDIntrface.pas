unit PaymMDIntrface;

interface

uses
  Sharemem,
  SysUtils, Classes, Windows,
  DB,RxMemDs,
  ConverDll,PaymClass,
  Sys_uLog, Sys_iStrUtils;

type
  TPaymMD =class(TrxMemoryData)
  private
    FSysLogFn: TRemoteLogProc;    // журнал приложения
    FLogList: TStrings;           // внешний список для журнала
    FLogLevel: Word;              // уровень детализации приложения
    FErrLevel: Word;
    FDataSortStr: String;
    FTStatus: integer;            // Statistic & Errors
    FAccOwner: TPaymAccount;

    FInpValue: Double;
    FOutValue: Double;
    FChkValue: Double;
    FCredOverChk: Double;              // ВсегоПоступило обороты
    FDebtOverChk: Double;              // ВсегоСписано обороты

    procedure AddToLog( aMsg: string; const lstLog: TStrings=nil; const iLevel: Word =$01);

    function  ResetPaymChain: integer;
    function  ResetDuplicates: integer;
    function  ScanTwinSerial(sort_md: TrxMemoryData): integer;
    function  IsTransactionEmpty(const aEpsValue: double=0.001): bool;
    procedure AddFlowDebt( const vDebt: double);
    procedure AddFlowCred( const vCred: double);
  public
    property  InpValue: Double read FInpValue;
    property  OutValue: Double read FOutValue;
    property  ChkValue: Double read FChkValue write FChkValue;

    property  TStatus: integer read FTStatus write FTStatus;

    function  RecDumpStr(const iLevel: Word=$01; const DelimChar: String='; '): string;
    function  LoadAccount(const aAccnt: TPaymAccount): integer;
    function  Validate(const aSortStr: String; const aDataCheck: Word): integer;

    procedure  AssignDataLog(aLogFn: TRemoteLogProc; const aListLog: TStrings=nil;
                              const isForced: bool=FALSE);
    constructor Create(const aOwner: TPaymAccount; const aSrcMD: TDataSet;
                       aLogFn: TRemoteLogProc; aLogList: TStrings;
                       const aLogLevel: integer =0);
  end;


implementation

uses dbUtils,Math,Variants,
  db_RefUtils;

{ TPaymMD }

procedure TPaymMD.AddFlowCred(const vCred: double);
begin
  FCredOverChk := FCredOverChk +vCred;
end;

procedure TPaymMD.AddFlowDebt(const vDebt: double);
begin
  FDebtOverChk := FDebtOverChk +vDebt;
end;

procedure TPaymMD.AddToLog;
begin
  if assigned( FSysLogFn) then
    FSysLogFn(aMsg, lstLog, iLevel);
end;

procedure TPaymMD.AssignDataLog(aLogFn: TRemoteLogProc;
                  const aListLog: TStrings=nil; const isForced: bool=FALSE);
begin
  if assigned(aLogFn) or IsForced then
    FSysLogFn := aLogFn;
  FLogList := aListLog;
end;

constructor TPaymMD.Create;
begin
  try
    inherited Create(nil);
    if aSrcMD.Active then
      aSrcMD.Close;
    CopyStructure(aSrcMD);

    FAccOwner := aOwner;
    AssignDataLog(aLogFn,aLogList);
    FLogLevel := aLogLevel;
    FCredOverChk := 0.0;              // ВсегоПоступило обороты
    FDebtOverChk := 0.0;              // ВсегоСписано обороты
    Open;
  except
    raise;
  end;
end;

function TPaymMD.IsTransactionEmpty(const aEpsValue: Double =0.001): bool;
begin
  result := (abs(fieldByName('CA_SUMM_CRED').asFloat) <aEpsValue) and
            (abs(fieldByName('CA_SUMM_DEBT').asFloat) <aEpsValue);
end;

function TPaymMD.LoadAccount;
var
  aData: TPaymTrans;
  j: integer;
begin
  result := 0;
  if assigned(aAccnt) and (not aAccnt.IsEmpty) then
  try
    if Active then begin
      Close;
      EmptyTable;
    end;
    Open;
    FInpValue := aAccnt.InpValue;
    FOutValue := aAccnt.OutValue;
    FChkValue := inpValue;

    for j := 0 to aAccnt.Count -1 do
    if assigned(aAccnt[j]) then
    try
      aData := aAccnt[j];
      Insert;
      FieldByName('UIN_CORR_ACNT').Value    := TPaymAccount(aAccnt).AccountID;
      FieldByName('CH_CURR').AsString       := TPaymAccount(aAccnt).CurrCh;
      FieldByName('ID_CURR').asInteger      := TPaymAccount(aAccnt).CurrId;
//    FieldByName('CORR_ACNT_NAME').asString := FAcntName;
      FieldByName('CA_DOC_DATE').asDateTime    := aData.DocDate;
      FieldByName('CA_DOC_ORG').asString       := aData.BankRef;
      FieldByName('CA_DOCUMENT').asString      := aData.PaymDocNo;
      FieldByName('CA_PAY_DATE').asDateTime    := aData.PaymDate;
      FieldByName('Pay_comment').asString      := aData.PaymInfo;
      FieldByName('DEB_CRED').asString         := aData.DCFlag;

      FieldByName('Debet_cli_acnt').asString   := nvlstr(aData.DebtAccnt,' ');
      FieldByName('Debet_cli_name').asString   := aData.DebtName;
      FieldByName('Debet_bank_name').asString  := aData.DebtBankName1;
      FieldByName('Debet_bank_bic').asString   := aData.DebtBankCode;

      FieldByName('Credit_cli_acnt').asString  := nvlstr(aData.CredAccnt,' ');
      FieldByName('Credit_cli_name').asString  := aData.CredName;
      FieldByName('Credit_bank_bic').asString  := aData.CredBankCode;
      FieldByName('Credit_bank_name').asString := aData.CredBankName1;
 //   FieldByName('CA_SUMM_DEBT').AsFloat      := 0.0;
 //   FieldByName('CA_SUMM_CRED').asFloat      := 0.0;

      if TPaymTrans(aData).DCFlag[1] ='D' then
        FieldByName('CA_SUMM_DEBT').AsFloat    := roundTo(aData.PaymValue,-2)
      else
      if TPaymTrans(aData).DCFlag[1] ='C' then
        FieldByName('CA_SUMM_CRED').asFloat    := roundTo(aData.PaymValue,-2);
      Post;
    except
      if State in [dsEdit] then Post;
      result := -1;
    end;
  finally
    if result =0 then
      result := RecordCount;
  end;
end;

function TPaymMD.ScanTwinSerial( sort_md: TrxMemoryData): integer;
var
  isTwinned: bool;
const
  sCompare1: string =
  'CA_DOC_DATE;CA_PAY_DATE;CA_DOCUMENT;CA_SUMM_DEBT;CA_SUMM_CRED;DEBET_CLI_ACNT;CREDIT_CLI_ACNT';
  sCompare2: string =
  'CA_DOC_DATE;CA_PAY_DATE;CA_DOCUMENT;CA_SUMM_DEBT;CA_SUMM_CRED';
begin
  result := 0;
  SortOnFields( FDataSortStr);
  First;
  Sort_md.SortOnFields(FDataSortStr);
  Sort_md.First;
  isTwinned := FALSE;

    while not EoF do begin
      while not Sort_md.EoF do begin

        if Sort_md.RecNo >RecNo then
        begin
          if DataSetLocateThrough(Sort_md, sCompare1,
             VarArrayOf([fieldByName('ca_doc_Date').asDateTime,
                         fieldByName('ca_pay_Date').asDateTime,
                         fieldByName('ca_document').asString,
                         fieldByName('ca_summ_Debt').asFloat,
                         fieldByName('ca_summ_Cred').asFloat,
                         fieldByName('debet_cli_acnt').asString,
                         fieldByName('CREDIT_CLI_ACNT').asString]),[]) then
               isTwinned := FSetDataSetField(Self, 'STAMP', -1) =0
             else
             if isTwinned then begin
               isTwinned := DataSetLocateThrough(Sort_md, sCompare2,
                        varArrayOf([FieldByName('ca_doc_Date').asDateTime,
                                    FieldByName('ca_pay_Date').asDateTime,
                                    fieldByName('ca_document').asString,
                                    fieldByName('ca_summ_Debt').asFloat,
                                    fieldByName('ca_summ_Cred').asFloat]),[]);

               if isTwinned then
                 if FSetDataSetField(Self, 'STAMP', -1) =0 then
                   inc(result);
             end;
           if isTwinned then
             inc( result);
        end; //Sort_md.RecNo >RecNo
        Sort_md.next;
      end;
      next;
    end;
end;


function TPaymMD.ResetDuplicates: integer;
var
  twins_open: bool;
  twins_count: integer;
  temp_md: TrxMemoryData;
begin
  result := 0;
  if RecordCount <2 then Exit;
  temp_md := TrxMemoryData.Create(nil);
  temp_md.CopyStructure( Self);
  if temp_md.LoadFromDataSet(Self, 0, lmCopy) <>RecordCount then
    addToLog( {FData.DefineStr +}': внутренняя ошибка клонирования данных')
  else
  if ScanTwinSerial(temp_md) >0 then
  try
    twins_open := FALSE;
    twins_count := 0;  //renumerate lines
    first;
    while not EoF do begin
      if (FieldByName('stamp').AsInteger =-1) or Twins_Open then
      begin
        Edit;
        fieldbyname('ca_doc_org').asString  := fieldbyname('ca_document').asString;
        fieldbyname('ca_document').asString := format('%s[%2.2d]',
                      [fieldbyname('ca_doc_org').asString, twins_count]);
        post;
      end;
      if twins_open then begin
        twins_open  := FALSE;
        twins_count := 0;
       end
      else begin
        twins_open := FieldByName('stamp').AsInteger =-1;
        inc(twins_count);
      end;

{     if FieldByName('stamp').AsInteger =-1 then
      begin
        Edit;
        fieldbyname('ca_doc_org').asString  := fieldbyname('ca_document').asString;
        fieldbyname('ca_document').asString := format('%s[%2.2d]',
                      [fieldbyname('ca_doc_org').asString, twins_count]);
        post;
        inc(twins_count);
        twins_open := TRUE;
       end
      else begin
        if twins_open then
          Edit;
          fieldbyname('ca_doc_org').asString  := fieldbyname('ca_document').asString;
          fieldbyname('ca_document').asString := format('%s[%2.2d]',
                                  [fieldbyname('ca_doc_org').asString, twins_count]);
          Post;
          twins_open := FALSE;
        end;
        twins_count := 0;
      end;}
      next;
    end;
  except
    result :=-1;
  end;
  FreeAndNil( temp_md);
end;

function TPaymMD.ResetPaymChain: integer;
var
  fc,fd: Double;
begin
  result := 0;
  try
    Edit;
//  FieldByName('UIN_CORR_ACNT').asInteger := FAccntId;
//  FieldByName('ID_CURR').asInteger       := FCurrId;
//  FieldByName('CORR_ACNT_NAME').asString := FAcntName;
    if FieldByName('CA_DOC_ORG').asString ='' then
      FieldByName('CA_DOC_ORG').asString := fieldByName('CA_DOCUMENT').asString;

    fieldByName('INPUT_VALUE').asFloat := ChkValue;
    fd := roundTo( fieldByName('CA_SUMM_DEBT').asFloat, -2);
    fc := roundTo( fieldByName('CA_SUMM_CRED').asFloat, -2);
    ChkValue := RoundTo( ChkValue - fd+fc, -2);
    fieldByName('OUT_VALUE').AsFloat := ChkValue;
    Post;
    AddFlowDebt(fd);
    AddFlowCred(fc);
  except
    result := 1;
  end
end;


function TPaymMD.Validate(const aSortStr: String; const aDataCheck: Word): integer;
var
  fs: string;
begin
  result := 0;
//AddToLog(format(' memData.validate entry:(%d lines)',[recordCount]),FLogList,3);
  if not IsDataSetEmpty(Self) then
  try
    SortOnFields( aSortStr);
    First;
    while ( not eof) do begin
//    AddDataLog( FGetDumpStr(2), 2, FAcntName+'.dump');
      if IsTransactionEmpty and (aDataCheck >1) then
      begin      // Logging deleted Line
         Delete; // perform deleting
         continue;
      end;

      if ResetPaymChain =0 then
        inc(result)
      else
        ;//Logging invalid Line

      Next;
    end;
(*  if FDataLog >=4 then begin                 //   после 1й валидации
      AddDataLog(format('%s validate 2nd:(%d lines)',[DefineStr,recordCount]), 4, FAcntName+'.dump');
      first;
      while (not eof) do begin
        AddDataLog(FGetDumpStr(2), 2, FAcntName+'.dump');
        next;
      end;
    end;*)
    TStatus := integer(abs(ChkValue -OutValue) <0.001);
 (* if (aDataCheck >1) and (abs(ChkValue -OutValue) >0.001) then // совпадают ли остатки?
    begin
//    FDataSortStr := aSortStr;
//    result := ResetDuplicates();
      fs := 'по счету ''%s'' значение остатка в выписке (%14.2f)'#13#10+
            ' не совпадает с расчетным (%14.2f)'#13#10+
            'Сохранять данные несмотря на это?';
      AddToLog( fs,FLogList, 2);
      case MessageDlg(format(fs,[FAccOwner.spAccount,OutValue,ChkValue]),
             mtConfirmation,[mbYes,mbCancel],0) of
       idYes: begin
                result := RecordCount;
                AddToLog( 'Принято решение сохранить данные',FLogList, 2);
              end;
       idCancel :
              begin
                result := -1;
                AddToLog( 'Принято решение отменить сохранение',FLogList, 2);
              end;
      end;
     end
    else result := 0;*)
  except
    result := -1;
  end;
end;


function TPaymMD.RecDumpStr;
var
  s: string;
begin
  SetLength(result,0);

  if FLogLevel <iLevel then exit;
  result := format('%s|%s', [ fieldByName('CA_PAY_DATE').asString,
                              fieldByName('CA_DOCUMENT').asString]);
  result := result + DelimChar;

  if (FLogLevel >=iLevel) and (iLevel and $2 =$2) then
  begin
    if fieldByName('CA_PAY_DATE').Value <>fieldByName('CA_DOC_DATE').Value then
      result := result + format('{%s|%s}', [fieldByName('CA_DOC_DATE').asString,
                                            fieldByName('CA_DOC_ORG').asString])
    else
      result := result + format('{%s}', [ fieldByName('CA_DOC_ORG').asString]);
    result := result + DelimChar;
  end;

  s := fieldByName('DEB_CRED').asString;
  case s[1] of
   'C': result := result + format('+:%12.2f', [ fieldByName('CA_SUMM_CRED').asfloat]);
   'D': result := result + format('-:%12.2f', [ fieldByName('CA_SUMM_DEBT').asfloat]);
   else
    result := result + format('D|C: %f|%f', [ fieldByName('CA_SUMM_DEBT').asfloat,
                                              fieldByName('CA_SUMM_CRED').asfloat]);
  end;

  if (FLogLevel >=iLevel) and (iLevel and $02 =$02) then
  begin
    result := result + DelimChar +
     format('inp/out: %f/%f', [ fieldByName('INPUT_VALUE').asfloat,
                                           fieldByName('OUT_VALUE').asfloat]);
    result := result + DelimChar;
  end;

  if (FLogLevel >=iLevel) and (iLevel and $04 =$04) then
    result := result + delimChar + format('FROM %s(%s) TO %s(%s) %d',
                  [ fieldByName('DEBET_CLI_ACNT').asString,
                    fieldByName('DEBET_CLI_NAME').asString,
                    fieldByName('CREDIT_CLI_ACNT').asString,
                    fieldByName('CREDIT_CLI_NAME').asString,
                    fieldByName('Stamp').asInteger]);
end;

end.

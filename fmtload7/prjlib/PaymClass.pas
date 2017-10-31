unit PaymClass;

interface
uses
  Sharemem,
  Windows,SysUtils,Classes,DB,
  XMLIntf,
  PaymStorage,
  ConverDll;

type
  TPeriod =class
  private
    FStartDT, FEndDT: TDateTime;
  public
    property StartDT: TDateTime read FStartDT write FStartDT;
    property EndDT: TDateTime read FEndDT write FEndDT;
    constructor Create(const aStart,aEnd: TDateTime); virtual;
  end;

  THolder = class
  end;

  TPaymTrans =class                    // платеж по выписке
  private
    FDocDate: TDateTime;               // Дата=31.01.2011
    FPaymDocNo: AnsiString;            // Номер=5970540
    FPaymValue: Double;                // Сумма=-500
    FBankRef: String;
    FDCFlag: AnsiString;               // Дебет|Кредит
    FPaymInfo: ansiString;

    FDebtAccnt: AnsiString;            // ПлательщикСчет=40702810438150007661
    FDebtDate: TDateTime;              // ДатаСписано
    FDebtCode: AnsiString;             // ПлательщикИНН=7723776905 //ПлательщикКПП
    FDebtCode2: AnsiString;            // ПлательщикКПП
    FDebtCurrAccnt: AnsiString;        // ПлательщикРасчСчет
    FDebtName: AnsiString;             // Плательщик
    FDebtName1: AnsiString;            // Плательщик1=ООО "Стройполис Компани"
    FDebtName2: AnsiString;            // Плательщик2=
    FDebtBankCode: AnsiString;         // ПлательщикБИК=44525225
    FDebtCorrAccnt: AnsiString;        // ПлательщикКорсчет
    FDebtBankName1: AnsiString;        // ПлательщикБанк1=СБЕРБАНК РОССИИ ОАО Г.МОСКВА

    FCredAccnt: AnsiString;            // ПолучательСчет=706018106380021010101
    FCredDate: TDateTime;              // ДатаПоступило
    FCredCode: AnsiString;             // ПолучательИНН=
    FCredCode2: AnsiString;            // ПолучательКПП
    FCredCurrAcnt: AnsiString;         // ПолучательРасчСчет
    FCredName: AnsiString;             // Получатель
    FCredName1: AnsiString;            // Получатель1=
    FCredName2: AnsiString;            // Получатель2=
    FCredBankCode: AnsiString;         // ПолучательБИК=0
    FCredCorrAcnt: AnsiString;         // ПолучательКорСчет
    FCredBankName1: AnsiString;        // ПолучательБанк1=

    procedure SetDebtDate(const Value: TDateTime);
    procedure SetCredDate(const Value: TDateTime);
    function GetDocDateAsString: AnsiString;
    procedure SetDocDateAsString(const Value: AnsiString);
    function GetPaymValue: AnsiString;
    procedure SetPaymValue(const Value: AnsiString);
    function GetDebtDateStr: String;
    procedure SetDebtDateStr(const Value: String);
    function GetCredDateStr: String;
    procedure SetCredDateStr(const Value: String);
    function GetPaymDate: TDateTime;
  published
    function  GetTransDateAsString(const aValue: AnsiString): TDateTime; virtual;
    procedure SetAttributesDebt(const aAccnt: TObject); virtual; //abstract;
    procedure SetAttributesCred(const aAccnt: TObject); virtual; //abstract;
    procedure SetPaymAttributes(const aAccnt: TObject; const aDocDate,aPmtDate: TDateTime;
               const sName,sAccnt,bnkName,bnkCode: string); virtual;
  public
    property DocDate: TDateTime read FDocDate write FDocDate;
    property DocDateStr: AnsiString read GetDocDateAsString write SetDocDateAsString;
    property PaymDocNo: AnsiString read FPaymDocNo write FPaymDocNo;
    property PaymDate: TDateTime read GetPaymDate;
    property BankRef: String read FBankRef write FBankRef;
    property PaymValue: Double read FPaymValue write FPaymValue;
    property PaymValStr: AnsiString read GetPaymValue write SetPaymValue;
    property DCFlag: AnsiString read FDCFlag write FDCFlag;
    property PaymInfo: AnsiString read FPaymInfo write FPaymInfo;

    property DebtAccnt: AnsiString read FDebtAccnt write FDebtAccnt;
    property DebtDate: TDateTime read FDebtDate write SetDebtDate;
    property DebtDateStr: String read GetDebtDateStr write SetDebtDateStr;
    property DebtCode: AnsiString read FDebtCode write FDebtCode;
    property DebtCode2: AnsiString read FDebtCode2 write FDebtCode2;
    property DebtCurrAccnt: AnsiString read FDebtCurrAccnt write FDebtCurrAccnt;
    property DebtName: AnsiString read FDebtName  write FDebtName;
    property DebtName1: AnsiString read FDebtName1 write FDebtName1;
    property DebtName2: AnsiString read FDebtName2 write FDebtName2;
    property DebtBankCode: AnsiString read FDebtBankCode write FDebtBankCode;
    property DebtCorrAccnt: AnsiString read FDebtCorrAccnt write FDebtCorrAccnt;
    property DebtBankName1: AnsiString read FDebtBankName1 write FDebtBankName1;

    property CredAccnt: AnsiString read FCredAccnt write FCredAccnt;
    property CredDate: TDateTime read FCredDate write SetCredDate;
    property CredDateStr: String read GetCredDateStr write SetCredDateStr;
    property CredCode: AnsiString read FCredCode write FCredCode;
    property CredCode2: AnsiString read FCredCode2 write FCredCode2;
    property CredCurrAcnt: AnsiString read FCredCurrAcnt write FCredCurrAcnt;
    property CredName: AnsiString read FCredName write FCredName;
    property CredName1: AnsiString read FCredName1 write FCredName1;
    property CredName2: AnsiString read FCredName2 write FCredName2;
    property CredBankCode: AnsiString read FCredBankCode write FCredBankCode;
    property CredCorrAcnt: AnsiString read FCredCorrAcnt write FCredCorrAcnt;
    property CredBankName1: AnsiString read FCredBankName1 write FCredBankName1;

    function StoreAs1CText( FS: TStreamStorage): integer; virtual;
//  function SetAttributes(
    constructor Create(const aData: String=''); virtual;
    constructor CreateFromStr( vOwnAccnt: TObject; aData: TStringList;
                               aDC,aSubsider: String); virtual;
  end;

  TCustStatement =class;

  TPaymAccount =class(TList)           // of TPaymTrans ( счет выписки )
  private
    FStrAccount: AnsiString;           //РасчСчет
    FAccountID: longint;
    FOwnerName: String;                //
    FOwnBank: String;                  //
    FOwnBankCode: String;
    FViewName: String;
    FCurrCode: LongInt;                // ISO код/номер
    FCurrID: Longint;                  // db ID валюты
    FCurrCh: string;                   // ISO символьный код
    FTaxCode: string;

    FStartDT: TDateTime;               // ДатаНачала
    FEndDT: TDateTime;                 // ДатаКонца
    FInpValue: Double;                 // НачальныйОстаток
    FOutValue: Double;                 // КонечныйОстаток
    FCredOver: Double;                 // ВсегоПоступило
    FDebtOver: Double;                 // ВсегоСписано
    FCredOverChk: Double;              // ВсегоПоступило обороты
    FDebtOverChk: Double;              // ВсегоСписано обороты

    FLogFn:  TRemoteLogProc;           //
    FOwner:  TCustStatement;           // TCustStatement onwer
    FMDPort: TDataSet;                 // see PaymMDIntrface
    FAccStatus: integer;               //
    FNumErr: integer;                  // statistic items
    FNumUpd: integer;                  //
    FNumAdd: integer;                  //
    procedure SetStartDate(const Value: TDateTime);
    procedure SetEndDT(const Value: TDateTime);
    procedure SetInpValue(const Value: Double);
    procedure SetOutValue(const Value: Double);
    procedure SetCredOver(const Value: Double);
    procedure SetDebtOver(const Value: Double);
    procedure AddCredOverChk(const Value: Double);
    procedure AddDebtOverChk(const Value: Double);
    function  GetReportName: String;
  published
    procedure AddToLog( const aMsg: string; const lstLog: TStrings=nil; const iLevel: Word =$01);
    procedure DataLogString(const s: String; const iLevel: Word; const sLogFName: string);
    function  IsEmpty: bool;
    function  MDStatus(out fSourced, fChecked: Double): integer;
  public
    property spAccount: AnsiString read FStrAccount write FStrAccount;
    property AccountID: longInt read FAccountID;
    property ViewName: string read FViewName;
    property ReportName: String read GetReportName;
    property mdPort: TDataSet read FMDPort;
    property Owner: TCustStatement read FOwner;
    property TaxCode: string read FTaxCode write FTaxCode;

    property NumErr: integer read FNumErr write FNumErr;
    property NumUpd: integer read FNumUpd write FNumUpd;
    property NumAdd: integer read FNumAdd write FNumAdd;
    property AccStatus: integer read FAccStatus write FAccStatus;

    property OwnerName: string read FOwnerName write FOwnerName;
    property OwnBank: string read FOwnBank write FOwnBank;
    property OwnBankCode: string read FOwnBankCode write FOwnBankCode;

    property CurrID: LongInt read FCurrID;
    property CurrCode: LongInt read FCurrCode write FCurrCode;
    property CurrCh: string read FCurrCh write FCurrCh;

    property StartDT: TDateTime read FStartDT write SetStartDate;
    property EndDT: TDateTime read FEndDT write SetEndDT;
    property InpValue: Double read FInpValue write SetInpValue;
    property OutValue: Double read FOutValue write SetOutValue;
    property CredOver: Double read FCredOver write SetCredOver;
    property DebtOver: Double read FDebtOver write SetDebtOver;
    property CredOverChk: Double read FCredOverChk write AddCredOverChk;
    property DebtOverChk: Double read FDebtOverChk write AddDebtOverChk;

    procedure SetPeriod(const aStartDT,aEndDt: TDateTime); virtual;
    procedure SetLogFunc(aLogFn: TRemoteLogProc); virtual;
    procedure SetOwnerStatement(aOwner: TCustStatement); virtual;

    function  IsProperPayment(const aList: TStringList; var aDC,aSubsider: String): longint;
    procedure SetCurrency(const sCurr: String=''; const iCurr: integer =0); virtual;
    procedure SetAccountID(const aAccntID,aCurrID: longint; const aViewName: string);
    procedure SetAccountData( const aStartDT,aEndDT: TDateTime;
               const aInpAmt,aOutAmt,aCredOver,aDebtOver: String); virtual;
    function  StoreAccountHeaderAs1CText( FS: TStreamStorage;
                              const IsHeaderOnly:bool=FALSE): integer; virtual;
    function  AddPayment(const lstSection: TStringList): integer; virtual;
    function  AddTransaction(aTrans: TPaymTrans): integer; virtual;
    function  ConvertToMemData( const mdTemplate: TComponent;
                                const iLevel: Word =$01): integer; virtual;
//  function  FindTransItem(const aDT: TDateTime; const aDocNo,aValStr): integer;
    function  Validate(const aSortStr: String; const iDataCheck: word): integer;

    constructor Create(const aAccount,aCurr,sOwnerName,sOwnBank: string); overload;virtual;
    constructor CreateAtList( lstStr: TStrings; const aAccount,
                             sOwnerName,sOwnBank: string); overload;virtual;

    destructor  Destroy; override;
  end;


  TCustStatement =class(TList) // of TPaymAccount
  private
    FAgentID: integer;

    FStartDT: TDateTime;
    FEndDT: TDateTime;
    FBankName: AnsiString;
    FBankAddr: AnsiString;
    FOwnerName: AnsiString;
    FOwnerAddr: AnsiString;
    FOwnerAccount: AnsiString;
    FIBAN: AnsiString;
    FAccntTypeChar: AnsiString;
    FStatus: LongWord;
    FLogFn: TRemoteLogProc;
    FLogList: TStrings;
    procedure SetStartDate(const Value: TDateTime);
    procedure SetEndDate(const Value: TDateTime);
    procedure SetBankName(const Value: AnsiString);
    procedure SetBankAddr(const Value: AnsiString);
    procedure SetOwnerName(const Value: AnsiString);
    procedure SetAccountStr(const Value: string);
    procedure SetOwnerAddress(const Value: AnsiString);
    procedure SetIBAN(const Value: string);
    procedure SetAccntTypeChar(const Value: string);
    function  GetAccountsIDLst: string;
    function  GetSrcName: string;
    function GetStartDateStr: String;
    function GetEndDateStr: String;
  published
//  function  LoadHeaderAs1CText101(FS: TStreamStorage): longint; virtual;

    function  StoreHeaderAs1CText101(FS: TStreamStorage): longint; virtual;
    function  StoreItemsAs1CText101(FS: TStreamStorage): longint; virtual;
    function  StoreAs1CText(Fs: TStreamStorage): longint; virtual;
    procedure StoreAs1CTextEnd(FS: TStreamStorage); virtual;
  public
    FSrcName: AnsiString;
    FDumpName: ansiString;

    property LogFn: TRemoteLogProc read FLogFn;
    property Status: LongWord read FStatus write FStatus;
    property SrcName: string read GetSrcName;
    property AgentID: integer read FAgentID write FAgentID;

    property sAccount: string read FOwnerAccount write SetAccountStr;
    property IBAN: string read FIBAN write SetIBAN;
    property AccntTypeChar: string read FAccntTypeChar write SetAccntTypeChar;

    property StartDate: TDateTime read FStartDt write SetStartDate;
    property EndDate: TDateTime read FEndDt write SetEndDate;
    property StartDateStr: String read GetStartDateStr;
    property EndDateStr: String read GetEndDateStr;

    property BankName: AnsiString read FBankName write SetBankName;
    property BankAddr: AnsiString read FBankAddr write SetBankAddr;
    property OwnerName: AnsiString read FOwnerName write SetOwnerName;
    property OwnerAddress: AnsiString read FOwnerAddr write SetOwnerAddress;
    property AccountsIDLst: string read GetAccountsIDLst;

    procedure SetLogFunc(const aLogFn: TRemoteLogProc;
                          const aLogList: TStrings =nil); virtual;
    procedure AddToLog( const aMsg: string; const lstLog: TStrings=nil;
                        const iLevel: Word =$01); virtual;

    procedure SetPeriod(const aStartDT,aEndDt: TDateTime); virtual;
    procedure SetHeaderValues(const aValues: String); virtual;
    procedure LoadFromText( aList: TStringList); virtual;

    function  AddNewAccount( aList: TStrings;
                             const aValues: String =''): integer; virtual;
    function  AddNewPayment( aList: TStringList): integer; virtual;

    constructor Create(aFName: String; const aAgentID: integer;
               aLogFn: TRemoteLogProc =nil; aLogList: TStrings =nil); virtual;
             //aLogFn: Pointer=nil; aLogList: TStrings =nil); virtual;


    constructor CreateAtList(aList: TStringList; const iAgentID: integer;
                      sHeadValues: String; const aLogFn: pointer=nil;
                      const aLogList: TStrings=nil); virtual;

    destructor  Destroy; override;
  end;


function TestValidRawMatch( aList: TStringList; var sErr: string): String;
function IsValidEmptyStmt( aList: TStrings;var sErr: string): integer;

function IsStatmntValid( aList: TStrings; var sErr: string; iPrm: Word): integer;

const
  RawFmtFirst = '1CClientBankExchange';
  RawFmtLast  = 'КонецФайла';

  HeaderParams: String =
  'ВерсияФормата='^M+            //  0
  'Кодировка='^M+                //
  'Отправитель='^M+              //  2
  'Получатель='^M+               //
  'ДатаСоздания='^M+             //  4
  'ВремяСоздания='^M+            //
  'ДатаНачала='^M+               //  6
  'ДатаКонца='^M+                //
  'РасчСчет=';                   //  8

  HeaderMasks: String =
  '1.01;1.02;1,01'^M+            //  0
  'Windows;windows-1251;Cp1251'^M+
  ' '^M+                         //  2
  ' '^M+                         //
  ' '^M+                         //  4
  ' '^M+                         //
  ' '^M+                         //  6
  ' '^M+                         //
  ' ';                           //  8

  DocParams: String =
  'СекцияДокумент'^M+            //  0
  'Номер='^M+                    //
  'Дата='^M+                     //
  'Сумма='^M+                    //
  'ДатаПоступило='^M+            //  4
  'ДатаСписано='^M+              //  5
  'ПлательщикСчет='^M+           //
  'Плательщик='^M+               //
  'ПлательщикИНН='^M+            //
  'Плательщик1='^M+              //  9
  'Плательщик2='^M+              // 10
  'ПлательщикРасчСчет='^M+       //
  'ПлательщикБанк1='^M+          //
  'ПлательщикБИК='^M+            //
  'ПлательщикКорсчет='^M+        // 14
  'ПолучательСчет='^M+           // 15
  'Получатель='^M+               //
  'ПолучательИНН='^M+            //
  'Получатель1='^M+              //
  'Получатель2='^M+              // 19
  'ПолучательРасчСчет='^M+       // 20
  'ПолучательБанк1='^M+          //
  'ПолучательБИК='^M+            //
  'ПолучательКорсчет='^M+        //
  'ВидПлатежа='^M+               // 24
  'ВидОплаты='^M+                // 25
  'Очередность='^M+              //
  'НазначениеПлатежа='^M+        //
  'ПлательщикКПП='^M+            //
  'ПолучательКПП='^M+            // 29
  'КонецДокумента';              // 30

  AccountParams: String =
  'СекцияРасчСчет'^M+            //  0
  'ДатаНачала='^M+               //
  'ДатаКонца='^M+                //  2
  'РасчСчет='^M+                 //
  '*CurrencyChar='^M+            //  4
  '*CurrencyCode='^M+
  'НачальныйОстаток='^M+         //  6
  'ВсегоПоступило='^M+           //
  'ВсегоСписано='^M+             //  8
  'КонечныйОстаток='^M+          //
  'КонецРасчСчет';               // 10

  sErrAccntHeader = 'ошибка при создании счета: "%s"';
  sErrAccNotFound = 'не найдено значение счета в блоке "%s"';
  sErrTransaction = 'документ "%s": ошибка определения параметра "%s"';
  sErrCreatePaymt = 'ошибка создания документа из блока данных';
  sInvalidPrm     = 'несоответствие формату параметра :';
  sErrCurrUnknown = 'не определена валюта счета';
  sErrDueSaving   = 'ошибка при сохранении ';

  minListStrCount = 4;

implementation
uses
  Dialogs,DateUtils, StrUtils,
  PaymMDIntrface,
   Sys_iStrUtils, Sys_iStrList, Sys_StrConv;

const
  mskAccount: SectionMask =
    (sBeginMask:'СекцияРасчСчет';
       sEndMask:'КонецРасчСчет');

  sMsgStmtEmpty = 'нет данных по операциям за данный период';


function MatchTaxCodeName(const aName:String; out aTaxCode: String): String;
var
  j: integer;
begin
  Result := aName;
  SetLength(aTaxCode,0);
  if (Pos(' ',aName) >0) and (aName[1] in ['0'..'9']) then
  begin
    j := 1;
    while (Length(aName) >j) and (aName[j] in ['0'..'9']) do
    begin
      aTaxCode := aTaxCode+aName[j];
      Inc(j);
    end;
    Result := Trim(Copy(aName,j,Length(aName)));
  end;
end;


function TestValidRawMatch( aList: TStringList; var sErr: string): String;
var
  iFileStart,iFileEnd: integer;
  sMatched,vValues: String;
begin
  SetLength(result, 0);
  SetLength(sErr, 0);
  SetLength(vValues,0);
{ if not assigned(aList) then
    sErr := 'Текст не содержит данных для распознавания'
  else}
  if aList.Count <16 then
    sErr := 'Недостаточно данных для распознавания'
  else
  begin
    iFileStart := MatchListParamValue(aList, sMatched, RawFmtFirst, [''], $10);
    iFileEnd   := MatchListParamValue(aList, sMatched, RawFmtLast, [''], $10);
    if iFileStart<>0 then
      sErr := sInvalidPrm + RawFmtFirst
    else
    if iFileEnd =0 then
      sErr := sInvalidPrm + RawFmtLast
    else
    begin
      while iFileEnd <aList.Count do
        aList.Delete(iFileEnd);

      if ExtractParamListValues(aList,HeaderParams,HeaderMasks,vValues,sErr) >0 then
        result := vValues;
    end;
  end;
end;

function IsValidEmptyStmt( aList: TStrings;var sErr: string): integer;
var
  fCred,fDebt,fInp,fOut: Double;
  sCredVal,sDebtVal,sInpVal,sOutVal,sMatched,vValues: String;
begin
  Result := -2;

  if (not Assigned(aList)) or (aList.Count <15) then begin
    sErr := sMsgStmtEmpty;
    Exit;
   end
  else SetLength(sErr,0);
  fCred := 0.0; fDebt := 0.0;
  Result := -1;

  if (MatchListParamValue(aList,sCredVal,'ВсегоПоступило',[''],0,15) =0) or
    (MatchListParamValue(aList,sDebtVal,'ВсегоСписано',[''],0,16) = 0) then
    sErr := 'нет данных по движению средств'
  else begin
    fCred := Str2Float(sCredVal);
    fDebt := Str2FLoat(sDebtVal);
  end;

  if (MatchListParamValue(aList,sInpVal,'НачальныйОстаток',[''],0,15) =0) or
    (MatchListParamValue(aList,sOutVal,'КонечныйОстаток',[''],0,16) =0) then
  begin
    if Length(sErr) >0 then sErr := sErr+', ';
    sErr := sErr + 'нет данных по остаткам';
   end
  else begin
    fInp := Str2Float(sInpVal);
    fOut := Str2FLoat(sOutVal);
  end;

  if (abs(fCred) <0.005) and (abs(fDebt) <0.005) and (abs(fOut-fInp) <0.005) then
  begin
    Result := 1;
    sErr := nvlStr(sErr,sMsgStmtEmpty);
   end
  else
   Result := 0;
end;


function SetNormalCompanyName( var aName: string; aNewName: String;
                               aTruncSet: array of string): Integer;
const
  sDefaultNullName = '1С:Предприятие';
var
  i: integer;
begin
  Result := 0;
  if (Length(aName) =0) or SameText(aName,sDefaultNullName) then
    aName := aNewName;
  if Length(aName) =0 then begin
    result := -1;
    exit;
  end;
  for i := 0 to High(aTruncSet) do
    if (Length(aTruncSet[i]) >0) and (Pos(aTruncSet[i],aName) >0) then
    begin
      ansiReplaceStr(aName,aTruncSet[i],'');
      Inc(Result);
    end;
end;


function IsStatmntValid( aList: TStrings; var sErr: string; iPrm: Word): integer;
begin
  Result := -2;
end;

{ TPaymAccount }

constructor TPaymAccount.Create(const aAccount,aCurr,sOwnerName,sOwnBank: string);
begin
  try
    inherited Create;
    spAccount := aAccount;
    SetCurrency(aCurr);
    OwnerName := sOwnerName;
    OwnBank   := sOwnBank;
  except
    raise;
  end;
end;


constructor TPaymAccount.CreateAtList(lstStr: TStrings; const aAccount,
                                       sOwnerName,sOwnBank: string);
var
  sDT1,sDT2,sCurrStr,sCodeStr,sInpVal,sOutVal,sDebt,sCred: String;
begin
  if not assigned(lstStr) then Fail
  else
  try
    inherited Create;
    spAccount := aAccount;
    sCurrStr  := GetParamListValueId( lstStr.Text, AccountParams,4); //['*CurrencyChar=']
    sCodeStr  := GetParamListValueID( lstStr.Text, AccountParams,5); //['*CurrencyCode=']
    SetCurrency( sCurrStr, Str2Int(sCodeStr));
    sDT1    := GetParamListValueId( lstStr.Text, AccountParams,1); //ДатаНачала
    sDT2    := GetParamListValueId( lstStr.Text, AccountParams,2); //['ДатаКонца']
    sInpVal := GetParamListValueID( lstStr.Text, AccountParams,6); //['НачальныйОстаток=']
    sCred   := GetParamListValueID( lstStr.Text, AccountParams,7); //['ВсегоПоступило=']
    sDebt   := GetParamListValueID( lstStr.Text, AccountParams,8); //['ВсегоСписано=']
    sOutVal := GetParamListValueID( lstStr.Text, AccountParams,9); //['КонечныйОстаток=']
    SetAccountData( Str2Date(sDT1), Str2Date(sDT2), sInpVal,sOutVal,sCred,sDebt);
  except
    Free;
    raise;
  end;
end;

destructor TPaymAccount.Destroy;
var
  j: integer;
begin
  try
    if Count >0 then
    for j := 0 to Count-1 do
      if assigned( items[j]) then
        TPaymTrans(items[j]).Free;
  finally
    inherited Destroy;
  end;
end;

procedure TPaymAccount.SetEndDT(const Value: TDateTime);
begin
  FEndDT := Value;
end;

procedure TPaymAccount.SetInpValue(const Value: Double);
begin
  FInpValue := Value;
end;

procedure TPaymAccount.SetOutValue(const Value: Double);
begin
  FOutValue := Value;
end;

procedure TPaymAccount.SetAccountData( const aStartDT,aEndDT: TDateTime;
                         const aInpAmt,aOutAmt,aCredOver,aDebtOver: string);
begin
  SetPeriod( aStartDT, aEndDT);
  InpValue := Str2Float(aInpAmt);
  OutValue := Str2Float(aOutAmt);
  CredOver := Str2Float(aCredOver);
  DebtOver := Str2Float(aDebtOver);
end;

procedure TPaymAccount.SetStartDate(const Value: TDateTime);
begin
  FStartDT := Value;
end;

function TPaymAccount.StoreAccountHeaderAs1CText( FS: TStreamStorage;
                            const IsHeaderOnly:bool=FALSE): integer;
var j,i,lCount: integer;
  sParam,sValue,tOwnerSrcName: String;
begin
  result := 0;
  if assigned(Owner) then
    tOwnerSrcName := Owner.SrcName
  else SetLength(tOwnerSrcName,0);
  lCount := StrAsListLineCount( AccountParams);

  if assigned(FS) and (lCount >1) then
  try
    FS.WriteText( GetStringListValueIdx( AccountParams,0), #0); //'СекцияРасчСчет'
    for i := 1 to lCount -2 do
    begin
      sParam := GetStringListValueIdx( AccountParams,i);
      SetLength(sValue,0);
      case i of
        1: sValue := Date2Str(StartDt);
        2: sValue := Date2Str(EndDt);
        3: sValue := spAccount;
        4: if (CurrCh<>'RUB') or (CurrCh<>'RUR') then
              sValue := CurrCh;
        5: if CurrCode >0 then
              sValue := format('%3.3d',[CurrCode]);
        6: sValue := format('%.2f',[InpValue]); // 'НачальныйОстаток'
        7: sValue := format('%.2f',[nvl2n(CredOverChk,CredOver)]); // 'ВсегоПоступило'
        8: sValue := format('%.2f',[nvl2n(DebtOverChk,DebtOver)]); // 'ВсегоСписано'
        9: sValue := format('%.2f',[OutValue]); // 'КонечныйОстаток'
      end;//case
      if Length(sValue) >0 then
        FS.WriteText(sParam,sValue);
    end;
    FS.WriteText(GetStringListValueIdx( AccountParams,10),#0);    //'КонецРасчСчет'

    if not IsHeaderOnly then
    for j := 0 to Count -1 do
      inc(result, TPaymTrans(Items[j]).StoreAs1CText(FS));
  except
    addToLog(format('%s: ' + sErrDueSaving + 'счета "%s"',[tOwnerSrcName,spAccount]));
  end;
end;

procedure TPaymAccount.SetPeriod(const aStartDT, aEndDt: TDateTime);
begin
  StartDT := aStartDT;
  EndDt   := aEndDt;
end;

procedure TPaymAccount.SetCredOver(const Value: Double);
begin
  FCredOver := Value;
end;

procedure TPaymAccount.SetDebtOver(const Value: Double);
begin
  FDebtOver := Value;
end;


procedure TPaymAccount.AddToLog(const aMsg: string; const lstLog: TStrings;
  const iLevel: Word);
begin
  if assigned( FLogFn) then
    FLogFn(aMsg, lstLog, iLevel);
end;

procedure TPaymAccount.SetLogFunc(aLogFn: TRemoteLogProc);
begin
  if assigned(aLogFn) then
    FLogFn := aLogFn;
end;

procedure TPaymAccount.AddCredOverChk(const Value: Double);
begin
  FCredOverChk := FCredOverChk + Value;
end;

procedure TPaymAccount.AddDebtOverChk(const Value: Double);
begin
  FDebtOverChk := FDebtOverChk + Value;
end;

procedure TPaymAccount.SetCurrency(const sCurr: String;
  const iCurr: integer);
begin
  if Length(sCurr) >0 then
    CurrCh := sCurr
  else begin
    if iCurr >0 then
      CurrCode := iCurr
    else
    if Length(spAccount) >=20 then // russian accounting number format
      CurrCode := StrToInt(Copy(spAccount, 6,3));
  end;
end;

procedure TPaymAccount.SetAccountID(const aAccntID,aCurrID: Integer;
  const aViewName: string);
begin
  FAccountID := aAccntID;
  FCurrID    := aCurrID;
  FViewName  := aViewName;
  if (aCurrID >0) and (Length(FCurrCh) =0) and (Length(aViewName) >3) then
    FCurrCh := Copy(aViewName, Length(aViewName)-2,3);
end;


function TPaymAccount.IsEmpty: bool;
begin
  result := Count =0;
end;


function TPaymAccount.Validate;
begin
  result := -2;
  if IsEmpty or (not assigned(FMDPort)) then exit;
  result := TpaymMD(FMDPort).Validate(aSortStr, iDataCheck);
end;

function TPaymAccount.MDStatus(out fSourced, fChecked: Double): integer;
begin
  fSourced := 0;
  fChecked := 0;
  if assigned(MDPort) then begin
    result := TPaymMD(MDPort).TStatus;
    fSourced := TPaymMD(MDPort).OutValue;
    fChecked := TPaymMD(MDPort).ChkValue;
   end
  else result := 0;
end;


function TPaymAccount.AddPayment(const lstSection: TStringList): integer;
var
  newTrans: TPaymTrans;
  tresult: Integer;
begin
  result := 0;
  try
    newTrans := TPaymTrans.CreateFromStr(Self, lstSection,'','');
    if assigned(newTrans) then begin
      tresult := AddTransaction(newTrans);
      if tresult =0 then
        result := Count
      else Result := tresult;
    end;
  except
    result := -1;
  end;
end;


function TPaymAccount.ConvertToMemData;
var
  PLines: TStrings;
begin
  result := -2;
  if assigned( mdTemplate) then
  try
    if assigned(Owner) then
      PLines := Owner.FLogList
    else PLines := nil;
    FMDPort := TPaymMD.Create(Self,mdTemplate as TDataSet,FLogFn,PLines,iLevel);
    if assigned(FMDPort) then
      result  := TpaymMD(FMDPort).LoadAccount( Self);
  except
    FreeAndNil(FMDPort);
    result  := -1;
  end;
end;


function TPaymAccount.GetReportName: String;
begin
  result := format('%s/%s:%s',[OwnerName,spAccount,
                   nvlstr(CurrCh, format('%3.3d', [FCurrCode]))]);
end;


procedure TPaymAccount.DataLogString(const s: String; const iLevel: Word;
  const sLogFName: string);
//var
//  idx: integer;
begin
{ if (not assigned(FDataLog)) or (length(trim(s)) =0) then exit;
  if (length(sLogFName) =0) then exit;

  idx := FDataLog.addLogFile( ansiUpperCase(sLogFName), iLevel);
  iLevel := Word(FDataLog.Objects[ idx]);

  if FappLogLevel >=iLevel then
    sys_uLog.WriteLog( FDataLog[idx], s);}
end;


procedure TPaymAccount.SetOwnerStatement(aOwner: TCustStatement);
begin
  if assigned(aOwner) then begin
    FOwner := aOwner;
//  SetLogFunc(FOwner.LogFn);
    if (abs(StartDT) <0.1) and (Abs(FOwner.StartDate) >0.1) then
      SetPeriod(FOwner.StartDate,FOwner.EndDate);
  end;
end;

function TPaymAccount.IsProperPayment(const aList: TStringList;
                       var aDC,aSubsider: String): longint;
var
  saDebt,saCred, sNewName,tmpName,sCodeStr: String;
begin
  result := -2;
  SetLength(aDC,0); SetLength(aSubsider,0);
  if assigned(aList) and (aList.Count >0) then
  try
    saDebt := GetParamListValue(aList, ['ПлательщикСчет=','ПлательщикРасчСчет=']);
    saCred := GetParamListValue(aList, ['ПолучательСчет=','ПолучательРасчСчет=']);
    sNewName := OwnerName;
    if saDebt = spAccount then begin
      aDC :='D';
      aSubsider := saCred;
      tmpName := GetParamListValue(aList, ['Плательщик1=','Плательщик=']);
      if SetNormalCompanyName(sNewName,tmpName,['']) >=0 then
      begin
        OwnerName := sNewName;
        OwnBank   := GetParamListValue(aList, ['ПлательщикБанк1=']);
        OwnBankCode := GetParamListValue(aList, ['ПлательщикБИК=']);
      end;
     end
    else
    if saCred = spAccount then begin
      aDC :='C';
      aSubsider := saDebt;
      tmpName := GetParamListValue(aList, ['Получатель1=','Получатель=']);
      if SetNormalCompanyName(sNewName,tmpName, ['']) >=0 then
      begin
        OwnerName := sNewName;
        OwnBank   := GetParamListValue(aList, ['ПолучательБанк1=']);
        OwnBankCode := GetParamListValue(aList, ['ПолучательБИК=']);
      end;
    end;
    OwnerName := MatchTaxCodeName(tmpName,sCodeStr);
    if Length(TaxCode) =0 then TaxCode := sCodeStr;
    result := longint( not(Length(aDC) >0));
  except
    result := -1;
  end;
end;


function TPaymAccount.AddTransaction(aTrans: TPaymTrans): integer;
var
  tresult: integer;
begin
  result := -2;
  if assigned(aTrans) then
  try
    tresult := Count;
    case aTrans.FDCFlag[1] of
     'C': AddCredOverChk(aTrans.PaymValue);
     'D': AddDebtOverChk(aTrans.PaymValue);
    else
      exit;
    end;
    Add(aTrans);
    if Count >tresult then
      result := 0;
  except
    result := -1;
  end;
end;

{ TCustStatement }


constructor TCustStatement.Create(aFName: String; const aAgentID: integer;
       aLogFn: TRemoteLogProc =nil; aLogList: TStrings =nil);
begin
  inherited Create;
  FSrcName := aFName;
  FAgentID := aAgentID;
  if Length(aFname) >0 then
    FDumpName := ChangeFileExt(aFName, format('.%d',[agentID]));
  SetLogFunc(aLogFn, aLogList);
end;

procedure TCustStatement.LoadFromText(//FS: TStreamStorage;
  aList: TStringList);
var
  sMsg,sStatmHeadValues: String;
begin
  sStatmHeadValues := TestValidRawMatch(aList, sMsg); // 1CStatement Header
  SetHeaderValues(sStatmHeadValues);

end;


constructor TCustStatement.CreateAtList(aList: TStringList;
                 const iAgentID: integer; sHeadValues: String;
                 const aLogFn: pointer=nil; const aLogList: TStrings =nil);
var
  aSection: TStringList;
  OkProcFlag: bool;
begin
  try
    aSection := TStringList.Create;
    OkProcFlag := TRUE;
    Create('', iAgentID, aLogFn,aLogList);
    try
      SetHeaderValues(sHeadValues);
      while (aList.Count >0) and OkProcFlag do
      begin
        if GetStringsSection(aList, 'СекцияРасчСчет','КонецРасчСчет',aSection,$01) >0 then
          OkProcFlag := AddNewAccount(aSection) >0
        else
        if GetStringsSection(aList, 'СекцияДокумент','КонецДокумента',aSection,$01) >0 then
          OkProcFlag := AddNewPayment(aSection) >0
        else begin
          if Length( Trim(aList[0])) >0 then
            AddToLog(format('неопознана секция/строка: %s', [aList[0]]));
          OkProcFlag := FALSE;
          aList.Delete(0);
        end;
      end;
    except
      raise;
    end;
  finally
    aSection.Free;
    if not OkProcFlag then begin
      Free;
      Fail;
    end;
  end;
end;

destructor TCustStatement.Destroy;
var
  j: integer;
begin
  try
    if Count >0 then
    for j := 0 to Count -1 do
      if assigned( Items[j]) then
        TpaymAccount(Items[j]).Free;
  finally
    inherited Destroy;
  end;
end;

procedure TCustStatement.SetAccntTypeChar(const Value: string);
begin
  FAccntTypeChar := Value;
end;

procedure TCustStatement.SetAccountStr(const Value: string);
begin
  FOwnerAccount := Value;
end;

procedure TCustStatement.SetBankAddr(const Value: AnsiString);
begin
  FBankAddr := Value;
end;

procedure TCustStatement.SetBankName(const Value: AnsiString);
begin
  FBankName := Value;
end;

procedure TCustStatement.SetEndDate(const Value: TDateTime);
begin
  FEndDT   := Value;
end;

procedure TCustStatement.SetIBAN(const Value: string);
begin
  FIBAN := Value;
end;

procedure TCustStatement.SetOwnerAddress(const Value: AnsiString);
begin
  FOwnerAddr := Value;
end;

procedure TCustStatement.SetOwnerName(const Value: AnsiString);
begin
  FOwnerName := Value;
end;

procedure TCustStatement.SetPeriod(const aStartDT, aEndDt: TDateTime);
begin
  StartDate := aStartDt;
  EndDate   := aEndDt;
end;

procedure TCustStatement.SetStartDate(const Value: TDateTime);
begin
  FStartDT := Value;
end;

function TCustStatement.StoreHeaderAs1CText101(FS: TStreamStorage): longint;
var
  sValue: String;
  slHeader: TStringList;
  i: integer;
begin
  result := 0;
  if Assigned(FS) then
  try
    FS.WriteText(RawFmtFirst, #0);
    slHeader := StrToStringList(HeaderParams);
    for i := 0 to slHeader.Count-1 do
    begin
      case i of
     0,1: begin
            sValue := GetStringListValueIdx(HeaderMasks, i);
            if pos(';',sValue) >0 then
              sValue := copy( sValue,1, Pred(pos(';',sValue)));
          end;
       2: sValue := BankName;
       3: sValue := OwnerName;
       4: sValue := DateToStr(Today);
       5: sValue := TimeToStr(Now);
       6: sValue := StartDateStr;
       7: sValue := EndDateStr;
       8: //if Count =1 then
            sValue := sAccount
          //else sValue := 'Все счета';
      end;
      FS.WriteText( GetStringListValueIdx(HeaderParams,i), sValue);
      inc(result);
    end;
  except
    addToLog(format('%s: '+ sErrDueSaving +'заголовка',[SrcName]));
    result := -1;
  end;
end;

{function TCustStatement.LoadHeaderAs1CText101(FS: TStreamStorage): longint;
//var
//  vParam,vStr: string;
begin
  if assigned(FS) then
  try
    vStr := FS.ReadText(vParam);
    showMessage( format('%s =%s',[vParam,vStr]));
    vStr := FS.ReadText('ВерсияФормата'); //'1.01'
    FS.ReadText('Кодировка', 'Windows');
    FS.ReadText('Отправитель','Клиент');
    FS.ReadText('Получатель','1С:Предприятие');
    FS.ReadText('ДатаСоздания', DateToStr(Today));
    FS.ReadText('ВремяСоздания',TimeToStr(Now));
    FS.ReadText('ДатаНачала', Date2Str(StartDate));
    FS.ReadText('ДатаКонца', Date2Str(EndDate));
    FS.ReadText('РасчСчет', 'Все счета');
  finally
  end;
end;}

function  TCustStatement.StoreItemsAs1CText101(FS: TStreamStorage): longint;
var j: integer;
begin
  result := 0;
  if Count >0 then
  try
    for j := 0 to Count-1 do
    if assigned( Items[j]) then
      inc( result, TPaymAccount( Items[j]).StoreAccountHeaderAs1CText(FS));
  except
    result := -1;
//  addToLog(format(sErrDueSaving + 'документов',[SrcName]));
  end;
end;

procedure TCustStatement.StoreAs1CTextEnd(FS: TStreamStorage);
begin
  if assigned(FS) then
    FS.WriteText(RawFmtLast,#0);
end;

function TCustStatement.StoreAs1CText(Fs: TStreamStorage): longint;
begin
  result := StoreHeaderAs1CText101(FS);
  if result >0 then begin
    result := StoreItemsAs1CText101(Fs);
    FS.WriteText(RawFmtLast,#0);
  end;
end;


procedure TCustStatement.SetHeaderValues(const aValues: String);
begin
  if Length(aValues) =0 then exit;

  BankName  := GetStringListValueIdx(aValues,2);           // Отправитель=
  if pos('||',BankName) >0 then begin
    BankAddr := GetStrParamValue( BankName,'||',$04);
    bankName := GetStrKeyName( BankName,'||',$04);
  end;
  OwnerName := GetStringListValueIdx(aValues,3);           // Получатель=

  StartDate := Str2Date(GetStringListValueIdx(aValues,6)); // ДатаНачала
  EndDate   := Str2Date(GetStringListValueIdx(aValues,7)); // ДатаКонца
  sAccount  := GetStringListValueIdx(aValues,8);           // РасчСчет
end;


function  TCustStatement.AddNewAccount;
var
  newAccount: TPaymAccount;
  sAccntStr: String;
begin
  result := -2;
  if assigned(aList) and (aList.Count >minListStrCount) then
  try
    sAccntStr := GetParamListValueId( aList.Text, AccountParams,3); //['РасчСчет=']
    if Length(sAccntStr) =0 then
      AddToLog(format(sErrAccNotFound, [aList.Text]))
    else begin
      newAccount := TPaymAccount.CreateAtList( aList, sAccntStr,OwnerName,BankName);
      if assigned(newAccount) then
      begin
        if Length( nvlstr(newAccount.CurrCh, format('%3.3d',[newAccount.CurrCode]))) =0 then
          addToLog( sAccntStr+': не определена валюта счета')
        else begin
          newAccount.SetOwnerStatement(Self);
          Add(newAccount);
          result := Count;
        end;
       end
      else
        AddToLog(format(sErrAccntHeader, [aList.Text]));
    end;
    aList.Clear;
  except
    result := -1;
  end;
end;


function TCustStatement.AddNewPayment(aList: TStringList): integer;
var
  j: integer;
  newTrans: TPaymTrans;
  iAccount: TPaymAccount;
  sDC,sNewName,sSubsider: String;
begin
  result := -2;
  if Count >0 then
  for j := 0 to Count -1 do
  if assigned(Items[j]) then
   try
     iAccount := TPaymAccount(Items[j]);
     if iAccount.IsProperPayment(aList,sDC,sSubsider) =0 then
     begin
       sNewName := OwnerName;
       if SetNormalCompanyName(sNewName, iAccount.OwnerName,['']) >=0 then
         OwnerName := sNewName;
       newTrans := TPaymTrans.CreateFromStr(iAccount,aList,sDC,sSubsider);
       if assigned(newTrans) then begin
         iAccount.Add(NewTrans);
         result := iAccount.Count;
        end
       else begin
         addToLog( format(sErrCreatePaymt+^M'"%s"',[aList.Text]));
         result := -1;
       end;
       aList.Clear;
       break;
     end;
   except
     result := -1;
   end;
end;

procedure TCustStatement.AddToLog(const aMsg: string; const lstLog: TStrings;
  const iLevel: Word);
begin
  if assigned(FLogFn) then
    FLogFn(aMsg, lstLog, iLevel);
end;

procedure TCustStatement.SetLogFunc;
begin
  if assigned(aLogFn) then
    FLogFn := aLogFn;
  FLogList := aLogList;
end;

function TCustStatement.GetAccountsIDLst: string;
var
  i: integer;
begin
  result := '';
  if Count >0 then begin
    for i := 0 to Count -1 do
    if assigned(Items[i]) {and (TBankAccnt(Items[i]).FStatus >0)} then
      result := result + IntToStr( TPaymAccount( Items[i]).AccountID) + ',';

    result := Copy(result, 1, Length(result)-1);
  end;
end;


function TCustStatement.GetSrcName: string;
begin
  result := nvlstr(FSrcName, FDumpName);
end;


function TCustStatement.GetStartDateStr: String;
begin
  result := Date2Str(StartDate);
end;

function TCustStatement.GetEndDateStr: String;
begin
  result := Date2Str(EndDate);
end;

{ TPaymTrans }
constructor TPaymTrans.Create(const aData: string ='');
begin
  inherited Create;
end;

constructor TPaymTrans.CreateFromStr(vOwnAccnt: TObject;
                    aData: TStringList; aDC,aSubsider: String);
var
  sDate,sDocDate,sName,bnkName,bnkCode: String;
begin
  if not assigned(vOwnAccnt) then Fail
  else
  if ((Length(aDC) =0) or (Length(aSubsider) =0)) and
     (TPaymAccount(vOwnAccnt).IsProperPayment(aData,aDC,aSubsider) <0) then Fail
  else begin
    sDocDate := GetParamListValueStr(aData.Text, ['Дата=']);
    if Str2Date(sDocDate) =0 then
      Fail
    else
    try
      inherited Create;
      DCFlag := aDC;
      case aDC[1] of
       'D': sName := GetParamListValueStr(aData.Text, ['Получатель1=','Получатель=']);
       'C': sName := GetParamListValueStr(aData.Text, ['Плательщик1=','Плательщик=']);
      end;
      sDate  := GetParamListValueStr(aData.Text,
                           [ nvl2s(aDC='C','ДатаПоступило=','ДатаСписано=')]);
      sDate  := nvlstr(sDate,sDocDate);
      bnkName := GetParamListValueStr(aData.Text,
                          [nvl2s(aDC='C','ПлательщикБанк1','ПолучательБанк1=')]);
      bnkCode := GetParamListValueStr(aData.Text,
                          [nvl2s(aDC='C','ПлательщикБИК=','ПолучательБИК=')]);
      PaymDocNo := GetParamListValueStr(aData.Text, ['Номер=']);
      PaymValStr:= GetParamListValueStr(aData.Text, ['Сумма=']);
      PaymInfo  := GetParamListValueStr(aData.Text, ['НазначениеПлатежа=']);
      SetPaymAttributes(vOwnAccnt, Str2Date(sDocDate), Str2Date(sDate),
                          sName, aSubsider, bnkName, bnkCode);
    except
      TPaymAccount(vOwnAccnt).AddToLog(format(sErrTransaction,
        [ GetParamListValueStr(aData.Text,['Номер=']), aData.Text]));
    end;
  end;
end;

function TPaymTrans.GetCredDateStr: String;
begin
  result := Date2Str(FCredDate)
end;

function TPaymTrans.GetDebtDateStr: String;
begin
  result := Date2Str(FDebtDate);
end;

function TPaymTrans.GetDocDateAsString: AnsiString;
begin
  result := Date2Str(FDocDate);
end;

function TPaymTrans.GetPaymValue: AnsiString;
begin
  result := FloatToStrF(FPaymValue,ffFixed,15,2);
end;

procedure TPaymTrans.SetCredDate(const Value: TDateTime);
begin
  FCredDate := Value;
end;

procedure TPaymTrans.SetCredDateStr(const Value: String);
begin
  if Length(Value) =10 then
  try
    FCredDate := GetTransDateAsString(Value);
  except FCredDate := 0
  end;
end;

procedure TPaymTrans.SetDebtDate(const Value: TDateTime);
begin
  FDebtDate := Value;
end;

procedure TPaymTrans.SetDebtDateStr(const Value: String);
begin
  try
    FDebtDate := GetTransDateAsString(Value);
    FCredDate := FDebtDate;
  except end;
end;

procedure TPaymTrans.SetPaymAttributes(const aAccnt: TObject;
                     const aDocDate,aPmtDate: TDateTime;
                     const sName, sAccnt, bnkName, bnkCode: string);
begin
  if not assigned(aAccnt) then exit;

  with aAccnt as TPaymAccount do begin
   DocDate := aDocDate;
   case DCFlag[1] of
    'C':  // приход :)
     begin
       CredDate      := aPmtDate;
       DebtName      := sName;
       DebtName1     := sName;
       DebtName2     := sAccnt;
       DebtCurrAccnt := sAccnt;
       DebtAccnt     := sAccnt;
       DebtBankName1 := BnkName;
       DebtBankCode  := BnkCode;
       SetAttributesCred(aAccnt);
{     CredName      := OwnerName;
      CredName1     := OwnerName;
      CredName2     := spAccount;
      CredAccnt     := spAccount;
      CredCurrAcnt  := spAccount;
      CredBankName1 := OwnBank;
      CredBankCode  := OwnBankCode;}
     end;
    'D': // расход :(
     begin
       DebtDate      := aPmtDate;
       CredName      := sName;
       CredName1     := sName;
       CredName2     := sAccnt;
       CredCurrAcnt  := sAccnt;
       CredAccnt     := sAccnt;
       CredBankName1 := BnkName;
       CredBankCode  := BnkCode;
       SetAttributesDebt(aAccnt);
{     DebtName      := OwnerName;
      DebtName1     := OwnerName;
      DebtName2     := spAccount;
      DebtAccnt     := spAccount;
      DebtCurrAccnt := spAccount;
      DebtBankName1 := OwnBank;
      DebtBankCode  := OwnBankCode;}
     end;
   end;
  end;
end;

procedure TPaymTrans.SetAttributesCred(const aAccnt: TObject);
begin
  if assigned(aAccnt) then
  with aAccnt as TPaymAccount do begin
    CredName  := OwnerName;
    CredName1 := OwnerName;
    CredName2    := spAccount;
    CredAccnt    := spAccount;
    CredCurrAcnt := spAccount;

    CredBankName1 := OwnBank;
    CredBankCode  := OwnBankCode;
  end;
end;

procedure TPaymTrans.SetAttributesDebt(const aAccnt: TObject);
begin
  if assigned(aAccnt) then
  with aAccnt as TPaymAccount do begin
    DebtName  := OwnerName;
    DebtName1 := OwnerName;
    DebtName2     := spAccount;
    DebtAccnt     := spAccount;
    DebtCurrAccnt := spAccount;

    DebtBankName1 := OwnBank;
    DebtBankCode  := OwnBankCode;
  end;
end;

procedure TPaymTrans.SetDocDateAsString(const Value: AnsiString);
begin
  FDocDate := GetTransDateAsString(Value);
end;

procedure TPaymTrans.SetPaymValue(const Value: AnsiString);
begin
  FPaymValue := Str2Float(Value);
end;

function TPaymTrans.GetTransDateAsString(const aValue: AnsiString): TDateTime;
begin
  result := Str2Date(aValue);
end;

function TPaymTrans.StoreAs1CText(FS: TStreamStorage): integer;
var
  lCount,i: integer;
  sParam,sValue: String;
begin
  result := 0;
  lCount := StrAsListLineCount( DocParams);
  if assigned(FS) and (lCount >1) then
  try
    for i:= 0 to lCount -1 do begin
      sParam := GetStringListValueIdx( DocParams,i);
      SetLength(sValue,0);
      case i of
        0: sValue := #0; // 'СекцияДокумент',#0);
        1: sValue := PaymDocNo;
        2: sValue := DocDateStr;
        3: sValue := PaymValStr;
        4: if DCFlag[1] ='C' then sValue := CredDateStr;
        5: if DCFlag[1] ='D' then sValue := DebtDateStr;
        6: sValue := DebtAccnt; // 'ПлательщикСчет='^M+
        7: sValue := DebtName;  //'Плательщик='^M+               //  5
        8: sValue := DebtCode;  //  'ПлательщикИНН='^M+            //
        9: sValue := DebtName1; //'Плательщик1='^M+              //
       10: sValue := nvlstr(DebtName2, ' '); //'Плательщик2='^M+              //
       11: sValue := DebtCurrAccnt;  //'ПлательщикРасчСчет='^M+       //
       12: sValue := nvlstr(DebtBankName1,' '); // 'ПлательщикБанк1='^M+          //  9
       13: sValue := nvlstr(DebtBankCode, ' '); // 'ПлательщикБИК='^M+            //
       14: sValue := DebtCorrAccnt; //   'ПлательщикКорсчет='^M+        //
       15: sValue := CredAccnt;     //   'ПолучательСчет='^M+           // 15
       16: sValue := CredName;      //   'Получатель='^M+               //
       17: sValue := CredCode;      //   'ПолучательИНН='^M+            //
       18: sValue := CredName1;     //'Получатель1='^M+              //
       19: sValue := nvlstr(CredName2,' ');     //'Получатель2='^M+              // 19
       20: sValue := CredCurrAcnt;      //'ПолучательРасчСчет='^M+       // 20
       21: sValue := nvlstr(CredBankName1,' '); //'ПолучательБанк1='^M+          //
       22: sValue := nvlstr(CredBankCode, ' '); //'ПолучательБИК='^M+            //
       23: sValue := CredCorrAcnt;      //'ПолучательКорсчет='^M+        //
       24: sValue := ' ';               //'ВидПлатежа='^M+               // 24
       25: sValue := '2';               //'ВидОплаты='^M+                // 25
       26: sValue := ' ';               //'Очередность='^M+              //
       27: sValue := PaymInfo;          //'НазначениеПлатежа='^M+        //
       28: sValue := nvlstr(DebtCode2,' ');  //'ПлательщикКПП='^M+            //
       29: sValue := nvlstr(CredCode2,' ');  //'ПолучательКПП='^M+            // 29
       30: sValue := #0; //'КонецДокумента',#0);
      end;
      if Length(sValue) >0 then
        FS.WriteText(sParam, sValue);
    end;
    result := 1;
  except
    result := -1;
  end;
end;

function TPaymTrans.GetPaymDate: TDateTime;
begin
  if DCFlag[1] = 'C' then
    result := CredDate
  else
  if DCFlag[1] = 'D' then
    result := DebtDate
  else
    result := 0;
end;


{ TPeriod }

constructor TPeriod.Create(const aStart, aEnd: TDateTime);
begin
  inherited Create;
  StartDT := aStart;
  EndDT   := aEnd;
end;


end.

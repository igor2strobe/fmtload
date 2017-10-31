create or replace package PKG_FMTLOAD is

  -- Author  : D7DEV
  -- Created : 24.09.2013 13:30:53
  -- Purpose : FMTLOAD oracle interface
  
  -- Public type declarations
-- type <TypeName> is <Datatype>;
  
  -- Public constant declarations
-- <ConstantName> constant <Datatype> := <Value>;

  -- Public variable declarations
-- <VariableName> <Datatype>;

  -- Public function and procedure declarations
-- function IsBankAccntValid(<Parameter> <Datatype>) return <Datatype>;

--function  StrToNumberSafe( sValue in varchar2, fmtString in CHAR) return number;
function GrepStrPos(sInp in out varchar2, sSep varchar2, iParam integer default 0) return varchar2;
  
function  GetCurrencyChar( idCurr integer) return varchar2;

function GetAccountID(iAgentId integer, iCurrId integer, sAccount varchar2) return number;

function AddNewAccount( iAgentID in number, iCurrId in number, sAccount in varchar2,
      sViewName in varchar2, iOptions in Integer default 0) return integer;

function GetNewAccountId( iAgentId in number, iCurrId in number, sAccount in varchar2,
   sViewName in varchar2, iOptions in Integer default 0) return integer;

FUNCTION GetCurrIDbyChar( sCurr$ varchar2) return number;
     
procedure GetBankAccntId(iAgentID$     IN       NUMBER,
                         sCurr$        IN       VARCHAR2,
                         sAccnt$       IN       VARCHAR2,
                         sOwnerName$   IN       VARCHAR2,
                         iProcPrm      in       Integer,
                         iAcntId$      OUT      NUMBER,
                         iCurrId$      OUT      NUMBER,
                         shortName$    OUT      VARCHAR2,
                         iFlag$        OUT      NUMBER);
   

procedure DeleteAccounts4Period( sAccntStr$ in varchar2, 
                            StartDt in Date, EndDt in Date,
                            iDeleted out integer,
                            iOptions in integer default 0);

 procedure AddAccount(iAccnt Integer, sCurr varchar2,
                      DocDT Date, PayDT Date,
                       sDoc VARCHAR2, sInfo VARCHAR2,
                       vDebt Number, vCred Number,
                       sDebtName VARCHAR2, sDebtAcnt VARCHAR2, sDebtCode VARCHAR2,
                       sDebtBName VARCHAR2, sDebtBCode VARCHAR2, sDebtBAcnt VARCHAR2,
                       sCredName VARCHAR2, sCredAcnt VARCHAR2, sCredCode VARCHAR2,
                       sCredBName VARCHAR2, sCredBCode VARCHAR2, sCredBAcnt VARCHAR2,
                       vINPUT Number, vOUT Number, DC_Flag varCHAR2, iOpFlag out integer);

procedure UpdPaymAgent(iAgent integer, aAgentName varchar2, aLibName varchar2,
  aDataPath varchar2, aDrvName varchar2, isHide integer, iRes out integer);
                       
/* FUNCTION GetVBBalanceInUSD(OnDate Date Default SysDate) return NUMBER;
 FUNCTION GetUnChainedInUSD(StartDate Date, OnDate Date DEFAULT SysDate) RETURN NUMBER;
 FUNCTION GetExtBalanceInUSD RETURN NUMBER;
 FUNCTION GetCliBalanceInUsd RETURN NUMBER;*/
 
 FUNCTION GetBalanceDeltaInUsd(StartDate Date, OnDate Date, fAddVal number default 0) RETURN NUMBER;
   
 procedure UpdateDeltaLog( StartDate DATE, OnDate Date, sParam VarCHAR2, 
                           vAddVal number Default 0, iForced integer);

 procedure ResetAccount(iAccnt integer, StartDate Date, onDate Date Default SysDate, 
                        sParam varchar2, vAdd number, iForced integer);

PROCEDURE After_Logon( Module_Name$ IN VARCHAR2, UsrOwner Varchar2, moduleID IN VARCHAR2);

end PKG_FMTLOAD;
/
create or replace package body PKG_FMTLOAD is

  -- Private type declarations
-- type <TypeName> is <Datatype>;
  
 -- Private constant declarations
-- <ConstantName> constant <Datatype> := <Value>;

 -- Private variable declarations
--  <VariableName> <Datatype>;

  -- Function and procedure implementations
/*function <FunctionName>(<Parameter> <Datatype>) return <Datatype> is
    <LocalVariable> <Datatype>;
  begin
    <Statement>;
    return(<Result>);
  end;*/
  

 -- 
function StrToNumberSafe( sValue in varchar2, fmtString in CHAR) return number 
is
begin
  return To_NUMBER(sValue, fmtString);   
  exception
    WHEN OTHERS THEN
      return 0;   
end StrToNumberSafe;

function GrepStrPos(sInp in out varchar2, sSep varchar2, iParam integer default 0) return varchar2 is
  s varchar2(1024);
  k integer := 0;
begin
  if (sInp is null) or (Length(sInp) =0) then
    return '';
  else
    s := sInp;  
  end if;  
  
  k := InStr(s, sSep);
  if k >0 then          
    sInp := substr(s, k+1, Length(s));
    return substr(s, 1, k-1);          
  else 
    sInp := '';
    return s;
  end if;
end;
 
function GetAccountID(iAgentId integer, iCurrId integer, sAccount varchar2) return number is
 id number;
begin
  SELECT nvl(uin_corr_acnt,0) INTO id
    FROM fin$corr_pay_acnt 
   WHERE id_currency =iCurrId AND ACCOUNT =sAccount AND uin_corr =iAgentId;
   
   return ID;
  exception    
    when NO_DATA_FOUND then 
      return -1;
end GetAccountID;


 --
function AddNewAccount( iAgentID in number, iCurrId in number, sAccount in varchar2,
      sViewName in varchar2, iOptions in Integer default 0) return integer
is
begin
  INSERT INTO fin$corr_pay_acnt (uin_corr, id_currency, corr_acnt_name, ACCOUNT,
     pred_value_summ,acnt_value_summ, pred_sess_date,curr_sess_date, period_start,period_end)
  VALUES (iAgentID, iCurrID, sViewName, sAccount,
              0.0, 0.0, SYSDATE,SYSDATE,SYSDATE,to_date('31.12.2999','DD.MM.YYYY'));
  if BitAND(iOptions, 2) =2 then
    Commit;
    return 1;
  else 
    return 0;
  end if;   
  exception
    when Others then 
      return -1;
end AddNewAccount; 
 
  
function GetNewAccountId(iAgentId in number,iCurrId in number,sAccount in varchar2, 
              sViewName in varchar2, iOptions in Integer default 0) return integer
is
  iAddFlag integer;
begin
  iAddFlag := AddNewAccount(iAgentId, iCurrId, sAccount, sViewName, iOptions);
  if iAddFlag =1 then
    return GetAccountID(iAgentId,iCurrId,sAccount);
  else
    return 0;  
  end if;
  exception
    when no_data_found then 
      return -1;   
end GetNewAccountId; 
  

--  ??????? ID ?????? ?? ???????? 
-- ???????: 02-03.06.2004, 20.04.2006, 24.09.2013
FUNCTION GetCurrIDbyChar( sCurr$ in varchar2) return number IS
 res number := 0;
BEGIN
  IF (sCurr$ IS NULL) or (Length(sCurr$) =0) 
    then return -2;
  else
    IF StrToNumberSafe( sCurr$, '099') >0 Then
      SELECT id_Currency INTO res 
        FROM FIN$CURRENCY
       WHERE TO_Char(curr_code) =sCurr$;
    else
      SELECT id_Currency INTO res 
        FROM FIN$CURRENCY
       WHERE CURR_SIGN =UPPER(sCurr$)  
          OR (InStr(Alter_Sign, UPPER(sCurr$)) >0);
     end if;        
  END IF;
  RETURN Res;
 EXCEPTION 
   WHEN NO_DATA_FOUND THEN 
     return -1;   
END GetCurrIDbyChar; 


--  ??????? ??????? ?????? ?? ID
function GetCurrencyChar( idCurr in integer) RETURN varchar2 
  IS
  CurrChar varchar2(5) := '';
BEGIN
  IF (idCurr IS not NULL) AND (idCurr >0) then   
    SELECT curr_sign INTO CurrChar 
      fROM FIN$CURRENCY
     WHERE id_currency =idCurr;
  END IF;
  RETURN CurrChar;
 EXCEPTION 
   WHEN NO_DATA_FOUND THEN 
    return '';   
END GetCurrencyChar; 

function UpdateAccntName(iAccID integer, sName varchar2, iParam integer default 0) return integer
  is
begin
  update fin$corr_pay_acnt ac
     set ac.corr_acnt_name =sName
   where ac.uin_corr_acnt = iAccID;
   
  if BitAND(iParam, 2) =2 then
    Commit;
  end if;  
  return 0;
  exception   
   when OTHERS then
     return -7;  
end UpdateAccntName;

function CheckAccountName(iAccID integer, sName varchar2, iParam integer default 0) return integer
is
  sVName varchar2(255);
begin
  select ac.corr_acnt_name into sVName
    from fin$corr_pay_acnt ac
   where ac.uin_corr_acnt = iAccID;
  
  if Trim(lower(sVName)) = trim(lower(sName)) then
    return 0;
  else
    if length(sName) >4 then
      return UpdateAccntName(iAccID,sName,iParam);
    else
      return -6;  
    end if;  
  end if;  
  exception
    when no_data_found then
      return -5;
end CheckAccountName;

--
procedure GetBankAccntID (
   iAgentID$     IN       NUMBER,
   sCurr$        IN       VARCHAR2,
   sAccnt$       IN       VARCHAR2,
   sOwnerName$   IN       VARCHAR2,
   iProcPrm      in       Integer,
   iAcntId$      OUT      NUMBER,
   iCurrId$      OUT      NUMBER,
   shortName$    OUT      VARCHAR2,
   iFlag$        OUT      NUMBER)
IS
/******************************************************************************
   PURPOSE:  ?????????? ID ?????, ???? ?? ??????????, ????? ??????? ????? ? ?????????? ID ??? ??
             ? ???????????? ????? "flag$"=1
   OUT:         acntID$ - ????????????? ????? ?? ??????? fin$CORR_PAY_ACNT
                currID$ - ????????????? ?????? ?? fin$currency
             shortName$ - ???????????? ????? ? ???? "????????-??????"
                 iFlag$ - 0 - ??; 1 -????? ????, -1 ????????????, -2 ??????, -4 ?????? ??????
   INPUT  :   iAgentID$ - ID ?????????? ??????
                CurrCh$ - ??????? ??????
                sAccnt$ - ????? ?????
             ownername$ - ???????????? ????????-????????? 
******************************************************************************/
  iCommitPrm integer := 2;
BEGIN
  iFlag$ := -8;
  if (iAgentID$ is NULL) or (iAgentId$ <=0) or (sAccnt$ is null) then     
    iFlag$ := -3;
    return;
  end if;  
   
  iCurrId$ := GetCurrIDbyChar(sCurr$);
  if iCurrId$ <=0 then
    iFlag$ := -4;
    return;   
  end if;  

  shortName$ := substr(sOwnerName$ ||' '|| GetCurrencyChar(iCurrID$),1,64);
  iCommitPrm := BitAND(iProcPrm,2); 

  iAcntID$ := GetAccountID(iAgentId$, iCurrId$, sAccnt$);
  IF iAcntid$ <0 THEN               
    iAcntID$ := GetNewAccountId(iAgentId$, iCurrId$, sAccnt$, ShortName$,iCommitPrm);
    if iAcntID$ >0 then
      iFlag$ := 1;      
    end if;  
  else 
    if (BitAND(iProcPrm, 16) =16) or (BitAND(iProcPrm, 8) =8) then -- sysdba or admin user mode
      iFlag$ := CheckAccountName(iAcntID$, shortName$,iCommitPrm);
    else
      iFlag$ := 0;  
    end if;
  END IF;
  
 EXCEPTION
   WHEN NO_DATA_FOUND then 
    begin
      iAcntID$ := GetNewAccountId(iAgentId$, iCurrId$, sAccnt$, shortName$,iCommitPrm);
      if iAcntID$ >0 then
        iFlag$ := 1;
      end if;  
    end;  
END GetBankAccntId;  


function GetRowCount4Delete( iAccntID in integer,
                            StartDt in Date, EndDt in Date) return integer
 is
 iRes Integer := 0; 
begin
  SELECT count(*) into iRes
    FROM fin$CORR_PAY_ITEMS t
   WHERE t.UIN_CORR_ACNT =iAccntID
     AND t.CHK_FLAG =0
     AND t.CA_PAY_DATE BETWEEN StartDt AND EndDt;
   Return iRes;
  EXCEPTION
   WHEN NO_DATA_FOUND Then
     return 0;   
end GetRowCount4Delete;


procedure AccountPeriodDeleteEx(iAccntID integer, StartDt in Date, EndDt in Date, iOperFlag Out Integer) Is
begin
  iOperFlag := 0;
 
  DELETE FROM FIN$CORR_PAY_ITEMS
   WHERE UIN_CORR_ACNT =iAccntID
     AND CHK_FLAG =0 AND CA_PAY_DATE BETWEEN StartDt AND EndDt;
     
  UPDATE fin$CORR_PAY_ITEMS 
     SET Valid =0
   WHERE UIN_CORR_ACNT =iAccntID AND CA_PAY_DATE BETWEEN StartDt AND EndDt;
  exception
    when others then
       iOperFlag := -1;   
end;  


procedure DeleteAccounts4Period( sAccntStr$ in varchar2, 
                           StartDt in Date, EndDt in Date,
                           iDeleted Out integer,                           
                           iOptions in integer default 0)
is 
  s varchar2(1024);
  sOneAccnt varchar2(16);
  iForDel  integer := 0;
  iOperFlag integer := 0;
  idAccnt  integer := 0;
begin       
  IF sAccntStr$ is null THEN
    iDeleted := -1;
    return;
  end if;
  
  s := sAccntStr$;
  iDeleted := 0;
  WHILE length(s) >0
  LOOP
    sOneAccnt := GrepStrPos(s, ',');
    idAccnt := strToNumberSafe( sOneAccnt,'99999');   
    iForDel := GetRowCount4Delete(idAccnt, StartDT,EndDt);        
    AccountPeriodDeleteEx(idAccnt, StartDt,EndDt, iOperFlag);
    if iOperFlag =0 then
      iDeleted := iDeleted + iForDel;
    end if;
    EXIT WHEN (Length(sOneAccnt) <=0) or (Length(sOneAccnt) is NULL) or
              (idAccnt =0) or (iOperFlag <0);
  END LOOP;
    
  if (iOperFlag =0) and (BitAND(iOptions,2) =2) then
    COMMIT;
  end if;
end DeleteAccounts4Period;

procedure UpdPaymItemsByID(sCurr varchar2, DocDT Date, sInfo varchar2, 
          sDebtName varchar2, sDebtCode varchar2,
          sDebtBName varchar2, sDebtBCode varchar2, sDebtBAcnt varchar2,
          sCredName varchar2, sCredCode varchar2,
          sCredBName varchar2, sCredBcode varchar2, sCredBAcnt varchar2,
          vINPUT number, vOUT number, CK_Flag number, itemID in number)
  is
begin
  UPDATE FIN$CORR_PAY_ITEMS
     SET CH_CURR=sCurr, CA_DOC_DATE=DocDT, PAY_COMMENT=sInfo,
         DEBET_CLI_NAME=sDebtName,  DEBET_CLI_INN=sDebtCode,
         DEBET_BANK_NAME=sDebtBName, DEBET_BANK_BIC=sDebtBCode, DEBET_BANK_ACNT=sDebtBAcnt,
         CREDIT_CLI_NAME=sCredName, CREDIT_CLI_INN=sCredCode,
         CREDIT_BANK_NAME=sCredBName, CREDIT_BANK_BIC=sCredBcode, CREDIT_BANK_ACNT=sCredBAcnt,
         INPUT_VALUE=vINPUT, OUT_VALUE=vOUT, CHK_FLAG=CK_Flag, VALID=1
    WHERE UIN_CorrAcntItem =itemID;
end;


procedure AddAccount(iAccnt Integer, sCurr varchar2,
                      DocDT Date, PayDT Date,
                      sDoc VARCHAR2, sInfo VARCHAR2,
                      vDebt Number, vCred Number,
                      sDebtName VARCHAR2, sDebtAcnt VARCHAR2, sDebtCode VARCHAR2,
                      sDebtBName VARCHAR2, sDebtBCode VARCHAR2, sDebtBAcnt VARCHAR2,
        sCredName VARCHAR2, sCredAcnt VARCHAR2, sCredCode VARCHAR2,
        sCredBName VARCHAR2, sCredBCode VARCHAR2, sCredBAcnt VARCHAR2,
        vINPUT Number, vOUT Number, DC_Flag VarCHAR2, iOpFlag out integer)
Is
  itemID integer;
  CK_Flag number;
Begin
  iOpFlag := -1;
  
  INSERT INTO FIN$CORR_PAY_ITEMS
 (UIN_CORR_ACNT, CH_CURR, CA_DOC_DATE, CA_DOCUMENT, CA_PAY_DATE,
  CA_SUMM_DEBT, CA_SUMM_CRED,
  PAY_COMMENT, DEBET_CLI_NAME, DEBET_CLI_ACNT, DEBET_CLI_INN,
  DEBET_BANK_NAME, DEBET_BANK_BIC, DEBET_BANK_ACNT,
  CREDIT_CLI_NAME, CREDIT_CLI_ACNT, CREDIT_CLI_INN,
  CREDIT_BANK_NAME, CREDIT_BANK_BIC, CREDIT_BANK_ACNT,
  INPUT_VALUE, OUT_VALUE, CHK_FLAG, DEB_CRED,VALID)
  VALUES (iAccnt, sCurr, DocDT, sDOC, PayDT, vDebt, vCred, sInfo, 
        sDebtNAME, sDebtAcnt, sDebtCode, sDebtBName, sDebtBCode, sDebtBAcnt,
        sCredName, sCredAcnt, sCredCode, sCredBName, sCredBCode, sCredBAcnt,
        vINPUT, vOUT, 0, DC_Flag, 1);
  iOpFlag := 1;      
  exception
    when Others THEN
    begin        
      IF DocDT is Null THEN
      SELECT UIN_CorrAcntItem, CHK_FLAG into itemID, CK_Flag
        FROM fin$CORR_PAY_ITEMS
       WHERE UIN_CORR_ACNT =iAccnt AND CA_DOCUMENT =sDOC
         AND CA_PAY_DATE =PayDT AND CA_DOC_DATE is NULL         
         AND DEBET_CLI_ACNT =nvl(sDebtAcnt,' ') AND CREDIT_CLI_ACNT =nvl(sCredAcnt, ' ')
         AND CA_SUMM_DEBT=vDEBT AND CA_SUMM_CRED=vCRED;
      ELSE   
      SELECT UIN_CorrAcntItem, CHK_FLAG into itemID, CK_Flag
        FROM fin$CORR_PAY_ITEMS
       WHERE UIN_CORR_ACNT =iAccnt AND CA_DOCUMENT =sDOC
         AND CA_PAY_DATE =PayDT AND CA_DOC_DATE =DocDT
         AND DEBET_CLI_ACNT =nvl(sDebtAcnt,' ') AND CREDIT_CLI_ACNT =nvl(sCredAcnt, ' ')
         AND CA_SUMM_DEBT=vDEBT AND CA_SUMM_CRED=vCRED;
      END IF;
      
      if (CK_Flag =-1) or (CK_Flag =-11) then
        CK_Flag :=-2;
      end if;    
    
      UpdPaymItemsByID(sCurr, DocDT, sInfo, sDebtName, sDebtCode,
                       sDebtBName, sDebtBCode, sDebtBAcnt, sCredName, sCredCode,
                       sCredBName, sCredBcode, sCredBAcnt, 
                       vINPUT, vOUT, CK_Flag, itemID);
      iOpFlag := 0;
    end;       
end AddAccount;


procedure AddNewPaymAgent(aAgentName varchar2, aLibName varchar2, aDataPath varChar2, 
  aDrvName varchar2, iRes out integer)
is
begin  
  insert into fin$corr_external(corr_name,odbc_alias,driver_name,
     dll_entry_point,last_sess_date,path_name, agent_flag, timeoutsec)   
  values(aAgentName, aDrvName,aDrvName, aLibName, SysDate, aDataPath, 3,600);
  iRes := 1;
  exception
   WHEN Others THEN
      iRes := -1;
end AddNewPaymAgent;

procedure UpdPaymAgent(iAgent integer, aAgentName varchar2, aLibName varchar2,
  aDataPath varchar2, aDrvName varchar2, isHide integer, iRes out integer)
is
  iFlag integer;
  sDriver varchar2(255);
begin
  sDriver := nvl(aDrvName,' ');
  if iAgent =0 then  
    AddNewPaymAgent(aAgentName,aLibName,aDataPath,sDriver, iRes);
  else 
    BEGIN
     if isHide =0 then -- cbHide.Unchecked
       iFlag := 3;
     else iFlag := 1;  -- cbHide.Checked
     end if; 
        
     UPDATE fin$corr_external t
      SET t.corr_name =aAgentName, t.dll_entry_point =aLibName,
          t.odbc_alias =sDriver, t.driver_name =sDriver,
          t.path_name =aDataPath, t.agent_flag =iFlag
      WHERE t.uin_corr =iAgent;
      iRes := 0;
    exception
      WHEN Others THEN
      AddNewPaymAgent(aAgentName,aLibName,aDataPath,sDriver, iRes);  
    END;  
  end if;  
end UpdPaymAgent;

FUNCTION GetVBBalanceInUSD(OnDate Date Default SysDate) RETURN NUMBER
IS
  AddValue NUMBER := 0.0;    
BEGIN
   FOR tmpvar IN
      (SELECT   a.id_currency,
                TRUNC(Sum(getvbbalance(id_vb_account)/c.rate),2) AS base_usd_val
           FROM fin$vb_accounts a, fin$currency c
          WHERE id_parent = 0
            AND c.id_currency = a.id_currency
            AND id_client IN (SELECT DISTINCT id_client0 FROM fin$offices)
            AND (a.end_date IS NULL OR a.end_date >OnDate)
       GROUP BY a.id_currency)
   LOOP
     EXIT WHEN tmpvar.base_usd_val IS NULL;
     AddValue := AddValue + tmpvar.base_usd_val;
   END LOOP;
   RETURN AddValue;
END GetVBBalanceInUSD; 


FUNCTION GetUnChainedInUSD(StartDate Date, OnDate Date DEFAULT SysDate) RETURN NUMBER 
 IS
  fValue number := 0.0; 
BEGIN
  for tmpVar in (
    SELECT id_currency, Trunc(sum(CA_SUMM_CRED-CA_SUMM_DEBT)/rate,2) as raw_usd_val
      FROM fin$CORR_PAY_ITEMS i, fin$currency c
     WHERE i.chk_flag=0 and i.ch_curr=c.curr_sign
			 AND (ca_pay_date >=StartDate and ca_pay_date <=OnDate)
     GROUP BY id_currency,rate)
   LOOP
	   EXIT WHEN tmpVar.raw_usd_val IS NULL;
	   fValue := fValue + tmpVar.raw_usd_val;
	 END LOOP;
  RETURN FValue;
END;


FUNCTION GetExtBalanceInUSD RETURN NUMBER 
 IS
  fValue number := 0.0; -- ????? ??????????? ???????
BEGIN
  for tmpVar in ( 
    SELECT c.ID_CURRENCY, Trunc(Sum(acnt_value_summ)/rate,2) as ext_usd_val
      FROM fin$corr_pay_acnt a, fin$currency c
     WHERE a.id_currency=c.id_currency
     GROUP BY c.ID_CURRENCY, rate)
  	LOOP
		  EXIT WHEN tmpVar.ext_usd_val IS NULL;
		  fValue := fValue + tmpVar.ext_usd_val;
		END LOOP;
	  RETURN fValue;
END;

FUNCTION GetCliBalanceInUsd RETURN NUMBER 
 IS
  fValue number := 0.0;  
BEGIN
  for tmpVar in (
  SELECT a.ID_CURRENCY, trunc(SUM(GetVBBalance(ID_VB_ACCOUNT))/c.rate,2) as cli_usd_val
       FROM fin$VB_ACCOUNTS a, fin$currency c
      WHERE ID_PARENT=0 AND c.id_currency=a.id_currency
        AND ID_CLIENT not in (SELECT distinct id_client0 FROM fin$offices) 
        AND (end_date is null OR end_date >sysdate)
      GROUP BY a.ID_CURRENCY, rate)
    loop
      EXIT WHEN tmpVar.cli_usd_val IS NULL;
      fValue := fValue + tmpVar.cli_usd_val;
    end loop;
  RETURN fValue;
END;

FUNCTION GetBalanceDeltaInUsd( StartDate Date, OnDate Date, fAddVal number default 0) RETURN NUMBER
 IS
  vExternal number := 0.0; 
  vClients  number := 0.0; -- ??????????? ????? ?? ????????
  vOwned    number;
  UnChained number := 0.0; 
  vbDelta   number := 0.0; -- ????? ?????????? ? ???
BEGIN
  UnChained := GetUnChainedInUSD(StartDate, OnDate);   -- ?????????????? 	
  vExternal := GetExtBalanceInUSD();                   -- ?? ???????
  vClients  := GetCliBalanceInUsd();                   -- ??????????
  vOwned    := GetVBBalanceInUSD(OnDate);              -- ??????????? 
  vbDelta   := vExternal - vOwned - vClients - UnChained;
  RETURN Trunc(vbDelta + fAddVal, 2);                  -- ??????? ?????????? ???????
END;

procedure UpdateDeltaLog( StartDate DATE, OnDate Date, sParam VarCHAR2, 
                          vAddVal number Default 0, iForced integer)
 IS
  IsUpdate boolean;
  v_base   number;
  v_delta  number;
  vOwned   number;
  vbDelta  number;
  UnChained number;
  vExternal number;
  vClients number;
begin
  if iForced=1 then isUpdate := TRUE; end if;
  vOwned    := GetVBBalanceInUSD(OnDate);              -- ???????????
  UnChained := GetUnChainedInUSD(StartDate, OnDate);   -- ?????????????? 	
  vExternal := GetExtBalanceInUSD();                   -- ???????
  vClients  := GetCliBalanceInUsd();                   -- ????? 
  vbDelta   := Trunc(vAddVal + vExternal - vOwned - vClients - UnChained, 2);  
--vbDelta   := GetBalanceDeltaOnUsd(StartDate, OnDate, vAddVal);
  
  SELECT v_base,v_delta INTO v_base,v_delta
    FROM (SELECT fl.v_base,fl.v_delta FROM fin$delta_log fl
           ORDER BY date_stamp DESC)
   WHERE ROWNUM =1;
 exception 
   WHEN NO_DATA_FOUND THEN 
     IsUpdate := TRUE;      
  
  IF IsUpdate OR (abs(vbDelta-v_delta)>=1.0) OR (abs(vOwned-v_base) >=1.0) THEN
     insert into fin$delta_log(v_delta, v_base, params)
          values (vbDelta, vOwned, sParam);
   end if;
end UpdateDeltaLog;


procedure ResetAccount(iAccnt integer, StartDate Date, onDate Date Default SysDate, 
                       sParam varchar2, vAdd number, iForced integer)
  
is
begin
  UPDATE fin$corr_pay_acnt
    set ACNT_VALUE_SUMM =CalcExtAcntBalance(UIN_CORR_ACNT)
  where UIN_CORR_ACNT =iAccnt; 
--  delta_monitor(:fr_upd, :str_prm, :def_date, :default_bal);
  UpdateDeltaLog(StartDate, OnDate, sParam, vAdd, iForced);
end ResetAccount; 


PROCEDURE After_Logon( Module_Name$ IN VARCHAR2, UsrOwner Varchar2, moduleID IN VARCHAR2)
IS
   tmpID NUMBER;
   tmpSerial NUMBER;
   Dead_flag NUMBER := 0;
   cmdName VARCHAR2(255);
/******************************************************************************
   PURPOSE:  ?????????? ??????? ??????????, ????? ?????????? ??????, ?????????? ????????????? ?????? ??? ??
   INPUT  :    module_name$ - ??? ????????????  ??????
                   moduleID$ - ?????? ?????????????? ?????? ??????       
                   
   author :    2006.02.10  AlexMK, 2014.03.24 i.ilmovski@gmail.com
******************************************************************************/
   CURSOR cCheckSessionID IS
   SELECT vs.sid, vs.SERIAL#
     FROM V$SESSION vs
    WHERE vs.MACHINE =(SELECT sys_context('USERENV','HOST') FROM dual)
     AND Upper(vs.MODULE) LIKE Upper(CONCAT(Module_Name$,'%'))
     AND vs.STATUS !='KILLED'
     AND vs.USERNAME = UsrOwner
     AND vs.AUDSID != (SELECT USERENV('SESSIONID') FROM dual);
BEGIN
  EXECUTE IMMEDIATE 'ALTER SESSION SET NLS_SORT=BINARY';
  SYS.DBMS_APPLICATION_INFO.SET_MODULE(Module_Name$, 'Killing prev.SESSION');
    
  OPEN cCheckSessionID;
    FETCH cCheckSessionID INTO tmpID, tmpSerial;
    IF cCheckSessionID%NOTFOUND THEN 
      dead_flag := 0;
    ELSE BEGIN
        cmdName := 'ALTER SYSTEM KILL SESSION ' || TO_CHAR(tmpID) || ',' || TO_CHAR(tmpSerial);        
        EXECUTE IMMEDIATE cmdName;
      END;
    END IF;  
  CLOSE cCheckSessionID;
  
  cmdName := Module_Name$ || ':' || moduleID;    
  SYS.DBMS_APPLICATION_INFO.SET_MODULE (cmdName, 'working'); 
  COMMIT; 
END After_Logon;

--begin
-- Initialization
--  <Statement>;
end PKG_FMTLOAD;
/

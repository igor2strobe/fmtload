CREATE OR REPLACE package body STROBE.PKG_FMTLOAD is

  -- Private type declarations
-- type <TypeName> is <Datatype>;
  
 -- Private constant declarations
-- <ConstantName> constant <Datatype> := <Value>;

 -- Private variable declarations
--  <VariableName> <Datatype>;
-- function  GetCurrChar(idCurr integer) return varchar2;
   
  -- Function and procedure implementations
/*function <FunctionName>(<Parameter> <Datatype>) return <Datatype> is
    <LocalVariable> <Datatype>;
  begin
    <Statement>;
    return(<Result>);
  end;*/
  
 function StrToNumberSafe( sValue in varchar2, fmtString in CHAR) return number is  
 begin
   return To_NUMBER(sValue, fmtString);   
   exception
     WHEN OTHERS THEN
       return 0;   
 end StrToNumberSafe;
  
 procedure AddNewAccnt( iAgentId$ number, iCurrId$ number, 
                        sAccnt$ varchar2, sName$ varchar2) is
 begin
   INSERT INTO fin$corr_pay_acnt (uin_corr, id_currency, corr_acnt_name, ACCOUNT,
                      pred_value_summ, acnt_value_summ, pred_sess_date,
                      curr_sess_date, period_start, period_end )
        VALUES (iAgentid$, iCurrid$, sName$, sAccnt$,
                      0.0, 0.0, SYSDATE, SYSDATE, SYSDATE, '31.12.2069');
 end AddNewAccnt; 
   
 
 function NewAccntId(
   iAgentId$ number, iCurrId$ number, sAccnt$ varchar2, sName$ varchar2) return number is
 begin
   AddNewAccnt(iAgentId$, iCurrId$, sAccnt$, sName$);
   COMMIT;  
   return GetAccntID(iAgentId$, iCurrId$, sAccnt$);
  exception
    when others then return -2;   
 end NewAccntId; 
 
  
--  возврат ID валюты по литералу !! или коду ISO
--  изваяно: 02-03.06.2004, 20.04.2006, 24.09.2013
FUNCTION GetCurrIDbyChar( sCurr$ varchar2) return number IS
  res number;   
BEGIN
  IF (sCurr$ IS NULL) or (sCurr$ ='') 
     Then return -2;
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

--  возврат символа валюты по ID
function GetCurrencyChar( idCurr integer) RETURN varchar2 IS
  CurrChar varchar2(5);
BEGIN
  CurrChar := '';
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

 
function GetAccntID(iAgentId$ number, iCurrId$ number, sAccnt$ varchar2) return number IS
  AcntID$ number;
begin
  SELECT nvl(t.uin_corr_acnt,0) INTO AcntId$
    FROM fin$corr_pay_acnt t
   WHERE t.id_currency = iCurrId$
     AND ACCOUNT = sAccnt$
     AND uin_corr = iAgentId$;
   return acntID$;  
  exception    
   when NO_DATA_FOUND then return -1;
   when OTHERS  then return -2;  
end;

 procedure GetBankAccntID (
   iAgentID$     IN       NUMBER,
   sCurr$        IN       VARCHAR2,     
   sAccnt$       IN       VARCHAR2,
   sOwnerName$   IN       VARCHAR2,
   iAcntId$      OUT      NUMBER,
   iCurrId$      OUT      NUMBER,
   shortName$    OUT      VARCHAR2,
   iFlag$        OUT      NUMBER)
IS
/******************************************************************************
   PURPOSE:  возвращает ID счета, если он существует, иначе создает новые и возвращает ID там же
             с выставлением флага "flag$"=1
   OUT:         acntID$ - идентификатор счета по таблице fin$CORR_PAY_ACNT
                currID$ - идентификатор валюты по fin$currency
             shortName$ - наименование счета в виде "компания-валюта"
                 iFlag$ - 0 - ок; 1 -новый счет, -1 заблокирован, -2 закрыт, -4 кривая валюта
   INPUT  :   iAgentID$ - ID платежного агента
                CurrCh$ - литерал валюты
                sAccnt$ - номер счета
             ownername$ - наименование компании-владельца 
******************************************************************************/

BEGIN
  if (iAgentID$ is NULL) or (iAgentId$ =0) then     
    iFlag$ := -3;
    return;
  end if;  
   
  iCurrId$ := GetCurrIDbyChar(sCurr$);
  if iCurrId$ <=0 then
    iFlag$ := -4;
    return;   
  end if;  
  shortName$ := sOwnerName$ ||' '|| GetCurrencyChar(iCurrID$);
    
  iAcntID$ := GetAccntID(iAgentId$, iCurrId$, sAccnt$);
  IF iAcntid$ <=0 THEN               
    iAcntID$ := NewAccntId(iAgentId$, iCurrId$, sAccnt$, ShortName$);
    if iAcntID$ >0 then
      iFlag$ := 1;
    else
      iFlag$ := -8;
    end if;  
  else
    iFlag$ := 0;         
  END IF;
 EXCEPTION
   WHEN NO_DATA_FOUND then 
    begin
      iAcntID$ := NewAccntId(iAgentId$, iCurrId$, sAccnt$, shortName$);
      if iAcntID$ >0 then
        iFlag$ := 1;
      else
        iFlag$ := -8;
      end if;  
    end;  
END GetBankAccntId;  

--begin
-- Initialization
--  <Statement>;
end PKG_FMTLOAD;
/

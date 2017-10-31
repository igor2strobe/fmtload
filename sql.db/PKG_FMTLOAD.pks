CREATE OR REPLACE package STROBE.PKG_FMTLOAD is

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

 function  StrToNumberSafe( sValue in varchar2, fmtString in CHAR) return number;
 function  GetCurrencyChar(idCurr integer) return varchar2;
 
 function  GetCurrIDbyChar(sCurr$ varchar2) return number; 
 
 function  GetAccntID(iAgentId$ number, iCurrId$ number, sAccnt$ varchar2) return number;
 
 procedure AddNewAccnt( iAgentId$ number,iCurrId$ number, sAccnt$ varchar2,sName$ varchar2);
 
 function  NewAccntId(iAgentId$ number,iCurrId$ number, sAccnt$ varchar2,sName$ varchar2) return number;
    
  procedure GetBankAccntId(
   iAgentID$ IN NUMBER, sCurr$ IN VARCHAR2, sAccnt$ IN VARCHAR2, sOwnerName$ IN VARCHAR2,
   iAcntId$ OUT NUMBER, iCurrId$ OUT NUMBER, shortName$ OUT VARCHAR2, iFlag$ OUT NUMBER);

end PKG_FMTLOAD;
/

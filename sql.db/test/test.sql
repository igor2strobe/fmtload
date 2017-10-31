rem PL/SQL Developer Test Script

set feedback off
set autoprint off

rem Execute PL/SQL Block
-- Created on 21.03.2014 by ADMIN 
declare 
  -- Local variables here
  iAccntID integer;
  sAccntStr varchar2(255);
  StartDT Date;
  EndDT Date;
  iRes integer;
begin
  -- Test statements here
  iAccntID := '2317';
  StartDT := '09.08.2013';
  EndDT   := '10.08.2013';
  select PKG_FmtLoad.GetDelRowCount( iAccntID, StartDt, EndDt) Into ires from dual;
--  select DeleteStatement( sAccntStr, StartDt, EndDt) into iRes from dual;
  dbms_output.put_line( to_char(iRes));                       
end;
/

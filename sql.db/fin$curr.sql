#SET FEEDBACK OFF;
#set heading off;
set pagesize 0;
set lines 120;
set pages 9999;

ALTER TABLE FIN$Currency
 ADD ALTER_SIGN varchar2(80);

update FIN$Currency
 set ALTER_SIGN ='RUB' WHERE curr_code=810;
  
update FIN$Currency
 set ALTER_SIGN ='BYB,BRB' WHERE curr_code=974;
  
update FIN$Currency
 set ALTER_SIGN ='PLN' WHERE curr_code=616;

exit;
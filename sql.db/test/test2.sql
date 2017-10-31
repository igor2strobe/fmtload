select i.* from fin$corr_pay_items i
 where i.chk_flag=0
  and i.uin_corr_acnt in( 
   select t.uin_corr_acnt from FIN$CORR_PAY_ACNT t
    where t.uin_corr in (447)
  )
   order by uin_corr_acnt, CA_PAY_DATE, CA_SUMM_DEBT, CA_SUMM_CRED, CA_DOCUMENT, DEBET_CLI_ACNT, CREDIT_CLI_ACNT, DEBET_CLI_NAME, CREDIT_CLI_NAME

 select t.uin_corr_acnt, t.* 
   from FIN$CORR_PAY_ACNT t
    where t.uin_corr in (447)
 order by t.uin_corr_acnt

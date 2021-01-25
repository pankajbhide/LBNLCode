/***************************************************************************
 NAME                   : lets_maximo.SQL

 DATE WRITTEN           : 29-APRIL-2010

 AUTHOR                 : Annette Leung

 PURPOSE                : This program to import LETS hour data into MAXIMO daily
 
 MODIFICATION HISTORY	: May 13, 2014
                          Modified the program for FSM project.  Change the WO# to match with ORDER_NUMBER 
                          and add two column for archive table.
                          
                        : Sept 123, 2015
                        : Modified the program for MAXIMO 7.6 upgrade
********************************************************************************/

whenever sqlerror exit 1 rollback;

declare                       
     orgid_v            lbl_letstrans.orgid%type;   
     siteid_v           lbl_letstrans.siteid%type;   
     letstransid_v      lbl_letstrans.lbl_letstransid%type;
     financialperiod_v  lbl_letstrans.financialperiod%type; 
     craft_v            lbl_letstrans.craft%type; 
     regularhrs_v       workorder.actlabhrs%type:=0;   
     overtime_v         workorder.actlabhrs%type:=0;

/******************** select LETS records ********************/     
   cursor lets_cur is
        select a.emp_no, a.reported_hrs, a.date_worked, a.ORDER_NUMBER, a.overtime,
        b.assetnum, b.glaccount, b.istask, b.location
        from lbl_letsdata a, workorder b
        where a.ORDER_NUMBER is not null                                
        and a.date_worked > (select max(transdate) from labtrans where lt1 is not null)           
        and a.ORDER_NUMBER = b.wonum (+)
        and b.orgid = orgid_v
        and b.siteid = siteid_v
        and a.org_code like 'FA%'
        and a.ORDER_NUMBER like 'W%'
        and a.paygroup = 'BWK'
        order by a.ORDER_NUMBER, a.date_worked;  
        
/******************** select LETS records and save into history table ********************/     
   cursor archive_lets_cur is
        select *
        from lbl_letsdata 
        order by ORDER_NUMBER;          


/******************** Main Program ********************/ 
   
begin

    orgid_v:='LBNL';
    siteid_v:='FAC';
  
--     orgid_v   :=upper('&1');
--     siteid_v  :=upper('&2'); 
   
     if (orgid_v is null or length(orgid_v)=0) then
       orgid_v :='LBNL';
     end if;
     
     if (siteid_v is null or length(siteid_v)=0) then
        siteid_v :='FAC';
     end if;  



     
   delete from lbl_letstrans; 

   for archive_lets_rec in archive_lets_cur
        loop   
            insert into batch_maximo.a_lbl_letsdata(TRANS_DATE, INTR_NO, CREATE_DATE, RPTG_PRD_END_DATE, PAYGROUP, EMP_NO,
                                    PROJECT_ID, ACCT_CD, OVERTIME, FIREFIGHTER, BASIS, ADJ_LATE_TIME, ADJ_LATE_PERIOD_END_DATE,
                                    REPORTED_HRS, IN_LDRS, PURCHASE_ORDER_NO, CRAFT_CODE, LBR_DIST_AMT, EARNINGS_TYPE, DATE_WORKED,
                                    ORG_CODE, HOURLY_RT,ACTIVITY_ID, ORDER_NUMBER)
            values
                                    (sysdate, archive_lets_rec.INTR_NO, archive_lets_rec.CREATE_DATE,
                                     archive_lets_rec.RPTG_PRD_END_DATE, archive_lets_rec.PAYGROUP, archive_lets_rec.EMP_NO,
                                     archive_lets_rec.PROJECT_ID, archive_lets_rec.ACCT_CD, archive_lets_rec.OVERTIME,
                                     archive_lets_rec.FIREFIGHTER, archive_lets_rec.BASIS, archive_lets_rec.ADJ_LATE_TIME,
                                     archive_lets_rec.ADJ_LATE_PERIOD_END_DATE,archive_lets_rec.REPORTED_HRS,
                                     archive_lets_rec.IN_LDRS, archive_lets_rec.PURCHASE_ORDER_NO, archive_lets_rec.CRAFT_CODE,
                                     archive_lets_rec.LBR_DIST_AMT, archive_lets_rec.EARNINGS_TYPE, archive_lets_rec.DATE_WORKED,
                                     archive_lets_rec.ORG_CODE, archive_lets_rec.HOURLY_RT, archive_lets_rec.ACTIVITY_ID, archive_lets_rec.ORDER_NUMBER ); 
        end loop; 
   
     for lets_rec in lets_cur 
    
      loop   
            select lbl_letstransseq.nextval
            into letstransid_v 
            from dual;
                                 

            select financialperiod 
            into   financialperiod_v 
            from   financialperiods
            where lets_rec.date_worked >= trunc(periodstart)
            and lets_rec.date_worked < trunc(periodend)
            and orgid = orgid_v;

           craft_v := LBL_MAXIMO_PKG.GET_LEADCRAFT_INFO(orgid_v, lets_rec.emp_no, 'CODE');
            
            if lets_rec.overtime = 'Y' then
                overtime_v := lets_rec.reported_hrs;
                regularhrs_v := 0;
            else
                overtime_v := 0;
                regularhrs_v := lets_rec.reported_hrs;
            end if;
            
            insert into lbl_letstrans(lbl_letstransid, description, transdate, laborcode, craft,
               regularhrs, enterby, enterdate, startdate, orgid, siteid,
               refwo, premiumpayhours, financialperiod)
            values
              (letstransid_v, 'LETS Data', lets_rec.date_worked, lets_rec.emp_no, craft_v, 
               regularhrs_v, 'LETSDATA', sysdate, lets_rec.date_worked, orgid_v, siteid_v,
               lets_rec.ORDER_NUMBER, overtime_v, financialperiod_v); 

        end loop;  
                  
commit;
    
end;                           
/






/***************************************************************************
 NAME                   : cpy_wfm_wom.SQL

 DATE WRITTEN           : 11-APRIL-2017

 AUTHOR                 : Annette Leung

 PURPOSE                : This program to copy the workflow transaction memo field to work order status table memo field
 
 MODIFICATION HISTORY	: 
                          
********************************************************************************/

whenever sqlerror exit 1 rollback;

declare                       
     orgid_v            wostatus.orgid%type;   
     siteid_v           wostatus.siteid%type;   
     

/******************** select workflow transaction records ********************/     
   cursor wftrans_cur is
   select * from wftransaction where ownertable = 'WORKORDER' 
   --and actionperformed in ('FAAGINFO', 'FAAGHOLD', 'FAAGWENG', 'FAAGWOCAN')
   and actionperformed is not null 
   and ownerid is not null
   and memo is not null 
   and processname in 
   (select  subprocessname from wfsubprocess where processname in ('FAMRO')) 
   and transdate >= (select to_date(varvalue,'YYYY-MM-DD HH24:MI:SS') from lbl_maxvars where varname = ('LAST_MEMO_COPIED_DATE'))
   and transtype = 'WFACTION';
   
   


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


   for wftrans_rec in wftrans_cur
        loop   
        
            update wostatus
                set memo = wftrans_rec.memo
                where orgid='LBNL' and siteid='FAC' and wonum= (select wonum from workorder where workorderid = wftrans_rec.ownerid)
                and changedate between (wftrans_rec.transdate - 0.0003) and (wftrans_rec.transdate + 0.0003)
                and status in (select distinct a.VALUE2 from action a where a.type = 'CHANGESTATUS' and a.objectname = 'WORKORDER');
                --and status in ('INFO', 'HOLD', 'CAN', 'WENG') ;
                
        end loop; 
   
        update lbl_maxvars
            set varvalue=to_char(sysdate,'YYYY-MM-DD HH24:MI:SS')
            where varname='LAST_MEMO_COPIED_DATE';

                  
commit;
    
end;                           
/






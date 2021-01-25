-- IF STATUS HISTORY WAPPR CAN WCLOSE

declare
--***************************************
-- prepare the where clause as applicable
--****************************************
cursor affected_workorders_cur is

select wonum, status from workorder
where 
status IN ('WCLOSE' ,'CAN', 'COMP')
and changeby in ('CHRISMORRIS' ,'TRKNIGHT')
and WORKTYPE ='LS'
--and trunc(changedate)=trunc(to_date('26-MAy-2016','DD-MON-YYYY'))
--WONUM = 'W0001017'
for update;

status_o     workorder.status%type;
statusdate_o workorder.statusdate%type;
statuschangeby_o workorder.changeby%type;

begin

for affected_workorders_rec in affected_workorders_cur 

loop

  -- find out status and statusdate prior to CAN 
  SELECT status, changedate, changeby 
    into status_o, statusdate_o, statuschangeby_o
    FROM MAXIMO.wostatus
    WHERE WONUM=affected_workorders_rec.wonum
    and status NOT IN ('WCLOSE','CAN','COMP')
    --!= affected_workorders_rec.status
    and changedate=(select max(changedate) from wostatus where WONUM=affected_workorders_rec.wonum and status NOT IN ('WCLOSE','CAN','COMP')); 
    
    -- update work order rollback to previous status
    update workorder
    set status=status_o, changedate=statusdate_o,changeby = statuschangeby_o, historyflag=0
    where current of affected_workorders_cur;
    
    -- remove from wostatus 
    delete from wostatus
    where wonum=affected_workorders_rec.wonum
    and   status in ('WCLOSE','CAN','COMP');
    --and   changedate=statusdate_o;
  
    -- update workview 
    update workview 
    set status=status_o,historyflag=0
    where recordkey=affected_workorders_rec.wonum
    and class='WORKORDER';

  end loop;

  commit;


END;

/

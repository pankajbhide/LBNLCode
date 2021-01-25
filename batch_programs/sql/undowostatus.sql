declare
--***************************************
-- prepare the where clause as applicable
--****************************************
cursor affected_workorders_cur is

select wonum, status from workorder
where status='CAN' and changeby='TRKNIGHT' 
and trunc(changedate)=trunc(to_date('26-MAy-2016','DD-MON-YYYY'))
for update;

status_o     workorder.status%type;
statusdate_o workorder.statusdate%type;

begin

for affected_workorders_rec in affected_workorders_cur 

loop

  -- find out status and statusdate prior to CAN 
  SELECT status, changedate 
    into status_o, statusdate_o
    FROM MAXIMO.wostatus
    WHERE WONUM=affected_workorders_rec.wonum
    and status != affected_workorders_rec.status
    and changedate=(select max(changedate) from wostatus
    where WONUM=affected_workorders_rec.wonum
    and status != affected_workorders_rec.status); 
    
    -- update work order rollback to previous status
    update workorder
    set status=status_o, changedate=statusdate_o, historyflag=0
    where current of affected_workorders_cur;
    
    -- remove from wostatus 
    delete from wostatus
    where wonum=affected_workorders_rec.wonum
    and   status='CAN'
    and   changedate=statusdate_o;
  
    -- update workview 
    update workview 
    set status=status_o
    where recordkey=affected_workorders_rec.wonum
    and class='WORKORDER';
    
    


  end loop;

  commit;


END;

/

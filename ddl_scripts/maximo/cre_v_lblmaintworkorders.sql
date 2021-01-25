create or replace view lbl_v_maintworkorder as 

select 
a.wonum,
a.worktype,
( select c.changedate    from maximo.wostatus c 
  where  c.orgid=a.orgid and c.siteid=a.siteid and
  c.wonum=a.wonum and c.changedate=(select min(d.changedate) 
  from maximo.wostatus d where c.orgid=d.orgid and c.siteid=d.siteid and
  c.wonum=d.wonum and rownum=1 and d.status in  (select e.value from maximo.synonymdomain e 
  where e.domainid='WOSTATUS' and e.maxvalue='APPR'))) first_approval_date
  ,
 nvl (( select c.changedate    from maximo.wostatus c 
  where  c.orgid=a.orgid and c.siteid=a.siteid and
  c.wonum=a.wonum and c.changedate=(select max(d.changedate) 
  from maximo.wostatus d where c.orgid=d.orgid and c.siteid=d.siteid and
  c.wonum=d.wonum and d.status in  (select e.value from maximo.synonymdomain e 
  where e.domainid='WOSTATUS' and e.maxvalue='COMP'))),sysdate) completion_date,
  
 round( 
 nvl (( select c.changedate    from maximo.wostatus c 
  where  c.orgid=a.orgid and c.siteid=a.siteid and
  c.wonum=a.wonum and c.changedate=(select max(d.changedate) 
  from maximo.wostatus d where c.orgid=d.orgid and c.siteid=d.siteid and
  c.wonum=d.wonum and d.status in  (select e.value from maximo.synonymdomain e 
  where e.domainid='WOSTATUS' and e.maxvalue='COMP'))),sysdate) - 
  ( select c.changedate    from maximo.wostatus c 
  where  c.orgid=a.orgid and c.siteid=a.siteid and
  c.wonum=a.wonum and c.changedate=(select min(d.changedate) 
  from maximo.wostatus d where c.orgid=d.orgid and c.siteid=d.siteid and
  c.wonum=d.wonum and rownum=1 and d.status in  (select e.value from maximo.synonymdomain e 
  where e.domainid='WOSTATUS' and e.maxvalue='APPR'))))  duration,
  decode(a.status,'COMP','Completed','WCLOSE','Completed','CLOSE', 'Completed','In Progress') status
from maximo.workorder a, maximo.worktype b
where a.reportdate between to_date('01-OCT-15','DD-MON-YY') and 
to_date('30-SEP-16','DD-MON-YY')
and a.worktype=b.worktype
and b.type !='NOCHARGE'
and upper(b.wtypedesc) like '%MAINT%'
and a.status not in (select e.value from maximo.synonymdomain e 
  where e.domainid='WOSTATUS' and e.maxvalue in ('WAPPR','CAN'));
  

grant select on lbl_v_maintworkorder to public;




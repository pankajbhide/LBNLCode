create or replace view lbl_v_wobacklog as 

select a.wonum, c.maxvalue, decode(c.maxvalue,'ALT-IMPV','Alterations/Improvements',
'CM','Corrective Maintenance',
'OPS','Operations',
'PM','Preventive Maintenance',
'PROJ','Projects',
'FURNITURE','Furniture') worktype_group,
a.worktype, b.wtypedesc worktype_desc, 
a.leadcraft,
a.status,
(select max(d.description) from craft d where d.craft=a.leadcraft ) craft_desc,
(case when round(sysdate - a.schedfinish) <= 30  then round(sysdate - a.schedfinish) else null end)  lessthan_30days,

(case when round(sysdate - a.schedfinish) > 30 and round(sysdate - a.schedfinish) <= 60  
      then round(sysdate - a.schedfinish) else null end) between30_60days,
      
(case when round(sysdate - a.schedfinish) > 60 and round(sysdate - a.schedfinish) <= 90  
      then round(sysdate - a.schedfinish) else null end) between60_90days, 
      
(case when round(sysdate - a.schedfinish) > 90
      then round(sysdate - a.schedfinish) else null end) above_90days     
from workorder a, worktype b, synonymdomain c
where a.worktype=b.worktype
and  (b.type is null or b.type !='NOCHARGE')
and  c.domainid='LBL_WOTYPEGROUP'
and  c.value=b.worktype
and  a.actfinish is null 
and  a.schedfinish < sysdate
and  a.status not in ('COMP','WCLOSE','CLOSE','CAN')
/*group by  1,2,3,4,5
/*decode(c.maxvalue,'ALT-IMPV','Alterations/Improvements',
'CM','Corrective Maintenance',
'OPS','Operations',
'PM','Preventive Maintenance',
'PROJ','Projects',
'FURNITURE','Furniture') ,
a.worktype, b.wtypedesc
--,  a.leadcraft */
order by 1,2,3,4;



grant select on lbl_v_wobacklog to public;

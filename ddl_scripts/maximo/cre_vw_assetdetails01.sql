create or replace view lbl_v_assetspec01  as select 
a.orgid  orgid,
a.siteid siteid,
a.assetnum assetnum,
a.description,  
(select ald.ldtext from longdescription ald where ald.ldownertable = 'ASSET' and ald.ldownercol = 'DESCRIPTION' and ald.ldkey = a.assetid) asset_longdesc,
a.location    ,
a.manufacturer,
a.status,
(select asp1.alnvalue from assetspec asp1 where asp1.assetnum = a.assetnum and asp1.ASSETATTRID = 'MODEL') model, 
(select asp2.alnvalue from assetspec asp2 where asp2.assetnum = a.assetnum and asp2.ASSETATTRID = 'SERIAL') serial, 
(select asp3.alnvalue from assetspec asp3 where asp3.assetnum = a.assetnum and asp3.ASSETATTRID = 'CAP-MOT') motor_capacity,
(select asp4.alnvalue from assetspec asp4 where asp4.assetnum = a.assetnum and asp4.ASSETATTRID = 'MOD-MOT') motor_model ,
(select asp5.alnvalue from assetspec asp5 where asp5.assetnum = a.assetnum and asp5.ASSETATTRID = 'MOT- HP') motor_horsepower,
(select asp6.alnvalue from assetspec asp6 where asp6.assetnum = a.assetnum and asp6.ASSETATTRID = 'ELE-VOLT') unit_voltage,
 s.jpnum jobplan, 
(select ldtext from longdescription where ldownertable = 'JOBTASK' and ldownercol = 'DESCRIPTION' and ldkey = (select jobtaskid from jobtask where jpnum = s.jpnum and jptask = '10' and jobplanid = (select jobplanid from jobplan where status = 'ACTIVE' and jpnum = s.jpnum))) jobplan_longdesc,
(select jpduration from jobplan where jpnum = s.jpnum and status = 'ACTIVE') jobplan_duration
from asset a,pm p, pmsequence s
where a.assetnum = p.assetnum
and p.pmnum (+) = s.pmnum;


grant select on lbl_v_assetspec01 to public;


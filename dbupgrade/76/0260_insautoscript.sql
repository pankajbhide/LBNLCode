delete from autoscript;

insert into autoscript( autoscript,status,
scheduledstatus,comments,ownerid,ownername,
ownerphone,owneremail,createdbyid,
description,orgid,siteid,action,
source,createddate,version,category,
statusdate,changedate,createdbyphone,
createdbyname,createdbyemail,owner,
createdby,changeby,autoscriptid,
hasld,langcode,binaryscriptsource,
scriptlanguage,userdefined,
loglevel,interface,active)
select 
autoscript,status,
scheduledstatus,comments,ownerid,ownername,
ownerphone,owneremail,createdbyid,
description,orgid,siteid,action,
source,createddate,version,category,
statusdate,changedate,createdbyphone,
createdbyname,createdbyemail,owner,
createdby,changeby,autoscriptseq.NEXTVAL,
hasld,langcode,binaryscriptsource,
scriptlanguage,userdefined,
loglevel,interface,active
from autoscript@this2src;


delete from scriptlaunchpoint ;

insert into scriptlaunchpoint (
launchpointname,autoscript,description,
launchpointtype,objectname,objectevent,
attributename,
scriptlaunchpointid, condition,active)
select 
a.launchpointname,a.autoscript,a.description,
a.launchpointtype,a.objectname,a.objectevent,
a.attributename,
scriptlaunchpointseq.NEXTVAL, a.condition,a.active
from scriptlaunchpoint@this2src a;

delete  autoscriptvars ;

insert into autoscriptvars
(autoscript, varname,varbindingvalue,varbindingtype,vartype,
description,allowoverride,literaldatatype,accessflag,
autoscriptvarsid) select 
autoscript, varname,varbindingvalue,varbindingtype,vartype,
description,allowoverride,literaldatatype,accessflag,
autoscriptvarsseq.NEXTVAL from autoscriptvars@this2src;

delete from launchpointvars ;

insert into launchpointvars
(launchpointname,autoscript,varname,
varbindingvalue, launchpointvarsid)
select 
launchpointname,autoscript,varname,
varbindingvalue, launchpointvarsseq.NEXTVAL 
from launchpointvars@this2src;


delete from autoscriptstate ;

insert into autoscriptstate(
autoscriptstateid,autoscript,changeby,changedate,
memo,orgid,siteid,status)
select autoscriptstateseq.NEXTVAL,autoscript,changeby,changedate,
memo,orgid,siteid,status
from autoscriptstate@this2src;

----

delete from longdescription where ldownertable='AUTOSCRIPT';







commit;

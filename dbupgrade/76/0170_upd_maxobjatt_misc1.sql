--**********************************************
-- Changes related to Work order applications 
-- Required for MAXIMO 6.2.6 ro 7.6.0.1
--**********************************************


update maxobjectcfg set classname='psdi.mbo.custapp.CustomMboSet' where objectname in ('LBL_MAILSTOP','LBL_BOBSYSTEMDTL', 'LBL_LABTRANS');
update maxobject    set classname='psdi.mbo.custapp.CustomMboSet' where objectname in ('LBL_MAILSTOP','LBL_BOBSYSTEMDTL','LBL_LABTRANS');

update maxattributecfg set classname=null where objectname='LBL_MAILSTOP' and attributename='MAILSTOPID';
update maxattribute    set classname=null where objectname='LBL_MAILSTOP' and attributename='MAILSTOPID';

update maxattributecfg set classname=null where objectname='LBL_BOBSYSTEMDTL' and attributename='SUBSYSTEMID';
update maxattribute    set classname=null where objectname='LBL_BOBSYSTEMDTL' and attributename='SUBSYSTEMID';


update maxattributecfg set DEFAULTVALUE='WAPPR' where objectname='PM' and attributename='WOSTATUS';
update maxattribute    set DEFAULTVALUE='WAPPR' where objectname='PM' and attributename='WOSTATUS';


update maxattribute set classname=null where objectname='TOOLTRANS' and
attributename in ('LBL_STARTDATE','LBL_FINISHDATE','LBL_LOCATIONS',
'LBL_TRIPS','LBL_METERREADING','LBL_FINISHTIME');

update maxattributecfg set classname=null where objectname='TOOLTRANS' and
attributename in ('LBL_STARTDATE','LBL_FINISHDATE','LBL_LOCATIONS',
'LBL_TRIPS','LBL_METERREADING','LBL_FINISHTIME');


-- FOR MAIL STOPS 
delete  from sigoption where app='LBLMLSTOP' and optionname in ('BOOKMARK','EDITSYS');


-- Remove VP and VM 

delete from maxapps where app in ('VP','VM','VS');
delete from maxpresentation where app in ('VP','VM','VS');
delete from sigoption where app in ('VP','VM','VS');
delete from applicationauth where app in ('VP','VM','VS');
delete from maxlabels where app in ('VP','VM','VS');
delete from maxmenu where (menutype='MODULE' and elementtype='APP'
and keyvalue in ('VP','VM','VS')) or (menutype !='MODULE' and
moduleapp in ('VP','VM','VS'));
delete from appdoctype where app in ('VP','VM','VS');
delete from sigoptflag where app in ('VP','VM','VS');



--create database link t2s connect to maximo identified by allset2g using 'mmo7dev';

/*
delete from condition where conditionnum='LBLALLWFSTAT';

insert into condition (conditionid, conditionnum, description,
expression, type, nocaching) select conditionseq.NEXTVAL, conditionnum,
description,expression, type, nocaching from condition@t2s where 
conditionnum='LBLALLWFSTAT';

drop database link t2s;

delete from MAXDOMVALCOND where conditionnum='LBLALLWFSTAT';

insert into MAXDOMVALCOND (domainid, valueid, conditionnum,
objectname, maxdomvalcondid) values
('WOSTATUS','WOSTATUS|REL', 'LBLALLWFSTAT','WORKORDER', MAXDOMVALCONDseq.NEXTVAL);

insert into MAXDOMVALCOND (domainid, valueid, conditionnum,
objectname, maxdomvalcondid) values
('WOSTATUS','WOSTATUS|WREL', 'LBLALLWFSTAT','WORKORDER', MAXDOMVALCONDseq.NEXTVAL);

insert into MAXDOMVALCOND (domainid, valueid, conditionnum,
objectname, maxdomvalcondid) values
('WOSTATUS','WOSTATUS|RFI', 'LBLALLWFSTAT','WORKORDER', MAXDOMVALCONDseq.NEXTVAL);

insert into MAXDOMVALCOND (domainid, valueid, conditionnum,
objectname, maxdomvalcondid) values
('WOSTATUS','WOSTATUS|SUBREL', 'LBLALLWFSTAT','WORKORDER', MAXDOMVALCONDseq.NEXTVAL);


insert into MAXDOMVALCOND (domainid, valueid, conditionnum,
objectname, maxdomvalcondid) values
('WOSTATUS','WOSTATUS|WSCH', 'LBLALLWFSTAT','WORKORDER', MAXDOMVALCONDseq.NEXTVAL);

*/



update maxattributecfg set classname=null where objectname='LBL_WRHSFEEDDEF' and attributename='DROP_PROJ_ACT_ID';
update maxattribute    set classname=null where objectname='LBL_WRHSFEEDDEF' and attributename='DROP_PROJ_ACT_ID';


update maxattributecfg set classname=null where objectname='LBL_WRHSFEEDDEF' and attributename='DEF_PROJ_ACT_ID';
update maxattribute    set classname=null where objectname='LBL_WRHSFEEDDEF' and attributename='DEF_PROJ_ACT_ID';




commit;









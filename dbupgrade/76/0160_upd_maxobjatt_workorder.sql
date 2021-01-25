--**********************************************
-- Changes related to Work order applications 
-- Required for MAXIMO 6.2.6 ro 7.6.0.1
--**********************************************


delete from lbl_maxvars where varname='LBL_WOLENGTH' and orgid='LBNL' and siteid='FAC';

insert into lbl_maxvars (orgid, siteid, varname, varvalue, description, lbl_maxvarsid, hasld) values
('LBNL','FAC','LBL_WOLENGTH',8,'Length of work order number', lbl_maxvarsidseq.nextval,0);

delete autokey where autokeyname='WORKORDERNUM' and siteid is null and orgid is null;


update autokey set orgid='LBNL', siteid='FAC' where autokeyname='WORKORDERNUM';

delete from maxlookupmap where target='MULTIASSETLOCCI' and lookupattr='RECORDCLASS';

insert into maxlookupmap(target,lookupattr,targetattr,sourcekey,seqnum,allownull,source,maxlookupmapid) 
values ('MULTIASSETLOCCI','RECORDCLASS','RECORDCLASS','VALUE', 1, 1,'SYNONYMDOMAIN', maxlookupmapseq.nextval);

commit;


update maxattributecfg set classname='psdi.app.workorder.FldWOWONum', defaultvalue='&AUTOKEY&'  where objectname='WORKORDER' and attributename='WONUM';
update maxattribute    set classname='psdi.app.workorder.FldWOWONum', defaultvalue='&AUTOKEY&'  where objectname='WORKORDER' and attributename='WONUM';



update maxattributecfg set classname='psdi.app.workorder.FldWOWONum', defaultvalue='&AUTOKEY&'  where objectname='WOACTIVITY' and attributename='WONUM';
update maxattribute    set classname='psdi.app.workorder.FldWOWONum', defaultvalue='&AUTOKEY&'  where objectname='WOACTIVITY' and attributename='WONUM';



update maxattributecfg set classname='psdi.app.person.FldPersonID' where objectname='WORKORDER' and attributename='WO1';
update maxattribute    set classname='psdi.app.person.FldPersonID' where objectname='WORKORDER' and attributename='WO1';


update maxattributecfg set classname=null where objectname='WORKORDER' and attributename='WO5';
update maxattribute    set classname=null where objectname='WORKORDER' and attributename='WO5';


update maxattributecfg set classname=null where objectname='WORKORDER' and attributename in ('LBL_DESTGROUP','LEADCRAFT','LBL_WKTHRUID');
update maxattribute    set classname=null where objectname='WORKORDER' and attributename in ('LBL_DESTGROUP','LEADCRAFT','LBL_WKTHRUID');


update maxobjectcfg set classname='psdi.mbo.custapp.CustomMboSet' where objectname in  ('LBL_WORKORDEREXT','LBL_WOWCDCONDITION');
update maxobject    set classname='psdi.mbo.custapp.CustomMboSet' where objectname in  ('LBL_WORKORDEREXT','LBL_WOWCDCONDITION');


update maxattributecfg set classname=null where objectname='LBL_WORKORDEREXT' and attributename in ('SCHED_ISSUES_DTL','PRIOR_WONUM','WARRANTY_ISS_DTL','HAZARDS_DTL','FOLLOW_STOP_WONUM','PARENT_WONUM');
update maxattribute    set classname=null where objectname='LBL_WORKORDEREXT' and attributename in ('SCHED_ISSUES_DTL','PRIOR_WONUM','WARRANTY_ISS_DTL','HAZARDS_DTL','FOLLOW_STOP_WONUM','PARENT_WONUM');


update maxattributecfg set sameasobject='WORKORDER', sameasattribute='WONUM' where objectname='LBL_WORKORDEREXT' and attributename in ('PRIOR_WONUM');
update maxattribute    set sameasobject='WORKORDER', sameasattribute='WONUM' where objectname='LBL_WORKORDEREXT' and attributename in ('PRIOR_WONUM');


-------------------------------

delete from maxrelationship where name='LBL_WO2MXPROPADMIN';

insert into maxrelationship (name, parent, child, whereclause, maxrelationshipid, remarks, dbjoinrequired) values
('LBL_WO2MXPROPADMIN','WORKORDER','MAXPROPVALUE','propname=''lbl.fac_admin_logins''',maxrelationshipseq.NEXTVAL,'For getting values of Facilities Admin logins',0);


commit;

---- for fixing 7.6 integrity checker errors -- 

update maxattributecfg set sameasobject=null, sameasattribute=null where 
objectname='A_LBL_WORKORDEREXT' and attributename='PRIOR_WONUM';

update maxattribute set sameasobject=null, sameasattribute=null where 
objectname='A_LBL_WORKORDEREXT' and attributename='PRIOR_WONUM';

update maxattributecfg set sameasobject=null, sameasattribute=null where 
objectname in ('A_LBL_WKTHRURES','A_LBL_WOWKTHRURES') and attributename='EHS_SUPPORT_CONT';

update maxattribute set sameasobject=null, sameasattribute=null where 
objectname in ('A_LBL_WKTHRURES','A_LBL_WOWKTHRURES') and attributename='EHS_SUPPORT_CONT';

commit;
----------------------

delete from maxdomain where domainid in ('LBL_ACTWORKTYPES','CRAFT');

delete from maxtabledomain where domainid in ('LBL_ACTWORKTYPES','CRAFT');

insert into maxdomain (domainid, description, domaintype,
maxdomainid, internal) values
('LBL_ACTWORKTYPES','LBNL:Active work types' ,'TABLE',
 maxdomainseq.NEXTVAL,0);

insert into maxtabledomain (domainid, 
validtnwhereclause, listwhereclause,
maxtabledomainid, objectname,errorresourcbundle, erroraccesskey)
values
('LBL_ACTWORKTYPES',
 'worktype=:worktype and lbl_inactive=0' ,'lbl_inactive=0',
 maxtabledomainseq.NEXTVAL,'WORKTYPE',
 'workorder','lbl_inactiveworktype');
 
 
 
insert into maxdomain (domainid, description, domaintype,
maxdomainid, internal) values
('CRAFT','CRAFT' ,'TABLE',
 maxdomainseq.NEXTVAL,0);

insert into maxtabledomain (domainid, 
validtnwhereclause, listwhereclause,
maxtabledomainid, objectname)
values
('CRAFT',
 'craft=:leadcraft' ,null,
 maxtabledomainseq.NEXTVAL,'CRAFT');
 
  
  
 commit;


update maxattributecfg set domainid='LBL_ACTWORKTYPES'  where objectname='WORKORDER' and attributename='WORKTYPE';
update maxattribute    set domainid='LBL_ACTWORKTYPES'  where objectname='WORKORDER' and attributename='WORKTYPE';

commit;

grant all on woserviceaddress to meauser;
 
 
update maxattributecfg set classname=null where  objectname='LBL_WOWCDCONDITION' and attributename='ANSWER';
update maxattribute    set classname=null where  objectname='LBL_WOWCDCONDITION' and attributename='ANSWER';


update maxattributecfg set domainid='LBL_WO2WKHDR' where  objectname='WORKORDER' and attributename='LBL_WKTHRUID';
update maxattribute    set domainid='LBL_WO2WKHDR' where  objectname='WORKORDER' and attributename='LBL_WKTHRUID';




update maxattributecfg set classname=null where objectname in ('WOCHANGE','WORELEASE','WOACTIVITY','WORKORDER') and attributename='LBL_DESTGROUP';
update maxattribute    set classname=null where objectname in ('WOCHANGE','WORELEASE','WOACTIVITY','WORKORDER') and attributename='LBL_DESTGROUP';


update maxattribute    set classname=null where objectname='LOCATIONS' and attributename='LBL_REL_REQD';
update maxattributecfg set classname=null where objectname='LOCATIONS' and attributename='LBL_REL_REQD';

update maxattribute set classname=null    where objectname in ('WOACTIVITY', 'WORELEASE','WOCHANGE') and attributename in ('LBL_REL_REQD','LBL_WKTHRUID');
update maxattributecfg set classname=null where objectname in ('WOACTIVITY', 'WORELEASE','WOCHANGE') and attributename in ('LBL_REL_REQD','LBL_WKTHRUID');


update maxobjectcfg set classname='psdi.mbo.custapp.CustomMboSet' where objectname='LBL_AUTH_RELEASE';
update maxobject    set classname='psdi.mbo.custapp.CustomMboSet' where objectname='LBL_AUTH_RELEASE'; 


update maxobjectcfg set classname='lbl.app.workorder.LblWOSet' where objectname='WORKORDER';
update maxobject    set classname='lbl.app.workorder.LblWOSet' where objectname='WORKORDER'; 


update maxattribute    set classname='psdi.app.person.FldPersonID' where objectname='LBL_AUTH_RELEASE' and attributename='PERSONID';
update maxattributecfg set classname='psdi.app.person.FldPersonID' where objectname='LBL_AUTH_RELEASE' and attributename='PERSONID';


update maxattribute set classname=null    where objectname in ('WORKTYPE') and attributename in ('LBL_REL_REQD');
update maxattributecfg set classname=null where objectname in ('WORKTYPE') and attributename in ('LBL_REL_REQD');
-------------------------

update maxobjectcfg set classname='psdi.mbo.custapp.CustomMboSet' where objectname in ('LBL_WCDCATEGORY','LBL_WCDCONDITION','LBL_WCDSUBCOND','LBL_WOWCDCONDITION');
update maxobject    set classname='psdi.mbo.custapp.CustomMboSet' where objectname in ('LBL_WCDCATEGORY','LBL_WCDCONDITION','LBL_WCDSUBCOND','LBL_WOWCDCONDITION');

update maxattribute set classname=null    where objectname in ('LBL_WOWCDCONDITION') and attributename in ('ANSWER');
update maxattributecfg set classname=null where objectname in ('LBL_WOWCDCONDITION') and attributename in ('ANSWER');

delete from maxmenu where elementtype='APP' and keyvalue in ('LBL_WCDCAT','LBLWCDCOND');

insert into maxmenu (elementtype, keyvalue, image, maxmenuid, menutype,moduleapp, position, subposition, visible)
values ('APP','LBL_WCDCAT','appimg_jobplan.gif',maxmenuseq.NEXTVAL,'MODULE','PLANS',10736,0,1);

insert into maxmenu (elementtype, keyvalue, image, maxmenuid, menutype,moduleapp, position, subposition, visible)
values ('APP','LBLWCDCOND','appimg_jobplan.gif',maxmenuseq.NEXTVAL,'MODULE','PLANS',10737,0,1);

update maxattributecfg set domainid='CRAFT' where objectname='WORKORDER' and attributename in ('LEADCRAFT');
update maxattribute    set domainid='CRAFT' where objectname='WORKORDER' and attributename in ('LEADCRAFT');

delete from synonymdomain where domainid='WOSTATUS' and maxvalue='WSCH';

insert into synonymdomain
(domainid,maxvalue, value, defaults, description, synonymdomainid, valueid) values
('WOSTATUS','WSCH','WSCH',1,'Waiting to be scheduled (IBM)', synonymdomainseq.NEXTVAL,'WOSTATUS|WSCH');



commit;








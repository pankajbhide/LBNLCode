--**********************************************
-- Changes related to Walk through application 
-- Required for MAXIMO 6.2.6 ro 7.6.0.1
--**********************************************

update maxobjectcfg set classname='lbl.app.lbl_walkthru.LblWalkthruSet' where objectname='LBL_WKTHRU';
update maxobject    set classname='lbl.app.lbl_walkthru.LblWalkthruSet' where objectname='LBL_WKTHRU'; 

update maxobjectcfg set classname='psdi.mbo.custapp.CustomMboSet' where objectname='LBL_WKTHRUFEEDBK';
update maxobject    set classname='psdi.mbo.custapp.CustomMboSet' where objectname='LBL_WKTHRUFEEDBK'; 

update maxobjectcfg set classname='psdi.mbo.custapp.CustomMboSet' where objectname='LBL_WKTHRUHAZ';
update maxobject    set classname='psdi.mbo.custapp.CustomMboSet' where objectname='LBL_WKTHRUHAZ'; 

update maxobjectcfg set classname='psdi.mbo.custapp.CustomMboSet' where objectname='LBL_WKTHRUMAT';
update maxobject    set classname='psdi.mbo.custapp.CustomMboSet' where objectname='LBL_WKTHRUMAT'; 

update maxobjectcfg set classname='psdi.mbo.custapp.CustomMboSet' where objectname='LBL_WKTHRUOPS';
update maxobject    set classname='psdi.mbo.custapp.CustomMboSet' where objectname='LBL_WKTHRUOPS'; 

update maxobjectcfg set classname='psdi.mbo.custapp.CustomMboSet' where objectname='LBL_WKTHRURES';
update maxobject    set classname='psdi.mbo.custapp.CustomMboSet' where objectname='LBL_WKTHRURES'; 
-- 
update maxobjectcfg set classname='psdi.mbo.custapp.CustomMboSet' where objectname='LBL_WOWKTHRU';
update maxobject    set classname='psdi.mbo.custapp.CustomMboSet' where objectname='LBL_WOWKTHRU'; 

update maxobjectcfg set classname='psdi.mbo.custapp.CustomMboSet' where objectname='LBL_WOWKTHRUFEEDBK';
update maxobject    set classname='psdi.mbo.custapp.CustomMboSet' where objectname='LBL_WOWKTHRUFEEDBK'; 

update maxobjectcfg set classname='psdi.mbo.custapp.CustomMboSet' where objectname='LBL_WOWKTHRUHAZ';
update maxobject    set classname='psdi.mbo.custapp.CustomMboSet' where objectname='LBL_WOWKTHRUHAZ'; 

update maxobjectcfg set classname='psdi.mbo.custapp.CustomMboSet' where objectname='LBL_WOWKTHRUMAT';
update maxobject    set classname='psdi.mbo.custapp.CustomMboSet' where objectname='LBL_WOWKTHRUMAT'; 

update maxobjectcfg set classname='psdi.mbo.custapp.CustomMboSet' where objectname='LBL_WOWKTHRUOPS';
update maxobject    set classname='psdi.mbo.custapp.CustomMboSet' where objectname='LBL_WOWKTHRUOPS'; 

update maxobjectcfg set classname='psdi.mbo.custapp.CustomMboSet' where objectname='LBL_WOWKTHRURES';
update maxobject    set classname='psdi.mbo.custapp.CustomMboSet' where objectname='LBL_WOWKTHRURES'; 

--------------
update maxattributecfg set classname=null where objectname='LBL_WKTHRU' and attributename='DESCRIPTION';
update maxattribute    set classname=null where objectname='LBL_WKTHRU' and attributename='DESCRIPTION';

update maxattributecfg set classname=null, DEFAULTVALUE='&AUTOKEY&' where objectname='LBL_WKTHRU' and attributename='WKTHRUID';
update maxattribute    set classname=null, DEFAULTVALUE='&AUTOKEY&' where objectname='LBL_WKTHRU' and attributename='WKTHRUID';

update maxattributecfg set classname='psdi.app.person.FldPersonID' where objectname='LBL_WKTHRUFEEDBK' and attributename='PERSONID';
update maxattribute    set classname='psdi.app.person.FldPersonID' where objectname='LBL_WKTHRUFEEDBK' and attributename='PERSONID';

update maxattributecfg set classname=null where objectname='LBL_WKTHRUHAZ' and attributename='HAZARDID';
update maxattribute    set classname=null where objectname='LBL_WKTHRUHAZ' and attributename='HAZARDID';

update maxattributecfg set classname=null where objectname='LBL_WKTHRUMAT' and attributename='ITEMNUM';
update maxattribute    set classname=null where objectname='LBL_WKTHRUMAT' and attributename='ITEMNUM';

update maxattributecfg set classname=null where objectname='LBL_WKTHRUOPS' and attributename='OPSEQUENCE';
update maxattribute    set classname=null where objectname='LBL_WKTHRUOPS' and attributename='OPSEQUENCE';

update maxattributecfg set classname=null where objectname='LBL_WKTHRUOPS' and attributename='OPDURATION';
update maxattribute    set classname=null where objectname='LBL_WKTHRUOPS' and attributename='OPDURATION';

update maxattributecfg set classname=null where objectname='LBL_WKTHRURES' and attributename='EHS_SUPPORT';
update maxattribute    set classname=null where objectname='LBL_WKTHRURES' and attributename='EHS_SUPPORT';

update maxattributecfg set classname=null where objectname='LBL_WKTHRURES' and attributename='PERMITS';
update maxattribute    set classname=null where objectname='LBL_WKTHRURES' and attributename='PERMITS';

update maxattributecfg set classname=null where objectname='LBL_WKTHRURES' and attributename='DRAWINGS';
update maxattribute    set classname=null where objectname='LBL_WKTHRURES' and attributename='DRAWINGS';

update maxattributecfg set classname=null where objectname='LBL_WKTHRURES' and attributename='CRAFT';
update maxattribute    set classname=null where objectname='LBL_WKTHRURES' and attributename='CRAFT';

update maxattributecfg set classname=null where objectname='LBL_WKTHRURES' and attributename='SEQUENCE';
update maxattribute    set classname=null where objectname='LBL_WKTHRURES' and attributename='SEQUENCE';

update maxattributecfg set classname='psdi.app.person.FldPersonID' where objectname='LBL_WKTHRURES' and attributename='EHS_SUPPORT_CONT';
update maxattribute    set classname='psdi.app.person.FldPersonID' where objectname='LBL_WKTHRURES' and attributename='EHS_SUPPORT_CONT';

update maxattributecfg set classname='psdi.app.person.FldPersonID' where objectname='LBL_WKTHRURES' and attributename='PERSONID';
update maxattribute    set classname='psdi.app.person.FldPersonID' where objectname='LBL_WKTHRURES' and attributename='PERSONID';

update maxattributecfg set classname=null where objectname='LBL_WKTHRURES' and attributename='CRAFT_DURATION';
update maxattribute    set classname=null where objectname='LBL_WKTHRURES' and attributename='CRAFT_DURATION';

update maxattributecfg set classname=null where objectname='LBL_WOWKTHRU' and attributename='DESCRIPTION';
update maxattribute    set classname=null where objectname='LBL_WOWKTHRU' and attributename='DESCRIPTION';

update maxattributecfg set classname='psdi.app.person.FldPersonID' where objectname='LBL_WOWKTHRUFEEDBK' and attributename='PERSONID';
update maxattribute    set classname='psdi.app.person.FldPersonID' where objectname='LBL_WOWKTHRUFEEDBK' and attributename='PERSONID';

update maxattributecfg set classname=null where objectname='LBL_WOWKTHRUHAZ' and attributename='HAZARDID';
update maxattribute    set classname=null where objectname='LBL_WOWKTHRUHAZ' and attributename='HAZARDID';

update maxattributecfg set classname=null where objectname='LBL_WOWKTHRUMAT' and attributename='ITEMNUM';
update maxattribute    set classname=null where objectname='LBL_WOWKTHRUMAT' and attributename='ITEMNUM';

update maxattributecfg set classname=null where objectname='LBL_WOWKTHRUOPS' and attributename='OPDURATION';
update maxattribute    set classname=null where objectname='LBL_WOWKTHRUOPS' and attributename='OPDURATION';

update maxattributecfg set classname=null where objectname='LBL_WOWKTHRURES' and attributename='EHS_SUPPORT';
update maxattribute    set classname=null where objectname='LBL_WOWKTHRURES' and attributename='EHS_SUPPORT';

------
update maxattributecfg set classname=null where objectname='LBL_WOWKTHRURES' and attributename='PERMITS';
update maxattribute    set classname=null where objectname='LBL_WOWKTHRURES' and attributename='PERMITS';

update maxattributecfg set classname=null where objectname='LBL_WOWKTHRURES' and attributename='DRAWINGS';
update maxattribute    set classname=null where objectname='LBL_WOWKTHRURES' and attributename='DRAWINGS';

update maxattributecfg set classname=null where objectname='LBL_WOWKTHRURES' and attributename='CRAFT';
update maxattribute    set classname=null where objectname='LBL_WOWKTHRURES' and attributename='CRAFT';

update maxattributecfg set classname=null where objectname='LBL_WOWKTHRURES' and attributename='SEQUENCE';
update maxattribute    set classname=null where objectname='LBL_WOWKTHRURES' and attributename='SEQUENCE';

update maxattributecfg set classname='psdi.app.person.FldPersonID' where objectname='LBL_WOWKTHRURES' and attributename='EHS_SUPPORT_CONT';
update maxattribute    set classname='psdi.app.person.FldPersonID' where objectname='LBL_WOWKTHRURES' and attributename='EHS_SUPPORT_CONT';

update maxattributecfg set classname='psdi.app.person.FldPersonID' where objectname='LBL_WOWKTHRURES' and attributename='PERSONID';
update maxattribute    set classname='psdi.app.person.FldPersonID' where objectname='LBL_WOWKTHRURES' and attributename='PERSONID';

update maxattributecfg set classname=null where objectname='LBL_WOWKTHRURES' and attributename='CRAFT_DURATION';
update maxattribute    set classname=null where objectname='LBL_WOWKTHRURES' and attributename='CRAFT_DURATION';


update maxattributecfg set sameasobject='PERSON', sameasattribute='PERSONID'  where objectname='LBL_WKTHRURES' and attributename='EHS_SUPPORT_CONT';
update maxattribute    set sameasobject='PERSON', sameasattribute='PERSONID'  where objectname='LBL_WKTHRURES' and attributename='EHS_SUPPORT_CONT';

update maxattributecfg set sameasobject='PERSON' , sameasattribute='PERSONID'  where objectname='LBL_WOWKTHRURES' and attributename='EHS_SUPPORT_CONT';
update maxattribute    set sameasobject='PERSON' , sameasattribute='PERSONID'  where objectname='LBL_WOWKTHRURES' and attributename='EHS_SUPPORT_CONT';

-----------------

delete from lbl_maxvars where varname='LBL_WKTRHULENGTH' and orgid='LBNL' and siteid='FAC';

insert into lbl_maxvars (orgid, siteid, varname, varvalue, description, lbl_maxvarsid, hasld) values
('LBNL','FAC','LBL_WKTRHULENGTH',9,'Length of walk through number', lbl_maxvarsidseq.nextval,0);

 -- Remove  system level autokey for walk through    
delete from autokey where autokeyname ='LBL_WKTHRUID' and orgid is null and siteid is null;

------
update maxobject    set SITEORGTYPE='SITE'    where objectname like 'LBL_WK%';
update maxobjectcfg set SITEORGTYPE='SITE'    where objectname like 'LBL_WK%';

update maxobject    set SITEORGTYPE='SITE'    where objectname like 'LBL_WOWK%';
update maxobjectcfg set SITEORGTYPE='SITE'    where objectname like 'LBL_WOWK%';

 -- For allowing walk thru application show in Plans module

delete from maxmenu where elementtype='APP' and keyvalue='LBLWKTHRU';

insert into maxmenu (elementtype, keyvalue, image, maxmenuid, menutype,moduleapp, position, subposition, visible)
values ('APP','LBLWKTHRU','appimg_jobplan.gif',maxmenuseq.NEXTVAL,'MODULE','PLANS',10735,0,1);

update maxattribute  set classname=null where  attributename in ('RES_DURATION', 'PLAN_TEAM_DURATION','PLAN_TEAM_DURATION','RES_DURATION','OPSEQUENCE');

update maxattributecfg  set classname=null where  attributename in ('RES_DURATION', 'PLAN_TEAM_DURATION','PLAN_TEAM_DURATION','RES_DURATION','OPSEQUENCE');

------

update sigoption set description='New Walk through template' where app='LBLWKTHRU' and optionname='INSERT'; 

delete from maxmenu where moduleapp like 'LBLWKTHRU' and keyvalue='BOOKMARK';

delete from sigoption where app = 'LBLWKTHRU' and optionname='BOOKMARK';



update maxmessages set value='Duration should be greater than 0.' where msgkey='lbl_wkthrudur>0';

commit;



grant select on lbl_maxvars to public;

delete from maxlookupmap where lookupattr='EHS_SUPPORT_CONT';

insert into maxlookupmap (allownull, lookupattr,
maxlookupmapid, seqnum, source, sourcekey, target,
targetattr) values (1, 'EHS_SUPPORT_CONT',
maxlookupmapseq.NEXTVAL,1,'PERSON','PERSONID','LBL_WKTHRURES',
'EHS_SUPPORT_CONT');


insert into maxlookupmap (allownull, lookupattr,
maxlookupmapid, seqnum, source, sourcekey, target,
targetattr) values (1, 'EHS_SUPPORT_CONT',
maxlookupmapseq.NEXTVAL,1,'PERSON','PERSONID','LBL_WOWKTHRURES',
'EHS_SUPPORT_CONT');

commit;




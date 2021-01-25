
-- Lockshop deployment ---

-- grants to public ---------
grant select on LBL_V_GL to public;

grant select on LBL_V_PROJACT to public;

grant select on WOSTATUSSEQ to public;
----------------- update meta tables -----------

update maxattribute a set a.classname=(select b.classname from maxattribute@this2src b where b.objectname='ISSUECURRENTITEM' and b.attributename='GLDEBITACCT')
where a.objectname='ISSUECURRENTITEM' and a.attributename='GLDEBITACCT';

update maxattributecfg a set a.classname=(select b.classname from maxattributecfg@this2src b where b.objectname='ISSUECURRENTITEM' and b.attributename='GLDEBITACCT')
where a.objectname='ISSUECURRENTITEM' and a.attributename='GLDEBITACCT';


update maxattribute a set a.classname=(select b.classname from maxattribute@this2src b where b.objectname='ISSUECURRENTITEM' and b.attributename='GLCREDITACCT')
where a.objectname='ISSUECURRENTITEM' and a.attributename='GLCREDITACCT';

update maxattributecfg a set a.classname=(select b.classname from maxattributecfg@this2src b where b.objectname='ISSUECURRENTITEM' and b.attributename='GLCREDITACCT')
where a.objectname='ISSUECURRENTITEM' and a.attributename='GLCREDITACCT';


update maxattribute a set a.classname=(select b.classname from maxattribute@this2src b where b.objectname='INVADJUSTMENT' and b.attributename='CONTROLACC')
where a.objectname='INVADJUSTMENT' and a.attributename='CONTROLACC';

update maxattributecfg a set a.classname=(select b.classname from maxattributecfg@this2src b where b.objectname='ISSUECURRENTITEM' and b.attributename='CONTROLACC')
where a.objectname='INVADJUSTMENT' and a.attributename='CONTROLACC';

update maxattribute a set a.classname=(select b.classname from maxattribute@this2src b where b.objectname='INVADJUSTMENT' and b.attributename='SHRINKAGEACC')
where a.objectname='INVADJUSTMENT' and a.attributename='SHRINKAGEACC';

update maxattributecfg a set a.classname=(select b.classname from maxattributecfg@this2src b where b.objectname='ISSUECURRENTITEM' and b.attributename='SHRINKAGEACC')
where a.objectname='INVADJUSTMENT' and a.attributename='SHRINKAGEACC';

update maxattribute a set a.classname=(select b.classname from maxattribute@this2src b where b.objectname='INVBALANCES' and b.attributename='CONTROLACC')
where a.objectname='INVBALANCES' and a.attributename='CONTROLACC';

update maxattributecfg a set a.classname=(select b.classname from maxattributecfg@this2src b where b.objectname='INVBALANCES' and b.attributename='CONTROLACC')
where a.objectname='INVBALANCES' and a.attributename='CONTROLACC';


update maxattribute a set a.classname=(select b.classname from maxattribute@this2src b where b.objectname='INVBALANCES' and b.attributename='SHRINKAGEACC')
where a.objectname='INVBALANCES' and a.attributename='SHRINKAGEACC';

update maxattributecfg a set a.classname=(select b.classname from maxattributecfg@this2src b where b.objectname='INVBALANCES' and b.attributename='SHRINKAGEACC')
where a.objectname='INVBALANCES' and a.attributename='SHRINKAGEACC';

update maxattribute a set a.classname=(select b.classname from maxattribute@this2src b where b.objectname='INVBALANCES' and b.attributename='CONTROLACCOUNT')
where a.objectname='INVBALANCES' and a.attributename='CONTROLACCOUNT';

update maxattributecfg a set a.classname=(select b.classname from maxattributecfg@this2src b where b.objectname='INVBALANCES' and b.attributename='CONTROLACCOUNT')
where a.objectname='INVBALANCES' and a.attributename='CONTROLACCOUNT';

update maxattribute a set a.classname=(select b.classname from maxattribute@this2src b where b.objectname='INVCOST' and b.attributename='INVCOSTADJACCOUNT')
where a.objectname='INVCOST' and a.attributename='INVCOSTADJACCOUNT';

update maxattributecfg a set a.classname=(select b.classname from maxattributecfg@this2src b where b.objectname='INVCOST' and b.attributename='INVCOSTADJACCOUNT')
where a.objectname='INVCOST' and a.attributename='INVCOSTADJACCOUNT';

update maxattribute a set a.classname=(select b.classname from maxattribute@this2src b where b.objectname='MATUSETRANS' and b.attributename='GLCREDITACCT')
where a.objectname='MATUSETRANS' and a.attributename='GLCREDITACCT';

update maxattributecfg a set a.classname=(select b.classname from maxattributecfg@this2src b where b.objectname='MATUSETRANS' and b.attributename='GLCREDITACCT')
where a.objectname='MATUSETRANS' and a.attributename='GLCREDITACCT';

update maxattribute a set a.classname=(select b.classname from maxattribute@this2src b where b.objectname='MATUSETRANS' and b.attributename='GLCREDITACCT')
where a.objectname='MATUSETRANS' and a.attributename='GLDEBITACCT';

update maxattributecfg a set a.classname=(select b.classname from maxattributecfg@this2src b where b.objectname='MATUSETRANS' and b.attributename='GLDEBITACCT')
where a.objectname='MATUSETRANS' and a.attributename='GLDEBITACCT';

update maxattribute a set a.classname=(select b.classname from maxattribute@this2src b where b.objectname='MATRECTRANS' and b.attributename='GLCREDITACCT')
where a.objectname='MATRECT RANS' and a.attributename='GLDEBITACCT';

update maxattributecfg a set a.classname=(select b.classname from maxattributecfg@this2src b where b.objectname='MATUSETRANS' and b.attributename='GLDEBITACCT')
where a.objectname='MATRECTRANS' and a.attributename='GLDEBITACCT';

update maxattribute a set a.classname=(select b.classname from maxattribute@this2src b where b.objectname='MATUSETRANS' and b.attributename='GLCREDITACCT')
where a.objectname='MATRECTRANS' and a.attributename='GLCREDITACCT';

update maxattributecfg a set a.classname=(select b.classname from maxattributecfg@this2src b where b.objectname='MATRECTRANS' and b.attributename='GLCREDITACCT')
where a.objectname='MATRECTRANS' and a.attributename='GLCREDITACCT';

---Object level metadata

update maxobjectcfg set classname='psdi.mbo.custapp.CustomMboSet' where objectname='LBL_WOCRAFTVN';
update maxobject      set classname='psdi.mbo.custapp.CustomMboSet' where objectname='LBL_WOCRAFTVN';

update maxobjectcfg set classname='psdi.mbo.custapp.CustomMboSet' where objectname='LBL_WOCRAFTVNHAZ';
update maxobject      set classname='psdi.mbo.custapp.CustomMboSet' where objectname='LBL_WOCRAFTVNHAZ';

update maxobject a set a.classname=(select b.classname from maxobject@this2src b where b.objectname='LBL_TASKVERBNOUN')
where a.objectname='LBL_TASKVERBNOUN' ;
update maxobjectcfg a set a.classname=(select b.classname from maxobject@this2src b where b.objectname='LBL_TASKVERBNOUN')
where a.objectname='LBL_TASKVERBNOUN' ;

update maxobject a set a.classname=(select b.classname from maxobject@this2src b where b.objectname='LBL_CRAFTVN')
where a.objectname='LBL_CRAFTVN' ;
update maxobjectcfg a set a.classname=(select b.classname from maxobject@this2src b where b.objectname='LBL_CRAFTVN')
where a.objectname='LBL_CRAFTVN' ;

update maxobjectcfg set classname='psdi.mbo.custapp.CustomMboSet' where objectname='LBL_CRAFTVNHAZ';
update maxobject      set classname='psdi.mbo.custapp.CustomMboSet' where objectname='LBL_CRAFTVNHAZ';

update maxobjectcfg set classname='psdi.mbo.custapp.CustomMboSet' where objectname='LBL_CRAFTHAZQUAL';
update maxobject      set classname='psdi.mbo.custapp.CustomMboSet' where objectname='LBL_CRAFTHAZQUAL';

update maxobject a set a.classname=(select b.classname from maxobject@this2src b where b.objectname='LBL_SEQUENCE')
where a.objectname='LBL_SEQUENCE' ;
update maxobjectcfg a set a.classname=(select b.classname from maxobject@this2src b where b.objectname='LBL_SEQUENCE')
where a.objectname='LBL_SEQUENCE' ;

update maxobjectcfg set classname='psdi.mbo.custapp.CustomMboSet' where objectname='LBL_SEQUENCE_LOCAT';
update maxobject      set classname='psdi.mbo.custapp.CustomMboSet' where objectname='LBL_SEQUENCE_LOCAT';

------------------

update maxattribute a set a.classname=(select b.classname from maxattribute@this2src b where b.objectname='ASSET' and b.attributename='LBL_KNUMBER')
where a.objectname='ASSET' and a.attributename='LBL_KNUMBER';

update maxattributecfg a set a.classname=(select b.classname from maxattributecfg@this2src b where b.objectname='ASSET' and b.attributename='LBL_KNUMBER')
where a.objectname='ASSET' and a.attributename='LBL_KNUMBER';

update maxattributecfg set classname=null where objectname='LBL_CRAFTHAZQUAL' and attributename='QUALIFICATIONID';
update maxattribute      set classname=null where objectname='LBL_CRAFTHAZQUAL' and attributename='QUALIFICATIONID';

update maxattributecfg set classname=null where objectname='LBL_CRAFTVNHAZ' and attributename='HAZARDID';
update maxattribute      set classname=null where objectname='LBL_CRAFTVNHAZ' and attributename='HAZARDID';

update maxattributecfg set classname=null where objectname='LBL_CRAFTVN' and attributename='TASKVERB';
update maxattribute      set classname=null where objectname='LBL_CRAFTVN' and attributename='TASKVERB';

update maxattributecfg set classname=null where objectname='LBL_TASKVERBNOUN' and attributename='DESCRIPTION';
update maxattribute      set classname=null where objectname='LBL_TASKVERBNOUN' and attributename='DESCRIPTION';

update maxattributecfg set classname=null where objectname='LBL_TASKVERBNOUN' and attributename='TYPE';
update maxattribute      set classname=null where objectname='LBL_TASKVERBNOUN' and attributename='TYPE';

update maxattributecfg set classname=null where objectname='LBL_WOCRAFTVN' and attributename='LBL_CRAFTVNID';
update maxattribute      set classname=null where objectname='LBL_WOCRAFTVN' and attributename='LBL_CRAFTVNID';

--- create table domains

delete from maxdomain where domainid in ('LBL_GLACCOUNT_LKUP','LBL_PROJACT_LOOKUP');

insert into maxdomain (domainid, description, domaintype, maxdomainid,
internal, nevercache) select a.domainid, a.description, a.domaintype,
maxdomainseq.NEXTVAL, a.internal, a.nevercache from maxdomain@this2src  a where a.domainid='LBL_GLACCOUNT_LKUP';

insert into maxdomain (domainid, description, domaintype, maxdomainid,
internal, nevercache) select a.domainid, a.description, a.domaintype,
maxdomainseq.NEXTVAL, a.internal, a.nevercache from maxdomain@this2src  a where a.domainid='LBL_PROJACT_LOOKUP';

delete from maxtabledomain where domainid in ('LBL_GLACCOUNT_LKUP','LBL_PROJACT_LOOKUP');

insert into maxtabledomain (domainid, validtnwhereclause, listwhereclause,
errorresourcbundle, erroraccesskey, maxtabledomainid,
objectname)
 select a.domainid, a.validtnwhereclause, a.listwhereclause,
a.errorresourcbundle, a.erroraccesskey, maxtabledomainseq.NEXTVAL, a.objectname
from maxtabledomain@this2src a where a.domainid='LBL_GLACCOUNT_LKUP';

insert into maxtabledomain (domainid, validtnwhereclause, listwhereclause,
errorresourcbundle, erroraccesskey, maxtabledomainid,
objectname)
 select a.domainid, a.validtnwhereclause, a.listwhereclause,
a.errorresourcbundle, a.erroraccesskey, maxtabledomainseq.NEXTVAL, a.objectname
from maxtabledomain@this2src a where a.domainid='LBL_PROJACT_LOOKUP';
----



delete from securityrestrict where app='LBL_WO';

insert into securityrestrict
(app,conditionnum, objectname, reevaluate,
restriction, securityrestrictid,
srestrictnum, type) select
a.app,a.conditionnum, a.objectname, a.reevaluate,
a.restriction, securityrestrictseq.NEXTVAL,
a.srestrictnum, a.type
from SECURITYRESTRICT@this2src a where app='LBL_WO';


---------

Insert into MAXMENU
(MENUTYPE, MODULEAPP, POSITION, SUBPOSITION, ELEMENTTYPE, KEYVALUE,     VISIBLE, MAXMENUID)
values
('MODULE', 'SETUP',     10041,          53,     'APP',  'LBL_TASKVN', 1, MAXMENUSEQ.NEXTVAL);

insert into MAXMENU
(MENUTYPE, MODULEAPP, POSITION, SUBPOSITION, ELEMENTTYPE, KEYVALUE, VISIBLE, IMAGE, TABDISPLAY, MAXMENUID)
values
('MODULE','INVENTOR',10610,0,'APP','INVISSUE',1,'appimg_invissue.gif','MAIN',MAXMENUSEQ.NEXTVAL);


delete from maxrelationship where name in ('LBL_CRAFTVNHAZ_REL','LBL_WOCRAFTVNHAZ_REL');

insert into maxrelationship (name, parent, child, whereclause, maxrelationshipid, remarks) 
values ('LBL_CRAFTVNHAZ_REL','LBL_WOCRAFTVN','LBL_CRAFTVNHAZ',':LBL_CRAFTVNID = LBL_CRAFTVNID',maxrelationshipseq.NEXTVAL, null);


insert into maxrelationship (name, parent, child, whereclause, maxrelationshipid, remarks) 
values ('LBL_WOCRAFTVNHAZ_REL','LBL_WOCRAFTVN','LBL_WOCRAFTVNHAZ',':LBL_CRAFTVNID = LBL_CRAFTVNID and :wonum = wonum',maxrelationshipseq.NEXTVAL, null);




commit;

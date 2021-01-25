--**********************************************
-- Changes related to Warehouse feeder
-- Required for MAXIMO 6.2.6 ro 7.6.0.1
--**********************************************


update maxobjectcfg set classname='psdi.mbo.custapp.CustomMboSet' where objectname='LBL_WRHSFEEDDEF';
update maxobject    set classname='psdi.mbo.custapp.CustomMboSet' where objectname='LBL_WRHSFEEDDEF'; 

update maxattributecfg set classname=null where objectname='LBL_WRHSFEEDDEF' and 
attributename in ('FEEDER_ID','RATE_PER_SQFT','RATE_PER_VAULT','EFFDT','MIN_DAYS_RECHARGE');

update maxattribute set classname=null where objectname='LBL_WRHSFEEDDEF' and 
attributename in ('FEEDER_ID','RATE_PER_SQFT','RATE_PER_VAULT','EFFDT','MIN_DAYS_RECHARGE');


update maxobjectcfg set classname='psdi.mbo.custapp.CustomMboSet' where objectname='LBL_WRHSFEEDDTL';
update maxobject    set classname='psdi.mbo.custapp.CustomMboSet' where objectname='LBL_WRHSFEEDDTL'; 

update maxattributecfg set classname=null where objectname='LBL_WRHSFEEDDTL' and 
attributename in ('DATE_RECEIVED','DATE_RETURNED','SQ_FT_USED','LBL_ORG_LEVEL_1');

update maxattribute set classname=null where objectname='LBL_WRHSFEEDDTL' and 
attributename in ('DATE_RECEIVED','DATE_RETURNED','SQ_FT_USED','LBL_ORG_LEVEL_1');

update maxattributecfg set classname='psdi.app.person.FldPersonID' where objectname='LBL_WRHSFEEDDTL' and 
attributename in ('CONSIGNORID','OWNERID');

update maxattribute    set classname='psdi.app.person.FldPersonID' where objectname='LBL_WRHSFEEDDTL' and 
attributename in ('CONSIGNORID','OWNERID');

update maxattributecfg set classname='psdi.app.financial.FldPartialGLAccount' where objectname='LBL_WRHSFEEDDTL' and 
attributename in ('PROJ_ACT_ID');

update maxattribute    set classname='psdi.app.financial.FldPartialGLAccount' where objectname='LBL_WRHSFEEDDTL' and 
attributename in ('PROJ_ACT_ID');

----------------
update maxattributecfg set classname='psdi.app.financial.FldPartialGLAccount' where objectname='LBL_WRHSFEEDDEF' and 
attributename in ('DROP_PROJ_ACT_ID','DEF_PROJ_ACT_ID');

update maxattribute    set classname='psdi.app.financial.FldPartialGLAccount' where objectname='LBL_WRHSFEEDDEF' and 
attributename in ('DROP_PROJ_ACT_ID','DEF_PROJ_ACT_ID');
----------------





update maxattributecfg set classname='psdi.app.financial.FldPartialGLAccount' where objectname='LBL_WRHSFEEDDEF' and 
attributename in ('GLDEBITACCT','GLCREDITACCT');

update maxattribute set classname='psdi.app.financial.FldPartialGLAccount' where objectname='LBL_WRHSFEEDDEF' and 
attributename in ('GLDEBITACCT','GLCREDITACCT');



update maxattributecfg    set sameasobject=null, sameasattribute =null, classname=null, domainid='LBL_UOM'  where objectname='LBL_WRHSFEEDDTL' and 
attributename in ('UNITOFMEASURE');

update maxattribute    set sameasobject=null, sameasattribute =null,classname=null, domainid='LBL_UOM'   where objectname='LBL_WRHSFEEDDTL' and 
attributename in ('UNITOFMEASURE');

delete from maxdomain where domainid='LBL_UOM';

delete from maxtabledomain where domainid='LBL_UOM';

insert into maxdomain(domainid, description, domaintype,internal,
nevercache,maxdomainid) values
('LBL_UOM','LBNL Unit of measure','TABLE',0,
0,maxdomainseq.NEXTVAL);

insert into maxtabledomain(domainid, listwhereclause,
validtnwhereclause,errorresourcbundle, erroraccesskey,
maxtabledomainid, objectname) values
('LBL_UOM','1=1',
 'measureunitid=:unitofmeasure', 'lbl_wrhsfeed','lbl_invaliduom',
maxtabledomainseq.NEXTVAL,'MEASUREUNIT');

delete measureunit where orgid is null and measureunitid in ('EA','FT','GB','GPM','HP','KW','OZ','PH','PSIG');

update measureunit set orgid='LBNL', siteid='FAC';
 
commit;


------------ data change -------------
update LBL_WRHSFEEDHDR a set  a.feeder_id='STR';

update LBL_WRHSFEEDDTL a set a.feeder_id='STR';

update lbl_wrhsfeeddef a set a.feeder_id='STR';

commit;


update sigoption set description='Save Record'  where app='LBLWRHSDEF' and optionname='SAVE';

update sigoption set description='Delete Record'  where app='LBLWRHSDEF' and optionname='DELETE';

update sigoption set description='Read access to Record'  where app='LBLWRHSDEF' and optionname='READ';


delete from maxmenu where moduleapp='LBLWRHSDEF' and keyvalue in ('MANAGELIB','MANAGEFOLD','ASSOCFOLD','DUPLICATE','INSERT','CREATEKPI','DELETE');


---
delete from maxlookupmap where lookupattr='LBL_ORG_LEVEL_1' and target='LBL_WRHSFEEDDTL';

delete from maxlookupmap where lookupattr='UNITOFMEASURE' and target='LBL_WRHSFEEDDTL';


insert into maxlookupmap (allownull, lookupattr,
maxlookupmapid, seqnum, source, sourcekey, target,
targetattr) values (1, 'LBL_ORG_LEVEL_1',
maxlookupmapseq.NEXTVAL,1,'CRAFT','LBL_ORG_LEVEL_1','LBL_WRHSFEEDDTL',
'LBL_ORG_LEVEL_1');

insert into maxlookupmap (allownull, lookupattr,
maxlookupmapid, seqnum, source, sourcekey, target,
targetattr) values (1, 'UNITOFMEASURE',
maxlookupmapseq.NEXTVAL,1,'MEASUREUNIT','MEASUREUNITID','LBL_WRHSFEEDDTL',
'UNITOFMEASURE');

commit;

------------- 

update maxmessages set value='Project/Activity id should not be null.' where msgkey='lbl_glaccountnull' and msggroup='workorder';

update maxmessages set value='Sq/Ft used should be > 0.' where msgkey='lbl_invalidsqftused';

commit;


delete from sigoption where app='LBLWRHSDTL' and optionname not in 
('BOOKMARK','CLEAR','FIELDDEFS','NEXT','PREVIOUS','READ','SAVE','SEARCHBOOK',
 'SEARCHTIPS','SEARCHSQRY','SEARCHMORE','BMXVIEWMANAGEWHER','BMXVIEWMANAGEWHERRO',
 'RUNREPORTS','SEARCHVMQR','SEARCHWHER' );
 
commit;



update sigoption set description='Next Record'     where app='LBLWRHSDTL' and optionname='NEXT';
update sigoption set description='Previous Record' where app='LBLWRHSDTL' and optionname='PREVIOUS';
update sigoption set description='Read access to record' where app='LBLWRHSDTL' and optionname='READ';
update sigoption set description='Save Record'     where app='LBLWRHSDTL' and optionname='SAVE';



commit;




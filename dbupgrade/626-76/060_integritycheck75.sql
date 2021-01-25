--create table maxattribute_140521 as select * from maxattribute;

--create table maxattributecfg_140521 as select * from maxattributecfg;



delete maxvars  where varname='LBL_WOLENGTH';

update  maxobject set eauditenabled=0 where objectname in ('LBL_WKTHRUHAZ',
'LBL_WOWKTHRUFEEDBK','LBL_MAILSTOP','LBL_WOWKTHRUHAZ');

update  maxobjectcfg set eauditenabled=0 where objectname in ('LBL_WKTHRUHAZ',
'LBL_WOWKTHRUFEEDBK','LBL_MAILSTOP','LBL_WOWKTHRUHAZ');
;

delete from maxattribute where objectname='INBOUNDCOMM' and attributename='DESCRIPTION_LONGDESCRIPTION';

delete from maxattributecfg where objectname='INBOUNDCOMM' and attributename='DESCRIPTION_LONGDESCRIPTION';

delete from maxattribute where objectname='LBL_WOWKTHRUFEEDBK' and attributename='DESCRIPTION_LONGDESCRIPTION';

delete from maxattributecfg where objectname='LBL_WOWKTHRUFEEDBK' and attributename='DESCRIPTION_LONGDESCRIPTION';

delete from maxattribute where objectname='LBL_WOWKTHRUMAT' and attributename='DESCRIPTION_LONGDESCRIPTION';

delete from maxattributecfg where objectname='LBL_WOWKTHRUMAT' and attributename='DESCRIPTION_LONGDESCRIPTION';

delete from maxattribute where objectname='LBL_WRHSFEEDHDR' and attributename='DESCRIPTION_LONGDESCRIPTION';

delete from maxattributecfg where objectname='LBL_WRHSFEEDHDR' and attributename='DESCRIPTION_LONGDESCRIPTION';

update maxattribute    set isldowner=0 where objectname='LBL_BOBSYSTEM' and attributename='DESCRIPTION';

update maxattributecfg set isldowner=0 where objectname='LBL_BOBSYSTEM' and attributename='DESCRIPTION';

update maxattribute    set isldowner=0 where objectname='MXGLTXN' ;

update maxattributecfg set isldowner=0 where objectname='MXGLTXN' ;

update maxattribute    set isldowner=0 where objectname='REASSIGNWF' ;

update maxattributecfg set isldowner=0 where objectname='REASSIGNWF' ;

update maxattribute    set isldowner=0 where objectname='SHOWWFWAIT' ;

update maxattributecfg set isldowner=0 where objectname='SHOWWFWAIT' ;

update maxattribute    set isldowner=0 where objectname='WOGENFORECAST' and attributename='DESCRIPTION' ;

update maxattributecfg set isldowner=0 where objectname='WOGENFORECAST' and attributename='DESCRIPTION';

update maxattribute    set defaultvalue=0 where objectname='INVENTORY' and attributename in ('IL5','IL6');

update maxattributecfg set defaultvalue=0 where objectname='INVENTORY' and attributename in ('IL5','IL6');

update maxattribute    set defaultvalue=0 where objectname='TOOLINV' and attributename in ('IL5','IL6');

update maxattributecfg set defaultvalue=0 where objectname='TOOLINV' and attributename in ('IL5','IL6');

update maxattribute    set isldowner=0 where objectname='LBL_LETSTRANS' and attributename='DESCRIPTION';

update maxattributecfg set isldowner=0 where objectname='LBL_LETSTRANS' and attributename='DESCRIPTION';

update maxattribute set length=31 where objectname in ('CONTLEASEENDASST') and attributename='GLACCT';

update maxattributecfg set length=31 where objectname in ('CONTLEASEENDASST') and attributename='GLACCT';

update maxattributecfg set sameasobject=null where objectname in ('PROPERTYLOOKUPLIST','YORNLOOKUPLIST');


commit;


-- Added in 2nd pass

alter table A_LBL_WORKORDEREXT modify  (WO1_PHONE varchar2(37));

update maxattribute       set maxtype='DECIMAL' where objectname='ISSUEITEMTOASSET' and attributename='UNITCOST';

update maxattributecfg    set maxtype='DECIMAL' where objectname='ISSUEITEMTOASSET' and attributename='UNITCOST';


commit;

alter table LBL_WORKORDEREXT modify  (WO1_PHONE varchar2(37));

alter table mr modify  (PHONE varchar2(37));

alter table phone modify  (PHONENUM varchar2(37));

alter table ticket  modify  (AFFECTEDPHONE varchar2(37));

alter table ticket  modify  (REPORTEDPHONE varchar2(37));

alter table workorder  modify  (phone varchar2(37));



alter table lbl_auth_release modify (building_number varchar2(21));

alter table a_lbl_auth_release modify (building_number varchar2(21));

--alter table a_workorder6 modify (wo1 varchar2(62));

--alter table worklog modify (createby varchar2(50));

--alter table worklog modify (modifyby  varchar2(50));

update maxattributecfg set length=20 where objectname='COMPCONTACT' and ATTRIBUTENAME='HOMEPHONE';

update maxattribute set length=20 where objectname='COMPCONTACT' and ATTRIBUTENAME='HOMEPHONE';

commit;

alter table COMPCONTACT modify (HOMEPHONE varchar2(20));
--

update maxattributecfg set length=10 where objectname='CONTRACTLINE' and ATTRIBUTENAME='PRNUM';

update maxattribute set length=10 where objectname='CONTRACTLINE' and ATTRIBUTENAME='PRNUM';

commit;

--alter table CONTRACTLINE modify (PRNUM varchar2(10));
---



update maxattributecfg set length=21 where objectname='INVOICECOST' and ATTRIBUTENAME='LOCATIONNONPER';

update maxattribute set length=21 where objectname='INVOICECOST' and ATTRIBUTENAME='LOCATIONNONPER';

commit;

--alter table INVOICECOST modify (LOCATIONNONPER varchar2(21));
----

update maxattributecfg set length=10 where objectname='LEASEVIEWLINE' and ATTRIBUTENAME='PRNUM';

update maxattribute set length=10 where objectname='LEASEVIEWLINE' and ATTRIBUTENAME='PRNUM';

commit;

--alter table LEASEVIEWLINE modify (PRNUM varchar2(10));
-------
update maxattributecfg set length=18 where objectname='LOCATIONS' and ATTRIBUTENAME='ITEMNUM';

update maxattribute set length=18 where objectname='LOCATIONS' and ATTRIBUTENAME='ITEMNUM';

commit;

-- alter table LOCATIONS modify (ITEMNUM varchar2(18));
-------
update maxattributecfg set length=18 where objectname='SEARCHDR' and ATTRIBUTENAME='ITEMNUM';

update maxattribute set length=18 where objectname='SEARCHDR' and ATTRIBUTENAME='ITEMNUM';

commit;

--alter table SEARCHDR modify (ITEMNUM varchar2(18));
-------


-- From IBM support 
Update maxattribute Set primarykeycolseq=null Where objectname='ALNDOMAIN';
;
Update maxattribute Set primarykeycolseq=1 Where objectname='ALNDOMAIN' And attributename='DOMAINID'
;
Update maxattribute Set primarykeycolseq=2 Where objectname='ALNDOMAIN' And attributename='VALUE'
;
Update maxattribute Set primarykeycolseq=3 Where objectname='ALNDOMAIN' And attributename='SITEID'
;
Update maxattribute Set primarykeycolseq=4 Where objectname='ALNDOMAIN' And attributename='ORGID'
;

-- From IBM support 
Update maxattributecfg Set primarykeycolseq=null Where objectname='ALNDOMAIN';
;
Update maxattributecfg Set primarykeycolseq=1 Where objectname='ALNDOMAIN' And attributename='DOMAINID'
;
Update maxattributecfg Set primarykeycolseq=2 Where objectname='ALNDOMAIN' And attributename='VALUE'
;
Update maxattributecfg Set primarykeycolseq=3 Where objectname='ALNDOMAIN' And attributename='SITEID'
;
Update maxattributecfg Set primarykeycolseq=4 Where objectname='ALNDOMAIN' And attributename='ORGID'
;

Commit;




update maxattribute  set 
sameasattribute=null, sameasobject=null
where objectname='COMPCONTACTMSTR' and attributename='HOMEPHONE';

update maxattribute  set 
sameasattribute=null, sameasobject=null
where objectname='A_WORKORDER6' and attributename='WO1';

update maxattributecfg  set 
sameasattribute=null, sameasobject=null
where objectname='COMPCONTACTMSTR' and attributename='HOMEPHONE';

update maxattributecfg  set 
sameasattribute=null, sameasobject=null
where objectname='A_WORKORDER6' and attributename='WO1';

commit;

alter table a_workorder6 modify wo1 varchar2(62);



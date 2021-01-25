
update CRONTASKINSTANCE set runasuserid='IT-BS-MXINTADM' where runasuserid  in ('MAXADMIN','SYSADM');

update CLASSSTRUCTURE set GENASSETDESC=0;


update maxmessages set value='LDAP Password:'  where msggroup='login' and msgkey='password';

update maxmessages set value='LDAP User Name:'  where msggroup='login' and msgkey='username';

commit;

grant select on lbl_v_coa to public;

grant select on lbl_v_projact to public;

grant select on lbl_v_gl to public;

update synonymdomain set description='Waiting to be scheduled(IBM)' where domainid='WOSTATUS' and maxvalue='WSCH';

update synonymdomain set description='Waiting to be scheduled(LBNL)' where domainid='WOSTATUS' and maxvalue='WSCH1';

commit;





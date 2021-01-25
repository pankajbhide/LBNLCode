

create table lbl_maxuser as select * from maxuser;

update maxuser set status='INACTIVE' where loginid not in ('PBhide','PMuramalla','IT-BS-MXINTADM','ALeung',
'CPeach','TLThompson','BWSimpson','MAWoods');


commit;



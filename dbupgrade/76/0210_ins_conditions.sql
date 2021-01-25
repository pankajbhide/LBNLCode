

-- Need db link this2src

drop database link this2src;

create database link this2src connect to maximo identified by allset2g using 'mmo7dev';

delete from condition where conditionnum like 'LBL%';


insert into condition(conditionid, conditionnum, description,
 expression, type,
 nocaching )  select conditionseq.NEXTVAL, a.conditionnum, a.description,
 a.expression, a.type, a. nocaching from maximo.condition@this2src  a
 where a.conditionnum like 'LBL%';
 
 commit;


delete from MAXATTRIBUTESKIPCOPY;

insert into MAXATTRIBUTESKIPCOPY
(objectname, attributename, maxattributeskipcopyid) select 
a.objectname, a.attributename,MAXATTRIBUTESKIPCOPYseq.NEXTVAL from
 MAXATTRIBUTESKIPCOPY@this2src a;

commit;




--create database link this2qa connect to maximo identified by allset7q using 'mmo7qa';


create table lbl_doctypes as select * from doctypes;

delete from doctypes;

insert into doctypes select * from doctypes@this2src;

commit;

create table lbl_docinfo as select * from docinfo;

update docinfo
set urlname= '/apps/mxes' || substr(urlname,length('/apps/mxes/bears/bea9/user_projects/domains/MXServer/'))
where urlname like '/apps/mxes/bears/bea9/user_projects/domains/MXServer/%';

UPDATE DOCINFO
   set urlname= '/apps/mxes' || urlname
where 
   URLNAME LIKE '/DOCLINKS%';

UPDATE DOCINFO 
   SET URLNAME = '/apps/mxes/DOCLINKS/MANUALS/GreenheckVektorMDMay2007.pdf' 
WHERE docinfoid = 39;

UPDATE DOCINFO 
   SET urlname = REPLACE(urlname, '\', '/')
where 
   urlname like '/apps/mxes/DOCLINKS/FAP\%';


commit;

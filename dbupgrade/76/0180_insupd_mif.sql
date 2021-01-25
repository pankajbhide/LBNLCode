


delete from billtoshipto;

insert into billtoshipto (addresscode,shiptocontact,
billtocontact,billtoshiptoid,
billtodefault,billto,
orgid,shiptodefault,
siteid,shipto) values
('BILLTO','813149',
 '813149',billtoshiptoseq.nextval,
 1,1,
 'LBNL',1,
 'FAC',1);
 
 
 
 
 insert into billtoshipto (addresscode,shiptocontact,
billtocontact,billtoshiptoid,
billtodefault,billto,
orgid,shiptodefault,
siteid,shipto) values
('069','813149',
 '813149',billtoshiptoseq.nextval,
 0,1,
 'LBNL',0,
 'FAC',1);
 
 
 
 insert into billtoshipto (addresscode,shiptocontact,
billtocontact,billtoshiptoid,
billtodefault,billto,
orgid,shiptodefault,
siteid,shipto) values
('078','813149',
 '813149',billtoshiptoseq.nextval,
 0,1,
 'LBNL',0,
 'FAC',1);
 
 
 insert into billtoshipto (addresscode,shiptocontact,
billtocontact,billtoshiptoid,
billtodefault,billto,
orgid,shiptodefault,
siteid,shipto) values
('079','813149',
 '813149',billtoshiptoseq.nextval,
 0,1,
 'LBNL',0,
 'FAC',1);
 
  insert into billtoshipto (addresscode,shiptocontact,
billtocontact,billtoshiptoid,
billtodefault,billto,
orgid,shiptodefault,
siteid,shipto) values
('903','813149',
 '813149',billtoshiptoseq.nextval,
 0,1,
 'LBNL',0,
 'FAC',1);
 
 
  insert into billtoshipto (addresscode,shiptocontact,
billtocontact,billtoshiptoid,
billtodefault,billto,
orgid,shiptodefault,
siteid,shipto) values
('079-0101','813149',
 '813149',billtoshiptoseq.nextval,
 0,1,
 'LBNL',0,
 'FAC',1);
 
insert into billtoshipto (addresscode,shiptocontact,
billtocontact,billtoshiptoid,
billtodefault,billto,
orgid,shiptodefault,
siteid,shipto) values
('069-0150','813149',
 '813149',billtoshiptoseq.nextval,
 1,1,
 'LBNL',1,
 'FAC',1);
 
insert into billtoshipto (addresscode,shiptocontact,
billtocontact,billtoshiptoid,
billtodefault,billto,
orgid,shiptodefault,
siteid,shipto) values
('904','813149',
 '813149',billtoshiptoseq.nextval,
 1,1,
 'LBNL',1,
 'FAC',1);
 
 
 

delete from  maxdomain where domainid='LBL_BUYER_ID';

insert into maxdomain (domainid, description, domaintype, length,
maxdomainid, maxtype, scale, internal) values
('LBL_BUYER_ID','List of Valid Buyers','ALN',25,
 maxdomainseq.NEXTVAL, 'ALN',0,0);
 
delete from alndomain where domainid='LBL_BUYER_ID';

insert into alndomain(domainid, value, alndomainid, description, 
valueid) values
('LBL_BUYER_ID','BCRAIG', alndomainseq.NEXTVAL,'BCRAIG',
 'BUYER_ID|BCRAIG');
 
insert into alndomain(domainid, value, alndomainid, description, 
valueid) values
('LBL_BUYER_ID','GLGOODMAN', alndomainseq.NEXTVAL,'GLGOODMAN',
 'BUYER_ID|GLGOODMAN');
 
 insert into alndomain(domainid, value, alndomainid, description, 
valueid) values
('LBL_BUYER_ID','BWSIMPSON', alndomainseq.NEXTVAL,'BWSIMPSON',
 'BUYER_ID|BWSIMPSON');
 
 insert into alndomain(domainid, value, alndomainid, description, 
valueid) values
('LBL_BUYER_ID','MISUNCHOI', alndomainseq.NEXTVAL,'MISUNCHOI',
 'BUYER_ID|MISUNCHOI');
 
 
  insert into alndomain(domainid, value, alndomainid, description, 
valueid) values
('LBL_BUYER_ID','SBONNER', alndomainseq.NEXTVAL,'SBONNER',
 'BUYER_ID|MISUNCHOI');
 

 
delete from maxlookupmap where target='PR' and targetattr='LBL_REQUESTEDBY';


insert into maxlookupmap (allownull, lookupattr, maxlookupmapid,
seqnum, source, sourcekey, target,targetattr) values
(1,'LBL_REQUESTEDBY', maxlookupmapseq.NEXTVAL,
1,'ALNDOMAIN', 'VALUE', 'PR', 'LBL_REQUESTEDBY');
 commit;

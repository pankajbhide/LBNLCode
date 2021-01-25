

delete from maxprop where propname in ('lbl.MX_RECEIPT','lbl.MX_VOUCHER',
'lbl.lbl_default_psnode','mxe.int.webappurl','mxe.lbl_restfulurl');

insert into maxprop (
changeby,changedate, description,encrypted,
globalonly,instanceonly,liverefresh,
maxpropid, maxtype,nullsallowed,
onlinechanges, propname,
securelevel,userdefined,masked,
accesstype) 
values
('PBHIDE',sysdate, 'LBNL URL for Restful service',0,
 0,0,1,
 maxpropseq.NEXTVAL,'ALN',1,
 1, 'mxe.lbl_restfulurl',
 'SECURE',1,0,
 2);


insert into maxprop (
changeby,changedate, description,encrypted,
globalonly,instanceonly,liverefresh,
maxpropid, maxtype,nullsallowed,
onlinechanges, propname,
securelevel,userdefined,masked,
accesstype) 
values
('PBHIDE',sysdate, 'LBNL MX_RECEIPT service Name',0,
 0,0,1,
 maxpropseq.NEXTVAL,'ALN',1,
 1, 'lbl.MX_RECEIPT',
 'SECURE',1,0,
 2);
 
insert into maxprop (
changeby,changedate, description,encrypted,
globalonly,instanceonly,liverefresh,
maxpropid, maxtype,nullsallowed,
onlinechanges, propname,
securelevel,userdefined,masked,
accesstype) 
values
('PBHIDE',sysdate, 'LBNL MX_VOUCHER Service Name',0,
 0,0,1,
 maxpropseq.NEXTVAL,'ALN',1,
 1, 'lbl.MX_VOUCHER',
 'SECURE',1,0,
 2); 
 
insert into maxprop (
changeby,changedate, description,encrypted,
globalonly,instanceonly,liverefresh,
maxpropid, maxtype,nullsallowed,
onlinechanges, propname,
securelevel,userdefined,masked,
accesstype) 
values
('PBHIDE',sysdate, 'LBNL PS-FMS Node',0,
 0,0,1,
 maxpropseq.NEXTVAL,'ALN',1,
 1, 'lbl.lbl_default_psnode',
 'SECURE',1,0,
 2); 

insert into maxprop (
changeby,changedate, description,encrypted,
globalonly,instanceonly,liverefresh,
maxpropid, maxtype,nullsallowed,
onlinechanges, propname,
securelevel,userdefined,masked,
accesstype) 
values
('PBHIDE',sysdate, 'Integration Web Application URL',0,
 0,0,1,
 maxpropseq.NEXTVAL,'ALN',1,
 1, 'mxe.int.webappurl',
 'SECURE',1,0,
 2); 



delete from maxpropvalue where propname in ('lbl.MX_RECEIPT','lbl.MX_VOUCHER',
'lbl.lbl_default_psnode','mxe.lbl_restfulurl');

insert into maxpropvalue (
changeby, changedate, maxpropvalueid,
propname, propvalue, servername,
accesstype) values
('PBHIDE',sysdate, maxpropvalueseq.NEXTVAL,
 'lbl.MX_RECEIPT','MX_RECEIPT','COMMON',
 2);

insert into maxpropvalue (
changeby, changedate, maxpropvalueid,
propname, propvalue, servername,
accesstype) values
('PBHIDE',sysdate, maxpropvalueseq.NEXTVAL,
 'lbl.MX_VOUCHER','MX_VOUCHER','COMMON',
 2);

insert into maxpropvalue (
changeby, changedate, maxpropvalueid,
propname, propvalue, servername,
accesstype) values
('PBHIDE',sysdate, maxpropvalueseq.NEXTVAL,
 'lbl.lbl_default_psnode','PSFT_EP','COMMON',
 2);

insert into maxpropvalue (
changeby, changedate, maxpropvalueid,
propname, propvalue, servername,
accesstype) values
('PBHIDE',sysdate, maxpropvalueseq.NEXTVAL,
 'mxe.lbl_restfulurl','https://maximo.lbl.gov/maxrest/rest','COMMON',
 2);

commit;

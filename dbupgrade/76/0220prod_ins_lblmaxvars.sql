drop public synonym lbl_maxvars;


delete  from lbl_maxvars where varname in 
('INV_ROTATE_DAY','WCLOSE_CLOSE_DAYS',
 'WO_FEEDBACK_WHERE', 
 'WO_ACKNOTIFY_LASTDATE','APPLICATION_ENV', 
 'TEST_USER_ID', 'WO_FEEDBACK_URL', 'WO_ACKNOWLEDGE_WHERE', 
 'WO_ACKNOTIFY_STARTDATE','WRC_MANAGERS_EMAIL','PLANTOPS_MANAGERS_EMAIL',
 'WO_VISIBILITY', 'WOFEEDBACK_EMAIL_SENT_DATE', 'WOFEEDBACK_EMAIL_LIST',
 'WOFEEDBACK_MIN_THRESHOLD',
 'TAWDHELP_URL', 'FACWPC_EMAIL','LBL_WKTRHULENGTH',
 'LBL_WOLENGTH','LAST_WOREQ_NUM','LOCKSHOP_SUPERVISOR','RADIOSHOP_SUPERVISOR',
 'WOREQ_TRANSP_<250_LEADCRAFT','WOREQ_TRANSP_<250_SUPERVISOR',
 'WOREQ_TRANSP_>250_LEADCRAFT','WOREQ_TRANSP_>250_SUPERVISOR',
 'FRST_WO_APPR_DT','STR03_FEEDER_NAME',
 'WOREQ_PEOPLE_LEADCRAFT','WOREQ_PEOPLE_SUPERVISOR',
 'WOREQ_CONF_TABLES_SUPERVISOR','WOREQ_CONF_TABLES_LEADCRAFT',
 'WOREQ_CONF_NON_TABLES_SUPERVISOR','WOREQ_CONF_NON_TABLES_LEADCRAFT',
 'WOREQ_CUSTODIAL_LEADCRAFT','WOREQ_CUSTODIAL_SUPERVISOR',
 'LAST_MONTHLY_ACTUALS_TO_MAXIMO','HAZARDID','PRECAUTIONID','WOREL_URL',
 'INACTIVEAUTH_NOTIFY','ALLOWABLE_CATS_STATUS','MAX2CATSIFACE_NOTIFY',
 'MAXWO2FMS_DTTM', 'FRST_WO_APPR_DT','PROJ_ACT_DELIMITER',
 'PETROVEND2MXES_NOTIFY','PETROVEND2MXES_HTMLFILELOCATION',
 'PET2MAX_MAXMETERFILE','PETROVEND2MXES_TRANSACTFILE',
 'PETROVEND2MXES_LOGDIR','PETROVEND2MXES_DIESELTANK',
 'PETROVEND2MXES_UNLEADEDTANK'
 
  );

insert into lbl_maxvars (description, hasld, lbl_maxvarsid,orgid, siteid, varname,
varvalue)
 SELECT 'ID of Petrovend Unleaded tank',0, lbl_maxvarsidseq.NEXTVAL,
'LBNL','FAC', varname, varvalue  
  FROM BATCH_MAXIMO.LBL_MAXVARS 
  WHERE VARNAME = 'PETROVEND2MXES_UNLEADEDTANK';



insert into lbl_maxvars (description, hasld, lbl_maxvarsid,orgid, siteid, varname,
varvalue)
 SELECT 'ID of Petrovend Diesel tank',0, lbl_maxvarsidseq.NEXTVAL,
'LBNL','FAC', varname, varvalue  
  FROM BATCH_MAXIMO.LBL_MAXVARS 
  WHERE VARNAME = 'PETROVEND2MXES_DIESELTANK';

insert into lbl_maxvars (description, hasld, lbl_maxvarsid,orgid, siteid, varname,
varvalue)
 SELECT 'Location of Petrovend log  directory',0, lbl_maxvarsidseq.NEXTVAL,
'LBNL','FAC', varname, varvalue  
  FROM BATCH_MAXIMO.LBL_MAXVARS 
  WHERE VARNAME = 'PETROVEND2MXES_LOGDIR';



insert into lbl_maxvars (description, hasld, lbl_maxvarsid,orgid, siteid, varname,
varvalue)
 SELECT 'Location of Petrovend transaction file',0, lbl_maxvarsidseq.NEXTVAL,
'LBNL','FAC', varname, varvalue  
  FROM BATCH_MAXIMO.LBL_MAXVARS 
  WHERE VARNAME = 'PETROVEND2MXES_TRANSACTFILE';



insert into lbl_maxvars (description, hasld, lbl_maxvarsid,orgid, siteid, varname,
varvalue)
 SELECT 'HTML file for Petrovend report',0, lbl_maxvarsidseq.NEXTVAL,
'LBNL','FAC', varname, varvalue  
  FROM BATCH_MAXIMO.LBL_MAXVARS 
  WHERE VARNAME = 'PETROVEND2MXES_HTMLFILELOCATION';



insert into lbl_maxvars (description, hasld, lbl_maxvarsid,orgid, siteid, varname,
varvalue)
 SELECT 'Location of Petrovend meter file',0, lbl_maxvarsidseq.NEXTVAL,
'LBNL','FAC', varname, varvalue  
  FROM BATCH_MAXIMO.LBL_MAXVARS 
  WHERE VARNAME = 'PET2MAX_MAXMETERFILE';


insert into lbl_maxvars (description, hasld, lbl_maxvarsid,orgid, siteid, varname,
varvalue)
 SELECT 'Notification email for Petrovend',0, lbl_maxvarsidseq.NEXTVAL,
'LBNL','FAC', varname, varvalue  
  FROM BATCH_MAXIMO.LBL_MAXVARS 
  WHERE VARNAME = 'PETROVEND2MXES_NOTIFY';



insert into lbl_maxvars (description, hasld, lbl_maxvarsid,orgid, siteid, varname,
varvalue)
 SELECT 'Last datetime for MAXIMO-FMS interface',0, lbl_maxvarsidseq.NEXTVAL,
'LBNL','FAC', varname, varvalue  
  FROM BATCH_MAXIMO.LBL_MAXVARS 
  WHERE VARNAME = 'MAXWO2FMS_DTTM';


insert into lbl_maxvars (description, hasld, lbl_maxvarsid,orgid, siteid, varname,
varvalue)
 SELECT 'First work order approval date',0, lbl_maxvarsidseq.NEXTVAL,
'LBNL','FAC', varname, varvalue  
  FROM BATCH_MAXIMO.LBL_MAXVARS 
  WHERE VARNAME = 'FRST_WO_APPR_DT';


insert into lbl_maxvars (description, hasld, lbl_maxvarsid,orgid, siteid, varname,
varvalue)
 SELECT 'Delimiter between project and activity',0, lbl_maxvarsidseq.NEXTVAL,
'LBNL','FAC', varname, varvalue  
  FROM BATCH_MAXIMO.LBL_MAXVARS 
  WHERE VARNAME = 'PROJ_ACT_DELIMITER';
  );



insert into lbl_maxvars (description, hasld, lbl_maxvarsid,orgid, siteid, varname,
varvalue) values 
 ('Days to wait until auth is inactivated',0, lbl_maxvarsidseq.NEXTVAL,
'LBNL','FAC', 'INACTIVEAUTH_NOTIFY', '30');

insert into lbl_maxvars (description, hasld, lbl_maxvarsid,orgid, siteid, varname,
varvalue) values 
 ('URL for work release application',0, lbl_maxvarsidseq.NEXTVAL,
'LBNL','FAC', 'WOREL_URL', 'https://worelease.lbl.gov');

insert into lbl_maxvars (description, hasld, lbl_maxvarsid,orgid, siteid, varname,
varvalue) values 
 ('Custodian leadcraft',0, lbl_maxvarsidseq.NEXTVAL,
'LBNL','FAC', 'WOREQ_CUSTODIAL_LEADCRAFT', 'FAOMC');

insert into lbl_maxvars (description, hasld, lbl_maxvarsid,orgid, siteid, varname,
varvalue) values 
 ('Custodial supervisor 1',0, lbl_maxvarsidseq.NEXTVAL,
'LBNL','FAC', 'WOREQ_CUSTODIAL_SUPERVISOR', '558003');


insert into lbl_maxvars (description, hasld, lbl_maxvarsid,orgid, siteid, varname,
varvalue) values 
 ('Conf room non table leadcraft',0, lbl_maxvarsidseq.NEXTVAL,
'LBNL','FAC', 'WOREQ_CONF_NON_TABLES_LEADCRAFT', 'FASSJ');


insert into lbl_maxvars (description, hasld, lbl_maxvarsid,orgid, siteid, varname,
varvalue) values 
 ('Conf room non table supervisor 1',0, lbl_maxvarsidseq.NEXTVAL,
'LBNL','FAC', 'WOREQ_CONF_NON_TABLES_SUPERVISOR', '558003');

insert into lbl_maxvars (description, hasld, lbl_maxvarsid,orgid, siteid, varname,
varvalue) values 
 ('Conf room supervisor 1',0, lbl_maxvarsidseq.NEXTVAL,
'LBNL','FAC', 'WOREQ_CONF_TABLES_SUPERVISOR', '010971');


insert into lbl_maxvars (description, hasld, lbl_maxvarsid,orgid, siteid, varname,
varvalue) values 
 ('Conf room leadcraft',0, lbl_maxvarsidseq.NEXTVAL,
'LBNL','FAC', 'WOREQ_CONF_TABLES_LEADCRAFT', 'FAOMC');



insert into lbl_maxvars (description, hasld, lbl_maxvarsid,orgid, siteid, varname,
varvalue) values 
 ('People move leadcraft 1',0, lbl_maxvarsidseq.NEXTVAL,
'LBNL','FAC', 'WOREQ_PEOPLE_LEADCRAFT', 'FAPLG');


insert into lbl_maxvars (description, hasld, lbl_maxvarsid,orgid, siteid, varname,
varvalue) values 
 ('People move leadcraft 1',0, lbl_maxvarsidseq.NEXTVAL,
'LBNL','FAC', 'WOREQ_PEOPLE_SUPERVISOR', '040029');



insert into lbl_maxvars (description, hasld, lbl_maxvarsid,orgid, siteid, varname,
varvalue) values 
 ('Stores feeder name',0, lbl_maxvarsidseq.NEXTVAL,
'LBNL','FAC', 'STR03_FEEDER_NAME', 'SIS');


insert into lbl_maxvars (description, hasld, lbl_maxvarsid,orgid, siteid, varname,
varvalue) values 
 ('Transportation leadcraft 1',0, lbl_maxvarsidseq.NEXTVAL,
'LBNL','FAC', 'WOREQ_TRANSP_<250_LEADCRAFT', 'FASST');

insert into lbl_maxvars (description, hasld, lbl_maxvarsid,orgid, siteid, varname,
varvalue) values 
 ('Transportation supevisor 1',0, lbl_maxvarsidseq.NEXTVAL,
'LBNL','FAC', 'WOREQ_TRANSP_<250_SUPERVISOR', '010971');


insert into lbl_maxvars (description, hasld, lbl_maxvarsid,orgid, siteid, varname,
varvalue) values 
 ('Transportation leadcraft 1',0, lbl_maxvarsidseq.NEXTVAL,
'LBNL','FAC', 'WOREQ_TRANSP_>250_LEADCRAFT', 'FASST');

insert into lbl_maxvars (description, hasld, lbl_maxvarsid,orgid, siteid, varname,
varvalue) values 
 ('Transportation supevisor 1',0, lbl_maxvarsidseq.NEXTVAL,
'LBNL','FAC', 'WOREQ_TRANSP_>250_SUPERVISOR', '010971');

insert into lbl_maxvars (description, hasld, lbl_maxvarsid,orgid, siteid, varname,
varvalue) values 
 ('Lockshop supervisor',0, lbl_maxvarsidseq.NEXTVAL,
'LBNL','FAC', 'LOCKSHOP_SUPERVISOR', '175351');

insert into lbl_maxvars (description, hasld, lbl_maxvarsid,orgid, siteid, varname,
varvalue) values 
 ('Radioshop supervisor',0, lbl_maxvarsidseq.NEXTVAL,
'LBNL','FAC', 'RADIOSHOP_SUPERVISOR', '651432');


insert into lbl_maxvars (description, hasld, lbl_maxvarsid,orgid, siteid, varname,
varvalue) values 
 ('Length of work order number',0, lbl_maxvarsidseq.NEXTVAL,
'LBNL','FAC', 'LBL_WOLENGTH', '8');


insert into lbl_maxvars (description, hasld, lbl_maxvarsid,orgid, siteid, varname,
varvalue) values
 ('Length of walk through number',0, lbl_maxvarsidseq.NEXTVAL,
'LBNL','FAC', 'LBL_WKTRHULENGTH', '9');


insert into lbl_maxvars (description, hasld, lbl_maxvarsid,orgid, siteid, varname,
varvalue) values
 ('Facilities WPC Email',0, lbl_maxvarsidseq.NEXTVAL,
'LBNL','FAC', 'FACWPC_EMAIL', 'wpc@lbl.gov');

insert into lbl_maxvars (description, hasld, lbl_maxvarsid,orgid, siteid, varname,
varvalue) values
 ('Help URL for TAWD application',0, lbl_maxvarsidseq.NEXTVAL,
'LBNL','FAC', 'TAWDHELP_URL', 'https://tad.lbl.gov/general/tawd_help.aspx');
 
 
insert into lbl_maxvars (description, hasld, lbl_maxvarsid,orgid, siteid, varname,
varvalue)
 SELECT 'Retention days for inventory tables',0, lbl_maxvarsidseq.NEXTVAL,
'LBNL','FAC', varname, varvalue  
  FROM BATCH_MAXIMO.LBL_MAXVARS 
  WHERE VARNAME = 'INV_ROTATE_DAY';


insert into lbl_maxvars (description, hasld, lbl_maxvarsid,orgid, siteid, varname,
varvalue)
 SELECT 'Days between WCLOSE and close',0, lbl_maxvarsidseq.NEXTVAL,
'LBNL','FAC', varname, varvalue  
  FROM BATCH_MAXIMO.LBL_MAXVARS 
  WHERE VARNAME = 'WCLOSE_CLOSE_DAYS';
  

 
insert into lbl_maxvars (description, hasld, lbl_maxvarsid,orgid, siteid, varname,
varvalue)
 SELECT 'Where condition for work order feedback',0, lbl_maxvarsidseq.NEXTVAL,
'LBNL','FAC', varname, varvalue  
  FROM BATCH_MAXIMO.LBL_MAXVARS 
  WHERE VARNAME = 'WO_FEEDBACK_WHERE';
  
insert into lbl_maxvars (description, hasld, lbl_maxvarsid,orgid, siteid, varname,
varvalue)
 SELECT 'Last datetime WOAck/notification generated',0, lbl_maxvarsidseq.NEXTVAL,
'LBNL','FAC', varname, varvalue  
  FROM BATCH_MAXIMO.LBL_MAXVARS 
  WHERE VARNAME = 'WO_ACKNOTIFY_LASTDATE';
  
insert into lbl_maxvars (description, hasld, lbl_maxvarsid,orgid, siteid, varname,
varvalue)
 SELECT 'MAXIMO application environment',0, lbl_maxvarsidseq.NEXTVAL,
'LBNL','FAC', varname, varvalue  
  FROM BATCH_MAXIMO.LBL_MAXVARS 
  WHERE VARNAME = 'APPLICATION_ENV';


insert into lbl_maxvars (description, hasld, lbl_maxvarsid,orgid, siteid, varname,
varvalue)
 SELECT 'Test user id for non-production env',0, lbl_maxvarsidseq.NEXTVAL,
'LBNL','FAC', varname, varvalue  
  FROM BATCH_MAXIMO.LBL_MAXVARS 
  WHERE VARNAME = 'TEST_USER_ID';

insert into lbl_maxvars (description, hasld, lbl_maxvarsid,orgid, siteid, varname,
varvalue)
 SELECT 'Work order feedback app URL',0, lbl_maxvarsidseq.NEXTVAL,
'LBNL','FAC', varname, varvalue
  FROM BATCH_MAXIMO.LBL_MAXVARS 
  WHERE VARNAME = 'WO_FEEDBACK_URL';

insert into lbl_maxvars (description, hasld, lbl_maxvarsid,orgid, siteid, varname,
varvalue)
 SELECT 'Where cond for work order acknowledgement',0, lbl_maxvarsidseq.NEXTVAL,
'LBNL','FAC', varname, varvalue  
  FROM BATCH_MAXIMO.LBL_MAXVARS 
  WHERE VARNAME = 'WO_ACKNOWLEDGE_WHERE';
  
insert into lbl_maxvars (description, hasld, lbl_maxvarsid,orgid, siteid, varname,
varvalue)
 SELECT 'Start datetime work order ack/notif',0, lbl_maxvarsidseq.NEXTVAL,
'LBNL','FAC', varname, varvalue  
  FROM BATCH_MAXIMO.LBL_MAXVARS 
  WHERE VARNAME = 'WO_ACKNOTIFY_STARTDATE';

insert into lbl_maxvars (description, hasld, lbl_maxvarsid,orgid, siteid, varname,
varvalue)
 SELECT 'WRC Managers email',0, lbl_maxvarsidseq.NEXTVAL,
'LBNL','FAC', varname, varvalue  
  FROM BATCH_MAXIMO.LBL_MAXVARS 
  WHERE VARNAME = 'WRC_MANAGERS_EMAIL';


insert into lbl_maxvars (description, hasld, lbl_maxvarsid,orgid, siteid, varname,
varvalue)
 SELECT 'Plant Ops Managers email',0, lbl_maxvarsidseq.NEXTVAL,
'LBNL','FAC', varname, varvalue  
  FROM BATCH_MAXIMO.LBL_MAXVARS 
  WHERE VARNAME = 'PLANTOPS_MANAGERS_EMAIL';


insert into lbl_maxvars (description, hasld, lbl_maxvarsid,orgid, siteid, varname,
varvalue)
 SELECT 'URL for work order visibility app',0, lbl_maxvarsidseq.NEXTVAL,
'LBNL','FAC', varname, varvalue
  FROM BATCH_MAXIMO.LBL_MAXVARS 
  WHERE VARNAME = 'WO_VISIBILITY';

  
-- feedback

insert into lbl_maxvars (description, hasld, lbl_maxvarsid,orgid, siteid, varname,
varvalue)
 SELECT 'Last datetime when wofeedback was sent',0, lbl_maxvarsidseq.NEXTVAL,
'LBNL','FAC', varname, varvalue  
  FROM BATCH_MAXIMO.LBL_MAXVARS 
  WHERE VARNAME = 'WOFEEDBACK_EMAIL_SENT_DATE';
  
insert into lbl_maxvars (description, hasld, lbl_maxvarsid,orgid, siteid, varname,
varvalue)
 SELECT 'List of emails for WO feedback',0, lbl_maxvarsidseq.NEXTVAL,
'LBNL','FAC', varname, varvalue  
  FROM BATCH_MAXIMO.LBL_MAXVARS 
  WHERE VARNAME = 'WOFEEDBACK_EMAIL_LIST';
  
insert into lbl_maxvars (description, hasld, lbl_maxvarsid,orgid, siteid, varname,
varvalue)
 SELECT 'Minimum threashold point for WO feedback',0, lbl_maxvarsidseq.NEXTVAL,
'LBNL','FAC', varname, varvalue  
  FROM BATCH_MAXIMO.LBL_MAXVARS 
  WHERE VARNAME = 'WOFEEDBACK_MIN_THRESHOLD';
  

insert into lbl_maxvars (description, hasld, lbl_maxvarsid,orgid, siteid, varname,
varvalue)
 SELECT 'Last work request number',0, lbl_maxvarsidseq.NEXTVAL,
'LBNL','FAC', varname, varvalue  
  FROM BATCH_MAXIMO.LBL_MAXVARS 
  WHERE VARNAME = 'LAST_WOREQ_NUM';
  
  
insert into lbl_maxvars (description, hasld, lbl_maxvarsid,orgid, siteid, varname,
varvalue)
 SELECT 'Last period for actuals to MAXIMO',0, lbl_maxvarsidseq.NEXTVAL,
'LBNL','FAC', varname, varvalue  
  FROM BATCH_MAXIMO.LBL_MAXVARS 
  WHERE VARNAME = 'LAST_MONTHLY_ACTUALS_TO_MAXIMO';
     
insert into lbl_maxvars (description, hasld, lbl_maxvarsid,orgid, siteid, varname,
varvalue)
 SELECT 'Last Hazard id ',0, lbl_maxvarsidseq.NEXTVAL,
'LBNL','FAC', varname, varvalue  
  FROM BATCH_MAXIMO.LBL_MAXVARS 
  WHERE VARNAME = 'HAZARDID';
  
     
insert into lbl_maxvars (description, hasld, lbl_maxvarsid,orgid, siteid, varname,
varvalue)
 SELECT 'Last Precaution id ',0, lbl_maxvarsidseq.NEXTVAL,
'LBNL','FAC', varname, varvalue  
  FROM BATCH_MAXIMO.LBL_MAXVARS 
  WHERE VARNAME = 'PRECAUTIONID';
     

INSERT INTO MAXIMO.LBL_MAXVARS(DESCRIPTION, HASLD,LBL_MAXVARSID,
ORGID, SITEID, VARNAME, VARVALUE) values
('Allowable CATS Status',0,lbl_maxvarsidseq.nextval,'LBNL','FAC',
 'ALLOWABLE_CATS_STATUS','Deleted');

INSERT INTO MAXIMO.LBL_MAXVARS(DESCRIPTION, HASLD,LBL_MAXVARSID,
ORGID, SITEID, VARNAME, VARVALUE) values
('Allowable CATS Status',0,lbl_maxvarsidseq.nextval,'LBNL','FAC',
 'ALLOWABLE_CATS_STATUS','Open');
 
 INSERT INTO MAXIMO.LBL_MAXVARS(DESCRIPTION, HASLD,LBL_MAXVARSID,
ORGID, SITEID, VARNAME, VARVALUE) values
('Allowable CATS Status',0,lbl_maxvarsidseq.nextval,'LBNL','FAC',
 'ALLOWABLE_CATS_STATUS','Overdue');
 
 INSERT INTO MAXIMO.LBL_MAXVARS(DESCRIPTION, HASLD,LBL_MAXVARSID,
ORGID, SITEID, VARNAME, VARVALUE) values
('Allowable CATS Status',0,lbl_maxvarsidseq.nextval,'LBNL','FAC',
 'ALLOWABLE_CATS_STATUS','Pending approval');
 
 INSERT INTO MAXIMO.LBL_MAXVARS(DESCRIPTION, HASLD,LBL_MAXVARSID,
ORGID, SITEID, VARNAME, VARVALUE) values
('Allowable CATS Status',0,lbl_maxvarsidseq.nextval,'LBNL','FAC',
 'ALLOWABLE_CATS_STATUS','Superseded');


INSERT INTO MAXIMO.LBL_MAXVARS(DESCRIPTION, HASLD,LBL_MAXVARSID,
ORGID, SITEID, VARNAME, VARVALUE) values
('Maximo-CATS admin user',0,lbl_maxvarsidseq.nextval,'LBNL','FAC',
 'MAX2CATSIFACE_NOTIFY','004828');

  
commit;



/***************************************************************************
 NAME                   : POSTCLONING.SQL

 DATE WRITTEN           : 9-MAR-2016

 AUTHOR                 : PANKAJ BHIDE

 PURPOSE                : THIS PROGRAM PERFORMS POST CLONING PROCEDURE AFTER
                          THE NON-PRODUCTION DATABASE IS CLONED FROM THE PROD
                          DATABASE.

                          THE PROGRAM EXPECTS THE ARUGEMENT THAT SPECIFIES THE
                          NAME OF THE CLONED DATABASE E.G. MMO7DEV, MMO7QA ETC.

 MODIFICATION HISTORY   :  APR 20 2016 PANKAJ - MODIFIED PROPERTY mxe.int.webappurl

                           MAY 9, 2016 PANKAJ - CHANGE PASSWORD AS PASSWORD
                                                VERIFICATION POLICY

                          OCT 27, 2016 PANKAJ - CHANGES FOR WORK ORDER RELEASE
                                                PHASE-2
                          APR 19, 2017 PANAKJ - REFLECT CHANGES FOR WORKFLOW
                                                AND ARCHIBUS 23.

                          AUG 22, 2017 PANKAJ - PROPERTIES FOR OSLC

                          JAN 04, 2021 PANKAJ - CHANGED TO MAXIMOFAC.DEV/QA
*****************************************************************************/

DECLARE

  T_STATEMENT1    VARCHAR2(32000);
  T_STATEMENT2    VARCHAR2(32000);
  T_STATEMENT2_1  VARCHAR2(32000);
  T_CLONEDBNAME   VARCHAR2(100);
  T_ENVIRONMENT   VARCHAR2(100) :=NULL;


  BEGIN

   T_CLONEDBNAME   :=UPPER('&1');

   IF (T_CLONEDBNAME IS NOT NULL) THEN

       -- DETERMINE THE ENVIRONMENT
       IF (INSTR(T_CLONEDBNAME,'DEV') !=0) THEN
         T_ENVIRONMENT :='DEV';
       END IF;

       IF (INSTR(T_CLONEDBNAME,'QA') !=0) THEN
         T_ENVIRONMENT :='QA';
       END IF;


       -- BASED UPON THE ENVIRONMENT, RE-CREATE THE LINKS

       T_STATEMENT1 :='CREATE DATABASE LINK ';

       IF (T_ENVIRONMENT = 'DEV') THEN

          -- CHANGE MAXIMO PASSWORD
          EXECUTE IMMEDIATE 'ALTER USER MAXIMO IDENTIFIED BY allset2g';

          -- DROP ALL THE LINKS
          EXECUTE IMMEDIATE 'DROP DATABASE LINK FMS9';
          EXECUTE IMMEDIATE 'DROP DATABASE LINK ARCHIBUS23';
          EXECUTE IMMEDIATE 'DROP DATABASE LINK LOCK2MAX';

          -- NO NEED TO MAINTAIN THIS TABLE. JUST UPDATE REQUIRED ROWS
          --DELETE FROM MAXIMO.LBL_MAXVARS;


          -- FMS
          T_STATEMENT2 :=' FMS9 CONNECT TO MMO_LINK_ID IDENTIFIED BY allset2p USING ' || '''' ||  'FMS9DEV' || '''';
          EXECUTE IMMEDIATE T_STATEMENT1 || T_STATEMENT2;

           -- ARCHIBUS
          T_STATEMENT2 :=' ARCHIBUS23 CONNECT TO AFM IDENTIFIED BY allset2q USING ' || '''' ||  'ARCHDEV' || '''';
          EXECUTE IMMEDIATE T_STATEMENT1 || T_STATEMENT2;

             -- LOCKSHOP
          T_STATEMENT2 :=' LOCK2MAX CONNECT TO LOCKADM IDENTIFIED BY lock12345 USING ' || '''' ||  'RESDEV' || '''';
          EXECUTE IMMEDIATE T_STATEMENT1 || T_STATEMENT2;

          T_STATEMENT2   := 'ALTER USER ';
          T_STATEMENT2_1 := ' IDENTIFIED BY ' ;
          EXECUTE IMMEDIATE T_STATEMENT2 || 'SPADM'         || T_STATEMENT2_1 || 'allset2g'   || ' REPLACE fork#4ptd';
          EXECUTE IMMEDIATE T_STATEMENT2 || 'MEAUSER'       || T_STATEMENT2_1 || 'allset2g'   || ' REPLACE fork#4ptd';
          EXECUTE IMMEDIATE T_STATEMENT2 || 'CHESS_LINK_ID' || T_STATEMENT2_1 || 'chess$1234' || ' REPLACE fork#4ptd';
          EXECUTE IMMEDIATE T_STATEMENT2 || 'MOBILEADM    ' || T_STATEMENT2_1 || 'allset2g'   || ' REPLACE fork#4ptd';
          EXECUTE IMMEDIATE T_STATEMENT2 || 'SOLUFY    ' || T_STATEMENT2_1 || 'Akwire$max4dev'   || ' REPLACE fork#4ptd';

          --INSERT INTO LBL_MAXVARS SELECT * FROM BATCH_MAXIMO.LBL_MAXVARSDEV;

          update maxpropvalue set propvalue='/apps/mxes/DOCLINKS=https://maximo.fac.dev.lbl.gov' where propname='mxe.doclink.path01';
          update maxpropvalue set propvalue='https://maximofac.dev.lbl.gov/maxrest/rest' where propname='mxe.lbl_restfulurl';
          update maxpropvalue set propvalue='https://maximofac.dev.lbl.gov/meaweb' where propname='mxe.int.webappurl'; -- added on 4/20/16
          update maxpropvalue set propvalue='/apps/mxes/maximo01/IBM/WebSphere/AppServer/profiles/ctgAppSrv01/globaldir' where propname='mxe.int.globaldir';

          update maxpropvalue set propvalue='FMS9DEV' where propname='lbl.lbl_default_psnode';

          -- JIRA EF-6035
          update maxpropvalue set propvalue='https://maximofac.dev.lbl.gov/maxrest/oslc' where propname='mxe.oslc.restwebappurl';
          update maxpropvalue set propvalue='https://maximofac.dev.lbl.gov/maximo/oslc/'  where propname='mxe.oslc.webappurl';


          update maxmessages set value='Welcome-Facilities Development, {0}' where msgkey='welcomeusername' and msggroup='login';
          update maxmessages set value='Welcome-Facilities Development' where msgkey='welcomemaximomessage' and msggroup='login';
          update commtemplate set subject = 'TEST Email from DEV - - ' || + subject;

          UPDATE LBL_MAXVARS SET VARVALUE='https://tad.dev.lbl.gov/general/tawd_help.aspx' WHERE VARNAME='TAWDHELP_URL';
          UPDATE LBL_MAXVARS SET VARVALUE='DEVELOPMENT', MESSAGE='[TEST] This email is generated from the test environment. This does not represent production data' where varname='APPLICATION_ENV';
          UPDATE LBL_MAXVARS SET VARVALUE='https://workrequest.dev.lbl.gov/WOFeedServlet' WHERE VARNAME='WO_FEEDBACK_URL';
          UPDATE LBL_MAXVARS SET VARVALUE='https://workrequest.dev.lbl.gov/jsp/workordervisibility.jsp' WHERE VARNAME='WO_VISIBILITY';
          UPDATE LBL_MAXVARS SET VARVALUE='https://worelease.dev.lbl.gov' WHERE VARNAME='WOREL_URL';
          UPDATE LBL_MAXVARS SET VARVALUE='https://worelease.dev.lbl.gov/browse/displayWorkOrders.aspx' WHERE VARNAME='WORELEASE_ENV'; --- ???

          update MAXENDPOINTDTL set value= 'https://fmsb2b.dev.lbl.gov:8003/PSIGW/HttpListeningConnector'
          where endpointname='PSFT_ENDPOINT'
          and property='URL';


       END IF; --  IF (T_ENVIRONMENT = 'DEV') THEN

        IF (T_ENVIRONMENT = 'QA') THEN

         -- CHANGE MAXIMO PASSWORD
          EXECUTE IMMEDIATE 'ALTER USER MAXIMO IDENTIFIED BY allset7q';

          -- DROP ALL THE LINKS
          EXECUTE IMMEDIATE 'DROP DATABASE LINK FMS9';
          EXECUTE IMMEDIATE 'DROP DATABASE LINK ARCHIBUS23';
          EXECUTE IMMEDIATE 'DROP DATABASE LINK LOCK2MAX';

          -- NO NEED TO MAINTAIN DATA INTO THIS TABLE.
          --DELETE FROM MAXIMO.LBL_MAXVARS;

          -- FMS
          T_STATEMENT2 :=' FMS9 CONNECT TO MMO_LINK_ID IDENTIFIED BY allset2p USING ' || '''' ||  'FMS9TST' || '''';
          EXECUTE IMMEDIATE T_STATEMENT1 || T_STATEMENT2;

           -- ARCHIBUS
          T_STATEMENT2 :=' ARCHIBUS23 CONNECT TO AFM IDENTIFIED BY allset2q USING ' || '''' ||  'ARCHQA' || '''';
          EXECUTE IMMEDIATE T_STATEMENT1 || T_STATEMENT2;

             -- LOCKSHOP
          T_STATEMENT2 :=' LOCK2MAX CONNECT TO LOCKADM IDENTIFIED BY la#09272010 USING ' || '''' ||  'RESQA' || '''';
          EXECUTE IMMEDIATE T_STATEMENT1 || T_STATEMENT2;

          T_STATEMENT2   := 'ALTER USER ';
          T_STATEMENT2_1 := ' IDENTIFIED BY ' ;
          EXECUTE IMMEDIATE T_STATEMENT2 || 'SPADM'         || T_STATEMENT2_1 || 'allset2q'   || ' REPLACE fork#4ptd';
          EXECUTE IMMEDIATE T_STATEMENT2 || 'MEAUSER'       || T_STATEMENT2_1 || 'allset2q'   || ' REPLACE fork#4ptd';
          EXECUTE IMMEDIATE T_STATEMENT2 || 'CHESS_LINK_ID' || T_STATEMENT2_1 || 'chess$1234' || ' REPLACE fork#4ptd';
          EXECUTE IMMEDIATE T_STATEMENT2 || 'MOBILEADM    ' || T_STATEMENT2_1 || 'allset2q'   || ' REPLACE fork#4ptd';
          EXECUTE IMMEDIATE T_STATEMENT2 || 'SOLUFY    ' || T_STATEMENT2_1 || 'Akwire$max4qa'   || ' REPLACE fork#4ptd';

          --INSERT INTO LBL_MAXVARS SELECT * FROM BATCH_MAXIMO.LBL_MAXVARSQA;


          update maxpropvalue set propvalue='/apps/mxes/DOCLINKS=https://maximofac.qa.lbl.gov'  where propname='mxe.doclink.path01';
          update maxpropvalue set propvalue='https://maximofac.qa.lbl.gov/maxrest/rest'  where propname='mxe.lbl_restfulurl';
          update maxpropvalue set propvalue='https://maximofac.qa.lbl.gov/meaweb' where propname='mxe.int.webappurl'; -- added on 4/20/16
          update maxpropvalue set propvalue='/apps/mxes/maximo01/IBM/WebSphere/AppServer/profiles/ctgAppSrv01/globaldir' where propname='mxe.int.globaldir';
          update maxpropvalue set propvalue='FMS9UAT' where propname='lbl.lbl_default_psnode';

              -- JIRA EF-6035
          update maxpropvalue set propvalue='https://maximofac.qa.lbl.gov/maxrest/oslc' where propname='mxe.oslc.restwebappurl';
          update maxpropvalue set propvalue='https://maximofac.qa.lbl.gov/maximo/oslc/'  where propname='mxe.oslc.webappurl';


          update maxmessages set value='Welcome-Facilities QA, {0}' where msgkey='welcomeusername' and msggroup='login';
          update maxmessages set value='Welcome-Facilities QA' where msgkey='welcomemaximomessage' and msggroup='login';
          update commtemplate set subject = 'TEST Email from DEV - - ' || + subject;

          UPDATE LBL_MAXVARS SET VARVALUE='https://tad.qa.lbl.gov/general/tawd_help.aspx' WHERE VARNAME='TAWDHELP_URL';
          UPDATE LBL_MAXVARS SET VARVALUE='QA', MESSAGE='[TEST] This email is generated from the test environment. This does not represent production data' where varname='APPLICATION_ENV';
          UPDATE LBL_MAXVARS SET VARVALUE='https://workrequest.qa.lbl.gov/WOFeedServlet' WHERE VARNAME='WO_FEEDBACK_URL';
          UPDATE LBL_MAXVARS SET VARVALUE='https://workrequest.qa.lbl.gov/jsp/workordervisibility.jsp' WHERE VARNAME='WO_VISIBILITY';
          UPDATE LBL_MAXVARS SET VARVALUE='https://worelease.qa.lbl.gov' WHERE VARNAME='WOREL_URL';
          UPDATE LBL_MAXVARS SET VARVALUE='https://worelease.qa.lbl.gov/browse/displayWorkOrders.aspx' WHERE VARNAME='WORELEASE_ENV'; --- ???

          update MAXENDPOINTDTL set value= 'https://fms9uat.qa.lbl.gov:8003/PSIGW/HttpListeningConnector'
          where endpointname='PSFT_ENDPOINT'
          and property='URL';

        END IF; --  IF (T_ENVIRONMENT = 'QA') THEN

       --***********************************
       -- COMMON ACTIONS FOR ALL DATABASES --
       --***********************************


       -- ADDED ON 7/18/16 FOR DISBLING SCHEDULED REPORTS
       update maxpropvalue set propvalue='1'  where propname='mxe.report.birt.disablequeuemanager';

       -- ADDED ON 4/19/17 TO SET ROLES TO THE DEVELOPERS
       update maxrole set value='FACIT' where maxrole='FAFAM';

       update maxrole set type='EMAILADDRESS', value ='pbhide@lbl.gov'
       where maxrole in ('FAC_WOLEAD', 'FAC_WOSUPERVISOR','FAWOSUPERVISOR','LBL_WOREPORTEDBY',   'LBL_WO2WO1',
                         'LBL_WO_REL_AUTHORIZER', 'FAWCSUPERVISOR','LBL_WO2BLDGMGR', 'LBL_WOREPORTEDBY',
                         'FAC_WOLEAD', 'FAC_WOSUPERVISOR');


       -- MAKE CUSTOMER COMMUNICATION ESCALATIONS INACTIVE
       UPDATE ESCALATION SET ACTIVE=0 WHERE ESCALATION LIKE 'LBL%';
       UPDATE ESCALATION SET ACTIVE=0 WHERE ESCALATION LIKE 'FA%';

       UPDATE LBL_MAXVARS SET VARVALUE='PBhide@lbl.gov' where varname in ('FACWPC_EMAIL','WRC_MANAGERS_EMAIL',
      'PLANTOPS_MANAGERS_EMAIL','PETROVEND2MXES_NOTIFY','PLANTOPS_MANAGERS_EMAIL');

       UPDATE LBL_MAXVARS SET VARVALUE='813149' where varname in ('TEST_USER_ID','MAX2CATSIFACE_NOTIFY');

       UPDATE PERSONGROUPTEAM
       SET RESPPARTY='813149', RESPPARTYGROUP='813149'
       WHERE PERSONGROUP='WRC_STOR'
       AND RESPPARTY='303001'
       AND RESPPARTYGROUP='303001';

       DELETE FROM  PERSONGROUPTEAM
       WHERE PERSONGROUP='WRC_STOR'
       AND RESPPARTY !='813149';



       UPDATE MAXPROPVALUE SET PROPVALUE='PBHIDE,ALEUNG,IT-BS-MXINTADM',
       CHANGEBY='PBHIDE',
       CHANGEDATE=SYSDATE 
       where propname='lbl.fac_admin_logins';
       
       UPDATE COMMTMPLTSENDTO SET BCC = 0, CC=0,SENDTO=0;                   
       UPDATE CRONTASKINSTANCE SET ACTIVE=0 WHERE CRONTASKNAME LIKE 'LBL%';
       UPDATE CRONTASKINSTANCE SET ACTIVE=0 WHERE instancename LIKE 'ESCLBL%';
            
       
       
       -- FOR LOCKSHOP 
       DELETE FROM COMMTMPLTSENDTO WHERE SENDTOVALUE='FASUPERTEST';
       DELETE FROM PERSONGROUPTEAM WHERE PERSONGROUP='FAWRCLOCKSHOP';

       INSERT INTO PERSONGROUPTEAM(GROUPDEFAULT, ORGDEFAULT,PERSONGROUP,
       PERSONGROUPTEAMID, RESPPARTY, RESPPARTYGROUP, RESPPARTYGROUPSEQ,
       RESPPARTYSEQ, SITEDEFAULT) VALUES
       (1,0,'FAWRCLOCKSHOP',PERSONGROUPTEAMSEQ.NEXTVAL, '813149','813149',1,0,0);

       INSERT INTO PERSONGROUPTEAM(GROUPDEFAULT, ORGDEFAULT,PERSONGROUP,
       PERSONGROUPTEAMID, RESPPARTY, RESPPARTYGROUP, RESPPARTYGROUPSEQ,
       RESPPARTYSEQ, SITEDEFAULT) VALUES
       (0,0,'FAWRCLOCKSHOP',PERSONGROUPTEAMSEQ.NEXTVAL, '024787','024787',3,3,0);

       INSERT INTO COMMTMPLTSENDTO
        VALUES
       (0,0,COMMTMPLTSENDTOSEQ.NEXTVAL,0,1,'FASUPERTEST','LBL_WO2BLDGMGR','GROUP','1');
             
             
       INSERT INTO COMMTMPLTSENDTO
       VALUES
       (0,0,COMMTMPLTSENDTOSEQ.NEXTVAL,0,1,'FASUPERTEST','LBL_AUTHAPPR','GROUP','1');
             
       INSERT INTO COMMTMPLTSENDTO
       VALUES
       (0,0,COMMTMPLTSENDTOSEQ.NEXTVAL,0,1,'FASUPERTEST','LBL_AUTHAPPRV1','GROUP','1');
             
       INSERT INTO COMMTMPLTSENDTO
       VALUES
       (0,0,COMMTMPLTSENDTOSEQ.NEXTVAL,0,1,'FASUPERTEST','LBL_KEYMAILED','GROUP','1');
             
       INSERT INTO COMMTMPLTSENDTO
       VALUES
       (0,0,COMMTMPLTSENDTOSEQ.NEXTVAL,0,1,'FASUPERTEST','LBL_KEYMAILEDV1','GROUP','1');
             
       INSERT INTO COMMTMPLTSENDTO
       VALUES(0,0,COMMTMPLTSENDTOSEQ.NEXTVAL,0,1,'FASUPERTEST','LBL_TRANSFERACK','GROUP','1');
             
       INSERT INTO COMMTMPLTSENDTO
       VALUES(0,0,COMMTMPLTSENDTOSEQ.NEXTVAL,0,1,'FASUPERTEST','LBL_TRANSFERACKV1','GROUP','1');
             
       INSERT INTO COMMTMPLTSENDTO
       VALUES(0,0,COMMTMPLTSENDTOSEQ.NEXTVAL,0,1,'FASUPERTEST','LBL_TRANSFERAPPR','GROUP','1');
             
       INSERT INTO COMMTMPLTSENDTO
       VALUES(0,0,COMMTMPLTSENDTOSEQ.NEXTVAL,0,1,'FASUPERTEST','LBL_TRANSFERAPPRV1','GROUP','1');

       INSERT INTO COMMTMPLTSENDTO
       VALUES(0,0,COMMTMPLTSENDTOSEQ.NEXTVAL,0,1,'FASUPERTEST','LBL_KEYPICKUPV1','GROUP','1');
                          
      

END IF;


COMMIT;


END;

/

   
   

  

   

  

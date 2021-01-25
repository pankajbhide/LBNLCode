set scan off
/***************************************************************************
*
* PROGRAM NAME          : send_wf_statuschange_em.SQL
*
*
* DESCRIPTION           : Send out Email when work order status change                         
*
* AUTHOR                : Annette Leung
*
* DATE WRITTEN          : Apr-24-2017
* DATE MODIFIED         : MAY-12-2017
*
* MODIFICATION HISORTY  : MAY-12-2017
*                       : Modified the program to include SCHED and WCOMP status
*                       : Changed the email layout
*                       
*                       : AUG-25-2017
*                       : Modified the program to only send to FAM default person
*
*                       : SEPT-5-2017
*                       : Modified the program to send out email to everyone in FAM group
*                       : when work order status is changed to CAN.
*
*                       : SEPT-27-2017
*                       : Modified the program to send out email only to default person 
*                       : of FAM.  Also send the email to customer and reported by
*
*                       : OCT-10-2017
*                       : Modified the program to send out email when status 
*                       : is changed to SPRI. Send to the default persson of FAM. 
***************************************************************************/
WHENEVER SQLERROR EXIT 1 ROLLBACK;


DECLARE

 ROW_COUNT_T NUMBER (7) :=0;
 T_BODY1     VARCHAR2(32000);
 T_BODY2     VARCHAR2(32000);
 T_BODY      VARCHAR2(32000);
 T_APP_ENVIRONMENT VARCHAR2(200);
 T_TEST_USER_ID    VARCHAR2(1000);
 T_SUBJECT VARCHAR2(32000);
 T_FOOTER  VARCHAR2(2000);
 T_TESTUSER_EMAIL VARCHAR2(100);
 T_REPORTEDBY_EMAIL VARCHAR2(100);
 T_CUSTOMER_EMAIL VARCHAR2(100) :=' ';
 T_SUPERVISOR_EMAIL VARCHAR2(100) :=' ';
 T_BLDGMNGR_EMAIL VARCHAR2(100) :=' ';
 T_FAM_EMAIL VARCHAR2(100) :=' ';
 T_LASTUPDATE   WORKORDER.STATUSDATE%TYPE;
 T_FAMID  WORKORDER.LBL_FAMID%TYPE;
 T_STATUS WORKORDER.STATUS%TYPE;


CURSOR  UPDATEWOSTATUS_CUR IS
    SELECT WONUM, DESCRIPTION, LOCATION, to_char(SCHEDSTART, 'DD-MON-YYYY HH24:MI') SCHEDSTART,
    to_char(SCHEDFINISH, 'DD-MON-YYYY HH24:MI') SCHEDFINISH, LEAD, STATUS, REPORTEDBY, WO1, SUPERVISOR, LBL_FAMID, WORKTYPE,
    (SELECT DESCRIPTION FROM SYNONYMDOMAIN WHERE DOMAINID = 'WOSTATUS' AND VALUE = WORKORDER.STATUS ) STATUSDESC,
    (SELECT LDTEXT FROM LONGDESCRIPTION WHERE LDOWNERTABLE = 'WORKORDER' and LDOWNERCOL = 'DESCRIPTION' and LDKEY = WORKORDER.WORKORDERID) LONGDESC,
    (SELECT WTYPEDESC FROM WORKTYPE WHERE WORKTYPE = WORKORDER.WORKTYPE) WORKTYPEDESC,
    (SELECT DISPLAYNAME FROM PERSON WHERE PERSONID = WORKORDER.REPORTEDBY) REPORTEDBYNAME,  
    (SELECT DISPLAYNAME FROM PERSON WHERE PERSONID = WORKORDER.LEAD) LEADNAME,
    (SELECT DISPLAYNAME FROM PERSON WHERE PERSONID = WORKORDER.SUPERVISOR) SUPERVISORNAME,  
    to_char(TARGSTARTDATE, 'DD-MON-YYYY HH24:MI') TARGSTART, to_char(TARGCOMPDATE, 'DD-MON-YYYY HH24:MI') TARGCOMP, 
    to_char(REPORTDATE, 'DD-MON-YYYY HH24:MI') REPORTDATE, to_char(STATUSDATE, 'DD-MON-YYYY HH24:MI') STATUSDATE,
    (SELECT MEMO FROM WOSTATUS WHERE WONUM = WORKORDER.WONUM AND STATUS = WORKORDER.STATUS AND CHANGEDATE = WORKORDER.STATUSDATE) MEMO
    FROM   WORKORDER
    WHERE  ORGID = 'LBNL' and SITEID = 'FAC' and STATUS in ('INFO', 'HOLD', 'ASSIGNED', 'WENG', 'SCHD', 'WCOMP', 'WSCH1', 'CAN', 'SPRI') AND ISTASK = 0
    AND STATUSDATE > (SELECT to_date(VARVALUE,'YYYY-MM-DD HH24:MI:SS') FROM LBL_MAXVARS WHERE  VARNAME='LAST_WOS_EMAIL_SEND_DATE');


 CURSOR MAXVAR_CUR IS
   SELECT VARNAME, VARVALUE FROM MAXIMO.LBL_MAXVARS
   WHERE VARNAME IN ('TEST_USER_ID','APPLICATION_ENV');


 PROCEDURE SEND_EMAIL(T_SUBJECT IN VARCHAR2,
                      T_BODY    IN VARCHAR2,
                      T_TESTUSER_EMAIL  IN VARCHAR2,
                      T_APP_ENVIRONMENT IN VARCHAR2,
                      T_SUPERVISOR IN VARCHAR2,
                      T_FAMID IN VARCHAR2,
                      T_REPORTEDBY IN VARCHAR2,
                      T_WO1 IN VARCHAR2,
                      T_STATUS IN VARCHAR2,
                      T_WORKTYPE IN VARCHAR2,
                      T_LOCATION IN VARCHAR2)

 IS
-- select FAM email address

   CURSOR FAFAM_CUR IS
    SELECT EMAILADDRESS FROM MAXIMO.EMAIL
    WHERE  personid in (SELECT RESPPARTY FROM PERSONGROUPTEAM WHERE PERSONGROUP = T_FAMID )
    AND ISPRIMARY=1 ;
    
-- select Building Managers email address    

    CURSOR BLDGMNGR_CUR IS
        SELECT PERSONID FROM LOCATIONUSERCUST
        WHERE LBL_ISBUILDINGRESP = 1
        AND LOCATION = (SELECT LO1 FROM LOCATIONS WHERE LOCATION = T_LOCATION);

   BEGIN
    T_REPORTEDBY_EMAIL := ' ';
    T_CUSTOMER_EMAIL   := ' ';
    T_SUPERVISOR_EMAIL := ' ';
    T_BLDGMNGR_EMAIL := ' ';


    IF (T_APP_ENVIRONMENT !='PRODUCTION') THEN
        LBL_MAXIMO_PKG.SEND_MAIL_HTML(T_TESTUSER_EMAIL,-- TO
        'wpc@lbl.gov', -- FROM
        T_SUBJECT,
        T_BODY,
        T_BODY,
        'smtp.lbl.gov',
        25);
    ELSE -- PROD ENV   
  
      CASE 
            WHEN ((T_STATUS = 'WENG') AND (T_SUPERVISOR is not null))  THEN
                BEGIN
                    SELECT EMAILADDRESS INTO T_SUPERVISOR_EMAIL
                    FROM EMAIL
                    WHERE PERSONID =  T_SUPERVISOR
                    AND ISPRIMARY=1;
                
                    EXCEPTION WHEN OTHERS THEN
                        T_SUPERVISOR_EMAIL := NULL;
                END;

                IF ( T_SUPERVISOR_EMAIL IS NOT NULL) THEN
                    LBL_MAXIMO_PKG.SEND_MAIL_HTML(T_SUPERVISOR_EMAIL,
                    'wpc@lbl.gov', -- FROM
                    T_SUBJECT,
                    T_BODY,
                    T_BODY,
                    'smtp.lbl.gov',
                    25);
                END IF;
            
            WHEN ((T_STATUS IN ('HOLD', 'INFO', 'WSCH1','SPRI')) AND (T_FAMID IS NOT NULL)) THEN
                BEGIN
                    SELECT EMAILADDRESS INTO T_FAM_EMAIL
                    FROM EMAIL
                    WHERE PERSONID = (SELECT RESPPARTY FROM PERSONGROUPTEAM WHERE GROUPDEFAULT = 1 AND PERSONGROUP = T_FAMID)
                    AND ISPRIMARY=1;
                
                    EXCEPTION WHEN OTHERS THEN
                        T_FAM_EMAIL := NULL;
                END;
-- Per Tammy request only send to the FAM default                 
                IF (T_FAM_EMAIL IS NOT NULL) THEN
                    LBL_MAXIMO_PKG.SEND_MAIL_HTML(T_FAM_EMAIL,
                            'wpc@lbl.gov', -- FROM
                            T_SUBJECT,
                            T_BODY,
                            T_BODY,
                            'smtp.lbl.gov',
                            25);
                END IF;

-- Per Beth request to send email to everyone in the FAM group when work order is changed to CAN status.                
            WHEN (T_STATUS = 'CAN') THEN
            
                 BEGIN
                    SELECT EMAILADDRESS INTO T_FAM_EMAIL
                    FROM EMAIL
                    WHERE PERSONID = (SELECT RESPPARTY FROM PERSONGROUPTEAM WHERE GROUPDEFAULT = 1 AND PERSONGROUP = T_FAMID)
                    AND ISPRIMARY=1;
                
                    EXCEPTION WHEN OTHERS THEN
                        T_FAM_EMAIL := NULL;
                END;
                
               IF (T_FAM_EMAIL IS NOT NULL) THEN
                    LBL_MAXIMO_PKG.SEND_MAIL_HTML(T_FAM_EMAIL,
                            'wpc@lbl.gov', -- FROM
                            T_SUBJECT,
                            T_BODY,
                            T_BODY,
                            'smtp.lbl.gov',
                            25);
                END IF; 
                
                IF (T_WO1 IS NOT NULL) THEN                
                    BEGIN                
                        SELECT EMAILADDRESS INTO T_CUSTOMER_EMAIL
                        FROM EMAIL
                        WHERE PERSONID =  T_WO1
                        AND ISPRIMARY=1;

                        EXCEPTION WHEN OTHERS THEN
                            T_CUSTOMER_EMAIL :=NULL;
                    END;
                    IF (T_CUSTOMER_EMAIL IS NOT NULL) THEN
                        LBL_MAXIMO_PKG.SEND_MAIL_HTML(T_CUSTOMER_EMAIL,
                        'wpc@lbl.gov', -- FROM
                        T_SUBJECT,
                        T_BODY,
                        T_BODY,
                        'smtp.lbl.gov',
                        25);
                    END IF;
                END IF;
                
/*            
                FOR FAFAM_REC IN FAFAM_CUR
                    LOOP
                        IF (FAFAM_REC.EMAILADDRESS IS NOT NULL) THEN               
                            LBL_MAXIMO_PKG.SEND_MAIL_HTML(FAFAM_REC.EMAILADDRESS,
                            'wpc@lbl.gov', -- FROM
                            T_SUBJECT,
                            T_BODY,
                            T_BODY,
                            'smtp.lbl.gov',
                            25);
                        END IF;
                    END LOOP;
*/                  
            WHEN (T_STATUS = 'ASSIGNED') THEN 
                IF (T_REPORTEDBY IS NOT NULL) THEN
                    BEGIN
                        SELECT EMAILADDRESS INTO T_REPORTEDBY_EMAIL
                        FROM EMAIL
                        WHERE PERSONID =  T_REPORTEDBY
                        AND ISPRIMARY=1;
                
                        EXCEPTION WHEN OTHERS THEN
                            T_REPORTEDBY_EMAIL := NULL;
                    END;
                    IF (T_REPORTEDBY_EMAIL IS NOT NULL) THEN
                        LBL_MAXIMO_PKG.SEND_MAIL_HTML(T_REPORTEDBY_EMAIL,
                        'wpc@lbl.gov', -- FROM
                        T_SUBJECT,
                        T_BODY,
                        T_BODY,
                        'smtp.lbl.gov',
                        25);
                    END IF;
                END IF;
                IF (T_WO1 IS NOT NULL) THEN                
                    BEGIN                
                        SELECT EMAILADDRESS INTO T_CUSTOMER_EMAIL
                        FROM EMAIL
                        WHERE PERSONID =  T_WO1
                        AND ISPRIMARY=1;

                        EXCEPTION WHEN OTHERS THEN
                            T_CUSTOMER_EMAIL :=NULL;
                    END;
                    IF (T_CUSTOMER_EMAIL IS NOT NULL) THEN
                        LBL_MAXIMO_PKG.SEND_MAIL_HTML(T_CUSTOMER_EMAIL,
                        'wpc@lbl.gov', -- FROM
                        T_SUBJECT,
                        T_BODY,
                        T_BODY,
                        'smtp.lbl.gov',
                        25);
                    END IF;
                END IF;
                
            WHEN ((T_STATUS = 'SCHD') AND (T_WORKTYPE NOT IN ('TM', 'PM'))) THEN
                BEGIN                
                    SELECT EMAILADDRESS INTO T_CUSTOMER_EMAIL
                    FROM EMAIL
                    WHERE PERSONID =  T_WO1
                    AND ISPRIMARY=1;

                    EXCEPTION WHEN OTHERS THEN
                        T_CUSTOMER_EMAIL :=NULL;       
                END;  
                IF (T_CUSTOMER_EMAIL IS NOT NULL) THEN
                    LBL_MAXIMO_PKG.SEND_MAIL_HTML(T_CUSTOMER_EMAIL,
                    'wpc@lbl.gov', -- FROM
                    T_SUBJECT,
                    T_BODY,
                    T_BODY,
                    'smtp.lbl.gov',
                    25);
                END IF;
                BEGIN
                    SELECT EMAILADDRESS INTO T_REPORTEDBY_EMAIL
                    FROM EMAIL
                    WHERE PERSONID =  T_REPORTEDBY
                    AND ISPRIMARY=1;
                
                    EXCEPTION WHEN OTHERS THEN
                        T_REPORTEDBY_EMAIL := NULL;
                END;
                IF (T_REPORTEDBY_EMAIL IS NOT NULL) THEN
                    LBL_MAXIMO_PKG.SEND_MAIL_HTML(T_REPORTEDBY_EMAIL,
                    'wpc@lbl.gov', -- FROM
                    T_SUBJECT,
                    T_BODY,
                    T_BODY,
                    'smtp.lbl.gov',
                    25);
                END IF;
                FOR BLDGMNGR_REC IN BLDGMNGR_CUR
                    LOOP
                        BEGIN
                            SELECT EMAILADDRESS INTO T_BLDGMNGR_EMAIL
                            FROM EMAIL
                            WHERE PERSONID =  BLDGMNGR_REC.PERSONID
                            AND ISPRIMARY=1;
                
                            EXCEPTION WHEN OTHERS THEN
                                T_BLDGMNGR_EMAIL := NULL;
                        END;
                        IF (T_BLDGMNGR_EMAIL IS NOT NULL) THEN
                            LBL_MAXIMO_PKG.SEND_MAIL_HTML(T_BLDGMNGR_EMAIL,
                            'wpc@lbl.gov', -- FROM
                            T_SUBJECT,
                            T_BODY,
                            T_BODY,
                            'smtp.lbl.gov',
                            25);
                        END IF;
                    END LOOP;
             WHEN ((T_STATUS = 'WCOMP') AND (T_SUPERVISOR is not null))  THEN
                BEGIN
                    SELECT EMAILADDRESS INTO T_SUPERVISOR_EMAIL
                    FROM EMAIL
                    WHERE PERSONID =  T_SUPERVISOR
                    AND ISPRIMARY=1;
                
                    EXCEPTION WHEN OTHERS THEN
                        T_SUPERVISOR_EMAIL := NULL;
                END;

                IF ( T_SUPERVISOR_EMAIL IS NOT NULL) THEN
                    LBL_MAXIMO_PKG.SEND_MAIL_HTML(T_SUPERVISOR_EMAIL,
                    'wpc@lbl.gov', -- FROM
                    T_SUBJECT,
                    T_BODY,
                    T_BODY,
                    'smtp.lbl.gov',
                    25);
                END IF; 
                LBL_MAXIMO_PKG.SEND_MAIL_HTML('wpc@lbl.gov',
                    'wpc@lbl.gov', -- FROM
                    T_SUBJECT,
                    T_BODY,
                    T_BODY,
                    'smtp.lbl.gov',
                    25);                    
            ELSE NULL;                
        END CASE; --Case Statement
        
   END IF ; -- IF (T_APP_ENVIRONMENT !='PRODUCTION') THEN
   
 END;

 BEGIN  -- main program

    FOR MAXVARS_REC IN MAXVAR_CUR

     LOOP

       IF (MAXVARS_REC.VARNAME='APPLICATION_ENV') THEN
          T_APP_ENVIRONMENT :=MAXVARS_REC.VARVALUE;
       END IF;

       IF (MAXVARS_REC.VARNAME='TEST_USER_ID') THEN
          T_TEST_USER_ID :=MAXVARS_REC.VARVALUE;
       END IF;

    END LOOP;

   -- ADDED BY PANKAJ on 5/5/17
   T_TESTUSER_EMAIL := NULL;

   IF (T_APP_ENVIRONMENT !='PRODUCTION') THEN
    SELECT A.EMAILADDRESS
    INTO T_TESTUSER_EMAIL
    FROM MAXIMO.EMAIL A 
    WHERE A.PERSONID=T_TEST_USER_ID
    AND A.ISPRIMARY=1;
  END IF;


    IF (T_APP_ENVIRONMENT !='PRODUCTION') THEN
       T_SUBJECT :='(TEST)';
       T_FOOTER  :='THIS DATA IS GENERATED FROM THE TEST DATABASE AND IT DOES NOT REPRESENT PRODUCTION DATABASE';
    END IF;


   -- READ RECORDS
   FOR UPDATEWOSTATUS_REC IN UPDATEWOSTATUS_CUR

     LOOP

        T_BODY1  :='<HTML><HEAD><TITLE> The Status of the Facilities work order is now changed </TITLE></HEAD>';
        T_BODY1  := T_BODY1  || '<BODY><TABLE><TR><TD>';
        T_BODY1  := T_BODY1  || 'Hello, ' || '</TD></TR>';
        T_BODY1  := T_BODY1  || '<TR><TD>&nbsp;</TD></TR>';
        IF (UPDATEWOSTATUS_REC.STATUS = 'CAN') THEN
            T_BODY1  := T_BODY1  ||' <b>The status of the Facilities work order ' || UPDATEWOSTATUS_REC.WONUM || ' is now changed to ' || UPDATEWOSTATUS_REC.STATUS || ' - ' || UPDATEWOSTATUS_REC.STATUSDESC  || '</b>';
            T_BODY1  := T_BODY1  || '<TR><TD>&nbsp;</TD></TR>';
        END IF;
        T_BODY1  := T_BODY1  || '<TR><TD>Given below are the details of the work order:</TD></TR>';
        T_BODY1  := T_BODY1  || '<TR><TD>&nbsp;</TD></TR>';
        -- COMPOSING EMAIL CONTAINS
        T_SUBJECT := ' The status of the Facilities work order ' || UPDATEWOSTATUS_REC.WONUM || ' is now changed to ' || UPDATEWOSTATUS_REC.STATUS;
        T_BODY2 := '<TABLE BORDER=1 ALIGN=LEFT>';
        IF (UPDATEWOSTATUS_REC.STATUS != 'WCOMP') THEN
            T_BODY2 := T_BODY2    || '<TR><TD>' || 'Work order number:  ' || '</TD><TD>' || UPDATEWOSTATUS_REC.WONUM || '</TD</TR>';
            T_BODY2 := T_BODY2    || '<TR><TD>' || 'Work order description: ' || '</TD><TD>' || UPDATEWOSTATUS_REC.DESCRIPTION || '</TD></TR>';
            T_BODY2 := T_BODY2    || '<TR><TD>' || 'Location: ' || '</TD><TD>' || UPDATEWOSTATUS_REC.LOCATION || '</TD</TR>';
             IF (UPDATEWOSTATUS_REC.STATUS = 'CAN') THEN
                T_BODY2 := T_BODY2    || '<TR><TD><b>' || 'Current Status: '  || '</b></TD><TD><b>'  || UPDATEWOSTATUS_REC.STATUS || ' - ' || UPDATEWOSTATUS_REC.STATUSDESC || '<b></TD</TR>';
                T_BODY2 := T_BODY2    || '<TR><TD><b>' || 'Status Memo: '  || '</b></TD><TD><b>' || UPDATEWOSTATUS_REC.MEMO || '</b></TD</TR>';
                T_BODY2 := T_BODY2    || '<TR><TD><b>' || 'Status Date: '  || '</b></TD><TD><b>' || UPDATEWOSTATUS_REC.STATUSDATE ||  '</b></TD></TR>';
            END IF;
            T_BODY2 := T_BODY2    || '<TR><TD>' || 'Scheduled start date:  ' || '</TD><TD>' || UPDATEWOSTATUS_REC.SCHEDSTART || '</TD></TR>';
            T_BODY2 := T_BODY2    || '<TR><TD>' || 'Scheduled end date: ' || '</TD><TD>' || UPDATEWOSTATUS_REC.SCHEDFINISH || '</TD></TR>';
            T_BODY2 := T_BODY2    || '<TR><TD>' || 'Facilities Lead: ' || '</TD><TD>' || UPDATEWOSTATUS_REC.LEADNAME ||  '</TD></TR>';
            T_BODY2 := T_BODY2    || '</TABLE>';
            T_BODY2 := T_BODY2    || '<br>';
            T_BODY2 := T_BODY2    || '<TR><TD>' || 'Please contact Facilities Work Planning and Control department for any clarifications.' ||  '</TD></TR>';
            T_BODY2 := T_BODY2    || '<br>';
            IF (UPDATEWOSTATUS_REC.STATUS = 'WSCH1') THEN
                T_BODY2 := T_BODY2    || '<TR><TD>' || 'If workflow is enabled, please check workflow inbox to accept the assignment.' ||  '</TD></TR>';
                T_BODY2 := T_BODY2    || '<br>';
            END IF;
            T_BODY2 := T_BODY2    || '<TR><TD>' || 'Facilities Work Planning and Control' ||  '</TD></TR>' ;
            T_BODY2 := T_BODY2 || '</TABLE></TD></TR><TR><TD>&nbsp;</TD></TR><TR><TD>&nbsp;</TD></TR>';
            T_BODY2 := T_BODY2 || '<TR><TD>&nbsp;</TD></TR><TR><TD>&nbsp;</TD></TR>';
        ELSE
            T_BODY2 := T_BODY2    || '<TR><TD>' || 'Work order number: ' || '</TD><TD>' || UPDATEWOSTATUS_REC.WONUM || '</TD</TR>';
            T_BODY2 := T_BODY2    || '<TR><TD>' || 'Requested Work: '    || '</TD><TD>' || UPDATEWOSTATUS_REC.DESCRIPTION || '</TD></TR>';
            T_BODY2 := T_BODY2    || '<TR><TD>' || 'Long Description: '  || '</TD><TD>' || UPDATEWOSTATUS_REC.LONGDESC || '</TD</TR>';
            T_BODY2 := T_BODY2    || '<TR><TD>' || 'Work Type:  '   || '</TD><TD>' || UPDATEWOSTATUS_REC.WORKTYPE ||' - ' || UPDATEWOSTATUS_REC.WORKTYPEDESC ||'</TD</TR>';
            T_BODY2 := T_BODY2    || '<TR><TD>' || 'Reported By: '  || '</TD><TD>' || UPDATEWOSTATUS_REC.REPORTEDBY || ' - ' || UPDATEWOSTATUS_REC.REPORTEDBYNAME || '</TD</TR>';
            T_BODY2 := T_BODY2    || '<TR><TD>' || 'Date Report: '  || '</TD><TD>' || UPDATEWOSTATUS_REC.REPORTDATE || '</TD</TR>';
            T_BODY2 := T_BODY2    || '<TR><TD>' || 'Lead: '        || '</TD><TD>' || UPDATEWOSTATUS_REC.LEAD || ' - ' || UPDATEWOSTATUS_REC.LEADNAME || '</TD</TR>';
            T_BODY2 := T_BODY2    || '<TR><TD>' || 'Supervisor: '  || '</TD><TD>' || UPDATEWOSTATUS_REC.SUPERVISOR || ' - ' || UPDATEWOSTATUS_REC.SUPERVISORNAME || '</TD</TR>';
            T_BODY2 := T_BODY2    || '<TR><TD>' || 'Location: '    || '</TD><TD>' || UPDATEWOSTATUS_REC.LOCATION || '</TD</TR>';
            T_BODY2 := T_BODY2    || '<TR><TD>' || 'Current Status: '  || '</TD><TD>'  || UPDATEWOSTATUS_REC.STATUS || ' - ' || UPDATEWOSTATUS_REC.STATUSDESC || '</TD</TR>';
            T_BODY2 := T_BODY2    || '<TR><TD>' || 'Status Memo: '  || '</TD><TD>' || UPDATEWOSTATUS_REC.MEMO || '</TD</TR>';
            T_BODY2 := T_BODY2    || '<TR><TD>' || 'Status Date: '  || '</TD><TD>' || UPDATEWOSTATUS_REC.STATUSDATE ||  '</TD></TR>';           
            T_BODY2 := T_BODY2    || '<TR><TD>' || 'Target Start Date:  '      || '</TD><TD>' || UPDATEWOSTATUS_REC.TARGSTART || '</TD></TR>';
            T_BODY2 := T_BODY2    || '<TR><TD>' || 'Target Completion Date: '  || '</TD><TD>'|| UPDATEWOSTATUS_REC.TARGCOMP || '</TD></TR>';        
            T_BODY2 := T_BODY2    || '<TR><TD>' || 'Scheduled Start Date:   '  || '</TD><TD>' || UPDATEWOSTATUS_REC.SCHEDSTART || '</TD></TR>';
            T_BODY2 := T_BODY2    || '<TR><TD>' || 'Scheduled Finish Date: '   || '</TD><TD>' || UPDATEWOSTATUS_REC.SCHEDFINISH || '</TD></TR>';
            T_BODY2 := T_BODY2    || '</TABLE>';  
            T_BODY2 := T_BODY2    || '<br>';
            T_BODY2 := T_BODY2    || '<TR><TD>' || 'In order for the Facilities commence work, you are requested to either change the status of the work order to release. Alternatively, you can change the status of the work order to request for more information.' ||  '</TD></TR>';
            T_BODY2 := T_BODY2    || '<TR><TD>' || 'You can contact the Facilities Work Planning and Control group wpc@lbl.gov or dial x6300 for any clarifications.' ||  '</TD></TR>';
            T_BODY2 := T_BODY2    || '<br>';
            T_BODY2 := T_BODY2    || '<TR><TD>' || 'Facilities Work Planning and Control' ||  '</TD></TR>' ;
            T_BODY2 := T_BODY2 || '<TR><TD>&nbsp;</TD></TR><TR><TD>&nbsp;</TD></TR>';
        END IF;

        IF (T_APP_ENVIRONMENT !='PRODUCTION') THEN
            T_BODY2 := T_BODY2 || '<TR><TD>' || T_FOOTER || '</TD></TR>';
        END IF;

        T_BODY2 := T_BODY2 || ' </TABLE></BODY></HTML>';
        T_BODY  := T_BODY1 || T_BODY2;


     SEND_EMAIL(T_SUBJECT, T_BODY, T_TESTUSER_EMAIL, T_APP_ENVIRONMENT, UPDATEWOSTATUS_REC.SUPERVISOR,
     UPDATEWOSTATUS_REC.LBL_FAMID, UPDATEWOSTATUS_REC.REPORTEDBY, UPDATEWOSTATUS_REC.WO1, UPDATEWOSTATUS_REC.STATUS,
     UPDATEWOSTATUS_REC.WORKTYPE, UPDATEWOSTATUS_REC.LOCATION);

   END LOOP;
   
   UPDATE LBL_MAXVARS
    SET VARVALUE = to_char(sysdate,'YYYY-MM-DD HH24:MI:SS')
    WHERE VARNAME='LAST_WOS_EMAIL_SEND_DATE';
    --rollback;
    
 END;

 /
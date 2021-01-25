set scan off
/***************************************************************************
*
* PROGRAM NAME          : send_followup_wrel_status_em.SQL
*
*
* DESCRIPTION           : Send out follow up email when work order status is still WREL after 2 days
*
*
* AUTHOR                : Annette Leung
*
* DATE WRITTEN          : May-22-2017
* DATE MODIFIED         :
*
* MODIFICATION HISORTY  :
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
 T_SUPERVISOR_EMAIL VARCHAR2(100) :=NULL; -- Pankaj
 T_LASTUPDATE   WORKORDER.STATUSDATE%TYPE;
 T_STATUS WORKORDER.STATUS%TYPE;
 T_WREL_URL VARCHAR2(2000);
 

CURSOR  FOLLOWUPWREL_CUR IS
    SELECT WONUM, DESCRIPTION, WORKTYPE,  REPORTEDBY, LOCATION, LEAD, SUPERVISOR, STATUS,
   (SELECT DESCRIPTION FROM SYNONYMDOMAIN WHERE DOMAINID = 'WOSTATUS' AND VALUE = WORKORDER.STATUS ) STATUSDESC,
   (SELECT LDTEXT FROM LONGDESCRIPTION WHERE LDOWNERTABLE = 'WORKORDER' and LDOWNERCOL = 'DESCRIPTION' and LDKEY = WORKORDER.WORKORDERID) LONGDESC,
   (SELECT WTYPEDESC FROM WORKTYPE WHERE WORKTYPE = WORKORDER.WORKTYPE) WORKTYPEDESC,
   (SELECT DISPLAYNAME FROM PERSON WHERE PERSONID = WORKORDER.LEAD) LEADNAME,
   (SELECT DISPLAYNAME FROM PERSON WHERE PERSONID = WORKORDER.SUPERVISOR) SUPERVISORNAME,  
   (SELECT DISPLAYNAME FROM PERSON WHERE PERSONID = WORKORDER.REPORTEDBY) REPORTEDBYNAME,  
   to_char(TARGSTARTDATE, 'MM/DD/YYYY') TARGSTART, to_char(TARGCOMPDATE, 'MM/DD/YYYY') TARGCOMP, 
   to_char(SCHEDSTART, 'MM/DD/YYYY') SCHEDSTART, to_char(SCHEDFINISH, 'MM/DD/YYYY') SCHEDFINISH, 
   to_char(REPORTDATE, 'MM/DD/YYYY') REPORTDATE, to_char(STATUSDATE, 'MM/DD/YYYY') STATUSDATE,
   (SELECT MEMO FROM WOSTATUS WHERE WONUM = WORKORDER.WONUM AND STATUS = WORKORDER.STATUS AND CHANGEDATE = WORKORDER.STATUSDATE) MEMO
   FROM   WORKORDER 
   WHERE  ORGID = 'LBNL' and SITEID = 'FAC' and STATUS in ('WREL') AND ISTASK = 0
   AND TRUNC(SYSDATE) - TRUNC(STATUSDATE) >= 2
   AND MOD(TRUNC(SYSDATE) - TRUNC(STATUSDATE), 2) = 0 ;

 CURSOR MAXVAR_CUR IS
   SELECT VARNAME, VARVALUE FROM MAXIMO.LBL_MAXVARS
   WHERE VARNAME IN ('TEST_USER_ID','APPLICATION_ENV');


 PROCEDURE SEND_EMAIL(T_SUBJECT IN VARCHAR2,
                      T_BODY    IN VARCHAR2,
                      T_TESTUSER_EMAIL  IN VARCHAR2,
                      T_APP_ENVIRONMENT IN VARCHAR2,
                      T_SUPERVISOR IN VARCHAR2,
                      T_LOCATION IN VARCHAR2,
                      T_STATUS IN VARCHAR2)

 IS
---- select Location Authorizer email address

   CURSOR LOCAUTHORIZER_CUR IS
    SELECT EMAILADDRESS FROM MAXIMO.EMAIL
    WHERE  personid in 
    (select personid from LBL_AUTH_RELEASE WHERE 
     LOCATION = T_LOCATION and siteid='FAC' and receive_email = 'Y') -- Pankaj as per index   
    AND ISPRIMARY=1 ;


   BEGIN
    T_SUPERVISOR_EMAIL := NULL; -- Pankaj 

   IF (T_APP_ENVIRONMENT !='PRODUCTION') THEN

        LBL_MAXIMO_PKG.SEND_MAIL_HTML(T_TESTUSER_EMAIL,-- TO 
           'wpc@lbl.gov', -- FROM 
           T_SUBJECT,
           T_BODY,
           T_BODY,
           'smtp.lbl.gov',
           25);
           
   ELSE -- PROD ENV

        IF (T_SUPERVISOR is not null) THEN
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
           
        END IF;   -- Supervisor's email           

         IF ( T_LOCATION IS NOT NULL) THEN
            FOR LOCAUTHORIZER_REC IN LOCAUTHORIZER_CUR
                LOOP     
                    IF  (LOCAUTHORIZER_REC.EMAILADDRESS IS NOT NULL) THEN       
                        LBL_MAXIMO_PKG.SEND_MAIL_HTML(LOCAUTHORIZER_REC.EMAILADDRESS,
                        'wpc@lbl.gov', -- FROM
                        T_SUBJECT,
                        T_BODY,
                        T_BODY,
                        'smtp.lbl.gov',
                        25);
                    END IF;
                END LOOP;
         END IF;  -- Authorizer's email
        
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

    SELECT A.EMAILADDRESS
    INTO T_TESTUSER_EMAIL
    FROM MAXIMO.EMAIL A
    WHERE A.PERSONID=T_TEST_USER_ID   
    AND A.ISPRIMARY=1;

    SELECT VARVALUE
    INTO T_WREL_URL
    FROM LBL_MAXVARS
    WHERE VARNAME = 'WOREL_URL';


    IF (T_APP_ENVIRONMENT !='PRODUCTION') THEN
       T_SUBJECT :='(TEST)';
       T_FOOTER  :='THIS DATA IS GENERATED FROM THE TEST DATABASE AND IT DOES NOT REPRESENT PRODUCTION DATABASE';
    END IF;


FOR FOLLOWUPWREL_REC IN FOLLOWUPWREL_CUR

     LOOP

        T_BODY1  :='<HTML><HEAD><TITLE>The Status of the Facilities work order is changed</TITLE></HEAD>';
        T_BODY1  := T_BODY1  || '<BODY><TABLE><TR><TD>';
        T_BODY1  := T_BODY1  || 'Hello, ' || '</TD></TR>';
        T_BODY1  := T_BODY1  || '<TR><TD>&nbsp;</TD></TR>';
        T_BODY1  := T_BODY1  || '<TR><TD>Given below are the details of the work order:</TD></TR>';
        T_BODY1  := T_BODY1  || '<TR><TD>&nbsp;</TD></TR>';


        -- COMPOSING EMAIL CONTAINS
        T_SUBJECT := ' The status of the Facilities work order ' || FOLLOWUPWREL_REC.WONUM || ' is now changed to ' || FOLLOWUPWREL_REC.STATUS;
        T_BODY2 := '<TABLE BORDER=1 ALIGN=LEFT>';

        T_BODY2 := T_BODY2    || '<TR><TD>' || 'Work order number: ' || '</TD><TD>' || FOLLOWUPWREL_REC.WONUM || '</TD</TR>';
        T_BODY2 := T_BODY2    || '<TR><TD>' || 'Requested Work: ' || '</TD><TD>' || FOLLOWUPWREL_REC.DESCRIPTION || '</TD></TR>';
        T_BODY2 := T_BODY2    || '<TR><TD>' || 'Long Description: ' || '</TD><TD>' || FOLLOWUPWREL_REC.LONGDESC || '</TD</TR>';
        T_BODY2 := T_BODY2    || '<TR><TD>' || 'Work Type:  ' || '</TD><TD>' || FOLLOWUPWREL_REC.WORKTYPE ||' - ' || FOLLOWUPWREL_REC.WORKTYPEDESC ||'</TD</TR>';
        T_BODY2 := T_BODY2    || '<TR><TD>' || 'Reported By: ' || '</TD><TD>' || FOLLOWUPWREL_REC.REPORTEDBY ||' - '|| FOLLOWUPWREL_REC.REPORTEDBYNAME || '</TD</TR>';
        T_BODY2 := T_BODY2    || '<TR><TD>' || 'Date Report - ' || '</TD><TD>' || FOLLOWUPWREL_REC.REPORTDATE || '</TD</TR>';
        T_BODY2 := T_BODY2    || '<TR><TD>' || 'Lead: ' || '</TD><TD>' || FOLLOWUPWREL_REC.LEAD || ' - ' || FOLLOWUPWREL_REC.LEADNAME || '</TD</TR>';
        T_BODY2 := T_BODY2    || '<TR><TD>' || 'Supervisor: ' || '</TD><TD>' || FOLLOWUPWREL_REC.SUPERVISOR || ' - ' || FOLLOWUPWREL_REC.SUPERVISORNAME || '</TD</TR>';
        T_BODY2 := T_BODY2    || '<TR><TD>' || 'Location: ' || '</TD><TD>' || FOLLOWUPWREL_REC.LOCATION || '</TD</TR>';
        T_BODY2 := T_BODY2    || '<TR><TD>' || 'Current Status: ' || '</TD><TD>' || FOLLOWUPWREL_REC.STATUS || ' - ' || FOLLOWUPWREL_REC.STATUSDESC || '</TD</TR>';
        T_BODY2 := T_BODY2    || '<TR><TD>' || 'Status Memo: ' || '</TD><TD>' || FOLLOWUPWREL_REC.MEMO || '</TD</TR>';
        T_BODY2 := T_BODY2    || '<TR><TD>' || 'Status Date: ' || '</TD><TD>' || FOLLOWUPWREL_REC.STATUSDATE ||  '</TD></TR>';
        T_BODY2 := T_BODY2    || '<TR><TD>' || 'Target Start Date:  ' || '</TD><TD>' || FOLLOWUPWREL_REC.TARGSTART || '</TD></TR>';
        T_BODY2 := T_BODY2    || '<TR><TD>' || 'Target Completion Date: ' || '</TD><TD>' || FOLLOWUPWREL_REC.TARGCOMP || '</TD></TR>';
        
        IF FOLLOWUPWREL_REC.STATUS in ('REL', 'RFI') THEN
            T_BODY2 := T_BODY2    || '<TR><TD>' || 'Scheduled Start Date:  ' || '</TD><TD>' || FOLLOWUPWREL_REC.SCHEDSTART || '</TD></TR>';
            T_BODY2 := T_BODY2    || '<TR><TD>' || 'Scheduled Finish Date: ' || '</TD><TD>' || FOLLOWUPWREL_REC.SCHEDFINISH || '</TD></TR>';
        END IF;
        
        T_BODY2 := T_BODY2    || '</TABLE>';
        
        T_BODY2 := T_BODY2    || '<br>';
        T_BODY2 := T_BODY2    || '<TR><TD>' || 'In order for the Facilities commence work, you are requested to either change the status of the work order to release. Alternatively, you can change the status of the work order to request for more information.' ||  '</TD></TR>';
        T_BODY2 := T_BODY2    || '<br>';
        T_BODY2 := T_BODY2    || '<TR><TD>' || '<a href= ' || T_WREL_URL || '>Work Order Release Page</a>'  ||  '</TD></TR>';
        T_BODY2 := T_BODY2    || '<br>';
        T_BODY2 := T_BODY2    || '<TR><TD>' || 'You can contact the Facilities Work Planning and Control group wpc@lbl.gov or dial x6300 for any clarifications.' ||  '</TD></TR>';
        T_BODY2 := T_BODY2    || '<br>';
        T_BODY2 := T_BODY2    || '<TR><TD>' || 'Facilities Work Planning and Control' ||  '</TD></TR>' ;
        T_BODY2 := T_BODY2 || '</TABLE></TD></TR><TR><TD>&nbsp;</TD></TR><TR><TD>&nbsp;</TD></TR>';
        T_BODY2 := T_BODY2 || '<TR><TD>&nbsp;</TD></TR><TR><TD>&nbsp;</TD></TR>';

      IF (T_APP_ENVIRONMENT !='PRODUCTION') THEN
        T_BODY2 := T_BODY2 || '<TR><TD>' || T_FOOTER || '</TD></TR>';
      END IF;

        T_BODY2 := T_BODY2 || ' </TABLE></BODY></HTML>';
        T_BODY  := T_BODY1 || T_BODY2;


     SEND_EMAIL(T_SUBJECT, T_BODY, T_TESTUSER_EMAIL, T_APP_ENVIRONMENT, FOLLOWUPWREL_REC.SUPERVISOR, 
        FOLLOWUPWREL_REC.LOCATION, FOLLOWUPWREL_REC.STATUS);
   END LOOP;

 END;

 /

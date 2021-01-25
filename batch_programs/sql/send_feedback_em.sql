set scan off
/***************************************************************************
*
* PROGRAM NAME          : send_feedback_em.SQL
*
*
* DESCRIPTION           : Send out an email to customer and reporter for filling customer feedback survey.
*
*
* AUTHOR                : Annette Leung
*
* DATE WRITTEN          : JULY 25, 2017
* DATE MODIFIED         :
*
* MODIFICATION HISORTY  :
***************************************************************************/
WHENEVER SQLERROR EXIT 1 ROLLBACK;

DECLARE

 T_SENDTOWO1 NUMBER (7) :=0;
 T_BODY      VARCHAR2(32000);
 T_BODY1     VARCHAR2(32000);
 T_BODY2     VARCHAR2(32000);
 T_BODY_REPORTEDBY VARCHAR2(32000);
 T_BODY_CUSTOMER VARCHAR2(32000);
 T_APP_ENVIRONMENT VARCHAR2(200);
 T_TEST_USER_ID    VARCHAR2(1000);
 T_TESTUSER_EMAIL VARCHAR2(100);
 T_FEEDBACK_URL VARCHAR2(2000);
 T_SUBJECT VARCHAR2(32000);
 T_FOOTER  VARCHAR2(2000);
 T_RECEIPENT VARCHAR2(100);
 T_RECEIPENT_EMAIL VARCHAR2(100);
 

CURSOR  FEEDBACKEMAIL_CUR IS
    SELECT A.WONUM, A.INSERTDATE, A.EMAILSENTDATE,
    B.DESCRIPTION, B.LOCATION, B.STATUSDATE, B.STATUS, 
    B.REPORTEDBY, B.WO1, 
    B.LEAD, (SELECT DISPLAYNAME FROM PERSON WHERE PERSONID = B.LEAD) LEADNAME, 
    (SELECT PHONENUM FROM PHONE WHERE PERSONID = B.LEAD) LEADPHONE,
    B.SUPERVISOR, (SELECT DISPLAYNAME FROM PERSON WHERE PERSONID = B.SUPERVISOR) SUPERVISORNAME, 
    (SELECT PHONENUM FROM PHONE WHERE PERSONID = B.SUPERVISOR) SUPERVISORPHONE
    FROM BATCH_MAXIMO.LBL_WOFEEDBACK_REQUEST A, WORKORDER B
    WHERE A.WONUM = B.WONUM 
    AND A.EMAILSENTDATE IS NULL;
    
CURSOR MAXVAR_CUR IS
   SELECT VARNAME, VARVALUE FROM MAXIMO.LBL_MAXVARS
   WHERE VARNAME IN ('TEST_USER_ID','APPLICATION_ENV');    


PROCEDURE SEND_EMAIL(T_SUBJECT IN VARCHAR2,
                      T_BODY    IN VARCHAR2,
                      T_TESTUSER_EMAIL  IN VARCHAR2,
                      T_APP_ENVIRONMENT IN VARCHAR2,
                      T_RECEIPENT IN VARCHAR2)

 IS
---- select receipent's email address

    BEGIN
    
        T_RECEIPENT_EMAIL := NULL;  

        IF (T_APP_ENVIRONMENT !='PRODUCTION') THEN
            LBL_MAXIMO_PKG.SEND_MAIL_HTML(T_TESTUSER_EMAIL,-- TO 
                'wpc@lbl.gov', -- FROM 
                T_SUBJECT,
                T_BODY,
                T_BODY,
                'smtp.lbl.gov',
                25);
           
        ELSE -- PROD ENV
  
          IF (T_RECEIPENT is not null) THEN
                BEGIN
                    SELECT A.EMAILADDRESS
                    INTO T_RECEIPENT_EMAIL
                    FROM MAXIMO.EMAIL A
                    WHERE A.PERSONID=T_RECEIPENT   
                    AND A.ISPRIMARY=1;
    
                    EXCEPTION WHEN OTHERS THEN
                        T_RECEIPENT_EMAIL := NULL;
                END;
            END IF;

            IF ( T_RECEIPENT_EMAIL IS NOT NULL) THEN                                     
                LBL_MAXIMO_PKG.SEND_MAIL_HTML(T_RECEIPENT_EMAIL,
                'wpc@lbl.gov', -- FROM
                T_SUBJECT,
                T_BODY,
                T_BODY,
                'smtp.lbl.gov',
                25);
            END IF; -- Receipent's email         
        
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
    INTO T_FEEDBACK_URL
    FROM LBL_MAXVARS
    WHERE VARNAME = 'WO_FEEDBACK_URL';
    
   -- READ RECORDS
   FOR FEEDBACKEMAIL_REC IN FEEDBACKEMAIL_CUR

     LOOP
        T_SUBJECT := NULL;
        T_FOOTER := NULL;
        T_SENDTOWO1 := 0;
        T_BODY1 := NULL;
        T_BODY_REPORTEDBY := NULL;
        T_BODY_CUSTOMER := NULL;
        
        IF(FEEDBACKEMAIL_REC.REPORTEDBY != FEEDBACKEMAIL_REC.WO1) and (FEEDBACKEMAIL_REC.WO1 is not null) THEN
            T_SENDTOWO1 := 1;
        END IF;
        
        IF (T_APP_ENVIRONMENT !='PRODUCTION') THEN
            T_SUBJECT :='[TEST]';
            T_FOOTER  :='[This email is generated from the TEST data and it does not represent the actual data]';
        END IF;

        T_BODY  :='<HTML><HEAD><TITLE>Work Order Completed</TITLE></HEAD>';
        T_BODY  := T_BODY  || '<BODY><TABLE><TR><TD>';
        T_BODY  := T_BODY  || 'Hello, ' || '<BR></TD></TR><TR><TD>&nbsp;</TD></TR>';
        T_BODY  := T_BODY  || '<TR><TD>' || 'The Facilities Division is pleased to inform you that the work requested below was completed on ' || FEEDBACKEMAIL_REC.WONUM || '.</TD</TR><TR><TD>&nbsp;</TD></TR>';
        T_BODY  := T_BODY  || '<TR><TD>' || 'We would appreciate it if you could take a few moments to let us know how well the Facilities Division addressed your needs.'    || '</TD><TR>';
        T_BODY  := T_BODY  || '<TR><TD>&nbsp;</TD></TR>';

        -- COMPOSING EMAIL CONTAINS
        T_SUBJECT := T_SUBJECT || ' Feedback requested on Facilities work order ' || FEEDBACKEMAIL_REC.WONUM;
   
        T_BODY1 := T_BODY1    || '<TR><TD>&nbsp;</TD></TR>';
        T_BODY1 := T_BODY1    || '<TR><TD>' || 'We are committed to serving you and are continuously working to improve our service. '  || '</TD</TR><TR><TD>&nbsp;</TD></TR>';
        T_BODY1 := T_BODY1    || '<TR><TD>' || 'Thank you. '  || '</TD</TR>';      
          
        T_BODY2 := '<TABLE BORDER=1 ALIGN=LEFT>';  
        T_BODY2 := T_BODY2    || '<TR><TD>' || 'Work order number: ' || '</TD><TD>' || FEEDBACKEMAIL_REC.WONUM || '</TD</TR>';
        T_BODY2 := T_BODY2    || '<TR><TD>' || 'Description: '    || '</TD><TD>' || FEEDBACKEMAIL_REC.DESCRIPTION || '</TD</TR>';
        T_BODY2 := T_BODY2    || '<TR><TD>' || 'Location: '    || '</TD><TD>' || FEEDBACKEMAIL_REC.LOCATION || '</TD</TR>';
        IF (FEEDBACKEMAIL_REC.LEADPHONE is not null) and (length(FEEDBACKEMAIL_REC.LEADPHONE)> 0)THEN
            T_BODY2 := T_BODY2    || '<TR><TD>' || 'Lead: ' || '</TD><TD>' || FEEDBACKEMAIL_REC.LEAD || ' - ' || FEEDBACKEMAIL_REC.LEADNAME || ' (' || FEEDBACKEMAIL_REC.LEADPHONE  || ')' || '</TD</TR>';
        ELSE
            T_BODY2 := T_BODY2    || '<TR><TD>' || 'Lead: '        || '</TD><TD>' || FEEDBACKEMAIL_REC.LEAD || ' - ' || FEEDBACKEMAIL_REC.LEADNAME || '</TD</TR>';            
        END IF;
        IF (FEEDBACKEMAIL_REC.SUPERVISORPHONE is not null) and (length(FEEDBACKEMAIL_REC.SUPERVISORPHONE)> 0) THEN
            T_BODY2 := T_BODY2    || '<TR><TD>' || 'Supervisor: ' || '</TD><TD>' || FEEDBACKEMAIL_REC.SUPERVISOR || ' - ' || FEEDBACKEMAIL_REC.SUPERVISORNAME || ' ('  ||  FEEDBACKEMAIL_REC.SUPERVISORPHONE || ')'  || '</TD</TR>';
        ELSE
            T_BODY2 := T_BODY2    || '<TR><TD>' || 'Supervisor: '  || '</TD><TD>' || FEEDBACKEMAIL_REC.SUPERVISOR || ' - ' || FEEDBACKEMAIL_REC.SUPERVISORNAME || '</TD</TR>';
        END IF;
        T_BODY2 := T_BODY2    || '<TR><TD>' || 'Status: '  || '</TD><TD>'  || FEEDBACKEMAIL_REC.STATUS || '</TD</TR>';
        T_BODY2 := T_BODY2    || '<TR><TD>' || 'Status Date: '  || '</TD><TD>' || FEEDBACKEMAIL_REC.STATUSDATE ||  '</TD></TR>';
        T_BODY2 := T_BODY2    || '</TABLE>';
        T_BODY2  := T_BODY2  || '<TR><TD>&nbsp;</TD></TR>';
        T_BODY_REPORTEDBY := T_BODY2 || '<TR><TD>' || '<a href=' || T_FEEDBACK_URL || '?action=validate&wonum=' || FEEDBACKEMAIL_REC.WONUM || '&customerid='|| FEEDBACKEMAIL_REC.REPORTEDBY || '><B>Please click on this link to record your feedback for the work performed.</B></a>'  ||  '</TD></TR>';
        T_BODY_REPORTEDBY := T_BODY_REPORTEDBY || T_BODY1;
        T_BODY_REPORTEDBY := T_BODY_REPORTEDBY    || '<br>';
        T_BODY_REPORTEDBY := T_BODY_REPORTEDBY    || '<TR><TD>&nbsp;</TD></TR><TR><TD>&nbsp;</TD></TR>';
        
        IF T_SENDTOWO1 = 1 THEN         
            T_BODY_CUSTOMER   := T_BODY2 || '<TR><TD>' || '<a href=' || T_FEEDBACK_URL || '?action=validate&wonum=' || FEEDBACKEMAIL_REC.WONUM || '&customerid='|| FEEDBACKEMAIL_REC.WO1 || '><B>Please click on this link to record your feedback for the work performed.</B></a>'  ||  '</TD></TR>';
            T_BODY_CUSTOMER := T_BODY_CUSTOMER || T_BODY1;
            T_BODY_CUSTOMER := T_BODY_CUSTOMER    || '<br>';
            T_BODY_CUSTOMER := T_BODY_CUSTOMER    || '<TR><TD>&nbsp;</TD></TR><TR><TD>&nbsp;</TD></TR>';
        END IF;
        
        IF (T_APP_ENVIRONMENT !='PRODUCTION') THEN
            T_BODY_REPORTEDBY := T_BODY_REPORTEDBY || '<TR><TD>' || T_FOOTER || '</TD></TR>';
            T_BODY_CUSTOMER := T_BODY_CUSTOMER || '<TR><TD>' || T_FOOTER || '</TD></TR>';
        ELSE
            T_BODY_REPORTEDBY := T_BODY_REPORTEDBY || ' </TABLE></BODY></HTML>';
            T_BODY_CUSTOMER := T_BODY_CUSTOMER || ' </TABLE></BODY></HTML>';
        END IF;  -- Environment
        
            T_BODY_REPORTEDBY := T_BODY || T_BODY_REPORTEDBY;
            SEND_EMAIL(T_SUBJECT, T_BODY_REPORTEDBY, T_TESTUSER_EMAIL, T_APP_ENVIRONMENT, FEEDBACKEMAIL_REC.REPORTEDBY);
        
            IF T_SENDTOWO1 = 1 THEN
                T_BODY_CUSTOMER :=  T_BODY_CUSTOMER || ' </TABLE></BODY></HTML>';
                T_BODY_CUSTOMER :=  T_BODY || T_BODY_CUSTOMER;
                SEND_EMAIL(T_SUBJECT, T_BODY_CUSTOMER, T_TESTUSER_EMAIL, T_APP_ENVIRONMENT, FEEDBACKEMAIL_REC.WO1); 
            END IF; -- Customer's email

        UPDATE BATCH_MAXIMO.LBL_WOFEEDBACK_REQUEST
            SET BATCH_MAXIMO.LBL_WOFEEDBACK_REQUEST.EMAILSENTDATE = SYSDATE
            WHERE BATCH_MAXIMO.LBL_WOFEEDBACK_REQUEST.WONUM = FEEDBACKEMAIL_REC.WONUM;
            
        COMMIT;
                
    END LOOP;
    
 END;

/

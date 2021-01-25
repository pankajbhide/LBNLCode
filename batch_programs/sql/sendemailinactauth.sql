/***************************************************************************
*
* PROGRAM NAME          : SENDEMAILINACTAUTH.SQL
*
*
* DESCRIPTION           : THIS PL/SQL SCRIPT FINDS OUT WHETHER ANY AUTHORIZER 
*                         STATUS IS INACTIVE. IF FOUND, THEN, IT UPDATES THE 
*                         INACTIVE STATUS NOTIFICATION DATE. 
*                         IN THE NEXT PHASE, IT SENDS THE EMAIL TO DIVISIONAL
*                         SAFETY COORDINATORS. 
*
*      
* AUTHOR                : PANKAJ BHIDE
*
* DATE WRITTEN          : 01-DEC-2015
* DATE MODIFIED         :
*
* MODIFICATION HISORTY  : 
***************************************************************************/
DECLARE CURSOR  INACTIVE_AUTH_CUR IS 

 SELECT A.PERSONID, C.DISPLAYNAME, A.BUILDING_NUMBER,A.ROOM_NUMBER, NVL(B.LO7,'BLANK') DIVISION
 FROM   LBL_AUTH_RELEASE A, LOCATIONS B, PERSON C
 WHERE  A.LOCATION=B.LOCATION
 AND    A.PERSONID=C.PERSONID 
 AND    B.DISABLED=0 -- ADDDED BY PANKAJ ON 1/14/16 EF-2396 
 AND TRUNC(A.DTINACTIVENOTIFY) <= TRUNC(SYSDATE)
 ORDER BY NVL(B.LO7,'BLANK'), A.PERSONID, A.LOCATION ;
 
 PRV_DV_ID   VARCHAR2(50);
 ROW_COUNT_T NUMBER (7) :=0;
 T_BODY1     VARCHAR2(32000);
 T_BODY2     VARCHAR2(32000);
 T_BODY3     VARCHAR2(32000);
 T_BODY      VARCHAR2(32000);
 PRV_DELTADATE DATE;
 T_APP_ENVIRONMENT VARCHAR2(200);
 T_TEST_USER_ID    VARCHAR2(1000);
 T_SUBJECT VARCHAR2(2000) :=' ';
 T_FOOTER  VARCHAR2(2000); 
 T_INACTIVE_AUTH_NOTIFY NUMBER(5);
 

 T_TESTUSER_EMAIL VARCHAR2(100);
 
 
 CURSOR MAXVAR_CUR IS
   SELECT VARNAME, VARVALUE FROM MAXIMO.LBL_MAXVARS
   WHERE VARNAME IN ('TEST_USER_ID','APPLICATION_ENV','INACTIVEAUTH_NOTIFY');
 
 
 PROCEDURE SEND_EMAIL(T_SUBJECT IN VARCHAR2,
                      T_BODY    IN VARCHAR2,
                      T_DIV     IN VARCHAR2,
                      T_TESTUSER_EMAIL  IN VARCHAR2,
                      T_APP_ENVIRONMENT IN VARCHAR2)
 
 IS
 
 CURSOR SAFETYCOORD_CUR IS
   SELECT EMAIL FROM EHS_COMMON.SAFETYCOORDS@EHS.LBL.GOV 
   WHERE ORG_LEVEL_1_CODE=T_DIV
   UNION
   SELECT EMAIL FROM EHS_COMMON.SAFETYCOORDS_BACKUP@EHS.LBL.GOV 
   WHERE ORG_LEVEL_1_CODE=T_DIV;
   
    
 
   BEGIN
   
   IF (T_APP_ENVIRONMENT !='PRODUCTION') THEN
   
    LBL_MAXIMO_PKG.SEND_MAIL_HTML(T_TESTUSER_EMAIL,-- TO 
           'wpc@lbl.gov', -- FROM 
           T_SUBJECT, 
           T_BODY,
           T_BODY, 
           'smtp.lbl.gov',
           25);   
 
   ELSE -- PROD ENV 
   
      IF (T_DIV='BLANK') THEN
                      
           LBL_MAXIMO_PKG.SEND_MAIL_HTML('wpc@lbl.gov', -- TO 
           'wpc@lbl.gov', -- FROM 
           T_SUBJECT, 
           T_BODY,
           T_BODY, 
           'smtp.lbl.gov',
           25);   
 
      ELSE     
      
         FOR SAFETYCOORD_REC IN SAFETYCOORD_CUR
         
         LOOP
           
           LBL_MAXIMO_PKG.SEND_MAIL_HTML(SAFETYCOORD_REC.EMAIL,
           'wpc@lbl.gov', -- FROM 
           T_SUBJECT, 
           T_BODY,
           T_BODY, 
           'smtp.lbl.gov',
           25);
        END LOOP;   
      END IF; -- T_DIV IS NULL 
  END IF ; -- IF (T_APP_ENVIRONMENT !='PRODUCTION') THEN         

 END;  
 
 FUNCTION BEFORE_DIVISION(I_DV_ID IN VARCHAR2)
   RETURN VARCHAR2
  
  IS
   O_BODY VARCHAR2(32000); 
   BEGIN
    O_BODY  :='<TR><TD><B>Division: ' || I_DV_ID ||'</B></TD></TR>';
    O_BODY  := O_BODY  || '<TR><TD><B>Date: ' || TO_CHAR(SYSDATE,'DD-Mon-YYYY') || '<B></TD></TR>';
    O_BODY  := O_BODY  || '<TR><TD>&nbsp;</TD></TR>';
    O_BODY  := O_BODY  || '<TR><TD>';
    O_BODY  := O_BODY  || '<TABLE BORDER=1  style=' || '"border-collapse:collapse"' ||' ALIGN=LEFT>';
    O_BODY  := O_BODY  || '<TR><TD><B>Authorizer Id</B></TD><TD><B>Authorizer Name</B></TD><TD><B>Building Number</B></TD>'; 
    O_BODY  := O_BODY  || '<TD><B>Room Number</B></TD></TR>'; 
    
    RETURN O_BODY;
   END; 
    
 
 
 BEGIN
 
    FOR MAXVARS_REC IN MAXVAR_CUR
     
     LOOP
     
       IF (MAXVARS_REC.VARNAME='APPLICATION_ENV') THEN
          T_APP_ENVIRONMENT :=MAXVARS_REC.VARVALUE;
       END IF;
       
       IF (MAXVARS_REC.VARNAME='TEST_USER_ID') THEN
          T_TEST_USER_ID :=MAXVARS_REC.VARVALUE;
       END IF;
       
       IF (MAXVARS_REC.VARNAME='INACTIVEAUTH_NOTIFY') THEN
          T_INACTIVE_AUTH_NOTIFY :=TO_NUMBER(MAXVARS_REC.VARVALUE);
       END IF;
       
       IF (T_INACTIVE_AUTH_NOTIFY IS NULL) THEN
         T_INACTIVE_AUTH_NOTIFY :=0;
       END IF;
        

       
    END LOOP;
    
    SELECT A.EMAILADDRESS 
    INTO T_TESTUSER_EMAIL
    FROM MAXIMO.EMAIL A
    WHERE A.PERSONID=T_TEST_USER_ID
    AND A.ISPRIMARY=1;
    
    IF (T_APP_ENVIRONMENT !='PRODUCTION') THEN
       T_SUBJECT :='(TEST)';
       T_FOOTER  :='THIS DATA IS GENERATED FROM THE TEST DATABASE AND IT DOES NOT REPRESENT PRODUCTION DATABASE';
    END IF;
    
    T_SUBJECT := TRIM(T_SUBJECT || ' List of inactive authorizers of the technical areas designated by your division.');
    
  
    T_BODY1  :='<HTML><HEAD><TITLE>List of Inactive Authorizers of the rooms</TITLE></HEAD>';
    T_BODY1  := T_BODY1  || '<BODY><TABLE><TR><TD>';
    T_BODY1  := T_BODY1  || 'Hello, ' || '</TD></TR>';  
    T_BODY1  := T_BODY1  || '<TR><TD>&nbsp;</TD></TR>';
    T_BODY1  := T_BODY1  || '<TR><TD>Given below is a list of inactive authorizers of the technical areas designated by your division. Please review and update with a current Lab employee. </TD></TR>';
    T_BODY1  := T_BODY1  || '<TR><TD>&nbsp;</TD></TR>';
   
 
    -- PHASE 1 UPDATE INACTIVE NOTIFICATION DATE FOR INACTIVE AUTHORIZERS
    UPDATE LBL_AUTH_RELEASE A 
    SET A.DTINACTIVENOTIFY=SYSDATE + T_INACTIVE_AUTH_NOTIFY
    WHERE A.DTINACTIVENOTIFY IS NULL 
    AND  NOT EXISTS (SELECT 1 FROM EDW_SHARE.PEOPLE_CURRENT B 
    WHERE B.EMPLOYEE_ID=A.PERSONID);
   
    -- PHASE 2 UPDATE INACTIVATED AUTHORIZERS IF FOUND ACTIVE NOW 
    UPDATE LBL_AUTH_RELEASE A 
    SET A.DTINACTIVENOTIFY=NULL
    WHERE A.DTINACTIVENOTIFY IS NOT NULL 
    AND  EXISTS (SELECT 1 FROM EDW_SHARE.PEOPLE_CURRENT B 
    WHERE B.EMPLOYEE_ID=A.PERSONID);
    
    -- PHASE 3 START SENDING EMAIL NOTIFICATION 
  
   -- READ RECORDS FROM ROOM DELTA TABLE 
   FOR INACTIVE_AUTH_REC IN INACTIVE_AUTH_CUR
   
     LOOP
     
       ROW_COUNT_T := ROW_COUNT_T+1 ;
       
            
       IF (ROW_COUNT_T =1) THEN
          PRV_DV_ID     := INACTIVE_AUTH_REC.DIVISION;
          T_BODY2 :=BEFORE_DIVISION(PRV_DV_ID);
      END IF;
      
      -- DIVISION CHANGES    
      IF (PRV_DV_ID !=INACTIVE_AUTH_REC.DIVISION) THEN
        T_BODY3 := T_BODY3 || '</TABLE></TD></TR><TR><TD>&nbsp;</TD></TR><TR><TD>&nbsp;</TD></TR>';
        T_BODY3 := T_BODY3 || '<TR><TD>&nbsp;</TD></TR><TR><TD>&nbsp;</TD></TR>';
        T_BODY3 := T_BODY3 || '<TR><TD>' || T_FOOTER || '</TD></TR>';
        T_BODY3 := T_BODY3 || ' </TABLE></BODY></HTML>';
        T_BODY  := T_BODY1 || T_BODY2 || T_BODY3;
        
        SEND_EMAIL(T_SUBJECT,T_BODY,PRV_DV_ID,
                   T_TESTUSER_EMAIL ,T_APP_ENVIRONMENT); 
                
         PRV_DV_ID  := INACTIVE_AUTH_REC.DIVISION;
         T_BODY2    :=BEFORE_DIVISION(PRV_DV_ID);
         T_BODY3    := ' ';
      END IF;
      
      -- CONTIUNUE COMPOSING REPORT THAT CONTAINS THE DETAILS OF ROOMS HAVING DELTA 
      T_BODY3 := T_BODY3    || '<TR><TD>' || INACTIVE_AUTH_REC.PERSONID || '</TD>';
      T_BODY3 := T_BODY3    || '<TD>' || INACTIVE_AUTH_REC.DISPLAYNAME|| '</TD>';
      T_BODY3 := T_BODY3    || '<TD>' || INACTIVE_AUTH_REC.BUILDING_NUMBER || '</TD>';
      T_BODY3 := T_BODY3    || '<TD>' || INACTIVE_AUTH_REC.ROOM_NUMBER ||  '</TD></TR>' ;
     
    
   END LOOP;
   
    IF (ROW_COUNT_T >= 1) THEN 
        T_BODY3 := T_BODY3 || '</TABLE></TD></TR><TR><TD>&nbsp;</TD></TR><TR><TD>&nbsp;</TD></TR>';
        T_BODY3 := T_BODY3 || '<TR><TD>&nbsp;</TD></TR><TR><TD>&nbsp;</TD></TR>';
        T_BODY3 := T_BODY3 || '<TR><TD>' || T_FOOTER || '</TD></TR>';
        T_BODY3 := T_BODY3 || ' </TABLE></BODY></HTML>';
        T_BODY  := T_BODY1 || T_BODY2 || T_BODY3;
        
        SEND_EMAIL(T_SUBJECT,T_BODY,PRV_DV_ID,
                   T_TESTUSER_EMAIL ,T_APP_ENVIRONMENT); 
   END IF;
       
   

 END;
 
 /
          
       

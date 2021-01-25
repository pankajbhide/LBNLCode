/*******************************************************************************
 PROGRAM NAME           : EXPIBOXRECIPIENT.SQL

 DATE WRITTEN           : 07-SEP-2016

 AUTHOR                 : PANKAJ BHIDE

 USAGE                  :


 PURPOSE                : INTERFACE PROGRAM TO EXPORT INFORMATION ABOUT
                          EMPLOYESS, LOCATIONS INTO A FLAT FILE FOR EXPORTING
                          IT TO SCLOGIC.

********************************************************************************/
WHENEVER SQLERROR EXIT 1 ROLLBACK;

DECLARE

    CURSOR EMPLOYEE_CUR IS
        SELECT LTRIM(RTRIM(EMPLID)) EMPLID, NAME, FIRST_NAME, LAST_NAME,
               TRIM(ORG_CODE) ORG_CODE, TERMINATION_DT,  -- TRIMMED ON 10/21/15
               SUBSTR(MAIL_DROP,1,12) MAIL_DROP, ZZ_BLDG, ZZ_ROOM,
               NVL(WORK_PHONE,' ') WORK_PHONE, HIRE_DT,
               NVL(EMAILID,' ') EMAILID, EMPL_CLASS, EMPL_STATUS, SUPERVISOR_ID,
               SUBSTR(JOBTITLE,1,30) JOBTITLE,
               SUBSTR(ORG_LEVEL_3_DESC,1,30) DEPARTMENT,
               TRIM(ORG_LEVEL_1_CODE)ORG_LEVEL_1_CODE , TRIM(ORG_LEVEL_2_CODE) ORG_LEVEL_2_CODE,
               TRIM(ORG_LEVEL_3_CODE)ORG_LEVEL_3_CODE,  TRIM(ORG_LEVEL_4_CODE) ORG_LEVEL_4_CODE,
               LBL_MAXIMO_PKG.GET_ROUTE(ZZ_BLDG ||'-'|| ZZ_ROOM) ROUTE
        --FROM DW.PS_EMPLOYEES_PUBLIC@DWPRD
        FROM EDW_SHARE.PS_EMPLOYEES_PUBLIC A
        WHERE NOT EXISTS
        (SELECT 1 FROM EDW_SHARE.PS_EMPLOYEES_PUBLIC B
         WHERE A.EMPLID = B.SUPERVISOR_ID
         AND B.EMPLID = A.SUPERVISOR_ID
         AND B.EMPLID != B.SUPERVISOR_ID)
        AND  A.EMPL_STATUS !='T'  -- ONLY ACTIVE EMPLOYEES
       ORDER BY EMPLID;


     CURSOR ROOM_CUR IS
       SELECT LOCATION, LO1,LO2,DESCRIPTION,
       LBL_MAXIMO_PKG.GET_ROUTE(LOCATION) ROUTE
       FROM LOCATIONS
       WHERE GISPARAM1='R'
       AND   LOCATIONS.DISABLED=0 -- ONLY ACTIVE ROOMS
       ORDER BY 1;

     T_FILEHANDLER UTL_FILE.FILE_TYPE;
     T_FILENAME    VARCHAR2(50);
     T_CONTENT     VARCHAR2(32000);
     ROW_CNT_T NUMBER(10) :=0;



BEGIN

   T_FILENAME     :='Recipient.txt';
   T_FILEHANDLER  :=UTL_FILE.FOPEN('MAXIMO', T_FILENAME, 'W');

   -- START READING EMPLOYEE INFORMATION
   FOR EMPLOYEE_REC IN EMPLOYEE_CUR

    LOOP

        ROW_CNT_T :=ROW_CNT_T + 1;
        IF (ROW_CNT_T =1) THEN
           T_CONTENT :='EmpID|FullName|FirstName|LastName|Route|Building|Room|Mailstop|Phone|Department|Location Description|Vehicle License|EmailAddress|Profile';
           UTL_FILE.PUT_LINE(T_FILEHANDLER, T_CONTENT );
        END IF;

        T_CONTENT := TRIM(EMPLOYEE_REC.EMPLID)         ||'|' ||
                     TRIM(EMPLOYEE_REC.NAME)           ||'|' ||
                     TRIM(EMPLOYEE_REC.FIRST_NAME)     ||'|' ||
                     TRIM(EMPLOYEE_REC.LAST_NAME)      ||'|' ||
                     TRIM(EMPLOYEE_REC.ROUTE)          ||'|' ||
                     TRIM(EMPLOYEE_REC.ZZ_BLDG)        ||'|' ||
                     TRIM(EMPLOYEE_REC.ZZ_ROOM)        ||'|' ||
                     TRIM(EMPLOYEE_REC.MAIL_DROP)      ||'|' ||
                     TRIM(EMPLOYEE_REC.WORK_PHONE)     ||'|' ||
                     TRIM(EMPLOYEE_REC.ORG_CODE)       ||'|' ||
                     '|' || -- LOCATION DESC
                     '|' || -- VEHICLE LICENSE
                     TRIM(EMPLOYEE_REC.EMAILID) || '|' || '1'; -- EMPLOYEE PROFILE 
         UTL_FILE.PUT_LINE(T_FILEHANDLER, T_CONTENT );
      END LOOP;

      -- START READING LOCATION INFORMATION
   FOR ROOM_REC IN ROOM_CUR

    LOOP

        T_CONTENT := TRIM(ROOM_REC.LOCATION)         ||'|' ||
                     TRIM(ROOM_REC.DESCRIPTION)      ||'|' ||
                     TRIM(ROOM_REC.DESCRIPTION)      ||'|' || -- FIRST NAME
                     TRIM(ROOM_REC.DESCRIPTION)      ||'|' || -- LAST NAME
                     TRIM(ROOM_REC.ROUTE)            ||'|' ||
                     TRIM(ROOM_REC.LO1)          ||'|' ||
                     TRIM(ROOM_REC.LO2)          ||'|' ||
                     '|' ||                            -- MAIL_DROP
                     '|' ||                            -- PHONE
                     '|' ||                            -- ORG_CODE
                     '|' || -- LOCATION DESC
                     '|' || -- VEHICLE LICENSE
                     '|0' ;   --  EMAILID AND OTHER PROFILE 
             UTL_FILE.PUT_LINE(T_FILEHANDLER, T_CONTENT );
      END LOOP;


  UTL_FILE.FCLOSE(T_FILEHANDLER);
END;
/

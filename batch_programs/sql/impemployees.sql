/*******************************************************************************
 PROGRAM NAME           : IMPEMPLOYEES.SQL

 DATE WRITTEN           : 17-MARCH-2009

 AUTHOR                 : PANKAJ BHIDE

 USAGE                  : PROGRAM NAME WITH ARGUEMENTS
                          1-ORGID



 PURPOSE                : INTERFACE PROGRAM TO REFRESH INFORMATION ABOUT THE
                          EMPLOYEES FROM DATAWAREHOUSE TO MAXIMO.


                          13-FEB-2010 CHANGED LOGIC FOR INSERTING/UPDATING
                          RECORDS INTO LABORCRAFTRATE

                          24-MAR-2010 DISABLED TRIGGER ON PERSON BEFORE EXECUTION
                          AND ENABLE IT AFTER THE EXECUTION OF THIS PROGRAM

                          PROVIDE PERSON.ROWSTAMP SINCE TRIGGER IS DISABLED.

                          14-JUN-2010 ADDED ORG_LEVEL_1-4 IN CRAFT AND PERSON
                          TABLES

                          21-FEB-2012 CHANGED PS_EMOLOYEES_PUBLIC@DWPRD TO
                          DW.PS_EMPLOYEES_PUBLIC. THIS POINTS TO LOCAL
                          MAT VIEW REFRESHES FROM EDWPRD DATABASE,

                          15-APR-2014 REVISION IN ALLOWING MULTIPLE CRAFT
                          FOR A LABOR. ALSO, IF THE LABOR BELONGS TO A PERSON
                          GROUP FACFIXEDCRAFT, THEN DO NOT CHANGE ITS DEFAULT
                          CRAFT.

                          21-OCT-2015 TRIMMED INPUT FIELD VALUES

                          23-OCT-2015 MODIFIED FOR MAXIMO 7.6 UPGRADE PROJECT

                          21-JUN-2018 AVOID LOOPING FOR EMPLOYEE UPDATE AND 
			              INSERT
                          
                          28-JUN-2018 INACTIATE PERSON/LABOR RECORD IF THE 
                          EMPLOYEE LEAVES THE LABORATORY
*****************************************************************************/
WHENEVER SQLERROR EXIT 1 ROLLBACK;


DECLARE

  ORGID_T            LABOR.ORGID%TYPE;
  SITEID_T           WORKORDER.SITEID%TYPE;
  SUPERVISOR_T       PERSON.SUPERVISOR%TYPE;

  CNT_FIXEDCRAFT_T   NUMBER(5) :=0;
  ROW_ID_T           NUMBER(6) :=0;
  LEVEL_T            NUMBER(6) :=0;
  --T_TOP_EMPLOYEE     PERSON.PERSONID%TYPE;
  EMPLID_T           PERSON.PERSONID%TYPE;
  RESULT_T           VARCHAR2(10);


  TYPE CRAFT_REF_CURSOR IS REF CURSOR;
  CRAFT_CUR            CRAFT_REF_CURSOR;

  TYPE CRAFT_REC IS RECORD
  (
    CRAFT_I        CRAFT.CRAFT%TYPE,
    DESCRIPTION_I  CRAFT.DESCRIPTION%TYPE,
    LBL_ORG_LEVEL_1_I  CRAFT.LBL_ORG_LEVEL_1%TYPE,
    LBL_ORG_LEVEL_2_I  CRAFT.LBL_ORG_LEVEL_2%TYPE,
    LBL_ORG_LEVEL_3_I  CRAFT.LBL_ORG_LEVEL_3%TYPE,
    LBL_ORG_LEVEL_4_I  CRAFT.LBL_ORG_LEVEL_4%TYPE
   );
   CURSOR EMPLOYEE_CUR IS
    SELECT LTRIM(RTRIM(EMPLID)) EMPLID, NAME, FIRST_NAME, LAST_NAME,
           TRIM(ORG_CODE) ORG_CODE, TERMINATION_DT,  -- TRIMMED ON 10/21/15
           SUBSTR(MAIL_DROP,1,12) MAIL_DROP, ZZ_BLDG, ZZ_ROOM,
           NVL(WORK_PHONE,' ') WORK_PHONE, HIRE_DT,
           NVL(EMAILID,' ') EMAILID, EMPL_CLASS, EMPL_STATUS, SUPERVISOR_ID,
           SUBSTR(JOBTITLE,1,30) JOBTITLE,
           SUBSTR(ORG_LEVEL_3_DESC,1,30) DEPARTMENT,
           TRIM(ORG_LEVEL_1_CODE)ORG_LEVEL_1_CODE , TRIM(ORG_LEVEL_2_CODE) ORG_LEVEL_2_CODE,  -- ADDED ON 6/14/10 TRIMMED ON 10/21/15
           TRIM(ORG_LEVEL_3_CODE)ORG_LEVEL_3_CODE,  TRIM(ORG_LEVEL_4_CODE) ORG_LEVEL_4_CODE   -- ADDED ON 6/14/10 TRIMMED ON 10/21/15
    --FROM DW.PS_EMPLOYEES_PUBLIC@dwprd
    FROM EDW_SHARE.PS_EMPLOYEES_PUBLIC a
    where not exists (select 1 from EDW_SHARE.PS_EMPLOYEES_PUBLIC b where a.emplid = b.supervisor_id and b.emplid = a.supervisor_id and b.emplid != b.supervisor_id)
   ORDER BY EMPLID;

    CURSOR PARENTEMP_CUR IS
    SELECT EMPLID, SUPERVISOR_ID, LEVEL
    FROM EDW_SHARE.PS_EMPLOYEES_PUBLIC
    CONNECT BY NOCYCLE  PRIOR SUPERVISOR_ID=EMPLID
    START WITH EMPLID= EMPLID_T
    ORDER BY LEVEL;

   DISPLAYNAME_T  PERSON.DISPLAYNAME%TYPE;
   PHONENUM_T     PHONE.PHONENUM%TYPE;
   EMAILADDRESS_T EMAIL.EMAILADDRESS%TYPE;
   LABORCODE_T    LABOR.LABORCODE%TYPE;
   LABORCODE_T2   LABORCRAFTRATE.LABORCODE%TYPE;
   STATUS_T       PERSONSTATUS.STATUS%TYPE;
   CRAFT_T        LABORCRAFTRATE.CRAFT%TYPE;
   DESCRIPTION_T  CRAFT.DESCRIPTION%TYPE;



   CRAFT_EXISTS_T NUMBER(5) := 0;
  --****************************************
  -- PROCEDURE TO INSERT CRAFT DETAILS INTO
  -- CRAFT RELATED TABLES
  --****************************************
  PROCEDURE INSERT_CRAFT_INFO(
            ORGID_I     IN CRAFT.ORGID%TYPE,
            CRAFT_CUR_I IN CRAFT_REF_CURSOR)
  IS
            CRAFT_REC_T CRAFT_REC;
            CRAFT_T     CRAFT.CRAFT%TYPE;
            RANK_T      CRAFTSKILL.RANK%TYPE;
            LBL_ORG_LEVEL_T  VARCHAR2(2000); -- ADDED 6/14/10
  BEGIN

    LOOP

      FETCH CRAFT_CUR_I INTO CRAFT_REC_T;

      EXIT WHEN CRAFT_CUR_I%NOTFOUND;

      BEGIN

         SELECT CRAFT.DESCRIPTION,
         NVL(LBL_ORG_LEVEL_1,' ') || NVL(LBL_ORG_LEVEL_2, ' ') || NVL(LBL_ORG_LEVEL_3, ' ') ||
         NVL(LBL_ORG_LEVEL_4, ' ')
         INTO  DESCRIPTION_T, LBL_ORG_LEVEL_T
         FROM   MAXIMO.CRAFT
         WHERE  CRAFT.ORGID=ORGID_I
         AND    CRAFT.CRAFT=CRAFT_REC_T.CRAFT_I;

         IF (CRAFT_REC_T.DESCRIPTION_I != DESCRIPTION_T) OR
         (NVL(CRAFT_REC_T.LBL_ORG_LEVEL_1_I,' ') || NVL(CRAFT_REC_T.LBL_ORG_LEVEL_2_I, ' ') || NVL(CRAFT_REC_T.LBL_ORG_LEVEL_3_I, ' ') ||
         NVL(CRAFT_REC_T.LBL_ORG_LEVEL_4_I, ' ') != LBL_ORG_LEVEL_T)   THEN

          UPDATE MAXIMO.CRAFT
          SET    CRAFT.DESCRIPTION=CRAFT_REC_T.DESCRIPTION_I,
                 LBL_ORG_LEVEL_1=CRAFT_REC_T.LBL_ORG_LEVEL_1_I,
                 LBL_ORG_LEVEL_2=CRAFT_REC_T.LBL_ORG_LEVEL_2_I,
                 LBL_ORG_LEVEL_3=CRAFT_REC_T.LBL_ORG_LEVEL_3_I,
                 LBL_ORG_LEVEL_4=CRAFT_REC_T.LBL_ORG_LEVEL_4_I
          WHERE  CRAFT.ORGID=ORGID_I
          AND    CRAFT.CRAFT=CRAFT_REC_T.CRAFT_I;

        END IF;

       EXCEPTION WHEN NO_DATA_FOUND THEN

         INSERT INTO CRAFT (CRAFT,
         DESCRIPTION, ORGID, CRAFTID,
         HASLD, LANGCODE,
         LBL_ORG_LEVEL_1,   -- ADDED 6/14/10
         LBL_ORG_LEVEL_2,
         LBL_ORG_LEVEL_3,
         LBL_ORG_LEVEL_4, ISCREW)
         VALUES (CRAFT_REC_T.CRAFT_I,
         CRAFT_REC_T.DESCRIPTION_I, ORGID_I,CRAFTSEQ.NEXTVAL,
         '0','EN',
         CRAFT_REC_T.LBL_ORG_LEVEL_1_I,
         CRAFT_REC_T.LBL_ORG_LEVEL_2_I,
         CRAFT_REC_T.LBL_ORG_LEVEL_3_I,
         CRAFT_REC_T.LBL_ORG_LEVEL_4_I, '0'
         );
      END;

       --- GET RANK
       SELECT CRAFTSKILL.RANK
       INTO RANK_T
       FROM MAXIMO.CRAFTSKILL
       WHERE ROWNUM=1;

       BEGIN

         SELECT CRAFT INTO CRAFT_T
         FROM MAXIMO.CRAFTSKILL
         WHERE CRAFTSKILL.ORGID=ORGID_I
         AND   CRAFTSKILL.CRAFT=CRAFT_REC_T.CRAFT_I
         AND   ROWNUM=1;

        EXCEPTION WHEN NO_DATA_FOUND THEN
          INSERT INTO CRAFTSKILL(CRAFT,
          DESCRIPTION, ORGID, CRAFTSKILLID,
          HASLD, LANGCODE, RANK)
          VALUES (CRAFT_REC_T.CRAFT_I,
          CRAFT_REC_T.DESCRIPTION_I, ORGID_I,CRAFTSKILLSEQ.NEXTVAL,
          '0','EN',RANK_T);

       END;

        BEGIN

         SELECT CRAFT  INTO CRAFT_T
         FROM MAXIMO.CRAFTRATE
         WHERE CRAFTRATE.ORGID=ORGID_I
         AND   CRAFTRATE.CRAFT=CRAFT_REC_T.CRAFT_I
         AND   ROWNUM=1;

        EXCEPTION WHEN NO_DATA_FOUND THEN
          INSERT INTO CRAFTRATE(CRAFT,
          STANDARDRATE, ORGID, CRAFTRATEID)
          VALUES (CRAFT_REC_T.CRAFT_I,
          0, ORGID_I,CRAFTRATESEQ.NEXTVAL);
       END;

        BEGIN

         SELECT CRAFT  INTO CRAFT_T
         FROM MAXIMO.PPCRAFTRATE
         WHERE PPCRAFTRATE.ORGID=ORGID_I
         AND   PPCRAFTRATE.CRAFT=CRAFT_REC_T.CRAFT_I
         AND   ROWNUM=1;

        EXCEPTION WHEN NO_DATA_FOUND THEN

          INSERT INTO PPCRAFTRATE(CRAFT,
          INHERIT, ORGID, PPCRAFTRATEID,
          PREMIUMPAYCODE, RATE, RATETYPE)
          VALUES (CRAFT_REC_T.CRAFT_I,
          '0', ORGID_I, PPCRAFTRATESEQ.NEXTVAL,
          1.0, 1, 'MULTIPLIER');
       END;

    END LOOP;

  END; -- END OF PROCEDURE

/*********************************************************************
 MAIN PROGRAM STARTS FROM HERE
*********************************************************************/
BEGIN

    DBMS_OUTPUT.ENABLE(100000000);

  --   GET THE VALUE OF ORG ID FROM THE ARUGEMENT
     ORGID_T   :=UPPER('&1');
    --ORGID_T := 'LBNL';

    IF (ORGID_T IS NULL OR LENGTH(ORGID_T)=0) THEN
       ORGID_T :='LBNL';
    END IF;

--     GET THE VALUE OF SITEID ID FROM THE ARUGEMENT
     SITEID_T   :=UPPER('&2');
    --SITEID_T := 'FAC';

    IF (SITEID_T IS NULL OR LENGTH(SITEID_T)=0) THEN
       SITEID_T :='FAC';
    END IF;

     -- LEVEL-1 --
    OPEN CRAFT_CUR FOR SELECT SUBSTR(TRIM(A.DEPTID),1,8) CRAFT_I,  -- TRIMMED 10/21/15
                       A.DESCR  DESCRIPTION_I,
                       TRIM(A.DEPTID) LBL_ORG_LEVEL_1_I,
                       NULL, NULL, NULL
                       FROM EDW_SHARE.ORG_DEPARTMENT A;

    INSERT_CRAFT_INFO(ORGID_T, CRAFT_CUR);
    CLOSE CRAFT_CUR;

    -- LEVEL-2 --
    OPEN CRAFT_CUR FOR SELECT SUBSTR(TRIM(A.DEPTID)|| TRIM(A.ZZ_GROUP),1,8) CRAFT_I, -- TRIMMED 10/21/15
                   A.DESCR DESCRIPTION_I,
                   TRIM(A.DEPTID)   LBL_ORG_LEVEL_1_I,
                   TRIM(A.ZZ_GROUP) LBL_ORG_LEVEL_2_I,
                   NULL, NULL
                   FROM EDW_SHARE.ORG_GROUP A;

    INSERT_CRAFT_INFO(ORGID_T, CRAFT_CUR);
    CLOSE CRAFT_CUR;

    -- LEVEL-3 --
    OPEN CRAFT_CUR FOR SELECT SUBSTR(TRIM(A.DEPTID)|| TRIM(A.ZZ_GROUP) || TRIM(A.ZZ_UNIT),1,8)  -- TRIMMED 10/21/15
                   CRAFT_I,  A.DESCR DESCRIPTION_I,
                   TRIM(A.DEPTID)    LBL_ORG_LEVEL_1_I,
                   TRIM(A.ZZ_GROUP)  LBL_ORG_LEVEL_2_I,
                   TRIM(A.ZZ_UNIT)   LBL_ORG_LEVEL_3_I,
                   NULL
                   FROM EDW_SHARE.ORG_UNIT A;

    INSERT_CRAFT_INFO(ORGID_T, CRAFT_CUR);
    CLOSE CRAFT_CUR;

    -- LEVEL-4 --
    OPEN CRAFT_CUR FOR
    SELECT SUBSTR(TRIM(A.DEPTID)|| TRIM(A.ZZ_GROUP) ||TRIM(A.ZZ_UNIT)||
           TRIM(A.ZZ_LEVEL4),1,8) CRAFT_I,  -- TRIMMED 10/21/15
           A.DESCR DESCRIPTION_I,
           TRIM(A.DEPTID)    LBL_ORG_LEVEL_1_I,
           TRIM(A.ZZ_GROUP)  LBL_ORG_LEVEL_2_I,
           TRIM(A.ZZ_UNIT)   LBL_ORG_LEVEL_3_I,
           TRIM(A.ZZ_LEVEL4) LBL_ORG_LEVEL_4_I
    FROM EDW_SHARE.ORG_LEVEL4 A;

    INSERT_CRAFT_INFO(ORGID_T, CRAFT_CUR);
    CLOSE CRAFT_CUR;

    EXECUTE IMMEDIATE 'ALTER TRIGGER PERSON_T DISABLE ';

    -- FIND OUT TOP LEVEL EMPLOYEE (E.G. LBNL DIRECTOR)
    /* Don't need any more
    SELECT EMPLID
    INTO   T_TOP_EMPLOYEE
    FROM   DW.PS_EMPLOYEES_PUBLIC
    WHERE  SUPERVISOR_ID =EMPLID
    AND    EMPL_STATUS='A';
    */

    --**************************
    -- BULK UPDATE WITHOUT LOOP
    --**************************
    UPDATE (SELECT TGT.DISPLAYNAME AS T_DISPLAYNAME, TGT.FIRSTNAME AS T_FIRSTNAME,TGT.LASTNAME AS T_LASTNAME,
        TGT.DROPPOINT AS T_DROPPOINT, TGT.HIREDATE AS T_HIREDATE, TGT.TITLE AS T_TITLE, TGT.DEPARTMENT AS T_DEPARTMENT,
        TGT.LOCATION AS T_LOCATION,
        TGT.SUPERVISOR AS T_SUPERVISOR, TGT.STATUSDATE AS T_STATUSDATE,
        TGT.ADDRESSLINE1 AS T_ADDRESSLINE1,
        TGT.LBL_ORG_LEVEL_1 AS T_LBL_ORG_LEVEL_1,
        TGT.LBL_ORG_LEVEL_2 AS T_LBL_ORG_LEVEL_2,
        TGT.LBL_ORG_LEVEL_3 AS T_LBL_ORG_LEVEL_3,
        TGT.LBL_ORG_LEVEL_4 AS T_LBL_ORG_LEVEL_4,
        TGT.LBL_STATUS AS T_LBL_STATUS,
        TGT.STATUS     AS T_STATUS,


        SRC.NAME AS S_NAME, SRC.FIRST_NAME AS  S_FIRST_NAME, SRC.LAST_NAME AS S_LAST_NAME,
        SRC.MAIL_DROP AS S_DROPPOINT,SRC.HIRE_DT AS S_HIREDATE, SRC.JOBTITLE AS S_TITLE,  SUBSTR(SRC.ORG_LEVEL_3_DESC,1,30) AS S_DEPARTMENT,
        LTRIM(RTRIM(SRC.ZZ_BLDG || DECODE(NVL(SRC.ZZ_ROOM,'*NULL*'),'*NULL*','','-'|| SRC.ZZ_ROOM))) AS S_LOCATION,
        DECODE(SRC.SUPERVISOR_ID,SRC.EMPLID,NULL,SRC.SUPERVISOR_ID) AS S_SUPERVISOR, SYSDATE AS S_STATUSDATE,
        'LBNL MS: ' || SRC.MAIL_DROP AS S_ADDRESSLINE1,
        TRIM(SRC.ORG_LEVEL_1_CODE) S_ORG_LEVEL_1_CODE,
        TRIM(SRC.ORG_LEVEL_2_CODE) S_ORG_LEVEL_2_CODE,
        TRIM(SRC.ORG_LEVEL_3_CODE) S_ORG_LEVEL_3_CODE,
        TRIM(SRC.ORG_LEVEL_4_CODE) S_ORG_LEVEL_4_CODE,
        DECODE(SRC.EMPL_STATUS,'T','I','A') S_LBL_STATUS,
        DECODE(SRC.EMPL_STATUS,'T','INACTIVE','ACTIVE') S_STATUS  -- ADDED 6/28/18 

        FROM EDW_SHARE.PS_EMPLOYEES_PUBLIC SRC, PERSON TGT
        WHERE SRC.EMPLID=TGT.PERSONID
        )
	SET T_DISPLAYNAME=S_NAME,
	T_FIRSTNAME=S_FIRST_NAME,
	T_LASTNAME=S_LAST_NAME,
	T_DROPPOINT=S_DROPPOINT,
	T_HIREDATE=S_HIREDATE,
	T_TITLE=S_TITLE,
	T_DEPARTMENT=S_DEPARTMENT,
	T_LOCATION=S_LOCATION,
	T_SUPERVISOR=S_SUPERVISOR,
	T_STATUSDATE=S_STATUSDATE,
	T_ADDRESSLINE1=S_ADDRESSLINE1,
	T_LBL_ORG_LEVEL_1=S_ORG_LEVEL_1_CODE,
	T_LBL_ORG_LEVEL_2=S_ORG_LEVEL_2_CODE,
	T_LBL_ORG_LEVEL_3=S_ORG_LEVEL_3_CODE,
	T_LBL_ORG_LEVEL_4=S_ORG_LEVEL_4_CODE,
	T_LBL_STATUS=S_LBL_STATUS,
    T_STATUS=S_STATUS;   -- ADDED 6/28/18 


        INSERT INTO MAXIMO.PERSON(
         PERSON.ACCEPTINGWFMAIL,PERSON.ADDRESSLINE1,PERSON.CITY, PERSON.COUNTRY,
         PERSON.DEPARTMENT, PERSON.DISPLAYNAME, PERSON.DROPPOINT,
         PERSON.FIRSTNAME, PERSON.HASLD, PERSON.HIREDATE,
         PERSON.LANGCODE, PERSON.LANGUAGE,
         PERSON.LASTNAME,
         PERSON.LOCATION,
         PERSON.LOCATIONORG, PERSON.LOCATIONSITE,
         PERSON.PERSONID,
         PERSON.PERSONUID, PERSON.POSTALCODE,
         PERSON.SHIPTOADDRESS,
         PERSON.STATUS, PERSON.TITLE,
         BILLTOADDRESS, LOCTOSERVREQ,  STATEPROVINCE,
         SUPERVISOR,
         TRANSEMAILELECTION,WFMAILELECTION,
         STATUSDATE,
         ROWSTAMP,  -- ADDED BY PANKAJ FOR ROWSTAMP TRIGGER
         LBL_ORG_LEVEL_1,  -- ADDED ON 6/14/10
         LBL_ORG_LEVEL_2,
         LBL_ORG_LEVEL_3,
         LBL_ORG_LEVEL_4,
         LBL_STATUS,
         DEVICECLASS)
         SELECT
         '1','LBNL MS: ' || EMPLOYEE_REC.MAIL_DROP,'BERKELEY','USA',
         SUBSTR(EMPLOYEE_REC.ORG_LEVEL_3_DESC,1,30) DEPARTMENT, EMPLOYEE_REC.NAME, EMPLOYEE_REC.MAIL_DROP,
         EMPLOYEE_REC.FIRST_NAME, '0', EMPLOYEE_REC.HIRE_DT,
         'EN','EN',
         EMPLOYEE_REC.LAST_NAME,
         LTRIM(RTRIM(EMPLOYEE_REC.ZZ_BLDG ||  DECODE(NVL(EMPLOYEE_REC.ZZ_ROOM,'*NULL*'),'*NULL*','','-'||
         EMPLOYEE_REC.ZZ_ROOM))), -- LOCATION
         'LBNL', 'FAC',
         EMPLOYEE_REC.EMPLID,
         PERSONSEQ.NEXTVAL,'94720',
         '069',
         'ACTIVE',EMPLOYEE_REC.JOBTITLE,
         '069',1,'CA',
         CASE
            WHEN EMPLOYEE_REC.SUPERVISOR_ID=EMPLOYEE_REC.EMPLID THEN NULL
            ELSE EMPLOYEE_REC.SUPERVISOR_ID
           END AS SUPERVSOR_ID,
         'NEVER','PROCESS',
         SYSDATE,
         MAXSEQ.NEXTVAL, -- ADDED BY PANKAJ FOR ROWSTAMP
         EMPLOYEE_REC.ORG_LEVEL_1_CODE, -- ADDED ON 6/14/10
         EMPLOYEE_REC.ORG_LEVEL_2_CODE, --
         EMPLOYEE_REC.ORG_LEVEL_3_CODE, --
         EMPLOYEE_REC.ORG_LEVEL_4_CODE,
         DECODE(EMPLOYEE_REC.EMPL_STATUS,'T','I','A'),
         '2'
          FROM EDW_SHARE.PS_EMPLOYEES_PUBLIC  EMPLOYEE_REC
         WHERE NOT EXISTS (SELECT 1 FROM PERSON B
                            WHERE B.PERSONID=EMPLOYEE_REC.EMPLID);


        EXECUTE IMMEDIATE 'ALTER TRIGGER PERSON_T ENABLE ';




    -- START REFRESHING EMPLOYEE DETAILS
    FOR EMPLOYEE_REC IN EMPLOYEE_CUR

     LOOP

       ROW_ID_T := ROW_ID_T + 1;

       /* BLOCK COMMENTED ON JUN 21, 2018 AVOD LOOP FOR EMPLOYEE
          UPDATE/INSERT

       IF (EMPLOYEE_REC.EMPLID=EMPLOYEE_REC.SUPERVISOR_ID) THEN
          SUPERVISOR_T :=NULL;
       ELSE
          SUPERVISOR_T :=EMPLOYEE_REC.SUPERVISOR_ID;
       END IF;



         BEGIN
         SELECT PERSON.DISPLAYNAME INTO DISPLAYNAME_T
         FROM   MAXIMO.PERSON
         WHERE  PERSON.PERSONID=EMPLOYEE_REC.EMPLID;

         UPDATE MAXIMO.PERSON
         SET    DISPLAYNAME=EMPLOYEE_REC.NAME, FIRSTNAME=EMPLOYEE_REC.FIRST_NAME,
                LASTNAME=EMPLOYEE_REC.LAST_NAME, DROPPOINT=EMPLOYEE_REC.MAIL_DROP,
                HIREDATE=EMPLOYEE_REC.HIRE_DT, TITLE=EMPLOYEE_REC.JOBTITLE,
                DEPARTMENT=EMPLOYEE_REC.DEPARTMENT,
                LOCATION=LTRIM(RTRIM(EMPLOYEE_REC.ZZ_BLDG ||
                DECODE(NVL(EMPLOYEE_REC.ZZ_ROOM,'*NULL*'),'*NULL*','','-'||
                EMPLOYEE_REC.ZZ_ROOM))),
                SUPERVISOR=SUPERVISOR_T,
                STATUSDATE=SYSDATE,
                ADDRESSLINE1='LBNL MS: ' || EMPLOYEE_REC.MAIL_DROP,
                CITY='BERKELEY',
                COUNTRY='USA',
                POSTALCODE='94720',
                STATEPROVINCE='CA',
                SHIPTOADDRESS='069',
                LBL_ORG_LEVEL_1=EMPLOYEE_REC.ORG_LEVEL_1_CODE, -- ADDED ON 6/14/10
                LBL_ORG_LEVEL_2=EMPLOYEE_REC.ORG_LEVEL_2_CODE,
                LBL_ORG_LEVEL_3=EMPLOYEE_REC.ORG_LEVEL_3_CODE,
                LBL_ORG_LEVEL_4=EMPLOYEE_REC.ORG_LEVEL_4_CODE,
                LBL_STATUS=DECODE(EMPLOYEE_REC.EMPL_STATUS,'T','I','A')
                --LOCATIONORG=ORGID_T,
                --LOCATIONSITE=SITEID_T
         WHERE PERSONID=EMPLOYEE_REC.EMPLID;


       EXCEPTION WHEN NO_DATA_FOUND THEN

         INSERT INTO MAXIMO.PERSON(
         PERSON.ACCEPTINGWFMAIL,PERSON.ADDRESSLINE1,PERSON.CITY, PERSON.COUNTRY,
         PERSON.DEPARTMENT, PERSON.DISPLAYNAME, PERSON.DROPPOINT,
         PERSON.FIRSTNAME, PERSON.HASLD, PERSON.HIREDATE,
         PERSON.LANGCODE, PERSON.LANGUAGE,
         PERSON.LASTNAME,
         PERSON.LOCATION,
         PERSON.LOCATIONORG, PERSON.LOCATIONSITE,
         PERSON.PERSONID,
         PERSON.PERSONUID, PERSON.POSTALCODE,
         PERSON.SHIPTOADDRESS,
         PERSON.STATUS, PERSON.TITLE,
         BILLTOADDRESS, LOCTOSERVREQ,  STATEPROVINCE,
         SUPERVISOR,
         TRANSEMAILELECTION,WFMAILELECTION,
         STATUSDATE,
         ROWSTAMP,  -- ADDED BY PANKAJ FOR ROWSTAMP TRIGGER
         LBL_ORG_LEVEL_1,  -- ADDED ON 6/14/10
         LBL_ORG_LEVEL_2,
         LBL_ORG_LEVEL_3,
         LBL_ORG_LEVEL_4,
         LBL_STATUS,
         DEVICECLASS)
         VALUES(
         '1','LBNL MS: ' || EMPLOYEE_REC.MAIL_DROP,'BERKELEY','USA',
         EMPLOYEE_REC.DEPARTMENT, EMPLOYEE_REC.NAME, EMPLOYEE_REC.MAIL_DROP,
         EMPLOYEE_REC.FIRST_NAME, '0', EMPLOYEE_REC.HIRE_DT,
         'EN','EN',
         EMPLOYEE_REC.LAST_NAME,
         LTRIM(RTRIM(EMPLOYEE_REC.ZZ_BLDG ||  DECODE(NVL(EMPLOYEE_REC.ZZ_ROOM,'*NULL*'),'*NULL*','','-'||
         EMPLOYEE_REC.ZZ_ROOM))), -- LOCATION
         ORGID_T, SITEID_T,
         EMPLOYEE_REC.EMPLID,
         PERSONSEQ.NEXTVAL,'94720',
         '069',
         'ACTIVE',EMPLOYEE_REC.JOBTITLE,
         '069',1,'CA',
         SUPERVISOR_T,
         'NEVER','PROCESS',
         SYSDATE,
         MAXSEQ.NEXTVAL, -- ADDED BY PANKAJ FOR ROWSTAMP
         EMPLOYEE_REC.ORG_LEVEL_1_CODE, -- ADDED ON 6/14/10
         EMPLOYEE_REC.ORG_LEVEL_2_CODE, --
         EMPLOYEE_REC.ORG_LEVEL_3_CODE, --
         EMPLOYEE_REC.ORG_LEVEL_4_CODE,
         DECODE(EMPLOYEE_REC.EMPL_STATUS,'T','I','A'),
                '2'
          );

      END;

      BLOCK COMMENT FOR AOVIDING LOOP ENDS HERE */



      -- REFRESH WORK PHONE DATA
      BEGIN
        SELECT PHONENUM INTO PHONENUM_T
        FROM   MAXIMO.PHONE
        WHERE  PERSONID=EMPLOYEE_REC.EMPLID
        AND    TYPE='WORK'
        AND    ISPRIMARY='1';

       IF (PHONENUM_T != EMPLOYEE_REC.WORK_PHONE) THEN

        UPDATE MAXIMO.PHONE
        SET PHONENUM=EMPLOYEE_REC.WORK_PHONE
        WHERE  PERSONID=EMPLOYEE_REC.EMPLID
        AND    TYPE='WORK'
        AND    ISPRIMARY='1';

      END IF;

        -- SET OTHER PHONES AS NON PRIMARY IF EXIST
        -- PANKAJ 09/09/23

        UPDATE MAXIMO.PHONE
        SET ISPRIMARY='0'
        WHERE  PERSONID=EMPLOYEE_REC.EMPLID
        AND    TYPE='WORK'
        AND    PHONENUM !=EMPLOYEE_REC.WORK_PHONE;



      EXCEPTION WHEN NO_DATA_FOUND THEN
       INSERT INTO MAXIMO.PHONE(
       PHONE.ISPRIMARY,PHONE.PERSONID,
       PHONE.PHONEID, PHONE.PHONENUM,
       PHONE.TYPE) VALUES
       ('1',EMPLOYEE_REC.EMPLID,
        PHONESEQ.NEXTVAL,EMPLOYEE_REC.WORK_PHONE,
        'WORK');

      END;

         -- REFRESH WORK EMAIL DATA
      if (EMPLOYEE_REC.EMAILID != ' ') then
          BEGIN
              SELECT EMAILADDRESS INTO EMAILADDRESS_T
              FROM   MAXIMO.EMAIL
              WHERE  PERSONID=EMPLOYEE_REC.EMPLID
              AND    TYPE='WORK'
              AND    ISPRIMARY='1';

              IF (EMAILADDRESS_T != EMPLOYEE_REC.EMAILID) THEN
                UPDATE MAXIMO.EMAIL
                SET EMAILADDRESS=EMPLOYEE_REC.EMAILID
                WHERE  PERSONID=EMPLOYEE_REC.EMPLID
                AND    TYPE='WORK'
                AND    ISPRIMARY='1';
            END IF;

        -- MAKE OTHERS NON-PRIMARY
        -- PANKAJ 09/09/23

            UPDATE MAXIMO.EMAIL
            SET    ISPRIMARY='0'
            WHERE  PERSONID=EMPLOYEE_REC.EMPLID
            AND    TYPE='WORK'
            AND    EMAILADDRESS !=EMPLOYEE_REC.EMAILID ;


            EXCEPTION WHEN NO_DATA_FOUND THEN
            INSERT INTO MAXIMO.EMAIL(
            EMAIL.ISPRIMARY,EMAIL.EMAILID,
            EMAIL.EMAILADDRESS, EMAIL.PERSONID,
            EMAIL.TYPE) VALUES
            ('1',EMAILSEQ.NEXTVAL,
            EMPLOYEE_REC.EMAILID, EMPLOYEE_REC.EMPLID,
            'WORK');

        END;
      end if;

     -- PERSONSTATUS TABLE
     BEGIN
       SELECT STATUS INTO STATUS_T
       FROM   MAXIMO.PERSONSTATUS
       WHERE  PERSONID=EMPLOYEE_REC.EMPLID
       AND    ROWNUM=1;
     EXCEPTION WHEN NO_DATA_FOUND THEN
       INSERT INTO PERSONSTATUS
       (PERSONSTATUS.CHANGEBY, PERSONSTATUS.CHANGEDATE,
        PERSONSTATUS.PERSONID, PERSONSTATUS.PERSONSTATUSID,
        STATUS) VALUES
        ('MAXIMO',SYSDATE,
         EMPLOYEE_REC.EMPLID, PERSONSTATUSSEQ.NEXTVAL,
         'ACTIVE');
     END;

     -- REFRESH LABOR RELATED TABLES
     BEGIN

       SELECT LABORCODE, STATUS INTO LABORCODE_T, STATUS_T
       FROM   MAXIMO.LABOR
       WHERE  LABOR.ORGID=ORGID_T
       AND    LABOR.LABORCODE=EMPLOYEE_REC.EMPLID;

     IF (STATUS_T !='INACTIVE') THEN 
       UPDATE MAXIMO.LABOR
       SET    LA1=EMPLOYEE_REC.TERMINATION_DT, LA2=SYSDATE,
              LA3=EMPLOYEE_REC.EMPL_STATUS,
              WORKLOCATION=LTRIM(RTRIM(EMPLOYEE_REC.ZZ_BLDG ||
              DECODE(NVL(EMPLOYEE_REC.ZZ_ROOM,'*NULL*'),'*NULL*','','-'||
              EMPLOYEE_REC.ZZ_ROOM))), -- LOCATION
              STATUS=DECODE(EMPLOYEE_REC.EMPL_STATUS,'T','INACTIVE','ACTIVE') -- ADDED 6/28/18
              
       WHERE  LABOR.ORGID=ORGID_T
       AND    LABOR.LABORCODE=EMPLOYEE_REC.EMPLID;
     END IF;

     EXCEPTION WHEN NO_DATA_FOUND THEN
       INSERT INTO MAXIMO.LABOR
       (LABOR.LABORCODE, LABOR.PERSONID,
        LABOR.REPORTEDHRS, LABOR.YTDOTHRS, LABOR.YTDHRSREFUSED,
        LABOR.AVAILFACTOR, ORGID,
        LABOR.WORKSITE,
        LA1, LA2, LA3,
        WORKLOCATION,
        ADDRESS4, LABOR.LABORID, STATUS, LBSDATAFROMWO)
       VALUES(EMPLOYEE_REC.EMPLID, EMPLOYEE_REC.EMPLID,
              0,0,0,
              1, ORGID_T,
              SITEID_T,
              EMPLOYEE_REC.TERMINATION_DT, SYSDATE,EMPLOYEE_REC.EMPL_STATUS,
              LTRIM(RTRIM(EMPLOYEE_REC.ZZ_BLDG ||
              DECODE(NVL(EMPLOYEE_REC.ZZ_ROOM,'*NULL*'),'*NULL*','','-'||
              EMPLOYEE_REC.ZZ_ROOM))), -- LOCATION
              '94720', LABORSEQ.NEXTVAL,
              'ACTIVE', '0');
      END;

     -- LABORSTATUS TABLE
     BEGIN
       SELECT STATUS INTO STATUS_T
       FROM   MAXIMO.LABORSTATUS
       WHERE  LABORCODE=EMPLOYEE_REC.EMPLID
       --ORGID=ORGID_T
       AND    ROWNUM=1;

     EXCEPTION WHEN NO_DATA_FOUND THEN

       INSERT INTO LABORSTATUS
       (LABORSTATUS.CHANGEBY, LABORSTATUS.CHANGEDATE,
        LABORSTATUS.LABORCODE, LABORSTATUS.LABORSTATUSID,
        LABORSTATUS.ORGID,
        STATUS) VALUES
        ('MAXIMO',SYSDATE,
         EMPLOYEE_REC.EMPLID, LABORSTATUSSEQ.NEXTVAL,
         ORGID_T,
         'ACTIVE');
     END;

    --##########################################################=
    --# DON'T INSERT/UPDATE CRAFT IF THE LABOR IS NO LONGER ACTIVE
    --# ADDED BY PANKAJ ON 4/10/17 FOR AKWIRE
    --############################################################

    IF (EMPLOYEE_REC.EMPL_STATUS='A') THEN

                    --*******************************
                    -- LABORCRAFTRATE TABLE
                    -- CHANGED BY PANKAJ ON 2/13/10
                    --***************************

                  IF ( EMPLOYEE_REC.ORG_CODE IS NOT NULL AND
                       LENGTH(LTRIM(EMPLOYEE_REC.ORG_CODE)) > 0) THEN


                     -- CHECK IF THE EMPLOYEE BELONGS TO THE PERSON GROUP
                     -- THAT CONTAINS THE EMPLOYEES WITH A PREDETERMINED
                     -- DEFAULT CRAFTS (FOR FACILIITES)

                     CNT_FIXEDCRAFT_T :=0;

                     SELECT COUNT(*)
                     INTO  CNT_FIXEDCRAFT_T
                     FROM  MAXIMO.PERSONGROUPTEAM
                     WHERE PERSONGROUP='FACFIXEDCRAFT'
                     AND   RESPPARTY=EMPLOYEE_REC.EMPLID;




                      CRAFT_EXISTS_T  := 0;

                      SELECT COUNT(*) INTO CRAFT_EXISTS_T
                      FROM   LABORCRAFTRATE
                      WHERE  LABORCODE=EMPLOYEE_REC.EMPLID
                      AND    CRAFT=EMPLOYEE_REC.ORG_CODE;


                      IF (CRAFT_EXISTS_T =0) THEN



                        IF (CNT_FIXEDCRAFT_T =0) THEN
                          -- MARK EXISTING CRAFTS AS NON-DEFAULT
                          UPDATE LABORCRAFTRATE
                          SET    DEFAULTCRAFT=0
                          WHERE  LABORCODE=EMPLOYEE_REC.EMPLID;


                         -- INSERT THE NEWER CRAFT AS DEFAULT
                         INSERT INTO MAXIMO.LABORCRAFTRATE
                         (CRAFT, DEFAULTCRAFT, INHERIT, LABORCODE,
                         ORGID, RATE, LABORCRAFTRATE.LABORCRAFTRATEID)
                         VALUES
                         (EMPLOYEE_REC.ORG_CODE, '1','0',EMPLOYEE_REC.EMPLID,
                          ORGID_T, 0, LABORCRAFTRATESEQ.NEXTVAL); --DEFAULT

                        ELSE

                         -- INSERT THE NEWER CRAFT AS NON-DEFAULT
                          INSERT INTO MAXIMO.LABORCRAFTRATE
                          (CRAFT, DEFAULTCRAFT, INHERIT, LABORCODE,
                           ORGID, RATE, LABORCRAFTRATE.LABORCRAFTRATEID)
                         VALUES
                          (EMPLOYEE_REC.ORG_CODE, '0','0',EMPLOYEE_REC.EMPLID,
                           ORGID_T, 0, LABORCRAFTRATESEQ.NEXTVAL); --DEFAULT

                        END IF;

                       END IF;

       END IF;    --IF ( EMPLOYEE_REC.ORG_CODE IS NOT NULL AND
                  -- LENGTH(LTRIM(EMPLOYEE_REC.ORG_CODE)) > 0) THEN
    END IF;   -- IF (EMPLOYEE_REC.EMPL_STATUS='A')


    --***************************************
    -- REFRESH ROWS OF PERSONANCESTOR TABLE
    --***************************************

    /* BLOCK COMMENT TO MOVE THE FOLLOWING TO ANOTHER PROGRAM

    IF (ROW_ID_T=1) THEN
      -- RESET THE SEQUENCE FOR PERSONACENSTOR
      RESULT_T := LBL_MAXIMO_PKG.RESET_SEQUENCE('PERSONANCESTORSEQ');

      -- CLEAN UP THE DATA FOR THE EMPLOYEE
      EXECUTE IMMEDIATE ' TRUNCATE TABLE PERSONANCESTOR ';
    END IF;



    EMPLID_T  := EMPLOYEE_REC.EMPLID;
    LEVEL_T   :=0;

     -- SELF ANCESTOR
     INSERT INTO PERSONANCESTOR
     (ANCESTOR, PERSONID, HIERARCHYLEVELS, PERSONANCESTORID)
      VALUES
     (EMPLID_T, EMPLID_T , LEVEL_T , PERSONANCESTORSEQ.NEXTVAL);



    if (EMPLOYEE_REC.emplid != EMPLOYEE_REC.SUPERVISOR_ID) and (EMPLOYEE_REC.SUPERVISOR_ID is not null)  then
    -- FIND OUT PARENT/S AND INSERT THEM
        FOR  PARENTEMP_REC  IN PARENTEMP_CUR

          LOOP

            LEVEL_T := LEVEL_T + 1 ;

        INSERT INTO PERSONANCESTOR
       (ANCESTOR, PERSONID, HIERARCHYLEVELS, PERSONANCESTORID)
        VALUES
       (PARENTEMP_REC.SUPERVISOR_ID, EMPLID_T, LEVEL_T, PERSONANCESTORSEQ.NEXTVAL);


     END LOOP;

  end if;
   **** BLOCK COMMENT ENDS****************/

   END LOOP;  --FOR EMPLOYEE_REC IN EMPLOYEE_CUR


  COMMIT;

END;

/
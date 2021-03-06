CREATE OR REPLACE PACKAGE BODY LBL_MAXIMO_PKG IS

/*****************************************************************************
 PROGRAM NAME           : CRE_PKB_LBL_MAXIMO_PKG.SQL

 DATE WRITTEN           : 01-JUL-2008

 AUTHOR                 : PANKAJ BHIDE

 PURPOSE                : PACKAGE BODY FOR LBL_MAXIMO_PKG
*****************************************************************************/
/* FUNCTION TO GET THE DESCRIPTION FOR THE WORK ORDER NUMBER */
FUNCTION GET_DESCRIPTION(ORGID_I  IN MAXIMO.WORKORDER.ORGID%TYPE,
                         SITEID_I IN MAXIMO.WORKORDER.SITEID%TYPE,
                         WONUM_I    IN MAXIMO.WORKORDER.WONUM%TYPE)

          RETURN MAXIMO.WORKORDER.DESCRIPTION%TYPE
IS
    DESCRIPTION_O MAXIMO.WORKORDER.DESCRIPTION%TYPE :=NULL;

BEGIN
    SELECT DESCRIPTION INTO DESCRIPTION_O
    FROM MAXIMO.WORKORDER
    WHERE  ORGID=ORGID_I
    AND    SITEID=SITEID_I
    AND    WONUM=WONUM_I;

    RETURN DESCRIPTION_O;

    EXCEPTION
        WHEN OTHERS THEN
        DESCRIPTION_O := NULL;

    RETURN DESCRIPTION_O;
END;

/* FUNCTION TO GET THE TARGET START DATE FOR THE WORKORDER NUMBER */
FUNCTION GET_TARGSTARTDATE(ORGID_I  IN MAXIMO.WORKORDER.ORGID%TYPE,
                           SITEID_I IN MAXIMO.WORKORDER.SITEID%TYPE,
                           WONUM_I    IN MAXIMO.WORKORDER.WONUM%TYPE)
          RETURN MAXIMO.WORKORDER.TARGSTARTDATE%TYPE
IS
    TARGSTARTDATE_O MAXIMO.WORKORDER.TARGSTARTDATE%TYPE :=NULL;

BEGIN
    SELECT TARGSTARTDATE INTO TARGSTARTDATE_O
    FROM MAXIMO.WORKORDER
    WHERE  ORGID=ORGID_I
    AND    SITEID=SITEID_I
    AND    WONUM=WONUM_I;

    RETURN TARGSTARTDATE_O;

    EXCEPTION
        WHEN OTHERS THEN
        TARGSTARTDATE_O := NULL;

    RETURN TARGSTARTDATE_O;
END;

/* FUNCTION TO GET THE EMPLOYEE NAME FROM LABOR TABLE */
FUNCTION GET_EMPLOYEE_NAME(PERSONID_I IN MAXIMO.PERSON.PERSONID%TYPE)
                           RETURN MAXIMO.PERSON.DISPLAYNAME%TYPE

IS
 NAME_O  PERSON.DISPLAYNAME%TYPE :=NULL;

 BEGIN
   SELECT DISPLAYNAME INTO NAME_O
   FROM MAXIMO.PERSON
   WHERE PERSONID=RTRIM(PERSONID_I);

   RETURN NAME_O;

   EXCEPTION

          WHEN OTHERS THEN
           NAME_O := NULL;

    RETURN NAME_O;

END;

/* FUNCTION TO GET THE FIRST APPOROVAL DATE OF THE WORKORDER */
FUNCTION GET_FRST_APPR_DATE(ORGID_I  IN MAXIMO.WORKORDER.ORGID%TYPE,
                            SITEID_I IN MAXIMO.WORKORDER.SITEID%TYPE,
                            WONUM_I  IN MAXIMO.WORKORDER.WONUM%TYPE)
                            RETURN MAXIMO.WORKORDER.CHANGEDATE%TYPE
IS

    TMP_APP_DATE   MAXIMO.WOSTATUS.CHANGEDATE%TYPE := NULL;
    APPROVAL_DATE  MAXIMO.WOSTATUS.CHANGEDATE%TYPE;

   BEGIN

   SELECT MIN(CHANGEDATE) INTO TMP_APP_DATE FROM MAXIMO.WOSTATUS
   WHERE WOSTATUS.ORGID=ORGID_I
   AND   WOSTATUS.SITEID=SITEID_I
   AND   WOSTATUS.WONUM=WONUM_I
   AND   WOSTATUS.STATUS IN
   (SELECT VALUE FROM MAXIMO.SYNONYMDOMAIN
    WHERE DOMAINID='WOSTATUS'
    AND MAXVALUE IN ('APPR','INPRG','WMATL','ASSIGNED','INPRG','COMP','WCLOSE','COMP','CLOSE')
    AND VALUE IS NOT NULL);



    APPROVAL_DATE :=TMP_APP_DATE;

   RETURN APPROVAL_DATE;
  END;

/* FUNCTION TO GET GISPARAM1 REQUIRED FOR FINDING BUILDING*/
FUNCTION GET_GISPARAM1(ORGID_I  IN MAXIMO.LOCATIONS.ORGID%TYPE,
                       SITEID_I IN MAXIMO.LOCATIONS.SITEID%TYPE,
                       LOCATION_I    IN MAXIMO.LOCATIONS.LOCATION%TYPE)
                      RETURN MAXIMO.LOCATIONS.GISPARAM1%TYPE
IS
    GISPARAM1_O  MAXIMO.LOCATIONS.GISPARAM1%TYPE := NULL;

BEGIN

    SELECT GISPARAM1 INTO GISPARAM1_O
    FROM MAXIMO.LOCATIONS A
    WHERE A.ORGID=ORGID_I
    AND   A.SITEID=SITEID_I
    AND   A.LOCATION=LOCATION_I;

    RETURN  GISPARAM1_O;

    EXCEPTION

    WHEN OTHERS THEN
         GISPARAM1_O := NULL;

    RETURN GISPARAM1_O;
END;

/* FUNCTION TO GET PARENT REQUIRED FOR FINDING BUILDING*/
FUNCTION GET_PARENT(ORGID_I  IN MAXIMO.LOCATIONS.ORGID%TYPE,
                    SITEID_I IN MAXIMO.LOCATIONS.SITEID%TYPE,
                    LOCATION_I    IN MAXIMO.LOCATIONS.LOCATION%TYPE)
                   RETURN MAXIMO.LOCHIERARCHY.PARENT%TYPE
IS
   PARENT_O  MAXIMO.LOCHIERARCHY.PARENT%TYPE := NULL;

BEGIN

    SELECT PARENT INTO PARENT_O
    FROM MAXIMO.LOCHIERARCHY A
    WHERE  A.ORGID=ORGID_I
    AND    A.SITEID=SITEID_I
    AND    A.LOCATION=LOCATION_I;

    RETURN  PARENT_O;

    EXCEPTION

    WHEN OTHERS THEN
         PARENT_O :=NULL;

    RETURN PARENT_O;
END;

/* FUNCTION TO GET BUILDING OF THE GIVEN LOCATION*/
FUNCTION GET_BUILDING(ORGID_I  IN MAXIMO.LOCATIONS.ORGID%TYPE,
                      SITEID_I IN MAXIMO.LOCATIONS.SITEID%TYPE,
                      LOCATION_I    IN MAXIMO.LOCATIONS.LOCATION%TYPE)
                    RETURN MAXIMO.LOCATIONS.LOCATION%TYPE

IS
   BUILDING_O   MAXIMO.LOCATIONS.LOCATION%TYPE := NULL;
   GISPARAM1_T  MAXIMO.LOCATIONS.GISPARAM1%TYPE := NULL;
   PARENT_T     MAXIMO.LOCHIERARCHY.PARENT%TYPE := NULL;

BEGIN

IF LOCATION_I = 'LBNL' OR LOCATION_I = 'H' OR LOCATION_I = 'C' OR
   LOCATION_I = 'O' OR LOCATION_I = 'N' THEN

    BUILDING_O := LOCATION_I;
    RETURN BUILDING_O;

END IF;

GISPARAM1_T := MAXIMO.LBL_MAXIMO_PKG.GET_GISPARAM1(ORGID_I, SITEID_I,LOCATION_I);

IF GISPARAM1_T = 'B' THEN
      BUILDING_O := LOCATION_I;
    RETURN  BUILDING_O;
END IF;

-- FLOOR LEVEL
PARENT_T  := MAXIMO.LBL_MAXIMO_PKG.GET_PARENT(ORGID_I, SITEID_I,LOCATION_I);
GISPARAM1_T := MAXIMO.LBL_MAXIMO_PKG.GET_GISPARAM1(ORGID_I, SITEID_I,PARENT_T);

IF GISPARAM1_T = 'B' THEN
      BUILDING_O := PARENT_T;
      RETURN  BUILDING_O;
END IF;

-- ROOM LEVEL
PARENT_T  := MAXIMO.LBL_MAXIMO_PKG.GET_PARENT(ORGID_I, SITEID_I,PARENT_T);
GISPARAM1_T := MAXIMO.LBL_MAXIMO_PKG.GET_GISPARAM1(ORGID_I, SITEID_I,PARENT_T);

IF GISPARAM1_T = 'B' THEN
      BUILDING_O := PARENT_T;
      RETURN  BUILDING_O;
END IF;

  BUILDING_O := LOCATION_I;
RETURN BUILDING_O;

END;

/* FUNCTION TO GET THE LEADCRAFT DESCRIPTION OF THE WORKORDER */
FUNCTION GET_LEADCRAFT_INFO(ORGID_I  IN MAXIMO.WORKORDER.ORGID%TYPE,
                            LEADCRAFT_I IN MAXIMO.WORKORDER.LEADCRAFT%TYPE,
                            INFO_TYPE_I IN MAXIMO.WORKORDER.STATUS%TYPE)
             RETURN MAXIMO.CRAFT.DESCRIPTION%TYPE
IS
     CRAFT_DESC_O   MAXIMO.CRAFT.DESCRIPTION%TYPE :=NULL;
     CRAFT_T        MAXIMO.LABORCRAFTRATE.CRAFT%TYPE :=NULL;

BEGIN
  BEGIN
     SELECT RTRIM(CRAFT) INTO CRAFT_T
     FROM   MAXIMO.LABORCRAFTRATE
     WHERE ORGID=ORGID_I
     AND   LABORCODE=LEADCRAFT_I
     AND   DEFAULTCRAFT=1;

     IF INFO_TYPE_I='CODE' THEN
        RETURN CRAFT_T;
     END IF;

     SELECT DESCRIPTION
     INTO CRAFT_DESC_O
     FROM MAXIMO.CRAFT
     WHERE CRAFT=CRAFT_T;


     IF INFO_TYPE_I != 'CODE' THEN
         RETURN CRAFT_DESC_O;
     END IF;

    EXCEPTION
     WHEN OTHERS THEN
      RETURN NULL;
    END;
END;

/* FUNCTION TO GET THE LAST MONTH MILEAGE OF THE VEHICLE FOR THE GIVEN DATE*/
FUNCTION GET_LAST_MILEAGE(ORGID_I    IN MAXIMO.ASSET.ORGID%TYPE,
                          SITEID_I   IN MAXIMO.ASSET.SITEID%TYPE,
                          ASSETNUM_I IN MAXIMO.ASSET.ASSETNUM%TYPE,
                          READINGDATE_I IN BATCH_MAXIMO.LBL_VEHMILEHISTORY.READINGDATE%TYPE)
                   RETURN MAXIMO.ASSETMETER.LASTREADING%TYPE
IS
   LASTREADING_O MAXIMO.ASSETMETER.LASTREADING%TYPE :=0;

BEGIN

 BEGIN

  SELECT A.LASTREADING INTO LASTREADING_O
  FROM BATCH_MAXIMO.LBL_VEHMILEHISTORY A
  WHERE  A.ORGID=ORGID_I
  AND    A.SITEID=SITEID_I
  AND    A.ASSETNUM=ASSETNUM_I
  AND    A.READINGDATE=(SELECT MAX(B.READINGDATE) FROM BATCH_MAXIMO.LBL_VEHMILEHISTORY B
  WHERE  B.ORGID=ORGID_I
  AND    B.SITEID=SITEID_I
  AND    B.ASSETNUM=ASSETNUM_I
  AND   TRUNC(B.READINGDATE) <= TRUNC(READINGDATE_I));

  RETURN  LASTREADING_O;

  EXCEPTION WHEN OTHERS  THEN
     NULL;
  END;

   -- ADDED BY PANKAJ ON 6/24/11
   -- IF ROW NOT FOUND, THEN, THE VEHICLE COULD BE NEW. IF IT IS A NEW VEHICLE
   -- THEN, GET THE READING FROM ASSETMETER TABLE FOR METERNAME=DELIVERY.

     BEGIN
       SELECT NVL(LASTREADING,0)
       INTO   LASTREADING_O
       FROM   MAXIMO.ASSETMETER A
       WHERE  A.ASSETNUM=ASSETNUM_I
       AND    A.METERNAME='DELIVERY'
       AND    A.SITEID=SITEID_I
       AND    A.MEASUREUNITID='MILES'
       AND    A.CHANGEDATE=(SELECT MAX(B.CHANGEDATE)
         FROM MAXIMO.ASSETMETER B
         WHERE  B.ASSETNUM=A.ASSETNUM
         AND    B.METERNAME='DELIVERY'
         AND    B.SITEID=A.SITEID
         AND    B.MEASUREUNITID=A.MEASUREUNITID);

      RETURN   LASTREADING_O;


      EXCEPTION WHEN OTHERS
       THEN
        RETURN   LASTREADING_O;

     END;


END;


/* FUNCTION TO GET TOTAL MILES DRIVEN BY THE VEHICLE FOR THE GIVEN
   FINANCIALPERIOD */

FUNCTION GET_MILEAGE_4_PERIOD(ORGID_I    IN MAXIMO.ASSET.ORGID%TYPE,
                              SITEID_I   IN MAXIMO.ASSET.SITEID%TYPE,
                              ASSETNUM_I IN MAXIMO.ASSET.ASSETNUM%TYPE,
                              FINANCIALPERIOD_I IN MAXIMO.FINANCIALPERIODS.FINANCIALPERIOD%TYPE)
          RETURN MAXIMO.ASSETMETER.LASTREADING%TYPE
IS
   LASTREADING_O  MAXIMO.ASSETMETER.LASTREADING%TYPE :=0;
   TO_DATE_T      MAXIMO.FINANCIALPERIODS.PERIODEND%TYPE;
   REC_CNT_T      NUMBER(7) :=0;
   END_READING_T    MAXIMO.ASSETMETER.LASTREADING%TYPE :=0;
   START_READING_T  MAXIMO.ASSETMETER.LASTREADING%TYPE :=0;

BEGIN

   SELECT (PERIODEND-1) INTO  TO_DATE_T
   FROM   MAXIMO.FINANCIALPERIODS
   WHERE  ORGID=ORGID_I
   AND    FINANCIALPERIOD=FINANCIALPERIOD_I;

  BEGIN

    SELECT LASTREADING INTO END_READING_T
    FROM BATCH_MAXIMO.LBL_VEHMILEHISTORY
    WHERE ORGID=ORGID_I
    AND   SITEID=SITEID_I
    AND   ASSETNUM=ASSETNUM_I
    AND   READINGDATE=TO_DATE_T;
  EXCEPTION
    WHEN OTHERS THEN
      END_READING_T :=0;
  END;


-- GET THE STARTING METERREADING FOR THE PERIOD

  BEGIN

   SELECT A.LASTREADING INTO START_READING_T
   FROM BATCH_MAXIMO.LBL_VEHMILEHISTORY A
   WHERE ORGID=ORGID_I
   AND   SITEID=SITEID_I
   AND   ASSETNUM=ASSETNUM_I
   AND   A.READINGDATE=(SELECT MAX(B.READINGDATE) FROM BATCH_MAXIMO.LBL_VEHMILEHISTORY B
   WHERE B.ORGID=ORGID_I
   AND   B.SITEID=SITEID_I
   AND   B.ASSETNUM=ASSETNUM_I
   AND   TRUNC(B.READINGDATE) < TRUNC(TO_DATE_T));

  EXCEPTION
    WHEN OTHERS THEN
       START_READING_T :=0;
  END;

IF END_READING_T >= START_READING_T
THEN
   LASTREADING_O :=END_READING_T   - START_READING_T;
ELSE
   LASTREADING_O :=START_READING_T - END_READING_T;
END IF;


RETURN LASTREADING_O;

END;

/* FUNCTION TO GET NAME OF PROJECT */
FUNCTION GET_PROJECT_NAME(PROJECT_ID_I  IN LBL_V_PROJACT.GLACCOUNT%TYPE)
                         RETURN LBL_V_PROJACT.ACCOUNTNAME%TYPE
IS
     DESCR_O       LBL_V_PROJACT.ACCOUNTNAME%TYPE;
BEGIN

       SELECT ACCOUNTNAME INTO DESCR_O
       FROM LBL_V_PROJACT
       WHERE GLACCOUNT=PROJECT_ID_I
       AND ACTIVE=1;

      RETURN DESCR_O;

    EXCEPTION

     WHEN OTHERS THEN
            DESCR_O := NULL;

         RETURN DESCR_O;
END;

/* FUNCTION TO GET TOTAL AREA OF THE BUILDING */
FUNCTION GET_BUILDING_AREA(BUILDING_NUMBER_I  IN  SPADM.SPACE_ROOM.BUILDING_NUMBER%TYPE)
                         RETURN MAXIMO.POLINE.CONVERSION%TYPE
IS
     TOTAL_AREA_O       MAXIMO.POLINE.CONVERSION%TYPE;
BEGIN
     SELECT NVL(SUM(AREA),0) INTO TOTAL_AREA_O FROM SPADM.SPACE_ROOM
     WHERE BUILDING_NUMBER=BUILDING_NUMBER_I;

         RETURN TOTAL_AREA_O;

    EXCEPTION

     WHEN OTHERS THEN
               TOTAL_AREA_O :=0;

         RETURN TOTAL_AREA_O;
END;



/* FUNCTION TO GET DESCRIPTION OF THE VALUELIST */

FUNCTION GET_VALUELIST_DESCRIPTION(ORGID_I    IN MAXIMO.ALNDOMAIN.ORGID%TYPE,
                                   SITEID_I   IN MAXIMO.ASSET.SITEID%TYPE,
                                   LISTNAME_I  IN  MAXIMO.ALNDOMAIN.DOMAINID%TYPE,
                                   VALUE_I     IN  MAXIMO.ALNDOMAIN.VALUE%TYPE)
                          RETURN MAXIMO.ALNDOMAIN.DESCRIPTION%TYPE
IS
     DESCR_O   MAXIMO.ALNDOMAIN.DESCRIPTION%TYPE;

BEGIN

    BEGIN

     SELECT DESCRIPTION INTO DESCR_O
     FROM MAXIMO.ALNDOMAIN
     WHERE  ORGID=ORGID_I
     AND    SITEID=SITEID_I
     AND    DOMAINID=LISTNAME_I
     AND    VALUE=VALUE_I;

         RETURN DESCR_O;

    EXCEPTION

     WHEN OTHERS THEN
            DESCR_O := NULL;

         RETURN DESCR_O;
    END;
 END;

FUNCTION GET_ROLLUP_VALUE(ORGID_I  IN MAXIMO.WORKORDER.ORGID%TYPE,
                          SITEID_I IN MAXIMO.WORKORDER.SITEID%TYPE,
                          P_WONUM   IN MAXIMO.WORKORDER.WONUM%TYPE,
                          P_COLUMN  IN VARCHAR2)
         RETURN NUMBER
IS
V_TOTAL NUMBER :=0;

SQL_STMT VARCHAR2(2000);

BEGIN

    BEGIN

      V_TOTAL :=0;

      SQL_STMT := 'SELECT SUM(' || P_COLUMN ||  ') FROM MAXIMO.WORKORDER B ';
      SQL_STMT := SQL_STMT || '  WHERE B.ORGID='  || '''' || ORGID_I  || '''' ;
      SQL_STMT := SQL_STMT || '  AND   B.SITEID=' || '''' || SITEID_I || '''' ;
      SQL_STMT := SQL_STMT || '  CONNECT BY PRIOR B.WONUM=B.PARENT START WITH WONUM=''' || P_WONUM ||  '''';

      EXECUTE IMMEDIATE SQL_STMT INTO V_TOTAL;


      RETURN V_TOTAL;

    EXCEPTION
        WHEN NO_DATA_FOUND THEN
        V_TOTAL :=0;

        RETURN V_TOTAL;
    END;


END;

FUNCTION CONVERT_TO_HOURS (IN_HOURS IN FLOAT) RETURN VARCHAR IS
          HOURS FLOAT;                          -- STORES HOURS
          FLAG BOOLEAN := FALSE;            I INTEGER;
          J INTEGER;
          S VARCHAR(10) := NULL;
    BEGIN
        HOURS := IN_HOURS;                      -- GET HOURS
        IF HOURS < 0.0   THEN                   -- IF LESS THAN 0
            HOURS := ABS(HOURS);                -- TAKE OUT THE NEGATIVE
            FLAG := TRUE;                       -- SET THE FLAG TO TRUE
        END IF;
            I := TRUNC(HOURS);            -- CONVERT THE HOURS TO A WHOLE NUMBER
        J := TO_NUMBER(ROUND((HOURS-(I))*(60.00))); --CALCULATE MINUTES
           IF J < 10   THEN                   -- IF MINUTES ARE LESS THAN 10
           S := (I ||':' ||'0' ||J);       -- ADD A HOURS + COLON + ZERO+ MINUTES
        ELSE
           S := (I||':'||J);               --ELSE ADD HOURS+COLOR+MINUTES
        END IF;
                IF FLAG THEN                       -- IF FLAG IS RAISED
           S := ('-' ||S);                 -- ADD THE NEGATIVE SIGN TO THE HOURS:MINUTES
        END IF;
   RETURN S;                               --RETURN HOURS:MINUTES
     END CONVERT_TO_HOURS;                    -- END FUNCTION



/* FUNCTION TO GET THE VALIDITY OF THIS PROJECT FOR THE GIVEN DATE */
FUNCTION IS_PS_PROJECT_VALID(PROJECT_ID_I  IN varchar2,
                             DATE_I        IN DATE)
                          RETURN VARCHAR2  IS

      CHARGEABLE_T      VARCHAR2(1);
 BEGIN

    RETURN '0';
  /*  THIS FUNCTION IS NOT USED ANY MORE AFTER FSM
    BEGIN
       SELECT A.PROJECT_STATUS INTO CHARGEABLE_T
         FROM   PS_PROJECT_STATUS A
         WHERE  A.BUSINESS_UNIT='LBNL'
         AND    A.PROJECT_ID=PROJECT_ID_I
         AND    A.EFFDT =(SELECT MAX(A_ED.EFFDT) FROM PS_PROJECT_STATUS A_ED
                          WHERE A.BUSINESS_UNIT = A_ED.BUSINESS_UNIT
                          AND A.PROJECT_ID = A_ED.PROJECT_ID
                          AND A_ED.PROJECT_ID=PROJECT_ID_I
                          AND A_ED.EFFDT <= DATE_I)
         AND A.EFFSEQ =(SELECT MAX(A_ES.EFFSEQ) FROM PS_PROJECT_STATUS A_ES
                        WHERE A.BUSINESS_UNIT = A_ES.BUSINESS_UNIT
                        AND A.PROJECT_ID = A_ES.PROJECT_ID
                        AND A_ES.PROJECT_ID=PROJECT_ID_I
                        AND A.EFFDT = A_ES.EFFDT);

     IF (CHARGEABLE_T !='C')  THEN
       RETURN '1';
     ELSE
       RETURN '0';
     END IF;

   EXCEPTION WHEN OTHERS THEN
      RETURN '0';

   END; */
  END ; -- END OF FUNCTION

/* FUNCTION TO GET LONG DESCRIPTION TEXT FOR GIVEN ENTITY */
FUNCTION GET_LONGDESCRIPTION(LDKEY_I IN MAXIMO.LONGDESCRIPTION.LDKEY%TYPE,
                             LDOWNERTABLE_I  IN MAXIMO.LONGDESCRIPTION.LDOWNERTABLE%TYPE,
                             LDOWNERCOL_I    IN MAXIMO.LONGDESCRIPTION.LDOWNERCOL%TYPE)
    RETURN VARCHAR2
    IS
     LDTEXT_T VARCHAR2(32767);
   BEGIN

    BEGIN
      SELECT  REPLACE_NON_ASCII(SUBSTR(TO_CHAR(A.LDTEXT),1,32767),' ') INTO LDTEXT_T
      FROM    MAXIMO.LONGDESCRIPTION A
      WHERE   A.LDKEY=LDKEY_I
      AND     A.LDOWNERTABLE =LDOWNERTABLE_I
      AND     A.LANGCODE='EN'
      AND     A.LDOWNERCOL=LDOWNERCOL_I;

    EXCEPTION WHEN OTHERS THEN
      NULL;
    END;

    RETURN LDTEXT_T;

END; -- END OF FUNCTION



/* FUNCTION TO NEW PROJECT ID AND ACTIVITY ID COMBO FOR A GIVEN GLACCOUNT */
FUNCTION GET_PROJACTCOMBO(GLACCOUNT_I MAXIMO.WORKORDER.GLACCOUNT%TYPE)
                         RETURN VARCHAR2


IS
      GLACCOUNT_O WORKORDER.GLACCOUNT%TYPE;

   BEGIN

        BEGIN

         SELECT TRIM(TRIM(PROJECT_ID)||'.'||TRIM(ACTIVITY_ID))
         INTO   GLACCOUNT_O
         --FROM   FMSADM.PS_ZL_PROJECT_MAP@FMS A
         FROM FMSADM.PS_ZL_PROJECT_MAP@FMS9 A
         WHERE  A.PROJECT_ID_FROM=GLACCOUNT_I;

         EXCEPTION WHEN OTHERS THEN
          NULL;
         END;


         RETURN GLACCOUNT_O;

END;




/* FUNCTION TO REMOVE NON-ASCII CHARACTERS AND REPLACE WITH DESIRED C
   CHARACTER */
FUNCTION REPLACE_NON_ASCII(INPUT_STR_T VARCHAR, REPLACE_WITH_T VARCHAR)
                         RETURN VARCHAR
                         IS


    STR_T VARCHAR2(32767);
    ACT NUMBER :=0;
    CNT_T NUMBER :=0;
    ASKEY_T NUMBER :=0;
    OUTPUT_STR_T VARCHAR2(32767);

 BEGIN

    STR_T :='^'||TO_CHAR(INPUT_STR_T)||'^';
    CNT_T :=LENGTH(STR_T);

   FOR I IN 1 .. CNT_T

    LOOP

    ASKEY_T :=0;

    SELECT ASCII(SUBSTR(STR_T,I,1)) INTO ASKEY_T
    FROM DUAL;

    IF (ASKEY_T < 32 OR ASKEY_T >=127)
      THEN
      STR_T :='^'||REPLACE(STR_T, CHR(ASKEY_T),REPLACE_WITH_T);
    END IF;

   END LOOP;

    OUTPUT_STR_T := TRIM(LTRIM(RTRIM(TRIM(STR_T),'^'),'^'));

    RETURN OUTPUT_STR_T;

END;

/* FUNCTION TO REMOVE NON-ASCII CHARACTERS */
FUNCTION REPLACE_NON_ASCII(INPUT_STR_T VARCHAR)
                         RETURN VARCHAR
                         IS


    STR_T VARCHAR2(32767);
    ACT NUMBER :=0;
    CNT_T NUMBER :=0;
    ASKEY_T NUMBER :=0;
    OUTPUT_STR_T VARCHAR2(32767);

 BEGIN

    STR_T :='^'||TO_CHAR(INPUT_STR_T)||'^';
    CNT_T :=LENGTH(STR_T);

   FOR I IN 1 .. CNT_T

    LOOP

    ASKEY_T :=0;

    SELECT ASCII(SUBSTR(STR_T,I,1)) INTO ASKEY_T
    FROM DUAL;

    IF (ASKEY_T < 32 OR ASKEY_T >=127)
      THEN
      STR_T :='^'||REPLACE(STR_T, CHR(ASKEY_T),'');
    END IF;

   END LOOP;

    OUTPUT_STR_T := TRIM(LTRIM(RTRIM(TRIM(STR_T),'^'),'^'));

   RETURN OUTPUT_STR_T;
END;



  /* FUNCTION TO FIND OUT WHETHER TO SEND ACK/NOTIFICATION */
FUNCTION ACK_NOTIFY_SENT(DATE_I IN MAXIMO.WORKORDER.CHANGEDATE%TYPE)
                        RETURN VARCHAR2  IS

     LASTDATETIME_T WORKORDER.CHANGEDATE%TYPE;

 BEGIN

  SELECT TO_DATE(VARVALUE,'MM/DD/YYYY HH24:MI:SS')
  INTO LASTDATETIME_T
  FROM BATCH_MAXIMO.LBL_MAXVARS
  WHERE VARNAME='WO_ACKNOTIFY_LASTDATE';


  IF (DATE_I > LASTDATETIME_T) THEN
   RETURN 'YES';
  ELSE
   RETURN 'NO';
  END IF;

 END;

 PROCEDURE SEND_MAIL_HTML(P_TO        IN VARCHAR2,
                                       P_FROM      IN VARCHAR2,
                                       P_SUBJECT   IN VARCHAR2,
                                       P_TEXT_MSG  IN VARCHAR2 DEFAULT NULL,
                                       P_HTML_MSG  IN VARCHAR2 DEFAULT NULL,
                                       P_SMTP_HOST IN VARCHAR2,
                                       P_SMTP_PORT IN NUMBER DEFAULT 25)
AS
  L_MAIL_CONN   UTL_SMTP.CONNECTION;
  L_BOUNDARY    VARCHAR2(50) := '----=*#ABC1234321CBA#*=';
BEGIN
  L_MAIL_CONN := UTL_SMTP.OPEN_CONNECTION(P_SMTP_HOST, P_SMTP_PORT);
  UTL_SMTP.HELO(L_MAIL_CONN, P_SMTP_HOST);
  UTL_SMTP.MAIL(L_MAIL_CONN, P_FROM);
  UTL_SMTP.RCPT(L_MAIL_CONN, P_TO);

  UTL_SMTP.OPEN_DATA(L_MAIL_CONN);

  UTL_SMTP.WRITE_DATA(L_MAIL_CONN, 'DATE: ' || TO_CHAR(SYSDATE, 'DD-MON-YYYY HH24:MI:SS') || UTL_TCP.CRLF);
  UTL_SMTP.WRITE_DATA(L_MAIL_CONN, 'TO: ' || P_TO || UTL_TCP.CRLF);
  UTL_SMTP.WRITE_DATA(L_MAIL_CONN, 'FROM: ' || P_FROM || UTL_TCP.CRLF);
  UTL_SMTP.WRITE_DATA(L_MAIL_CONN, 'SUBJECT: ' || P_SUBJECT || UTL_TCP.CRLF);
  UTL_SMTP.WRITE_DATA(L_MAIL_CONN, 'REPLY-TO: ' || P_FROM || UTL_TCP.CRLF);
  UTL_SMTP.WRITE_DATA(L_MAIL_CONN, 'MIME-VERSION: 1.0' || UTL_TCP.CRLF);
  UTL_SMTP.WRITE_DATA(L_MAIL_CONN, 'CONTENT-TYPE: MULTIPART/ALTERNATIVE; BOUNDARY="' || L_BOUNDARY || '"' || UTL_TCP.CRLF || UTL_TCP.CRLF);

  IF P_TEXT_MSG IS NOT NULL THEN
    UTL_SMTP.WRITE_DATA(L_MAIL_CONN, '--' || L_BOUNDARY || UTL_TCP.CRLF);
    UTL_SMTP.WRITE_DATA(L_MAIL_CONN, 'CONTENT-TYPE: TEXT/PLAIN; CHARSET="ISO-8859-1"' || UTL_TCP.CRLF || UTL_TCP.CRLF);

    UTL_SMTP.WRITE_DATA(L_MAIL_CONN, P_TEXT_MSG);
    UTL_SMTP.WRITE_DATA(L_MAIL_CONN, UTL_TCP.CRLF || UTL_TCP.CRLF);
  END IF;

  IF P_HTML_MSG IS NOT NULL THEN
    UTL_SMTP.WRITE_DATA(L_MAIL_CONN, '--' || L_BOUNDARY || UTL_TCP.CRLF);
    UTL_SMTP.WRITE_DATA(L_MAIL_CONN, 'CONTENT-TYPE: TEXT/HTML; CHARSET="ISO-8859-1"' || UTL_TCP.CRLF || UTL_TCP.CRLF);

    UTL_SMTP.WRITE_DATA(L_MAIL_CONN, P_HTML_MSG);
    UTL_SMTP.WRITE_DATA(L_MAIL_CONN, UTL_TCP.CRLF || UTL_TCP.CRLF);
  END IF;

  UTL_SMTP.WRITE_DATA(L_MAIL_CONN, '--' || L_BOUNDARY || '--' || UTL_TCP.CRLF);
  UTL_SMTP.CLOSE_DATA(L_MAIL_CONN);

  UTL_SMTP.QUIT(L_MAIL_CONN);
END;

  /* FUNCTION TO FIND OUT IBOX ROUTE FOR A LOCATION */
FUNCTION GET_ROUTE(LOCATION_I LOCATIONS.LOCATION%TYPE)
  RETURN LOCATIONSPEC.ALNVALUE%TYPE

  IS

   BLDG_T LOCATIONS.LOCATION%TYPE;
   ROUTE_T LOCATIONSPEC.ALNVALUE%TYPE :=NULL;

BEGIN

     BEGIN
       SELECT LO1 INTO BLDG_T
        FROM MAXIMO.LOCATIONS
        WHERE LOCATION=LOCATION_I
        AND   GISPARAM1 IS NOT NULL;
     EXCEPTION WHEN OTHERS THEN
        NULL;
     END;

     BEGIN
      SELECT ALNVALUE INTO ROUTE_T
      FROM MAXIMO.LOCATIONSPEC
      WHERE LOCATION=BLDG_T
      AND   ASSETATTRID='IB-ROUTE'
      AND   ALNVALUE IS NOT NULL;
      EXCEPTION WHEN OTHERS THEN
        NULL;
     END;

    RETURN ROUTE_T;

END;


/* FUNCTION TO GET THE ID OF INTEGRATION USER */
FUNCTION GET_MXINT_USERID
       RETURN VARCHAR2

IS

 CHANGEBY_T WORKORDER.CHANGEBY%TYPE;


BEGIN

    -- MAXIMO 7.6
    SELECT PROPVALUE
    INTO  CHANGEBY_T
    FROM MAXPROPVALUE
    WHERE UPPER(PROPNAME)='MXE.INT.DFLTUSER';

    RETURN CHANGEBY_T;

END;


/* FUNCTION TO RESET SEQUENCE */
FUNCTION RESET_SEQUENCE(SEQNAME_I VARCHAR2)
       RETURN VARCHAR2

IS


BEGIN

    EXECUTE IMMEDIATE 'DROP SEQUENCE ' ||   SEQNAME_I;

    EXECUTE IMMEDIATE 'CREATE SEQUENCE ' || SEQNAME_I ||
    '  INCREMENT BY 1 ' ||
    '   START WITH 1 ' ||
    '   MINVALUE 1 ' ||
    '   MAXVALUE 9999999999999999999999999999 ' ||
    '   NOCYCLE' ||
    '   NOORDER' ||
    '   CACHE 20' ;

RETURN 'SUCCESS';
END;



PROCEDURE SEND_MAIL_HTML_CLOB(P_TO        IN VARCHAR2,
                                       P_FROM      IN VARCHAR2,
                                       P_SUBJECT   IN VARCHAR2,
                                       P_CLOB_MSG IN CLOB,
                                       P_SMTP_HOST IN VARCHAR2,
                                       P_SMTP_PORT IN NUMBER DEFAULT 25)
AS
  L_MAIL_CONN   UTL_SMTP.CONNECTION;
  L_BOUNDARY    VARCHAR2(50) := '----=*#ABC1234321CBA#*=';
  L_OFFSET       NUMBER;
  L_AMOUNT       NUMBER;

BEGIN
  L_MAIL_CONN := UTL_SMTP.OPEN_CONNECTION(P_SMTP_HOST, P_SMTP_PORT);
  UTL_SMTP.HELO(L_MAIL_CONN, P_SMTP_HOST);
  UTL_SMTP.MAIL(L_MAIL_CONN, P_FROM);
  UTL_SMTP.RCPT(L_MAIL_CONN, P_TO);

  UTL_SMTP.OPEN_DATA(L_MAIL_CONN);

  UTL_SMTP.WRITE_DATA(L_MAIL_CONN, 'DATE: ' || TO_CHAR(SYSDATE, 'DD-MON-YYYY HH24:MI:SS') || UTL_TCP.CRLF);
  UTL_SMTP.WRITE_DATA(L_MAIL_CONN, 'TO: ' || P_TO || UTL_TCP.CRLF);
  UTL_SMTP.WRITE_DATA(L_MAIL_CONN, 'FROM: ' || P_FROM || UTL_TCP.CRLF);
  UTL_SMTP.WRITE_DATA(L_MAIL_CONN, 'SUBJECT: ' || P_SUBJECT || UTL_TCP.CRLF);
  UTL_SMTP.WRITE_DATA(L_MAIL_CONN, 'REPLY-TO: ' || P_FROM || UTL_TCP.CRLF);
  UTL_SMTP.WRITE_DATA(L_MAIL_CONN, 'MIME-VERSION: 1.0' || UTL_TCP.CRLF);
  UTL_SMTP.WRITE_DATA(L_MAIL_CONN, 'CONTENT-TYPE: MULTIPART/ALTERNATIVE; BOUNDARY="' || L_BOUNDARY || '"' || UTL_TCP.CRLF || UTL_TCP.CRLF);



  IF (P_CLOB_MSG IS NOT NULL) THEN
    UTL_SMTP.WRITE_DATA(L_MAIL_CONN, '--' || L_BOUNDARY || UTL_TCP.CRLF);
    UTL_SMTP.WRITE_DATA(L_MAIL_CONN, 'CONTENT-TYPE: TEXT/HTML; CHARSET="ISO-8859-1"' || UTL_TCP.CRLF || UTL_TCP.CRLF);


     -- SEND THE EMAIL IN 1900 BYTE CHUNKS TO UTL_SMTP
      L_OFFSET  := 1;
      L_AMOUNT := 1900;

      WHILE L_OFFSET < DBMS_LOB.GETLENGTH(P_CLOB_MSG)
       LOOP
          UTL_SMTP.WRITE_DATA(L_MAIL_CONN,
                            DBMS_LOB.SUBSTR(P_CLOB_MSG,L_AMOUNT,L_OFFSET));
          L_OFFSET  := L_OFFSET + L_AMOUNT ;
          L_AMOUNT := LEAST(1900,DBMS_LOB.GETLENGTH(P_CLOB_MSG) - L_AMOUNT);
      END LOOP;


    UTL_SMTP.WRITE_DATA(L_MAIL_CONN, UTL_TCP.CRLF || UTL_TCP.CRLF);
  END IF;

  UTL_SMTP.WRITE_DATA(L_MAIL_CONN, '--' || L_BOUNDARY || '--' || UTL_TCP.CRLF);
  UTL_SMTP.CLOSE_DATA(L_MAIL_CONN);

  UTL_SMTP.QUIT(L_MAIL_CONN);
END;


-- PROCEDURE TO GET PROPERTY VALUE OF A GIVEN PROPERTY

PROCEDURE GET_PROPERTY_VALUE
(
  P_PROPERTY   IN   MAXPROPVALUE.PROPNAME%TYPE,
  P_PROPVALUE  OUT  MAXPROPVALUE.PROPVALUE%TYPE
 )
AS


BEGIN

   BEGIN

   SELECT PROPVALUE
   INTO   P_PROPVALUE
   FROM   MAXPROPVALUE
   WHERE  PROPNAME=P_PROPERTY;

   EXCEPTION WHEN OTHERS THEN
      NULL;
   END ;
END;








END;

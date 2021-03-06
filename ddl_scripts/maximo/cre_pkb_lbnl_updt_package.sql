CREATE OR REPLACE PACKAGE BODY lbnl_updt_package
IS

/* UPDATE FINANCIALPERIODS TABLE WITH THE GIVEN VALUES */

FUNCTION UPDATE_FEEDER_CLOSE(FINANCIALPERIOD_I IN FINANCIALPERIODS.FINANCIALPERIOD%TYPE,
                             FEEDER_NAME_I     IN FINANCIALPERIODS.CLOSEDBY%TYPE,
                             ORGID_I           IN FINANCIALPERIODS.orgid%TYPE)


 RETURN VARCHAR2

  IS
     NO_OF_ROWS_T    NUMBER(5) :=0;
     CLOSEDBY_T         FINANCIALPERIODS.CLOSEDBY%TYPE;
     SUCCESS_T VARCHAR2(1) :='1';

  BEGIN

    SELECT COUNT(*) INTO NO_OF_ROWS_T
    FROM  MAXIMO.FINANCIALPERIODS
    WHERE FINANCIALPERIOD=FINANCIALPERIOD_I
    and   orgid=orgid_i;

    -- UPDATE ONLY IF THE ROW WITH MATCHING FINANCIAL ROW EXISTS
    IF NO_OF_ROWS_T > 0 THEN

       -- GET THE EXISTING COMBINATION OF THE CLOSEDBY
       SELECT CLOSEDBY INTO CLOSEDBY_T
       FROM MAXIMO.FINANCIALPERIODS
       WHERE FINANCIALPERIOD=FINANCIALPERIOD_I
       and   orgid=orgid_i;

       -- CHECK IF INCOMING FEEDER_NAME ALREADY UPDATED OR NOT
       IF INSTR(NVL(CLOSEDBY_T,' '),FEEDER_NAME_I)=0  -- NOT UPDATED
        THEN

             IF LENGTH(CLOSEDBY_T) > 0  THEN
               CLOSEDBY_T := LTRIM(CLOSEDBY_T) || '|' || FEEDER_NAME_I; -- APPEND FEEDER NAME
             ELSE
               CLOSEDBY_T := FEEDER_NAME_I;
             END IF;

             UPDATE MAXIMO.FINANCIALPERIODS
             SET CLOSEDBY=CLOSEDBY_T , CLOSEDATE=SYSDATE, lbl_feederprocessed=CLOSEDBY_T
             WHERE FINANCIALPERIOD=FINANCIALPERIOD_I
             and   orgid=orgid_i;
       END IF;

    END IF;

    RETURN SUCCESS_T ;

  END;



/* INSERT LOCATION INTO MAXIMO TABLES */
FUNCTION INSERT_LOCATION_TABLES(LOCATION_I IN LOCATIONS.LOCATION%TYPE,
                                PARENT_I        IN LOCHIERARCHY.PARENT%TYPE,
                                DESCRIPTION_I           IN LOCATIONS.DESCRIPTION%TYPE,
                                CHANGEBY_I IN LOCATIONS.CHANGEBY%TYPE)
   RETURN VARCHAR2
IS
   TBL_ROWS_COUNT_T NUMBER(4);
   ANCESTOR_ROWS_CNT NUMBER(4);
   LOCANCESTOR_T LOCANCESTOR.ANCESTOR%TYPE;
   PARENT_T     LOCHIERARCHY.PARENT%TYPE;
   LOCATION_T    LOCATIONS.LOCATION%TYPE;
   CURSOR LOCANCESTOR_CUR IS SELECT  ANCESTOR FROM MAXIMO.LOCANCESTOR
                             WHERE   LOCATION=PARENT_T;
   SUCCESS_T VARCHAR2(1) :='1';
BEGIN

    -- INSERT RECORD INTO MAXIMO LOCOPER TABLE

    TBL_ROWS_COUNT_T :=0;
    LOCATION_T := LTRIM(RTRIM(LOCATION_I));
    PARENT_T := LTRIM(RTRIM(PARENT_I));

    SELECT COUNT(*) INTO TBL_ROWS_COUNT_T
    FROM MAXIMO.LOCOPER
    WHERE LOCATION=LOCATION_T;

    IF TBL_ROWS_COUNT_T = 0 THEN
          INSERT INTO MAXIMO.LOCOPER (LOCATION) VALUES (LOCATION_T);
    END IF;

    -- INSERT RECORD IN MAXIMO LOCHIERARCHY TABLE
    TBL_ROWS_COUNT_T :=0;
     SELECT COUNT(*) INTO TBL_ROWS_COUNT_T
     FROM MAXIMO.LOCHIERARCHY
     WHERE LOCATION=LOCATION_T AND
           PARENT=PARENT_T;

    IF TBL_ROWS_COUNT_T = 0  THEN
         INSERT INTO MAXIMO.LOCHIERARCHY(LOCATION,PARENT,SYSTEMID,CHILDREN)
         VALUES (LOCATION_T, PARENT_T, 'PRIMARY','N');
    END IF;


    -- NOW CHANGE PARENT RECORD TO INDICATE THAT IT HAS CHILD
    -- SET CHILDREN FLAG TO Y

    TBL_ROWS_COUNT_T :=0;
     SELECT COUNT(*) INTO TBL_ROWS_COUNT_T
     FROM MAXIMO.LOCHIERARCHY
     WHERE LOCATION=PARENT_T;

     IF TBL_ROWS_COUNT_T > 0 THEN
        UPDATE MAXIMO.LOCHIERARCHY A
    SET A.CHILDREN='Y'
        WHERE A.LOCATION=PARENT_T;
     END IF;


    -- INSERT RECORD/S INTO MAXIMO LOCANCESTOR
    TBL_ROWS_COUNT_T :=0;
    SELECT COUNT(*) INTO TBL_ROWS_COUNT_T  FROM MAXIMO.LOCANCESTOR
    WHERE LOCATION=LOCATION_T AND
          ANCESTOR=LOCATION_T;

                IF TBL_ROWS_COUNT_T = 0 THEN

                   -- INSERT ITS OWN RECORD
                   INSERT INTO MAXIMO.LOCANCESTOR(LOCATION,ANCESTOR,SYSTEMID)
                        VALUES (LOCATION_T, LOCATION_T,'PRIMARY');

                 -- NOW START INSERTING FOR ITS ANCESTORS
                 IF NOT LOCANCESTOR_CUR%ISOPEN THEN
                    OPEN LOCANCESTOR_CUR;
                END IF;

                LOOP
                 FETCH LOCANCESTOR_CUR INTO LOCANCESTOR_T;

                   EXIT WHEN LOCANCESTOR_CUR%NOTFOUND;
                   LOCANCESTOR_T := LTRIM(RTRIM(LOCANCESTOR_T));
                   ANCESTOR_ROWS_CNT :=0;
                   SELECT COUNT(*) INTO ANCESTOR_ROWS_CNT FROM MAXIMO.LOCANCESTOR
                   WHERE LOCATION=LOCATION_T AND
                         ANCESTOR=LOCANCESTOR_T AND
             SYSTEMID='PRIMARY';
                   IF ANCESTOR_ROWS_CNT = 0 THEN
                      INSERT INTO MAXIMO.LOCANCESTOR (LOCATION,ANCESTOR,SYSTEMID)
                      VALUES (LOCATION_T,LOCANCESTOR_T,'PRIMARY');
                   END IF;
                 END LOOP;

                 IF LOCANCESTOR_CUR%ISOPEN THEN
                    CLOSE LOCANCESTOR_CUR;
                END IF;
             END IF;  -- IF COUNT OF LOCANCESTOR IS = 0

     -- NOW FINALLY INSERT INTO LOCATIONS TABLE
     TBL_ROWS_COUNT_T :=0;
     SELECT COUNT(*) INTO TBL_ROWS_COUNT_T
     FROM MAXIMO.LOCATIONS
     WHERE LOCATION=LOCATION_T;

     IF TBL_ROWS_COUNT_T  = 0 THEN
        INSERT INTO MAXIMO.LOCATIONS (LOCATION, DESCRIPTION, TYPE, CHANGEBY, CHANGEDATE,
    GISPARAM1)
        VALUES (LOCATION_T, DESCRIPTION_I, 'OPERATING',CHANGEBY_I,SYSDATE,
    'O');
     END IF;

    RETURN SUCCESS_T ;

END;


/* INSERT INITIAL METER READING FOR THE VEHICLE */
FUNCTION INSERT_LBL_VEHMILEHISTORY(ASSETNUM_I         IN ASSET.ASSETNUM%TYPE,
                                   METERREADING_I     IN ASSETMETER.LASTREADING%TYPE,
                                   READINGDATE_I      IN ASSETMETER.LASTREADINGDATE%TYPE,
                                   ORGID_I            IN ASSET.ORGID%TYPE,
                                   SITEID_I           IN ASSET.SITEID%TYPE)
   RETURN VARCHAR2
IS

   SUCCESS_T VARCHAR2(1) :='1';

BEGIN

 INSERT INTO BATCH_MAXIMO.LBL_VEHMILEHISTORY
     (ASSETNUM, LASTREADING,READINGDATE,
      ORGID, SITEID, VMH1) VALUES
     (ASSETNUM_I, NVL(METERREADING_I,0), READINGDATE_I,
      ORGID_I, SITEID_I, ' ');

 RETURN SUCCESS_T ;

END;



END;

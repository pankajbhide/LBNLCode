/************************************************************************
*
* PROGRAM NAME          : SP_RECHARGE1.SQL
*
*
* DESCRIPTION           : THIS PL/SQL SCRIPT CALCULATES THE SPACE RECHARGE
*                         FOR EACH ROOM FROM SPACE DATABASE AND INSERTS THE
*                         TRANSACTIONS INTO SPACE_CHARGE_TRANS_DETAIL TABLE
*                         IT ALSO TRANSFERS THE DATA FROM SPACE_ROOM TABLE
*                         TO "SPACE_HISTORICAL_INFO" TABLE.THIS SCRIPT IS
*                         SCHEDULED TO BE EXECUTED ON THE FIRST DAY OF THE
*                         MONTH.
*
* AUTHOR                : PANKAJ BHIDE
*
* DATE WRITTEN          : 01-NOV-1999
*
* DATE MODIFIED         :
*
* MODIFICATION HISORTY  : 01-31-00 Pankaj - Check if room's inactive flag
*                         is set to 'N' for calculations
*
*                        08-AUG-02 - PANKAJ - CHECK WHETHER THE DW.PV_PROJECT
*                        SNAPSHOT IS COMPLETELY REFRESHED. IF IT IS NOT
*                        REFRESHED COMPLETELY, THE PROGRAM WILL WAIT FOR 2
*                        MINUTES AND LOOP TO CHECK WHETHER THE SNAPSHOT
*                        CONTAINS THE RECORD. IT WILL EXIT THE LOOP WHEN
*                        IT FINDS THE RECORD IN THE SNAPSHOT.
*
*
*                        12/16/02 -PANKAJ - CHANGES MADE TO INCORPORATE THE
*                        ACCELERATED GL CLOSING.
*
*                       02/03/03 - PANKAJ - ADJ_ARE_T  IS DECLARED WITH
*                       PRECISION 2  DECIMALS INSTEAD OF NUMBER(5)=>AREA.
*
*                       05/10/03 - PANKAJ - CHANGED THE VALUES OF LINE_DESCR
*                       AS PER THE EMAIL FROM RICH NOSEK ON 05/07/03.
*
*                      05/11/05 - PANAKJ - Commented for monatory_amount > 0
*
*                      02/25/2011 - PANKAJ - A FEW CHANGES AFTER ARCHIBUS
*                                   WENT LIVE
*
*                      07/12/2014 - PANKAJ - CHANGES FOR F$M REMOVE REF
*                                   FOR DW.PV_PROJECT
*
*                      06/25/2015 - PANKAJ - DO NOT REPLACE THE DROP-OUT 
*                                   PROJECT ID WITH INVALID COMBINATION OF  
*                                   PROJECT AND ACTIVITY IN 
*                                   SPACE_CHARGE_TRANS_DETAIL TABLE.
*
*                      10/17/2015   REPLACE CURRENT USE AND CURRENT USE
*                                   DETAILS WITH RM_CAT AND RM_TYPE
*
*                      9/11/2017   JIRA EF-6544 COPIED LBL_PI, COUNT_EM, 
*                                  CAP_EM, LBL_COMMENTS TO SPACE_HISTORICAL_INFO
*************************************************************************/
WHENEVER SQLERROR EXIT 1 ROLLBACK;

DECLARE

    SPACE_BUILDING_REC_T  SPADM.SPACE_BUILDING%ROWTYPE;
    BUILDING_NUMBER_T  SPADM.SPACE_ROOM.BUILDING_NUMBER%TYPE;
    FLOOR_NUMBER_T     SPADM.SPACE_ROOM.FLOOR_NUMBER%TYPE;
    ROOM_NUMBER_T      SPADM.SPACE_ROOM.ROOM_NUMBER%TYPE;
    DESCR_T            MAXIMO.LBL_V_COA.accountname%TYPE;
    PROJECT_OVERRIDE_T SPADM.SPACE_CHARGE_TRANS_DETAIL.PROJECT_OVERRIDE%TYPE;
    PROJECT_ID_T       SPADM.SPACE_CHARGE_DISTRIBUTION.PROJECT_ID%TYPE;
    PROJ_ACT_ID_T      SPADM.SPACE_CHARGE_DISTRIBUTION.PROJ_ACT_ID%TYPE;

    MONETARY_AMOUNT_T  SPADM.SPACE_CHARGE_TRANS_DETAIL.MONETARY_AMOUNT%TYPE;
    PRV_MONETARY_AMOUNT_T SPADM.SPACE_CHARGE_TRANS_DETAIL.MONETARY_AMOUNT%TYPE;
    ACCOUNTING_PERIOD_T SPADM.SPACE_CHARGE_TRANS_DETAIL.ACCOUNTING_PERIOD%TYPE;
    FISCAL_YEAR_T      SPADM.SPACE_CHARGE_TRANS_DETAIL.FISCAL_YEAR%TYPE;
    RESOURCE_AMOUNT_T  SPADM.SPACE_CHARGE_TRANS.RESOURCE_AMOUNT%TYPE;
    CHARGE_ID_T        SPADM.SPACE_CHARGE_TRANS.CHARGE_ID%TYPE;
    RESOURCE_ID_T      SPADM.SPACE_CHARGE_TRANS.RESOURCE_ID%TYPE;
    JOURNAL_LINE_T     SPADM.SPACE_CHARGE_TRANS.JOURNAL_LINE%TYPE;
    ORG_LEVEL_1_CODE_T SPADM.SPACE_CHARGE_TRANS_DETAIL.ORG_LEVEL_1_CODE%TYPE;
    LINEDESCR_T2       SPADM.SPACE_CHARGE_TRANS.LINE_DESCR%TYPE;
    RECHARGE_RATE_T    SPADM.SPACE_CHARGE_RATE.RECHARGE_RATE%TYPE;
    --ADJ_AREA_T         SPADM.SPACE_ROOM.AREA%TYPE;
    ADJ_AREA_T         NUMBER(9,2);
    TRANSACTION_DT_T   SPADM.SPACE_CHARGE_TRANS_DETAIL.TRANSACTION_DT%TYPE;
    REC_COUNT_T        NUMBER(10);
    REC_COUNT_T2        NUMBER(10);
    
     -- FROM ARCHIBUS  - JIRA EF-6544
     T_LBL_PI          SPACE_HISTORICAL_INFO.LBL_PI%TYPE; 
     T_COUNT_EM        SPACE_HISTORICAL_INFO.COUNT_EM%TYPE;
     T_CAP_EM          SPACE_HISTORICAL_INFO.CAP_EM%TYPE;
     T_LBL_COMMENTS    SPACE_HISTORICAL_INFO.LBL_COMMENTS%TYPE;


    TYPE CHARGE_RECTYPE IS
         RECORD (CHARGE_ID  SPACE_CHARGE_TRANS_DETAIL.CHARGE_ID%TYPE,
                PROJ_ACT_ID  SPACE_CHARGE_TRANS_DETAIL.PROJ_ACT_ID%TYPE,
                ORG_LEVEL_1_CODE SPACE_CHARGE_TRANS_DETAIL.ORG_LEVEL_1_CODE%TYPE);

    TYPE CHARGE_TABLE_TYPE IS TABLE OF CHARGE_RECTYPE
         INDEX BY BINARY_INTEGER;

    CHARGE_TABLE CHARGE_TABLE_TYPE;

    MATCHING_ROW BINARY_INTEGER := 1;
    SEARCH_ROW   BINARY_INTEGER := 1;


    /* CURSOR TO READ ALL ROOMS FROM SPACE_ROOM TABLE */

    CURSOR SPACE_ROOM_CUR IS
     SELECT A.*,
     --B.project_id,
     B.PROJ_ACT_ID,
     NVL(B.charged_to_percent,0) CHARGED_TO_PERCENT
     FROM SPADM.SPACE_ROOM A, SPADM.SPACE_CHARGE_DISTRIBUTION B
     WHERE A.building_number=B.building_number(+)
     AND   A.floor_number=B.floor_number(+)
     AND   A.room_number=B.room_number(+)
     ORDER BY A.BUILDING_NUMBER, A.FLOOR_NUMBER, A.ROOM_NUMBER;

    /* CURSOR TO READ SPACE_CHARGE_DISTRIBUTION TABLE */

    CURSOR SPACE_CHARGE_DISTR_CUR IS
     SELECT * FROM SPADM.SPACE_CHARGE_DISTRIBUTION
     WHERE BUILDING_NUMBER=BUILDING_NUMBER_T AND
           FLOOR_NUMBER   =FLOOR_NUMBER_T    AND
           ROOM_NUMBER    =ROOM_NUMBER_T;

    /* CURSOR TO READ SPACE_CHARGE_TRANS_DETAIL TABLE */

    CURSOR SPACE_CHARGE_TRANS_DTL_CUR IS
     SELECT ORG_LEVEL_1_CODE,
            --  PROJECT_ID,
            PROJ_ACT_ID,
            SUM(MONETARY_AMOUNT) RESOURCE_AMOUNT_T
     FROM   SPADM.SPACE_CHARGE_TRANS_DETAIL
     WHERE  FISCAL_YEAR=FISCAL_YEAR_T
     AND    ACCOUNTING_PERIOD=ACCOUNTING_PERIOD_T
     GROUP BY ORG_LEVEL_1_CODE, PROJ_ACT_ID
     ORDER BY ORG_LEVEL_1_CODE, PROJ_ACT_ID;


     /* CURSOR TO READ SPACE_CHARGE_TRANS_DETAIL TABLE
        FOR OFFSETTING ENTRIES */

    CURSOR SPACE_CHARGE_TRANS_OFF_CUR IS
     SELECT ORG_LEVEL_1_CODE,
            SUM(MONETARY_AMOUNT) OFFSET_AMOUNT_T
     FROM   SPADM.SPACE_CHARGE_TRANS_DETAIL
     WHERE  FISCAL_YEAR=FISCAL_YEAR_T
     AND    ACCOUNTING_PERIOD=ACCOUNTING_PERIOD_T
     GROUP BY ORG_LEVEL_1_CODE
     ORDER BY ORG_LEVEL_1_CODE;


     SNAPSHOT_CNT_T  NUMBER(10) :=0;


/*********************************************************************
  MAIN PROGRAM STARTS FROM HERE
 *********************************************************************/
BEGIN

 DBMS_OUTPUT.ENABLE(100000000);

-- FIRSTLY CHECK WHETHER THE SNAPSHOT TITLED DW.PV_PROJECT IS
-- REFRESHED OR NOT
/*
WHILE SNAPSHOT_CNT_T=0

 LOOP

   SELECT COUNT(*) INTO SNAPSHOT_CNT_T FROM DW.PV_PROJECT;
   IF SNAPSHOT_CNT_T != 0 THEN
      EXIT;
   ELSE
     -- SLEEP FOR 2 MINUTES
      DBMS_LOCK.SLEEP(120);
   END IF;

  END LOOP; */

-- COMMENTED BY PANKAJ ON 12/14/02
-- GET LAST DATE OF THE PRIOR MONTH

/*SELECT TRUNC(LAST_DAY(ADD_MONTHS(SYSDATE,-1))) INTO TRANSACTION_DT_T
FROM DUAL;

-- GET FISCAL YEAR AND THE PRIOR MONTH'S ACCOUNTING PERIOD

FISCAL_YEAR_T :=ISS.DATE_TO_FISCAL_YEAR(TRANSACTION_DT_T);
ACCOUNTING_PERIOD_T :=ISS.PRIOR_ACCOUNTING_PERIOD;   */

-- GET THE VALUE OF TRANSACTION_DT_T FROM THE FINANCIALPERIODS TABLE
SELECT TRUNC(X.PERIODEND-1),TO_NUMBER(SUBSTR(X.FINANCIALPERIOD,1,4)),
TO_NUMBER(SUBSTR(X.FINANCIALPERIOD, 5,2))
INTO  TRANSACTION_DT_T, FISCAL_YEAR_T, ACCOUNTING_PERIOD_T
FROM   FINANCIALPERIODS X
WHERE  X.FINANCIALPERIOD=(SELECT MIN(Y.FINANCIALPERIOD) FROM FINANCIALPERIODS Y
WHERE  (NVL(Y.CLOSEDBY,' ') NOT LIKE '%SPA01%'));

-- NOW DELETE ALL THE RECORDS FROM THE TABLES WHERE RECHARGE INFORMATION
-- IS INSERTED. THIS WILL ENABLE TO REEXECUTE THE PROGRAM AGAIN IF WE
-- NEED To RESENT THE FEEDER TO FMs


DELETE FROM SPADM.SPACE_CHARGE_TRANS_DETAIL
WHERE  TRANSACTION_DT=TRANSACTION_DT_T
AND    FISCAL_YEAR=FISCAL_YEAR_T
AND    ACCOUNTING_PERIOD=ACCOUNTING_PERIOD_T;


DELETE FROM SPADM.SPACE_HISTORICAL_INFO
WHERE TRANSACTION_DT=TRANSACTION_DT_T;

DELETE FROM SPADM.SPACE_CHARGE_TRANS
WHERE  TRANS_DT=TRANSACTION_DT_T
AND    FISCAL_YEAR=FISCAL_YEAR_T
AND    ACCOUNTING_PERIOD=ACCOUNTING_PERIOD_T;

 -- START READING SPACE_ROOM TABLE


 FOR SPACE_ROOM_REC_T   IN SPACE_ROOM_CUR

  LOOP
   -- GET BUILDING INFORMATION

   SPADM.SPACE_PACKAGE.GET_BUILDING_DETAILS(SPACE_ROOM_REC_T.BUILDING_NUMBER,
                                            SPACE_BUILDING_REC_T);


    -- PROCESS ONLY IF BUILDING IS ACTIVE

    -- CHANGE FOR MXES
    IF SPACE_BUILDING_REC_T.INACTIVE != 1 THEN

    -- PROCESS ONLY IF ASSIGNMENT STATUS OF ROOM='Y' AND
    -- IT IS CHARGEABLE

    IF SPACE_ROOM_REC_T.ASSIGNMENT_STATUS='Y' AND
       SPACE_ROOM_REC_T.CHARGEABLE='Y'        AND
       SPACE_ROOM_REC_T.INACTIVE != 1    -- Added by Pankaj 01/31/00
    THEN

       -- ASSIGNMENT FOR FOLLOWING CURSOR

       BUILDING_NUMBER_T := LTRIM(RTRIM(SPACE_ROOM_REC_T.BUILDING_NUMBER));
       FLOOR_NUMBER_T    := LTRIM(RTRIM(SPACE_ROOM_REC_T.FLOOR_NUMBER));
       ROOM_NUMBER_T     := LTRIM(RTRIM(SPACE_ROOM_REC_T.ROOM_NUMBER));


       -- START READING SPACE_CHARGE_DISTRIBUTION TABLE FOR
       -- THE GIVEN BUILDING, FLOOR AND ROOM


        IF (SPACE_ROOM_REC_T.PROJ_ACT_ID IS NOT NULL)  THEN

         -- CHECK IF PROJECT IS VALID

         PROJECT_OVERRIDE_T :=NULL;
         DESCR_T :=NULL;
         DESCR_T :=SPADM.SPACE_PACKAGE.GET_PROJECT_NAME(SPACE_ROOM_REC_T.PROJ_ACT_ID);

         -- IF THE PROJECT IS NOT VALID
         IF DESCR_T IS NULL THEN

           PROJECT_OVERRIDE_T :='Y';

           -- GET DEFAULT PROJECT FOR DIVISION
           --PROJ_ACT_ID_T := SPADM.SPACE_PACKAGE.GET_DEFAULT_PROJECT(SPACE_ROOM_REC_T.ORG_LEVEL_1_CODE);
           --PROJ_ACT_ID_T := SPADM.SPACE_PACKAGE.GET_DEFAULT_PROJECT(SPACE_ROOM_REC_T.ORG_LEVEL_1_CODE);
           -- PANKAJ JUNE 25, 2015 -- DO NOT BRING DEFAULT PROJECT ID IF PROJ/ACT COMBO IS NOT VALID 
           PROJ_ACT_ID_T := SPACE_ROOM_REC_T.PROJ_ACT_ID; -- KEEP IT AS IT AS 
           
         ELSE

           PROJ_ACT_ID_T :=SPACE_ROOM_REC_T.PROJ_ACT_ID;
           PROJECT_OVERRIDE_T :='N';

         END IF;


         MONETARY_AMOUNT_T :=0;

         -- GET RECHARGE RATE FOR GIVEN REPORT_CATEGORY AND CURRENT USE

         RECHARGE_RATE_T :=0;
         RECHARGE_RATE_T :=SPACE_PACKAGE.GET_RECHARGE_RATE(SPACE_ROOM_REC_T.CURRENT_USE,
                                                          SPACE_BUILDING_REC_T.REPORT_CATEGORY);

         -- CALCULATE RECHARGE AMOUNT CONSIDERING THE OCCUPIED PERCENTAGE,
         -- RECHARGE RATE AND PERCENT DISTRIBUTION

         ADJ_AREA_T :=(SPACE_ROOM_REC_T.AREA * SPACE_ROOM_REC_T.OCCUPIED_PERCENT)/ 100;

         MONETARY_AMOUNT_T :=(ADJ_AREA_T * RECHARGE_RATE_T);
             MONETARY_AMOUNT_T :=(MONETARY_AMOUNT_T * SPACE_ROOM_REC_T.CHARGED_TO_PERCENT)/100;

         -- INSERT RECORD ONLY IF THE RECHARGE AMOUNT IS > 0

         --   Commented by Pankaj on 11/28/05
         --   IF MONETARY_AMOUNT_T > 0 THEN

           -- CHECK WHETHER RECORD ALREADY INSERTED

           PRV_MONETARY_AMOUNT_T :=0;
           SELECT NVL(SUM(MONETARY_AMOUNT),0) INTO PRV_MONETARY_AMOUNT_T
           FROM SPADM.SPACE_CHARGE_TRANS_DETAIL
           WHERE PROJ_ACT_ID=PROJ_ACT_ID_T
           AND BUILDING_NUMBER=SPACE_ROOM_REC_T.BUILDING_NUMBER
           AND FLOOR_NUMBER=SPACE_ROOM_REC_T.FLOOR_NUMBER
           AND ROOM_NUMBER=SPACE_ROOM_REC_T.ROOM_NUMBER
           AND ORG_LEVEL_1_CODE=SPACE_ROOM_REC_T.ORG_LEVEL_1_CODE
           AND FISCAL_YEAR=FISCAL_YEAR_T
           AND ACCOUNTING_PERIOD=ACCOUNTING_PERIOD_T;


           -- IF RECORD DOES NOT EXIST, THEN INSERT ELSE UPDATE AMOUNT

           --dbms_output.put_line('amt :' || to_char(PRV_MONETARY_AMOUNT_T));

           IF PRV_MONETARY_AMOUNT_T =0 THEN

             INSERT INTO SPADM.SPACE_CHARGE_TRANS_DETAIL (CHARGE_ID, TRANSACTION_DT,
             PROJ_ACT_ID, LOCATION, ORG_LEVEL_1_CODE, CHARGED_TO_PERCENT,
             BUILDING_NUMBER, FLOOR_NUMBER, ROOM_NUMBER,
             ACCOUNTING_PERIOD, FISCAL_YEAR,
             MONETARY_AMOUNT, PROJECT_OVERRIDE) VALUES (0,TRANSACTION_DT_T,
             PROJ_ACT_ID_T, SPACE_ROOM_REC_T.LOCATION, SPACE_ROOM_REC_T.ORG_LEVEL_1_CODE,
             SPACE_ROOM_REC_T.CHARGED_TO_PERCENT,
             SPACE_ROOM_REC_T.BUILDING_NUMBER, SPACE_ROOM_REC_T.FLOOR_NUMBER,
                 SPACE_ROOM_REC_T.ROOM_NUMBER, ACCOUNTING_PERIOD_T, FISCAL_YEAR_T,
             MONETARY_AMOUNT_T, PROJECT_OVERRIDE_T);

           ELSE

             UPDATE SPADM.SPACE_CHARGE_TRANS_DETAIL
             SET MONETARY_AMOUNT=(PRV_MONETARY_AMOUNT_T + MONETARY_AMOUNT_T)
             WHERE PROJ_ACT_ID=PROJ_ACT_ID_T
             AND BUILDING_NUMBER=SPACE_ROOM_REC_T.BUILDING_NUMBER
             AND FLOOR_NUMBER=SPACE_ROOM_REC_T.FLOOR_NUMBER
             AND ROOM_NUMBER=SPACE_ROOM_REC_T.ROOM_NUMBER
                 AND ORG_LEVEL_1_CODE=SPACE_ROOM_REC_T.ORG_LEVEL_1_CODE
                 AND FISCAL_YEAR=FISCAL_YEAR_T
             AND ACCOUNTING_PERIOD=ACCOUNTING_PERIOD_T;


         END IF;

       -- END IF;   -- MONETARY_AMOUNT > 0

       END IF; --  IF (SPACE_CHARGE_DISTR_REC_T.PROJECT_ID IS NOT NULL)  THEN


    END IF;   -- ASSIGNMENT STATUS='Y'

  END IF;  -- INACTIVE !='Y'


     -- TRANSFER THE ROOM INFORMATION INTO SPACE_HISTORICAL_INFO

     REC_COUNT_T2 :=0;

     
     SELECT COUNT(*) INTO REC_COUNT_T2
     FROM SPADM.SPACE_HISTORICAL_INFO
     WHERE TRANSACTION_DT=TRANSACTION_DT_T
     AND   LOCATION=SPACE_ROOM_REC_T.LOCATION;
     
     -- GET THE EXTRA INFORMATION ABOUT THE ROOM
     -- FROM ARCHIBUS
     -- JIRA EF-6544
     T_LBL_PI         :=NULL; 
     T_COUNT_EM       :=NULL;  
     T_CAP_EM         :=NULL;  
     T_LBL_COMMENTS   :=NULL;  
     
     BEGIN
       SELECT LBL_PI, COUNT_EM, CAP_EM, LBL_COMMENTS
       INTO   T_LBL_PI, T_COUNT_EM, T_CAP_EM, T_LBL_COMMENTS
       FROM  AFM.RM@ARCHIBUS23
       WHERE BL_ID=SPACE_ROOM_REC_T.BUILDING_NUMBER
       AND   FL_ID=SPACE_ROOM_REC_T.FLOOR_NUMBER
       AND   RM_ID=SPACE_ROOM_REC_T.ROOM_NUMBER;
    EXCEPTION WHEN OTHERS  THEN
      NULL;
    END;
    
            

     IF (REC_COUNT_T2= 0) THEN

      INSERT INTO SPADM.SPACE_HISTORICAL_INFO (TRANSACTION_DT, LOCATION,
                BUILDING_NUMBER, FLOOR_NUMBER, ROOM_NUMBER,
                LOCALITY, REPORT_CATEGORY, AREA,
                DESIGN_USE, CURRENT_USE, CURRENT_USE_DETAIL,
                CHARGEABLE, ASSIGNMENT_STATUS,
                ORG_LEVEL_1_CODE, ORG_LEVEL_2_CODE, ORG_LEVEL_3_CODE,
                ORG_LEVEL_4_CODE, OCCUPIED_PERCENT,
                INACTIVE,
                LBL_PI,COUNT_EM,CAP_EM,LBL_COMMENTS -- JIRA EF-6544                
                ) VALUES
                (TRANSACTION_DT_T, SPACE_ROOM_REC_T.LOCATION,
                 SPACE_ROOM_REC_T.BUILDING_NUMBER, SPACE_ROOM_REC_T.FLOOR_NUMBER,
                 SPACE_ROOM_REC_T.ROOM_NUMBER,
                 SPACE_BUILDING_REC_T.LOCALITY, SPACE_BUILDING_REC_T.REPORT_CATEGORY,
                 SPACE_ROOM_REC_T.AREA,
                 SPACE_ROOM_REC_T.DESIGN_USE, 
                 --SPACE_ROOM_REC_T.CURRENT_USE,
                 --SPACE_ROOM_REC_T.CURRENT_USE_DETAIL,
                 --CURRENT USE AND CURRENT USE DETAILS ARE REPLACED WITH 
                 -- ROOM CATEGORY AND ROOM TYPE
                 -- REVISED BY PANKAJ ON 10/17/15
                 SPACE_ROOM_REC_T.LBL_RMCAT,
                 SUBSTR(SPACE_ROOM_REC_T.LBL_RMTYPE,INSTR(SPACE_ROOM_REC_T.LBL_RMTYPE,'-')+1), 
                 SPACE_ROOM_REC_T.CHARGEABLE, SPACE_ROOM_REC_T.ASSIGNMENT_STATUS,
                 SPACE_ROOM_REC_T.ORG_LEVEL_1_CODE, SPACE_ROOM_REC_T.ORG_LEVEL_2_CODE,
                 SPACE_ROOM_REC_T.ORG_LEVEL_3_CODE, SPACE_ROOM_REC_T.ORG_LEVEL_4_CODE,
                 SPACE_ROOM_REC_T.OCCUPIED_PERCENT,
                 SPACE_ROOM_REC_T.INACTIVE,
                 T_LBL_PI,T_COUNT_EM,T_CAP_EM, T_LBL_COMMENTS   -- JIRA EF-6544
                 );
        END IF;

    END LOOP;


  -- START READING RECORDS FROM SPACE_CHARGE_TRANS_DETAIL SEQUENTIALLY AND
    -- INSERT DATA INTO SPACE_CHARGE_TRANS TABLE AND PREPARE ARRARY FOR
    -- SUBSEQUENT PROCESSING

    JOURNAL_LINE_T :=0;
    MATCHING_ROW := 1;


    FOR SPACE_CHARGE_TRANS_DTL_REC_T IN SPACE_CHARGE_TRANS_DTL_CUR

     LOOP

       SELECT SPACE_SEQ.NEXTVAL INTO  CHARGE_ID_T FROM DUAL;
       JOURNAL_LINE_T := JOURNAL_LINE_T + 1;


       RESOURCE_ID_T := 'SPA01' || LTRIM(RTRIM(TO_CHAR(FISCAL_YEAR_T,'9999'))) ||
       LTRIM(RTRIM(LPAD(TO_CHAR(ACCOUNTING_PERIOD_T),3,'0'))) ||
       LPAD(LTRIM(RTRIM(TO_CHAR(CHARGE_ID_T))),18,'0');

       -- CHANGED BY PANKAJ ON 05/09/03 AS PER THE REQUEST FROM RICH NOSEK
       LINEDESCR_T2 :='Space Recharge: ' || SPACE_CHARGE_TRANS_DTL_REC_T.ORG_LEVEL_1_CODE ||
                      ' (' ||to_char(TRANSACTION_DT_T,'MON-YYYY') || ')' ;

       INSERT INTO SPACE_CHARGE_TRANS
       (CHARGE_ID, BUSINESS_UNIT,
        --PROJECT_ID,
        ACTIVITY_ID, RESOURCE_ID,
        BUSINESS_UNIT_GL, JOURNAL_ID, JOURNAL_DATE, UNPOST_SEQ,
        JOURNAL_LINE, FISCAL_YEAR, ACCOUNTING_PERIOD, ACCOUNT,
        BUDGET_YEAR, BUS_UNIT_GL_FROM, CURRENCY_CD, LEDGER_GROUP,
        ANALYSIS_TYPE, RESOURCE_TYPE, RESOURCE_CATEGORY, TRANS_DT,
        ACCOUNTING_DT, JRNL_LN_REF, OPEN_ITEM_STATUS, LINE_DESCR,
        JRNL_LINE_STATUS, FOREIGN_AMOUNT, CUR_EXCHNG_RT, PROCESS_INSTANCE,
        PC_DISTRIB_STATUS, GL_DISTRIB_STATUS, RESOURCE_STATUS, DESCR,
        EMPL_RCD, APPL_JRNL_ID, PYMNT_CNT, DST_ACCT_TYPE, LINE_NBR,
        SCHED_NBR, DISTRIB_LINE_NUM, ITEM_LINE, ITEM_SEQ_NUM,
        DST_SEQ_NUM, SCUED_LINE_NO, DEMAND_LINE_NO, ORDER_INT_LINE_NO,
        LBNL_REF_01,LBNL_REF_02, LBNL_PO_AMT, RESOURCE_AMOUNT,
        PROJ_ACT_ID) VALUES

        (CHARGE_ID_T, 'LBNL',
         -- SPACE_CHARGE_TRANS_DTL_REC_T.PROJECT_ID,
         LPAD('0',15,'0'), RESOURCE_ID_T,
         'LBNL', 'SPA01     ',TRANSACTION_DT_T, 0,
         JOURNAL_LINE_T, FISCAL_YEAR_T, ACCOUNTING_PERIOD_T, '617000',
         FISCAL_YEAR_T, 'LBNL', 'USD', 'STANDARD',
         'ACT', 'RECHR','50000', TRANSACTION_DT_T,
         TRANSACTION_DT_T, 'SPA01', 'N', LINEDESCR_T2 ,
         '0', 0, 0, 0,
         'N','N','A','SPACE-RECHARGE',
         0, 'SPACE', 0,'DST',0,
         0, 0, 0, 0,
         0, 0, 0, 0,
         NVL(SPACE_CHARGE_TRANS_DTL_REC_T.ORG_LEVEL_1_CODE,' '), CHARGE_ID_T, 0, SPACE_CHARGE_TRANS_DTL_REC_T.RESOURCE_AMOUNT_T,
         SPACE_CHARGE_TRANS_DTL_REC_T.PROJ_ACT_ID);

         CHARGE_TABLE(MATCHING_ROW).CHARGE_ID  := CHARGE_ID_T;
         CHARGE_TABLE(MATCHING_ROW).PROJ_ACT_ID:= SPACE_CHARGE_TRANS_DTL_REC_T.PROJ_ACT_ID;
         CHARGE_TABLE(MATCHING_ROW).ORG_LEVEL_1_CODE :=SPACE_CHARGE_TRANS_DTL_REC_T.ORG_LEVEL_1_CODE;

         MATCHING_ROW := MATCHING_ROW + 1;

    END LOOP;

     -- SET MATCHING ROW CORRECTLY AS IT IS STARTED FROM ONE
     IF MATCHING_ROW > 1 THEN
        MATCHING_ROW := MATCHING_ROW - 1;
     END IF;


  -- NOW UPDATE "SPACE_CHARGE_TRANS_DETAIL" TABLE WITH THE CORRECT CHARGE_ID
  -- READ FROM ARRAY

   SEARCH_ROW :=1;

     WHILE (SEARCH_ROW <= MATCHING_ROW)
      LOOP
         CHARGE_ID_T   := CHARGE_TABLE(SEARCH_ROW).CHARGE_ID;
         PROJ_ACT_ID_T  := CHARGE_TABLE(SEARCH_ROW).PROJ_ACT_ID;
         ORG_LEVEL_1_CODE_T := CHARGE_TABLE(SEARCH_ROW).ORG_LEVEL_1_CODE;

         UPDATE SPACE_CHARGE_TRANS_DETAIL
         SET CHARGE_ID=CHARGE_ID_T
         WHERE PROJ_ACT_ID=PROJ_ACT_ID_T
         AND   ORG_LEVEL_1_CODE=ORG_LEVEL_1_CODE_T
         AND   ACCOUNTING_PERIOD=ACCOUNTING_PERIOD_T
         AND   FISCAL_YEAR=FISCAL_YEAR_T
         AND   CHARGE_ID=0;
         SEARCH_ROW := SEARCH_ROW + 1;
        END LOOP;

    -- CLEAR CHARGE_TABLE MEMORY TABLE TO RELEASE MEMORY
   IF (MATCHING_ROW > 0) THEN
       CHARGE_TABLE.DELETE;
   END IF;

--  START CREATING THE OFFSET ENTRIES

  FOR  SPACE_CHARGE_TRANS_OFF_REC IN  SPACE_CHARGE_TRANS_OFF_CUR

   LOOP
        -- NEGATE THE AMOUNT

        RESOURCE_AMOUNT_T := (SPACE_CHARGE_TRANS_OFF_REC.OFFSET_AMOUNT_T * -1);

        SELECT SPACE_SEQ.NEXTVAL INTO  CHARGE_ID_T FROM DUAL;
        JOURNAL_LINE_T := JOURNAL_LINE_T + 1;

        RESOURCE_ID_T := 'SPA01' || LTRIM(RTRIM(TO_CHAR(FISCAL_YEAR_T,'9999'))) ||
        LTRIM(RTRIM(LPAD(TO_CHAR(ACCOUNTING_PERIOD_T),3,'0'))) ||
        LPAD(LTRIM(RTRIM(TO_CHAR(CHARGE_ID_T))),18,'0');


        -- CHANGED BY PANKAJ ON 05/09/03 AS PER THE REQUEST FROM RICH NOSEK
        -- DESCR_T2 :='SPACE-RECHARGE: ' || SPACE_CHARGE_TRANS_OFF_REC.ORG_LEVEL_1_CODE;

       LINEDESCR_T2 :='Space Recharge: ' || SPACE_CHARGE_TRANS_OFF_REC.ORG_LEVEL_1_CODE ||
                      ' (' ||to_char(TRANSACTION_DT_T,'MON-YYYY') || ')' ;

       INSERT INTO SPACE_CHARGE_TRANS
       (CHARGE_ID, BUSINESS_UNIT, PROJECT_ID,
        ACTIVITY_ID, RESOURCE_ID,
        BUSINESS_UNIT_GL, JOURNAL_ID, JOURNAL_DATE, UNPOST_SEQ,
        JOURNAL_LINE, FISCAL_YEAR, ACCOUNTING_PERIOD, ACCOUNT,
        BUDGET_YEAR, BUS_UNIT_GL_FROM, CURRENCY_CD, LEDGER_GROUP,
        ANALYSIS_TYPE, RESOURCE_TYPE, RESOURCE_CATEGORY, TRANS_DT,
        ACCOUNTING_DT, JRNL_LN_REF, OPEN_ITEM_STATUS, LINE_DESCR,
        JRNL_LINE_STATUS, FOREIGN_AMOUNT, CUR_EXCHNG_RT, PROCESS_INSTANCE,
        PC_DISTRIB_STATUS, GL_DISTRIB_STATUS, RESOURCE_STATUS, DESCR,
        EMPL_RCD, APPL_JRNL_ID, PYMNT_CNT, DST_ACCT_TYPE, LINE_NBR,
        SCHED_NBR, DISTRIB_LINE_NUM, ITEM_LINE, ITEM_SEQ_NUM,
        DST_SEQ_NUM, SCUED_LINE_NO, DEMAND_LINE_NO, ORDER_INT_LINE_NO,
        LBNL_REF_01, LBNL_REF_02, LBNL_PO_AMT, RESOURCE_AMOUNT
        ) VALUES
        (CHARGE_ID_T, 'LBNL', '379999',
         LPAD('0',15,'0'), RESOURCE_ID_T,
         'LBNL', 'SPA01     ',TRANSACTION_DT_T, 0,
         JOURNAL_LINE_T, FISCAL_YEAR_T, ACCOUNTING_PERIOD_T, '618000',
         FISCAL_YEAR_T, 'LBNL', 'USD', 'STANDARD',
         'ACT', 'RECOV','50500', TRANSACTION_DT_T,
         TRANSACTION_DT_T, 'SPA01', 'N',LINEDESCR_T2,
         '0', 0, 0, 0,
         'N','N','A',LINEDESCR_T2,
         0, 'SPACE', 0,'DST',0,
         0, 0, 0, 0,
         0, 0, 0, 0,
         LPAD(' ',7,' '),CHARGE_ID_T, 0, RESOURCE_AMOUNT_T
         );

   END LOOP;

  END;

/


commit;
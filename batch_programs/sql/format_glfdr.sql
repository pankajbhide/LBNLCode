/************************************************************************
*
* PROGRAM NAME          : FORMAT_GLFDR.SQL
*
*
* DESCRIPTION           : THIS SCRIPT READS STORES FEEDER DATA FROM 
*                         BATCH_MAXIMO.LBL_PROJ_FEEDERS TABLE AND SPOOLS 
*                         THE CONTENTS TO THE PRE-FORMATTED DAT FILE
*                         
*                         ARGUMENTS
*                         1-ORGID, 2-SITEID, 3-PROJ TRANS TYPE, 
*                      
*
* AUTHOR                : PANKAJ BHIDE
*
* DATE WRITTEN          : 24-MAR-2014
*
* DATE MODIFIED         :
*
* MODIFICATION HISORTY  : 16-APR-2015 CHANGES FOR ASSET_TYPE JIRA=EF-967
* 
*                         30-JUN-2015 CHANGES FOR ASSET_STATUS JIRA-EF-967
*
*                         28-AUG-2015 CHANGES AS PER JIRA EF-1580, EF-1581
*
*                         09-NOV-2015 CHANGES AS PER JIRA EF-2088. 
*************************************************************************/
WHENEVER SQLERROR EXIT 1 ROLLBACK;

 
DECLARE

 T_FILEHANDLER  UTL_FILE.FILE_TYPE;
 T_FILEHANDLER1 UTL_FILE.FILE_TYPE;
 T_FILEHANDLER2 UTL_FILE.FILE_TYPE;
 T_FILENAME    VARCHAR2(50);
 T_FILENAME_CNT VARCHAR2(50);
 T_CONTENT     CHAR(419);  -- FIXED LENGTH 
 T_DRCR_SIGN  VARCHAR2(1);
 ROW_CNT_T   NUMBER(10) :=0;
 FILEROW_CNT_T   NUMBER(10) :=0; 
 ERROR_T     EXCEPTION;
 
 TOT_DR_AMT NUMBER(15,2) :=0;
 TOT_CR_AMT NUMBER(15,2) :=0;
 MESSAGE_T  VARCHAR2(1000);
 T_LINE     VARCHAR2(1000);
 AMOUNT_T   NUMBER(15,2) :=0;
 FISCAL_YEAR_T VARCHAR2(4);
 ACCOUNTING_PERIOD_T VARCHAR2(2);
 T_DEPT_CODE        BATCH_MAXIMO.LBL_PROJ_FEEDERS.DEPARTMENT_CODE%TYPE;
 T_FUND_CODE        BATCH_MAXIMO.LBL_PROJ_FEEDERS.FUND_CODE%TYPE;
 T_RESOURCE_TYPE     VARCHAR2(50);
 T_RESOURCE_CATEGORY VARCHAR2(50);
 T_ANALYSIS_TYPE     VARCHAR2(50);
 T_PROJ_BUS_UNIT     VARCHAR2(50);
-- T_ASSET_STATUS      VARCHAR2(2):='02'; -- FIXED VALULE SUPPLIED BY JANET L OCFO 
 T_ASSET_STATUS      VARCHAR2(2):='01'; -- FIXED VALULE SUPPLIED BY JANET L OCFO 
 T_JRNL_LINE_REF     VARCHAR2(10);
 T_SUM_COUNT         NUMBER(5) :=0;
 T_PC_BUSINESS_UNIT  VARCHAR2(50); -- JIRA 2088
 
 CURSOR PROJ_FEEDER_CUR IS
  SELECT * FROM   BATCH_MAXIMO.LBL_PROJ_FEEDERS A
  WHERE   A.ORGID='&1'
  AND     A.SITEID='&2'
  AND     A.FISCAL_YEAR=(SELECT TO_NUMBER(SUBSTR(X.FINANCIALPERIOD,1,4),'9999') 
                       FROM   FINANCIALPERIODS X
                       WHERE   X.FINANCIALPERIOD=(SELECT MIN(Y.FINANCIALPERIOD) 
                       FROM FINANCIALPERIODS Y
                       WHERE   NVL(Y.CLOSEDBY,' ')  NOT LIKE '%&3%') 
                       AND ORGID='&1')
  AND     A.ACCOUNTING_PERIOD=(SELECT TO_NUMBER(SUBSTR(X.FINANCIALPERIOD,5,2),'99') 
                             FROM  FINANCIALPERIODS X 
                             WHERE X.FINANCIALPERIOD=(SELECT MIN(Y.FINANCIALPERIOD) 
                             FROM FINANCIALPERIODS Y
                             WHERE   NVL(Y.CLOSEDBY,' ')  NOT LIKE '%&3%') 
                             AND ORGID='&1')
  AND     A.PROJ_TRANS_TYPE='&3'
  AND     A.ENTRY_TYPE LIKE 'GL%' 
  AND     A.LBL_PROJ_FEED1 IS NULL
  AND     A.INACTIVE=0
  ORDER BY A.RECORD_ID;
  
-- ADDED BY PANKAJ ON 8/28/15 JIRA EF-1580
  CURSOR SUMMARY_PROJ_FEEDER_CUR IS
  SELECT A.ACCOUNT, A.DR_CR, SUM(A.RESOURCE_AMOUNT) AS RESOURCE_AMOUNT
  FROM   BATCH_MAXIMO.LBL_PROJ_FEEDERS A
  WHERE   A.ORGID='&1'
  AND     A.SITEID='&2'
  AND     A.FISCAL_YEAR=(SELECT TO_NUMBER(SUBSTR(X.FINANCIALPERIOD,1,4),'9999') 
                       FROM   FINANCIALPERIODS X
                       WHERE   X.FINANCIALPERIOD=(SELECT MIN(Y.FINANCIALPERIOD) 
                       FROM FINANCIALPERIODS Y
                       WHERE   NVL(Y.CLOSEDBY,' ')  NOT LIKE '%&3%') 
                       AND ORGID='&1')
  AND     A.ACCOUNTING_PERIOD=(SELECT TO_NUMBER(SUBSTR(X.FINANCIALPERIOD,5,2),'99') 
                             FROM  FINANCIALPERIODS X 
                             WHERE X.FINANCIALPERIOD=(SELECT MIN(Y.FINANCIALPERIOD) 
                             FROM FINANCIALPERIODS Y
                             WHERE   NVL(Y.CLOSEDBY,' ')  NOT LIKE '%&3%') 
                             AND ORGID='&1')
  AND     A.PROJ_TRANS_TYPE='&3'
  AND     A.ENTRY_TYPE LIKE 'GL%' 
  AND     A.LBL_PROJ_FEED1 IS NULL
  AND     A.INACTIVE=0
  GROUP BY A.ACCOUNT, A.DR_CR
  ORDER BY DECODE(A.DR_CR,'DR',1,2);
  
  STR_FEEDER_DEF_T      BATCH_MAXIMO.LBL_STORES_FEED_DEFAULTS%ROWTYPE;
 
 BEGIN
 
   -- GET THE DETAILS ABOUT THE STORES FEEDER DEFAULTS 
   SELECT * INTO STR_FEEDER_DEF_T
   FROM BATCH_MAXIMO.LBL_STORES_FEED_DEFAULTS
   WHERE ORGID='&1'
   AND   SITEID='&2'; 
 
   T_FILENAME     :=LOWER('&3' || '.dat');
   T_FILENAME_CNT :=LOWER('&3' || '.datcnt');
   
   T_FILEHANDLER  :=UTL_FILE.FOPEN('MAXIMO', T_FILENAME, 'W');
   T_FILEHANDLER2 :=UTL_FILE.FOPEN('MAXIMO', T_FILENAME_CNT, 'W');
  
   
   FOR PROJ_FEEDER_REC IN PROJ_FEEDER_CUR
   
    LOOP
    
    ROW_CNT_T := ROW_CNT_T + 1;
    
    IF (PROJ_FEEDER_REC.DR_CR='DR') THEN
      T_DRCR_SIGN :=' ';
    ELSE
      T_DRCR_SIGN :='-';
    END IF;
    
      
    
    IF (ROW_CNT_T =1) THEN
    
      T_CONTENT :='H'                      || -- HEADER 
        RPAD('LBNL', 5,' ')      || -- BUSINESS UNIT
        --LPAD(TO_CHAR(PROJ_FEEDER_REC.JOURNAL_ID),10,'0') || -- JOURNAL ID
        RPAD('NEXT', 10,' ')      || -- JOURNAL ID AS PER JANET L 
        TO_CHAR(PROJ_FEEDER_REC.TRANS_DATE,'MMDDYYYY')   || -- JOURNAL DATE
        'N'                                || -- REGULAR ENTRY
        RPAD(' ',3,' ')                    || -- ADJUSTING PERIOD 3 SPACES
        TO_CHAR(PROJ_FEEDER_REC.TRANS_DATE,'MMDDYYYY')   || -- ADB AVG DAILY BAL DATE
        RPAD('ACTUALS', 10 ,' ')                 || -- LEDGER GROUP 
        RPAD('ACTUALS', 10 ,' ')                 || -- LEDGER 
        ' '                                || -- REVERSAL CODE
        RPAD(' ',8,' ')                    || -- REVERSAL DATE 8 SPACES
        RPAD(' ',3,' ')                    || -- REVERSAL ADJ PERIOD
        ' '                                || -- ADB REVERSAL CODE
        RPAD(' ',8,' ')                    || -- ADB REVERSAL DATE 8 SPACES
        'SIS'                              || -- JOURNAL SOURCE
        RPAD(' ',8,' ')                    || -- TRANS REF NUMBER 8 SPACES
        RPAD(PROJ_FEEDER_REC.LINE_DESCR, 30,' ')         || -- DESCRIPTION 
        'USD'                              || -- DEF CURRENCY CODE
        RPAD(' ',5,' ')                    || -- DEF CURRENCY RATE TYPE 
        RPAD(' ',8,' ')                    || -- CURRENCY EFF DATE
        RPAD(' ',17,' ')                   || -- DEF CURRENCY EXCHANGE RATE
        '   '                              || -- SYSTEM SOURCE
        RPAD(' ',8,' ')                    || -- DOC TYPE 
        RPAD(' ',12,' ')                   || -- DOC SEQ 
        RPAD(' ',1,' ')                    || -- BUDGET HEADER
        '1'                                || -- COMMITMENT CONTROL
        RPAD(' ',4,' ')                    || -- GLACCOUNT TYPE 
        RPAD(' ',10,' ');                     -- JOURNAL CLASS
        
        UTL_FILE.PUT_LINE(T_FILEHANDLER, T_CONTENT );
        
        FISCAL_YEAR_T := LTRIM(TO_CHAR(PROJ_FEEDER_REC.FISCAL_YEAR,'9999'));
        ACCOUNTING_PERIOD_T := LTRIM(TO_CHAR(PROJ_FEEDER_REC.ACCOUNTING_PERIOD,'99'));
        
     END IF ; -- ROW_CNT_T =1
     
        -- DERIVE REQUIRED INFORMATION IN CASE OF TRANSACTION
        -- RELATED TO PROJECT ID AND ACTIVITY ID  
        
        T_RESOURCE_TYPE :=' ';
        T_RESOURCE_CATEGORY :=' ';
        T_ANALYSIS_TYPE :=' ';
        T_PROJ_BUS_UNIT :='LBNL';
        T_FUND_CODE :=' ';
        T_DEPT_CODE :=' ';
        
        IF (PROJ_FEEDER_REC.ASSET_TYPE IS NOT NULL)  THEN 
           T_JRNL_LINE_REF :=T_ASSET_STATUS || PROJ_FEEDER_REC.ASSET_TYPE || 'XXXX ' ;
        ELSE
           T_JRNL_LINE_REF  := '          ';
        END IF;
                       
        IF (PROJ_FEEDER_REC.LBL_PROJECT_ID  IS NOT NULL  AND
            PROJ_FEEDER_REC.LBL_ACTIVITY_ID IS NOT NULL  )
         THEN 
           T_RESOURCE_TYPE :=STR_FEEDER_DEF_T.DEF_RESOURCE_TYPE;
           T_RESOURCE_CATEGORY :=STR_FEEDER_DEF_T.DEF_RESOURCE_CATEGORY;
           T_ANALYSIS_TYPE :=STR_FEEDER_DEF_T.ANALYSIS_TYPE;
           BEGIN
             SELECT  PRJ_LEVEL1_CF_VAL, PRJ_LEVEL2_CF_VAL, PRJ_LEVEL3_CF_VAL         
             INTO    T_PROJ_BUS_UNIT, T_FUND_CODE, T_DEPT_CODE            
             FROM    FMSADM.PS_PSA_ORGPRJ_ACT@FMS9 P           
             WHERE   P.PROJECT_ID=PROJ_FEEDER_REC.LBL_PROJECT_ID           
             AND     P.ACTIVITY_ID=PROJ_FEEDER_REC.LBL_ACTIVITY_ID         
             AND     P.EFFDT = (SELECT MAX(P_ED.EFFDT)            
             --AND     P.EFFDT <= (SELECT MAX(P_ED.EFFDT)            
                      FROM FMSADM.PS_PSA_ORGPRJ_ACT@FMS9 P_ED           
                      WHERE P_ED.BUSINESS_UNIT = P.BUSINESS_UNIT            
                      AND P_ED.PROJECT_ID = P.PROJECT_ID            
                      AND P_ED.ACTIVITY_ID = P.ACTIVITY_ID          
                      AND P_ED.EFFDT <= SYSDATE);     
            EXCEPTION WHEN OTHERS  THEN 
               NULL;
            END;      
           
        ELSE
           T_PROJ_BUS_UNIT :='LBNL'; -- DEFAULT 
           T_RESOURCE_TYPE :=' ';
           T_RESOURCE_CATEGORY :=' ';
           T_ANALYSIS_TYPE :=' ';
           T_PROJ_BUS_UNIT :=' ';
           T_FUND_CODE :=STR_FEEDER_DEF_T.DEF_FUND;
           T_DEPT_CODE :=STR_FEEDER_DEF_T.DEF_DEPARTMENT;               
        END IF;
        
        IF (TRIM(T_PROJ_BUS_UNIT) IS NULL) THEN
         T_PROJ_BUS_UNIT :='LBNL';
        END IF;
        
         -- JIRA EF-2088 
        IF (PROJ_FEEDER_REC.LBL_PROJECT_ID  IS NOT NULL AND
            PROJ_FEEDER_REC.LBL_ACTIVITY_ID IS NOT NULL) THEN
            
          T_PC_BUSINESS_UNIT :='LBNL';
        ELSE
          T_PC_BUSINESS_UNIT :='     ';
        END IF;
        
       T_CONTENT :='L'                      || -- HEADER 
        RPAD(T_PROJ_BUS_UNIT, 5,' ')      || -- BUSINESS UNIT JIRA EF-1581        
        LPAD(TO_CHAR(PROJ_FEEDER_REC.RECORD_ID),9,'0') ||-- JOURNAL LINE NUMBER
        RPAD('ACTUALS',10,' ')         || -- LEDGER 
        RPAD(PROJ_FEEDER_REC.ACCOUNT,10,' ')   || -- ACCOUNT 
        RPAD(' ',10,' ')         || -- ALT ACCOUNT 
        RPAD(T_DEPT_CODE,10,' ')      || -- DEPT 
        RPAD(' ',8,' ')           || -- OPERATING UNIT 
        RPAD(' ',6,' ')           || -- PRODUCT
        RPAD(T_FUND_CODE,5,' ')       || -- FUND CODE TBD
        RPAD(' ',5,' ')           || -- CLASS FLD TBD
        RPAD(' ',5,' ')           || -- PROG CODE TBD
        RPAD(' ',8,' ')           || -- BUDGET REF
        RPAD(' ',5,' ')           || -- AFFILIATE
        RPAD(' ',10,' ')           || -- FUND AFFILIATE 
        RPAD(' ',10,' ')           || -- OPER UNIT AFFILIATE
        RPAD(NVL(PROJ_FEEDER_REC.WONUM,' '),10,' ')           || -- CHARFLD 1
        RPAD(' ',10,' ')           || -- CHARFLD 2
        RPAD(' ',10,' ')           || -- CHARFLD 3
        RPAD(NVL(PROJ_FEEDER_REC.LBL_PROJECT_ID,' '),15,' ')           || -- PROJECT ID 
        RPAD(' ',4,' ')            || -- BOOK CODE
        RPAD(' ',8,' ')            || -- BUDGET PERIOD 
        RPAD(' ',10,' ')           || -- SCENARIO 
        RPAD(' ',3,' ')            || -- STAT CODE
        RPAD(' ',28,' ')           || -- BASE CURRENCY AMT 
        RPAD(' ',1,' ')            || -- MOVEMENT FLAG 
        RPAD(' ',17,' ')           || -- STAT AMOUNT 
        --RPAD(' ',10,' ')         || -- JRNL LINE REF 
        -- JIRA-967
        RPAD(T_JRNL_LINE_REF,10,' ')  ||
        RPAD(PROJ_FEEDER_REC.LINE_DESCR,30,' ')  || -- JRNL LINE DESCR
        'USD'                      || -- CURRENCY CODE
        RPAD(' ',5,' ')            ||  -- CURRENTCY RATE TYPE
        T_DRCR_SIGN                || -- SIGN 
        LPAD(TO_CHAR(PROJ_FEEDER_REC.RESOURCE_AMOUNT),27,'0') || -- AMOUNT 
        RPAD(' ',17,' ')            ||  -- CURRENTCY EXCHANGE RATE
        RPAD(T_PC_BUSINESS_UNIT,5,' ')          ||  -- JIRA EF-2088 
        RPAD(NVL(PROJ_FEEDER_REC.LBL_ACTIVITY_ID,' '),15,' ')          ||  -- PROJ ACTIVITY ID
        RPAD(T_ANALYSIS_TYPE,3,' ')             ||  -- PROJ ANALYSIS TYPE
        RPAD(T_RESOURCE_TYPE,5,' ')             ||  -- PROJ RES TYPE
        RPAD(T_RESOURCE_CATEGORY,5,' ')         ||  -- PROJ RES CATG
        RPAD(' ',5,' ')             ||  -- PROJ RES SUB CATEG
        RPAD(' ',8,' ')             ||  -- BUDGET DATE
        RPAD(' ',1,' ')             ||  -- BUDGET LINE STAT         
        RPAD(' ',10,' ')            ||  -- ENTRY EVENT 
        RPAD(' ',4,' ')             ||  -- INTERUNIT GROUP NO
        RPAD(' ',1,' ')             ||  -- INTERUNIT ANCHOR 
        RPAD(' ',30,' ');            --OPEN ITEM KEY 
        UTL_FILE.PUT_LINE(T_FILEHANDLER, T_CONTENT );
       
       /*
       IF (PROJ_FEEDER_REC.DR_CR='DR') THEN
        TOT_DR_AMT := TOT_DR_AMT + PROJ_FEEDER_REC.RESOURCE_AMOUNT;
       END IF;
         
       IF (PROJ_FEEDER_REC.DR_CR='CR') THEN
        TOT_CR_AMT := TOT_CR_AMT + PROJ_FEEDER_REC.RESOURCE_AMOUNT;
       END IF;
      */      
        
       
    END LOOP;
    
    UTL_FILE.FCLOSE(T_FILEHANDLER);
    
    -- CHECK NUMBER OF RECORDS AND TOTAL DEBIT AND CREDIT AMOUNTS
    -- IF TOTAL DEBIT IS NOT EQUAL TO TOTAL CREDIT THEN, RETURN
    -- WITH ERROR STATUS 
    
     T_FILEHANDLER1  :=UTL_FILE.FOPEN('MAXIMO', T_FILENAME, 'R');
     
     LOOP
     
     BEGIN 
     
      UTL_FILE.GET_LINE(T_FILEHANDLER1, T_LINE);
      
      IF (T_LINE IS NOT NULL) THEN      
        FILEROW_CNT_T := FILEROW_CNT_T + 1;
        
        IF (FILEROW_CNT_T  != 1) THEN -- SKIP FIRST HEADER ROW 
        
           AMOUNT_T := TO_NUMBER(SUBSTR(T_LINE,282,28));
                    
           
           IF (AMOUNT_T) > 0 THEN
            TOT_DR_AMT := TOT_DR_AMT + ABS(AMOUNT_T);
           END IF;
           
           IF (AMOUNT_T) < 0 THEN
            TOT_CR_AMT := TOT_CR_AMT + ABS(AMOUNT_T);
           END IF;
           
         END IF; --  IF (FILEROW_CNT_T  != 1)
            
        END IF; -- IF (T_LINE IS NOT NULL) THEN
                     
    EXCEPTION
    
     WHEN UTL_FILE.INVALID_PATH THEN
       DBMS_OUTPUT.PUT_LINE('FILE LOCATION IS INVALID');
     WHEN NO_DATA_FOUND THEN /*EOF REACHED*/
        UTL_FILE.FCLOSE(T_FILEHANDLER1); /* CLOSE THE FILE TYPE*/
     EXIT;
    
    END;   
   
    END LOOP;
    
    IF (TOT_DR_AMT != TOT_CR_AMT) THEN
     RAISE ERROR_T;
    END IF;
    
    -- ADDED BY PANKAJ ON 8/28/15 JIRA-1580 
    FOR SUMMARY_PROJ_FEEDER_REC IN SUMMARY_PROJ_FEEDER_CUR
    
     LOOP
  
       T_SUM_COUNT := T_SUM_COUNT + 1;
       
       IF (T_SUM_COUNT =1) THEN 
              
        -- WRITE TO COUNT FILE 
        UTL_FILE.PUT_LINE(T_FILEHANDLER2,'');      
        
        MESSAGE_T := 'GENERAL LEDGER FEEDER : ' || '&3' ;
        UTL_FILE.PUT_LINE(T_FILEHANDLER2,MESSAGE_T);
        MESSAGE_T := '*************************************';
        UTL_FILE.PUT_LINE(T_FILEHANDLER2,MESSAGE_T);
                
        UTL_FILE.PUT_LINE(T_FILEHANDLER2,'');
        MESSAGE_T :='FISCAL YEAR: ' || 
                     FISCAL_YEAR_T || ' ACCOUNTING PERIOD: ' || 
                     ACCOUNTING_PERIOD_T; 
        UTL_FILE.PUT_LINE(T_FILEHANDLER2,MESSAGE_T);
        MESSAGE_T := '------------------------------------------------------';
        UTL_FILE.PUT_LINE(T_FILEHANDLER2,MESSAGE_T);   
        UTL_FILE.PUT_LINE(T_FILEHANDLER2,'');
        UTL_FILE.PUT_LINE(T_FILEHANDLER2,'');
        
        MESSAGE_T := 'GLACCOUNT: ' || SUMMARY_PROJ_FEEDER_REC.ACCOUNT || '   ' ||
                     'DR/CR: '     || SUMMARY_PROJ_FEEDER_REC.DR_CR   || '   ' ||
                     'AMOUNT: '    || TO_CHAR(SUMMARY_PROJ_FEEDER_REC.RESOURCE_AMOUNT,'99999999.99');
        UTL_FILE.PUT_LINE(T_FILEHANDLER2,MESSAGE_T);                        
                
      ELSE
        
        MESSAGE_T := 'GLACCOUNT: ' || SUMMARY_PROJ_FEEDER_REC.ACCOUNT || '   ' ||
                     'DR/CR: '     || SUMMARY_PROJ_FEEDER_REC.DR_CR   || '   ' ||
                     'AMOUNT: '    || TO_CHAR(SUMMARY_PROJ_FEEDER_REC.RESOURCE_AMOUNT,'99999999.99');
        UTL_FILE.PUT_LINE(T_FILEHANDLER2,MESSAGE_T);                        
        
     END IF;
    
      END LOOP;
      
    UTL_FILE.PUT_LINE(T_FILEHANDLER2,'');       
    UTL_FILE.PUT_LINE(T_FILEHANDLER2,'');  
    MESSAGE_T := 'TOTAL NUMBER OF RECORDS: ' || LTRIM(TO_CHAR(FILEROW_CNT_T-1,'999999'));
    UTL_FILE.PUT_LINE(T_FILEHANDLER2,MESSAGE_T);
   
    UTL_FILE.PUT_LINE(T_FILEHANDLER2,'');
    UTL_FILE.PUT_LINE(T_FILEHANDLER2,'');
    
    MESSAGE_T := 'TOTAL DEBIT AMOUNT: ' || LTRIM(TO_CHAR(TOT_DR_AMT,'999999999.99'));
    UTL_FILE.PUT_LINE(T_FILEHANDLER2,MESSAGE_T);
   
    UTL_FILE.PUT_LINE(T_FILEHANDLER2,'');
    UTL_FILE.PUT_LINE(T_FILEHANDLER2,'');

    MESSAGE_T := 'TOTAL CREDIT AMOUNT: ' || LTRIM(TO_CHAR(TOT_CR_AMT,'999999999.99'));
    UTL_FILE.PUT_LINE(T_FILEHANDLER2,MESSAGE_T);
   
    UTL_FILE.PUT_LINE(T_FILEHANDLER2,'');
    UTL_FILE.PUT_LINE(T_FILEHANDLER2,'');
    
    MESSAGE_T :='GL FEEDER GENERATED ON: ' ||
                 TO_CHAR(SYSDATE,'MM/DD/YYYY HH24:MI');
                 
    UTL_FILE.PUT_LINE(T_FILEHANDLER2,MESSAGE_T);                  
    UTL_FILE.PUT_LINE(T_FILEHANDLER2,'');
    UTL_FILE.PUT_LINE(T_FILEHANDLER2,'');


    UTL_FILE.FCLOSE(T_FILEHANDLER2); 
      
    
EXCEPTION
  WHEN UTL_FILE.INVALID_PATH THEN
     RAISE_APPLICATION_ERROR(-20000, 'ERROR: INVALID PATH FOR FILE.');
END;
/


/************************************************************************
*
* PROGRAM NAME          : FORMAT_PROJFDR.SQL
*
*
* DESCRIPTION           : THIS SCRIPT READS STORES FEEDER DATA FROM 
*                         BATCH_MAXIMO.LBL_PROJ_FEEDERS TABLE AND SPOOLS 
*                         THE CONTENTS TO THE PRE-FORMATTED CSV FILE
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
* MODIFICATION HISORTY  : 28-AUG-2015 CHANGES AS PER JIRA EF-1580
*************************************************************************/
WHENEVER SQLERROR EXIT 1 ROLLBACK;
 
DECLARE

 T_FILEHANDLER UTL_FILE.FILE_TYPE;
 T_FILEHANDLER2 UTL_FILE.FILE_TYPE;
 T_FILEHANDLER1 UTL_FILE.FILE_TYPE;
 T_FILENAME    VARCHAR2(50);
 T_FILENAME_CNT VARCHAR2(50);
 T_CONTENT     VARCHAR2(1000);
 ROW_CNT_T NUMBER(10) :=0;
 TOT_DR_AMT NUMBER(15,2) :=0;
 TOT_CR_AMT NUMBER(15,2) :=0;
 MESSAGE_T  VARCHAR2(1000);
 T_LINE     VARCHAR2(1000);
 RESOURCE_AMT_T VARCHAR2(1000);
 ERROR_T    EXCEPTION;
 FISCAL_YEAR_T VARCHAR2(4);
 ACCOUNTING_PERIOD_T VARCHAR2(2);
 DRCR_T VARCHAR2(2);
 AMOUNT_T  NUMBER(15,2) :=0;
 T_SUM_COUNT         NUMBER(5) :=0; 
 
  A_SEPARATOR VARCHAR2(1) := ',';
  A_FROM      PLS_INTEGER;
  A_TILL      PLS_INTEGER;
  A_FIELD_NO  PLS_INTEGER;
  A_BUFFER    VARCHAR2(32767);
  A_N_FIELDS  PLS_INTEGER;
  A_FIELD     VARCHAR2(4000);
 

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
  AND     A.ENTRY_TYPE LIKE 'PROJ%' 
  AND     A.LBL_PROJ_FEED1 IS NULL
  AND     A.INACTIVE=0
  ORDER BY A.RECORD_ID;


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
  AND     A.ENTRY_TYPE LIKE 'PROJ%' 
  AND     A.LBL_PROJ_FEED1 IS NULL
  AND     A.INACTIVE=0
  GROUP BY A.ACCOUNT, A.DR_CR
  ORDER BY DECODE(A.DR_CR,'DR',1,2);


 
 BEGIN
 
   T_FILENAME     :=LOWER('&3' || '.CSV');
   T_FILENAME_CNT :=LOWER('&3' || '.CNT');
   
   T_FILEHANDLER  :=UTL_FILE.FOPEN('MAXIMO', T_FILENAME, 'W');
   T_FILEHANDLER2 :=UTL_FILE.FOPEN('MAXIMO', T_FILENAME_CNT, 'W');
   
   FOR PROJ_FEEDER_REC IN PROJ_FEEDER_CUR
   
    LOOP
    
    ROW_CNT_T := ROW_CNT_T + 1;
    
     IF ( PROJ_FEEDER_REC.DR_CR='DR') THEN
       RESOURCE_AMT_T :=  LTRIM(TO_CHAR(ABS(PROJ_FEEDER_REC.RESOURCE_AMOUNT),'999999999.99'));
     ELSE
       RESOURCE_AMT_T :=  LTRIM(TO_CHAR((ABS(PROJ_FEEDER_REC.RESOURCE_AMOUNT)*-1),'999999999.99'));
     END IF;
     
    T_CONTENT :=RTRIM(PROJ_FEEDER_REC.RECORD_ID       ||','|| --1
       PROJ_FEEDER_REC.LBL_PROJECT_ID                 ||','|| --2
       PROJ_FEEDER_REC.LBL_ACTIVITY_ID                ||','|| --3
       PROJ_FEEDER_REC.ACCOUNT                        ||','|| --4
       PROJ_FEEDER_REC.WONUM                          ||','|| --5    
       PROJ_FEEDER_REC.RESOURCE_TYPE                  ||','|| --6
       PROJ_FEEDER_REC.RESOURCE_CATEGORY              ||','|| --7
       TO_CHAR(PROJ_FEEDER_REC.TRANS_DATE,'MM/DD/YYYY') ||','|| --8
       PROJ_FEEDER_REC.LINE_DESCR                     ||','||   --9
       PROJ_FEEDER_REC.PROJ_TRANS_TYPE                ||','||   --10
       PROJ_FEEDER_REC.DR_CR                          ||','||   --11
       '1'                                            ||','||   --12
       PROJ_FEEDER_REC.UNIT_OF_MEASURE                ||','||   --13
       RESOURCE_AMT_T        ||','|| --14
       TRIM(PROJ_FEEDER_REC.ANALYSIS_TYPE) );    
    
       UTL_FILE.PUT_LINE(T_FILEHANDLER, T_CONTENT );
       
       /*
       
       IF (PROJ_FEEDER_REC.DR_CR='DR') THEN
        TOT_DR_AMT := TOT_DR_AMT + PROJ_FEEDER_REC.RESOURCE_AMOUNT;
       END IF;
         
       IF (PROJ_FEEDER_REC.DR_CR='CR') THEN
        TOT_CR_AMT := TOT_CR_AMT + PROJ_FEEDER_REC.RESOURCE_AMOUNT;
       END IF;
       */
       
       IF (ROW_CNT_T=1) THEN
        FISCAL_YEAR_T := LTRIM(TO_CHAR(PROJ_FEEDER_REC.FISCAL_YEAR,'9999'));
        ACCOUNTING_PERIOD_T := LTRIM(TO_CHAR(PROJ_FEEDER_REC.ACCOUNTING_PERIOD,'99'));
       END IF;
        
       
    END LOOP;
    
    UTL_FILE.FCLOSE(T_FILEHANDLER);
    
    -- CHECK NUMBER OF RECORDS AND TOTAL DEBIT AND CREDIT AMOUNTS
    -- IF TOTAL DEBIT IS NOT EQUAL TO TOTAL CREDIT THEN, RETURN
    -- WITH ERROR STATUS 
    
     T_FILEHANDLER1  :=UTL_FILE.FOPEN('MAXIMO', T_FILENAME, 'R');
     ROW_CNT_T := 0;
     
     LOOP
     
     BEGIN 
     
      UTL_FILE.GET_LINE(T_FILEHANDLER1, T_LINE);
      dbms_output.put_line(t_line);
      IF (T_LINE IS NOT NULL) THEN      
         A_BUFFER := A_SEPARATOR || T_LINE || A_SEPARATOR;
         A_FIELD_NO := 1;
         A_N_FIELDS := LENGTH(A_BUFFER) - LENGTH(REPLACE(A_BUFFER,A_SEPARATOR,'')) - 1;
         A_FROM := 1;
         
      WHILE (A_FIELD_NO <= A_N_FIELDS )
      
       LOOP
         A_TILL := INSTR(A_BUFFER,A_SEPARATOR,1,A_FIELD_NO + 1);
         A_FIELD := SUBSTR(A_BUFFER,A_FROM + 1,A_TILL - A_FROM - 1);
         A_FROM := A_TILL;
         
        CASE A_FIELD_NO 
         WHEN 11 THEN DRCR_T:= A_FIELD;
         WHEN 14 THEN AMOUNT_T := TO_NUMBER(A_FIELD);               
         ELSE NULL;
        END CASE;
        
        A_FIELD_NO := A_FIELD_NO + 1;
        
       END LOOP;
      
      IF (DRCR_T='DR')  THEN
           TOT_DR_AMT := TOT_DR_AMT + ABS(AMOUNT_T);
      END IF;
          
      IF (DRCR_T ='CR') THEN
           TOT_CR_AMT := TOT_CR_AMT + ABS(AMOUNT_T);
      END IF;
      
      ROW_CNT_T := ROW_CNT_T + 1;
      
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
        
        
        MESSAGE_T := 'Project Feeder : ' || '&3' ;
        UTL_FILE.PUT_LINE(T_FILEHANDLER2,MESSAGE_T);
        MESSAGE_T := '**********************************';
        UTL_FILE.PUT_LINE(T_FILEHANDLER2,MESSAGE_T);
        
        
        UTL_FILE.PUT_LINE(T_FILEHANDLER2,'');
        MESSAGE_T :='Fiscal year: ' || 
                     FISCAL_YEAR_T || ' Accounting Period: ' || 
                     ACCOUNTING_PERIOD_T; 
        UTL_FILE.PUT_LINE(T_FILEHANDLER2,MESSAGE_T);
        MESSAGE_T := '------------------------------------------------------';
        UTL_FILE.PUT_LINE(T_FILEHANDLER2,MESSAGE_T);   
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
        MESSAGE_T := 'Total number of records: ' || LTRIM(TO_CHAR(ROW_CNT_T,'999999'));
        UTL_FILE.PUT_LINE(T_FILEHANDLER2,MESSAGE_T);
       
        UTL_FILE.PUT_LINE(T_FILEHANDLER2,'');
        UTL_FILE.PUT_LINE(T_FILEHANDLER2,'');
        
        MESSAGE_T := 'Total Debit Amount: ' || LTRIM(TO_CHAR(TOT_DR_AMT,'999999999.99'));
        UTL_FILE.PUT_LINE(T_FILEHANDLER2,MESSAGE_T);
       
        UTL_FILE.PUT_LINE(T_FILEHANDLER2,'');
        UTL_FILE.PUT_LINE(T_FILEHANDLER2,'');

        MESSAGE_T := 'Total Credit Amount: ' || LTRIM(TO_CHAR(TOT_CR_AMT,'999999999.99'));
        UTL_FILE.PUT_LINE(T_FILEHANDLER2,MESSAGE_T);
       
        UTL_FILE.PUT_LINE(T_FILEHANDLER2,'');
        UTL_FILE.PUT_LINE(T_FILEHANDLER2,'');
        
        MESSAGE_T :='Project Feeder generated on: ' ||
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


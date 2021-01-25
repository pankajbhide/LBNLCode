/***************************************************************************
 NAME                   : IMPACTCOST_MTH.SQL

 DATE WRITTEN           : 24-APRIL-2006

 AUTHOR                 : PANKAJ BHIDE 

 PURPOSE                : THIS PROGRAM BRINGS THE $ COSTS (LABOR + OTHER) SPENT 
                          ON THE WORK ORDERS FROM DATA WAREHOUSE. IT REMOVES ALL
                          THE PRELIMINARY RECORDS FROM THE EXISTING TRANSACTION
                          TABLES.     
                          
                          THIS PROGRAM WILL BE SCHEDULED TO EXECUTE ON 5TH OF 
                          EVERY MONTH (EXCEPT IN OCT - IT IS EXECUTED AFTER THE 
                          LEDGER FOR SEPT IS HARDCLOSED).
 
 MODIFICATION HISTORY   : 18-AUG-06 PANKAJ - IF THE TRANSACTION DATE IS NULL,
                          THEN PASS THE VALUE OF DTTM_STAMP.
                          
                          07-APR-2009 PANKAJ - CHANGES FOR MXES 
                          
                          11-MAR-2010 PANKAJ - ITEM SETID=ILBNL
                          
                          20-MAY-2010 PANKAJ - CHANGED THE WAY TO DETECT EMPLOYEE 
                          RELATED RECORD, REMOVED PS_PROJECT 
                          
                          Modified the program due to the changes of the GL Account
                          using combination of Project ID and Activity ID 
                          by Annette Leung 1/7/14
                          
                          Modified the program due to MAXIMO 7.6 upgrade 2/2015
                          by Annette Leung.
                          
                          create  view lbl_v_wo_2014_2016 as 
                          select wonum from workorder
                          where orgid='LBNL' and siteid='FAC' and
                          lbl_maximo_pkg.GET_FRST_APPR_DATE('LBNL','FAC',wonum) >= to_date('01-OCT-13','DD-MON-YY');
*******************************************************************************/

--WHENEVER SQLERROR EXIT 1 ROLLBACK;

DECLARE

     FROM_ACCOUNTING_PERIOD_T      VARCHAR2(2);
     TO_ACCOUNTING_PERIOD_T        VARCHAR2(2);
     FROM_FISCAL_YEAR_T            VARCHAR2(4);
     COPIED_FISCAL_YEAR_T          VARCHAR2(4) :=NULL;
     COPIED_ACCOUNTING_PERIOD_T    VARCHAR2(2) :=NULL;
     TO_FISCAL_YEAR_T              VARCHAR2(4);
     APPROVAL_DATE_T    WORKORDER.CHANGEDATE%TYPE;
     STARTUP_DATE_T     WORKORDER.CHANGEDATE%TYPE;
     REC_COUNT_T        NUMBER(12) :=0;
     PRV_WONUM          WORKORDER.WONUM%TYPE;
     PRV_SITEID         WORKORDER.SITEID%TYPE;
     PRV_ORGID          WORKORDER.ORGID%TYPE;
     NEW_LABCOST_T      WORKORDER.ACTLABCOST%TYPE :=0;
     NEW_LABHRS_T       WORKORDER.ACTLABHRS%TYPE  :=0;
     NEW_TOOLCOST_T     WORKORDER.ACTTOOLCOST%TYPE :=0;
     LABTRANSID_T       LABTRANS.LABTRANSID%TYPE;
     CRAFT_T            LABTRANS.CRAFT%TYPE;
     PAYRATE_T          LABTRANS.PAYRATE%TYPE;        
     FINANCIALPERIOD_T  LABTRANS.FINANCIALPERIOD%TYPE;
     RESULT_T           VARCHAR2(30);
     TOOLNUM_T          ITEM.ITEMNUM%TYPE;
     TOOL_DESCRIPTION_T ITEM.DESCRIPTION%TYPE;
     REC_FOUND_T1       NUMBER(9) :=0;
     REC_FOUND_T2       NUMBER(9) :=0;
     MEMO_T             LABTRANS.MEMO%TYPE;
     ORGID_T            LABTRANS.ORGID%TYPE;
     SITEID_T           LABTRANS.SITEID%TYPE;
     
     JOURNAL_ID_T       WORKORDER.DESCRIPTION%type;
     CHANGEBY_T         WORKORDER.CHANGEBY%TYPE;
     
     LABOR_RES_TYPE_T   WORKORDER.DESCRIPTION%type;
     
     
 CURSOR INPUT_RECORDS_CUR IS
     SELECT A.WONUM, A.ORGID, A.SITEID, A.ASSETNUM, A.GLACCOUNT, A.LOCATION, 
            A.SUPERVISOR, A.ACTLABCOST, A. ACTTOOLCOST, A.ACTLABHRS, A.ISTASK,
                B.EMPLID, 
            NVL(B.TRANS_DT, TRUNC(B.DTTM_STAMP)) TRANS_DT, -- ADDED BY PANKAJ 08/18/06
            B.ACCOUNTING_PERIOD, B.RESOURCE_TYPE,
            B.FISCAL_YEAR, B.RESOURCE_QUANTITY, 
            NVL(B.RESOURCE_AMOUNT,0) RESOURCE_AMOUNT,
            B.RESOURCE_CATEGORY
     FROM PS_ZMX_PRJ_RES_VW B, WORKORDER A 
     WHERE  A.ORGID = ORGID_T
     and A.SITEID = SITEID_T
     and A.ORGID = B.BUSINESS_UNIT
     and A.WONUM = B.CHARTFIELD1
     and A.SUPERVISOR is not null  
     and A.GLACCOUNT is not null
     and A.LOCATION is not null
     and B.BUSINESS_UNIT = ORGID_T
     --and B.ANALYSIS_Type = 'ACT' 
     and (B.FISCAL_YEAR between FROM_FISCAL_YEAR_T  and TO_FISCAL_YEAR_T)
     and (B.ACCOUNTING_PERIOD between FROM_ACCOUNTING_PERIOD_T  and TO_ACCOUNTING_PERIOD_T)    
     and B.PROJ_TRANS_TYPE != JOURNAL_ID_T  
     ORDER BY A.WONUM, B.RESOURCE_CATEGORY, B.EMPLID, B.TRANS_DT;
    
    CURSOR TOOL_CUR IS 
     SELECT DESCRIPTION FROM ITEM WHERE ITEMNUM=TOOLNUM_T AND ITEMTYPE='TOOL'; -- MXES 
    --  SELECT DESCRIPTION FROM TOOL WHERE ORGID=ORGID_T AND TOOLNUM=TOOLNUM_T;
    
    -- CURSOR TO GET THE RESOURCE CATEGORY DESCRIPTION FROM DATA WAREHOUSE 
    CURSOR RESOURCE_CATEGORY_CUR IS
      SELECT SUBSTR(RESCAT_DS,1,50) RESCAT_DS -- ITEM.DESCRIPTION=VARCHAR2(50)
      FROM   lbl_resource_category_cur
      WHERE  RESCAT_CD=SUBSTR(TOOLNUM_T,2);  -- TOOLNUM STARTS WITH R 
              
    -- CURSOR TO GET ALL LEFTOVER PREILMINARY LABTRANS RECORDS
    -- WHICH COULD NOT BE REPLACED FROM PS_PROJ_RESOURCE RECORDS
    
    CURSOR LABTRANS_LEFTOUT_CUR IS
      SELECT SUM(LINECOST) LEFT_ACTLABCOST, SUM(REGULARHRS+
                                            NVL(PREMIUMPAYHOURS,0)) LEFT_ACTLABHRS, -- MXES 
             REFWO
      FROM  MAXIMO.LABTRANS
      WHERE ORGID=ORGID_T    -- MXES 
      AND   SITEID=SITEID_T  -- MXES 
      AND   LT1='W'
      AND   MEMO LIKE 'PRELIMINARY%'
      GROUP BY REFWO;
    
    -- CURSOR TO GET ALL LEFTOVER PREILMINARY TOOLTRANS RECORDS
    -- WHICH COULD NOT BE REPLACED FROM PS_PROJ_RESOURCE RECORDS  
    
    CURSOR TOOLTRANS_LEFTOUT_CUR IS
      SELECT SUM(LINECOST) LEFT_ACTTOOLCOST, REFWO
      FROM  MAXIMO.TOOLTRANS
      WHERE ORGID=ORGID_T    -- MXES 
      AND   SITEID=SITEID_T  -- MXES  
      AND   TT1='W'
      AND   MEMO LIKE 'PRELIMINARY%'
    
      GROUP BY REFWO;      
      
 -- ADDED BY PANKAJ JIRA EF-4010      
      
 FUNCTION GET_LABOR_RESTYPE RETURN VARCHAR2
 
 IS
   CURSOR LOV_CUR IS
     SELECT VARVALUE
        FROM LBL_MAXVARS 
        WHERE VARNAME='RES_TYPE_LABOR'
        AND   ORGID=ORGID_T
        AND   SITEID=SITEID_T;
     

      
     LABRES_STRING_O  VARCHAR2(2000) := NULL;
     RESULT_STR_T     VARCHAR2(2000) := NULL;
  BEGIN

    FOR LOV_VALUE IN LOV_CUR
    
    LOOP
        IF RESULT_STR_T IS NOT NULL THEN
           RESULT_STR_T := RESULT_STR_T ||  '|'  || LOV_VALUE.VARVALUE;
        ELSE
           RESULT_STR_T := LOV_VALUE.VARVALUE;
        END IF;
    END LOOP;

        LABRES_STRING_O :='|' || LTRIM(RTRIM(RESULT_STR_T)) || '|';
        
    RETURN LABRES_STRING_O ;
  END; -- END OF FUNCTION 
  
          
     /*****************************************************************
      PROCEDURE TO DELETE WEEKLY PRELIMINARY RECORDS FROM TRANSACTION 
      TABLES
     *****************************************************************/
     PROCEDURE BEFORE_WONUM(WONUM_I       IN WORKORDER.WONUM%TYPE,
                            ORGID_I       IN WORKORDER.ORGID%TYPE, -- MXES 
                            SITEID_I      IN WORKORDER.SITEID%TYPE)                                 
       IS 
       
       BEGIN 
            DELETE  FROM MAXIMO.LABTRANS 
            WHERE  ORGID=ORGID_I
            AND    SITEID=SITEID_I
            AND    REFWO=WONUM_I
            AND    LT1='W'
            AND    MEMO LIKE 'PRELIMINARY%';
               
            DELETE FROM MAXIMO.TOOLTRANS
            WHERE  ORGID=ORGID_I
            AND    SITEID=SITEID_I
            AND    REFWO=WONUM_I
            AND    TT1='W'
            AND    MEMO LIKE 'PRELIMINARY%'; 
         
    END ;  -- PROCEDURE BEFORE_WONUM
    
     /*****************************************************************
      PROCEDURE TO UPDATE WORKORDER TABLE WITH THE NEW ACTUAL COSTS 
     *****************************************************************/
     PROCEDURE AFTER_WONUM(WONUM_I           IN WORKORDER.WONUM%TYPE,
                           ORGID_I           IN WORKORDER.ORGID%TYPE,
                           SITEID_I          IN WORKORDER.SITEID%TYPE)
                           
    IS
     NEW_LABCOST_T1      WORKORDER.ACTLABCOST%TYPE :=0;
     NEW_LABHRS_T1       WORKORDER.ACTLABHRS%TYPE  :=0;
     NEW_TOOLCOST_T1     WORKORDER.ACTTOOLCOST%TYPE :=0;
     BEGIN
     
        SELECT SUM(LINECOST), 
        SUM(NVL(REGULARHRS,0)+NVL(PREMIUMPAYHOURS,0)) 
        INTO   NEW_LABCOST_T1, NEW_LABHRS_T1
        FROM   LABTRANS
        WHERE  ORGID=ORGID_I
        AND    SITEID=SITEID_I
        AND    REFWO=WONUM_I
        AND    LT1='M'
        AND    MEMO LIKE 'FINAL%';
        
        
        SELECT SUM(LINECOST) 
        INTO   NEW_TOOLCOST_T1
        FROM   TOOLTRANS
        WHERE  ORGID=ORGID_I
        AND    SITEID=SITEID_I
        AND    REFWO=WONUM_I
        AND    TT1='M'
        AND    MEMO LIKE 'FINAL%';                 
                     
     
        UPDATE MAXIMO.WORKORDER 
        SET ACTLABCOST =NVL(NEW_LABCOST_T1,0),
            ACTLABHRS  =NVL(NEW_LABHRS_T1,0),
            ACTTOOLCOST=NVL(NEW_TOOLCOST_T1,0),
            LASTCOPYLINKDATE = sysdate,
            CHANGEBY = CHANGEBY_T,
            ACTINTLABHRS = NVL(NEW_LABHRS_T1,0),
            ACTINTLABCOST = NVL(NEW_LABCOST_T1,0)
            --CHANGEDATE = sysdate
        WHERE ORGID=ORGID_I
        AND   SITEID=SITEID_I
        AND   WONUM= WONUM_I;
    END;
    
  /* INSERT A NEW TOOL IN TOOL */ 
   FUNCTION INSERT_TOOL(ORGID_I          IN TOOLTRANS.ORGID%TYPE,
                        TOOLNUM_I        IN ITEM.itemnum%TYPE, 
                        DESCRIPTION_I    IN ITEM.DESCRIPTION%TYPE)
   RETURN VARCHAR2
   IS
   SUCCESS_T VARCHAR2(1) :='1';
   SETID_T   ITEM.itemsetid%TYPE;

   BEGIN
   
   SELECT  SETID INTO SETID_T
   FROM MAXIMO.SETS 
   WHERE SETTYPE='ITEM';   
   
       
   INSERT INTO MAXIMO.ITEM (ITEMNUM, DESCRIPTION, 
   ROTATING, LOTTYPE, CAPITALIZED, OUTSIDE, sparepartautoadd,inspectionrequired,
   attachonissue, conditionenabled, hasld, iskit,
   itemsetid,itemtype,langcode, prorate,
   ITEM.itemid, issueunit, orderunit, hardresissue, pluscsolution, iscrew,
   pluscismte, pluscisinhousecal, taxexempt, statusdate, status)
   VALUES
   (TOOLNUM_I, DESCRIPTION_I, 
    0,'NOLOT',1,0, 0,0,
    0,0,0,0,
   SETID_T, 'TOOL','EN',0,
   ITEMSEQ.NEXTVAL, 'EA', 'EA', '0', '0', '0', '0', '0', '0', sysdate, 'ACTIVE');
   
   INSERT INTO MAXIMO.ITEMORGSTATUS (changeby, changedate, itemnum, 
            itemorgstatusid,itemsetid, status, orgid)
   SELECT CHANGEBY_T, SYSDATE, TOOLNUM_I, 
       ITEMORGSTATUSSEQ.NEXTVAL, SETID_T, 'ACTIVE', 'LBNL'
   FROM DUAL
   WHERE NOT EXISTS (select * from itemorgstatus where itemnum = TOOLNUM_I and orgid = 'LBNL');
    
   INSERT INTO MAXIMO.ITEMSTATUS (changeby, changedate, itemnum, 
            itemstatusid,itemsetid, status)
   SELECT CHANGEBY_T, SYSDATE, TOOLNUM_I, ITEMSTRUCTSEQ.NEXTVAL, SETID_T, 'ACTIVE'
   FROM DUAL
   WHERE NOT EXISTS (select * from itemstatus where itemnum = TOOLNUM_I);   

   INSERT INTO MAXIMO.ITEMSTRUCT (itemnum, instance, itemid, quantity,
        itemsetid, itemstructid, langcode, hasld)
   SELECT TOOLNUM_I, '0', TOOLNUM_I, '1', SETID_T, ITEMSTRUCTSEQ.NEXTVAL, 'EN', '0'
   FROM DUAL
   WHERE NOT EXISTS (select * from ITEMSTRUCT where itemnum = TOOLNUM_I);   
  
   INSERT INTO MAXIMO.ITEMORGINFO (itemnum, itemorginfoid, itemsetid, orgid,
        statusdate, status, category, taxexempt)
   SELECT TOOLNUM_I, ITEMORGINFOSEQ.NEXTVAL, SETID_T, ORGID_T, SYSDATE, 'ACTIVE', 'STK', '0'
   FROM DUAL
   WHERE NOT EXISTS (select * from ITEMORGINFO where itemnum = TOOLNUM_I and orgid = ORGID_T); 
            
   RETURN SUCCESS_T ;
   
   END;    
 
   /* INSERT A NEW LABOR RECORD */ 
   FUNCTION INSERT_LABOR(ORGID_I   LABOR.ORGID%TYPE,
                         LABORCODE_I        IN LABOR.LABORCODE%TYPE)
    RETURN VARCHAR2
   IS
      SUCCESS_T VARCHAR2(1) :='1';
      LABORCODE_T  LABOR.LABORCODE%TYPE;
  
  BEGIN
     
      BEGIN
  
       SELECT LABORCODE INTO LABORCODE_T
       FROM   MAXIMO.LABOR
       WHERE  LABOR.ORGID=ORGID_I
       AND    LABOR.LABORCODE=LABORCODE_I;
     
       EXCEPTION WHEN NO_DATA_FOUND THEN
         INSERT INTO MAXIMO.LABOR 
         (LABOR.LABORCODE, LABOR.PERSONID,
          LABOR.REPORTEDHRS, LABOR.YTDOTHRS, LABOR.YTDHRSREFUSED,
          LABOR.AVAILFACTOR, LABOR.ORGID,
          LABOR.LABORID, LABOR.STATUS, LABOR.WORKSITE, LABOR.LBSDATAFROMWO)          
          VALUES(LABORCODE_I, LABORCODE_I,
              0,0,0,
              1, ORGID_I,
              LABORSEQ.NEXTVAL, 'ACTIVE', 'WORK', '0');
              
      INSERT INTO MAXIMO.LABORSTATUS 
         (LABORSTATUS.CHANGEBY, LABORSTATUS.CHANGEDATE, LABORSTATUS.LABORCODE, LABORSTATUS.LABORSTATUSID, 
         LABORSTATUS.ORGID, LABORSTATUS.STATUS)          
          VALUES(CHANGEBY_T, SYSDATE, LABORCODE_I, LABORSTATUSSEQ.NEXTVAL,
          ORGID_T, 'ACTIVE');              
      END;
                         
        
     RETURN SUCCESS_T ;
  END; 

/*******************************
 MAIN PROGRAM STARTS FROM HERE  
*******************************/
   
BEGIN
  
     -- GET THE VALUE OF THE LAST FISCAL YEAR AND ACCOUNTING PERIOD 
     -- WHICH IS HARD-CLOSED. THIS IS STORED IN DW_LBNL_HARD_CLOSE OBJECT.
    
     DBMS_OUTPUT.ENABLE(1000000); 
     
     
     
     ORGID_T   := 'LBNL';
     SITEID_T  := 'FAC';
     
delete  from labtrans where lt1 is not null and (financialperiod like '2015%' or financialperiod like '2016%');

delete from tooltrans where tt1 is not null and (financialperiod like '2015%' or financialperiod like '2016%');

    
    
    FROM_FISCAL_YEAR_T := 2015;
    TO_FISCAL_YEAR_T := 2016;
    FROM_ACCOUNTING_PERIOD_T := 1;
    TO_ACCOUNTING_PERIOD_T := 12; 
        
    
      -- GET THE POSSIBLE LABOR RESOURCE TYPES
    LABOR_RES_TYPE_T :=GET_LABOR_RESTYPE;
        
    select lbl_maximo_pkg.get_mxint_userid into CHANGEBY_T 
     from dual;  

--    SELECT PROPVALUE INTO CHANGEBY_T  
--     FROM MAXPROPVALUE  
--     WHERE UPPER(PROPNAME) ='MXE.INT.DFLTUSER';
    
     SELECT TO_DATE(VARVALUE,'MM-DD-YYYY')
        INTO STARTUP_DATE_T
        FROM LBL_MAXVARS 
        WHERE VARNAME='FRST_WO_APPR_DT'
        AND   ORGID=ORGID_T
        AND   SITEID=SITEID_T;
        
     SELECT VARVALUE
        INTO JOURNAL_ID_T
        FROM LBL_MAXVARS 
        WHERE VARNAME='STR03_FEEDER_NAME'
        AND   ORGID=ORGID_T
        AND   SITEID=SITEID_T;
        
      
    
           
    -- START READING THE RECORDS FROM THE LBL_PS_PROJ_RESOURCE CURSOR
        
    FOR INPUT_RECORDS_REC IN INPUT_RECORDS_CUR
    
      LOOP   
    
   
                
      --GET THE FIRST APPROVALDATE OF WORK ORDER
      APPROVAL_DATE_T := MAXIMO.LBL_MAXIMO_PKG.GET_FRST_APPR_DATE(
                         INPUT_RECORDS_REC.ORGID, 
                         INPUT_RECORDS_REC.SITEID, 
                         INPUT_RECORDS_REC.WONUM);
      
      -- CONSIDER ONLY THOSE WORK ORDERS WHICH ARE APPROVED AFTER 10/1/05
      IF TO_DATE(APPROVAL_DATE_T,'DD-MON-RRRR') >= TO_DATE(STARTUP_DATE_T,'DD-MON-YYYY') 
         THEN
          
          REC_COUNT_T := REC_COUNT_T + 1;
          
          IF (REC_COUNT_T=1)  THEN
                              
             PRV_WONUM     :=INPUT_RECORDS_REC.WONUM;
             PRV_ORGID     :=INPUT_RECORDS_REC.ORGID;
             PRV_SITEID    :=INPUT_RECORDS_REC.SITEID;
             
             -- DELETE PRELIMINARY RECORDS FROM TRANSACTION TABLES
             -- AND GET THE OLD ACTUAL COSTS              
             BEFORE_WONUM(PRV_WONUM, PRV_ORGID, PRV_SITEID);
                          
          END IF;   --IF REC_COUNT_T=1  
          
          -- WORK ORDER NUMBER CHANGED 
          -- MXES  CHECK COMBINATION OF ORGID+SITEID+WONUM 
          IF (  (PRV_ORGID || PRV_SITEID || PRV_WONUM) != 
                (INPUT_RECORDS_REC.ORGID || INPUT_RECORDS_REC.SITEID ||INPUT_RECORDS_REC.WONUM)
              )
                THEN 
          
             -- UPDATE WORKORDER TABLE TO REPLACE THE VALUES OF 
             -- ACTUAL COSTS 
             AFTER_WONUM(PRV_WONUM, PRV_ORGID, PRV_SITEID) ;
                       
                         
             PRV_WONUM     :=INPUT_RECORDS_REC.WONUM;
             PRV_ORGID     :=INPUT_RECORDS_REC.ORGID;
             PRV_SITEID    :=INPUT_RECORDS_REC.SITEID;             
                          
             -- DELETE PRELIMINARY RECORDS FROM TRANSACTION TABLES
             -- AND GET THE OLD ACTUAL COSTS              
             BEFORE_WONUM(PRV_WONUM, PRV_ORGID, PRV_SITEID);
                                       
          END IF;  -- (PRV_WONUM != INPUT_RECORDS_REC.WONUM)
           
           -- *****************************************************
           -- PROCESS THE INDIVIDUAL TRANSACTION FOR THE WORK ORDER
           -- *****************************************************
           
           -- PREARE THE VALUE OF FINANCIALPERIOD 
           FINANCIALPERIOD_T := LTRIM(TO_CHAR(INPUT_RECORDS_REC.FISCAL_YEAR,'9999')) || 
           LPAD(LTRIM(TO_CHAR(INPUT_RECORDS_REC.ACCOUNTING_PERIOD,'99')),2,'0');
           
           MEMO_T := 'FINAL-' || TO_CHAR(SYSDATE,'MM-DD-YYYY HH24:MI');
           
           -- PROCESS PURE LABOR RECORDS TO INSERT INTO LABTRANS TABLE                    
           IF   (INPUT_RECORDS_REC.RESOURCE_QUANTITY != 0 
           AND  INPUT_RECORDS_REC.EMPLID IS NOT NULL
           -- ADDED BY PANKAJ JIRA EF-4010
           AND INSTR(LABOR_RES_TYPE_T, '|' || INPUT_RECORDS_REC.RESOURCE_TYPE|| '|') > 0            
           --AND  LENGTH(LTRIM(INPUT_RECORDS_REC.EMPLID)) >0
           AND  LENGTH(INPUT_RECORDS_REC.EMPLID) >1  ) THEN 
               
              -- GET CRAFT CODE FOR THE EMPLOYEE 
              CRAFT_T := LBL_MAXIMO_PKG.GET_LEADCRAFT_INFO(INPUT_RECORDS_REC.ORGID,
              INPUT_RECORDS_REC.EMPLID, 'CODE'); -- MXES 
              
              -- THIS CONDITION SHOULD NOT HAPPEN.............
              IF CRAFT_T IS NULL THEN
                 RESULT_T := INSERT_LABOR(INPUT_RECORDS_REC.ORGID,
                                          INPUT_RECORDS_REC.EMPLID);
                                          
                 CRAFT_T :=' ';     
               END IF;
               
                IF (INPUT_RECORDS_REC.RESOURCE_QUANTITY != 0 AND 
                   INPUT_RECORDS_REC.RESOURCE_AMOUNT != 0)
                THEN
                   PAYRATE_T := (INPUT_RECORDS_REC.RESOURCE_AMOUNT /
                                INPUT_RECORDS_REC.RESOURCE_QUANTITY);
                ELSE
                   PAYRATE_T :=0;
                END IF;               
              
               -- START INSERTING RECORD INTO LABTRANS TABLE
               SELECT  LABTRANSSEQ.NEXTVAL INTO LABTRANSID_T FROM DUAL;
               
               INSERT INTO LABTRANS (TRANSDATE, LABORCODE, 
               CRAFT, PAYRATE,
               ASSETNUM , REFWO,    -- MXES 
               REGULARHRS, ROLLUP,               
               PREMIUMPAYHOURS, ENTERBY, ENTERDATE, 
               TRANSTYPE, OUTSIDE, GLDEBITACCT, 
               LINECOST, ENTEREDASTASK,   
               FINANCIALPERIOD, LOCATION, LT1, MEMO,
                   STARTDATE, GENAPPRSERVRECEIPT, LABTRANSID,
                   ORGID, SITEID)  VALUES
              (INPUT_RECORDS_REC.TRANS_DT, INPUT_RECORDS_REC.EMPLID, 
               CRAFT_T, PAYRATE_T,
               INPUT_RECORDS_REC.ASSETNUM, INPUT_RECORDS_REC.WONUM, -- MXES 
               INPUT_RECORDS_REC.RESOURCE_QUANTITY, '0', -- MXES 
               0, 'DATAWHSE', INPUT_RECORDS_REC.TRANS_DT,
                   'WORK', '0', INPUT_RECORDS_REC.GLACCOUNT, 
                   INPUT_RECORDS_REC.RESOURCE_AMOUNT, INPUT_RECORDS_REC.ISTASK,
               FINANCIALPERIOD_T, INPUT_RECORDS_REC.LOCATION,'M',MEMO_T,
               INPUT_RECORDS_REC.TRANS_DT,'1',LABTRANSID_T,
                   INPUT_RECORDS_REC.ORGID,INPUT_RECORDS_REC.SITEID);
               
               
               ELSE
                   -- FIND OUT THE RESOURCE CATEGORY ALREADY EXISTS. IF NOT THEN 
                   -- INSERT IT INTO TOOL TABLE
                   
                   -- ALL THE TOOLS DENOTED BY RESOURCE CATEGORIES WILL BE
                   -- PREFIXED WITH R.
                   
                   TOOLNUM_T := 'R' || INPUT_RECORDS_REC.RESOURCE_CATEGORY;
                   
                   REC_FOUND_T1 :=0;
                   REC_FOUND_T2 :=0; 
                   
                   FOR TOOL_REC IN TOOL_CUR
                    LOOP
                      REC_FOUND_T1 := REC_FOUND_T1 + 1;
                      EXIT;
                    END LOOP;
                   
                   -- TOOL DOES NOT EXIST IN TOOL TABLE 
                   -- THEREFORE ADD A NEW TOOL 
                   
                   IF REC_FOUND_T1=0 THEN
                     FOR RESOURCE_CATEGORY_REC IN  RESOURCE_CATEGORY_CUR 
                        LOOP
                          REC_FOUND_T2 := REC_FOUND_T2 + 1;
                          TOOL_DESCRIPTION_T :=RESOURCE_CATEGORY_REC.RESCAT_DS;
                          EXIT;
                        END LOOP;
                        
                        IF REC_FOUND_T2=0 THEN 
                          TOOL_DESCRIPTION_T := 'TO BE DETERMINED'; 
                    END IF;     
                    
                    RESULT_T :=INSERT_TOOL(INPUT_RECORDS_REC.ORGID,
                                           TOOLNUM_T,TOOL_DESCRIPTION_T);
                END IF;
                
                -- NOW INSERT INTO TOOLTRANS TABLE
                INSERT INTO MAXIMO.TOOLTRANS
                (TRANSDATE,ITEMNUM, 
                 TOOLRATE, ASSETNUM, 
                 TOOLQTY,  TOOLHRS,
                 ENTERDATE, ENTERBY,
                 OUTSIDE, ROLLUP, ENTEREDASTASK, TT1,
                 LINECOST, FINANCIALPERIOD,
                 GLDEBITACCT, LOCATION, 
                 REFWO, ORGID, 
                 SITEID,MEMO,
                 TOOLTRANS.TOOLTRANSID,
                 ITEMSETID, EXCHANGERATE2, LANGCODE, HASLD, LINECOST2)
                VALUES
                (INPUT_RECORDS_REC.TRANS_DT, TOOLNUM_T,
                 0, INPUT_RECORDS_REC.ASSETNUM,
                 0, 0,
                 INPUT_RECORDS_REC.TRANS_DT, 'DATAWHSE',
                 '0','0',INPUT_RECORDS_REC.ISTASK, 'M',
                 INPUT_RECORDS_REC.RESOURCE_AMOUNT, FINANCIALPERIOD_T,
                 INPUT_RECORDS_REC.GLACCOUNT, INPUT_RECORDS_REC.LOCATION,
                 INPUT_RECORDS_REC.WONUM,INPUT_RECORDS_REC.ORGID,
                 INPUT_RECORDS_REC.SITEID,MEMO_T,
                 TOOLTRANSSEQ.NEXTVAL,     -- MXES 
                 'ILBNL','1.0', 'EN', '0', INPUT_RECORDS_REC.RESOURCE_AMOUNT); 
                 -- 'SET1'); CHANGED BY PANKAJ 3/11/10
                                  
               END IF; -- IF   (INPUT_RECORDS_REC.RESOURCE_QUANTITY !=0 ....)

     END IF; -- TO_DATE(APPROVAL_DATE_T,'DD-MON-YY') >= TO_DATE(STARTUP_DATE_T,'DD-MON-YY')        
              
  END LOOP;

      -- PROCESS LAST WORK ORDER FROM THE CONTROL BREAK 
      IF (REC_COUNT_T > 0) THEN   
      -- UPDATE WORKORDER TABLE TO REPLACE THE VALUES OF 
      -- ACTUAL COSTS 
         AFTER_WONUM(PRV_WONUM, PRV_ORGID, PRV_SITEID);                         
     END IF;
    
   IF (REC_COUNT_T > 0) THEN   
   
    -- DELETE THE LEFTOVER LABTRANS RECORDS WHICH COULD NOT BE REPLACED
    -- BY THE PS_PROJ_RESOURCE RECORDS (PROBABLY DROP OUTS) AND UPDATE THE ACTUAL 
    -- COSTS ON THE WORK ORDER TABLE     
     
    FOR LABTRANS_LEFTOUT_REC IN   LABTRANS_LEFTOUT_CUR 
    
     LOOP
        
         NEW_LABCOST_T :=0;
         NEW_LABHRS_T  :=0;
        
         SELECT ACTLABCOST, ACTLABHRS
         INTO   NEW_LABCOST_T, NEW_LABHRS_T
         FROM   MAXIMO.WORKORDER
         WHERE  WONUM=LABTRANS_LEFTOUT_REC.REFWO;        
                
         NEW_LABCOST_T := NEW_LABCOST_T - LABTRANS_LEFTOUT_REC.LEFT_ACTLABCOST;
         NEW_LABHRS_T  := NEW_LABHRS_T  - LABTRANS_LEFTOUT_REC.LEFT_ACTLABHRS;
         
         UPDATE MAXIMO.WORKORDER
         SET ACTLABCOST=NEW_LABCOST_T, ACTLABHRS=NEW_LABHRS_T
         WHERE  WONUM=LABTRANS_LEFTOUT_REC.REFWO;
         
     END LOOP;
     
    -- DELETE THE LEFTOVER TOOLTRANS RECORDS WHICH COULD NOT BE REPLACED
    -- BY THE PS_PROJ_RESOURCE RECORDS (PROBABLY DROP OUTS) AND UPDATE THE ACTUAL 
    -- COSTS ON THE WORK ORDER TABLE
      
    FOR TOOLTRANS_LEFTOUT_REC IN   TOOLTRANS_LEFTOUT_CUR 
    
     LOOP
        
         NEW_TOOLCOST_T :=0;    
         
         SELECT ACTTOOLCOST
         INTO   NEW_TOOLCOST_T 
         FROM   MAXIMO.WORKORDER
         WHERE  WONUM=TOOLTRANS_LEFTOUT_REC.REFWO;
                       
         NEW_TOOLCOST_T := NEW_TOOLCOST_T - TOOLTRANS_LEFTOUT_REC.LEFT_ACTTOOLCOST;
                  
         UPDATE MAXIMO.WORKORDER
         SET    ACTTOOLCOST=NEW_TOOLCOST_T
         WHERE  WONUM=TOOLTRANS_LEFTOUT_REC.REFWO;
         
     END LOOP;    
      
     -- FINALLY DELETE THE LEFTOOVER RECORDS FROM LABTRANS AND TOOLTRANS       
                  
     DELETE FROM MAXIMO.LABTRANS
     WHERE   ORGID=ORGID_T
     AND     SITEID=SITEID_T          
     AND     LT1='W'
     AND     MEMO LIKE 'PRELIMINARY%';
    
     
     DELETE FROM MAXIMO.TOOLTRANS
     WHERE  ORGID=ORGID_T
     AND    SITEID=SITEID_T                    
     AND    TT1='W'
     AND    MEMO LIKE 'PRELIMINARY%';
     
   
     -- FINALLY UPDATE LBL_MAXVARS AND SET THE VALUE OF TO_FISCAL_YEAR AND
     -- TO_ACCOUNTING_PERIOD FOR WHICH THE ACTUALS ARE COPIED TO MAXIMO 
     
     UPDATE LBL_MAXVARS
     SET    VARVALUE=LTRIM(RTRIM(TO_CHAR(TO_FISCAL_YEAR_T,'9999'))) ||   
                     LPAD(LTRIM(TO_CHAR(TO_ACCOUNTING_PERIOD_T,'99')),2,'0')
     WHERE  VARNAME='LAST_MONTHLY_ACTUALS_TO_MAXIMO'
     AND    ORGID=ORGID_T
     AND    SITEID=SITEID_T;
     
   END IF;     -- IF (REC_COUNT_T > 0) THEN   
     

COMMIT;

 DBMS_STATS.GATHER_TABLE_STATS(
                           OWNNAME=>'MAXIMO', 
                           TABNAME=>'LABTRANS',
                           ESTIMATE_PERCENT=>DBMS_STATS.AUTO_SAMPLE_SIZE,
                           CASCADE=>TRUE); 
                           
DBMS_STATS.GATHER_TABLE_STATS(
                           OWNNAME=>'MAXIMO', 
                           TABNAME=>'TOOLTRANS',
                           ESTIMATE_PERCENT=>DBMS_STATS.AUTO_SAMPLE_SIZE,
                           CASCADE=>TRUE);
                                                       
END;            


/
 

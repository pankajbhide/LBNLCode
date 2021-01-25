
/***************************************************************************
 NAME                   : IMPACTCOST_DLY.SQL

 DATE WRITTEN           : 09-APRIL-2009

 AUTHOR                 : PANKAJ BHIDE 

 PURPOSE                : THIS PROGRAM BRINGS THE $ COSTS (LABOR + OTHER) SPENT 
                          ON THE WORK ORDERS FROM DATA WAREHOUSE. 
                                                    
                          THIS PROGRAM WILL BE SCHEDULED TO EXECUTE DAILY.
 
 MODIFICATION HISTORY	: 11-MAR-2010 ITEM SETID=ILBNL
                 
                          20-MAY-2010 CHANGED THE LOGIC FOR CHECKING EMPLOYEE ID 
                          IS BLANK OR NOT. 
                          
                          Modified the program due to the changes of the GL Account
                          using combination of Project ID and Activity ID 
                          by Annette Leung 12/19/13
                          
                          Modified the program due to MAXIMO 7.6 upgrade 2/2015
                          by Annette Leung.
                          
                          Set labtrans.genapprservreceipt = 1
                          
                          Modified to get all the analysis type of transacation
                          by Annette Leung 6/13/16
                          
                          Modified to include all the burdens.
                          by Annette Leung 7/5/16

                          Revisions JIRA EF-4010 Pankaj Bhide
                          
                          Replaced ISS.CURRENT_FISCAL_YEAR and ISS.CURRENT_ACCOUNTING_PERIOD  
                          Annette Leung 9/15/17
********************************************************************************/

WHENEVER SQLERROR EXIT 1 ROLLBACK;

DECLARE
 
     FISCAL_YEAR_T          VARCHAR2(4) :=NULL;
     ACCOUNTING_PERIOD_T    VARCHAR2(2) :=NULL;
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
            A.SUPERVISOR, A.ACTLABCOST, A.ACTTOOLCOST, A.ACTLABHRS, A.ISTASK,
	        B.EMPLID, 
            NVL(B.TRANS_DT, TRUNC(B.DTTM_STAMP)) TRANS_DT, -- ADDED BY PANKAJ 08/18/06
            B.ACCOUNTING_PERIOD, B.RESOURCE_TYPE,
            B.FISCAL_YEAR, B.RESOURCE_QUANTITY, 
            NVL(B.RESOURCE_AMOUNT,0) RESOURCE_AMOUNT,
            B.RESOURCE_CATEGORY     
    from WORKORDER A, PS_ZMX_PRJ_RES_VW B
    where A.ORGID = ORGID_T
    and A.SITEID = SITEID_T
    and A.ORGID = B.BUSINESS_UNIT
    and A.WONUM = B.CHARTFIELD1
    and A.SUPERVISOR is not null  
    and A.GLACCOUNT is not null
    and A.LOCATION is not null
    and B.BUSINESS_UNIT = ORGID_T
    --and B.ANALYSIS_TYPE = 'ACT'   
    and B.FISCAL_YEAR = FISCAL_YEAR_T
    and B.ACCOUNTING_PERIOD = ACCOUNTING_PERIOD_T 
    --and B.PROJ_TRANS_TYPE != JOURNAL_ID_T
    and B.PROJ_TRANS_TYPE not in (select VARVALUE FROM LBL_MAXVARS WHERE VARNAME='STR03_FEEDER_NAME' AND ORGID=ORGID_T AND SITEID=SITEID_T)
    order by A.WONUM, B.RESOURCE_CATEGORY, B.EMPLID, B.TRANS_DT;
         
    
    CURSOR TOOL_CUR IS 
      --SELECT DESCRIPTION FROM TOOL WHERE ORGID=ORGID_T AND TOOLNUM=TOOLNUM_T;
      SELECT DESCRIPTION FROM ITEM WHERE ITEMNUM=TOOLNUM_T AND ITEMTYPE='TOOL'; -- MXES 
 
         
    -- CURSOR TO GET THE RESOURCE CATEGORY DESCRIPTION FROM DATA WAREHOUSE 
    CURSOR RESOURCE_CATEGORY_CUR IS
      SELECT SUBSTR(RESCAT_DS,1,50) RESCAT_DS -- TOOL.DESCRIPTION=VARCHAR2(50)
      FROM   lbl_resource_category_cur
      WHERE  RESCAT_CD=SUBSTR(TOOLNUM_T,2);  -- TOOLNUM STARTS WITH R


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
        AND    LT1 IS NOT NULL;  
                
        
        SELECT SUM(LINECOST) 
        INTO   NEW_TOOLCOST_T1
        FROM   TOOLTRANS
        WHERE  ORGID=ORGID_I
        AND    SITEID=SITEID_I
        AND    REFWO=WONUM_I
        AND    TT1 IS NOT NULL;
        
   	      
        UPDATE MAXIMO.WORKORDER 
        SET ACTLABCOST =NVL(NEW_LABCOST_T1,0),
            ACTLABHRS  =NVL(NEW_LABHRS_T1,0),
            ACTTOOLCOST=NVL(NEW_TOOLCOST_T1,0),
            LASTCOPYLINKDATE = sysdate,
            CHANGEBY = CHANGEBY_T,
            ACTINTLABHRS = NVL(NEW_LABHRS_T1,0),
            ACTINTLABCOST = NVL(NEW_LABCOST_T1,0),
            CHANGEDATE = sysdate
        WHERE ORGID=ORGID_I
        AND   SITEID=SITEID_I
        AND   WONUM= WONUM_I;
    END;
    
  /* INSERT A NEW TOOL IN ITEM (TOOL) MXES  */ 
   FUNCTION INSERT_TOOL(ORGID_I          IN TOOL.ORGID%TYPE,
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
   SETID_T,'TOOL','EN',0,
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
  
     DBMS_OUTPUT.ENABLE(1000000); 
 
    ORGID_T   := UPPER('&1');
    SITEID_T  := UPPER('&2');
    

--------------------------------------------------------
   
     IF (ORGID_T IS NULL OR LENGTH(ORGID_T)=0) THEN
       ORGID_T :='LBNL';
     END IF;
     
     IF (SITEID_T IS NULL OR LENGTH(SITEID_T)=0) THEN
        SITEID_T :='FAC';
     END IF;

     
--     FISCAL_YEAR_T       := ISS.CURRENT_FISCAL_YEAR;
--     ACCOUNTING_PERIOD_T := ISS.CURRENT_ACCOUNTING_PERIOD;

        select fiscal_year_nr, fiscal_month_nr
        into FISCAL_YEAR_T,ACCOUNTING_PERIOD_T
        from edw_share.current_fiscal_year@edw;
    
     select lbl_maximo_pkg.get_mxint_userid into CHANGEBY_T 
     from dual; 
     
     --SELECT PROPVALUE INTO CHANGEBY_T  
     --FROM MAXPROPVALUE  
     --WHERE UPPER(PROPNAME) ='MXE.INT.DFLTUSER';

---------------------------------------------
     SELECT TO_DATE(VARVALUE,'MM-DD-YYYY')
        INTO STARTUP_DATE_T
        FROM LBL_MAXVARS 
        WHERE VARNAME='FRST_WO_APPR_DT'
        AND   ORGID=ORGID_T
        AND   SITEID=SITEID_T;
        

--        SELECT VARVALUE
--        INTO JOURNAL_ID_T
--        FROM LBL_MAXVARS 
--        WHERE VARNAME='STR03_FEEDER_NAME'
--        AND   ORGID=ORGID_T
--        AND   SITEID=SITEID_T;
        
            
     MEMO_T     := 'PRELIMINARY-' || TO_CHAR(SYSDATE,'MM-DD-YYYY');

   -- GET THE POSSIBLE LABOR RESOURCE TYPES JIRA EF-4010
    LABOR_RES_TYPE_T :=GET_LABOR_RESTYPE;

        
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
             AFTER_WONUM(PRV_WONUM, PRV_ORGID, PRV_SITEID);                     
                        
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

           -- PROCESS PURE LABOR RECORDS TO INSERT INTO LABTRANS TABLE
           IF   (INPUT_RECORDS_REC.RESOURCE_QUANTITY != 0
           AND  INPUT_RECORDS_REC.EMPLID IS NOT NULL
           AND INSTR(LABOR_RES_TYPE_T, '|' || INPUT_RECORDS_REC.RESOURCE_TYPE|| '|') > 0
           AND  LENGTH(INPUT_RECORDS_REC.EMPLID) >1) -- ADDED ON 8/1/2009 THEN
           THEN


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
               FINANCIALPERIOD_T, INPUT_RECORDS_REC.LOCATION,'W',MEMO_T,
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
	           
	           -- TOOL DOES NOT EXIST IN ITEM TABLE 
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
                 '0','0',INPUT_RECORDS_REC.ISTASK, 'W',
                 INPUT_RECORDS_REC.RESOURCE_AMOUNT, FINANCIALPERIOD_T,
                 INPUT_RECORDS_REC.GLACCOUNT, INPUT_RECORDS_REC.LOCATION,
                 INPUT_RECORDS_REC.WONUM,INPUT_RECORDS_REC.ORGID,
                 INPUT_RECORDS_REC.SITEID,MEMO_T,
                 TOOLTRANSSEQ.NEXTVAL,     -- MXES
                 'ILBNL','1.0', 'EN', '0', INPUT_RECORDS_REC.RESOURCE_AMOUNT);
                 -- 'SET1'); CHANGED PANKAJ 3/11/10

	       END IF; -- IF   (INPUT_RECORDS_REC.RESOURCE_QUANTITY !=0 ....)

     END IF; -- TO_DATE(APPROVAL_DATE_T,'DD-MON-YY') >= TO_DATE(STARTUP_DATE_T,'DD-MON-YY')        
              
  END LOOP;

      -- PROCESS LAST WORK ORDER FROM THE CONTROL BREAK 
      IF (REC_COUNT_T > 0) THEN   
      -- UPDATE WORKORDER TABLE TO REPLACE THE VALUES OF 
      -- ACTUAL COSTS 
         AFTER_WONUM(PRV_WONUM, PRV_ORGID, PRV_SITEID);                         
     END IF;

           
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



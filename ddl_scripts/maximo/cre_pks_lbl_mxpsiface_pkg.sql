CREATE OR REPLACE PACKAGE lbl_mxpsiface_pkg
IS
/*****************************************************************************
 PROGRAM NAME           : LBL_MXPSIFACE_PKG

 DATE WRITTEN           : 25-DEC-2013

 AUTHOR                 : PANKAJ BHIDE

 PURPOSE                : PACKAGE SPECS FOR FUNCTIONS DEVELOPED FOR INTERFACING
                          THE DATA BETWEEN MAXIMO AND PEOPLESOFT (F$M)
****************************************************************************/

T_PROJ_ACT_DELIMITER VARCHAR2(1);



/**************************************************************
FUNCTION TO SYNCHRONIZE PROJECT AND ACTIVITIES FROM PEOPLESOFT
   TO MAXIMO.
**************************************************************/
FUNCTION SYNC_PROJACT_COA(I_ORGID  IN MAXIMO.SITE.ORGID%TYPE,
                          I_SITEID IN MAXIMO.SITE.SITEID%TYPE)
                          RETURN  VARCHAR2;



/**********************************************************************
 FUNCTION TO RETURN THE VALUES OF WORK ORDER APPROVAL
 THE RESULTING STRING WOULD BE ENCLOSED WITH PIPE CHARACTER
 ***********************************************************************/
 FUNCTION WO_APPR_SYNONYMS  RETURN VARCHAR2;


 /**********************************************************************
 FUNCTION TO RETURN THE ASSET TYPE FOR A  GIVEN ITEM GROUP
 ***********************************************************************/
 FUNCTION GET_ASSET_TYPE (I_ITEMGROUP  IN ITEM.ITEMNUM%TYPE,
                          I_ACCOUNT    IN CHARTOFACCOUNTS.GLACCOUNT%TYPE)
                          RETURN VARCHAR2;



/*******************************************************************************
 FUNCTION TO RETURN THE DESCRIPTION BASED UPON THE TYPE (E.G. SHORT, DETAILED ETC)
 *******************************************************************************/
FUNCTION PREPARE_DESCRIPTION(I_DESCRIPTION IN WORKORDER.DESCRIPTION%TYPE,
                             I_TYPE IN WORKORDER.DESCRIPTION%TYPE,
                             I_LBL_DESTGROUP IN WORKORDER.LBL_DESTGROUP%TYPE,
                             I_WORKTYPE IN WORKORDER.WORKTYPE%TYPE,
                             I_LBL_VALUESTREAM IN WORKORDER.LBL_VALUESTREAM%TYPE)
                             RETURN VARCHAR2;
/*********************************************************************
 FUNCTION TO INSERT RECORD INTO JOB/WORKORDER INTERFACE
 TABLE ON FMS SIDE
*********************************************************************/
FUNCTION   INSERT_WOJOB_INTFC(I_WONUM IN WORKORDER.WONUM%TYPE,
             I_DESCRIPTION IN WORKORDER.DESCRIPTION%TYPE,
             I_DESCSHORT   IN WORKORDER.DESCRIPTION%TYPE,
             I_LDKEY IN LONGDESCRIPTION.LDKEY%TYPE,
             I_PROJECT_ID IN LBL_V_PROJACT.LBL_PROJECT_ID%TYPE,
             I_ACTIVITY_ID IN LBL_V_PROJACT.LBL_ACTIVITY_ID%TYPE,
             I_STATUS  IN WORKORDER.STATUS%TYPE)
             RETURN VARCHAR2;
/**************************************************************
 FUNCTION TO SEND WORK ORDER INFORMATION TO FMS
**************************************************************/
FUNCTION SENDWO2FMS(I_ORGID  IN MAXIMO.SITE.ORGID%TYPE,
                    I_SITEID IN MAXIMO.SITE.SITEID%TYPE)
                    RETURN  VARCHAR2;

FUNCTION INSERT_LBL_PROJ_FEEDERS(ORGID_T IN BATCH_MAXIMO.LBL_PROJ_FEEDERS.ORGID%TYPE,
           SITEID_T             IN  BATCH_MAXIMO.LBL_PROJ_FEEDERS.SITEID%TYPE,
           PROJ_TRANS_TYPE_T    IN  BATCH_MAXIMO.LBL_PROJ_FEEDERS.PROJ_TRANS_TYPE%TYPE,
           FISCAL_YEAR_T        IN  BATCH_MAXIMO.LBL_PROJ_FEEDERS.FISCAL_YEAR%TYPE,
           ACCOUNTING_PERIOD_T  IN  BATCH_MAXIMO.LBL_PROJ_FEEDERS.ACCOUNTING_PERIOD%TYPE,
           JOURNAL_ID_T         IN  BATCH_MAXIMO.LBL_PROJ_FEEDERS.journal_id%TYPE,
           RECORD_ID_T          IN  BATCH_MAXIMO.LBL_PROJ_FEEDERS.RECORD_ID%TYPE,
           TRANS_DATE_T         IN  BATCH_MAXIMO.LBL_PROJ_FEEDERS.TRANS_DATE%TYPE,
           ENTRY_TYPE_T         IN  BATCH_MAXIMO.LBL_PROJ_FEEDERS.ENTRY_TYPE%TYPE,
           LBL_PROJECT_ID_T     IN  BATCH_MAXIMO.LBL_PROJ_FEEDERS.LBL_PROJECT_ID%TYPE,
           LBL_ACTIVITY_ID_T    IN  BATCH_MAXIMO.LBL_PROJ_FEEDERS.LBL_ACTIVITY_ID%TYPE,
           ACCOUNT_T            IN  BATCH_MAXIMO.LBL_PROJ_FEEDERS.ACCOUNT%TYPE,
           WONUM_T              IN  BATCH_MAXIMO.LBL_PROJ_FEEDERS.WONUM%TYPE,
           TRANSTYPE_T          IN  BATCH_MAXIMO.LBL_PROJ_FEEDERS.TRANSTYPE%TYPE,
           RESOURCE_TYPE_T      IN  BATCH_MAXIMO.LBL_PROJ_FEEDERS.RESOURCE_TYPE%TYPE,
           RESOURCE_CATEGORY_T  IN  BATCH_MAXIMO.LBL_PROJ_FEEDERS.RESOURCE_CATEGORY%TYPE,
           LINE_DESCR_T       IN  BATCH_MAXIMO.LBL_PROJ_FEEDERS.LINE_DESCR%TYPE,
           UNIT_OF_MEASURE_T  IN  BATCH_MAXIMO.LBL_PROJ_FEEDERS.UNIT_OF_MEASURE%TYPE,
           DR_CR_T            IN  BATCH_MAXIMO.LBL_PROJ_FEEDERS.DR_CR%TYPE,
           RESOURCE_AMOUNT_T  IN  BATCH_MAXIMO.LBL_PROJ_FEEDERS.RESOURCE_AMOUNT%TYPE,
           INACTIVE_T         IN  BATCH_MAXIMO.LBL_PROJ_FEEDERS.INACTIVE%TYPE,
           ANALYSIS_TYPE_T    IN  BATCH_MAXIMO.LBL_PROJ_FEEDERS.ANALYSIS_TYPE%TYPE,
           DEPARTMENT_CODE_T  IN  BATCH_MAXIMO.LBL_PROJ_FEEDERS.DEPARTMENT_CODE%TYPE,
           FUND_CODE_T        IN BATCH_MAXIMO.LBL_PROJ_FEEDERS.FUND_CODE%TYPE,
           ASSET_TYPE_T       IN BATCH_MAXIMO.LBL_PROJ_FEEDERS.ASSET_TYPE%TYPE)
         RETURN VARCHAR2;


/**************************************************************
 FUNCTION TO GENERATE STORES FEEDERS
**************************************************************/
FUNCTION GENERATE_STORES_FEEDER(I_ORGID  IN MAXIMO.SITE.ORGID%TYPE,
                              I_SITEID IN MAXIMO.SITE.SITEID%TYPE)
                    RETURN  VARCHAR2;



/**************************************************************
 FUNCTION TO GENERATE STORES FEEDERS (PROJECT)
**************************************************************/
FUNCTION GENERATE_STORES_PROJ_FEEDER(I_ORGID  IN MAXIMO.SITE.ORGID%TYPE,
                              I_SITEID IN MAXIMO.SITE.SITEID%TYPE)
                    RETURN  VARCHAR2;


 END;

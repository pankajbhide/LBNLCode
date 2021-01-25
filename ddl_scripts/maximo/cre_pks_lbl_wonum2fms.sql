CREATE OR REPLACE PACKAGE LBL_WONUM2FMS AS


 /*****************************************************************************
 PROGRAM NAME           : LBL_WONUM2FMS

 DATE WRITTEN           : 01/01/2009

 AUTHOR                 : PANKAJ BHIDE

 PURPOSE                : PACKAGE SPECS FOR INTERFACING THE DATA CREATED
                          FROM MAXIMO WORK ORDERS FOR  FMS PROJECTS
*****************************************************************************/

-- FUNCTION TO RETURN THE GLACCOUNT OF TRUNK NODE(ROOT) OF THE WORK ORDER
FUNCTION GET_ROOT_GLACCOUNT(ORGID_I IN WORKORDER.ORGID%TYPE,
                           SITEID_I IN WORKORDER.SITEID%TYPE,
                           WONUM_I  IN WORKORDER.WONUM%TYPE)
        RETURN MAXIMO.WORKORDER.GLACCOUNT%TYPE;

/**********************************************************************
 FUNCTION TO RETURN THE VALUES OF WORK ORDER APPROVAL
 THE RESULTING STRING WOULD BE ENCLOSED WITH PIPE CHARACTER
 ***********************************************************************/
 FUNCTION GET_APPR_SYNONYMS  RETURN VARCHAR2;


 /******************************************************************
 FUNCTION TO INSERT THE RECORD/S INTO THE FMS INTERFACE TABLES
 *******************************************************************/
 FUNCTION INSERT_FMS_IFACE_TABLES(
      LBNL_MX_TR_DATE_I  IN PS_LBNL_MX_PROJECT.LBNL_MX_TRANS_DATE%TYPE,
      LBNL_MX_PR_CODE_I  IN PS_LBNL_MX_PROJECT.LBNL_MX_TRANS_CODE%TYPE,
      LBNL_MX_TM_CODE_I  IN PS_LBNL_MX_PROJECT.LBNL_MX_TRANS_CODE%TYPE,
      LBNL_MX_LC_CODE_I  IN PS_LBNL_MX_PROJECT.LBNL_MX_TRANS_CODE%TYPE,
      PROJECT_ID_I       IN PS_LBNL_MX_PROJECT.PROJECT_ID%TYPE,
      LBNL_PARENT_PROJ_I IN PS_LBNL_MX_PROJECT.LBNL_PARENT_PROJ%TYPE,
      START_DT_I         IN PS_LBNL_MX_PROJECT.START_DT%TYPE,
      END_DT_I           IN PS_LBNL_MX_PROJECT.END_DT%TYPE,
      DESCR_I            IN PS_LBNL_MX_PROJECT.DESCR%TYPE,
      DESCR254_I         IN PS_LBNL_MX_PROJECT.DESCR254%TYPE,
      TEAM_MEMBER_I      IN PS_LBNL_MX_TEAM.TEAM_MEMBER%TYPE,
      LOCATION_I         IN PS_LBNL_MX_LOC.LOCATION%TYPE)

   RETURN BOOLEAN;

 /**********************************************************
 FUNCTION TO PREPARE TRANS_CODE USED IN THE INTERFACE TABLES
 *******************************************************************/
 FUNCTION PREPARE_TRANS_CODE(
      TRANS_TYPE_I       VARCHAR2,
      PROJECT_ID_I       IN PS_LBNL_MX_PROJECT.PROJECT_ID%TYPE,
      PARENT_I           IN PS_LBNL_MX_PROJECT.LBNL_PARENT_PROJ%TYPE,
      TEAM_MEMBER_I      IN PS_LBNL_MX_TEAM.TEAM_MEMBER%TYPE,
      LOCATION_I         IN PS_LBNL_MX_LOC.LOCATION%TYPE)

   RETURN PS_LBNL_MX_PROJECT.LBNL_MX_TRANS_CODE%TYPE;

 /**********************************************************
 FUNCTION TO FIND OUT WHETHER THE PROJECT IS END DATED IN FMS
 *******************************************************************/
 FUNCTION IS_PROJ_ENDDT_FMS(
            PROJECT_ID_I  IN PS_LBNL_MX_PROJECT.PROJECT_ID%TYPE)
   RETURN PS_LBNL_MX_PROJECT.LBNL_MX_TRANS_CODE%TYPE;

 /*******************************************************************
 FUNCTION TO FIND OUT WHETHER PARENT IS VALID FOR THE GIVEN PASS
 *******************************************************************/
 FUNCTION IS_PARENT_VALID_PASS(
            PROJECT_ID_I  IN PS_LBNL_MX_PROJECT.PROJECT_ID%TYPE,
            PASS_ID_I     IN VARCHAR2)
   RETURN PS_LBNL_MX_PROJECT.LBNL_MX_TRANS_CODE%TYPE;

END;

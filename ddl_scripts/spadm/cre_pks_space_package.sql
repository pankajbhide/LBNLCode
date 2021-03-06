-- Start of DDL Script for Package SPADM.SPACE_PACKAGE
-- Generated 21-Sep-2017 11:33:58 from SPADM@MMOPRD

CREATE OR REPLACE 
PACKAGE space_package IS

--******************************************
--
--  PACKAGE SPECIFICATIONS : SPACE_PACKAGE
--
--  CONNECT SPADM@MMOXXX 
--*****************************************

/* PROCEDURE TO GET THE DOMAIN DESCRIPTION FOR ALN DOMAIN */

FUNCTION GET_ALNDOMAIN_DESC(DOMAINID_I IN maximo.ALNDOMAIN.DOMAINID%TYPE,
                            VALUE_I    IN maximo.ALNDOMAIN.VALUE%TYPE)
                            RETURN maximo.ALNDOMAIN.DESCRIPTION%TYPE;

/* PROCEDURE TO GET BUILDING INFORMATION */

PROCEDURE GET_BUILDING_DETAILS(BUILDING_NUMBER_I    IN  SPADM.SPACE_BUILDING.BUILDING_NUMBER%TYPE,
                               BUILDING_RECORD_O   OUT  SPADM.SPACE_BUILDING%ROWTYPE);

/* PROCEDURE TO GET FLOOR INFORMATION */

PROCEDURE GET_FLOOR_DETAILS(BUILDING_NUMBER_I IN  SPADM.SPACE_FLOOR.BUILDING_NUMBER%TYPE,
                            FLOOR_NUMBER_I    IN  SPADM.SPACE_FLOOR.FLOOR_NUMBER%TYPE,
                            FLOOR_RECORD_O    OUT SPADM.SPACE_FLOOR%ROWTYPE);

/* PROCEDURE TO GET ROOM INFORMATION */

PROCEDURE GET_ROOM_DETAILS(BUILDING_NUMBER_I    IN SPADM.SPACE_ROOM.BUILDING_NUMBER%TYPE,
                           FLOOR_NUMBER_I       IN SPADM.SPACE_ROOM.FLOOR_NUMBER%TYPE,
                           ROOM_NUMBER_I        IN SPADM.SPACE_ROOM.FLOOR_NUMBER%TYPE,
                           ROOM_RECORD_O        OUT SPADM.SPACE_ROOM%ROWTYPE);

/* PROCEDURE TO GET NAME OF PROJECT */
FUNCTION GET_PROJECT_NAME(PROJECT_ID_I  IN  maximo.lbl_v_coa.glaccount%TYPE)
                           RETURN maximo.lbl_v_coa.accountname%TYPE;

/* PROCEDURE TO GET DESCRIPTION OF ORGANIZATION LEVEL */
FUNCTION GET_LEVEL_DESC (LEVEL1_I  IN SPADM.SPACE_ROOM.ORG_LEVEL_1_CODE%TYPE,
                         LEVEL2_I  IN SPADM.SPACE_ROOM.ORG_LEVEL_2_CODE%TYPE,
                         LEVEL3_I  IN SPADM.SPACE_ROOM.ORG_LEVEL_3_CODE%TYPE,
                         LEVEL4_I  IN SPADM.SPACE_ROOM.ORG_LEVEL_4_CODE%TYPE,
                         LEVEL_NUMBER_I IN NUMBER)
                         RETURN EDW_SHARE.ORG_DEPARTMENT.DESCR%TYPE;

FUNCTION FORMAT_STR(STR_I IN VARCHAR2,
                    NO_OF_DIGITS_I IN NUMBER)
                    RETURN VARCHAR2;


/* FUNCTION TO PREPARE LOCATION CODE */
FUNCTION PREPARE_LOCATION(BUILDING_NUMBER_I   IN  SPADM.SPACE_ROOM.BUILDING_NUMBER%TYPE,
                          FLOOR_NUMBER_I      IN  SPADM.SPACE_ROOM.FLOOR_NUMBER%TYPE,
                          ROOM_NUMBER_I       IN  SPADM.SPACE_ROOM.ROOM_NUMBER%TYPE)
                          RETURN LOCATIONS.LOCATION%TYPE;

/* FUNCTION TO GET THE NEXT NUMBER FOR LDKEY USED IN LONGDESCRIPTION TABLE */
FUNCTION GET_LDKEY RETURN NUMBER;

/* FUNCTION TO GET THE LONG DESCRIPTION TEXT FROM LONGDESCRIPTION TABLE */
FUNCTION GET_LDTEXT(LDKEY_I  IN LONGDESCRIPTION.LDKEY%TYPE,
                    LDOWNERTABLE_I  IN LONGDESCRIPTION.LDOWNERTABLE%TYPE,
                    LDOWNERCOL_I    IN LONGDESCRIPTION.LDOWNERCOL%TYPE)
                    RETURN VARCHAR2;  -- FOR ORACLLE FORMS COMPATIBILITY (MXES) 
                    --RETURN LONGDESCRIPTION.LDTEXT%TYPE;

/* INSERT INTO MAXIMO TABLES */
PROCEDURE INSERT_LOCATION_TABLES(LOCATION_I IN LOCATIONS.LOCATION%TYPE,
                                 PARENT_I       IN LOCHIERARCHY.PARENT%TYPE,
                                 LDKEY_I        IN LONGDESCRIPTION.LDKEY%TYPE,
                                 LDTEXT_I   IN LONGDESCRIPTION.LDTEXT%TYPE,
                                 CHANGEBY_I IN LOCATIONS.CHANGEBY%TYPE);

/* PROCEDURE TO INSERT BUILDING DETAILS INTO THE TABLES OTHER THAN THE
   BASE VIEW */
PROCEDURE INSERT_BUILDING(BUILDING_NUMBER_I IN SPADM.SPACE_BUILDING.BUILDING_NUMBER%TYPE,
                          LOCALITY_I        IN SPADM.SPACE_BUILDING.LOCALITY%TYPE,
                          NO_OF_FLOORS_I    IN NUMBER,
                          LDKEY_I           IN LONGDESCRIPTION.LDKEY%TYPE,
                          LDTEXT_I          IN VARCHAR2,  -- FORMS COMAPATIBILITY  (MXES) 
                          --LDTEXT_I          IN LONGDESCRIPTION.LDTEXT%TYPE,
                          INACTIVE_I        IN SPADM.SPACE_BUILDING.INACTIVE%TYPE,
                          CHANGEBY_I        IN LOCATIONS.CHANGEBY%TYPE);
/* PROCEDURE TO INSERT FLOOR DETAILS INTO THE TABLES OTHER THAN THE
   BASE VIEW */
PROCEDURE INSERT_FLOOR(BUILDING_NUMBER_I IN SPADM.SPACE_FLOOR.BUILDING_NUMBER%TYPE,
                       FLOOR_NUMBER_I    IN SPADM.SPACE_FLOOR.FLOOR_NUMBER%TYPE,  
                       INACTIVE_I        IN SPADM.SPACE_FLOOR.INACTIVE%TYPE,
                       LEVEL_NUMBER_I    IN SPADM.SPACE_FLOOR.LEVEL_NUMBER%TYPE,
                       CHANGEBY_I        IN LOCATIONS.CHANGEBY%TYPE);



/* PROCEDURE TO INSERT ROOM DETAILS INTO THE TABLES OTHER THAN THE BASE VIEW */
PROCEDURE INSERT_ROOM(BUILDING_NUMBER_I IN  SPADM.SPACE_ROOM.BUILDING_NUMBER%TYPE,
                      FLOOR_NUMBER_I    IN SPADM.SPACE_ROOM.FLOOR_NUMBER%TYPE,
                      ROOM_NUMBER_I     IN SPADM.SPACE_ROOM.ROOM_NUMBER%TYPE,
                      LDKEY_I           IN LONGDESCRIPTION.LDKEY%TYPE,
                      LDTEXT_I          IN VARCHAR2, -- FORMS COMPATIBILITY (MXES) 
                      --LDTEXT_I          IN LONGDESCRIPTION.LDTEXT%TYPE,
                      INACTIVE_I        IN SPADM.SPACE_ROOM.INACTIVE%TYPE,
                      CHANGEBY_I        IN LOCATIONS.CHANGEBY%TYPE);

/* GET DEFAULT PROJECT FOR LEVEL1 ORG UNIT (DIVISION) */
FUNCTION GET_DEFAULT_PROJECT(LEVEL1_I      IN  SPADM.SPACE_ROOM.ORG_LEVEL_1_CODE%TYPE)
                             RETURN MAXIMO.LBL_V_COA.GLACCOUNT%TYPE;

/* PROCEDURE TO INSERT DEFAULT PROJECT WITH 100% FOR A ROOM */
PROCEDURE INSERT_DEFAULT_PROJECT(BUILDING_NUMBER_I IN SPADM.SPACE_ROOM.BUILDING_NUMBER%TYPE,
           FLOOR_NUMBER_I    IN SPADM.SPACE_ROOM.FLOOR_NUMBER%TYPE,
           ROOM_NUMBER_I     IN SPADM.SPACE_ROOM.ROOM_NUMBER%TYPE,
           LOCATION_I        IN LOCATIONS.LOCATION%TYPE,
       LEVEL1_I          IN SPADM.SPACE_ROOM.ORG_LEVEL_1_CODE%TYPE);

/* GET CURRENT RECHRAGE RATE FOR CURRENT USE AND REPORT_CATEGORY */

FUNCTION GET_RECHARGE_RATE(CURRENT_USE_I IN SPACE_CHARGE_RATE.CURRENT_USE%TYPE,
                           REPORT_CATEGORY_I IN SPACE_CHARGE_RATE.REPORT_CATEGORY%TYPE)
                           RETURN SPACE_CHARGE_RATE.RECHARGE_RATE%TYPE;

/* DECLARATIONS USEFUL FOR GETTING THE SPACE RECHARGE

TYPE SPACE_CHARGE_REC IS RECORD (
     PROJECT_ID       EDW_SHARE.PV_PROJECT.PROJECT_ID%TYPE,
     RECHARGE_AMOUNT  SPADM.SPACE_CHARGE_TRANS.RECHARGE_AMOUNT%TYPE);

TYPE SPACE_CHARGE_TABLE IS TABLE OF SPACE_CHARGE_REC INDEX BY BINARY_INTEGER;

/* PROCEDURE TO GET RECHARGE AMOUNT FOR THE SPECIFIED BUILDING/FLOOR/ROOM AND
   PERIOD. THIS PROCEDURE RETURNS TABLE OF ROW CONTAINING PROJECT_ID AND
   RE-CHARGE AMOUNT

PROCEDURE GET_RECHARGE_AMOUNT(BUILDING_NUMBER_I   IN   SPADM.SPACE_ROOM.BUILDING_NUMBER%TYPE,
                              FLOOR_NUMBER_I      IN   SPADM.SPACE_ROOM.FLOOR_NUMBER%TYPE,
                              ROOM_NUMBER_I       IN   SPADM.SPACE_ROOM.ROOM_NUMBER%TYPE,
                              PERIOD_DATE_I       IN   SPADM.SPACE_CHARGE_TRANS.TRANSACTION_DATE%TYPE,
                              SPACE_CHARGE_TBL_O  OUT  SPACE_CHARGE_TABLE); */


FUNCTION PREPARE_OLD_LOCATION(BUILDING_NUMBER_I   IN  SPADM.SPACE_ROOM.BUILDING_NUMBER%TYPE,
                              FLOOR_NUMBER_I      IN  SPADM.SPACE_ROOM.FLOOR_NUMBER%TYPE,
                  ROOM_NUMBER_I       IN  SPADM.SPACE_ROOM.ROOM_NUMBER%TYPE)
                              RETURN LOCATIONS.LOCATION%TYPE;

FUNCTION GET_EMPLOYEE_NAME(EMPLOYEE_ID_I  IN EDW_SHARE.PEOPLE_CURRENT.EMPLOYEE_ID%TYPE)
                           RETURN EDW_SHARE.PEOPLE_CURRENT.EMPLOYEE_NAME%TYPE;

FUNCTION IS_ALPHA_NUMERIC(STRING_I IN SPADM.SPACE_ROOM.DIVISION_COMMENTS%TYPE)
                           RETURN BOOLEAN;
/*
TYPE OCCUPANT_RECORD IS RECORD (
     EMPLOYEE_NAME    SPADM.SPACE_ROOM.DIVISION_COMMENTS%TYPE,
     EMPLOYEE_DETAILS SPADM.SPACE_ROOM.DIVISION_COMMENTS%TYPE,
     BUILDING_NUMBER  HRADM.PS_ZZ_WRK_LOCATION.ZZ_BLDG%TYPE,
     ROOM_NUMBER      HRADM.PS_ZZ_WRK_LOCATION.ZZ_ROOM%TYPE);

TYPE OCCUPANT_REF_CUR IS REF CURSOR RETURN OCCUPANT_RECORD;
*/
-- PROCEDURE TO RETURN OCCUPANT DETAILS INTO THE REF CURSOR

/*PROCEDURE GET_OCCUPANT_DETAIL(OCC_RESULTSET  IN OUT OCCUPANT_REF_CUR,
                              BUILDING_NUMBER_I IN SPADM.SPACE_ROOM.BUILDING_NUMBER%TYPE,
                  ROOM_NUMBER_I     IN SPADM.SPACE_ROOM.ROOM_NUMBER%TYPE); */

TYPE TEAM_RECORD IS RECORD (
     EMPLID             varchar2(50),
     TEAM_MEMBER        varchar2(50),
     PROJECT_ID         varchar2(50));

TYPE TEAM_REF_CUR IS REF CURSOR RETURN TEAM_RECORD;

PROCEDURE GET_PI_CONTACT_DETAIL(TEAM_RESULTSET IN OUT TEAM_REF_CUR,
                        TYPE_I  SPADM.SPACE_ROOM.CURRENT_USE_DETAIL%TYPE,
                        PROJECT_ID_I   IN SPADM.SPACE_CHARGE_DISTRIBUTION.PROJECT_ID%TYPE);

FUNCTION GET_PERIOD_TYPE(YY_I IN SPADM.SPACE_CHARGE_TRANS.FISCAL_YEAR%TYPE,
                         MM_I IN SPADM.SPACE_CHARGE_TRANS.ACCOUNTING_PERIOD%TYPE)
             RETURN  SPADM.SPACE_ROOM.SPACE_TYPE%TYPE;

FUNCTION GET_PERIOD_DATE(YY_I IN SPADM.SPACE_CHARGE_TRANS.FISCAL_YEAR%TYPE,
                         MM_I IN SPADM.SPACE_CHARGE_TRANS.ACCOUNTING_PERIOD%TYPE,
             TYPE_I IN SPADM.SPACE_ROOM.SPACE_TYPE%TYPE)
                         RETURN DATE;

PROCEDURE TBL_INIT(BUILDING_NUMBER_I IN SPACE_CHARGE_DISTRIBUTION.BUILDING_NUMBER%TYPE,
          FLOOR_NUMBER_I    IN SPACE_CHARGE_DISTRIBUTION.FLOOR_NUMBER%TYPE,
          ROOM_NUMBER_I     IN SPACE_CHARGE_DISTRIBUTION.ROOM_NUMBER%TYPE,
          CHANGEBY_I        IN SPACE_CHARGE_DISTRIBUTION.CHANGEBY%TYPE);

PROCEDURE TBL_ADD(BUILDING_NUMBER_I IN SPACE_CHARGE_DISTRIBUTION.BUILDING_NUMBER%TYPE,
          FLOOR_NUMBER_I    IN SPACE_CHARGE_DISTRIBUTION.FLOOR_NUMBER%TYPE,
          ROOM_NUMBER_I     IN SPACE_CHARGE_DISTRIBUTION.ROOM_NUMBER%TYPE,
          PROJECT_ID_I      IN SPACE_CHARGE_DISTRIBUTION.PROJECT_ID%TYPE,
          CHARGED_TO_PERCENT_I IN SPACE_CHARGE_DISTRIBUTION.CHARGED_TO_PERCENT%TYPE,
          CHANGEBY_I        IN SPACE_CHARGE_DISTRIBUTION.CHANGEBY%TYPE);

PROCEDURE TBL_UPD(BUILDING_NUMBER_I IN SPACE_CHARGE_DISTRIBUTION.BUILDING_NUMBER%TYPE,
          FLOOR_NUMBER_I       IN SPACE_CHARGE_DISTRIBUTION.FLOOR_NUMBER%TYPE,
          ROOM_NUMBER_I        IN SPACE_CHARGE_DISTRIBUTION.ROOM_NUMBER%TYPE,
          PROJECT_ID_I         IN SPACE_CHARGE_DISTRIBUTION.PROJECT_ID%TYPE,
          CHARGED_TO_PERCENT_I IN SPACE_CHARGE_DISTRIBUTION.CHARGED_TO_PERCENT%TYPE,
          CHANGEBY_I        IN SPACE_CHARGE_DISTRIBUTION.CHANGEBY%TYPE);

PROCEDURE TBL_DELETE(
          BUILDING_NUMBER_I IN SPACE_CHARGE_DISTRIBUTION.BUILDING_NUMBER%TYPE,
          FLOOR_NUMBER_I    IN SPACE_CHARGE_DISTRIBUTION.FLOOR_NUMBER%TYPE,
          ROOM_NUMBER_I     IN SPACE_CHARGE_DISTRIBUTION.ROOM_NUMBER%TYPE,
          PROJECT_ID_I      IN SPACE_CHARGE_DISTRIBUTION.PROJECT_ID%TYPE,
          CHARGED_TO_PERCENT_I IN SPACE_CHARGE_DISTRIBUTION.CHARGED_TO_PERCENT%TYPE,
          CHANGEBY_I        IN SPACE_CHARGE_DISTRIBUTION.CHANGEBY%TYPE);

FUNCTION  TBL_CHECK(
          BUILDING_NUMBER_I IN SPACE_CHARGE_DISTRIBUTION.BUILDING_NUMBER%TYPE,
          FLOOR_NUMBER_I    IN SPACE_CHARGE_DISTRIBUTION.FLOOR_NUMBER%TYPE,
          ROOM_NUMBER_I     IN SPACE_CHARGE_DISTRIBUTION.ROOM_NUMBER%TYPE,
          PROJECT_ID_I      IN SPACE_CHARGE_DISTRIBUTION.PROJECT_ID%TYPE,
          CHANGEBY_I        IN SPACE_CHARGE_DISTRIBUTION.CHANGEBY%TYPE)
          RETURN BOOLEAN;
            
          
FUNCTION LBL_LONG_TO_CLOB (
          LONG_I LONG)
         RETURN CLOB;
         
FUNCTION LBL_VARCHAR_TO_CLOB(
         VARCHAR_I VARCHAR2)
          RETURN CLOB;

FUNCTION LBL_CLOB_TO_LONG(
         CLOB_I CLOB)
          RETURN LONG;                        
          
FUNCTION INS_UPD_LONGDESCRIPTION(
          LDKEY_I           IN NUMBER,
          LDTEXT_I          IN VARCHAR2,
          LOCATION_I        IN LOCATIONS.LOCATION%TYPE)
          RETURN VARCHAR2 ;               

/*
PRAGMA RESTRICT_REFERENCES (GET_ALNDOMAIN_DESC, WNDS,RNPS,WNPS);
PRAGMA RESTRICT_REFERENCES (GET_PROJECT_NAME, WNDS);
PRAGMA RESTRICT_REFERENCES (GET_LEVEL_DESC, WNDS,RNPS,WNPS);
PRAGMA RESTRICT_REFERENCES (FORMAT_STR, WNDS,RNPS,WNPS);
PRAGMA RESTRICT_REFERENCES (PREPARE_LOCATION, WNDS,RNPS,WNPS);
PRAGMA RESTRICT_REFERENCES (GET_LDKEY, WNDS,RNPS,WNPS);
PRAGMA RESTRICT_REFERENCES (GET_LDTEXT, WNDS,RNPS,WNPS);
PRAGMA RESTRICT_REFERENCES (GET_DEFAULT_PROJECT, WNDS,RNPS,WNPS);
PRAGMA RESTRICT_REFERENCES (GET_RECHARGE_RATE, WNDS,RNPS,WNPS);
PRAGMA RESTRICT_REFERENCES (PREPARE_OLD_LOCATION, WNDS,RNPS,WNPS);
PRAGMA RESTRICT_REFERENCES (GET_EMPLOYEE_NAME, WNDS,RNPS,WNPS);
PRAGMA RESTRICT_REFERENCES (IS_ALPHA_NUMERIC, WNDS,RNPS,WNPS);
PRAGMA RESTRICT_REFERENCES (INSERT_DEFAULT_PROJECT,RNPS,WNPS);
PRAGMA RESTRICT_REFERENCES (INSERT_LOCATION_TABLES,RNPS,WNPS);
PRAGMA RESTRICT_REFERENCES (INSERT_BUILDING,RNPS,WNPS);
PRAGMA RESTRICT_REFERENCES (INSERT_ROOM,RNPS,WNPS);
PRAGMA RESTRICT_REFERENCES (GET_OCCUPANT_DETAIL,WNDS,RNPS,WNPS);
PRAGMA RESTRICT_REFERENCES (GET_PI_CONTACT_DETAIL,WNDS,RNPS,WNPS);
PRAGMA RESTRICT_REFERENCES (GET_PERIOD_TYPE,WNDS,RNPS,WNPS);
PRAGMA RESTRICT_REFERENCES (GET_PERIOD_DATE,WNDS,RNPS,WNPS);
PRAGMA RESTRICT_REFERENCES (TBL_CHECK,WNDS,RNPS,WNPS); */


END;
/

-- Grants for Package
GRANT EXECUTE ON space_package TO public
/


-- End of DDL Script for Package SPADM.SPACE_PACKAGE


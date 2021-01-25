CREATE OR REPLACE PACKAGE lbl_maximo_misc_pkg
IS
 FUNCTION GET_LAST_STATUS(
          ORGID_I  IN MAXIMO.WORKORDER.ORGID%TYPE,
          SITEID_I IN MAXIMO.WORKORDER.SITEID%TYPE,
          WONUM_I  IN MAXIMO.WORKORDER.WONUM%TYPE,
          STATUS_I IN MAXIMO.WOSTATUS.STATUS%TYPE)
          RETURN MAXIMO.WORKORDER.STATUS%TYPE;


FUNCTION GET_ALNDOMAIN_DESC(DOMAINID_I IN ALNDOMAIN.DOMAINID%TYPE,
                            ALNVALUE_I IN ALNDOMAIN.VALUE%TYPE)
                            RETURN ALNDOMAIN.DESCRIPTION%TYPE;

FUNCTION GET_FINANCIALPERIOD( TRANSDATE_I IN FINANCIALPERIODS.PERIODSTART%TYPE)
                              RETURN FINANCIALPERIODS.FINANCIALPERIOD%TYPE;
--**********************************************************************
-- FUNCTION TO FIND OUT WHETHER THE LOCATION CONTAINS ANY HAZARD WHIC IS
-- LISTED IN WORK CONTROL HAZARDS TEMPLATE SAFETYPLAN
--**********************************************************************
FUNCTION CHECK_HAZ_IN_SFPLAN(SITEID_I IN WORKORDER.siteid%TYPE,
                             LOCATION_I IN WORKORDER.LOCATION%TYPE)
                             RETURN NUMBER;
--****************************************************************
-- FUNCTION TO POPULATE THE HAZARDS/PRECUATIONS TO THE WORK ORDER
-- WHICH ARE ASSOCIATED WITH THE LOCATIONS OR AS PER THE VALUE
-- SPECIFIED ON THE WORK CONTROL HAZARD
--****************************************************************

FUNCTION POPULATE_WOHAZARDS(ORGID_I IN WORKORDER.ORGID%TYPE,
                            SITEID_I IN WORKORDER.siteid%TYPE,
                            WONUM_I IN WORKORDER.wonum%TYPE,
                            LOCATION_I IN WORKORDER.LOCATION%TYPE,
                            COPY_FROM_SF_I VARCHAR2,
                            LBL_WCNTRHAZARD_I IN WORKORDER.LBL_WORKCNTRHAZARD%TYPE)
                           RETURN VARCHAR2;
--*********************************************************************
-- FUNCTION TO CHECK WHTHER LOCATION HAZARDS HAVE BEEN INSERTED OR NOT
--*********************************************************************
FUNCTION WOHAZARDS_EXIST(ORGID_I IN WORKORDER.ORGID%TYPE,
                         SITEID_I IN WORKORDER.siteid%TYPE,
                         WONUM_I IN WORKORDER.wonum%TYPE)
                        RETURN NUMBER;

PRAGMA RESTRICT_REFERENCES (GET_LAST_STATUS, WNDS,RNPS,WNPS);

END;

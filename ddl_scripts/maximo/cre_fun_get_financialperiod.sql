CREATE OR REPLACE FUNCTION GET_FINANCIALPERIOD
  ( TRANSDATE_I IN MATUSETRANS.TRANSDATE%TYPE)
  RETURN   FINANCIALPERIODS.FINANCIALPERIOD%TYPE

  IS
--
--****************************************************
-- START OF DDL SCRIPT FOR FUNCTION GET_FINANCIALPERIOD
-- -----------------------------------------------------


-- PURPOSE: THIS FUNCTION RETURNS FINANCIALPERIOD BASED ON
--          THE TRANSACTION DATE PASSED TO THE FUNCTION
--
-- MODIFICATION HISTORY
-- PERSON      DATE    COMMENTS
-- ---------   ------  -------------------------------------------

  -- DECLARE PROGRAM VARIABLES AS SHOWN ABOVE
  FINANCIALPERIOD_T FINANCIALPERIODS.FINANCIALPERIOD%TYPE;

BEGIN

 BEGIN

 SELECT A.FINANCIALPERIOD
 INTO  FINANCIALPERIOD_T
 FROM   FINANCIALPERIODS A
 WHERE  A.ORGID='LBNL'
 AND    TRANSDATE_I >= A.PERIODSTART
 AND    TRANSDATE_I <  A.PERIODEND;

EXCEPTION
   WHEN OTHERS THEN
       RETURN NULL;
  END;

    RETURN FINANCIALPERIOD_T ;

END;

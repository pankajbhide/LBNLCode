/************************************************************
 * PROGRAM NAME: UPDTPERD.SQL                               *
 *                                                          *
 * DESCRIPTION : THIS PROGRAM UPDATES THE FINANACIALPERIODS *
 *               TABLE AFTER SENDING THE GL FEEDER RECORDS  *
 *               TO THE GENERAL LEDGER.                     *
 *               IT CLOSES THE FINANCIAL PERIOD SO THAT THE *
 *               USERS CAN NOT CHARGE THE TIME TO THAT      *
 *               PERIOD.
 *                                                          *
 *               THE PROGRAM ACCEPTS THE FINANCIALPERIOD    *
 *               THAT NEEDS TO BE CLOSED AND THE FEEDER TYPE*
 *                                                          *
 * DATE WRITTEN: 17-DEC-2002                                *
 *                                                          *
 * MODIFICATION                                             *
 * HISTORY     :  10-MAR-2006 PANKAJ CHANGED THE CRITERIA   *
 *                TO FIND OUT THE CANDIDATE ACCOUNTING PERIOD * 
 *                WHICH CAN BE CHANGED.                     *
 *                                                          *
 *                26-MAR-2009 PANKAJ-MINOR MODIFICATIONS FOR*
 *                MXES                                      * 
 ************************************************************/
WHENEVER SQLERROR EXIT 1 ROLLBACK;

SET ECHO OFF
SET VERIFY OFF

DECLARE
    FINANCIALPERIOD_T  FINANCIALPERIODS.FINANCIALPERIOD%TYPE;
    RETURN_T VARCHAR2(1);
    ORGID_T  FINANCIALPERIODS.orgid%TYPE;
BEGIN
  
       -- MXES 
    ORGID_T   :=UPPER('&2');
    
   
    IF (ORGID_T IS NULL OR LENGTH(ORGID_T)=0) THEN
       ORGID_T :='LBNL';
    END IF;
     
   
    -- GET THE LATEST FINANCIAL PERIOD

    SELECT FINANCIALPERIOD INTO FINANCIALPERIOD_T
    FROM MAXIMO.FINANCIALPERIODS
    WHERE FINANCIALPERIOD=(SELECT MIN(C.FINANCIALPERIOD)
    FROM MAXIMO.FINANCIALPERIODS C WHERE
    (NVL(C.CLOSEDBY,' ') NOT LIKE '%&1%') AND C.ORGID=ORGID_T)
    AND ORGID=ORGID_T;

    RETURN_T := MAXIMO.LBNL_UPDT_PACKAGE.UPDATE_FEEDER_CLOSE(FINANCIALPERIOD_T,'&1','&2');

 EXCEPTION
  WHEN OTHERS THEN
     NULL;
END;

/

COMMIT;

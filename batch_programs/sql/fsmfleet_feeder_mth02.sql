REM ************************************************************************
REM
REM     NAME               : FLEET_FEEDER_MTH02.SQL
REM
REM     AUTHOR             : PANKAJ
REM
REM     DATE               : 12/21/00
REM
REM     DESCRIPTION        : THIS REPORT GENERATES REPORT SHOWING THE FLEET
REM                          RECHARGES SENT TO FMS
REM
REM     AUTHOR             : PANKAJ BHIDE
REM
REM     MODIFICATION
REM     HISTORY            : 12/13/02 PANKAJ - MODIFIED TO TAKE CARE OF THE
REM                          ACCELERATED GL CLOSE.
REM        
REM                          12/21/04 PANKAJ - ADDED CONDITION INVOICENUM=FLEET
REM
REM                          03/30/08 PANKAJ - CHANGES REQUIRED FOR MXES 
REM
REM ************************************************************************
SET HEADSEP !
SET HEADING ON
SET FEEDBACK OFF
SET TERMOUT OFF
SET VERIFY OFF

COLUMN TODAY   NEW_VALUE XTODAY NOPRINT
COLUMN FISCAL_YEAR NEW_VALUE      XFISCAL_YEAR NOPRINT
COLUMN ACCOUNTING_PERIOD  NEW_VALUE XACCOUNTING_PERIOD NOPRINT

TTITLE LEFT    'RUN DATE:' XTODAY    -
       CENTER  'LAWRENCE BERKELEY LABORATORY'  -
       RIGHT   'PAGE: ' FORMAT 999 SQL.PNO    SKIP 1 -
       CENTER  'FLEET RECHARGES SENT TO GENERAL LEDGER' SKIP 1 -
       CENTER  'FISCAL YEAR: ' XFISCAL_YEAR '  ACCOUNTING PERIOD: ' XACCOUNTING_PERIOD SKIP 2

CLEAR BREAKS
CLEAR COMPUTES

COLUMN GLDEBITACCT        HEADING 'PROJECT!ACTIVITY ID'        FORMAT A15
COLUMN ASSETNUM            HEADING 'LICENSE!NUMBER'    FORMAT A11
COLUMN DESCRIPTION        HEADING 'DESCRIPTION'       FORMAT A25
COLUMN LINECOST           HEADING 'RECHARGE!AMOUNT'   FORMAT 999999.99 JUSTIFY RIGHT
COLUMN PROJECT_OVERRIDE   HEADING 'DROPOUT ACCT!CHARGED'     FORMAT A13 JUSTIFY CENTER

BREAK ON GLDEBITACCT SKIP 1  NODUPLICATES
COMPUTE SUM OF LINECOST ON GLDEBITACCT

SET LINESIZE 79
SET PAGESIZE 50
SET NEWPAGE 0

SPOOL fl_recharge

SELECT  A.GLDEBITACCT,
        A.ASSETNUM,
        SUBSTR(C.DESCRIPTION,1,30) DESCRIPTION,
        A.LINECOST,
        SUBSTR(B.FINANCIALPERIOD,1,4) FISCAL_YEAR,
        SUBSTR(B.FINANCIALPERIOD,5,2) ACCOUNTING_PERIOD,
        DECODE(A.ICT1,'Y','    Yes    ','')  PROJECT_OVERRIDE,
        SYSDATE TODAY
FROM MAXIMO.INVOICECOST A, MAXIMO.INVOICELINE C,MAXIMO.INVOICE B
WHERE  A.ORGID=B.ORGID
AND    A.SITEID=B.SITEID
AND    A.ORGID=C.ORGID
AND    A.SITEID=C.SITEID
AND    A.ORGID='&1'
AND    A.SITEID='&2'
AND    A.INVOICENUM=B.INVOICENUM
AND    A.INVOICENUM=C.INVOICENUM
AND    A.INVOICELINENUM=C.INVOICELINENUM
AND    B.INVOICENUM LIKE 'FLEET%'    -- 12/21/04
AND    TRUNC(B.INVOICEDATE)=(SELECT TRUNC(X.PERIODEND-1)
FROM   FINANCIALPERIODS X
WHERE  X.ORGID='&1'
AND    X.FINANCIALPERIOD=(SELECT MIN(Y.FINANCIALPERIOD) FROM FINANCIALPERIODS Y
WHERE  NVL(Y.CLOSEDBY,' ') NOT LIKE '%MOT%' AND Y.orgid='&1'))
ORDER BY 1,2;

SPOOL OFF;

/

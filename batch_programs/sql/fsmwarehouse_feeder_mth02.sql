REM ************************************************************************
REM
REM     NAME               : WAREHOUSE_FEEDER_MTH02.SQL
REM
REM     AUTHOR             : PANKAJ
REM
REM     DATE               : 09-MAY-2012
REM
REM     DESCRIPTION        : THIS REPORT GENERATES REPORT SHOWING THE WAREHOUSE 
REM                          RECHARGES SENT TO FMS
REM
REM     AUTHOR             : PANKAJ BHIDE
REM
REM     MODIFICATION
REM     HISTORY            : 
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
       CENTER  'WAREHOUSE RECHARGES SENT TO GENERAL LEDGER' SKIP 1 -
       CENTER  'FISCAL YEAR: ' XFISCAL_YEAR '  ACCOUNTING PERIOD: ' XACCOUNTING_PERIOD SKIP 2

CLEAR BREAKS
CLEAR COMPUTES

COLUMN GLDEBITACCT        HEADING 'PROJECT!ACTIVITY ID'        FORMAT A15
COLUMN DESCRIPTION        HEADING 'DESCRIPTION'       FORMAT A35
COLUMN DIVISION           HEADING 'DIVION'            FORMAT A4
COLUMN LINECOST           HEADING 'RECHARGE!AMOUNT'   FORMAT 999999.99 JUSTIFY RIGHT
COLUMN PROJECT_OVERRIDE   HEADING 'DROPOUT ACCT!CHARGED'     FORMAT A13 JUSTIFY CENTER

BREAK ON GLDEBITACCT SKIP 1  NODUPLICATES
COMPUTE SUM OF LINECOST ON GLDEBITACCT

SET LINESIZE 79
SET PAGESIZE 50
SET NEWPAGE 0

SPOOL warehouse_recharge

SELECT  A.GLDEBITACCT,
        SUBSTR(C.DESCRIPTION,1,35) DESCRIPTION,
        SUBSTR(trim(ltrim(a.memo,'DIV:')),1,4) DIVISION, 
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
AND    B.INVOICENUM LIKE 'WAREHOUSE%'    
AND    TRUNC(B.INVOICEDATE)=(SELECT TRUNC(X.PERIODEND-1)
FROM   FINANCIALPERIODS X
WHERE  X.ORGID='&1'
AND    X.FINANCIALPERIOD=(SELECT MIN(Y.FINANCIALPERIOD) FROM FINANCIALPERIODS Y
WHERE  NVL(Y.CLOSEDBY,' ') NOT LIKE '%STR%' AND Y.orgid='&1'))
ORDER BY 1,2;

SPOOL OFF;

/

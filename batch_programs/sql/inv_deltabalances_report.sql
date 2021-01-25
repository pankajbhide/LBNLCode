rem  **************************************************************************************
rem  Program Name: inv_deltabalances_report.sql
rem  Written by:   Pankaj Bhide
rem  Last Update:  3/31/2009
rem  Description:  This report display display the table lbl_archive.lbl_deltabalances. The 
rem                table lbl_deltabalances contain all the inventory items that has a "delta"
rem                in the Maximo recored current balances and the balances derived from the 
rem                opening balances after the receipt, issue, adjustments. These items number
rem                will be reconciled. The output of this report is saved into a file call
rem                lbl_deltabalances.txt, which is mailed to the serveral people whose name
rem                are specified in a environment input text file.
rem  ****************************************************************************************
spool inv_deltabalances_report

column Today NEW_VALUE xTODAY noprint format a1 trunc

ttitle left  'Run Date:    ' xTODAY skip 1 'Report Name: lbl_deltabalances_report' -
       right 'Page: ' format 9 sql.pno skip 2 -
       center 'Inconsistencies Found in Inventory Balances and Calculated Balances' skip1 -
       center '(Units)' skip 3

btitle  left 'The balances shown in ''CLOSE BAL'' are the balances cecorded in MAXIMO.' skip 1 'The balances shown in ''CALC BAL'' should be the actual balances.'


set linesize 75
set pagesize 40

rem Alias some column name to save space

set heading on
column ITEMNUM heading 'ITEM|NUMBER' format a10
column LOCATION heading 'LOC' format a3
column OPENING_BALANCE heading 'OPEN|BAL' format 999999 
column RECEIPT_QTY heading 'RECEIPT|(RTV)' format 999999
column ISSUE_QTY heading 'RETURN|(ISSUE)' format 999999
column OVERAGE heading 'OVER' format 999999
column SHORTAGE heading 'SHORT' format 999999
column CLOSING_BALANCE heading 'CLOSE|BAL' format 999999
column CALC_UNITS heading 'CALC|BAL' format 999999

select    ITEMNUM, LOCATION, OPENING_BALANCE, RECEIPT_QTY, ISSUE_QTY, OVERAGE, SHORTAGE, CLOSING_BALANCE, CALC_UNITS, to_char(SYSDATE, 'MM/DD/YYYY HH:mm') Today
from      BATCH_MAXIMO.LBL_DELTABALANCES
WHERE     ORGID='&1'
and       SITEID='&2'
order by  ITEMNUM, COPIED_DATE;

spool off

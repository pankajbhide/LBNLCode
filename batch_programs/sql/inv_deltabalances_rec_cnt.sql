rem  **************************************************************************************
rem  Program Name: inv_deltabalances_rec_cnt.sql
rem  Written by:   Pankaj Bhide
rem  Last Update:  3/30/2009    
rem  Description:  This report get total line count in the batch_maximo.lbl_deltabalances 
rem                table.
rem                The output file is used to determine whether to run a report on the data 
rem                in this table or not.
rem  ****************************************************************************************
SET HEADING OFF
SET FEEDBACK OFF
SET TERMOUT OFF
SET ECHO OFF
SET PAGESIZE 0
SET SPACES 0
SET NEWPAGE 0
SET LINESIZE 10
SET VERIFY OFF

spool inv_deltabalances_rec_cnt

select ltrim(to_char(count(*))) from batch_maximo.lbl_deltabalances 
where  orgid='&1' and siteid='&2';

spool off

-- connect to batch_maximo@mmoxxx

drop table lbl_max2catsemail;

create table lbl_max2catsemail
( externalrefid varchar2(100),
  wonum         varchar2(15),
  description   varchar2(500),
  row_id        varchar2(100),
  datecopied    varchar2(50),
  siteid        varchar2(8), 
  orgid         varchar2(8), 
  reportedby    varchar2(50),
  status        varchar2(100),
  status_desc   varchar2(500));
  
grant all on lbl_max2catsemail to public;

drop table lbl_max2catsinfo;

create table lbl_max2catsinfo
(   DESCRIPTION varchar2(2000),
    REPORTEDBY varchar2(2000),
    LOCATION varchar2(2000),
    UNPARSEDLOCATION varchar2(2000),
    GLACCOUNT varchar2(2000),
    WO2 varchar2(2000),
    WO_STATUS varchar2(2000),
    RISK_LEVEL varchar2(2000),
    ISSUE_DESC varchar2(2000),
    NOTES varchar2(2000),
    ASSESSMENT_TYPE varchar2(2000),
    TITLE varchar2(2000),
    REVIEW_REPORT_TITLE varchar2(2000),
    STATUS varchar2(2000),
    WONUM varchar2(2000),
    SITEID varchar2(2000),
    ORGID varchar2(2000),
    EXTERNALREFID varchar2(2000),
    REPORTDATE date,
    targSTARTDATE date,
    TARGCOMPDATE date,
    ROW_ID varchar2(2000),
    datetimecopied varchar2(2000),
    INITIATOR_EMPLOYEE_ID varchar2(2000),
    APPROVER_EMPLOYEE_ID varchar2(2000),
    INITIATOR_NAME varchar2(2000),
    APPROVER_NAME varchar2(2000),
    INSTITUTIONAL_FLAG varchar2(2000),
    PROGRAM_PROJECT varchar2(2000),
    CORRECTIVE_ACTION varchar2(2000)
    );
                                 
grant all on lbl_max2catsinfo to public;






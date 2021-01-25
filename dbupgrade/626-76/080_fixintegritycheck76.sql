
delete from maxsequence where tbname in ('MOTORS','PUMPS','VALVES');

update maxattribute set domainid=null where attributename='DRIVER' and objectname='IMPROFILE';
update maxattributecfg set domainid=null where attributename='DRIVER' and objectname='IMPROFILE';

Delete From maxuser Where userid = 'MAXREG';

commit;

/*  NOT REQUIRED 

drop SEQUENCE itemstatusseq;

CREATE SEQUENCE itemstatusseq
  INCREMENT BY 1
  START WITH 15999
  MINVALUE 1
  MAXVALUE 9999999999999999999999999999
  NOCYCLE
  NOORDER
  CACHE 20;



drop view ACCOUNTS_VMMO;
drop view DW_LBNL_HARD_CLOSE;
drop view EQTRANS_V;
drop view EQUIPMENT_V;
drop view FAILURECODE_V;
drop view FAILURELIST_V;
drop view JOBLABOR_V;
drop view JOBMATERIAL_V;
drop view JOBOPERATION_V;
drop view JOBPLAN_V;
drop view JOBTOOL_V;
drop view JPASSETSPLINK_V;
drop view LBL_ALL_INVTRANS;
drop view LBL_CHESS_LOCATIONS;
drop view LBL_COMPLIANCE_COST;
drop view LBL_DW_LIENS;
drop view LBL_INFRASTRUCTURE_LOCATIONS;
drop view LBL_INFRA_LOCATIONS;
drop view LBL_MAXIMO_EQUIPMENT;
drop view LBL_MAXIMO_ITEMS;
drop view LBL_MXFMS_REQS;
drop view LBL_PS_ITM_VENDOR;
drop view LBL_PS_ITM_VENDOR_LOC;
drop view LBL_PS_ITM_VNDR_UOM;
drop view LBL_PS_ITM_VNDR_UOM_PR;
drop view LBL_PS_PURCH_ITEM_ATTR;
drop view LBL_PS_ZL_PROJECT_MAP;
drop view LBL_RESOURCE_CATEGORY_CUR;
drop view LBL_T1;
drop view LBL_VEHICLESPEC;
drop view LBL_VEHICLE_TRIP_RECORDS;
drop view LBL_VEHICLE_USAGE;
drop view LBL_V_AUTH_RELEASE;
drop view LBL_V_LOC2FMS;
drop view LBL_V_TEMP;
drop view LBL_V_WORKORDER_COST1;
drop view LONGDESCRIPTION_V;
drop view MXOPNWOCNT_V;
drop view MXOPNWOTOTS_V;
drop view MXVIEW0;
drop view PMANCESTOR_V;
drop view PMSEQUENCE_V;
drop view PM_V;
drop view PO_DISTRIBUTIONS;
drop view PO_HEADERS;
drop view PO_LINES;
drop view PO_LINE_LOCATIONS;
drop view PO_VENDORS;
drop view PO_VENDOR_CONTACTS;
drop view PO_VENDOR_SITES;
drop view PS_BUS_UNIT_TBL_FS;
drop view PS_BUS_UNIT_TBL_PM;
drop view PS_BU_JE_ID_CFS;
drop view PS_BU_LED_GRP_TBL;
drop view PS_CAL_DETP_TBL;
drop view PS_CURRENCY_CD_TBL;
drop view PS_CUR_RT_TBL;
drop view PS_DEPT_TBL_VMMO;
drop view PS_EMPLOYMENT_VMMO;
drop view PS_EMPL_PHON_VMMO;
drop view PS_ITM_CAT_TBL;
drop view PS_JOB_VMMO;
drop view PS_LBNL_MX_COUNT;
drop view PS_LBNL_MX_ERROR;
drop view PS_LBNL_MX_ERR_TBL;
drop view PS_LBNL_MX_LOC;
drop view PS_LBNL_MX_PROJECT;
drop view PS_LBNL_MX_TEAM;
drop view PS_MX_ACCTG_LN;
drop view PS_MX_API_LOG;
drop view PS_MX_BU_INTFC;
drop view PS_MX_ITMIN_INTFC;
drop view PS_MX_POIN_INTFC;
drop view PS_MX_RECVIN_INTFC;
drop view PS_MX_REQ_INTFC;
drop view PS_PERS_DATA_VMMO;
drop view PS_PROJECT;
drop view PS_PROJECT_STATUS;
drop view PS_PROJECT_TEAM;
drop view PS_PROJ_LOCATION;
drop view PS_PROJ_RESOURCE;
drop view PS_PROJ_TEAM_SCHED;
drop view PS_RECV_LN_DISTRIB;
drop view PS_SET_CNTRL_REC;
drop view PS_SHIPTO_TBL;
drop view PS_UNITS_TBL;
drop view PS_ZW_EW_DR_RE;
drop view PS_ZW_PC_DR_PR_CT;
drop view PS_ZZ_DEPT_VMMO;
drop view PS_ZZ_GROUP_VMMO;
drop view PS_ZZ_LABOR_DIST;
drop view PS_ZZ_LEVEL4_VMMO;
drop view PS_ZZ_MISC_VMMO;
drop view PS_ZZ_UNIT_VMMO;
drop view ROUTES_V;
drop view ROUTE_STOP_V;
drop view V_ACCOUNTDEFAULTS;
drop view V_ADDRESS;
drop view V_ALNDOMAINVALUE;
drop view V_ALTITEM;
drop view V_APPDOCTYPE;
drop view V_APPFIELDDEFAULTS;
drop view V_APPLAUNCH;
drop view V_APPROVALLIMIT;
drop view V_ARCHIVE;
drop view V_ASSETATTRIBUTE;
drop view V_ASSETCLASS;
drop view V_ASSIGNMENT;
drop view V_ATTENDANCE;
drop view V_AUTOKEY;
drop view V_A_ASSIGNMENT;
drop view V_A_EQUIPMENT;
drop view V_A_EQUIPMENTSPEC;
drop view V_A_INVBALANCES;
drop view V_A_INVENTORY;
drop view V_A_INVTRANS;
drop view V_A_MATRECTRANS;
drop view V_A_MATUSETRANS;
drop view V_A_TOOLTRANS;
drop view V_A_WORKORDER;
drop view V_A_WOSTATUS;
drop view V_BOOKMARK;
drop view V_CALENDAR;
drop view V_CHARTOFACCOUNTS;
drop view V_CLASSSPEC;
drop view V_CLASSSTRUCTLINK;
drop view V_CLASSSTRUCTURE;
drop view V_COMMODITYAUTH;
drop view V_COMPANIES;
drop view V_COMPANYACCDEF;
drop view V_COMPCONTACT;
drop view V_CROSSOVERDOMAIN;
drop view V_CURRENCY;
drop view V_DEFAULTQUERY;
drop view V_DESKTOPDFLTS;
drop view V_DMSAPISETTING;
drop view V_DOCINFO;
drop view V_DOCLINKS;
drop view V_DOCTYPES;
drop view V_DUMMY_TABLE;
drop view V_EQHIERARCHY;
drop view V_EQHISTORY;
drop view V_EQSTATUS;
drop view V_EQTRANS;
drop view V_EQUIPMENT;
drop view V_EQUIPMENTSPEC;
drop view V_EXCHANGE;
drop view V_FAILURECODE;
drop view V_FAILUREDELETE;
drop view V_FAILURELIST;
drop view V_FAILUREREMARK;
drop view V_FAILUREREPORT;
drop view V_FIELDDEFAULTS;
drop view V_FINANCIALPERIODS;
drop view V_FINCNTRL;
drop view V_GLCOMPONENTS;
drop view V_GLCONFIGURE;
drop view V_GROUPRESTRICTION;
drop view V_HAZARD;
drop view V_HAZARDPREC;
drop view V_HOLIDAY;
drop view V_INVBALANCES;
drop view V_INVENTORY;
drop view V_INVLOT;
drop view V_INVOICE;
drop view V_INVOICECOST;
drop view V_INVOICELINE;
drop view V_INVOICEMATCH;
drop view V_INVOICESTATUS;
drop view V_INVOICETRANS;
drop view V_INVRESERVE;
drop view V_INVTRANS;
drop view V_INVVENDOR;
drop view V_ITEM;
drop view V_ITEMSPEC;
drop view V_ITEMSTRUCT;
drop view V_JOBLABOR;
drop view V_JOBMATERIAL;
drop view V_JOBPLAN;
drop view V_JOBTASK;
drop view V_JOBTOOL;
drop view V_JPASSETSPLINK;
drop view V_KPI;
drop view V_LABAVAIL;
drop view V_LABOR;
drop view V_LABORAUTH;
drop view V_LABTRANS;
drop view V_LANGUAGE;
drop view V_LISTTRANSLATION;
drop view V_LOCANCESTOR;
drop view V_LOCATIONS;
drop view V_LOCATIONSPEC;
drop view V_LOCAUTH;
drop view V_LOCHIERARCHY;
drop view V_LOCKOUT;
drop view V_LOCLEADTIME;
drop view V_LOCOPER;
drop view V_LOCSTATUS;
drop view V_LOGINTRACKING;
drop view V_LONGDESCRIPTION;
drop view V_MATRECTRANS;
drop view V_MATUSETRANS;
drop view V_MAXAPPS;
drop view V_MAXDOMAIN;
drop view V_MAXENCRYPT;
drop view V_MAXGROUPS;
drop view V_MAXHLP;
drop view V_MAXRELATIONSHIP;
drop view V_MAXSERVICE;
drop view V_MAXSYSCOLSCFG;
drop view V_MAXSYSCOLUMNS2;
drop view V_MAXSYSCOLUMNS;
drop view V_MAXSYSINDEXES;
drop view V_MAXTABLEDOMAIN;
drop view V_MAXTABLES2;
drop view V_MAXTABLES;
drop view V_MAXTABLESCFG;
drop view V_MAXTRIGGERS;
drop view V_MAXUSERAUTH;
drop view V_MAXUSERGROUPS;
drop view V_MAXUSERSTATUS;
drop view V_MAXVARS;
drop view V_MAXVARTYPE;
drop view V_MAX_AP_INTERFACE;
drop view V_MAX_COA_INTERFAC;
drop view V_MAX_ISU_INTERFAC;
drop view V_MAX_ITM_INTERFAC;
drop view V_MAX_LC_INTERFACE;
drop view V_MAX_PO_INTERFACE;
drop view V_MAX_PR_INTERFACE;
drop view V_MAX_RCV_INTERFAC;
drop view V_MAX_SRL_INTERFAC;
drop view V_MEASUREMENT;
drop view V_MEASUREPOINT;
drop view V_MEASUREUNIT;
drop view V_MOUT_AP_INTERFAC;
drop view V_MOUT_GL_INTERFAC;
drop view V_MOUT_ISU_INTERFA;
drop view V_MOUT_PO_INTERFAC;
drop view V_MOUT_PR_INTERFAC;
drop view V_MOUT_RCV_INTERFA;
drop view V_MOUT_RSV_INTERFA;
drop view V_MOUT_SRL_INTERFA;
drop view V_MR;
drop view V_MRCOST;
drop view V_MRLINE;
drop view V_MRSTATUS;
drop view V_MXCOLLAB;
drop view V_MXCOLLABREF;
drop view V_NUMDOMAINVALUE;


drop view V_ORDERUNIT;
drop view V_ORGANIZATIONS;
drop view V_PM;
drop view V_PMANCESTOR;
drop view V_PMSCHEDACTIVITY;
drop view V_PMSEQUENCE;
drop view V_PO;
drop view V_POCOST;
drop view V_POECOMSTATUS;
drop view V_POINTWO;
drop view V_POLINE;
drop view V_POSTATUS;
drop view V_PR;
drop view V_PRCOST;
drop view V_PRECAUTION;
drop view V_PRICALC;
drop view V_PRINTER;
drop view V_PRLINE;
drop view V_PRSTATUS;
drop view V_QUERY;
drop view V_QUOTATIONLINE;
drop view V_RANGEDOMSEGMENT;
drop view V_REORDERMUTEX;
drop view V_REORDERPAD;
drop view V_RFQ;
drop view V_RFQLINE;
drop view V_RFQSTATUS;
drop view V_RFQVENDOR;
drop view V_ROUTE_STOP;
drop view V_ROUTES;
drop view V_SAFETYLEXICON;
drop view V_SAFETYPLAN;
drop view V_SCHARGES;
drop view V_SERVICECONTRACT;
drop view V_SERVRECTRANS;
drop view V_SHIFT;
drop view V_SHIFTPATTERNDAY;
drop view V_SHIPMENT;
drop view V_SHIPMENTLINE;
drop view V_SIGOPTION;
drop view V_SITE;
drop view V_SITEECOM;
drop view V_SITERESTRICTION;
drop view V_SITEUSER;
drop view V_SPAREPART;
drop view V_SPLEXICONLINK;
drop view V_SPRELATEDASSET;
drop view V_SPWORKASSET;
drop view V_STARTCENTER;
drop view V_TAGLOCK;
drop view V_TAGOUT;
drop view V_TAX;
drop view V_TAXTYPE;
drop view V_TOLERANCE;
drop view V_TOOL;
drop view V_TOOLTRANS;
drop view V_TRANSLATION;
drop view V_USERGROUPAUTH;
drop view V_USERPREF;
drop view V_USERRESTRICTIONS;
drop view V_VALUELIST;
drop view V_VALUELISTDOMAIN;
drop view V_VENDORSTATUS;
drop view V_VERITYACTION;
drop view V_WFACTION;
drop view V_WFACTIONLIST;
drop view V_WFASSIGNMENT;
drop view V_WFCALLSTACK;
drop view V_WFCONDITION;
drop view V_WFINPUT;
drop view V_WFINSTANCE;
drop view V_WFNODE;
drop view V_WFNOTIFICATION;
drop view V_WFPROCESS;
drop view V_WFREVISION;
drop view V_WFROLE;
drop view V_WFSTART;
drop view V_WFSTOP;
drop view V_WFSUBPROCESS;
drop view V_WFTASK;
drop view V_WFTRANSACTION;
drop view V_WOANCESTOR;
drop view V_WOASSIGNMNTPARTY;
drop view V_WOASSIGNMNTQUEUE;
drop view V_WOGEN;
drop view V_WOHAZARD;
drop view V_WOHAZARDPREC;
drop view V_WOLOCKOUT;
drop view V_WOPRECAUTION;
drop view V_WORKORDER;
drop view V_WORKPERIOD;
drop view V_WORKPRIORITY;
drop view V_WORKTYPE;
drop view V_WOSAFETYLINK;
drop view V_WOSAFETYPLAN;
drop view V_WOSCHEDACTIVITY;
drop view V_WOSTATUS;
drop view V_WOTAGLOCK;
drop view V_WOTAGOUT;
drop view V_WPEDITSETTING;
drop view V_WPLABOR;
drop view V_WPMATERIAL;
drop view V_WPTOOL;
drop view WORKORDER_V;

update maxattribute set sameasobject=null, sameasattribute=null 
where objectname='A_LBL_WORKORDEREXT' and attributename='PRIOR_WONUM';

update maxattribute set sameasobject=null, sameasattribute=null 
where objectname='A_LBL_WKTHRURES' and attributename='EHS_SUPPORT_CONT';

update maxattribute set sameasobject=null, sameasattribute=null 
where objectname='A_MATRECTRANS6' and attributename='INVUSELINESPLITID';

update maxattribute set sameasobject=null, sameasattribute=null 
where objectname='A_MATRECTRANS6' and attributename='INVUSEID';

update maxattribute set sameasobject=null, sameasattribute=null 
where objectname='A_LBL_WOWKTHRURES' and attributename='EHS_SUPPORT_CONT';

update maxattribute set sameasobject=null, sameasattribute=null 
where objectname='A_LBL_WOWKTHRU' and attributename='ACCESS_LOCATION';

update maxattribute set sameasobject=null, sameasattribute=null 
where objectname='A_MATRECTRANS6' and attributename='INVUSELINEID';

update maxattribute set sameasobject=null, sameasattribute=null 
where objectname='A_MATRECTRANS6' and attributename='ININVUSELINEID';

update maxattribute set sameasobject=null, sameasattribute=null 
where objectname='A_MATUSETRANS6' and attributename='INVUSEID';

update maxattribute set sameasobject=null, sameasattribute=null 
where objectname='A_MATUSETRANS6' and attributename='INVUSELINEID';

update maxattribute set sameasobject=null, sameasattribute=null 
where objectname='MATRECTRANS' and attributename='SHIPMENTLINENUM';

update maxattribute set sameasobject=null, sameasattribute=null 
where objectname='MATRECTRANS' and attributename='INVUSELINENUM';

*/





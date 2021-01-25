CREATE OR REPLACE PACKAGE lbl_mxmrowkfl_pkg
IS


FUNCTION GET_LATEST_WFSTATUS(OBJECTID_I    IN VARCHAR2,
                             PROCESSNAME_I IN VARCHAR2,
                             OBJECTTYPE_I  IN VARCHAR2)
                            RETURN VARCHAR2;


FUNCTION IS_MATERIAL_AVAILABLE(ORGID_I    IN WORKORDER.ORGID%TYPE,
                             SITEID_I   IN WORKORDER.SITEID%TYPE,
                             WONUM_I    IN WORKORDER.WONUM%TYPE)
                            RETURN VARCHAR2;


FUNCTION SCHDTARGDATES_MISSING(ORGID_I    IN WORKORDER.ORGID%TYPE,
                             SITEID_I   IN WORKORDER.SITEID%TYPE,
                             WONUM_I    IN WORKORDER.WONUM%TYPE)
                            RETURN VARCHAR2;


FUNCTION ELIGIBLE_IN_WORKFLOW(ORGID_I    IN WORKORDER.ORGID%TYPE,
                             SITEID_I    IN WORKORDER.SITEID%TYPE,
                             WONUM_I     IN WORKORDER.WONUM%TYPE,
                             STATUS_I    IN WORKORDER.STATUS%TYPE,
                             PROCESSNAME_I IN VARCHAR2,
                             SUBPROCESS_I  IN VARCHAR2)
                             RETURN VARCHAR2;



END;

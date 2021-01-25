CREATE OR REPLACE PACKAGE BODY lbl_mxmrowkfl_pkg IS


 -- FUNCTION TO FIND OUT THE LAST WORKFLOW STATUS FOR A GIVEN
 -- OBJECT, PROCESS AND TYPE OF OBJECT
 FUNCTION GET_LATEST_WFSTATUS(OBJECTID_I    IN VARCHAR2,
                              PROCESSNAME_I IN VARCHAR2,
                              OBJECTTYPE_I  IN VARCHAR2)
                            RETURN VARCHAR2

    IS
        NODETYPE_T  MAXIMO.WFTRANSACTION.NODETYPE%TYPE :='WFSTOP';

    BEGIN

     IF (OBJECTTYPE_I='WORKORDER') THEN

      BEGIN

       SELECT NODETYPE INTO NODETYPE_T
       FROM   WFTRANSACTION
       WHERE  PROCESSNAME=PROCESSNAME_I
       AND OWNERID=(SELECT WORKORDERID FROM WORKORDER WHERE WONUM=OBJECTID_I)
       AND TRANSDATE =(SELECT MAX(TRANSDATE) FROM WFTRANSACTION
                       WHERE PROCESSNAME=PROCESSNAME_I
                       AND OWNERID=(SELECT WORKORDERID FROM WORKORDER
                       WHERE WONUM=OBJECTID_I))
       AND TRANSID =(SELECT MAX(TRANSID) FROM WFTRANSACTION
                     WHERE PROCESSNAME=PROCESSNAME_I
                     AND OWNERID=(SELECT WORKORDERID FROM WORKORDER
                     WHERE WONUM=OBJECTID_I));

      EXCEPTION
        WHEN OTHERS THEN
           NODETYPE_T :='WFSTOP';
     END;
    END IF;

     RETURN NODETYPE_T;

    END; -- END OF FUNCTION

-- FUNCTION TO FIND WHETHER THE WORK ORDER STAYS IN WORKFLOW OR NOT

FUNCTION ELIGIBLE_IN_WORKFLOW(ORGID_I    IN WORKORDER.ORGID%TYPE,
                             SITEID_I   IN WORKORDER.SITEID%TYPE,
                             WONUM_I    IN WORKORDER.WONUM%TYPE,
                             STATUS_I   IN WORKORDER.STATUS%TYPE,
                             PROCESSNAME_I IN VARCHAR2,
                             SUBPROCESS_I  IN VARCHAR2)
                             RETURN VARCHAR2
    IS
      WORKTYPE_T WORKTYPE.TYPE%TYPE;
      REL_CNT_T   NUMBER(5) :=0;
      ISTASK_T     WORKORDER.ISTASK%TYPE;
      T_LBL_ELIGMROWKFLOW WORKTYPE.LBL_ELIGMROWKFLOW%TYPE;
      TYPE_T       WORKTYPE.TYPE%TYPE;
      T_CUSTO_LEADCRAFT WORKORDER.LEADCRAFT%TYPE;
      T_WOLEADCRAFT     WORKORDER.LEADCRAFT%TYPE;
      T_LBL_FAMID       WORKORDER.LBL_FAMID%TYPE;
      T_LOCATION        WORKORDER.LOCATION%TYPE;
      T_GLACCOUNT       WORKORDER.GLACCOUNT%TYPE;
      T_LBL_PLANNER_GROUP WORKORDER.LBL_PLANNER_GROUP%TYPE;
      T_CLASSSTRUCTUREID  WORKORDER.CLASSSTRUCTUREID%TYPE;

    BEGIN


    IF (ORGID_I ='LBNL' AND SITEID_I ='FAC' AND PROCESSNAME_I='FAMRO') THEN


       -- GET OTHER ELEMENTS OF THE WORK ORDER
     BEGIN
      SELECT WORKTYPE,
             ISTASK, LEADCRAFT, LBL_FAMID,
             LOCATION, GLACCOUNT, LBL_PLANNER_GROUP, CLASSSTRUCTUREID
      INTO   WORKTYPE_T,
             ISTASK_T,  T_WOLEADCRAFT, T_LBL_FAMID,
             T_LOCATION, T_GLACCOUNT, T_LBL_PLANNER_GROUP, T_CLASSSTRUCTUREID

      FROM   WORKORDER
      WHERE  ORGID=ORGID_I
      AND    SITEID=SITEID_I
      AND    WONUM=WONUM_I;



     EXCEPTION WHEN OTHERS THEN
       RETURN '0';
     END ;


    IF (SUBPROCESS_I IS NULL) THEN -- BEFORE TERMINAL NODE

      --IF (STATUS_I NOT IN ('WPLAN','WPLANSUP','PLAN','WSCH1')) THEN
      -- CHECK ONLY 2 STATUS FOR THE LIMITED IMPLEMENTATION OF THE WORKFLOW
      -- ADDED STATUS SPRI JIRA EF-6648

       IF (STATUS_I NOT IN ('WPLAN','WPLANSUP','PLAN','WSCH1','SPRI')) THEN
        RETURN '0';
       END IF;

     END IF;



   IF (SUBPROCESS_I='FAM') THEN

      -- ALWAYS RETURN ZERO; WF NOT FINALIZED YET

      RETURN 0;
       /*IF (STATUS_T IN ('WPLAN',
                        'PLAN','ASSIGNED','WSCH1','WMATL','SCHD','WREL',
                        'REL','CAN','CLOSE','WCOMP','COMP')) THEN
           RETURN '0';
       END IF; */

    END IF;


    IF (SUBPROCESS_I IN ('FAEXPEDITE')) THEN

       IF (STATUS_I NOT IN ('WPLAN')) THEN

           RETURN '0';
       END IF;

     END IF;

     IF (SUBPROCESS_I IN ('FAPLANSUPV')) THEN

       IF (STATUS_I NOT IN ('WPLANSUP')) THEN

           RETURN '0';
       END IF;

     END IF;





    IF (SUBPROCESS_I='FAPLANNER') THEN

       IF (STATUS_I NOT IN ('PLAN')) THEN

           RETURN '0';
       END IF;

       IF (T_GLACCOUNT IS NULL OR T_LOCATION IS NULL OR
           WORKTYPE_T  IS NULL OR T_CLASSSTRUCTUREID IS NULL OR
           T_LBL_PLANNER_GROUP IS NULL) THEN

        RETURN '0';
       END IF;


    END IF;


    IF (SUBPROCESS_I='FASCHEDULE') THEN

        -- ADDED STATUS SPRI JIRA EF-6630
        IF (STATUS_I NOT IN ('WSCH1','SPRI')) THEN

           RETURN '0';
       END IF;


       /*IF (STATUS_T IN ('SCHD','WREL',
                        'REL','CAN','CLOSE','WCOMP','COMP')) THEN

           RETURN '0';
       END IF;*/

    END IF;


    IF (SUBPROCESS_I='FASUPERVSR') THEN

       RETURN '0';

       /*IF (STATUS_T IN ('WCOMP','COMP','CLOSE','CAN')) THEN
           RETURN '0';
       END IF;*/

    END IF;



      -- TASK WORK ORDERS (GENERATED THROUGH PMS DO NOT REMAIN IN WORKFLOW
      IF (ISTASK_T =1) THEN
        RETURN '0';
      END IF;

      -- IF FAM ID IS NULL THEN EXIT WORKFLOW
      IF (T_LBL_FAMID IS NULL) THEN
        RETURN '0';
      END IF;

      -- CHECK WORK TYPE THAT CAN BE BYPASSED
      IF (WORKTYPE_T IS NOT NULL) THEN

          SELECT TYPE, LBL_ELIGMROWKFLOW
          INTO   TYPE_T, T_LBL_ELIGMROWKFLOW
          FROM   WORKTYPE
          WHERE  WORKTYPE=WORKTYPE_T;

          IF (TYPE_T='NOCHARGE')  THEN
            RETURN '0';
          END IF;

          IF (T_LBL_ELIGMROWKFLOW='0') THEN
            RETURN '0';
          END IF;



      END IF;


      RETURN '1';
   ELSE
      RETURN '0';
   END IF;


END; -- END FUNCTION




FUNCTION IS_MATERIAL_AVAILABLE(ORGID_I    IN WORKORDER.ORGID%TYPE,
                             SITEID_I   IN WORKORDER.SITEID%TYPE,
                             WONUM_I    IN WORKORDER.WONUM%TYPE)
                            RETURN VARCHAR2

IS

  CURSOR WPMATERIAL_CUR  IS
  SELECT * FROM MAXIMO.WPMATERIAL A
  WHERE  A.ORGID=ORGID_I
  AND    A.SITEID=SITEID_I
  AND    A.WONUM=WONUM_I;

  CURBAL_T INVBALANCES.CURBAL%TYPE :=0;



BEGIN

   FOR WPMATERIAL_REC IN   WPMATERIAL_CUR

     LOOP

       SELECT A.CURBAL INTO CURBAL_T
       FROM   MAXIMO.INVBALANCES A
       WHERE A.ORGID=WPMATERIAL_REC.ORGID
       AND   A.SITEID=WPMATERIAL_REC.SITEID
       AND   A.ITEMNUM=WPMATERIAL_REC.ITEMNUM
       AND   A.LOCATION=WPMATERIAL_REC.LOCATION;

       IF (CURBAL_T < WPMATERIAL_REC.ITEMQTY) THEN
           RETURN '0';
       ELSE
           RETURN '1';
       END IF;
  END LOOP;

       RETURN '0';


END;

FUNCTION SCHDTARGDATES_MISSING(ORGID_I    IN WORKORDER.ORGID%TYPE,
                               SITEID_I   IN WORKORDER.SITEID%TYPE,
                               WONUM_I    IN WORKORDER.WONUM%TYPE)
                            RETURN VARCHAR2

IS
  T_LBL_RELEASE_STATUS WORKORDER.LBL_RELEASE_STATUS%TYPE;
  T_TARGSTARTDATE  WORKORDER.TARGSTARTDATE%TYPE;
  T_TARGCOMPDATE   WORKORDER.TARGCOMPDATE%TYPE;
  T_SCHEDSTART     WORKORDER.SCHEDSTART%TYPE;
  T_SCHEDFINISH    WORKORDER.SCHEDFINISH%TYPE;

 BEGIN
      SELECT LBL_RELEASE_STATUS, TARGSTARTDATE , TARGCOMPDATE,
             SCHEDSTART, SCHEDFINISH
      INTO   T_LBL_RELEASE_STATUS, T_TARGSTARTDATE, T_TARGCOMPDATE,
             T_SCHEDSTART, T_SCHEDFINISH
      FROM   WORKORDER
      WHERE  ORGID=ORGID_I
      AND    SITEID=SITEID_I
      AND    WONUM=WONUM_I;

     IF (T_LBL_RELEASE_STATUS IN ('REQUIRED','REQUEST FOR INFORMATION','WAITING RELEASE','RELEASED')) THEN

       IF (T_TARGSTARTDATE IS NULL) THEN
         RETURN '1';
       END IF;

       IF (T_TARGCOMPDATE IS NULL) THEN
         RETURN '1';
       END IF;

       IF (T_SCHEDSTART IS NULL) THEN
         RETURN '1';
       END IF;

       IF (T_SCHEDFINISH IS NULL) THEN
         RETURN '1';
       END IF;


    ELSE -- RELEASE NOT REQUIRED

     IF (T_SCHEDSTART IS NULL) THEN
         RETURN '1';
       END IF;

       IF (T_SCHEDFINISH IS NULL) THEN
         RETURN '1';
       END IF;

    END IF;


     RETURN '0';
  END;





END;

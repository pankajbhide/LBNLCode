/************************************************************************
*
* PROGRAM NAME          : REFRESH_LBL_MTH_VEHUSAGE.SQL
*
*
* DESCRIPTION           : PROGRAM TO REFRESH THE DATA VEHICLE USAGE TABLES
*
*                         THE DATA IN THIS TABLE IS USEFUL FOR PRINTING THE
*                         VEHICLE USAGE REPORTS
*
* AUTHOR                : PANKAJ BHIDE
*
* DATE WRITTEN          : 18-OCT-2007
*
* DATE MODIFIED         : 30-OCT-2007 INSERT THE DATA INTO LBL_MTH_VEHUSAGELINE
*                                     EVEN  IF THE NUMBER OF TRIPS ARE ZERO.
*
*                         31-OCT-2007 FIXED A ISSUE OF GETTING OLD WORK ORDERS
*                                     WHICH WERE PREVIOUSLY CANCELED WERE GETTING
*                                     INCLUDED.
*
* MODIFICATION HISORTY  : 22-JAN-2010 CHANGES FOR MXES
*************************************************************************/
DECLARE

 -- CURSOR TO READ THE LAST 3 FINANCIALPERIODS FROM TODAY
 CURSOR FINANCIALPERIODS_CUR IS
   SELECT PERIODSTART, PERIODEND, FINANCIALPERIOD
   FROM MAXIMO.FINANCIALPERIODS
   WHERE PERIODSTART >= (SYSDATE-122)
   AND CLOSEDATE IS NOT NULL
   ORDER BY FINANCIALPERIOD;

 FINANCIALPERIOD_T FINANCIALPERIODS.FINANCIALPERIOD%TYPE;

 -- GET THE TRIPS AGAINST THE VEHICLES FOR THE FINANCIALPERIOD
 CURSOR WORKORDERS_CUR IS
 -- OPEN WORK ORDERS FOR ACC PERIOD
  SELECT B.ASSETNUM, A.WONUM, B.LOCATION, B.ORGID, B.SITEID
  FROM MAXIMO.WOSTATUS A, MAXIMO.WORKORDER B
  WHERE A.ORGID=B.ORGID
  AND   A.SITEID=B.SITEID
  AND   A.WONUM=B.WONUM
  AND   B.LEADCRAFT='VEHTRIPS'
  AND   A.STATUS NOT IN ('WCLOSE','CLOSE','CAN','COMP')
  AND   A.CHANGEDATE=(SELECT MAX(C.CHANGEDATE)
  FROM MAXIMO.WOSTATUS C WHERE C.ORGID=A.ORGID
  AND  C.SITEID=A.SITEID AND C.WONUM=A.WONUM
  AND  C.CHANGEDATE  < (SELECT PERIODEND   FROM FINANCIALPERIODS WHERE FINANCIALPERIOD=FINANCIALPERIOD_T))
  UNION
  -- CLOSED WORK ORDER FOR ACC PERIOD
  SELECT B.ASSETNUM, A.WONUM, B.LOCATION, B.ORGID, B.SITEID
  FROM MAXIMO.WOSTATUS A, MAXIMO.WORKORDER B
  WHERE A.ORGID=B.ORGID
  AND   A.SITEID=B.SITEID
  AND   A.WONUM=B.WONUM
  AND   B.LEADCRAFT='VEHTRIPS'
  AND   A.STATUS IN ('WCLOSE','CLOSE','CAN','COMP')
  AND   A.CHANGEDATE=(SELECT MAX(C.CHANGEDATE)
  FROM MAXIMO.WOSTATUS C WHERE C.ORGID=A.ORGID
  AND  C.SITEID=A.SITEID AND C.WONUM=A.WONUM
  AND  C.CHANGEDATE >= (SELECT PERIODSTART FROM FINANCIALPERIODS WHERE FINANCIALPERIOD=FINANCIALPERIOD_T)
  AND  C.CHANGEDATE  < (SELECT PERIODEND   FROM FINANCIALPERIODS WHERE FINANCIALPERIOD=FINANCIALPERIOD_T))
  ORDER BY 1,2,3;


   PRV_ASSETNUM  ASSET.ASSETNUM%TYPE;
   REC_CNT_T  NUMBER(10) :=0;
   NUMBER_OF_TRIPS_T NUMBER(15,2) :=0;
   TOTAL_NUMBER_OF_TRIPS_T NUMBER(15,2) :=0;
   PRV_SITEID WORKORDER.SITEID%TYPE;
   PRV_ORGID  WORKORDER.ORGID%TYPE;
   MILEAGE_COST_T    NUMBER(15,2) :=0;
   NUMBER_OF_MILES_T NUMBER(15,2) :=0;
   FEEDER_COST_T     NUMBER(18,2) :=0;

 BEGIN

 -- START PROCESSING EACH FINANCIALPERIOD

 FOR FINANCIALPERIODS_REC IN FINANCIALPERIODS_CUR

   LOOP -- OUTER LOOP

     -- DELETE PREVIOUS RECORD START WITH CLEAN TABLE
     DELETE FROM BATCH_MAXIMO.LBL_MTH_VEHUSAGE
     WHERE FINANCIALPERIOD=FINANCIALPERIODS_REC.FINANCIALPERIOD;

     DELETE FROM BATCH_MAXIMO.LBL_MTH_VEHUSAGELINE
     WHERE FINANCIALPERIOD=FINANCIALPERIODS_REC.FINANCIALPERIOD;

     FINANCIALPERIOD_T :=FINANCIALPERIODS_REC.FINANCIALPERIOD;

     REC_CNT_T :=0;

     -- START GETTING VEHICLE INFORMATION
     FOR WORKORDERS_REC IN WORKORDERS_CUR

       LOOP -- INNER LOOP

        REC_CNT_T :=REC_CNT_T + 1;

        IF (REC_CNT_T =1) THEN
          PRV_ORGID :=WORKORDERS_REC.ORGID;
          PRV_SITEID:=WORKORDERS_REC.SITEID;
          PRV_ASSETNUM :=WORKORDERS_REC.ASSETNUM;
        END IF;

        -- IF ASSET CHANGES THEN GET THE MILEAGE COST,
        -- NUMBER OF MILES, FEEDER COST AND INSERT INTO THE
        -- HEADER TABLE

        IF (PRV_ASSETNUM != WORKORDERS_REC.ASSETNUM) THEN

             MILEAGE_COST_T :=0;

             SELECT NVL(SUM(A.LINECOST),0)
             INTO   MILEAGE_COST_T
             FROM MAXIMO.INVOICECOST A, MAXIMO.INVOICELINE B,
             MAXIMO.INVOICE C
             WHERE A.SITEID=PRV_SITEID
             AND   A.INVOICENUM=B.INVOICENUM
             AND   A.INVOICELINENUM=B.INVOICELINENUM
             AND   B.SITEID=PRV_SITEID
             AND   B.INVOICENUM=C.INVOICENUM
             AND   C.SITEID=PRV_SITEID
             AND   C.INVOICENUM LIKE 'FLEET%'
             AND   C.FINANCIALPERIOD=FINANCIALPERIODS_REC.FINANCIALPERIOD
             AND   B.INVOICEUNIT='MILES'
             AND   A.ASSETNUM=PRV_ASSETNUM;

             NUMBER_OF_MILES_T :=0;

             SELECT NVL(SUM(B.INVOICEQTY),0)
             INTO   NUMBER_OF_MILES_T
             FROM MAXIMO.INVOICECOST A, MAXIMO.INVOICELINE B,
             MAXIMO.INVOICE C
             WHERE A.SITEID=PRV_SITEID
             AND   A.INVOICENUM=B.INVOICENUM
             AND   A.INVOICELINENUM=B.INVOICELINENUM
             AND   B.SITEID=PRV_SITEID
             AND   B.INVOICENUM=C.INVOICENUM
             AND   C.SITEID=PRV_SITEID
             AND   C.INVOICENUM LIKE 'FLEET%'
             AND   C.FINANCIALPERIOD=FINANCIALPERIODS_REC.FINANCIALPERIOD
             AND   B.INVOICEUNIT='MILES'
             AND   A.ASSETNUM=PRV_ASSETNUM;

             FEEDER_COST_T :=0;

	     SELECT NVL(SUM(A.LINECOST),0)
             INTO   FEEDER_COST_T
             FROM MAXIMO.INVOICECOST A, MAXIMO.INVOICELINE B,
             MAXIMO.INVOICE C
             WHERE A.SITEID=PRV_SITEID
             AND   A.INVOICENUM=B.INVOICENUM
             AND   A.INVOICELINENUM=B.INVOICELINENUM
             AND   B.SITEID=PRV_SITEID
             AND   B.INVOICENUM=C.INVOICENUM
             AND   C.SITEID=PRV_SITEID
             AND   C.INVOICENUM LIKE 'FLEET%'
             AND   C.FINANCIALPERIOD=FINANCIALPERIODS_REC.FINANCIALPERIOD
             AND   A.ASSETNUM=PRV_ASSETNUM;

             INSERT INTO BATCH_MAXIMO.LBL_MTH_VEHUSAGE
             (ORGID, SITEID, FINANCIALPERIOD,
              ASSETNUM, TOTAL_MILES, MILEAGE_COST,FEEDER_COST,
              TOTAL_TRIPS,
              LASTUPDATEDATE) VALUES
              (PRV_ORGID, PRV_SITEID,FINANCIALPERIODS_REC.FINANCIALPERIOD,
               PRV_ASSETNUM, NUMBER_OF_MILES_T, MILEAGE_COST_T, FEEDER_COST_T,
               TOTAL_NUMBER_OF_TRIPS_T,
               SYSDATE);

             PRV_ORGID :=WORKORDERS_REC.ORGID;
             PRV_SITEID:=WORKORDERS_REC.SITEID;
             PRV_ASSETNUM :=WORKORDERS_REC.ASSETNUM;
             TOTAL_NUMBER_OF_TRIPS_T :=0;

        END IF; -- IF (PRV_ASSETNUM != WORKORDERS_REC.ASSETNUM) THEN

          -- NOW GET THE INDIVIDUAL TRIPS
          -- FOR THE SAME VEHICLE FOR THE ABOVE ACCOUNTING PERIOD

          NUMBER_OF_TRIPS_T :=0;

          SELECT NVL(SUM(A.LBL_TRIPS),0)
          INTO   NUMBER_OF_TRIPS_T
          FROM MAXIMO.TOOLTRANS A
          WHERE A.ORGID='LBNL'
          AND   A.ITEMNUM='VEHTRIPS'
          AND   A.ASSETNUM=WORKORDERS_REC.ASSETNUM
          AND   A.REFWO=WORKORDERS_REC.WONUM
          AND   A.LBL_STARTDATE BETWEEN FINANCIALPERIODS_REC.PERIODSTART
    	  AND   FINANCIALPERIODS_REC.PERIODEND;

    	  -- REPORT EVEN IF THE NUMBER OF TRIPS ARE ZERO
          -- IF (NUMBER_OF_TRIPS_T !=0) THEN

            INSERT INTO BATCH_MAXIMO.LBL_MTH_VEHUSAGELINE
            (ORGID, SITEID, ASSETNUM,
             FINANCIALPERIOD, LOCATION, LINETYPE,
              QUANTITY, LASTUPDATEDATE) VALUES
              (WORKORDERS_REC.ORGID, WORKORDERS_REC.SITEID, WORKORDERS_REC.ASSETNUM,
               FINANCIALPERIODS_REC.FINANCIALPERIOD, WORKORDERS_REC.LOCATION,'VEHTRIPS',
               NUMBER_OF_TRIPS_T, SYSDATE);

               TOTAL_NUMBER_OF_TRIPS_T := TOTAL_NUMBER_OF_TRIPS_T + NUMBER_OF_TRIPS_T;

          -- END IF; -- IF (NUMBER_OF_USAGES_T !=0) THEN

       END LOOP; -- INNER LOOP

       -- LAST RECORD

       IF (REC_CNT_T > 1) THEN

             MILEAGE_COST_T :=0;

             SELECT NVL(SUM(A.LINECOST),0)
             INTO   MILEAGE_COST_T
             FROM MAXIMO.INVOICECOST A, MAXIMO.INVOICELINE B,
             MAXIMO.INVOICE C
             WHERE A.SITEID=PRV_SITEID
             AND   A.INVOICENUM=B.INVOICENUM
             AND   A.INVOICELINENUM=B.INVOICELINENUM
             AND   B.SITEID=PRV_SITEID
             AND   B.INVOICENUM=C.INVOICENUM
             AND   C.SITEID=PRV_SITEID
             AND   C.INVOICENUM LIKE 'FLEET%'
             AND   C.FINANCIALPERIOD=FINANCIALPERIODS_REC.FINANCIALPERIOD
             AND   B.INVOICEUNIT='MILES'
             AND   A.ASSETNUM=PRV_ASSETNUM;

             NUMBER_OF_MILES_T :=0;

             SELECT NVL(SUM(B.INVOICEQTY),0)
             INTO   NUMBER_OF_MILES_T
             FROM MAXIMO.INVOICECOST A, MAXIMO.INVOICELINE B,
             MAXIMO.INVOICE C
             WHERE A.SITEID=PRV_SITEID
             AND   A.INVOICENUM=B.INVOICENUM
             AND   A.INVOICELINENUM=B.INVOICELINENUM
             AND   B.SITEID=PRV_SITEID
             AND   B.INVOICENUM=C.INVOICENUM
             AND   C.SITEID=PRV_SITEID
             AND   C.INVOICENUM LIKE 'FLEET%'
             AND   C.FINANCIALPERIOD=FINANCIALPERIODS_REC.FINANCIALPERIOD
             AND   B.INVOICEUNIT='MILES'
             AND   A.ASSETNUM=PRV_ASSETNUM;

             FEEDER_COST_T :=0;

	     SELECT NVL(SUM(A.LINECOST),0)
             INTO   FEEDER_COST_T
             FROM MAXIMO.INVOICECOST A, MAXIMO.INVOICELINE B,
             MAXIMO.INVOICE C
             WHERE A.SITEID=PRV_SITEID
             AND   A.INVOICENUM=B.INVOICENUM
             AND   A.INVOICELINENUM=B.INVOICELINENUM
             AND   B.SITEID=PRV_SITEID
             AND   B.INVOICENUM=C.INVOICENUM
             AND   C.SITEID=PRV_SITEID
             AND   C.INVOICENUM LIKE 'FLEET%'
             AND   C.FINANCIALPERIOD=FINANCIALPERIODS_REC.FINANCIALPERIOD
             AND   A.ASSETNUM=PRV_ASSETNUM;

             INSERT INTO BATCH_MAXIMO.LBL_MTH_VEHUSAGE
             (ORGID, SITEID, FINANCIALPERIOD,
              ASSETNUM, TOTAL_MILES, MILEAGE_COST,FEEDER_COST,
              TOTAL_TRIPS,
              LASTUPDATEDATE) VALUES
              (PRV_ORGID, PRV_SITEID,FINANCIALPERIODS_REC.FINANCIALPERIOD,
               PRV_ASSETNUM, NUMBER_OF_MILES_T,MILEAGE_COST_T,FEEDER_COST_T,
               TOTAL_NUMBER_OF_TRIPS_T,
               SYSDATE);
        END IF;

      END LOOP -- OUTER LOOP

COMMIT;

END ;


/



















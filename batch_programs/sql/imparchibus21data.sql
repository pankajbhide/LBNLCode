/*****************************************************************************
 PROGRAM NAME           : IMPARCHIBUSDATA.SQL

 DATE WRITTEN           : 8-JUNE-2010

 AUTHOR                 : PANKAJ BHIDE

 USAGE                  :


 PURPOSE                : PROGRAM TO SYNCCHRONIZE THE DATA FROM ARCHIBUS TO
                          MAXIMO

                          DATA SYCHRONIZED FROM ARCHIBUS:

                          USE CODE
                          BUILDINGS
                          FLOORS
                          ROOMS

                          THIS PROGRAM ASSUMES A DATABASE LINK TITLED "ARCHIBUS"
                          THAT CONNECT TO AFM@SHRXXX DATABASE ON WHICH ARCHIBUS
                          APPLICATION IS HOSTED ON.


 MODIFICATION HISTORY:    16-MAR-2011 CHANGED THE FIELDS MAPPING FOR ROOM INFO

                          08-NOV-2011 DON'T SYNC FOR BUILDING 0000 (BLDG 0000 IS
                          A PLACEHOLDER BUILDING. )

                          18-NOV-2011 CHANGES TO REFELCT RE-ADJUSTING HIERARCHY
                          IF FLOOR OF THE ROOM IS CHANGED.

                          21-MAY-2012 REVISION TO FIX CHILDREN COLUMN OF
                          LOCHIERARCHY TABLE

                          2-NOV-2012 REVISION TO BRING RM_CAT AND RM_TYPE FIELDS
                          (ADDED AS PER RT#110321)

                          28-JUN-2013 IF THE PARENT LOCATION IS DISABLED, THEN,
                          DISABLE ALL ITS CHILDREN.

                          07-APR-2014 ROOMS ARE ACTIVATED AND DE-ACTIVATED BASED
                          UPON FLOOR INFORMATION IN ARCHIBUS. WHEN SUCH CHANGES ARE
                          MADE, THE PROGRAM SHOULD APPROPRIATELY RELECT CORRECT
                          FLOOR FOR THE ROOM.
                          
                          01-DEC-2014 CHANGES MADE FOR ARCHIBUS 21
                          
                          
                          22-JAN-15 IF THE ROOM IS INACTIVATED IN ARCHIBUS AND IF
                          IT DOES NOT EXIST IN MAXIMO, NO NEED TO INSERT ITS RECORD
                          INTO MAXIMO.
                          
                          04-JUN-15 SYCHRONIZE ROOM CATEGORY AND ROOM TYPE
                          JIRA EF-1241
                          
                          01-OCT-15 CHANGES REQUIRED FOR MAXIMO 7.6
                          
                          18-DEC-15 DEFAULT VALUE OF SITEID=H 
                          
                          26-FEB-16 RE-CREATE RECORDS IN LOCHIEARCHY AND 
                                    LOCANCESTOR IF THE PARENT OF THE BUILDING
                                    (SITE_ID) IS CHANGED JIRA EF-2832
                          
 ******************************************************************************/
WHENEVER SQLERROR EXIT 1 ROLLBACK;

DECLARE

  CURSOR RMCAT_CUR IS
    SELECT * FROM RMCAT@ARCHIBUS21 
    WHERE RM_CAT IS NOT NULL 
    AND    DESCRIPTION IS NOT NULL ;

  CURSOR RMTYPE_CUR IS
    SELECT * FROM RMTYPE@ARCHIBUS21 
    WHERE RM_CAT IS NOT NULL 
    AND RM_TYPE IS NOT NULL 
    AND DESCRIPTION IS NOT NULL ;


  CURSOR LBNL_USE_CODES_CUR  IS
    --SELECT * FROM LBNL_USE_CODES@ARCHIBUS;
    SELECT * FROM RMUSE@ARCHIBUS21;  -- ARCHIBUS 21


  --CURSOR LBNL_USE_DETAILS_CUR  IS
  --  SELECT * FROM LBNL_USE_DETAILS@ARCHIBUS;

  CURSOR BL_CUR IS
    SELECT * FROM BL@ARCHIBUS21
     WHERE BL_ID NOT IN ('0000') ;

  CURSOR FL_CUR IS
    SELECT * FROM FL@ARCHIBUS21
     WHERE BL_ID NOT IN ('0000') ;

  CURSOR RM_CUR IS
    SELECT * FROM RM@ARCHIBUS21
    WHERE BL_ID NOT IN ('0000')
    ORDER BY BL_ID ASC, RM_ID ASC, LBL_INACTIVE DESC;

  CURSOR ROOMS_CUR IS
    SELECT * FROM SPADM.SPACE_ROOM
     WHERE BUILDING_NUMBER NOT IN ('0000')
     FOR UPDATE;

  CURSOR LOCATIONS_CUR IS
    SELECT * FROM MAXIMO.LOCATIONS WHERE ROWSTAMP IS NULL
     FOR UPDATE;

  CURSOR LOCHIERARCHY_CUR IS
    SELECT LH.* FROM
    LOCATIONS LL, LOCHIERARCHY LH
    WHERE LL.LOCATION=LH.LOCATION
    AND   LL.GISPARAM1 IN ('B','F','R')
    FOR UPDATE;

     T_DESCRIPTION1 MAXIMO.ALNDOMAIN.DESCRIPTION%TYPE;
     EXISTS_T NUMBER(5);
     NO_OF_FLOORS_T NUMBER(5);
     CONSTRUCTION_YEAR_T NUMBER(4);
     LOCATION_T  LOCATIONS.LOCATION%TYPE;
     NUMBER_OF_RECORDS_T NUMBER(5) :=0;
     PROJECT_ID_T LBL_SP_CHARGE_DIST.PROJECT_ID%TYPE;
     CHANGEDATE_T DATE;
     CURR_FLOOR_LOC_T LOCATIONS.LOCATION%TYPE;
     ACT_FLOOR_LOC_T  LOCATIONS.LOCATION%TYPE;
     CURR_FLOOR_T     LOCATIONS.LOCATION%TYPE;
     NEW_ROOM_T       NUMBER(5) :=0;
     CHILDREN_FOUND_T NUMBER(5) :=0;
     T_EXISTING_PARENT  LOCATIONS.LOCATION%TYPE;

     -- ADDED BY PANKAJ ON 6/28/13

     PARENT_T     LOCATIONS.LOCATION%TYPE;
     DISABLED_T   LOCATIONS.DISABLED%TYPE;
    
     CHANGEBY_T   LOCATIONS.CHANGEBY%TYPE; -- 7.6
     
     T_CONSTRAINT_NAME  VARCHAR2(100);
     T_COMMAND          VARCHAR2(100);

     T_RMTYPE  VARCHAR2(100);
     
     CURSOR CUR_INACTIVEPARENTS IS
      SELECT DISTINCT B.PARENT
      FROM LOCHIERARCHY B
      WHERE B.PARENT IN (SELECT A.LOCATION FROM LOCATIONS A
        WHERE A.LOCATION=B.PARENT
        AND A.DISABLED=1)
      ORDER BY 1;

     CURSOR CUR_ANCESTORS IS
      SELECT A.LOCATION FROM LOCANCESTOR A
      WHERE A.ANCESTOR=PARENT_T
      ORDER BY 1;

 BEGIN

    -- MAXIMO 7.6 
    SELECT PROPVALUE
    INTO  CHANGEBY_T 
    FROM MAXPROPVALUE 
    WHERE UPPER(PROPNAME)='MXE.INT.DFLTUSER';

  -- READ ALL THE USE CODE, IF EXISTS, THEN, UPDATE
  -- DESCRIPTION, ELSE, INSERT A NEW RECORD
  
  FOR LBNL_USE_CODES_REC IN LBNL_USE_CODES_CUR

   LOOP

     BEGIN

      SELECT A.DESCRIPTION
      INTO   T_DESCRIPTION1
      FROM   MAXIMO.ALNDOMAIN A
      WHERE  A.DOMAINID='SP_USE_CODES'
      AND    A.VALUE=LBNL_USE_CODES_REC.RM_USE;


      IF (T_DESCRIPTION1 !=
          LBNL_USE_CODES_REC.DESCRIPTION)
           THEN

           UPDATE MAXIMO.ALNDOMAIN
           SET    DESCRIPTION=LBNL_USE_CODES_REC.DESCRIPTION,
                  VALUEID='SP_USE_CODES|' || LBNL_USE_CODES_REC.RM_USE -- FOR 7.6 
           WHERE  DOMAINID='SP_USE_CODES'
           AND    VALUE=LBNL_USE_CODES_REC.RM_USE;
    END IF;

     EXCEPTION

      WHEN NO_DATA_FOUND THEN
           INSERT INTO MAXIMO.ALNDOMAIN
           (DOMAINID,
            VALUE,
            ALNDOMAINID,
            DESCRIPTION,
            VALUEID) -- 7.6
           VALUES('SP_USE_CODES',
           LBNL_USE_CODES_REC.RM_USE,
           ALNDOMAINSEQ.NEXTVAL,
           LBNL_USE_CODES_REC.DESCRIPTION,
           'SP_USE_CODES|' || LBNL_USE_CODES_REC.RM_USE); -- FOR 7.6 

     END;


   END LOOP;
   
  /*** NOT USED ANY MORE AS FACILITIES PLANNING DOES NOT KEEP USE CODE
       AND USE CODE DETAILS UPTO DATE. 
       
  
   --  USE CODE DETAILS
   FOR LBNL_USE_DETAILS_REC IN LBNL_USE_DETAILS_CUR

   LOOP

     BEGIN

      SELECT A.DESCRIPTION
      INTO   T_DESCRIPTION1
      FROM   MAXIMO.ALNDOMAIN A
      WHERE  A.DOMAINID='SP_USE_DETAILS'
      AND    A.VALUE=LBNL_USE_DETAILS_REC.LBNL_USE_DETAIL_CODE;


      IF (T_DESCRIPTION1 !=
          LBNL_USE_DETAILS_REC.LBNL_USE_DETAIL_DESCRIPTION)
           THEN

           UPDATE MAXIMO.ALNDOMAIN
           SET    DESCRIPTION=LBNL_USE_DETAILS_REC.LBNL_USE_DETAIL_DESCRIPTION
           WHERE  DOMAINID='SP_USE_DETAILS'
           AND    VALUE=LBNL_USE_DETAILS_REC.LBNL_USE_DETAIL_CODE;
    END IF;

     EXCEPTION

      WHEN NO_DATA_FOUND THEN
           INSERT INTO MAXIMO.ALNDOMAIN
           (DOMAINID,
            VALUE,
            ALNDOMAINID,
            DESCRIPTION)
           VALUES('SP_USE_DETAILS',
           LBNL_USE_DETAILS_REC.LBNL_USE_DETAIL_CODE,
           ALNDOMAINSEQ.NEXTVAL,
           LBNL_USE_DETAILS_REC.LBNL_USE_DETAIL_DESCRIPTION );

     END;  


   END LOOP; 
**************/

   -- ROOM CATEGORY

   FOR RMCAT_REC IN RMCAT_CUR

   LOOP

     BEGIN

      SELECT A.DESCRIPTION
      INTO   T_DESCRIPTION1
      FROM   MAXIMO.ALNDOMAIN A
      WHERE  A.DOMAINID='LBL_RMCAT'
      AND    A.VALUE=RMCAT_REC.RM_CAT;


      IF (T_DESCRIPTION1 !=
          RMCAT_REC.DESCRIPTION)
           THEN

           UPDATE MAXIMO.ALNDOMAIN
           SET    DESCRIPTION=RMCAT_REC.DESCRIPTION,
                  VALUEID='LBL_RMCAT|' || RMCAT_REC.RM_CAT -- FOR 7.6 
           WHERE  DOMAINID='LBL_RMCAT'
           AND    VALUE=RMCAT_REC.RM_CAT;
    END IF;

     EXCEPTION

      WHEN NO_DATA_FOUND THEN
           INSERT INTO MAXIMO.ALNDOMAIN
           (DOMAINID,
            VALUE,
            ALNDOMAINID,
            DESCRIPTION,
            VALUEID ) -- 7.6
           VALUES('LBL_RMCAT',
           RMCAT_REC.RM_CAT,
           ALNDOMAINSEQ.NEXTVAL,
           RMCAT_REC.DESCRIPTION,
           'LBL_RMCAT|' || RMCAT_REC.RM_CAT -- FOR 7.6 
            );

     END;


   END LOOP;

   -- ROOM TYPE

   FOR RMTYPE_REC IN RMTYPE_CUR

   LOOP

     BEGIN

      SELECT A.DESCRIPTION
      INTO   T_DESCRIPTION1
      FROM   MAXIMO.ALNDOMAIN A
      WHERE  A.DOMAINID='LBL_RMTYPE'
      AND    A.VALUE=RMTYPE_REC.RM_CAT || '-' || RMTYPE_REC.RM_TYPE;


      IF (T_DESCRIPTION1 !=
          RMTYPE_REC.DESCRIPTION)
           THEN

           UPDATE MAXIMO.ALNDOMAIN
           SET    DESCRIPTION=RMTYPE_REC.DESCRIPTION,
                  VALUEID='LBL_RMTYPE|' || RMTYPE_REC.RM_CAT || '-' || RMTYPE_REC.RM_TYPE  -- 7.6
           WHERE  DOMAINID='LBL_RMTYPE'
           AND    VALUE=RMTYPE_REC.RM_CAT || '-' || RMTYPE_REC.RM_TYPE;
    END IF;

     EXCEPTION

      WHEN NO_DATA_FOUND THEN
           INSERT INTO MAXIMO.ALNDOMAIN
           (DOMAINID,
            VALUE,
            ALNDOMAINID,
            DESCRIPTION,
            VALUEID ) -- 7.6
           VALUES('LBL_RMTYPE',
           RMTYPE_REC.RM_CAT || '-' || RMTYPE_REC.RM_TYPE,
           ALNDOMAINSEQ.NEXTVAL,
           RMTYPE_REC.DESCRIPTION,
           'LBL_RMTYPE|'|| RMTYPE_REC.RM_CAT || '-' || RMTYPE_REC.RM_TYPE  -- 7.6
            );

     END;


   END LOOP;



    EXECUTE IMMEDIATE 'ALTER TRIGGER LOCATIONS_T DISABLE ';
    
    SELECT CONSTRAINT_NAME
    INTO   T_CONSTRAINT_NAME
    FROM   USER_CONS_COLUMNS 
    WHERE  TABLE_NAME='LOCATIONS' 
    AND    COLUMN_NAME='ROWSTAMP';

    T_COMMAND := 'ALTER TABLE LOCATIONS DISABLE CONSTRAINT ' || T_CONSTRAINT_NAME;
    EXECUTE IMMEDIATE T_COMMAND;
    

  --************************************************************
  -- READ THE RECORDS FROM BUILDING AND INSERT/UPDATE THE DATA
  -- INTO MAXIMO
  --************************************************************

  FOR BL_REC IN BL_CUR

   LOOP

    CONSTRUCTION_YEAR_T :=TO_NUMBER(TO_CHAR(BL_REC.DATE_BL,'YYYY'));

    BEGIN
      SELECT CHANGEDATE INTO CHANGEDATE_T
      FROM    SPADM.SPACE_BUILDING
      WHERE   BUILDING_NUMBER=BL_REC.BL_ID;

      IF (BL_REC.LBL_CHANGEDATE > CHANGEDATE_T) THEN
      
        SELECT PARENT 
        INTO   T_EXISTING_PARENT
        FROM   LOCHIERARCHY
        WHERE  LOCATION=BL_REC.BL_ID
        AND   SYSTEMID='PRIMARY';
        
        -- IF THE SITE ID HAS CHANGED THEN DELETE EXISTING
        -- RECORDS IN LOCHIEARCHY, LOCANCESTOR WITH OLD PARENT 
        -- AND FIX THEM WITH THE NEW PARENT 
        -- REVISED BY PANKAJ ON 2/26/16 
        IF (T_EXISTING_PARENT != NVL(BL_REC.SITE_ID,'H')) THEN
          
           -- ADJUST LOCHIEARCHY , LOCANCESTOR 
           UPDATE LOCHIERARCHY
           SET PARENT=NVL(BL_REC.SITE_ID,'H')
           WHERE LOCATION=BL_REC.BL_ID
           AND   SYSTEMID='PRIMARY';
           
           UPDATE LOCANCESTOR
           SET ANCESTOR=NVL(BL_REC.SITE_ID,'H')
           WHERE ANCESTOR=T_EXISTING_PARENT
           AND   LOCATION IN (SELECT B.LOCATION
           FROM LOCHIERARCHY B
           START   WITH B.LOCATION=BL_REC.BL_ID
           CONNECT BY PRIOR B.LOCATION= B.PARENT);
      END IF;
            

       UPDATE SPADM.SPACE_BUILDING
       SET   BUILDING_NAME=NVL(BL_REC.NAME,'BUILDING: ' || BL_REC.BL_ID),
             LOCALITY=NVL(BL_REC.SITE_ID,'H'),
             REPORT_CATEGORY=NVL(BL_REC.LBL_REPORT_CATEGORY,'H'),
             FUNCTIONAL_PLAN_AREA=NVL(BL_REC.LBL_FUNCTIONAL_PLAN_AREA,'2'),
             CONSTRUCTION_YEAR=CONSTRUCTION_YEAR_T,
             STRUCTURE_TYPE=NVL(BL_REC.LBL_STRUCTURE_TYPE, 'B'),
             STRUCTURE_DETAIL=BL_REC.LBL_STRUCTURE_DETAIL,
             INACTIVE=NVL(BL_REC.LBL_INACTIVE,0),
             CHANGEBY=CHANGEBY_T,
             CHANGEDATE=SYSDATE
       WHERE  BUILDING_NUMBER=BL_REC.BL_ID;

      END IF;

     EXCEPTION

      WHEN NO_DATA_FOUND THEN


         LOCATION_T :=SPADM.SPACE_PACKAGE.PREPARE_LOCATION(BL_REC.BL_ID,
         NULL,NULL);

         SELECT COUNT(*) INTO NUMBER_OF_RECORDS_T
         FROM  MAXIMO.LOCATIONS
         WHERE LOCATION=LOCATION_T
         AND   SITEID='FAC';
         
        -- INSERT BLDG IN MAXIMO ONLY IF IT IS ACTIVE IN ARCHIBUS 
        IF (NUMBER_OF_RECORDS_T = 0 AND  NVL(BL_REC.LBL_INACTIVE,0)=0) THEN

        INSERT INTO LOCATIONS (
         LO1,
         DESCRIPTION, LO4, LO5,
         LO6, LO14,
         LO7, LO8,
         DISABLED, LOCATION, TYPE, CHANGEDATE, CHANGEBY,
         GISPARAM1,
         ORGID, SITEID,
         ISDEFAULT,
         AUTOWOGEN, USEINPOPR,LANGCODE ,
         LOCATIONSID, HASLD, STATUSDATE,
         PLUSCLOOP,       -- 7.6 
         PLUSCPMEXTDATE , -- 7.6
         ISREPAIRFACILITY , -- 7.6
         STATUS   -- 7.6          
         ) VALUES
         (BL_REC.BL_ID,
          NVL(BL_REC.NAME,'BUILDING: ' || BL_REC.BL_ID), NVL(BL_REC.SITE_ID,'H'), NVL(BL_REC.LBL_REPORT_CATEGORY,'H'),
          NVL(BL_REC.LBL_FUNCTIONAL_PLAN_AREA,'2'), CONSTRUCTION_YEAR_T,
          NVL(BL_REC.LBL_STRUCTURE_TYPE,'B'), BL_REC.LBL_STRUCTURE_DETAIL,
          NVL(BL_REC.LBL_INACTIVE,0), LOCATION_T, 'OPERATING',SYSDATE, CHANGEBY_T,
          'B',
          'LBNL','FAC',
          0,
          0,0,'EN',
          LOCATIONSSEQ.NEXTVAL,0, SYSDATE,
          0,  -- 7.6 
          0,  -- 7.6 
          0,   -- 7.6
          'OPERATING'
          ); 

          SPADM.SPACE_PACKAGE.INSERT_BUILDING (BL_REC.BL_ID,
                                 NVL(BL_REC.SITE_ID,'H'), -- 7.6 DEFAULT HILL 
                                 0, -- NO_OF_FLOORS_T, (DO NOT ADD FLOOR RECORD)
                                 NULL, -- LDKEY 
                                 NULL, -- LDTEXT
                                 NVL(BL_REC.LBL_INACTIVE,0),
                                 CHANGEBY_T);
      END IF ; -- NUMBER OF RECORDS =0

     END;


    END LOOP;  -- BUILDING


  --************************************************************
  -- READ THE RECORDS FROM FLOOR AND INSERT/UPDATE THE DATA
  -- INTO MAXIMO
  --************************************************************

  FOR FL_REC IN FL_CUR

   LOOP


    BEGIN
      SELECT CHANGEDATE  INTO CHANGEDATE_T
      FROM SPADM.SPACE_FLOOR
      WHERE   BUILDING_NUMBER=FL_REC.BL_ID
      AND     FLOOR_NUMBER=FL_REC.FL_ID;

      IF (FL_REC.LBL_CHANGEDATE > CHANGEDATE_T) THEN


      UPDATE SPADM.SPACE_FLOOR
      SET   DESCRIPTION=FL_REC.NAME,
            INACTIVE=NVL(FL_REC.LBL_INACTIVE,0),
            LEVEL_NUMBER=FL_REC.LBL_LEVEL_NUMBER,
            CHANGEBY=CHANGEBY_T,
            CHANGEDATE=SYSDATE
      WHERE  BUILDING_NUMBER=FL_REC.BL_ID
      AND    FLOOR_NUMBER=FL_REC.FL_ID;

     END IF;



     EXCEPTION

      WHEN NO_DATA_FOUND THEN


       LOCATION_T :=SPADM.SPACE_PACKAGE.PREPARE_LOCATION(FL_REC.BL_ID,
       FL_REC.FL_ID, NULL);

       SELECT COUNT(*) INTO NUMBER_OF_RECORDS_T
       FROM  MAXIMO.LOCATIONS
       WHERE LOCATION=LOCATION_T
       AND   SITEID='FAC';

       IF (NUMBER_OF_RECORDS_T =0  AND  NVL(FL_REC.LBL_INACTIVE,0)=0) THEN

        INSERT INTO LOCATIONS (
         LO1,
         LO2,
         DESCRIPTION,
         LO4,
         DISABLED, LOCATION, TYPE, CHANGEDATE, CHANGEBY,
         GISPARAM1,
         ORGID, SITEID,
         ISDEFAULT,
         AUTOWOGEN, USEINPOPR,LANGCODE ,
         LOCATIONSID, HASLD, STATUSDATE,
         PLUSCLOOP,       -- 7.6 
         PLUSCPMEXTDATE , -- 7.6
         ISREPAIRFACILITY , -- 7.6
         STATUS   -- 7.6  
          ) VALUES
         (FL_REC.BL_ID,
          FL_REC.FL_ID,
          FL_REC.NAME,
          FL_REC.LBL_LEVEL_NUMBER,
          NVL(FL_REC.LBL_INACTIVE,0), LOCATION_T, 'OPERATING',SYSDATE, CHANGEBY_T,
          'F',
          'LBNL','FAC',
          0,
          0,0,'EN',
          LOCATIONSSEQ.NEXTVAL,0, SYSDATE,
          0,
          0,
          0,
          'OPERATING'
          );

          SPADM.SPACE_PACKAGE.INSERT_FLOOR(FL_REC.BL_ID,
                                 FL_REC.FL_ID,
                                 NVL(FL_REC.LBL_INACTIVE,0),
                                 FL_REC.LBL_LEVEL_NUMBER,
                                 CHANGEBY_T);

        END IF; -- NUMBER OF RECORDS =0

     END;


    END LOOP;  -- FLOOR


  --************************************************************
  -- READ THE RECORDS FROM ROOM AND INSERT/UPDATE THE DATA
  -- INTO MAXIMO
  --************************************************************

  FOR RM_REC IN RM_CUR

   LOOP


    LOCATION_T :=SPADM.SPACE_PACKAGE.PREPARE_LOCATION(RM_REC.BL_ID,
                 RM_REC.FL_ID, RM_REC.RM_ID);



    NEW_ROOM_T :=0;

    -- CHECK WHETER THE COMBINATION OF BL,FL,RM EXISTST IN MAXIMO
    BEGIN

      SELECT DISABLED, CHANGEDATE INTO DISABLED_T, CHANGEDATE_T
      FROM   MAXIMO.LOCATIONS A
      WHERE  A.LO1=RM_REC.BL_ID
      AND    A.LO2=RM_REC.FL_ID
      AND    A.LO3=RM_REC.RM_ID
      AND    A.GISPARAM1='R';

      NEW_ROOM_T :=0;
    EXCEPTION WHEN NO_DATA_FOUND THEN
       NEW_ROOM_T :=1;
    END;


     -- PREPARE RMTYPE 
     T_RMTYPE :=NULL;
     
     IF (RM_REC.RM_CAT  IS NOT NULL AND
         RM_REC.RM_TYPE IS NOT NULL) THEN
         
          T_RMTYPE :=RM_REC.RM_CAT || '-' ||  RM_REC.RM_TYPE;
     END IF;
         
    -- ROOM EXISTS
    IF (NEW_ROOM_T=0) THEN

     IF (RM_REC.LBL_CHANGEDATE > CHANGEDATE_T) THEN
   
     
     

      UPDATE SPADM.SPACE_ROOM
      SET   DESCRIPTION=NVL(RM_REC.NAME,'BUILDING: '|| RM_REC.BL_ID || '-' ||   RM_REC.RM_ID),
            INACTIVE=NVL(RM_REC.LBL_INACTIVE,0),
            DESIGN_USE=NVL(RM_REC.RM_USE,'OF'),
            --CURRENT_USE=NVL(RM_REC.LBNL_CURRENT_USE,NVL(RM_REC.LBNL_DESIGN_USE,'OF')),
            -- MAPPING CHANGED BY PANKAJ ON 3/15/11
            CURRENT_USE=NVL(RM_REC.RM_USE, 'OF'),
            --CURRENT_USE_DETAIL=NVL(RM_REC.LBNL_CURRENT_USE_DETAIL,'ENCL'),
            AREA=RM_REC.AREA,
            CHARGEABLE=NVL(RM_REC.LBL_CHARGEABLE,'Y'),
            ASSIGNMENT_STATUS=NVL(RM_REC.LBL_ASSIGNMENT_STATUS,'Y'),
            ORG_LEVEL_1_CODE=RM_REC.DV_ID,
            --ORG_LEVEL_2_CODE=RM_REC.ORG_LEVEL_2_CODE, -- THIS WOULD BE MAINTAINTED IN MAXIMO
            --ORG_LEVEL_3_CODE=RM_REC.ORG_LEVEL_3_CODE,
            --ORG_LEVEL_4_CODE=RM_REC.ORG_LEVEL_4_CODE,
            OCCUPIED_PERCENT=NVL(RM_REC.LBL_OCCUPIED_PERCENTAGE,100),
            DIVISION_COMMENTS=RM_REC.LBL_DIVISION_COMMENTS, -- THIS WOULD BE MAINTAINED IN MAXIMO
            LBL_RMCAT=RM_REC.RM_CAT,
            LBL_RMTYPE=T_RMTYPE,
            CHANGEBY=CHANGEBY_T,
            CHANGEDATE=SYSDATE
      WHERE  BUILDING_NUMBER=RM_REC.BL_ID
      AND    FLOOR_NUMBER=RM_REC.FL_ID
      AND    ROOM_NUMBER=RM_REC.RM_ID;

     


   END IF; -- IF (RM_REC.LBNL_CHANGEDATE > CHANGEDATE_T)

  END IF; -- OLD ROOM

    -- ROOM DOES NOT EXIST
    IF (NEW_ROOM_T=1 AND  NVL(RM_REC.LBL_INACTIVE,0)=0) THEN



       -- CHECK WHETHER THE RECORD EXISTS IN LOCATIONS TABLE
       -- FOR LOCATION REFERENCED BY THE ROOM
       SELECT COUNT(*) INTO NUMBER_OF_RECORDS_T
       FROM LOCATIONS
       WHERE LOCATION=LOCATION_T;

       -- IF RECORD EXISTS, THEN, IT IS POSSIBLE
       -- THAT THE FLOOR OF THE ROOM IS CHANGED IN ARCHIBUS
       -- THEREFORE DELETE EXISTING LOCATIONS RELATED RECORD 
       -- FROM MAXIMO AND RE-INSERT THE NEW LOCATIONS RELATED 
       -- RECORD AS PER ARCHIBUS
       -- ADDED ON 4/7/14

        IF (NUMBER_OF_RECORDS_T >0) THEN


         DELETE FROM LOCATIONS
         WHERE LOCATION=LOCATION_T;

         DELETE FROM LOCHIERARCHY
         WHERE LOCATION=LOCATION_T;

         DELETE FROM LOCANCESTOR
         WHERE LOCATION=LOCATION_T;

        END IF;

        -- NOW INSERT INTO LOCATIONS RELATED TABLES
        -- WITH THE LATEST DATA FROM ARCHIBUS
        INSERT INTO LOCATIONS (
         LO1,
         LO2,
         LO3,
         DESCRIPTION,
         LO4,
         LO5,
         --LO6,
         LO14,
         GISPARAM2,
         GISPARAM3,
         LO7,
         LO8,
         LO9,
         LO10,
         LO11,
         LO15,
         DISABLED, LOCATION, TYPE, CHANGEDATE, CHANGEBY,
         GISPARAM1,
         ORGID, SITEID,
         ISDEFAULT,
         AUTOWOGEN, USEINPOPR,LANGCODE ,
         LOCATIONSID, HASLD, STATUSDATE,
         LBL_RMCAT,
         LBL_RMTYPE,
         PLUSCLOOP,       -- 7.6 
         PLUSCPMEXTDATE , -- 7.6
         ISREPAIRFACILITY , -- 7.6
         STATUS   -- 7.6  
            ) VALUES
         (RM_REC.BL_ID,
          RM_REC.FL_ID,
          RM_REC.RM_ID,
          NVL(RM_REC.NAME,'BUILDING: '|| RM_REC.BL_ID || '-' ||   RM_REC.RM_ID),
          NVL(RM_REC.RM_USE,'OF'),
          --NVL(RM_REC.LBNL_CURRENT_USE,NVL(RM_REC.LBNL_DESIGN_USE,'OF')),
          NVL(RM_REC.RM_USE,'OF'),
          -- NVL(RM_REC.LBNL_CURRENT_USE_DETAIL,'ENCL'),
          RM_REC.AREA,
          NVL(RM_REC.LBL_CHARGEABLE,'Y'),
          NVL(RM_REC.LBL_ASSIGNMENT_STATUS,'Y'),
          RM_REC.DV_ID,
          RM_REC.DP_ID,
          RM_REC.LBL_ORG_LEVEL_3_CODE,
          RM_REC.LBL_ORG_LEVEL_4_CODE,
          NVL(RM_REC.LBL_OCCUPIED_PERCENTAGE,100),
          RM_REC.LBL_DIVISION_COMMENTS,
          NVL(RM_REC.LBL_INACTIVE,0), LOCATION_T, 'OPERATING',SYSDATE, CHANGEBY_T,
          'R',
          'LBNL','FAC',
          0,
          0,0,'EN',
          LOCATIONSSEQ.NEXTVAL,0, SYSDATE,
          RM_REC.RM_CAT,
          T_RMTYPE,
          0,
          0,
          0,
          'OPERATING');
          
          SPADM.SPACE_PACKAGE.INSERT_ROOM(RM_REC.BL_ID,
                      RM_REC.FL_ID,
                      RM_REC.RM_ID,
                      NULL,
                      NULL,
                      NVL(RM_REC.LBL_INACTIVE,0),
                      CHANGEBY_T); 
      

    /* NOT REQUIRED REVISION FOR F$M 
      EXISTS_T :=0;

      SELECT COUNT(*)
      INTO  EXISTS_T
      FROM  LBL_SP_CHARGE_DIST
      WHERE BUILDING_NUMBER=RM_REC.BL_ID
      AND   FLOOR_NUMBER=RM_REC.FL_ID
      AND   ROOM_NUMBER=RM_REC.RM_ID;

      IF (EXISTS_T =0 AND RM_REC.ORG_LEVEL_1_CODE IS NOT NULL) THEN

       BEGIN

         SELECT PROJECT_ID
         INTO   PROJECT_ID_T
         FROM   SPADM.SPACE_DEFAULT_PROJECT
         WHERE  ORG_LEVEL_1_CODE=RM_REC.ORG_LEVEL_1_CODE;

        IF (PROJECT_ID_T IS NOT NULL) THEN
         INSERT INTO LBL_SP_CHARGE_DIST
         (BUILDING_NUMBER, FLOOR_NUMBER, ROOM_NUMBER,
          LOCATION, PROJECT_ID, CHARGED_TO_PERCENT,
          CHANGEBY, CHANGEDATE,LBL_SP_CHARGE_DIID,
          ORGID, SITEID)
         VALUES
          (RM_REC.BL_ID ,RM_REC.FL_ID, RM_REC.RM_ID,
           LOCATION_T, PROJECT_ID_T, 100,
           'ARCHIBUS',SYSDATE, LBL_SP_CHARGE_DISTSEQ.NEXTVAL,
           'LBNL','FAC');
        END IF; -- PROJECT_ID_T IS NOT NULL

       EXCEPTION WHEN OTHERS THEN
         NULL;
      END;

    END IF; -- IF (EXISTS_T =0 AND RM_REC.ORG_LEVEL_1_CODE IS NOT NULL) */

   END IF;  --    IF (NEW_ROOM_T=0) THEN

  END LOOP;  -- ROOM


    -- IF ROOMS ARE DELETED FROM ARCHIBUS, THEN, DISABLE THEM FROM 
    -- MAXIMO 

    FOR ROOMS_REC IN ROOMS_CUR

      LOOP

       BEGIN
         SELECT 1 INTO EXISTS_T
         FROM  RM@ARCHIBUS21
         WHERE BL_ID=ROOMS_REC.BUILDING_NUMBER
         AND   FL_ID=ROOMS_REC.FLOOR_NUMBER
         AND   RM_ID=ROOMS_REC.ROOM_NUMBER;

        EXCEPTION
          WHEN NO_DATA_FOUND THEN

          UPDATE SPADM.SPACE_ROOM
          SET   INACTIVE=1, CHANGEDATE=SYSDATE, CHANGEBY=CHANGEBY_T
          WHERE CURRENT OF ROOMS_CUR;

       END;

     END LOOP;

    -- UPDATE CHILDREN FIELD IF REQUIRED 
    FOR LOCHIERARCHY_REC IN LOCHIERARCHY_CUR

     LOOP

      CHILDREN_FOUND_T :=0;

      SELECT COUNT(*) INTO CHILDREN_FOUND_T
      FROM  LOCHIERARCHY LHH1
      WHERE LHH1.PARENT=LOCHIERARCHY_REC.LOCATION;

     IF (CHILDREN_FOUND_T=0) THEN
        UPDATE LOCHIERARCHY
        SET CHILDREN=0
        WHERE CURRENT OF LOCHIERARCHY_CUR;
     ELSE
        UPDATE LOCHIERARCHY
        SET CHILDREN=1
        WHERE CURRENT OF LOCHIERARCHY_CUR;
     END IF;

   END LOOP;


    -- UPDATE ROWSTAMP IF MISSING
    FOR LOCATIONS_REC IN   LOCATIONS_CUR

     LOOP

       UPDATE LOCATIONS
       SET ROWSTAMP=MAXIMO.MAXSEQ.NEXTVAL
       WHERE CURRENT OF LOCATIONS_CUR;

     END LOOP;

    -- DISABLE ALL CHILDREN IF PARENT IS DISABLED 
    -- ADDED BY PANKAJ ON 6/28/13
    FOR REC_INACTIVEPARENTS IN CUR_INACTIVEPARENTS

    LOOP

      PARENT_T:= REC_INACTIVEPARENTS.PARENT;

       FOR REC_ANCESTORS IN CUR_ANCESTORS

        LOOP

           SELECT A.DISABLED
           INTO DISABLED_T
           FROM LOCATIONS A
           WHERE A.LOCATION=REC_ANCESTORS.LOCATION;

           IF (DISABLED_T !=1) THEN

               --DBMS_OUTPUT.PUT_LINE('ACTIVE LOCATION ' || REC_ANCESTORS.LOCATION || ' FOR INACTIVE PARENT ' || PARENT_T);

             UPDATE LOCATIONS A
             SET A.DISABLED=1
             WHERE A.LOCATION=REC_ANCESTORS.LOCATION;

          END IF;

        END LOOP;

   END LOOP;



    EXECUTE IMMEDIATE 'ALTER TRIGGER LOCATIONS_T ENABLE ';

    T_COMMAND := 'ALTER TABLE LOCATIONS ENABLE CONSTRAINT ' || T_CONSTRAINT_NAME;
    EXECUTE IMMEDIATE T_COMMAND;

 COMMIT;

END;

/


CREATE OR REPLACE PACKAGE BODY lbl_maximo_misc_pkg IS

FUNCTION GET_LAST_STATUS(
          ORGID_I  IN MAXIMO.WORKORDER.ORGID%TYPE,
          SITEID_I IN MAXIMO.WORKORDER.SITEID%TYPE,
          WONUM_I    IN MAXIMO.WORKORDER.WONUM%TYPE,
          STATUS_I IN MAXIMO.WOSTATUS.STATUS%TYPE)
          RETURN MAXIMO.WORKORDER.STATUS%TYPE

IS
    STATUS_O MAXIMO.WORKORDER.STATUS%TYPE;
BEGIN
    SELECT STATUS INTO STATUS_O FROM MAXIMO.WOSTATUS
    WHERE ORGID=ORGID_I
    AND   SITEID=SITEID_I
    AND   WONUM=WONUM_I
    AND   STATUS != STATUS_I
    AND CHANGEDATE=(SELECT MAX(CHANGEDATE) FROM WOSTATUS
    WHERE WOSTATUS.ORGID=ORGID_I
    AND   WOSTATUS.SITEID=SITEID_I
    AND   WOSTATUS.WONUM=WONUM_I
    AND   WOSTATUS.STATUS != STATUS_I);


    RETURN STATUS_O;

    EXCEPTION
        WHEN OTHERS THEN
        STATUS_O := NULL;

    RETURN STATUS_O;
END;

FUNCTION GET_ALNDOMAIN_DESC(DOMAINID_I IN ALNDOMAIN.DOMAINID%TYPE,
                            ALNVALUE_I IN ALNDOMAIN.VALUE%TYPE)
                            RETURN ALNDOMAIN.DESCRIPTION%TYPE
IS
 DESCRIPTION_O  ALNDOMAIN.DESCRIPTION%TYPE;
 BEGIN
   SELECT DESCRIPTION INTO DESCRIPTION_O FROM MAXIMO.ALNDOMAIN
   WHERE DOMAINID=RTRIM(DOMAINID_I) AND VALUE=RTRIM(ALNVALUE_I);

   RETURN SUBSTR(DESCRIPTION_O,1,30);

    EXCEPTION

          WHEN OTHERS THEN
         DESCRIPTION_O := NULL;

    RETURN DESCRIPTION_O;

END;


FUNCTION GET_FINANCIALPERIOD(TRANSDATE_I IN FINANCIALPERIODS.PERIODSTART%TYPE)
                              RETURN FINANCIALPERIODS.FINANCIALPERIOD%TYPE
IS
 FINANCIALPERIOD_O  MAXIMO.FINANCIALPERIODS.FINANCIALPERIOD%TYPE;

 BEGIN
   SELECT FINANCIALPERIOD INTO FINANCIALPERIOD_O
   FROM   MAXIMO.FINANCIALPERIODS
   WHERE  ORGID='LBNL'
   AND    TRANSDATE_I >= MAXIMO.FINANCIALPERIODS.PERIODSTART
   AND    TRANSDATE_I < MAXIMO.FINANCIALPERIODS.PERIODEND;

   RETURN FINANCIALPERIOD_O;

    EXCEPTION

          WHEN OTHERS THEN
             FINANCIALPERIOD_O := NULL;

    RETURN FINANCIALPERIOD_O;

END;

--***************************************************************
-- FUNCTION TO FIND WHETHER ANY LOCATION HAZARDS ARE AMONG THE
-- THE HAZARDS SPECIFIED IN A SAFETY PLAN TITLED  FAWC-1
--***************************************************************
FUNCTION CHECK_HAZ_IN_SFPLAN(SITEID_I IN WORKORDER.SITEID%TYPE,
                             LOCATION_I IN WORKORDER.LOCATION%TYPE)
                            RETURN NUMBER

IS
    NUMER_OF_RECORDS_O NUMBER(5) :=0;

 BEGIN

    SELECT COUNT(*) INTO NUMER_OF_RECORDS_O
    FROM MAXIMO.SAFETYLEXICON A, MAXIMO.HAZARD B
    WHERE A.ORGID=B.ORGID
    AND   A.HAZARDID=B.HAZARDID
    AND   A.LOCATION=LOCATION_I
    AND   A.HAZARDID IN (
     SELECT X.HAZARDID
     FROM SAFETYLEXICON X
     WHERE X.SITEID=SITEID_I AND X.SAFETYLEXICONID IN
      (SELECT Y.SAFETYLEXICONID FROM SPLEXICONLINK Y
       WHERE  Y.SITEID=SITEID_I AND Y.SPWORKASSETID IN (SELECT Z.SPWORKASSETID
       FROM   SPWORKASSET Z
       WHERE  Z.SITEID=SITEID_I AND Z.SAFETYPLANID='FAWC-1')));


    RETURN   NUMER_OF_RECORDS_O;

     EXCEPTION

          WHEN OTHERS THEN
           NUMER_OF_RECORDS_O :=0;

     RETURN NUMER_OF_RECORDS_O;
 END;

--****************************************************************
-- FUNCTION TO POPULATE THE HAZARDS/PRECUATIONS TO THE WORK ORDER
-- WHICH ARE ASSOCIATED WITH THE LOCATIONS OR AS PER THE VALUE
-- SPECIFIED ON THE WORK CONTROL HAZARD
--****************************************************************
FUNCTION POPULATE_WOHAZARDS(ORGID_I IN WORKORDER.ORGID%TYPE,
                            SITEID_I IN WORKORDER.SITEID%TYPE,
                            WONUM_I IN WORKORDER.WONUM%TYPE,
                            LOCATION_I IN WORKORDER.LOCATION%TYPE,
                            COPY_FROM_SF_I VARCHAR2,
                            LBL_WCNTRHAZARD_I IN WORKORDER.LBL_WORKCNTRHAZARD%TYPE)
                           RETURN VARCHAR2

IS

 LOCATION_T        WORKORDER.LOCATION%TYPE;
 WONUM_T           WORKORDER.WONUM%TYPE;
 ORGID_T           WORKORDER.ORGID%TYPE;
 SITEID_T          WORKORDER.SITEID%TYPE;
 LDKEY_T           LONGDESCRIPTION.LDKEY%TYPE; -- MXES
 S_LDKEY_T         VARCHAR2(2000);
 LDKEY_T1          LONGDESCRIPTION.LDKEY%TYPE :=NULL; -- MXES
 HAZARDID_T        SAFETYLEXICON.HAZARDID%TYPE;
 WOSAFETYLINKSEQ_T WOSAFETYLINK.WOSAFETYLINKID%TYPE;
 HAZARDID_T1       WOSAFETYLINK.HAZARDID%TYPE;
 PRECAUTIONID_T1   WOPRECAUTION.PRECAUTIONID%TYPE;
 LDTEXT_T          LONGDESCRIPTION.LDTEXT%TYPE;
 V_CURSORID        INTEGER;
 DESCRIPTION_T     HAZARD.DESCRIPTION%TYPE;
 T_PRECAUTIONENABLED VARCHAR2(1);
 HAZMATENABLED_T  VARCHAR2(1);
 TAGOUTENABLED_T  VARCHAR2(1);
 HAZARDTYPE_T     HAZARD.HAZARDTYPE%TYPE;
 COPIED_FROM_T    WOSAFETYLINK.LBL_WOSL02%TYPE;
 HASLD_T          VARCHAR2(1);
 SEQ_NUMBER_T     VARCHAR2(1);
 V_DUMMY          INTEGER;
 V_SELECTSTAT1    VARCHAR2(4000);
 V_SELECTSTAT2    VARCHAR2(4000);
 V_SELECTSTAT3    VARCHAR2(4000);
 V_SELECTSTAT     VARCHAR2(4000);
 NUMBER1_T        NUMBER(6);
 NUMBER2_T        VARCHAR2(10);

    -- CURSOR TO GET ALL PRECUATIONS FOR EACH HAZARD
    -- READ FROM PREVIOUS CURSOR

    CURSOR PRECAUTION_CUR IS
     SELECT  A.HAZARDID, A.PRECAUTIONID, A.ORGID, A.SITEID,
             B.DESCRIPTION, B.HASLD, B.PRECAUTIONUID
     FROM MAXIMO.HAZARDPREC A, PRECAUTION B
     WHERE A.SITEID=B.SITEID
     AND   A.HAZARDID=HAZARDID_T
     AND   A.PRECAUTIONID=B.PRECAUTIONID;

BEGIN

    ORGID_T         := ORGID_I;
    SITEID_T        := SITEID_I;
    LOCATION_T      := NVL(LOCATION_I,'X');
    WONUM_T         := WONUM_I;

    -- DELETE THE EXISTING RECORDS FROM THE WORK ORDER RELATED HAZARDS TABLES
    -- WHICH WERE PREVIOSULY INSERTED THROUGH THIS TRIGGER AND NOT INSERTED
    -- VIA MAXIMO FRAMEWORK

    DELETE FROM MAXIMO.WOSAFETYLINK
    WHERE SITEID=SITEID_T
    AND   WONUM=WONUM_T
    AND   ORGID=ORGID_T
    AND   LBL_WOSL01 IS NOT NULL; --INDICATES THAT THE RECORD WAS PREVIOUSLY INSERTED BY TRIGGER

    DELETE FROM MAXIMO.LONGDESCRIPTION
    WHERE LDOWNERTABLE='WOHAZARD'
    AND   LDOWNERCOL='DESCRIPTION'
    AND   LDKEY IN (SELECT A.WOHAZARDID FROM  MAXIMO.WOHAZARD A
        WHERE A.SITEID=SITEID_T
        AND   A.WONUM=WONUM_T
        AND   A.WOSAFETYDATASOURCE='WO'
        AND   A.ORGID=ORGID_T
        AND   A.LBL_HAZ01 IS NOT NULL --INDICATES THAT THE RECORD WAS PREVIOUSLY INSERTED BY TRIGGER
        AND   A.HASLD=1);    -- MXES

    DELETE FROM MAXIMO.WOHAZARD
    WHERE SITEID=SITEID_T
    AND   WONUM=WONUM_T
    AND   WOSAFETYDATASOURCE='WO'
    AND   ORGID=ORGID_T
    AND   LBL_HAZ01 IS NOT NULL; --INDICATES THAT THE RECORD WAS PREVIOUSLY INSERTED BY TRIGGER

    DELETE FROM MAXIMO.LONGDESCRIPTION
    WHERE  LDOWNERTABLE='WOPRECAUTION'
    AND    LDOWNERCOL='DESCRIPTION'
    AND    LDKEY IN  (SELECT A.WOPRECAUTIONID FROM MAXIMO.WOPRECAUTION A
      WHERE  A.SITEID=SITEID_T
      AND    A.WONUM=WONUM_T
      AND    A.WOSAFETYDATASOURCE='WO'
      AND    A.ORGID=ORGID_T
      AND    A.LBL_PREC01  IS NOT NULL --INDICATES THAT THE RECORD WAS PREVIOUSLY INSERTED BY TRIGGER
      AND    A.HASLD=1);

    DELETE FROM MAXIMO.WOPRECAUTION
    WHERE  SITEID=SITEID_T
    AND    WONUM=WONUM_T
    AND    WOSAFETYDATASOURCE='WO'
    AND    ORGID=ORGID_T
    AND    LBL_PREC01  IS NOT NULL;-- INDICATES THAT THE RECORD WAS PREVIOUSLY INSERTED BY TRIGGER

    DELETE FROM MAXIMO.WOHAZARDPREC
    WHERE  SITEID=SITEID_T
    AND    WONUM=WONUM_T
    AND    WOSAFETYDATASOURCE='WO'
    AND    ORGID=ORGID_T
    AND    LBL_HAZPREC01 IS NOT NULL; -- INDICATES THAT THE RECORD WAS PREVIOUSLY INSERTED BY TRIGGER

    --DELETE FROM LBL_DUMMY;


    -- PREPARE SELECT STATEMENT FOR PROCESSING

    V_SELECTSTAT1 := ' SELECT A.HAZARDID, ' ;
    V_SELECTSTAT1 := V_SELECTSTAT1  || ' B.DESCRIPTION,  LTRIM(RTRIM(TO_CHAR(B.HAZARDUID))) LDKEY, '; -- MXES
    V_SELECTSTAT1 := V_SELECTSTAT1  || ' LTRIM(TO_CHAR(B.PRECAUTIONENABLED)), LTRIM(TO_CHAR(B.HAZMATENABLED)), ';
    V_SELECTSTAT1 := V_SELECTSTAT1  || ' LTRIM(TO_CHAR(B.TAGOUTENABLED)), B.HAZARDTYPE, ';
    V_SELECTSTAT1 := V_SELECTSTAT1  || '''' || '1' || '''' || ' AS SEQ_NUMBER, ';
    V_SELECTSTAT1 := V_SELECTSTAT1  || ' LTRIM(RTRIM(TO_CHAR(B.HASLD))) AS HAS_LD';  -- MXES
    V_SELECTSTAT1 := V_SELECTSTAT1  || ' FROM MAXIMO.SAFETYLEXICON A, ';
    V_SELECTSTAT1 := V_SELECTSTAT1  || ' MAXIMO.HAZARD B ';
    V_SELECTSTAT1 := V_SELECTSTAT1  || ' WHERE A.ORGID=B.ORGID AND  A.HAZARDID=B.HAZARDID ';

    V_SELECTSTAT2 := ' AND   A.LOCATION=' || '''' || LOCATION_T || '''';


    -- IF SUPERVISOR HAS INDICATED THAT THE WORK HAZARD CONTROL IS EITHER 2 OR 4
    -- THEN, WE SHOULD GET THE HAZARDS SPEICIFIED BY THE TASK HAZARD ANALYSIS SAFETYPLAN
    -- FAWAC-1


    IF (LBL_WCNTRHAZARD_I IN ('2', '4')) THEN

     IF (COPY_FROM_SF_I ='Y') THEN

       -- GET LOCATION SPECIFIC HAZARDS AND HAZARDS COMMON BETWEEN FAWAC-1 SAFETYPLAN

       V_SELECTSTAT3 := ' SELECT A.HAZARDID, ' ;
       V_SELECTSTAT3 := V_SELECTSTAT3  || ' A.DESCRIPTION, LTRIM(RTRIM(TO_CHAR(A.HAZARDUID))) LDKEY, '; -- MXES
       V_SELECTSTAT3 := V_SELECTSTAT3  || ' A.PRECAUTIONENABLED, A.HAZMATENABLED, ';
       V_SELECTSTAT3 := V_SELECTSTAT3  || ' A.TAGOUTENABLED, A.HAZARDTYPE, ';
       V_SELECTSTAT3 := V_SELECTSTAT3  || '''' || '2' || '''' || ' AS SEQ_NUMBER, ';
       V_SELECTSTAT3 := V_SELECTSTAT3  || ' LTRIM(RTRIM(TO_CHAR(A.HASLD))) AS HAS_LD';  -- MXES
       V_SELECTSTAT3 := V_SELECTSTAT3  || ' FROM MAXIMO.HAZARD A';
       V_SELECTSTAT3 := V_SELECTSTAT3 || '  WHERE A.HAZARDID IN ( ';
       V_SELECTSTAT3 := V_SELECTSTAT3 || '  SELECT X.HAZARDID  FROM SAFETYLEXICON X ';
       V_SELECTSTAT3 := V_SELECTSTAT3 || '  WHERE X.SITEID=' || '''' || SITEID_T || '''' || ' AND X.SAFETYLEXICONID IN ';
       V_SELECTSTAT3 := V_SELECTSTAT3 || '  (SELECT Y.SAFETYLEXICONID FROM SPLEXICONLINK Y ';
       V_SELECTSTAT3 := V_SELECTSTAT3 || '  WHERE  Y.SITEID=' || '''' || SITEID_I || '''';
       V_SELECTSTAT3 := V_SELECTSTAT3 || '  AND Y.SPWORKASSETID IN (SELECT Z.SPWORKASSETID ';
       V_SELECTSTAT3 := V_SELECTSTAT3 || '  FROM   SPWORKASSET Z ';
       V_SELECTSTAT3 := V_SELECTSTAT3 || '  WHERE  Z.SITEID=' || '''' ||SITEID_I || '''';
       V_SELECTSTAT3 := V_SELECTSTAT3 || '  AND Z.SAFETYPLANID='|| '''' || 'FAWC-1' || ''''||')))';
       V_SELECTSTAT3 := V_SELECTSTAT3 || '  ORDER BY 8,1 '; -- 8->SEQ_NUMBER

       V_SELECTSTAT  := V_SELECTSTAT1 || V_SELECTSTAT2 ||   '  UNION ALL ' || V_SELECTSTAT3;

      ELSE --  IF (COPY_FROM_SF_I ='Y') THEN

        V_SELECTSTAT  := V_SELECTSTAT1  || V_SELECTSTAT2 || ' ORDER BY 8,1 ';  -- ONLY LOCATION SPECIFIC HAZARDS

      END IF; --  IF (COPY_FROM_SF_I ='Y') THEN

    ELSE  --   IF (LBL_WCNTRHAZARD_I IN ('2', '4')) THEN

     V_SELECTSTAT  := V_SELECTSTAT1  || V_SELECTSTAT2 || ' ORDER BY 8,1 ';  -- ONLY LOCATION SPECIFIC HAZARDS

    END IF;

   NUMBER1_T := 100;
   NUMBER2_T :=LTRIM(TO_CHAR(NUMBER1_T));

   --INSERT INTO LBL_DUMMY(COL1, COL2, COL3 ) VALUES (V_SELECTSTAT, SYSDATE,NUMBER2_T);


   -- OPEN CURSOR FOR PROCESSING
   V_CURSORID :=DBMS_SQL.OPEN_CURSOR;


   -- PARSE THE QUERY USING CURSOR
   DBMS_SQL.PARSE(V_CURSORID, V_SELECTSTAT, DBMS_SQL.NATIVE);


   -- DEFINE SELECT LIST ITEMS

   DBMS_SQL.DEFINE_COLUMN(V_CURSORID,1, HAZARDID_T, 100);
   DBMS_SQL.DEFINE_COLUMN(V_CURSORID,2, DESCRIPTION_T, 4000);
   DBMS_SQL.DEFINE_COLUMN(V_CURSORID,3, S_LDKEY_T, 2000);
   DBMS_SQL.DEFINE_COLUMN(V_CURSORID,4, T_PRECAUTIONENABLED, 100);
   DBMS_SQL.DEFINE_COLUMN(V_CURSORID,5, HAZMATENABLED_T, 100);
   DBMS_SQL.DEFINE_COLUMN(V_CURSORID,6, TAGOUTENABLED_T, 100);
   DBMS_SQL.DEFINE_COLUMN(V_CURSORID,7, HAZARDTYPE_T, 100);
   DBMS_SQL.DEFINE_COLUMN(V_CURSORID,8, SEQ_NUMBER_T, 100);
   DBMS_SQL.DEFINE_COLUMN(V_CURSORID,9, HASLD_T, 100);  -- MXES


   --EXECUTE THIS STATEMENT. WE DO NOT CARE ABOUT THE RETURN
   -- VALUE.

   V_DUMMY := DBMS_SQL.EXECUTE(V_CURSORID);


   -- FETCH THE ROWS IN THE BUFFER AND ALSO CHECK FOR THE EXIT CONDITION
   LOOP  -- OUTER LOOP

     IF DBMS_SQL.FETCH_ROWS(V_CURSORID) = 0 THEN
         EXIT;
     END IF;

   -- RETRIEVE THE ROWS FROM THE BUFFER INTO PL/SQL VARIABLES

   DBMS_SQL.COLUMN_VALUE(V_CURSORID,1, HAZARDID_T);
   DBMS_SQL.COLUMN_VALUE(V_CURSORID,2, DESCRIPTION_T);
   DBMS_SQL.COLUMN_VALUE(V_CURSORID,3, S_LDKEY_T);
   DBMS_SQL.COLUMN_VALUE(V_CURSORID,4, T_PRECAUTIONENABLED);
   DBMS_SQL.COLUMN_VALUE(V_CURSORID,5, HAZMATENABLED_T);
   DBMS_SQL.COLUMN_VALUE(V_CURSORID,6, TAGOUTENABLED_T);
   DBMS_SQL.COLUMN_VALUE(V_CURSORID,7, HAZARDTYPE_T);
   DBMS_SQL.COLUMN_VALUE(V_CURSORID,8, SEQ_NUMBER_T);
   DBMS_SQL.COLUMN_VALUE(V_CURSORID,9, HASLD_T);


   HAZARDID_T := LTRIM(RTRIM(HAZARDID_T));
   DESCRIPTION_T := LTRIM(RTRIM(DESCRIPTION_T));
   T_PRECAUTIONENABLED := LTRIM(RTRIM(T_PRECAUTIONENABLED));
   HAZMATENABLED_T := LTRIM(RTRIM(HAZMATENABLED_T));
   TAGOUTENABLED_T := LTRIM(RTRIM(TAGOUTENABLED_T));
   HAZARDTYPE_T := LTRIM(RTRIM(HAZARDTYPE_T));
   S_LDKEY_T := LTRIM(RTRIM(S_LDKEY_T));
   SEQ_NUMBER_T := LTRIM(RTRIM(SEQ_NUMBER_T));
   HASLD_T     := LTRIM(RTRIM(HASLD_T));

     NUMBER1_T := NUMBER1_T + 10;
     NUMBER2_T :=LTRIM(TO_CHAR(NUMBER1_T));

   --  INSERT INTO LBL_DUMMY(COL1, COL2, COL3) VALUES ('PROCESSING HAZARD: ' || HAZARDID_T, SYSDATE,NUMBER2_T);

   -- MARK THE HAZARDS COPIED FROM SAFETY PLAN FAWC-1
   -- SO THAT THE SUPERVISORS CAN DELETE NON-APPLICABLE HAZARDS

   COPIED_FROM_T := NULL;

    IF (COPY_FROM_SF_I ='Y') THEN

     IF (SEQ_NUMBER_T ='2') THEN -- INDICATES THAT THEY ARE FROM FAWAC-1

       IF (LBL_WCNTRHAZARD_I ='2') THEN
          COPIED_FROM_T := 'FORMAL AUTH:FAWC-1';
       END IF;

       IF (LBL_WCNTRHAZARD_I ='4') THEN
         COPIED_FROM_T := 'FORMAL AUTH+TASK JHA';
       END IF;

      END IF ; -- IF (SEQ_NUMBER_T ='2')

   END IF; -- IF (COPY_FROM_SF_I ='N') THEN


   LDKEY_T1 := NULL;
   LDTEXT_T := NULL;

     BEGIN -- CHECK RECORD IN MAXIMO.WOSAFETYLINK

     SELECT HAZARDID INTO HAZARDID_T1
     FROM   MAXIMO.WOSAFETYLINK
     WHERE  SITEID=SITEID_T
     AND    WONUM=WONUM_T
     AND    HAZARDID=HAZARDID_T
     AND    LOCATION=LOCATION_T
     AND    ORGID=ORGID_T;

     EXCEPTION

      WHEN OTHERS THEN

        SELECT WOSAFETYLINKSEQ.NEXTVAL INTO WOSAFETYLINKSEQ_T FROM SYS.DUAL;

         -- START INSERTING THE HAZARD RECORDS IN RELEVANT TABLES
         INSERT INTO MAXIMO.WOSAFETYLINK (LOCATION, HAZARDID, WOSAFETYLINKID, ORGID,
                     WONUM, WOSAFETYDATASOURCE, SITEID, LBL_WOSL01, LBL_WOSL02)
         VALUES (LOCATION_T, HAZARDID_T, WOSAFETYLINKSEQ_T, ORGID_T,
                 WONUM_T, 'WO',SITEID_T, 'LBL', COPIED_FROM_T);

          NUMBER1_T := NUMBER1_T + 10;
          NUMBER2_T :=LTRIM(TO_CHAR(NUMBER1_T));
         -- INSERT INTO LBL_DUMMY(COL1,COL2, COL3) VALUES ('INSERTED HAZARD WOSAFETYLINK ' || HAZARDID_T, SYSDATE,NUMBER2_T);

          SELECT WOHAZARDSEQ.NEXTVAL INTO LDKEY_T1 FROM DUAL;

          IF (HASLD_T ='1')  THEN -- MXES

            -- GET LDTEXT FOR THE HAZARD

           BEGIN
             SELECT A.LDTEXT INTO LDTEXT_T
             FROM MAXIMO.LONGDESCRIPTION A
             WHERE A.LDOWNERTABLE='HAZARD'
             AND   A.LDOWNERCOL='DESCRIPTION'
             AND   A.LDKEY=S_LDKEY_T;

            EXCEPTION
              WHEN OTHERS THEN
               NULL;
            END;

           -- THIS HAZARD DOES CONTAIN LONG DESCRIPTION

           INSERT INTO MAXIMO.LONGDESCRIPTION (LDKEY, LDTEXT, LDOWNERCOL, LDOWNERTABLE,
           LANGCODE, LONGDESCRIPTIONID)
           VALUES (LDKEY_T1, LDTEXT_T, 'DESCRIPTION','WOHAZARD',
           'EN',LONGDESCRIPTIONSEQ.NEXTVAL);

         END IF; -- IF (HASLD_T=1)
       END;  -- RECORD EXISTS IN MAXIMO.WOSAFETYLINK

       BEGIN -- CHECK RECORD EXISTS IN WOHAZARD TABLE

          SELECT HAZARDID INTO HAZARDID_T1
          FROM   MAXIMO.WOHAZARD
          WHERE SITEID=SITEID_T
          AND   WONUM=WONUM_T
          AND   HAZARDID=HAZARDID_T
          AND   ORGID=ORGID_T;

         EXCEPTION
           WHEN OTHERS THEN

           INSERT INTO MAXIMO.WOHAZARD (WONUM, HAZARDID, WOHAZARDID,
           PRECAUTIONENABLED, HAZMATENABLED, TAGOUTENABLED,
           HAZARDTYPE,LBL_HAZ01,WOSAFETYDATASOURCE, DESCRIPTION,
           ORGID, SITEID, LANGCODE, HAZ20, HASLD) VALUES
           (WONUM_T, HAZARDID_T, LDKEY_T1,
            TO_NUMBER(T_PRECAUTIONENABLED), TO_NUMBER(HAZMATENABLED_T), TO_NUMBER(TAGOUTENABLED_T),
            HAZARDTYPE_T, 'LBL', 'WO', DESCRIPTION_T,
            ORGID_T, SITEID_T,'EN','0', TO_NUMBER(HASLD_T));

           NUMBER1_T := NUMBER1_T + 10;
           NUMBER2_T :=LTRIM(TO_CHAR(NUMBER1_T));
          -- INSERT INTO LBL_DUMMY(COL1, COL2, COL3) VALUES ('INSERTED HAZARD WOHAZARD ' || HAZARDID_T, SYSDATE, NUMBER2_T);

        END; -- CHECK RECORD EXISTS IN WOHAZARD TABLE


        -- START INSERTING THE PRECAUTION RECORDS FOR EACH HAZARD
         FOR PRECAUTION_REC IN PRECAUTION_CUR

          LOOP

            BEGIN -- CHECK INTO WOHAZARDPREC

              SELECT HAZARDID INTO HAZARDID_T1
              FROM   MAXIMO.WOHAZARDPREC
              WHERE  SITEID=SITEID_T
              AND    WONUM=WONUM_T
              AND    HAZARDID=PRECAUTION_REC.HAZARDID
              AND    PRECAUTIONID=PRECAUTION_REC.PRECAUTIONID;

             EXCEPTION
              WHEN OTHERS THEN


              INSERT INTO MAXIMO.WOHAZARDPREC (WONUM, HAZARDID, PRECAUTIONID,
               WOSAFETYDATASOURCE, ORGID, SITEID, LBL_HAZPREC01, WOHAZARDPRECID)
               VALUES
               (WONUM_T, PRECAUTION_REC.HAZARDID, PRECAUTION_REC.PRECAUTIONID,
                'WO', ORGID_T, SITEID_T, 'LBL',WOHAZARDPRECSEQ.NEXTVAL);

           NUMBER1_T := NUMBER1_T + 10;
           NUMBER2_T :=LTRIM(TO_CHAR(NUMBER1_T));
          -- INSERT INTO LBL_DUMMY(COL1,COL2, COL3) VALUES ('INSERTED PRECAUTION WOHAZARDPREC ' || PRECAUTION_REC.HAZARDID|| '-' || PRECAUTION_REC.PRECAUTIONID, SYSDATE, NUMBER2_T);

           END; -- CHECK INTO WOHAZARDPREC

           BEGIN -- CHECK RECORD EXISTS IN WOPRECAUTION

            LDKEY_T :=NULL;

            SELECT PRECAUTIONID INTO PRECAUTIONID_T1
            FROM   MAXIMO.WOPRECAUTION
            WHERE  SITEID=SITEID_T
            AND    WONUM=WONUM_T
            AND    PRECAUTIONID=PRECAUTION_REC.PRECAUTIONID;

           EXCEPTION


             WHEN OTHERS THEN

             SELECT WOPRECAUTIONSEQ.NEXTVAL INTO LDKEY_T FROM DUAL;

             INSERT INTO WOPRECAUTION (WONUM, PRECAUTIONID, DESCRIPTION,
               WOSAFETYDATASOURCE, ORGID, SITEID, WOPRECAUTIONID,
               LBL_PREC01, PREC10, LANGCODE, HASLD) VALUES
               (WONUM_T,  PRECAUTION_REC.PRECAUTIONID, PRECAUTION_REC.DESCRIPTION,
                'WO', ORGID_T, SITEID_T, LDKEY_T,
                'LBL','0','EN',PRECAUTION_REC.HASLD);

                 NUMBER1_T := NUMBER1_T + 10;
                 NUMBER2_T :=LTRIM(TO_CHAR(NUMBER1_T));
                 --INSERT INTO LBL_DUMMY(COL1, COL2, COL3) VALUES ('INSERTED PRECAUTION WOPRECAUTION ' || PRECAUTION_REC.HAZARDID || '-' || PRECAUTION_REC.PRECAUTIONID, SYSDATE, NUMBER2_T);

               LDTEXT_T :=NULL;
               IF (PRECAUTION_REC.HASLD=1) THEN
                -- THIS PRECAUTION DOES CONTAIN LONG DESCRIPTION


                BEGIN
                 SELECT LDTEXT_T INTO LDTEXT_T
                 FROM   MAXIMO.LONGDESCRIPTION
                 WHERE  LDOWNERTABLE='PRECAUTION'
                 AND    LDOWNERCOL='DESCRIPTION'
                 AND    LDKEY=PRECAUTION_REC.PRECAUTIONUID;

                 EXCEPTION WHEN  OTHERS
                  THEN
                     LDTEXT_T :=NULL;
               END;

               IF (LDTEXT_T IS NOT NULL) THEN
                 INSERT INTO MAXIMO.LONGDESCRIPTION (LDKEY, LDTEXT, LDOWNERCOL, LDOWNERTABLE,
                 LANGCODE, LONGDESCRIPTIONID)
                 VALUES (LDKEY_T,  LDTEXT_T, 'DESCRIPTION','WOPRECAUTION',
                 'EN',LONGDESCRIPTIONSEQ.NEXTVAL);
               END IF; -- LDTEXT_T IS NOT NULL

               END IF; --IF (RECAUTION_REC.HAS_LD=1)

          END; -- CHECK RECORD EXISTS IN WOPRECAUTION

        END LOOP; -- FOR PRECAUTION_REC IN PRECAUTION_CUR

   END LOOP; -- OUTER LOOP

   DBMS_SQL.CLOSE_CURSOR(V_CURSORID);

    RETURN '1';

    EXCEPTION
       WHEN OTHERS THEN
         DBMS_SQL.CLOSE_CURSOR(V_CURSORID);

  RETURN '0';
END;

--*********************************************************************
-- FUNCTION TO CHECK WHTHER LOCATION HAZARDS HAVE BEEN INSERTED OR NOT
--*********************************************************************
FUNCTION WOHAZARDS_EXIST(ORGID_I IN WORKORDER.ORGID%TYPE,
                         SITEID_I IN WORKORDER.SITEID%TYPE,
                         WONUM_I IN WORKORDER.WONUM%TYPE)
                        RETURN NUMBER
IS
  REC_CNT_T NUMBER(5) :=0;

BEGIN


    SELECT COUNT(*) INTO REC_CNT_T FROM MAXIMO.WOSAFETYLINK
    WHERE SITEID=SITEID_I
    AND   WONUM=WONUM_I
    AND   ORGID=ORGID_I
    AND   LBL_WOSL01 IS NOT NULL;

    RETURN REC_CNT_T;
END;

END;
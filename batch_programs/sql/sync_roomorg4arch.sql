/*****************************************************************************
 PROGRAM NAME           : SYNC_ROOMORG4arch.SQL

 DATE WRITTEN           : 24-JAN-2011

 AUTHOR                 : PANKAJ BHIDE

 USAGE                  :


 PURPOSE                : PROGRAM TO SYNCCHRONIZE THE ORGANIZATION STRUCTURE DATA
                          ASSOCIATED WITH ROOMS

                         THIS PROGRAM ASSUMES A DATABASE LINK TITLED "archibus23"
                         THAT CONNECT TO AFM@ARCHPRD DATABASE ON WHICH ARCHIBUS
                         APPLICATION IS HOSTED ON.

                         ARPIL 11 - MODIFIED FOR ARCHIBUS 21

                         MAR 22, 2016 - PANKAJ - JIRA EF-3108
                         
                         FEB 1, 2017 - PANKAJ - REVISION FOR VER 23

 ******************************************************************************/
WHENEVER SQLERROR EXIT 1 ROLLBACK;

DECLARE

  CURSOR ROOM_CUR  IS SELECT * FROM SPADM.SPACE_ROOM  A
                      WHERE A.ORG_LEVEL_1_CODE IS NOT NULL ORDER BY LOCATION;

  TEMP1_T VARCHAR2(2000);
  TEMP2_T VARCHAR2(2000);
  REC_CNT_T  NUMBER(6) :=0;

 BEGIN


    DBMS_OUTPUT.ENABLE(1000000);

  -- READ ALL ROOM RECORDS HAVING LEVEL-1 NOT NULL
  -- THE INFORMATION ABOUT LEVEL2, LEVEL3 AND LEVEL4 WOULD BE MAINTAINED BY
  -- MAXIMO. THIS INFORMATION IS REQUIRED TO SYNCHRONIZED TO ARCHIBUS

  FOR ROOM_REC IN ROOM_CUR

   LOOP

     BEGIN

      SELECT  NVL(DP_ID,'X') || NVL(lbl_org_level_3_code,'X') || NVL(lbl_org_level_4_code,'X')
      INTO    TEMP1_T
      FROM    RM@archibus23  B
      WHERE   B.BL_ID=ROOM_REC.BUILDING_NUMBER
      AND     B.FL_ID=ROOM_REC.FLOOR_NUMBER
      AND     B.RM_ID=ROOM_REC.ROOM_NUMBER
      AND     B.DV_ID=ROOM_REC.ORG_LEVEL_1_CODE;  -- VER 21


      -- UPDATE ONLY WHEN LEVEL1 IS SAME AS WHAT IS RECORDED IN
      -- MAXIMO AND ARCHIBUS

     IF ((ROOM_REC.ORG_LEVEL_2_CODE  IS NOT NULL)  OR
         (ROOM_REC.ORG_LEVEL_3_CODE  IS NOT NULL) OR
         (ROOM_REC.ORG_LEVEL_4_CODE  IS NOT NULL )) THEN

      -- CHECK WHETHER ARE THERE ANY CHANGES;
      TEMP2_T := NVL(ROOM_REC.ORG_LEVEL_2_CODE,'X') || NVL(ROOM_REC.ORG_LEVEL_3_CODE,'X')
                 || NVL(ROOM_REC.ORG_LEVEL_4_CODE,'X');

      IF (TEMP1_T != TEMP2_T) THEN

        IF (ROOM_REC.ORG_LEVEL_2_CODE IS NOT NULL) THEN

         REC_CNT_T :=0;
         SELECT COUNT(*) INTO REC_CNT_T
         FROM    DP@archibus23
         WHERE   DV_ID=ROOM_REC.ORG_LEVEL_1_CODE
         AND     DP_ID=ROOM_REC.ORG_LEVEL_2_CODE;


         IF (REC_CNT_T =1) THEN
           UPDATE  RM@archibus23 B
           SET     DP_ID=ROOM_REC.ORG_LEVEL_2_CODE,
                   LBL_ORG_LEVEL_3_CODE =NULL, LBL_ORG_LEVEL_4_CODE=NULL -- EF-3108
           WHERE   B.BL_ID=ROOM_REC.BUILDING_NUMBER
           AND     B.FL_ID=ROOM_REC.FLOOR_NUMBER
           AND     B.RM_ID=ROOM_REC.ROOM_NUMBER
           AND     B.DV_ID=ROOM_REC.ORG_LEVEL_1_CODE;
        END IF ; --  IF (REC_CNT_T =1) THEN

       END IF; -- IF (ROOM_REC.ORG_LEVEL_2_CODE  IS NOT NULL) THEN

       IF ((ROOM_REC.ORG_LEVEL_2_CODE  IS NOT NULL) AND
           (ROOM_REC.ORG_LEVEL_3_CODE  IS NOT NULL))
        THEN


         REC_CNT_T :=0;
         SELECT COUNT(*) INTO REC_CNT_T
         FROM    lbl_org_level_3@archibus23
         WHERE   DV_ID=ROOM_REC.ORG_LEVEL_1_CODE
         AND     DP_ID=ROOM_REC.ORG_LEVEL_2_CODE
         AND     lbl_org_level_3_code=ROOM_REC.ORG_LEVEL_3_CODE;

         dbms_output.put_line('rec_cnt: ' ||  to_char(rec_cnt_t));

         IF (REC_CNT_T=1) THEN
           UPDATE  RM@archibus23 B
           SET     lbl_org_level_3_code=ROOM_REC.ORG_LEVEL_3_CODE,
                   LBL_ORG_LEVEL_4_CODE=NULL -- EF-3108
           WHERE   B.BL_ID=ROOM_REC.BUILDING_NUMBER
           AND     B.FL_ID=ROOM_REC.FLOOR_NUMBER
           AND     B.RM_ID=ROOM_REC.ROOM_NUMBER
           AND     B.DV_ID=ROOM_REC.ORG_LEVEL_1_CODE
           AND     B.DP_ID=ROOM_REC.ORG_LEVEL_2_CODE;
        END IF ; --  IF (REC_CNT_T =1) THEN

       END IF; -- IF (ROOM_REC.ORG_LEVEL_3_CODE  IS NOT NULL) THEN

       IF ((ROOM_REC.ORG_LEVEL_2_CODE  IS NOT NULL) AND
           (ROOM_REC.ORG_LEVEL_3_CODE  IS NOT NULL) AND
           (ROOM_REC.ORG_LEVEL_4_CODE  IS NOT NULL))
        THEN

         REC_CNT_T :=0;
         SELECT COUNT(*) INTO REC_CNT_T
         FROM    lbl_org_level_4@archibus23
         WHERE   DV_ID=ROOM_REC.ORG_LEVEL_1_CODE
         AND     DP_ID=ROOM_REC.ORG_LEVEL_2_CODE
         AND     lbl_org_level_3_code=ROOM_REC.ORG_LEVEL_3_CODE
         AND     lbl_org_level_4_code=ROOM_REC.ORG_LEVEL_4_CODE;

         IF (REC_CNT_T =1) THEN
           UPDATE  RM@archibus23 B
           SET     lbl_org_level_4_code=ROOM_REC.ORG_LEVEL_4_CODE
           WHERE   B.BL_ID=ROOM_REC.BUILDING_NUMBER
           AND     B.FL_ID=ROOM_REC.FLOOR_NUMBER
           AND     B.RM_ID=ROOM_REC.ROOM_NUMBER
           AND     B.DV_ID=ROOM_REC.ORG_LEVEL_1_CODE
           AND     B.DP_ID=ROOM_REC.ORG_LEVEL_2_CODE
           AND     B.lbl_org_level_3_code=ROOM_REC.ORG_LEVEL_3_CODE;
        END IF ; --  IF (REC_CNT_T =1) THEN

       END IF; -- IF (ROOM_REC.ORG_LEVEL_4_CODE  IS NOT NULL) THEN

     END IF;  --    IF (TEMP1_T != TEMP2_T) THEN

    END IF; --((ROOM_REC.ORG_LEVEL_2_CODE 3, 4 IS NOT NULL)

     EXCEPTION

      WHEN NO_DATA_FOUND THEN
           NULL;


     END;

  END LOOP;


COMMIT;

END;


 /

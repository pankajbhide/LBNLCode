/*******************************************************************************
 PROGRAM NAME           : EXPORTFLAGS.SQL

 DATE WRITTEN           : 09-SEP-2016

 AUTHOR                 : PANKAJ BHIDE

 USAGE                  :


 PURPOSE                : INTERFACE PROGRAM TO EXPORT INFORMATION ABOUT
                          FLAGS INSERTED BY PEOPLESOFT FOR EXPORTING
                          IT TO SCLOGIC.

********************************************************************************/
--WHENEVER SQLERROR EXIT 1 ROLLBACK;

DECLARE

    CURSOR FLAGS_CUR IS
      SELECT * FROM FMS_LINK_ID.FLAGS A
      WHERE A.LASTMODIFIED >= (SELECT (TO_DATE(VARVALUE,'YYYY-MM-DD HH24:MI:SS')-90)
      FROM  FMS_LINK_ID.LBL_IBOXVARS WHERE VARNAME='LASTDTTM_FLAGSSENT');

    CURSOR PO_CUR IS
      SELECT * FROM FMS_LINK_ID.LBL_PS2IBOXINFO B
      WHERE B.DATE_INSERTED >= (SELECT (TO_DATE(VARVALUE,'YYYY-MM-DD HH24:MI:SS')-90)
      FROM  FMS_LINK_ID.LBL_IBOXVARS WHERE VARNAME='LASTDTTM_POSENT');



     T_FILEHANDLER1 UTL_FILE.FILE_TYPE;
     T_FILENAME1    VARCHAR2(50);

     T_FILEHANDLER2 UTL_FILE.FILE_TYPE;
     T_FILENAME2    VARCHAR2(50);

     T_CONTENT     VARCHAR2(32000);
     ROW_CNT_T NUMBER(10) :=0;



BEGIN

   T_FILENAME1     :='Flags.txt';
   T_FILEHANDLER1  :=UTL_FILE.FOPEN('MAXIMO', T_FILENAME1, 'W');

   T_FILENAME2     :='lbl_ps2iboxinfo.txt';
   T_FILEHANDLER2  :=UTL_FILE.FOPEN('MAXIMO', T_FILENAME2, 'W');


   -- START READING FLAGS INFORMATION
   FOR FLAGS_REC IN FLAGS_CUR

    LOOP

        ROW_CNT_T :=ROW_CNT_T + 1;
        IF (ROW_CNT_T =1) THEN
           T_CONTENT :='FLAGTYPE|FLAGREFID|FLAGDESCRIPTION|FLAGACTIVE|FLAGADDER|FLAGSTARTDATE|FLAGENDDATE|PROFILEID|LASTMODIFIED';
           UTL_FILE.PUT_LINE(T_FILEHANDLER1, T_CONTENT );
        END IF;

        T_CONTENT := '0'                      ||'|' || -- FLAGTYPE=0 FOR POS
                     FLAGS_REC.ASSETID        ||'|' || -- PO NUMBER
                     FLAGS_REC.DESCRIPTION    ||'|' ||
                     FLAGS_REC.ACTIVE         ||'|' ||
                     'PO-PCARD'               ||'|' || -- FLAG ADDER
                     TO_CHAR(FLAGS_REC.DATE_,  'YYYY-MM-DD HH24:MI:SS')   ||'|' || -- FLAG START DATE
                     TO_CHAR(FLAGS_REC.EXPIRES,'YYYY-MM-DD HH24:MI:SS')  ||'|' || -- FLAG END   DATE
                     '1'                      ||'|' ||  -- PROFILE ID=1
                     TO_CHAR(FLAGS_REC.LASTMODIFIED,'YYYY-MM-DD HH24:MI:SS');  -- LASTMODIFIED

         UTL_FILE.PUT_LINE(T_FILEHANDLER1, T_CONTENT );
      END LOOP;

  UTL_FILE.FCLOSE(T_FILEHANDLER1);

  -- START READING PO INFORMATION
  ROW_CNT_T :=0;
  FOR PO_REC IN PO_CUR

    LOOP

        ROW_CNT_T :=ROW_CNT_T + 1;
        IF (ROW_CNT_T =1) THEN
           T_CONTENT :='PO_ID|RECIPIENT_NAME|VENDOR_NAME|DELIVER_TO|ATTEN_TO_NAME|REQUESTER_NAME|TOTAL_PO_AMT|RECEIVING_REQD|SOURCE_DESC|DATE_INSERTED';
           UTL_FILE.PUT_LINE(T_FILEHANDLER2, T_CONTENT );
        END IF;

        T_CONTENT := PO_REC.PO_ID                 ||'|' ||
                     PO_REC.RECIPIENT_NAME        ||'|' ||
                     PO_REC.VENDOR_NAME           ||'|' ||
                     PO_REC.DELIVER_TO            ||'|' ||
                     PO_REC.ATTEN_TO_NAME         ||'|' ||
                     PO_REC.REQUESTER_NAME        ||'|' ||
                     TO_CHAR(PO_REC.TOTAL_PO_AMT,'99999999.99')         ||'|' ||
                     PO_REC.RECEIVING_REQD        ||'|' ||
                     PO_REC.SOURCE_DESC         ||'|' ||
                     TO_CHAR(PO_REC.DATE_INSERTED,'YYYY-MM-DD HH24:MI:SS');  -- LASTMODIFIED

         UTL_FILE.PUT_LINE(T_FILEHANDLER2, T_CONTENT );
      END LOOP;

  UTL_FILE.FCLOSE(T_FILEHANDLER2);

-- FINALLY UPDATE FMS_LINK_ID.LBL_IBOXVARS
UPDATE FMS_LINK_ID.LBL_IBOXVARS
SET VARVALUE=TO_CHAR(SYSDATE, 'YYYY-MM-DD HH24:MI:SS')
WHERE VARNAME IN ('LASTDTTM_FLAGSSENT','LASTDTTM_POSENT');

COMMIT;


END;

/

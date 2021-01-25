CREATE OR REPLACE PACKAGE BODY LBL_MAXIMO_FEEDBACK IS

-- ************************************************************
-- PACAKGE BODY FOR LBL_MAXIMO_FEEDBACK
--
-- AUTHOR : PANKAJ BHIDE
--
-- MODIFICTION
-- HISTORY:     PANKAJ 8/3/10 ALLOW MULITPLE
--              TRANS AND SET VALUE TO 0 IF NOT RECORDED
--
--
-- ************************************************************

FUNCTION GET_LAST_STATUS(
          ORGID_I   IN MAXIMO.WORKORDER.ORGID%TYPE,
          SITEID_I  IN MAXIMO.WORKORDER.SITEID%TYPE,
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
    AND   CHANGEDATE=(SELECT MAX(CHANGEDATE) FROM WOSTATUS
    WHERE ORGID=ORGID_I AND SITEID=SITEID_I AND WONUM=WONUM_I
    AND STATUS != STATUS_I);


    RETURN STATUS_O;

    EXCEPTION
        WHEN OTHERS THEN
        STATUS_O := NULL;

    RETURN STATUS_O;
END;

 PROCEDURE INSERT_UPD_LBL_WOFEEDBACK(
 ORGID_I    IN MAXIMO.WORKORDER.ORGID%TYPE,
 SITEID_I   IN MAXIMO.WORKORDER.SITEID%TYPE,
 WONUM_I    IN MAXIMO.WORKORDER.WONUM%TYPE,
 ID_I       IN BATCH_MAXIMO.LBL_WOFEEDBACK.ID%TYPE,
 CUSTOMERID_I IN BATCH_MAXIMO.LBL_WOFEEDBACK.CUSTOMERID%TYPE,
 VALUE_I    IN BATCH_MAXIMO.LBL_WOFEEDBACK.VALUE%TYPE,
 CHANGEBY_I IN BATCH_MAXIMO.LBL_WOFEEDBACK.CHANGEBY%TYPE,
 WOFEEDBACKID_I IN BATCH_MAXIMO.LBL_WOFEEDBACK.WOFEEDBACKID%TYPE )

 IS
  COUNT_T NUMBER(10) :=0;
  VALUE_T BATCH_MAXIMO.LBL_WOFEEDBACK.VALUE%TYPE;
 BEGIN

   /*
    SELECT COUNT(*) INTO COUNT_T FROM BATCH_MAXIMO.LBL_WOFEEDBACK
    WHERE  ORGID=ORGID_I
    AND   SITEID=SITEID_I
    AND   WONUM=WONUM_I
    AND   ID=ID_I
    AND   CUSTOMERID=CUSTOMERID_I;

    IF (COUNT_T !=0) THEN  -- RECORD EXISTS

      UPDATE BATCH_MAXIMO.LBL_WOFEEDBACK
      SET VALUE=VALUE_I, VERSION=VERSION+1, CHANGEBY=CHANGEBY_I, CHANGEDATE=SYSDATE
      WHERE  ORGID=ORGID_I
      AND   SITEID=SITEID_I
      AND   WONUM=WONUM_I
      AND   ID=ID_I
      AND   CUSTOMERID=CUSTOMERID_I;

    ELSE */

      -- CHANGED BY PANKAJ ON 8/3/10

      IF (UPPER(VALUE_I)='SELECT') THEN
         VALUE_T :='0';
      ELSE
         VALUE_T := VALUE_I;
      END IF;

      INSERT INTO BATCH_MAXIMO.LBL_WOFEEDBACK
        (ORGID, SITEID, WONUM, CUSTOMERID, ID, VALUE, VERSION, CHANGEBY, CHANGEDATE,
         wofeedbackid )
         VALUES
         (ORGID_I,SITEID_I,WONUM_I, CUSTOMERID_I, ID_I, VALUE_T, 0, CHANGEBY_I, SYSDATE,
          WOFEEDBACKID_I );

    --END IF; -- IF (MODE_I = 'U')

  END ;


 PROCEDURE INSERT_UPD_WOFEEDBACKCOMMENTS(
 ORGID_I    IN MAXIMO.WORKORDER.ORGID%TYPE,
 SITEID_I   IN MAXIMO.WORKORDER.SITEID%TYPE,
 WONUM_I IN MAXIMO.WORKORDER.WONUM%TYPE,
 CUSTOMERID_I IN BATCH_MAXIMO.LBL_WOFEEDBACKCOMMENTS.CUSTOMERID%TYPE,
 RESPTOCOMMENTS_I    IN BATCH_MAXIMO.LBL_WOFEEDBACKCOMMENTS.RESPTOCOMMENTS%TYPE,
 COMMENTS_I IN BATCH_MAXIMO.LBL_WOFEEDBACKCOMMENTS.COMMENTS%TYPE,
 CHANGEBY_I IN BATCH_MAXIMO.LBL_WOFEEDBACKCOMMENTS.CHANGEBY%TYPE,
 CONTACT_NAME_I      IN BATCH_MAXIMO.LBL_WOFEEDBACKCOMMENTS.CONTACT_NAME%TYPE,
 CONTACT_DETAILS_I   IN BATCH_MAXIMO.LBL_WOFEEDBACKCOMMENTS.CONTACT_DETAILS%TYPE,
 WOFEEDBACKID_I IN BATCH_MAXIMO.LBL_WOFEEDBACKCOMMENTS.WOFEEDBACKID%TYPE )

 IS

  COUNT_T NUMBER(8) :=0;

 BEGIN

  IF (COMMENTS_I IS NOT NULL) OR (RESPTOCOMMENTS_I IS NOT NULL) THEN

  COUNT_T :=0;
 /*
  SELECT COUNT(*) INTO COUNT_T FROM BATCH_MAXIMO.LBL_WOFEEDBACKCOMMENTS
  WHERE ORGID=ORGID_I
  AND   SITEID=SITEID_I
  AND   WONUM=WONUM_I
  AND   CUSTOMERID=CUSTOMERID_I;


  IF (COUNT_T > 0)
   THEN
     UPDATE BATCH_MAXIMO.LBL_WOFEEDBACKCOMMENTS
     SET COMMENTS=COMMENTS_I, VERSION=VERSION+1,
     RESPTOCOMMENTS=RESPTOCOMMENTS_I,
     CONTACT_NAME=CONTACT_NAME_I, CONTACT_DETAILS=CONTACT_DETAILS_I,
     CHANGEBY=CHANGEBY_I, CHANGEDATE=SYSDATE
     WHERE ORGID=ORGID_I
     AND   SITEID=SITEID_I
     AND   WONUM=WONUM_I
     AND   CUSTOMERID=CUSTOMERID_I;

    ELSE */

         INSERT INTO BATCH_MAXIMO.LBL_WOFEEDBACKCOMMENTS
         (ORGID, SITEID, WONUM, CUSTOMERID, COMMENTS, VERSION,
          RESPTOCOMMENTS, CONTACT_NAME, CONTACT_DETAILS,
       	  CHANGEBY, CHANGEDATE, wofeedbackid)
         VALUES
         (ORGID_I,SITEID_I,WONUM_I, CUSTOMERID_I, COMMENTS_I, 0,
         RESPTOCOMMENTS_I,
         CONTACT_NAME_I, CONTACT_DETAILS_I,
	     CHANGEBY_I, SYSDATE,
         WOFEEDBACKID_I);
    --END IF; -- IF (COUNT >0)

  END IF;  -- IF (COMMENTS_I IS NOT NULL) OR (RESPTOCOMMENTS_I IS NOT NULL) THEN

END;


END;

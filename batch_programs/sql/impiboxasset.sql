/**********************************************************************************
PROGRAM NAME           : IMPIBOXASSET.SQL

 DATE WRITTEN           : 19-SEP-2016

 AUTHOR                 : PANKAJ BHIDE

 USAGE                  : 
                                                    
                          
 PURPOSE                : INTERFACE PROGRAM TO ASSET INFORMATION FROM A FLAT FILE
                          INTO ASSET TABLE OWNED BY FMS_LINK_ID. 
                          
********************************************************************************/                      
WHENEVER SQLERROR EXIT 1 ROLLBACK;

DECLARE        

   
     T_FILEHANDLER1 UTL_FILE.FILE_TYPE;
     T_FILENAME1    VARCHAR2(50);
     t_line         varchar2(4000);

          
     T_CONTENT     VARCHAR2(32000);
     ROW_CNT_T NUMBER(10) :=0;
     T_EXISTS    NUMBER(5);
     
     
     T_ITEMID     VARCHAR2(4000);
     T_STATUS     VARCHAR2(4000);
     T_CARRIER    VARCHAR2(4000);
     T_PONUM      VARCHAR2(4000);
     T_ATTTO      VARCHAR2(4000);
     T_VENDOR     VARCHAR2(4000);
     T_DOE        VARCHAR2(4000);
     T_PCARD      VARCHAR2(4000);
     T_DELVTO     VARCHAR2(4000);
     T_REQUESTOR  VARCHAR2(4000);
     T_POAMT      VARCHAR2(4000); 
     T_RECVSTATUS VARCHAR2(4000);
     T_DATE       VARCHAR2(4000);
     T_ID         NUMBER(10);


BEGIN
  
   T_FILENAME1     :='Asset_Export.txt';
   
   -- GET THE INPUT FILE NAME FROM LBL_MAXVARS
   --SELECT TRIM(VARVALUE) INTO T_FILENAME1
   --FROM LBL_MAXVARS WHERE VARNAME='IBOASSETFILE';
   
   
   
   T_FILEHANDLER1  :=UTL_FILE.FOPEN('MAXIMO', T_FILENAME1, 'R');
   
   
   LOOP
      BEGIN
        UTL_FILE.GET_LINE (T_FILEHANDLER1, T_CONTENT);
    
        ROW_CNT_T := ROW_CNT_T + 1;
--        T_CONTENT := T_CONTENT || '|';      
        
        T_DATE :=NULL;
    IF (ROW_CNT_T > 1) THEN -- SKIP HEADER ROW 
                     
       SELECT       
       
        TRIM(SUBSTR(T_CONTENT, 1,   50)), --- T_ITEMID
        TRIM(SUBSTR(T_CONTENT, 51,  50)), -- T_STATUS
        TRIM(SUBSTR(T_CONTENT, 101, 50)), -- T_CARRIER
        TRIM(SUBSTR(T_CONTENT, 151,50)),  -- T_PONUM
        TRIM(SUBSTR(T_CONTENT, 201,50)),  -- T_ATTTO
        TRIM(SUBSTR(T_CONTENT, 251,50)),  -- T_VENDOR
        TRIM(SUBSTR(T_CONTENT, 301,50)),  -- T_DOE
        TRIM(SUBSTR(T_CONTENT, 351,50)),  -- T_PCARD
        TRIM(SUBSTR(T_CONTENT, 401,50)),  -- T_DELVTO
        TRIM(SUBSTR(T_CONTENT, 451,50)),  -- T_REQUESTOR
        TRIM(SUBSTR(T_CONTENT, 501,50)),  -- T_POAMT
        TRIM(SUBSTR(T_CONTENT, 551, 50)), -- T_RECVSTATUS
        TRIM(SUBSTR(T_CONTENT, 601, 20))  -- T_DATE
        INTO 
        T_ITEMID, T_STATUS,    T_CARRIER, T_PONUM,
        T_ATTTO,  T_VENDOR,    T_DOE,     T_PCARD,
        T_DELVTO, T_REQUESTOR, T_POAMT,   T_RECVSTATUS, 
        T_DATE           
      FROM DUAL;
    
    
    
      IF (T_DATE IS NOT NULL) THEN 
      
       t_line := 'row: '|| to_char(row_cnt_t) || ' itemid: ' || t_itemid || ' t_status: '||  t_status || ' carrier: ' || t_carrier || ' ponum:' || t_ponum || ' attento: ' || t_attto || ' poamt:' || t_poamt || ' date:  '  || t_date;
       dbms_output.put_line(t_line);
       
              
        IF (T_ITEMID IS NOT NULL ) THEN
         BEGIN
             SELECT 1 INTO T_EXISTS FROM FMS_LINK_ID.ASSET 
             WHERE ASSETID=T_ITEMID;
             
             UPDATE FMS_LINK_ID.ASSET
             SET ITEMVAR1=T_CARRIER, ITEMVAR2=T_PONUM, ITEMVAR3=T_ATTTO,
                 ITEMVAR4=T_VENDOR,  ITEMVAR5=T_DOE,   ITEMVAR6=T_PCARD,
                 ITEMVAR7=T_DELVTO,  ITEMVAR8=T_REQUESTOR, ITEMVAR9=T_POAMT,
                 ITEMVAR10=T_RECVSTATUS,
                 DATE_=TO_DATE(T_DATE,'YYYY-MM-DD HH24:MI:SS'),
                 CHANGEDATE=SYSDATE                 
             WHERE ASSETID=T_ITEMID;
   
           EXCEPTION WHEN NO_DATA_FOUND  THEN
             INSERT INTO FMS_LINK_ID.ASSET
             (ASSETID,ITEMVAR1,ITEMVAR2,ITEMVAR3,ITEMVAR4,ITEMVAR5,
              ITEMVAR6, ITEMVAR7, ITEMVAR8, ITEMVAR9,ITEMVAR10,
              DATE_, CHANGEDATE, PROFILEID) VALUES
              (T_ITEMID, T_CARRIER, T_PONUM, T_ATTTO, T_VENDOR,T_DOE,
               T_PCARD, T_DELVTO,T_REQUESTOR,T_POAMT, T_RECVSTATUS,
               TO_DATE(T_DATE,'YYYY-MM-DD HH24:MI:SS'), SYSDATE,1);            
          END;  
       END IF;             
   END IF;
  
  END IF;
   
   EXCEPTION
      WHEN NO_DATA_FOUND THEN
        EXIT;
    END;
    
  END LOOP;  
   
  UTL_FILE.FCLOSE(T_FILEHANDLER1);
  
-- FINALLY UPDATE FMS_LINK_ID.LBL_IBOXVARS
UPDATE FMS_LINK_ID.LBL_IBOXVARS 
SET VARVALUE=TO_CHAR(SYSDATE, 'YYYY-MM-DD HH24:MI:SS')
WHERE VARNAME IN ('LASTDTTM_ASSETRECD');
  
COMMIT;
  
  
END; 

/

                       

/*****************************************************************************
 PROGRAM NAME           : GEN_SISFEEDER.SQL 

 DATE WRITTEN           : 24-FEB-2014

 AUTHOR                 : PANKAJ BHIDE

 USAGE                  : PROGRAM NAME WITH ARGUEMENTS
                          1-ORGID 2-SITEID                          
                           
                          
 PURPOSE                : INTERFACE PROGRAM TO INSERT STORES TRANSACTIONS 
                          INTO BATCH_MAXIMO.LBL_PROJECT_FEEDERS TABLE (ONE A 
                          MONTH)
                          
 REVISION HISTORY:      : APRIL 17, 2015 CHANGES FOR ASSET TYPE
                          JIRA-EF-967
                                                   
*****************************************************************************/
WHENEVER SQLERROR EXIT 1 ROLLBACK;

DECLARE
 
 ORGID_T            WORKORDER.ORGID%TYPE;
 SITEID_T           WORKORDER.SITEID%TYPE;
 RETURN_T           VARCHAR2(2000);
 

/*********************************************************************
 MAIN PROGRAM STARTS FROM HERE
*********************************************************************/
BEGIN

    DBMS_OUTPUT.ENABLE(1000000);  
    
    -- GET THE VALUE OF ORG ID FROM THE ARUGEMENT 
    ORGID_T   :=UPPER('&1');
      
    IF (ORGID_T IS NULL OR LENGTH(ORGID_T)=0) THEN
       ORGID_T :='LBNL';
    END IF;
     
     -- GET THE VALUE OF SITE ID FROM THE ARUGEMENT 
    SITEID_T   :=UPPER('&2');
      
    IF (SITEID_T IS NULL OR LENGTH(SITEID_T)=0) THEN
       SITEID_T :='FAC';
    END IF; 
     
    RETURN_T :=LBL_MXPSIFACE_PKG.generate_stores_feeder(
    ORGID_T, SITEID_T);
    IF (RETURN_T='SUCCESS') THEN
       COMMIT;    
    ELSE
      ROLLBACK;
    END IF;
      
    
   

END;

/



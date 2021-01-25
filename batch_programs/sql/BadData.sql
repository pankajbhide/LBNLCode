/*******************************************************************************
 PROGRAM NAME           : BadData.SQL

 DATE WRITTEN           : JUNE-2017

 AUTHOR                 : ANNETTE LEUNG
                          
 PURPOSE                : To ensure the imported data are correctly loaded in MAXIMO.
*****************************************************************************/

whenever sqlerror exit 1 rollback;

declare


-- Input file should not be null
cursor InputFile_Cur is 
    select assetnum, asset_status, existing_assetnum
        from lbl_assetupd_details 
        where  inputfilename is null;

-- Status should not be null
cursor AssetStatus_Cur is 
    select assetnum, asset_status, existing_assetnum 
        from lbl_assetupd_details
        where asset_status is null;
        
-- Existing Asset and New Asset are not null but has Decommisioned status        
cursor InvalidStatus_Cur is 
    select existing_assetnum, assetnum, asset_status
        from lbl_assetupd_details 
        where existing_assetnum is not null 
        and assetnum is not null 
        and upper(asset_status) = 'DECOMMISSIONED';        

-- Existing Asset: Decommissioned
cursor Decommission_Cur is
    select a.assetnum, a.status, b.existing_assetnum, b.asset_status 
        from asset a
        right outer join  lbl_assetupd_details b
            on a.assetnum = b.existing_assetnum
        where b.existing_assetnum is not null 
        and b.assetnum is null
        and upper(nvl(a.status, 'null')) != upper(b.asset_status) 
        and upper(b.asset_status) = 'DECOMMISSIONED';

-- Existing Asset: Operating     
cursor Operating_Cur is
    select a.assetnum, a.status, b.existing_assetnum, b.asset_status 
        from asset a
        right outer join  lbl_assetupd_details b
            on a.assetnum = b.existing_assetnum
        where b.existing_assetnum is not null 
        and b.assetnum is null
        and upper(nvl(a.status, 'null')) != upper(b.asset_status) 
        and upper(b.asset_status) = 'OPERATING';
   
-- Existing Asset: Classifciation        
cursor Classification_Cur is
    select a.assetnum, a.lbl_asset_classification, b.existing_assetnum, b.classification
        from asset a
        right outer join  lbl_assetupd_details b
            on a.assetnum = b.existing_assetnum
        where b.existing_assetnum is not null
        and b.assetnum is null
        and upper(nvl(a.lbl_asset_classification, 'null')) != upper(nvl(b.classification, 'null'));
   
-- Existing Asset: Model
cursor Model_Cur is
    select a.assetnum, a.lbl_model, b.existing_assetnum, b.model
        from asset a
        right outer join  lbl_assetupd_details b
            on a.assetnum = b.existing_assetnum
        where b.existing_assetnum is not null
        and b.assetnum is null
        and upper(nvl(a.lbl_model, 'null')) != upper(nvl(b.model, 'null')); 
        
--Existing Asset: Strategy
cursor Strategy_Cur is 
    select a.assetnum, a.lbl_strategy, b.existing_assetnum, substr(b.strategy, 1, (instr(b.strategy, '-') - 2)) strategy
        from asset a
        right outer join  lbl_assetupd_details b
            on a.assetnum = b.existing_assetnum
        where b.existing_assetnum is not null
        and b.assetnum is null
        and upper(nvl(a.lbl_strategy, 'null')) != upper(nvl((substr(b.strategy, 1, (instr(b.strategy, '-') - 2))), 'null'));       
        
-- Existing Asset: Location
cursor Location_Cur is
    select a.assetnum, a.location, b.existing_assetnum, b.location newlocation
        from asset a
        right outer join  lbl_assetupd_details b
            on a.assetnum = b.existing_assetnum
        where b.existing_assetnum is not null
        and b.assetnum is null
        and upper(a.location) != upper(b.location);    
        
-- Existing Asset: Manufacturer
cursor Manufacturer_Cur is 
    select a.assetnum, a.manufacturer, b.existing_assetnum, b.manufacturer newmanufacturer
        from asset a
        right outer join  lbl_assetupd_details b
            on a.assetnum = b.existing_assetnum
        where b.existing_assetnum is not null
        and b.assetnum is null
        and upper(nvl(a.manufacturer, 'null')) != upper(nvl(b.manufacturer, 'null'));            
   
-- Existing Asset: Serial
cursor Serial_Cur is
    select a.assetnum, a.serialnum, b.existing_assetnum,  b.serialnum newserial
        from asset a
        right outer join  lbl_assetupd_details b
            on a.assetnum = b.existing_assetnum
        where b.existing_assetnum is not null
        and upper(nvl(a.serialnum, 'null')) != upper(nvl(b.serialnum, 'null')); 
        
-- long description    
cursor LongDesc_Cur is 
    select a.assetnum,
        (select  TO_CHAR(SUBSTR(ldtext,0,3999)) 
            from longdescription 
            where ldownertable = 'ASSET' 
            and ldownercol = 'LBL_STRATEGY' 
            and ldkey = (select assetuid from asset where asset.assetnum = a.assetnum)) longdesc, 
        b.existing_assetnum, b.strategy_comments
        from asset a
        right outer join  lbl_assetupd_details b
            on a.assetnum = b.existing_assetnum
        where b.existing_assetnum is not null 
        and b.assetnum is null
        and b.strategy_comments is not null
        and nvl((select  TO_CHAR(SUBSTR(ldtext,0,3999)) 
                    from longdescription 
                    where ldownertable = 'ASSET' 
                    and ldownercol = 'LBL_STRATEGY' 
                    and ldkey = (select assetuid from asset where asset.assetnum = a.assetnum)), 'null') != b.strategy_comments;

-- If parent asset is decommissioned, all the parent and child PM are inactive.                    
cursor PM_Cur is 
    select c.pmnum, c.assetnum, c.status
        from pm c 
        where upper(c.status) != 'INACTIVE' 
        and c.assetnum in 
            (select a.assetnum child
                from   lbl_archive.assetancestor_asup a, lbl_assetupd_details b
                where  a.ancestor = b.existing_assetnum
                and upper(b.asset_status) = 'DECOMMISSIONED');     

-- Safety Plan related asset                
cursor Sprelated_Cur is
    select a.assetnum, a.relatedasset
        from sprelatedasset a
        where a.assetnum in 
        (select b.existing_assetnum 
            from lbl_assetupd_details b 
            where upper(b.asset_status) = 'DECOMMISSIONED');     
            
-- Safety Lexicon             
cursor Safetylexicon_Cur is
    select assetnum, hazardid, safetylexiconid 
        from safetylexicon 
            where assetnum in                                 
            (select b.existing_assetnum 
            from lbl_assetupd_details b 
            where upper(b.asset_status) = 'DECOMMISSIONED');  

-- Safety Plan work asset            
cursor SpWorkAsset_Cur is 
    select workasset, safetyplanid 
        from spworkasset 
        where workasset in                                 
            (select b.existing_assetnum 
            from lbl_assetupd_details b 
            where upper(b.asset_status) = 'DECOMMISSIONED');   

-- Safety Plan Lexicon Link
cursor Splexiconlink_Cur is           
    select spworkassetid, safetylexiconid, splexiconlinkid 
        from splexiconlink 
        where spworkassetid in 
        (select spworkassetid 
            from spworkasset 
            where workasset in (select b.existing_assetnum 
            from lbl_assetupd_details b 
            where upper(b.asset_status) = 'DECOMMISSIONED'));      
            
-- Update pluscassetstatus table       
cursor Pluscassetstatus_Cur is      
    select a.assetnum, a.status, a.changeby, a.changedate, b.existing_assetnum, b.asset_status
        from pluscassetstatus a
        right outer join lbl_assetupd_details b
            on a.assetnum = b.existing_assetnum
        where b.existing_assetnum is not null 
        and b.assetnum is null
        and upper(nvl(a.status, 'null')) != upper(b.asset_status) 
        and upper(b.asset_status) = 'DECOMMISSIONED'
        and (a.changedate = 
                (select max(c.changedate) 
                        from pluscassetstatus c 
                        where c.assetnum = a.assetnum)
        or nvl(a.changedate, '') is null);    

-- New Asset
cursor NewAsset_Cur is 
    select  a.assetnum, b.assetnum newasset, a.status, b.asset_status, a.lbl_asset_classification, b.classification,
            a.location, b.location newlocation, a.manufacturer, b.manufacturer newmanufacturer,
            a.lbl_model, b.model, a.serialnum, b.serialnum newserial, a.lbl_strategy, b.strategy, 
            (select  TO_CHAR(SUBSTR(ldtext,0,3999)) 
                from longdescription 
                where ldownertable = 'ASSET' 
                and ldownercol = 'LBL_STRATEGY' 
                and ldkey = 
                    (select assetuid from asset where asset.assetnum = a.assetnum)) longdesc, b.strategy_comments
        from asset a
        right outer join  lbl_assetupd_details b
            on a.assetnum = b.assetnum
        where b.existing_assetnum is null 
        and b.assetnum is not null
        and upper(b.asset_status) = 'OPERATING'
        and (
            upper(nvl(a.status, 'null')) != upper(b.asset_status)
        or  upper(nvl(a.lbl_asset_classification, 'null')) != upper(nvl(b.classification, 'null'))
        or  upper(nvl(a.location, 'null')) != upper(b.location)
        or  upper(nvl(a.manufacturer, 'null')) != upper(nvl(b.manufacturer, 'null'))
        or  upper(nvl(a.lbl_model, 'null')) != upper(nvl(b.model, 'null'))
        or  upper(nvl(a.serialnum, 'null')) != upper(nvl(b.serialnum, 'null'))
        or  upper(nvl(a.lbl_strategy, 'null')) != upper(nvl((substr(b.strategy, 1, (instr(b.strategy, '-') - 2))), 'null'))
        or  nvl((select  TO_CHAR(SUBSTR(ldtext,0,3999)) 
                    from longdescription 
                    where ldownertable = 'ASSET' 
                    and ldownercol = 'LBL_STRATEGY' 
                    and ldkey = (select assetuid from asset where asset.assetnum = a.assetnum)), 'null') != b.strategy_comments
            );
            
-- New Asset: Updated in pluscassetstatus table
cursor NewPluscassetstatus_Cur is    
    select a.assetnum, a.status, b.assetnum newasset, b.asset_status
        from pluscassetstatus a
        right outer join lbl_assetupd_details b
            on a.assetnum = b.assetnum
        where b.assetnum is not null
        and upper(nvl(a.status, 'null')) != upper(b.asset_status) 
        and upper(b.asset_status) = 'OPERATING'
        and a.changedate = (select max(c.changedate) from pluscassetstatus c where c.assetnum = a.assetnum);        
            
-- Duplicate Asset and Long Description            
cursor DuplicateAsset_Cur is             
    select  a.assetnum, b.assetnum newasset, a.status, b.asset_status, a.lbl_asset_classification, b.classification,
            a.location, b.location newlocation, a.manufacturer, b.manufacturer newmanufacturer,
            a.lbl_model, b.model, a.serialnum, b.serialnum newserial, a.lbl_strategy, b.strategy, 
            (select  TO_CHAR(SUBSTR(ldtext,0,3999)) 
                from longdescription 
                where ldownertable = 'ASSET' 
                and ldownercol = 'LBL_STRATEGY' 
                and ldkey = 
                    (select assetuid from asset where asset.assetnum = a.assetnum)) longdesc, b.strategy_comments
        from asset a
        right outer join  lbl_assetupd_details b
            on a.assetnum = b.assetnum
        where b.existing_assetnum is not null 
        and b.assetnum is not null
        and upper(b.asset_status) = 'OPERATING'
        and (
            upper(nvl(a.status, 'null')) != upper(b.asset_status)
        or  upper(nvl(a.lbl_asset_classification, 'null')) != upper(nvl(b.classification, 'null'))
        or  upper(nvl(a.location, 'null')) != upper(b.location)
        or  upper(nvl(a.manufacturer, 'null')) != upper(nvl(b.manufacturer, 'null'))
        or  upper(nvl(a.lbl_model, 'null')) != upper(nvl(b.model, 'null'))
        or  upper(nvl(a.serialnum, 'null')) != upper(nvl(b.serialnum, 'null'))
        or  upper(nvl(a.lbl_strategy, 'null')) != upper(nvl((substr(b.strategy, 1, (instr(b.strategy, '-') - 2))), 'null'))            
        or  nvl((select  TO_CHAR(SUBSTR(ldtext,0,3999)) 
                    from longdescription 
                    where ldownertable = 'ASSET' 
                    and ldownercol = 'LBL_STRATEGY' 
                    and ldkey = (select assetuid from asset where asset.assetnum = a.assetnum)), 'null') != b.strategy_comments
            );

-- Duplicated Asset: Updated in pluscassetstatus table
cursor DupPluscassetstatus_Cur is    
    select a.assetnum, a.status, a.changeby, a.changedate, b.assetnum newasset, b.asset_status
        from pluscassetstatus a
        right outer join lbl_assetupd_details b
            on a.assetnum = b.assetnum
        where b.existing_assetnum is not null 
        and b.assetnum is not null
        and upper(nvl(a.status, 'null')) != upper(b.asset_status) 
        and upper(b.asset_status) = 'OPERATING'
        and a.changedate = (select max(c.changedate) from pluscassetstatus c where c.assetnum = a.assetnum);  

-- Asset Ancestor         
cursor AssetAncestor_Cur is 
    select b.assetnum newasset
        from lbl_assetupd_details b
        where not exists (select a.assetnum from assetancestor a where a.hierarchylevels = 0)
        and upper(b.asset_status) = 'OPERATING'
        and b.assetnum is not null;
  
        
-- Doclinks                     
cursor Doclinks_Cur is
    select  a.existing_assetnum, a.assetnum, 
            b.document olddocument, b.doctype olddoctype, b.ownerid oldownerid, 
            c.document newdocument, c.doctype newdoctype, c.ownerid newownerid
        from lbl_assetupd_details a, doclinks b, doclinks c
        where a.existing_assetnum is not null 
        and a.assetnum is not null
        and a.existing_assetnum in 
            (select assetnum 
                from asset 
                where assetuid in 
                (select assetuid from doclinks where ownertable = 'ASSET'))   
        and upper(a.asset_status) = 'OPERATING'
        and b.ownertable = 'ASSET'
        and c.ownertable = 'ASSET'
        and (select assetuid from asset where assetnum = a.existing_assetnum) = b.ownerid
        and (select assetuid from asset where assetnum = a.assetnum) = c.ownerid
        and (b.document != c.document or b.doctype != c.doctype);     
 
 -- Asset Trans        
cursor Assettrans_Cur is 
    select a.assetnum, a.toloc, b.assetnum newasset, b.location
        from assettrans a
        right outer join lbl_assetupd_details b
            on a.assetnum = b.assetnum
        where b.assetnum is not null 
        and upper(b.asset_status) = 'OPERATING' 
        and Upper(nvl(a.toloc, 'null')) != Upper(b.location);               
   
     T_FILEHANDLER1 UTL_FILE.FILE_TYPE;
     T_FILENAME1    VARCHAR2(50);
     CRLF CONSTANT CHAR(1) := CHR(10); -- Line Feed 

begin
    T_FILENAME1        := 'Assetlog.txt';
    T_FILEHANDLER1     :=UTL_FILE.FOPEN('MAXIMO', T_FILENAME1, 'W');
    
-- InputFile should not be null
UTL_FILE.PUT_LINE(T_FILEHANDLER1, 'Input File is null' );      
    for InputFile_Rec IN InputFile_Cur
        loop
            UTL_FILE.PUT_LINE(T_FILEHANDLER1, 'MAXIMO Asset: ' || InputFile_Rec.assetnum);
            UTL_FILE.PUT_LINE(T_FILEHANDLER1, 'MAXIMO Status: '|| InputFile_Rec.asset_status);
            UTL_FILE.PUT_LINE(T_FILEHANDLER1, 'Existing Asset: '|| InputFile_Rec.existing_assetnum || CRLF);
        end loop;
    UTL_FILE.PUT_LINE(T_FILEHANDLER1, '-----------------------------------------------------' );    
    
-- Asset status should not be null
UTL_FILE.PUT_LINE(T_FILEHANDLER1, 'Asset Status is null' );      
    for AssetStatus_Rec IN AssetStatus_Cur
        loop
            UTL_FILE.PUT_LINE(T_FILEHANDLER1, 'MAXIMO Asset: ' || AssetStatus_Rec.assetnum);
            UTL_FILE.PUT_LINE(T_FILEHANDLER1, 'MAXIMO Status: '|| AssetStatus_Rec.asset_status);
            UTL_FILE.PUT_LINE(T_FILEHANDLER1, 'Existing Asset: '|| AssetStatus_Rec.existing_assetnum || CRLF);
        end loop;
    UTL_FILE.PUT_LINE(T_FILEHANDLER1, '-----------------------------------------------------' );        


-- Existing Asset and New Asset are not null but has Decommissioned status    
UTL_FILE.PUT_LINE(T_FILEHANDLER1, 'Existing and New Assets are not null but has Decommissioned status' );      
    for InvalidStatus_Rec IN InvalidStatus_Cur
        loop
            UTL_FILE.PUT_LINE(T_FILEHANDLER1, 'Existing Asset: ' || InvalidStatus_Rec.existing_assetnum);
            UTL_FILE.PUT_LINE(T_FILEHANDLER1, 'New Asset: '|| InvalidStatus_Rec.assetnum);
            UTL_FILE.PUT_LINE(T_FILEHANDLER1, 'Existing Status: '|| InvalidStatus_Rec.asset_status || CRLF);
        end loop;
    UTL_FILE.PUT_LINE(T_FILEHANDLER1, '-----------------------------------------------------' );     
        
-- Decommissioned Assets    
    UTL_FILE.PUT_LINE(T_FILEHANDLER1, 'Decommissioned Assets' );      
    for Decommission_Rec IN Decommission_Cur
        loop
            UTL_FILE.PUT_LINE(T_FILEHANDLER1, 'MAXIMO Asset: ' || Decommission_Rec.assetnum);
            UTL_FILE.PUT_LINE(T_FILEHANDLER1, 'MAXIMO Status: '|| Decommission_Rec.status);
            UTL_FILE.PUT_LINE(T_FILEHANDLER1, 'Existing Asset: '|| Decommission_Rec.existing_assetnum);
            UTL_FILE.PUT_LINE(T_FILEHANDLER1, 'New Status: '|| Decommission_Rec.asset_status || CRLF);
        end loop;
    UTL_FILE.PUT_LINE(T_FILEHANDLER1, '-----------------------------------------------------' );
    
-- Operating Assets       
    UTL_FILE.PUT_LINE(T_FILEHANDLER1, 'Operating Assets' );      
    for Operating_Rec IN Operating_Cur
        loop
            UTL_FILE.PUT_LINE(T_FILEHANDLER1, 'MAXIMO Asset: ' || Operating_Rec.assetnum);
            UTL_FILE.PUT_LINE(T_FILEHANDLER1, 'MAXIMO Status: '|| Operating_Rec.status);
            UTL_FILE.PUT_LINE(T_FILEHANDLER1, 'Existing Asset: '|| Operating_Rec.existing_assetnum);
            UTL_FILE.PUT_LINE(T_FILEHANDLER1, 'New Status: '|| Operating_Rec.asset_status || CRLF);
        end loop;
    UTL_FILE.PUT_LINE(T_FILEHANDLER1, '-----------------------------------------------------' );
                
    
-- Classification
    UTL_FILE.PUT_LINE(T_FILEHANDLER1, 'Classification' );      
    for Classification_Rec IN Classification_Cur
        loop
            UTL_FILE.PUT_LINE(T_FILEHANDLER1, 'MAXIMO Asset: ' || Classification_Rec.assetnum);
            UTL_FILE.PUT_LINE(T_FILEHANDLER1, 'MAXIMO Classification: '|| Classification_Rec.lbl_asset_classification);
            UTL_FILE.PUT_LINE(T_FILEHANDLER1, 'Existing Asset: '|| Classification_Rec.existing_assetnum);
            UTL_FILE.PUT_LINE(T_FILEHANDLER1, 'New Classification: '|| Classification_Rec.classification || CRLF);
        end loop;
    UTL_FILE.PUT_LINE(T_FILEHANDLER1, '-----------------------------------------------------' );   
    
-- Model
    UTL_FILE.PUT_LINE(T_FILEHANDLER1, 'Model' );      
    for Model_Rec IN Model_Cur
        loop
            UTL_FILE.PUT_LINE(T_FILEHANDLER1, 'MAXIMO Asset: ' || Model_Rec.assetnum);
            UTL_FILE.PUT_LINE(T_FILEHANDLER1, 'MAXIMO Model# : '|| Model_Rec.lbl_model);
            UTL_FILE.PUT_LINE(T_FILEHANDLER1, 'Existing Asset: '|| Model_Rec.existing_assetnum);
            UTL_FILE.PUT_LINE(T_FILEHANDLER1, 'New Model# : '|| Model_Rec.model || CRLF);
        end loop;
    UTL_FILE.PUT_LINE(T_FILEHANDLER1, '-----------------------------------------------------' );    
    
-- Strategy    
    UTL_FILE.PUT_LINE(T_FILEHANDLER1, 'Strategy' );      
    for Strategy_Rec IN Strategy_Cur
        loop
            UTL_FILE.PUT_LINE(T_FILEHANDLER1, 'MAXIMO Asset: ' || Strategy_Rec.assetnum);
            UTL_FILE.PUT_LINE(T_FILEHANDLER1, 'MAXIMO Strategy : '|| Strategy_Rec.lbl_strategy);
            UTL_FILE.PUT_LINE(T_FILEHANDLER1, 'Existing Asset: '|| Strategy_Rec.existing_assetnum);
            UTL_FILE.PUT_LINE(T_FILEHANDLER1, 'New Strategy# : '|| Strategy_Rec.strategy || CRLF);
        end loop;
    UTL_FILE.PUT_LINE(T_FILEHANDLER1, '-----------------------------------------------------' );                 

-- Location
    UTL_FILE.PUT_LINE(T_FILEHANDLER1, 'Location' );      
    for Location_Rec IN Location_Cur
        loop
            UTL_FILE.PUT_LINE(T_FILEHANDLER1, 'MAXIMO Asset: ' || Location_Rec.assetnum);
            UTL_FILE.PUT_LINE(T_FILEHANDLER1, 'MAXIMO Location : '|| Location_Rec.location);
            UTL_FILE.PUT_LINE(T_FILEHANDLER1, 'Existing Asset: '|| Location_Rec.existing_assetnum);
            UTL_FILE.PUT_LINE(T_FILEHANDLER1, 'New Location : '|| Location_Rec.newlocation || CRLF);
        end loop;
    UTL_FILE.PUT_LINE(T_FILEHANDLER1, '-----------------------------------------------------' );        
    
-- Manufacturer
    UTL_FILE.PUT_LINE(T_FILEHANDLER1, 'Manufacturer' );      
    for Manufacturer_Rec IN Manufacturer_Cur
        loop
            UTL_FILE.PUT_LINE(T_FILEHANDLER1, 'MAXIMO Asset: ' || Manufacturer_Rec.assetnum);
            UTL_FILE.PUT_LINE(T_FILEHANDLER1, 'MAXIMO Manufacturer : '|| Manufacturer_Rec.manufacturer);
            UTL_FILE.PUT_LINE(T_FILEHANDLER1, 'Existing Asset: '|| Manufacturer_Rec.existing_assetnum);
            UTL_FILE.PUT_LINE(T_FILEHANDLER1, 'New Manufacturer : '|| Manufacturer_Rec.newmanufacturer || CRLF);
        end loop;
    UTL_FILE.PUT_LINE(T_FILEHANDLER1, '-----------------------------------------------------' );      
    
-- Serial
    UTL_FILE.PUT_LINE(T_FILEHANDLER1, 'Serial' );      
    for Serial_Rec IN Serial_Cur
        loop
            UTL_FILE.PUT_LINE(T_FILEHANDLER1, 'MAXIMO Asset: ' || Serial_Rec.assetnum);
            UTL_FILE.PUT_LINE(T_FILEHANDLER1, 'MAXIMO Serial : '|| Serial_Rec.serialnum);
            UTL_FILE.PUT_LINE(T_FILEHANDLER1, 'Existing Asset: '|| Serial_Rec.existing_assetnum);
            UTL_FILE.PUT_LINE(T_FILEHANDLER1, 'New Serial : '|| Serial_Rec.newserial || CRLF);
        end loop;
    UTL_FILE.PUT_LINE(T_FILEHANDLER1, '-----------------------------------------------------' );   
    
-- Long Description
    UTL_FILE.PUT_LINE(T_FILEHANDLER1, 'Long Description' );      
    for LongDesc_Rec IN LongDesc_Cur
        loop
            UTL_FILE.PUT_LINE(T_FILEHANDLER1, 'MAXIMO Asset: ' || LongDesc_Rec.assetnum);
            UTL_FILE.PUT_LINE(T_FILEHANDLER1, 'MAXIMO LongDesc : '|| LongDesc_Rec.longdesc);
            UTL_FILE.PUT_LINE(T_FILEHANDLER1, 'Existing Asset: '|| LongDesc_Rec.existing_assetnum);
            UTL_FILE.PUT_LINE(T_FILEHANDLER1, 'Strategy Comments : '|| LongDesc_Rec.strategy_comments || CRLF);
        end loop;
    UTL_FILE.PUT_LINE(T_FILEHANDLER1, '-----------------------------------------------------' );   
    
-- Parent and Child PM
    UTL_FILE.PUT_LINE(T_FILEHANDLER1, 'Parent and Child PM are not INACTIVE' );      
    for PM_Rec IN PM_Cur
        loop
            UTL_FILE.PUT_LINE(T_FILEHANDLER1, 'MAXIMO PM: ' || PM_Rec.pmnum);
            UTL_FILE.PUT_LINE(T_FILEHANDLER1, 'MAXIMO Asset: '|| PM_Rec.assetnum);
            UTL_FILE.PUT_LINE(T_FILEHANDLER1, 'MAXIMO PM Status : '|| PM_Rec.status || CRLF);
        end loop;
    UTL_FILE.PUT_LINE(T_FILEHANDLER1, '-----------------------------------------------------' );   
    
-- SP Related Assets
    UTL_FILE.PUT_LINE(T_FILEHANDLER1, 'SP Related Asset record is not deleted' );      
    for Sprelated_Rec IN Sprelated_Cur
        loop
            UTL_FILE.PUT_LINE(T_FILEHANDLER1, 'MAXIMO Asset: ' || Sprelated_Rec.assetnum);
            UTL_FILE.PUT_LINE(T_FILEHANDLER1, 'MAXIMO SP Related Asset: '|| Sprelated_Rec.relatedasset || CRLF);
        end loop;
    UTL_FILE.PUT_LINE(T_FILEHANDLER1, '-----------------------------------------------------' );    
    
-- Safety Lexicon
    UTL_FILE.PUT_LINE(T_FILEHANDLER1, 'Safetylexicon record is not deleted' );      
    for Safetylexicon_Rec IN Safetylexicon_Cur
        loop
            UTL_FILE.PUT_LINE(T_FILEHANDLER1, 'MAXIMO Asset: ' || Safetylexicon_Rec.assetnum);
            UTL_FILE.PUT_LINE(T_FILEHANDLER1, 'MAXIMO Hazard: ' || Safetylexicon_Rec.hazardid);
            UTL_FILE.PUT_LINE(T_FILEHANDLER1, 'MAXIMO Safetylexicon Asset: '|| Safetylexicon_Rec.safetylexiconid || CRLF);
        end loop;
    UTL_FILE.PUT_LINE(T_FILEHANDLER1, '-----------------------------------------------------' );             

-- Safety Plan work asset
    UTL_FILE.PUT_LINE(T_FILEHANDLER1, 'Safety Plan work asset record is not deleted' );      
    for SpWorkAsset_Rec IN SpWorkAsset_Cur
        loop
            UTL_FILE.PUT_LINE(T_FILEHANDLER1, 'MAXIMO Asset: ' || SpWorkAsset_Rec.workasset);
            UTL_FILE.PUT_LINE(T_FILEHANDLER1, 'MAXIMO Safety Plan id: '|| SpWorkAsset_Rec.safetyplanid || CRLF);
        end loop;
    UTL_FILE.PUT_LINE(T_FILEHANDLER1, '-----------------------------------------------------' );  
    
-- Safety Lexicon Link
    UTL_FILE.PUT_LINE(T_FILEHANDLER1, 'Safety Lexicon Link is not deleted' );      
    for Splexiconlink_Rec IN Splexiconlink_Cur
        loop
            UTL_FILE.PUT_LINE(T_FILEHANDLER1, 'MAXIMO Safety Plan Work Asset id: ' || Splexiconlink_Rec.spworkassetid);
            UTL_FILE.PUT_LINE(T_FILEHANDLER1, 'MAXIMO Safety Lexicon id: ' || Splexiconlink_Rec.safetylexiconid);
            UTL_FILE.PUT_LINE(T_FILEHANDLER1, 'MAXIMO Safety Lexicon Link id: '|| Splexiconlink_Rec.splexiconlinkid || CRLF);
        end loop;
    UTL_FILE.PUT_LINE(T_FILEHANDLER1, '-----------------------------------------------------' );      

-- Update Pluscassetstatus 
    UTL_FILE.PUT_LINE(T_FILEHANDLER1, 'Status does not updated in pluscassetstatus table' );      
    for Pluscassetstatus_Rec IN Pluscassetstatus_Cur
        loop
            UTL_FILE.PUT_LINE(T_FILEHANDLER1, 'MAXIMO Asset: ' || Pluscassetstatus_Rec.assetnum);
            UTL_FILE.PUT_LINE(T_FILEHANDLER1, 'MAXIMO Asset Status: ' || Pluscassetstatus_Rec.status);
            UTL_FILE.PUT_LINE(T_FILEHANDLER1, 'Existing Asset: ' || Pluscassetstatus_Rec.existing_assetnum);
            UTL_FILE.PUT_LINE(T_FILEHANDLER1, 'Exisitng Asset Status: '|| Pluscassetstatus_Rec.asset_status || CRLF);
        end loop;
    UTL_FILE.PUT_LINE(T_FILEHANDLER1, '-----------------------------------------------------' );       
   
-- New Asset
    UTL_FILE.PUT_LINE(T_FILEHANDLER1, 'New Asset info does not match in Asset Table' );      
    for NewAsset_Rec IN NewAsset_Cur
        loop
            UTL_FILE.PUT_LINE(T_FILEHANDLER1, 'MAXIMO Asset: ' || NewAsset_Rec.assetnum);
            UTL_FILE.PUT_LINE(T_FILEHANDLER1, 'New Asset: ' || NewAsset_Rec.newasset);
            UTL_FILE.PUT_LINE(T_FILEHANDLER1, 'MAXIMO Asset Status: ' || NewAsset_Rec.status);
            UTL_FILE.PUT_LINE(T_FILEHANDLER1, 'New Asset Status: ' || NewAsset_Rec.asset_status);
            UTL_FILE.PUT_LINE(T_FILEHANDLER1, 'MAXIMO Classification: ' || NewAsset_Rec.lbl_asset_classification);
            UTL_FILE.PUT_LINE(T_FILEHANDLER1, 'New Asset Classification: ' || NewAsset_Rec.classification);
            UTL_FILE.PUT_LINE(T_FILEHANDLER1, 'MAXIMO Location: ' || NewAsset_Rec.location);
            UTL_FILE.PUT_LINE(T_FILEHANDLER1, 'New Asset Location: ' || NewAsset_Rec.newlocation);
            UTL_FILE.PUT_LINE(T_FILEHANDLER1, 'MAXIMO Manufacturer: ' || NewAsset_Rec.manufacturer);
            UTL_FILE.PUT_LINE(T_FILEHANDLER1, 'New Asset Manufacturer: ' || NewAsset_Rec.newmanufacturer);
            UTL_FILE.PUT_LINE(T_FILEHANDLER1, 'MAXIMO Model: ' || NewAsset_Rec.lbl_model);
            UTL_FILE.PUT_LINE(T_FILEHANDLER1, 'New Asset Model: ' || NewAsset_Rec.model);
            UTL_FILE.PUT_LINE(T_FILEHANDLER1, 'MAXIMO Serial: ' || NewAsset_Rec.serialnum);
            UTL_FILE.PUT_LINE(T_FILEHANDLER1, 'New Asset Serial: ' || NewAsset_Rec.newserial);
            UTL_FILE.PUT_LINE(T_FILEHANDLER1, 'MAXIMO Strategy: ' || NewAsset_Rec.lbl_strategy);
            UTL_FILE.PUT_LINE(T_FILEHANDLER1, 'New Asset Strategy: ' || NewAsset_Rec.strategy);
            UTL_FILE.PUT_LINE(T_FILEHANDLER1, 'MAXIMO Asset Long Description: ' || NewAsset_Rec.longdesc);
            UTL_FILE.PUT_LINE(T_FILEHANDLER1, 'New Asset Strategy Comments: '|| NewAsset_Rec.strategy_comments || CRLF);
        end loop;
    UTL_FILE.PUT_LINE(T_FILEHANDLER1, '-----------------------------------------------------' );  
    
-- New Asset: Update Status in Pluscassetstatus table 
    UTL_FILE.PUT_LINE(T_FILEHANDLER1, 'New Asset: Status does not updated in pluscassetstatus table' );      
    for NewPluscassetstatus_Rec IN NewPluscassetstatus_Cur
        loop
            UTL_FILE.PUT_LINE(T_FILEHANDLER1, 'MAXIMO Asset: ' || NewPluscassetstatus_Rec.assetnum);
            UTL_FILE.PUT_LINE(T_FILEHANDLER1, 'MAXIMO Asset Status: ' || NewPluscassetstatus_Rec.status);
            UTL_FILE.PUT_LINE(T_FILEHANDLER1, 'Existing Asset: ' || NewPluscassetstatus_Rec.newasset);
            UTL_FILE.PUT_LINE(T_FILEHANDLER1, 'Exisitng Asset Status: '|| NewPluscassetstatus_Rec.asset_status || CRLF);
        end loop;
    UTL_FILE.PUT_LINE(T_FILEHANDLER1, '-----------------------------------------------------' );             
    
-- Duplicate Asset
    UTL_FILE.PUT_LINE(T_FILEHANDLER1, 'Duplicated Asset Info does not math in Asset Table' );      
    for DuplicateAsset_Rec IN DuplicateAsset_Cur
        loop
            UTL_FILE.PUT_LINE(T_FILEHANDLER1, 'MAXIMO Asset: ' || DuplicateAsset_Rec.assetnum);
            UTL_FILE.PUT_LINE(T_FILEHANDLER1, 'New Asset: ' || DuplicateAsset_Rec.newasset);
            UTL_FILE.PUT_LINE(T_FILEHANDLER1, 'MAXIMO Asset Status: ' || DuplicateAsset_Rec.status);
            UTL_FILE.PUT_LINE(T_FILEHANDLER1, 'New Asset Status: ' || DuplicateAsset_Rec.asset_status);
            UTL_FILE.PUT_LINE(T_FILEHANDLER1, 'MAXIMO Classification: ' || DuplicateAsset_Rec.lbl_asset_classification);
            UTL_FILE.PUT_LINE(T_FILEHANDLER1, 'New Asset Classification: ' || DuplicateAsset_Rec.classification);
            UTL_FILE.PUT_LINE(T_FILEHANDLER1, 'MAXIMO Location: ' || DuplicateAsset_Rec.location);
            UTL_FILE.PUT_LINE(T_FILEHANDLER1, 'New Asset Location: ' || DuplicateAsset_Rec.newlocation);
            UTL_FILE.PUT_LINE(T_FILEHANDLER1, 'MAXIMO Manufacturer: ' || DuplicateAsset_Rec.manufacturer);
            UTL_FILE.PUT_LINE(T_FILEHANDLER1, 'New Asset Manufacturer: ' || DuplicateAsset_Rec.newmanufacturer);
            UTL_FILE.PUT_LINE(T_FILEHANDLER1, 'MAXIMO Model: ' || DuplicateAsset_Rec.lbl_model);
            UTL_FILE.PUT_LINE(T_FILEHANDLER1, 'New Asset Model: ' || DuplicateAsset_Rec.model);
            UTL_FILE.PUT_LINE(T_FILEHANDLER1, 'MAXIMO Serial: ' || DuplicateAsset_Rec.serialnum);
            UTL_FILE.PUT_LINE(T_FILEHANDLER1, 'New Asset Serial: ' || DuplicateAsset_Rec.newserial);
            UTL_FILE.PUT_LINE(T_FILEHANDLER1, 'MAXIMO Strategy: ' || DuplicateAsset_Rec.lbl_strategy);
            UTL_FILE.PUT_LINE(T_FILEHANDLER1, 'New Asset Strategy: ' || DuplicateAsset_Rec.strategy);
            UTL_FILE.PUT_LINE(T_FILEHANDLER1, 'MAXIMO Asset Long Description: ' || DuplicateAsset_Rec.longdesc);
            UTL_FILE.PUT_LINE(T_FILEHANDLER1, 'New Asset Strategy Comments: '|| DuplicateAsset_Rec.strategy_comments || CRLF);
        end loop;
    UTL_FILE.PUT_LINE(T_FILEHANDLER1, '-----------------------------------------------------' );    
    
--  Duplicated Asset: Update Status in Pluscassetstatus table 
    UTL_FILE.PUT_LINE(T_FILEHANDLER1, 'Duplicated Asset: Status does not updated in pluscassetstatus table' );      
    for DupPluscassetstatus_Rec IN DupPluscassetstatus_Cur
        loop
            UTL_FILE.PUT_LINE(T_FILEHANDLER1, 'MAXIMO Asset: ' || DupPluscassetstatus_Rec.assetnum);
            UTL_FILE.PUT_LINE(T_FILEHANDLER1, 'MAXIMO Asset Status: ' || DupPluscassetstatus_Rec.status);
            UTL_FILE.PUT_LINE(T_FILEHANDLER1, 'MAXIMO Change By: ' || DupPluscassetstatus_Rec.changeby);
            UTL_FILE.PUT_LINE(T_FILEHANDLER1, 'MAXIMO Change Date: ' || DupPluscassetstatus_Rec.changedate);
            UTL_FILE.PUT_LINE(T_FILEHANDLER1, 'Existing Asset: ' || DupPluscassetstatus_Rec.newasset);
            UTL_FILE.PUT_LINE(T_FILEHANDLER1, 'Exisitng Asset Status: '|| DupPluscassetstatus_Rec.asset_status || CRLF);
        end loop;
    UTL_FILE.PUT_LINE(T_FILEHANDLER1, '-----------------------------------------------------' );      
        
--  Asset Ancestor 
    UTL_FILE.PUT_LINE(T_FILEHANDLER1, 'New Assset is not in Asset Ancestor Table' );      
    for AssetAncestor_Rec IN AssetAncestor_Cur
        loop
            UTL_FILE.PUT_LINE(T_FILEHANDLER1, 'New Asset : '|| AssetAncestor_Rec.newasset || CRLF);
        end loop;
    UTL_FILE.PUT_LINE(T_FILEHANDLER1, '-----------------------------------------------------' );  

-- Asset Doclinks
    UTL_FILE.PUT_LINE(T_FILEHANDLER1, 'Duplicated Doclink is not exist' );      
    for Doclinks_Rec IN Doclinks_Cur
        loop
            UTL_FILE.PUT_LINE(T_FILEHANDLER1, 'Existing Asset: ' || Doclinks_Rec.existing_assetnum);
            UTL_FILE.PUT_LINE(T_FILEHANDLER1, 'New Asset: ' || Doclinks_Rec.assetnum);
            UTL_FILE.PUT_LINE(T_FILEHANDLER1, 'MAXIMO Old Document: ' || Doclinks_Rec.olddocument);
            UTL_FILE.PUT_LINE(T_FILEHANDLER1, 'MAXIMO New Document: ' || Doclinks_Rec.newdocument);
            UTL_FILE.PUT_LINE(T_FILEHANDLER1, 'MAXIMO Old Document Type: ' || Doclinks_Rec.olddoctype);
            UTL_FILE.PUT_LINE(T_FILEHANDLER1, 'MAXIMO New Document Type: ' || Doclinks_Rec.newdoctype);
            UTL_FILE.PUT_LINE(T_FILEHANDLER1, 'MAXIMO Old Owner ID: ' || Doclinks_Rec.oldownerid);
            UTL_FILE.PUT_LINE(T_FILEHANDLER1, 'MAXIMO New Owner ID : '|| Doclinks_Rec.newownerid || CRLF);
        end loop;
    UTL_FILE.PUT_LINE(T_FILEHANDLER1, '-----------------------------------------------------' );  
    
-- Asset Trans
    UTL_FILE.PUT_LINE(T_FILEHANDLER1, 'No record in AssetTrans Table' );      
    for assettrans_Rec IN assettrans_Cur
        loop
            UTL_FILE.PUT_LINE(T_FILEHANDLER1, 'MAXIMO Asset: ' || assettrans_Rec.assetnum);
            UTL_FILE.PUT_LINE(T_FILEHANDLER1, 'New Asset: ' || assettrans_Rec.newasset);
            UTL_FILE.PUT_LINE(T_FILEHANDLER1, 'MAXIMO Asset Location: ' || assettrans_Rec.toloc);
            UTL_FILE.PUT_LINE(T_FILEHANDLER1, 'Asset Location: '|| assettrans_Rec.location || CRLF);
        end loop;
    UTL_FILE.PUT_LINE(T_FILEHANDLER1, '-----------------------------------------------------' );      
        
-- Close the text file    
    UTL_FILE.FCLOSE(T_FILEHANDLER1);                      
end;
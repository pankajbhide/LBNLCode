####################################################
# Purpose:  Library functions for validate locations
#
# Author : Pankaj Bhide
#
# Date    : Mar 31, 2017
#
# Revision
# History : 

######################################################
import sys
from lblpycommon import * 
import cx_Oracle

def myExit(logFile, dbConnection, boolError):
    
    if (logFile is not None):
        logFile.close()
        
    if (dbConnection is not None):
        dbConnection.close()
        dbConnection=None
        
    if (boolError):
        exit(1)
    else:
        exit(0)
###############################################
# Function to insert the row into the log table
###############################################
def insertLogtable(dbConnection, strSource, strAbout, logFile, strBuilding, strFloor, strRoom, strError):
 
    strInsert = "INSERT INTO batch_maximo.lbl_arch2maxverify "
    strInsert +=" (orgid, siteid, source, building_number, floor_number, room_number, error_message, changedate)"
    strInsert +=" VALUES ('LBNL','FAC', :source, :building_number, :floor_number, :room_number, :error_message, sysdate)"
    logCursor=dbConnection.cursor();

    try:
        logCursor.execute (strInsert,source=strSource, building_number=strBuilding, floor_number=strFloor, room_number=strRoom, error_message=strAbout +":"+strError)
    except cx_Oracle.DatabaseError, exception:
            logFile.write("ERROR: Failure in inserting data to the log file")
            myExit(logFile, dbConnection, True)            

    logCursor.close ()
    logCursor=None

############################################################################
# Function to check whether data in Archibus correctly reflects in MAXIMO
#############################################################################
def validateMaximoData(dbConnection,strMaxEntity,logFile, strBl_id, strFl_id, strRm_id, strSite_id, strLbl_inactive):
    
    ###################################################################################
    # All the active buildings in Archibus must exists in MAXIMO showing active status
    ###################################################################################
    maxCursor=dbConnection.cursor();
    
    ##### Buildings ##########
    if (strMaxEntity=='BUILDING'):
        strSelect="select locality, trim(to_char(inactive)) inactive from space_building where building_number=:bl_number"
        try:
            maxCursor.execute (strSelect, bl_number=strBl_id)
        except cx_Oracle.DatabaseError, exception:
            logFile.write("ERROR: Failed to select from space_building\n")
            myExit(logFile, dbConnection, True)   
            
                  
        resultSet = maxCursor.fetchall ()        
        boolMaxBuildingFound=False  
        for strLocality, strInactive in resultSet:
            
            boolMaxBuildingFound=True
            if (strLocality != strSite_id):
                insertLogtable(dbConnection, "ARCHIBUS","BUILDING" ,logFile,strBl_id, strFl_id, strRm_id, "Building: Locality in MAXIMO differs from Site id Archibus")
            if (strLbl_inactive !=strInactive):
                insertLogtable(dbConnection, "ARCHIBUS", "BUILDING", logFile, strBl_id, strFl_id, strRm_id, "Building: Inactive in MAXIMO differs from inactive in Archibus")
            
            
        if ((boolMaxBuildingFound==False) and (strLbl_inactive=="0")):
            insertLogtable(dbConnection, "ARCHIBUS", logFile, strBl_id, strFl_id, strRm_id, "Active building in Archibus missing in MAXIMO")
            
    ##### Floors ##########        
    if (strMaxEntity=='FLOOR'):
        strSelect="select floor_number, trim(to_char(inactive)) inactive from space_floor where building_number=:1 and floor_number=:2"
        try:
            maxCursor.execute (strSelect, (strBl_id, strFl_id))
        except cx_Oracle.DatabaseError, exception:
            logFile.write("ERROR: Failed to select from space_floor\n")
            myExit(logFile, dbConnection, True)   
            
            
        resultSet = maxCursor.fetchall ()    
        boolMaxFloorFound=False  
        for strTemp1, strInactive in resultSet:
            
            boolMaxFloorFound=True          
            if (strLbl_inactive !=strInactive):
                insertLogtable(dbConnection, "ARCHIBUS","FLOOR", logFile,strBl_id, strFl_id, strRm_id, "Floor: Inactive in MAXIMO differs from inactive in Archibus")
                            
        if ((boolMaxFloorFound==False) and (strLbl_inactive=="0")):
            insertLogtable(dbConnection, "ARCHIBUS", "FLOOR", logFile, strBl_id, strFl_id, strRm_id, "Floor: Active floor in Archibus missing in MAXIMO")                
    
    ##### Room ##########        
    if (strMaxEntity=='ROOM'):
        strSelect="select room_number, trim(to_char(inactive)) inactive from space_room where building_number=:bl_number and floor_number=:fl_number and room_number=:rm_number"
        try:
            maxCursor.execute (strSelect, bl_number=strBl_id, fl_number=strFl_id, rm_number=strRm_id)
        except cx_Oracle.DatabaseError, exception:
            logFile.write("ERROR: Failed to select from space_room\n")
            myExit(logFile, dbConnection, True) 
            
        
        resultSet = maxCursor.fetchall ()    
        boolMaxRoomFound=False  
        for strTemp1, strInactive in resultSet :
            
            boolMaxRoomFound=True
            if (strLbl_inactive != strInactive):
                insertLogtable(dbConnection, "ARCHIBUS", "ROOM", logFile,strBl_id, strFl_id, strRm_id, "Room: Inactive in MAXIMO differs from inactive in Archibus")
                
            
        if ((boolMaxRoomFound==False) and (strLbl_inactive=="0")):
            insertLogtable(dbConnection, "ARCHIBUS", "ROOM", logFile,strBl_id, strFl_id, strRm_id, "Room: Active room in Archibus missing in MAXIMO")                
                  
      
#####################################################
# Purpose:  Program to validate data about buildings
#           floors, rooms in Archibus and MAXIMO
#
# Author : Pankaj Bhide
#
# Date    : Mar 18, 2017
#
# Revision
# History : 
######################################################
import sys
sys.path.append('/apps/mxes/py_local_packages')
sys.path.append('/apps/mxes/max7tidal/fac/python')
from lblpycommon import * 
import cx_Oracle
import datetime
from lblpy import Locations
from lblpy import func_validatelocations

           
######################################
###### Main program starts from here
######################################

###########################################################
# Create a log file where all the messages can be logged
###########################################################

logFile=lbl_libutil01.createLogfile("MAXIMO", "validatelocations")

if (logFile is None):
    print "Can not create a log file for lbl_validatelocations" 
    exit (1)

now = datetime.datetime.now()
strDate=now.strftime("%m-%d-%Y %H:%M")
logFile.write("Program to validate locations data started " + strDate +"\n")
############################
# Get database connection
############################
try:
    dbConnection=lbl_libutil01.getDBConnection("MAXIMO")
except cx_Oracle.DatabaseError, exception:
    logFile.write("ERROR: Failure in connecting to the database")
    func_validatelocations.myExit(logFile,dbConnection, True)
    
if (dbConnection is None):
    logFile.write("ERROR: Failure in connecting to the database")
    func_validatelocations.myExit(logFile,dbConnection, True)
   
    
##################################################
# Delete all the prior records from the log table
##################################################
logCursor0=dbConnection.cursor();
strDelete="delete from batch_maximo.lbl_arch2maxverify"

try:
    logCursor0.prepare(strDelete)   
except:
    logFile.write("ERROR: Failure in connecting to the database")
    func_validatelocations.myExit(logFile,dbConnection, True)
    

try:
    logCursor0.execute(None)
         
except cx_Oracle.DatabaseError, exception:
    logFile.write("ERROR: Failed to execute delete from log table")        
    func_validatelocations.myExit(logFile, dbConnection, True)

######################
######BUILDINGS    
######################

################################################
# Validate building records
# Read all the building records from Archibus
################################################
strBlSQL="select bl_id, site_id, name, trim(to_char(lbl_inactive)) lbl_inactive from bl@archibus23 order by bl_id"

############################################################
# Create cursor based on the sql statement for buildings
############################################################  
blCursor=dbConnection.cursor()

try:
    
    blCursor.execute (strBlSQL)
except cx_Oracle.DatabaseError, exception:
    logFile.write("Error: Failed to execute " + strBlSQL + "\n")
    func_validatelocations.myExit(logFile,dbConnection, True)
        
#######################################        
# Get a results set from executed sql
#######################################
resultSet = blCursor.fetchall ()

######################################################################
# Retrieve rows from the building results set and process each record
######################################################################
for strBl_id, strSite_id, strName, strLbl_inactive in resultSet:
    
    print "Processing building: " + strBl_id
    listErrormessagesstrError=""
    #######################################################
    # Create a new instance of building from Building class
    #######################################################
    objBuilding=Locations.Building(strBl_id, strName, strSite_id, strLbl_inactive)
    
    ############################################################
    # Invoke validateBuildingData method for validating the
    # the building details. Returns the list of error messages
    ############################################################
    listErrormessages=objBuilding.validateBuildingdata()
    
    if listErrormessages:
        ############################################
        # Insert the error messages into log table
        ###########################################
        for strError in listErrormessages:
            func_validatelocations.insertLogtable(dbConnection, "ARCHIBUS", "BUILDING",logFile, strBl_id, '', '', strError )
    
    # Now validate the similar data in MAXIMO        
    func_validatelocations.validateMaximoData(dbConnection,'BUILDING',logFile, strBl_id, "", "", strSite_id, strLbl_inactive)
    blCursor=None
    resultSet =None

                              
######################
######FLOORS 
######################    
    
################################################
# Validate floor records
# Read all the floor records from Archibus
################################################
strFlSQL  ="select a.bl_id, a.fl_id, a.name, trim(to_char(a.lbl_inactive)) lbl_inactive,b.bl_id bl_bl_id, trim(to_char(b.lbl_inactive)) "
strFlSQL +=" bl_inactive, b.site_id from fl@archibus23 a left outer join bl@archibus23 b on a.bl_id=b.bl_id"

#####################################################
# Create cursor based on the sql statement for floors
######################################################  
flCursor=dbConnection.cursor()

try:
    
    flCursor.execute (strFlSQL)
except cx_Oracle.DatabaseError, exception:
    logFile.write("Error: Failed to execute " + strFlSQL + "\n")
    func_validatelocations.myExit(logFile,dbConnection, True)
    
#######################################        
# Get a results set from executed sql
#######################################
resultSet = flCursor.fetchall ()

####################################################################
# Retrieve rows from the floor results set and process each record
#####################################################################
for strBl_id, strFl_id, strName, strLbl_inactive, strBlBl_id, strLbl_blinactive, strSite_id in resultSet:
    
    print "Processing floor: " + strBl_id + "-" + strFl_id
    
    listErrormessagesstrError=""
    #######################################################
    # Create a new instance of building from Building class
    #######################################################
    objBuilding=Locations.Building(strBl_id, strName, strSite_id, strLbl_inactive)
    
    ############################################################
    # Invoke validateBuildingData method for validating the
    # the building details. Returns the list of error messages
    ############################################################
    listErrormessages=objBuilding.validateBuildingdata()
    
    if listErrormessages:  # Not empty list
        ############################################
        # Insert the error messages into log table
        ###########################################
        for strError in listErrormessages:
            func_validatelocations.insertLogtable(dbConnection, "ARCHIBUS", "FLOOR",logFile, strBl_id, '', '', strError )
            
    listErrormessagesstrError=""
    #######################################################
    # Create a new instance of floor from Floor class
    #######################################################
    objFloor=Locations.Floor(strBl_id, strFl_id, strSite_id, strLbl_inactive)
    
    ############################################################
    # Invoke validateFloorData method for validating the
    # the building details. Returns the list of error messages
    ############################################################
    listErrormessages=objFloor.validateFloordata()
    
    if listErrormessages:  # Not empty list

        ############################################
        # Insert the error messages into log table
        ###########################################
        for strError in listErrormessages:
            func_validatelocations.insertLogtable(dbConnection, "ARCHIBUS", "FLOOR", logFile, strBl_id, strFl_id, '', strError )
    
    # Now validate the same data into MAXIMO
    func_validatelocations.validateMaximoData(dbConnection,'FLOOR',logFile,strBl_id, strFl_id, "", "", strLbl_inactive)
    flCursor=None
    resultSet=None

######################
######ROOMS
######################
################################################
# Validate room records
# Read all the room records from Archibus
################################################
strRmSQL  = " select a.bl_id, a.fl_id, a.rm_id, trim(to_char(a.area)) area, a.dwgname, layer_name,  trim(to_char(a.lbl_inactive)) lbl_inactive,"
strRmSQL  +=" b.bl_id fl_bl_id, b.fl_id fl_fl_id, trim(to_char(b.lbl_inactive)) fl_lbl_inactive, c.site_id, to_char(trim(c.lbl_inactive)) bl_lbl_inactive " 
strRmSQL  +=" from rm@archibus23 a left outer join fl@archibus23 b on a.bl_id=b.bl_id and a.fl_id=b.fl_id "
strRmSQL  +=" left outer join bl@archibus23 c on c.bl_id=a.bl_id "

#####################################################
# Create cursor based on the sql statement for rooms
######################################################  
rmCursor=dbConnection.cursor()

try:
    
    rmCursor.execute (strRmSQL)
except cx_Oracle.DatabaseError, exception:
    logFile.write("Error: Failed to execute " + strRmSQL + "\n")
    func_validatelocations.myExit(logFile,dbConnection, True)
        

#######################################        
# Get a results set from executed sql
#######################################
resultSet = rmCursor.fetchall ()

####################################################################
# Retrieve rows from the Room results set and process each record
#####################################################################
for strBl_id, strFl_id, strRm_id, strArea, strDwgname, strLayer_name, strLbl_inactive, strFlBl_id, strFl_Fl_id, strLbl_flinactive, strSite_id, strLbl_Blinactive in resultSet:
    
    print "Processing room: " + strBl_id + "-" + strFl_id + "-" + strRm_id
    
    listErrormessagesstrError=""
    #######################################################
    # Create a new instance of building from Building class
    #######################################################
    objBuilding=Locations.Building(strBl_id, strName, strSite_id, strLbl_inactive)
    
    ############################################################
    # Invoke validateBuildingData method for validating the
    # the building details. Returns the list of error messages
    ############################################################
    listErrormessages=objBuilding.validateBuildingdata()
    
    if  listErrormessages:  # Not empty list
        ############################################
        # Insert the error messages into log table
        ###########################################
        for strError in listErrormessages:
            func_validatelocations.insertLogtable(dbConnection, "ARCHIBUS", "ROOM", logFile, strBl_id, '', '', strError )
            
    listErrormessagesstrError=""
    #######################################################
    # Create a new instance of floor from Floor class
    #######################################################
    objFloor=Locations.Floor(strBl_id, strFl_id, strSite_id, strLbl_inactive)
    
    ############################################################
    # Invoke validateFloorData method for validating the
    # the building details. Returns the list of error messages
    ############################################################
    listErrormessages=objFloor.validateFloordata()
    
    if listErrormessages:  # Not empty list

        ############################################
        # Insert the error messages into log table
        ###########################################
        for strError in listErrormessages:
            func_validatelocations.insertLogtable(dbConnection, "ARCHIBUS", "ROOM", logFile, strBl_id, strFl_id, '', strError )

    #######################################################
    # Create a new instance of room from Room class
    #######################################################
    objRoom=Locations.Room(strBl_id, strFl_id, strRm_id, strLbl_inactive, strArea,strDwgname,strLayer_name)
    
    ############################################################
    # Invoke validateRoomData method for validating the
    # the building details. Returns the list of error messages
    ############################################################
    listErrormessages=objRoom.validateRoomdata()
    
    if listErrormessages:  # Not empty list

        ############################################
        # Insert the error messages into log table
        ###########################################
        for strError in listErrormessages:
            func_validatelocations.insertLogtable(dbConnection, "ARCHIBUS", "ROOM", logFile,strBl_id, strFl_id, strRm_id, strError )
            
    # Now validate the same data into MAXIMO        
    func_validatelocations.validateMaximoData(dbConnection,'ROOM',logFile, strBl_id, strFl_id, strRm_id, "", strLbl_inactive)
    rmCursor=None
    resultSet=None    

dbConnection.commit()

###############################################################
# Generate a report of the errors stored in the log table 
# so that the report can be emailed to the Facilities Planning
# group.
################################################################

strLogSQL  =" select building_number, nvl(floor_number, ' ') floor_number, nvl(room_number,' ') room_number, error_message "
strLogSQL +=" from  batch_maximo.lbl_arch2maxverify order by building_number, floor_number, room_number"

logCursor=dbConnection.cursor()

try:
    
    logCursor.execute (strLogSQL)
except cx_Oracle.DatabaseError, exception:
    logFile.write("Error: Failed to execute " + strLogSQL + "\n")
    func_validatelocations.myExit(logFile,dbConnection, True)
        

#######################################
# Get a results set from executed sql
#######################################
resultSet = logCursor.fetchall()
intLogcount=0

####################################################################
# Retrieve rows from the log results set and process each record
#####################################################################
chrDblquote = "\""
now = datetime.datetime.now()
strDate=now.strftime("%m-%d-%Y %H:%M")

strBody  = "<HTML>\n<HEAD>\n<TITLE>Archibus-MAXIMO Location reconciliation report( " + strDate + " )</TITLE>\n</HEAD>\n<BODY>\n"
strBody += "<P align=" + chrDblquote + "center" + chrDblquote + "><FONT face=" + chrDblquote + "Arial" + chrDblquote + " size=" + chrDblquote + "4" + chrDblquote + ">"
strBody += "Lawrence Berkeley National Laboratory</FONT></P>\n"
strBody += "<P align=" + chrDblquote + "center" + chrDblquote + "><FONT face=" + chrDblquote + "Arial" + chrDblquote + " size=" + chrDblquote + "4" + chrDblquote + ">"
strBody += "Archibus-MAXIMO Location reconciliation report " +  strDate + " </FONT></P>\n";
strBody += "</HEAD>\n<BODY>\n<FONT face=" + chrDblquote + "Arial" + chrDblquote + ">\n<TABLE align=" + chrDblquote + "center" + chrDblquote + " border = \"1\">\n"
strBody += "<TR><TH>#</TH><TH>Building Number</TH><TH>Floor Number</TH><TH>Room Number</TH><TH>Error Message</TH/></TR>\n"


for strBuilding_number, strFloor_number, strRoom_number, strError_message in resultSet:
    intLogcount=intLogcount+1
    if (lbl_libutil01.isBlank(strBuilding_number) == False):
        strBody +="<TR><TD>" + str(intLogcount) + "</TD><TD>" + strBuilding_number+ "</TD><TD>" + strFloor_number + "</TD><TD>" + strRoom_number + "</TD><TD>" + strError_message + "</TD></TR>"
    
   
strBody +="<TR><TD></TD><TR></TABLE></BODY></HTML>"


if (intLogcount >0):
    lbl_libutil01.send_html_email('PBhide@lbl.gov', 'PBhide@lbl.gov', "Archibus-MAXIMO Locations Reconciliation", strBody)
    
logCursor=None
resultSet=None

now = datetime.datetime.now()
strDate=now.strftime("%m-%d-%Y %H:%M")

logFile.write("Program to validate locations data completed " + strDate + "\n")

# Normal successful exit    
func_validatelocations.myExit(logFile, dbConnection, False)


    

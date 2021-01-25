#####################################################
# Purpose:  Module holding definitions of classes 
#
#
#
# Author : Pankaj Bhide
#
# Date    : Mar 18, 2017
#
# Revision
# History :  Mar 13, 2018 Extra validation checks for
#                         extended room numbering       
######################################################
""" 
    Module holding the definitions of building, floor
    and room classes. 
"""

from lblpycommon import * 

#############################
# Building class definition
#############################
class Building(object):
    
    def __init__(self, bl_id=None, name=None, site_id=None,inactive=None):
        """ 
            Building class initializer
        """

        self.bl_id=bl_id
        self.name=name
        self.site_id=site_id
        self.inactive=inactive
        
    def validateBuildingdata(self):
        """
            Method to validate building data in Archibus
            Returns the list containing details of invalid data
        """
        listErrormessages=[]
        
        if (self.inactive=="0"):
            
            # Building Id should not be null
            if (lbl_libutil01.isBlank(self.bl_id)==True):
                listErrormessages.append("Building number should not be blank")
                            
            #Site id should not be null
            if (lbl_libutil01.isBlank(self.site_id)== True):
                listErrormessages.append("Site id should not be blank")
                            
            #Length of building number should either be 3 or 4   
            if (len(self.bl_id) < 3 or len(self.bl_id) > 4):
                listErrormessages.append("Length of the building number should either be 3 or 4")    
                
            # If length of building number is 4, then last character should be alpha
            if (len(self.bl_id) == 4 and self.bl_id != "0000"):               
                # Get the last character of the building number
                strLastChar=self.bl_id[-1:]
                if ((strLastChar.isalpha()) == False):
                    listErrormessages.append("Last character of the building number should either be alpha or zero")
                      
        return listErrormessages

#############################
# Floor class definition
#############################        
class Floor():
    def __init__(self, bl_id=None, fl_id=None, site_id=None,inactive=None):
        """ 
            Floor class initializer
        """
        self.bl_id=bl_id
        self.fl_id=fl_id
        self.site_id=site_id
        self.inactive=inactive
        
    listErrormessages=[]
    def validateFloordata(self):
        """
        Method to validate floor data in Archibus. 
        Returns the list containing details about invalid data
        """
        listErrormessages=[]
         
        if (lbl_libutil01.isBlank(self.inactive) == "0"):
        	if (lbl_libutil01.isBlank(self.fl_id) == True):
            		listErrormessages.append("Floor number should not be blank")
            
        	#Length of floor number should be 1 or 2 
        	if (len(self.fl_id) < 1 or len(self.fl_id) > 2):    
            		listErrormessages.append("Length of the floor number should either be 1 or 2")
            
        	if (len(self.fl_id)==2 and self.site_id=="H" and self.bl_id !="0000"):    
            		# Get the last character of the building number
            		strLastChar=self.fl_id[-1:]
            		if ((strLastChar.isalpha()) == False):
                		listErrormessages.append("Last character of the floor number should be alpha")
                
        return listErrormessages
                                
class Room():
    def __init__(self, bl_id=None, fl_id=None, rm_id=None,inactive=None, area=None,dwg_name=None, layer_name=None):
        """ 
            Room class initializer
        """
        self.bl_id=bl_id
        self.fl_id=fl_id
        self.rm_id=rm_id
        self.inactive=inactive
        self.area=area
        self.dwg_name=dwg_name
        self.layer_name=layer_name
                
    listErrormessages=[]
    def validateRoomdata(self):
        """
        Method to validate Room data in Archibus. 
        Returns the list containing details about invalid data
        """
        listErrormessages=[]
        
        if (lbl_libutil01.isBlank(self.rm_id) == True):
            listErrormessages.append("Room number should not be blank")
        
        if (self.inactive=="0"):            
            #Length of active room number should be either 4 or 6
             
            if (len(self.rm_id) < 4 or len(self.rm_id) > 6):                
                    listErrormessages.append("Length of the active room number should be either be 4 or 6")
            
            if (len(self.rm_id)==5):
                # Get the last character of the room number
                strLastChar=self.rm_id[-1:]
                if ((strLastChar.isalpha()) == False):
                    listErrormessages.append("Last character of the room number should be alpha")
                            
            if (len(self.rm_id)==6):    
                # 5th character should either be A-Z
                # 6th character should either be 1-9
                str5thChar=self.rm_id[4]
                str6thChar=self.rm_id[5]
                
                if (str5thChar.isalpha() == False or str5thChar.islower()==True):
                    listErrormessages.append("The 5th character of the room number should be upper case alpha [A-Z]")
                    
                if (str6thChar.isdigit() == False or str6thChar=='0'):
                    listErrormessages.append("The 6th character of the room number should be [1-9]")
                    
                    
                
            #if (lbl_libutil01.isBlank(self.dwg_name) == True):
            #    listErrormessages.append("Drawing name should not be blank")
            
            if (self.area=="0" and lbl_libutil01.isBlank(self.dwg_name) == False):

                listErrormessages.append("Area of the room should be greater than zero");
                                
                if (lbl_libutil01.isBlank(self.layer_name)== True):
                	listErrormessages.append("Layer name should not be blank ")
                
        return listErrormessages
 

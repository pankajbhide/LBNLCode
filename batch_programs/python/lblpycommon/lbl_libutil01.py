#####################################################
# Purpose:  General purpose library functions
#
# Author : Pankaj Bhide
#
# Date    : Mar 18, 2017
#
# Revision
# History : 

######################################################
""" 
   Library of utility functions 
"""
import cx_Oracle
import smtplib
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText
import platform
import os
import datetime
import csv

########################################
# Function to write to CSV file 
#########################################
def writeCSV(strPath, strFieldnames, data):
    """
    Writes a CSV file using DictWriter
    """
    with open(strPath, "wb") as out_file:
        writer = csv.DictWriter(out_file, delimiter=',' ,quoting=csv.QUOTE_ALL, fieldnames=strFieldnames)
        writer.writeheader()
        for row in data:
            writer.writerow(row)

########################################
# Function to return database connection
#########################################

def getDBConnection(strDBName):
    """
    Method that returns Oracle DB connection 
    object. The argument is database name 
    For example getDBConnection("MAXIMO")
    will return Oracle db connection object.
    """
 
    if (strDBName=="MAXIMO"):
        try:
            
            if (platform.system()=='Windows'):
                with open('C:\PyDevelopment\mxes_meta_file', 'r') as content_file: 
                    content = content_file.read()
            else:  ## Solaris/Linux
                strHome=os.environ['HOME']
                strDBMetafile=strHome +  "/max7tidal/mxes_meta_dir/mxes_meta_file"
                with open(strDBMetafile, 'r') as content_file:
                    content = content_file.read()
        except:
            return None
  
    listcontent=content.split('/')
    strUsername=listcontent[0]
 
    strPassworddb=listcontent[1]
    listpassdb=strPassworddb.split('@')
 
    strPassword=listpassdb[0]
    strDatabase=listpassdb[1]
    strDatabase=strDatabase.strip()

 
    conn = cx_Oracle.connect(strUsername,strPassword,strDatabase)
    return conn  # this contain db connection object

################################################
# Function to find whether the string is blank
################################################
def isBlank (myString):
    """
    Method to find out whether the string is empty or not
    If the string is empty, it returns true, else it returns
    false.
    """ 
    if myString and myString.strip():
        #myString is not None AND myString is not empty or blank
        return False
    #myString is None OR myString is empty or blank
    return True


############################################################
# Function to return string that contains a list columns
# surrounded by quotes from a list
############################################################
def surroundquote(myColumnsList):
    """
    Method to return list of string that contains a list
    of columns surrounded by quotes from a list
    """ 
    strColumns=""
    for column in myColumnsList:
        if (isBlank(strColumns) ==True):
            strColumns = '"' + column +'"'
        else:
            strColumns += ',"' + column+ '"'
    
    return strColumns
#########################################################
# Function to send HTML formatted email
#########################################################
def send_html_email(strFrom,  strTo, strSubject, strBody):
    """
    Method to send email using HTML format.
    The arguments are from, to, subject and body of the email
    using HTML tags
    """    
    # me == my email address
    # you == recipient's email address
    me = strFrom
    you = strTo
    
    # Create message container - the correct MIME type is multipart/alternative.
    msg = MIMEMultipart('alternative')
    msg['Subject'] = strSubject
    msg['From'] = me
    msg['To'] = you
    
    # Create the body of the message (a plain-text and an HTML version).
    text = strBody
    html = strBody 
    # Record the MIME types of both parts - text/plain and text/html.
    part1 = MIMEText(text, 'plain')
    part2 = MIMEText(html, 'html')
    
    # Attach parts into message container.
    # According to RFC 2046, the last part of a multipart message, in this case
    # the HTML message, is best and preferred.
    msg.attach(part1)
    msg.attach(part2)
    
    # Send the message via local SMTP server.
    s = smtplib.SMTP('smtp.lbl.gov')
    # sendmail function takes 3 arguments: sender's address, recipient's address
    # and message to send - here it is sent as one string.
    s.sendmail(me, you, msg.as_string())
    s.quit()
        
##############################################
# Function to create log file with the given
# application and name
#############################################

def createLogfile(strApplication, strLogfilename):
    """
    Method that returns log file handle.
    Depending upon the application (passed as first argument)
    and file name (passed as second argument), the method
    creates a log file and return log file handle. 
    """
    now = datetime.datetime.now()
    strDate=now.strftime("%Y%m%d%H%M")
    strFormattedfilename=strLogfilename+"log."+strDate
    logFile=None
    
    if (strApplication=="MAXIMO"):
        
        try:
            
            if (platform.system()=='Windows'):
                
                strFileWithPath='C:\PyDevelopment\\'+ strFormattedfilename
                           
                    
            else:  ## Solaris/Linux
                strHome=os.environ['HOME']
                strFileWithPath=strHome +  "/max7tidal/fac/log/" + strFormattedfilename
                
            
            logFile=open(strFileWithPath , 'w+')
             
        except:
            pass
        
        return logFile
            
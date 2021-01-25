package lbl;


import java.io.BufferedWriter;
import java.io.FileOutputStream;
import java.io.FileWriter;
import java.io.PrintWriter;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.text.SimpleDateFormat;
import java.util.Date;

import org.apache.poi.hssf.usermodel.HSSFCell;
import org.apache.poi.hssf.usermodel.HSSFCellStyle;
import org.apache.poi.hssf.usermodel.HSSFFont;
import org.apache.poi.hssf.usermodel.HSSFFooter;
import org.apache.poi.hssf.usermodel.HSSFHeader;
import org.apache.poi.hssf.usermodel.HSSFRow;
import org.apache.poi.hssf.usermodel.HSSFSheet;
import org.apache.poi.hssf.usermodel.HSSFWorkbook;
import org.apache.poi.hssf.util.HSSFColor;

import util.MailUtil;
import util.MaxConnection;

/****************************************************************
*  
* Program name: SendWOFeedback.java
* * 
* Description : This program sends the email notifications to
*               the nominated recipients for the work order
*               feedback sumbitted from the customers
*                 
* Date Written : 31-MAY-2007
*                
* Author       : Pankaj Bhide
* 
* Modification
* History      :Modified by Pankaj on 2/20/08 at the request of
*               Heather P for sending her the report as CC.
*               
*               April 30 2009 Changes for MXES
*               
*               August 06 2010 Changes requested by Facilities
*               for multiple feedback requests
*               
*               Sept 29, 2010 Fixed wordwrap function to avoid
*               null pointer exception
*               
*               Dec 22, 2010 Exclude zero from below threshold 
*               sheet (RT#89242)
* *****************************************************************/
public class SendWOFeedback
{

    public static void main(String[] args) throws SQLException, Exception
    {
        PrintWriter   printWriter = null;
	    FileWriter fileOutStrm=null;
	    BufferedWriter bufWriter=null;
	    Connection myConnection;
        Statement myStatement1=null;
        PreparedStatement pstmt, pstmt2=null;
        String strSelectStat1=null, strSelect=null;
        ResultSet Rs1=null;
        HSSFWorkbook wb=null;
        String strFileName=null,  strSort=null;
        FileOutputStream fileOut=null;
        HSSFSheet sheet=null, sheet2=null, sheet3=null;
        HSSFRow row=null;
        HSSFCell cellWorkorderNumber=null, cellWorkorderDescription=null;
        HSSFCell cellSupervisor=null, cellCustomer=null, cellComments=null;
        HSSFCell cellFeedbackCriteria=null, cellFeedbackRating=null;
        HSSFCell  cellWorktype=null,  cellReportedby=null, cellFeedbackdate=null;
        int intReccount=0, intTotalReccount=0, intMinThreshold=0;
        String strLastDateTime=null, strWOFeedBackEmailList=null;
        String strApplicationenv=null, strTestuserid=null;
        String strMinThreashold=null;
        String strSubjectline="", strFooter="";
        String strBody="", strPrvWonum="";
        boolean bolPrintComments=false;
      
        // Changes for MXES 
     	if (args.length==0)
    	{
    	    System.out.println("SendWOFeedback <orgid> <siteid>" );
    	    System.exit(1);
    	}
        
    	String strOrgid=args[0].trim();
    	String strSiteid=args[1].trim();
    	
    	if (strOrgid.length() ==0)
    		strOrgid="LBNL";
    	
    	if (strSiteid.length() ==0)
    		strSiteid="FAC";
    	    	
       // Output log file
        try 
        {
            fileOutStrm=new  FileWriter("sendwofeedback.log", true);
            bufWriter  =new  BufferedWriter(fileOutStrm);
            printWriter=new  PrintWriter(bufWriter);
        }
        catch (Exception ex)
        {
          System.out.println("IO Exception: " + ex);
          System.exit(1);
        }
   	    
        Date startDateTime = new Date();           
        printWriter.println("Program started at :" + startDateTime);
        System.out.println("Program started at :" + startDateTime);
        
        try 
    	{
    	  // Acquire db connect object
    	
    	  myConnection = MaxConnection.getDBConnection();
    	  myConnection.setAutoCommit(false);  	     	  
       	}
    	 finally {    	    
    	 } 
   	  
    	 // Firstly get the contents of the parameter values the 
    	 // last date/time when the program was executed 
    	 
    	 strSelectStat1  =" select varname, varvalue from lbl_maxvars ";
    	 strSelectStat1 +=" where  varname in ('WOFEEDBACK_EMAIL_SENT_DATE',"; 
    	 strSelectStat1 +=" 'WOFEEDBACK_EMAIL_LIST','APPLICATION_ENV', ";
    	 strSelectStat1 +=" 'TEST_USER_ID','WOFEEDBACK_MIN_THRESHOLD') ";
    	 strSelectStat1 +="  and orgid=" + "'"  + strOrgid +"'";
    	 strSelectStat1 +="  and siteid=" + "'" + strSiteid +"'";
    	 myStatement1 = myConnection.createStatement();	     	 
    	 Rs1=myStatement1.executeQuery(strSelectStat1);
    	     	 
    	 intReccount=0;
    	 // Browse through the record set
    	 while(Rs1.next()) 			    
    	 {
    	     intReccount++;    	     
    	     	    
    	     if (Rs1.getString("varname").equals("WOFEEDBACK_EMAIL_SENT_DATE"))
    	         strLastDateTime=Rs1.getString("varvalue");
    	    
    	     if (Rs1.getString("varname").equals("WOFEEDBACK_EMAIL_LIST"))
    	         strWOFeedBackEmailList=Rs1.getString("varvalue");    	
    	     
    	     if (Rs1.getString("varname").equals("APPLICATION_ENV"))
    	         strApplicationenv=Rs1.getString("varvalue");    	
    	     
    	     if (Rs1.getString("varname").equals("TEST_USER_ID"))
    	         strTestuserid=Rs1.getString("varvalue");
    	    
    	     if (Rs1.getString("varname").equals("WOFEEDBACK_MIN_THRESHOLD"))
    	     {
    	         strMinThreashold=Rs1.getString("varvalue");
    	         intMinThreshold=java.lang.Integer.parseInt(strMinThreashold);
    	     }   	       
    	         	     
    	 } // while(Rs1.next())
    	 if (Rs1 != null) Rs1.close();
    	 
    	 if (intReccount != 5)
    	 {
     	    printWriter.println("Key rows missing in lbl_maxvars table. Contact support");
  	        System.out.println("Key rows missing in lbl_maxvars table. Contact support");
  	        if (myConnection != null) myConnection.close();
  	        System.exit(1);
    	 } // if (intReccount != 5)   	 
    	 
         // Create a new work book
    	 SimpleDateFormat df = new SimpleDateFormat("yyyyMMddHHmmss");
    	 SimpleDateFormat df1 = new SimpleDateFormat("MM/dd/yyyy HH:mm:ss");
    	    	 
    	 wb=new HSSFWorkbook();
         strFileName="WorkFeedback_" + df.format(startDateTime)+ ".xls";
         fileOut=new FileOutputStream(strFileName);                      
         
         HSSFFont font=wb.createFont();
         font.setBoldweight(HSSFFont.BOLDWEIGHT_BOLD);
         font.setColor(HSSFColor.BLUE.index);
                       
         HSSFFont fontRed=wb.createFont();
         fontRed.setBoldweight(HSSFFont.BOLDWEIGHT_BOLD);
         fontRed.setColor(HSSFColor.RED.index);
         
         HSSFCellStyle alphaHeaderStyle=wb.createCellStyle();
         alphaHeaderStyle.setAlignment(HSSFCellStyle.BORDER_DOUBLE);
         alphaHeaderStyle.setFillBackgroundColor(HSSFColor.DARK_YELLOW.index);
         alphaHeaderStyle.setFillForegroundColor(HSSFColor.BLACK.index);
         alphaHeaderStyle.setFont(font);
         
         HSSFCellStyle numberHeaderStyle=wb.createCellStyle();
         numberHeaderStyle.setAlignment(HSSFCellStyle.ALIGN_RIGHT);
         numberHeaderStyle.setFillBackgroundColor(HSSFColor.BLUE_GREY.index);
         numberHeaderStyle.setFillForegroundColor(HSSFColor.BLUE_GREY.index);
         numberHeaderStyle.setFont(font);    
         
         HSSFCellStyle numberRowStyle=wb.createCellStyle();
         numberRowStyle.setAlignment(HSSFCellStyle.ALIGN_RIGHT);
         
         HSSFCellStyle numberRowRedStyle=wb.createCellStyle();
         numberRowRedStyle.setAlignment(HSSFCellStyle.ALIGN_RIGHT);
         numberRowRedStyle.setFont(fontRed);
         
    	 
    	 //******************************************************
    	 // Select the qualifying records 
         //******************************************************
    	 strSelectStat1  =" select a.wonum, c.description, ";
    	 strSelectStat1 +=" maximo.lbl_maximo_pkg.get_employee_name(c.supervisor) supervisor_name, ";
    	 strSelectStat1 +=" maximo.lbl_maximo_pkg.get_employee_name(a.customerid) customer_name, ";
    	 strSelectStat1 +=" b.text feedback_criteria, a.value scale,  ";
    	 strSelectStat1 +=" to_char(sysdate,'YYYYMMDD_HH24MI') currentdatetime, ";
    	 strSelectStat1 +=" d.comments submitted_comments, ";
    	 strSelectStat1 +=" c.worktype, ";
    	 strSelectStat1 +=" to_char(a.changedate,'MM-DD-YYYY') feedback_date, ";
    	 strSelectStat1 +=" maximo.lbl_maximo_pkg.get_employee_name(c.reportedby) reportedby_name ";
    	 strSelectStat1 +=" from batch_maximo.lbl_wofeedback a, ";
    	 strSelectStat1 +=" batch_maximo.lbl_feedback b,  ";
    	 strSelectStat1 +=" maximo.workorder c,  ";
    	 strSelectStat1 +=" batch_maximo.lbl_wofeedbackcomments d  ";
    	 strSelectStat1 +=" where a.orgid=b.orgid ";
    	 strSelectStat1 +=" and a.siteid=a.siteid ";
  	     strSelectStat1 +=" and a.id=b.id ";
  	     strSelectStat1 +=" and a.orgid=c.orgid  ";
  	     strSelectStat1 +=" and a.siteid=c.siteid  ";
  	     strSelectStat1 +=" and a.wonum=c.wonum  ";
  	     strSelectStat1 +=" and a.orgid=d.orgid(+)  ";
  	     strSelectStat1 +=" and a.siteid=d.siteid(+)  ";
  	     strSelectStat1 +=" and a.customerid=d.customerid(+) ";
  	     strSelectStat1 +=" and a.wonum=d.wonum(+) ";
  	     // Added by Pankaj on 8/6/10
  	     strSelectStat1 +=" and a.wofeedbackid=d.wofeedbackid(+) ";
  	     strSelectStat1 +=" and a.changedate > to_date(" ;
  	     strSelectStat1 +="'" +strLastDateTime +"',('MM/DD/YYYY HH24:MI:SS'))";
  	     strSelectStat1 +="  and a.orgid=" + "'"  + strOrgid +"'";
  	     strSelectStat1 +="  and a.siteid=" + "'" + strSiteid +"'";
  	     strSort         =" order by  a.wonum, a.customerid, a.id  ";
  	     strSelect      = strSelectStat1 + strSort; 	    	         

  	     Rs1=myStatement1.executeQuery(strSelect);
    	 intTotalReccount=0;
    	 
        // Browse through the record set.
        while(Rs1.next()) 			    
        {
          intTotalReccount++;
          if (intTotalReccount ==1 )
          {             
              /*********************************************
              * 1 ST SHEET - FEEDBACK OF ALL THE QUALIFYING 
              * WORKORDERS
              *********************************************/
              // Create a new sheet
              sheet=wb.createSheet("AllWorkOrdersFeedback");
                                                       
              // Create the header row
               populateHeaderRow(sheet,
                      row,
                      Rs1,
                      cellWorkorderNumber, 
                      cellWorkorderDescription,
                      cellWorktype,
                      cellReportedby,
                      cellSupervisor,
                      cellCustomer, 
                      cellComments,
                      cellFeedbackCriteria, 
                      cellFeedbackRating,
                      cellFeedbackdate,
                      "ALLWORKORDERS",
                      alphaHeaderStyle,
                      numberHeaderStyle);
          } // if (intReccount==1)
          
          bolPrintComments=false;
          if (! Rs1.getString("wonum").equals(strPrvWonum))
          {
               strPrvWonum=Rs1.getString("wonum");
               bolPrintComments=true;
          } 
          // Create the Data Row
          populateDataRow(sheet,
                  row,
                  Rs1,
                  cellWorkorderNumber, 
                  cellWorkorderDescription,
                  cellSupervisor,
                  cellCustomer, 
                  cellComments,
                  cellFeedbackCriteria, 
                  cellFeedbackRating,
                  intTotalReccount,
                  "ALLWORKORDERS",
                  alphaHeaderStyle,
                  numberHeaderStyle,
                  numberRowStyle,
                  numberRowRedStyle,
                  intMinThreshold,
                  bolPrintComments,
                  cellWorktype,
                  cellFeedbackdate );
        } // while(Rs1.next())
        
        // Auto-size the sheet
        if (intTotalReccount >=1 )
        {
         sheet.autoSizeColumn((short) 0);
         sheet.autoSizeColumn((short) 1);
         sheet.autoSizeColumn((short) 2);
         sheet.autoSizeColumn((short) 3);
         sheet.autoSizeColumn((short) 4);
         sheet.autoSizeColumn((short) 5);         
         sheet.autoSizeColumn((short) 6);         
         sheet.autoSizeColumn((short) 7);         
         sheet.autoSizeColumn((short) 8);         
        } 
         
        /*********************************************
         * 2ND SHEET - FEEDBACK OF QUALIFYING 
         * WORKORDERS WHOSE SCALE IS <= THRESHOLD VALUE
         *********************************************/
         strSelectStat1 += " and a.wonum in (select distinct z.wonum ";
 	     strSelectStat1 += " from batch_maximo.lbl_wofeedback z ";
 	     strSelectStat1 +="  where z.orgid=" + "'"  + strOrgid +"'";
  	     strSelectStat1 +="  and   z.siteid=" + "'" + strSiteid +"'";
 	     strSelectStat1 += " and   z.value !='n/a' and trim(z.value) !='0' and lpad(z.value,2,'0') <= lpad('" + strMinThreashold + "',2,'0')";
 	     strSelectStat1 += " and z.changedate > to_date(" ;
 	     strSelectStat1 +="'" +strLastDateTime +"',('MM/DD/YYYY HH24:MI:SS')))";
 	     strSelectStat1 +="  and a.orgid=" + "'"  + strOrgid +"'";
   	     strSelectStat1 +="  and a.siteid=" + "'" + strSiteid +"'";
 	     strSort        =" order by  a.wonum, a.customerid, a.id  ";
 	     strSelect      = strSelectStat1 + strSort;
 	     
 	     //System.out.println(strSelect);
         Rs1=myStatement1.executeQuery(strSelect);
    	 intReccount=0;
    	 strPrvWonum="";
    	 
        // Browse through the record set.
        while(Rs1.next()) 			    
        {
          intReccount++;
          if (intReccount==1)
          {
             // Create a new sheet
             sheet2=wb.createSheet("BelowThresholdWOFeedback");
             // Create the header row
             populateHeaderRow(sheet2,
                     row,
                     Rs1,
                     cellWorkorderNumber, 
                     cellWorkorderDescription,
                     cellWorktype,
                     cellReportedby,
                     cellSupervisor,
                     cellCustomer, 
                     cellComments,
                     cellFeedbackCriteria, 
                     cellFeedbackRating,
                     cellFeedbackdate,
                     "BelowThresholdWOFeedback",
                     alphaHeaderStyle,
                     numberHeaderStyle);
         } // if (intReccount==1)
         
              bolPrintComments=false;
              if (! Rs1.getString("wonum").equals(strPrvWonum))
              {
                   strPrvWonum=Rs1.getString("wonum");
                   bolPrintComments=true;
              } 
              // Create the Data Row
              populateDataRow(sheet2,
                      row,
                      Rs1,
                      cellWorkorderNumber, 
                      cellWorkorderDescription,
                      cellSupervisor,
                      cellCustomer, 
                      cellComments,
                      cellFeedbackCriteria, 
                      cellFeedbackRating,
                      intReccount,
                      "ALLWOBelowThresholdWOFeedback",
                      alphaHeaderStyle,
                      numberHeaderStyle,
                      numberRowStyle,
                      numberRowRedStyle,
                      intMinThreshold,
                      bolPrintComments,
                      cellWorktype,
                      cellFeedbackdate );
            } // while(Rs1.next())
            
            // Auto-size the sheet
            if (intReccount >=1 )
            {
             sheet.autoSizeColumn((short) 0);
             sheet.autoSizeColumn((short) 1);
             sheet.autoSizeColumn((short) 2);
             sheet.autoSizeColumn((short) 3);
             sheet.autoSizeColumn((short) 4);
             sheet.autoSizeColumn((short) 5);         
             sheet.autoSizeColumn((short) 6);         
             sheet.autoSizeColumn((short) 7);         
             sheet.autoSizeColumn((short) 8);         
            } 
             
        // Clean up tasks
         Date now = new Date();                
        if (intTotalReccount >= 1)
        {
          wb.write(fileOut);
          
          if (! strApplicationenv.equalsIgnoreCase("PRODUCTION"))
          {
              strSubjectline="[TEST] ";
              strFooter +="<BR><BR><B>[This email is generated from the TEST data and it does not represent the actual data.]</B>";
                               
         
          } // if (! strApplicationenv.equals("PRODUCTION"))
          
          strSubjectline +="Work Order Feedback details file attached";
          Date endDateTime = new Date();           
          
          strBody  ="The attached MS Excel file contains the details of work order feedback responses.\n ";
          strBody +="Data extracted from: " + strLastDateTime + " to: " + df1.format(endDateTime);
          
          //Added this at the request of Heather P.
          String[] strTokens=strWOFeedBackEmailList.split(",");
          for (int i=0;i<strTokens.length;i++)
          {          
            MailUtil.SendMailAttachment("smtp.lbl.gov", "iss-fac@lbl.gov", 
                    strTokens[i], strSubjectline, 
                    strBody, 
                    strFileName);                               
          } // for (int i=0;i<strTokens.length;i++)

          updLBLMaxvars(myConnection,strOrgid, strSiteid,"WOFEEDBACK_EMAIL_SENT_DATE"); 
       }  
         
        
        if (fileOut != null) fileOut.close();
        myConnection.commit();
        if (myConnection != null) myConnection.close();
        
        printWriter.println("Program ended at :" + now);
        System.out.println("Program ended at :" + now);
                
    } // end of main        
        //**************************************************
        // Method to populate the data row in the given
        // sheet and on the given row
        // **************************************************       
        public static void populateDataRow(HSSFSheet sheet,
                          HSSFRow   row,
                          ResultSet Rs1,
                          HSSFCell cellWorkorderNumber, 
                          HSSFCell cellWorkorderDescription,
                          HSSFCell cellSupervisor,
                          HSSFCell cellCustomer, 
                          HSSFCell cellComments,
                          HSSFCell cellFeedbackCriteria, 
                          HSSFCell cellFeedbackRating,
                          int intReccount,
                          String strSheettype,
                          HSSFCellStyle alphaHeaderStyle,
                          HSSFCellStyle numberHeaderStyle,
                          HSSFCellStyle numberRowStyle,
                          HSSFCellStyle numberRowRedStyle,
                          int intMinThreshold,
                          boolean bolPrintComments,
                          HSSFCell cellWorktype,
                          HSSFCell cellFeedbackDate) throws SQLException            
          {
              row=sheet.createRow((short) intReccount); // Data Row
              cellWorkorderNumber=row.createCell((short) 0);
              cellWorkorderNumber.setCellValue(Rs1.getString("wonum"));
          
              cellWorkorderDescription=row.createCell((short) 1);
              cellWorkorderDescription.setCellValue(Rs1.getString("description"));
            
              cellSupervisor=row.createCell((short) 2);
              cellSupervisor.setCellValue(Rs1.getString("supervisor_name"));
          
              cellWorktype=row.createCell((short) 3);
              cellWorktype.setCellValue(Rs1.getString("worktype"));
              
              cellCustomer=row.createCell((short) 4);
              cellCustomer.setCellValue(Rs1.getString("customer_name"));

              cellFeedbackCriteria=row.createCell((short) 5);
              cellFeedbackCriteria.setCellValue(Rs1.getString("feedback_criteria"));
              
              cellFeedbackRating=row.createCell((short) 6);
              cellFeedbackRating.setCellValue(Rs1.getString("scale"));
              cellFeedbackRating.setCellStyle(numberRowStyle);
              
              if (! Rs1.getString("scale").endsWith("n/a") &&
                      java.lang.Integer.parseInt(Rs1.getString("scale")) < intMinThreshold)
                       cellFeedbackRating.setCellStyle(numberRowRedStyle );
              
              cellFeedbackDate=row.createCell((short) 7);
              cellFeedbackDate.setCellValue(Rs1.getString("feedback_date"));
             
              if (bolPrintComments)
              {
                cellComments=row.createCell((short) 8);
                String strWrappedtext=wordwrap(Rs1.getString("submitted_comments"), 40);
                cellComments.setCellValue(strWrappedtext);
              } // if (bolPrintComments)             
          }
            
         // **************************************************
         // Method to populate the header row in the given
        // sheet 
        // **************************************************       
          public static void populateHeaderRow(HSSFSheet sheet,
                          HSSFRow   row,
                          ResultSet Rs1,
                          HSSFCell cellWorkorderNumber, 
                          HSSFCell cellWorkorderDescription,
                          HSSFCell cellWorktype,
                          HSSFCell cellReportedby,
                          HSSFCell cellSupervisor,
                          HSSFCell cellCustomer, 
                          HSSFCell cellComments,
                          HSSFCell cellFeedbackCriteria, 
                          HSSFCell cellFeedbackRating,
                          HSSFCell cellFeedbackdate,
                          String strSheettype,
                          HSSFCellStyle alphaHeaderStyle,
                          HSSFCellStyle numberHeaderStyle)            
          {
                            
              //    Header Row              
              row=sheet.createRow((short) 0); // Header Row
              
              cellWorkorderNumber=row.createCell((short) 0);
              cellWorkorderNumber.setCellValue("Workorder");
              cellWorkorderNumber.setCellStyle(alphaHeaderStyle);
              
              cellWorkorderDescription=row.createCell((short) 1);
              cellWorkorderDescription.setCellValue("Description");
              cellWorkorderDescription.setCellStyle(alphaHeaderStyle);
              
              cellSupervisor=row.createCell((short) 2);
              cellSupervisor.setCellValue("Supervisor");
              cellSupervisor.setCellStyle(alphaHeaderStyle);
             
              cellWorktype=row.createCell((short) 3);
              cellWorktype.setCellValue("Worktype");
              cellWorktype.setCellStyle(alphaHeaderStyle);
                         
              cellCustomer=row.createCell((short) 4);
              cellCustomer.setCellValue("Feedback From");
              cellCustomer.setCellStyle(alphaHeaderStyle);
                          
              cellFeedbackCriteria=row.createCell((short) 5);
              cellFeedbackCriteria.setCellValue("Feedback_Criteria");
              cellFeedbackCriteria.setCellStyle(alphaHeaderStyle);
                             
              cellFeedbackRating=row.createCell((short) 6);
              cellFeedbackRating.setCellValue("Rating");
              cellFeedbackRating.setCellStyle(numberHeaderStyle);
              
              cellFeedbackdate=row.createCell((short) 7);
              cellFeedbackdate.setCellValue("Feedback_Date");
              cellFeedbackdate.setCellStyle(alphaHeaderStyle);
              
              cellComments=row.createCell((short) 8);
              cellComments.setCellValue("Comments");
              cellComments.setCellStyle(alphaHeaderStyle);
            } 
             
                    
     /****************************************************************
     * Method to update the record in lbl_maxvars table to indicate
     * the last date/time stamp when the program was executed
     * @throws SQLException
     ****************************************************************/
    private static void updLBLMaxvars(Connection myConnection, 
    		String strOrgid, String strSiteid, String strVarname) throws SQLException
    {
        String strUpdate=null;
        PreparedStatement pstmt=null;
                		    
        strUpdate  = " update lbl_maxvars ";
        strUpdate +="  set varvalue=to_char(sysdate,'MM/DD/YYYY HH24:MI:SS') ";
        strUpdate +="  where orgid=" + "'"  + strOrgid +"'";
        strUpdate +="  and   siteid=" + "'" + strSiteid +"'";
        strUpdate += " and   varname=? ";
        
        pstmt = myConnection.prepareStatement(strUpdate);
  	    pstmt.setString(1,strVarname);
	    pstmt.executeUpdate();
	    if (pstmt != null) pstmt.close();
	    
      }

    public static String wordwrap(String base, int regex){
        //Prepare variables
    	// Added by Pankaj on 9/29/10
    	//
    	if (base==null || base.length()<=0)
    		 return base;
    	
        String rsm = base;
        boolean gotspace = false;
        boolean gotfeed = false;
        
        //Jump to characters to add line feeds
        int pos = regex;
        while (pos < rsm.length()){
             //Progressivly go backwards until next space
             int bf = pos-regex; //What is the stop point
             gotspace = false;
             gotfeed = false;
             
             //Find space just before to avoid cutting words
             for (int ap=pos; ap>bf; ap--){
                  //Is it a space?
                  if (String.valueOf(rsm.charAt(ap)).equals(" ") == true && gotspace == false){
                       //Insert line feed and compute position variable
                       gotspace=true;
                       pos = ap; //Go to position
                  }
                  //If it is a line feed, go to it
                  else if (String.valueOf(rsm.charAt(ap)).equals("\n") == true && gotfeed == false){
                       pos = ap; //Go to position
                       gotfeed = true;
                  }
             }
             //Got no feed? Append a line feed to the appropriate place
             if (gotfeed == false){
                  if (gotspace == false){rsm = new StringBuffer(rsm).insert(pos, "\n").toString();}
                  else{rsm = new StringBuffer(rsm).insert(pos+1, "\n").toString();}
             }
             //Increment position by regex and restart loop
             pos += (regex+1);
        }
        //Return th result
        return (rsm);
   }

} // class
    


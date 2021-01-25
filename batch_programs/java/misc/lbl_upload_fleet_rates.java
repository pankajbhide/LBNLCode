/***********************************************************
*  
* Program name:  updload_fleet_rates.java 
*  
* Description :  This program reads the data from the data file 
*                which contains the fleet rates for the different
*                vehicle classes.
* 
* 
*                This program assumes the input file be delimted by
*                commas with the following data format:
*             
*                Vehicle class  
*                Asset number                            
*                New Base Rate
*                New Milagte Rate
*                                
* Date Written : 12-SEP-05
*               
* Author       : Pankaj Bhide
* 
* Modification
* History      :
* *****************************************************************/

import java.io.BufferedReader;
import java.io.BufferedWriter;
import java.io.FileNotFoundException;
import java.io.FileReader;
import java.io.FileWriter;
import java.io.IOException;
import java.io.PrintWriter;
import java.sql.Connection;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.Date;
import java.util.StringTokenizer;


public class lbl_upload_fleet_rates
{
    public static void main(String[] args) throws SQLException, NumberFormatException, IOException
    {
        Connection myConnection;
        String strSelectStat1=null, strEqnum=null,strInputLine=null,strAnswer="Z";
        String strClass=null, strClassDesc=null, strInsert=null, strUpdate=null, strAssetnum=null;
  	    ResultSet vehicleRS=null;
  	    double dblCurrentBaseRate=0, dblCurrentMileageCost=0;
  	    double dblOldBaseRate=0,dblNewBaseRate=0,dblOldRate1=0,dblNewRate1=0;
  	    double dblOldMileageRate=0, dblNewMileageRate=0,dblOldRate2=0,dblNewRate2=0;
  	    double dblNewRate3=0;
  	    int intRowsUpdated=0;
  	    Statement myStatement1, myStatement2, myStatement3, myStatement4;
  	    PrintWriter   printWriter = null;
  	    FileWriter fileOutStrm=null;
  	    BufferedWriter bufWriter=null; 
        
        Date now = new Date();   
            
        System.out.println("**********************************************************");
        System.out.println(" Program to upload the fleet rate data and update database");
        System.out.println(" It is recommended to backup equipmentspec table");
    	System.out.println("**********************************************************");
    	System.out.println(" ");
    	
    	System.out.println(" This program assumes the input file delimted by commas with the following data format ");
    	
        System.out.println(" ");             
        System.out.println("Vehicle class");
        System.out.println("Asset number");
        System.out.println("New Base Rate");
        System.out.println("New Milagte Rate");
        //System.out.println("Vehicle class description");
        //System.out.println("Old Base Rate");
        //System.out.println("Old Rate 1");
        //System.out.println("New Rate 1");
        //System.out.println("Old Mileage Rate");
        
        //System.out.println("Old Rate 2");
        //System.out.println("New Rate 2");
        System.out.println(" ");             
        
        while (! strAnswer.equals("Y") && ! strAnswer.equals("N"))
        {
                strAnswer=lbl_console.readLine("Shall we proceed (Y/N): ");
        }
        
        if (strAnswer.equals("N")) System.exit(0);
        
       try 
    	{
    	  // Acquire db connect object
    	 lbl_dbconn dbConn = new lbl_dbconn();

    	  myConnection = dbConn.getConnection();
    	  myConnection.setAutoCommit(false);
    	  
    	  myStatement1 = myConnection.createStatement();
      	  myStatement2 = myConnection.createStatement();
      	  myStatement3 = myConnection.createStatement();
      	  myStatement4 = myConnection.createStatement();
    	}
    	 finally {
    	     
    	 }
    	 
        String strInputFile=lbl_console.readLine("Enter the name of input CSV file(with full path): ");
        int intNumberOfLinesToSkip=lbl_console.readInt("Enter line number to start from: ");                      
        
        FileReader fileInStrm = null;
        try
        {
            fileInStrm = new FileReader(strInputFile);
            
        }
        catch (FileNotFoundException e)
        {
              e.printStackTrace();
        }
        
        // Output file
        try 
        {
            fileOutStrm=new  FileWriter("lbl_upload_fleet_rates.log", false);
            bufWriter  =new  BufferedWriter(fileOutStrm);
            printWriter=new  PrintWriter(bufWriter);
        }
        
           catch (Exception ex)
            {
              System.out.println("IO Exception: " + ex);
            }
           
        System.out.println("Program started at :" + now);
        printWriter.println("Program started at :" + now);
               
        BufferedReader inFile=new BufferedReader(fileInStrm);
        int intNumberofLines=0;
        
        while((strInputLine=inFile.readLine()) != null)
        {
           intNumberofLines++;
           if (intNumberofLines >= intNumberOfLinesToSkip) 
           {
             StringTokenizer strToken = new StringTokenizer(strInputLine,",");
             
             int intTokenNumber=0;
             while (strToken.hasMoreElements())
             {
                 String strTemp=strToken.nextToken();
                 strTemp=strTemp.trim();
                 
                 switch(intTokenNumber)
                 { 
                     case 0:
                         strClass=strTemp.trim();                         
                         break;
                         
                     case 1:
                    	 strAssetnum=strTemp.trim(); strTemp.trim(); 
                         break; // in 2015 Fac changed the format of the file. they specified assetnum ion 2nd field
                     
                     case 2:
                         dblNewBaseRate=Double.parseDouble(strTemp);
                         break;
                     case 3:                       
                         dblNewMileageRate=Double.parseDouble(strTemp);
                          break;
                  } // end of switch
                     intTokenNumber++;        
                } // end of while hasMoreElement for token loop
            
           if (strClass != null && strClass.length() >0)
           {
            //System.out.println("Class: " + strClass);
            //System.out.println("New Base Rate: " + dblNewBaseRate);
            //System.out.println("New Mileage Rate: " + dblNewMileageRate);
            
            strSelectStat1= " select assetnum, base_rate, mileage_cost from maximo.lbl_vehiclespec " ;
 			strSelectStat1=strSelectStat1 + " where assetnum=";
 			strSelectStat1=strSelectStat1 + "'" + strAssetnum + "'"; 
 			strSelectStat1=strSelectStat1 + " order by assetnum";
 			    			   			
 			vehicleRS = myStatement1.executeQuery(strSelectStat1);
 			    			
 			// Browse through the record set
 			while(vehicleRS.next()) 			    
 			{
 			  
 			   dblCurrentBaseRate=vehicleRS.getDouble("base_rate");
			   dblCurrentMileageCost=vehicleRS.getDouble("mileage_cost");
			   
			   // Insert the record with old and new values into lbl_vehratehistory
			   strInsert="insert into batch_maximo.lbl_vehratehistory ";
			   strInsert=strInsert + " (eqnum, vehicle_class, old_base_rate, ";
			   strInsert=strInsert + " old_mileage_cost, base_rate, mileage_cost, changedate, ";
			   strInsert=strInsert + " changeby) values ("; 
			   strInsert=strInsert + "'" + strAssetnum + "' ," + "'" + strClass + "' ,";
			   strInsert=strInsert +  dblCurrentBaseRate + "," + dblCurrentMileageCost + ",";
			   strInsert=strInsert +  dblNewBaseRate + "," + dblNewMileageRate + ",";
			   strInsert=strInsert +  " sysdate, user" + ")" ;
			   myStatement2.executeUpdate(strInsert);
			   
			   // Update equipmentspec table
			   strUpdate="update maximo.assetspec";
			   strUpdate=strUpdate + " set numvalue=" + dblNewBaseRate;
			   strUpdate=strUpdate + " , changedate=sysdate, changeby=user";
			   strUpdate=strUpdate + " where assetnum=" + "'" + strAssetnum + "'";
			   strUpdate=strUpdate + " and assetattrid=" + "'FL-RATE'";
			   myStatement3.executeUpdate(strUpdate);			   
   
			   strUpdate="update maximo.assetspec";
			   strUpdate=strUpdate + " set numvalue=" + dblNewMileageRate;
			   strUpdate=strUpdate + " , changedate=sysdate, changeby=user";
			   strUpdate=strUpdate + " where assetnum=" + "'" + strAssetnum + "'";
			   strUpdate=strUpdate + " and assetattrid=" + "'FL-COST'";
			   myStatement4.executeUpdate(strUpdate);   
			   
			   System.out.println("Updated data for asset: " + strAssetnum + " / Class: " + strClass + " Base Rate: " + dblNewBaseRate + " Mileage Rate: " + dblNewMileageRate );
			   //System.out.println("Updated data for asset: " + strAssetnum + " / Class: " + strClass + " Base Rate: " + dblNewBaseRate + " Mileage Rate: " + dblNewMileageRate );
 			} // while(vehicleRS.next()) 			        
           } //if (strClass != null && strClass.length() >0)
                 
          } // intNumberofLines >= intNumberOfLinesToSkip
        }    
        //Commit all the changes//
         myConnection.commit();

        /* Close resources */
        if (vehicleRS != null)
            vehicleRS .close();             
        if (myStatement1 != null)
            myStatement1.close();
        if (myStatement2 != null)
            myStatement2.close();
        if (myStatement3 != null)
            myStatement3.close();
        if (myStatement4 != null)
            myStatement4.close();
        if (myConnection != null)
            myConnection.close();
        Date now3 = new Date();   
        System.out.println("Program successfully ended at :" + now3);
	    printWriter.println("Program successfully ended at :" + now3);
	    if (printWriter != null)
           printWriter.close();
	    System.exit(0);  
     }
 }

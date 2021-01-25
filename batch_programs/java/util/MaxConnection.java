/***********************************************************
*  
* Program name:  MaxConnection.java
*  
* Description :  Create a connection to the oracle database using 
*                the login/password from max_meta_file
*                
*        		 This program reads the username and password from 
*                max_meta_file and 'JDBC' entry in the file max.env
*                to create the connection string
* 				
*                Should the database name change, this JDBC field need
*                to be updated.
* 
* Date Written : 27-APR-2009
*               
* Author       : Pankaj Bhide
* 
* Modification
* History      :
* *****************************************************************/

package util;

import java.sql.*;
import java.io.*;
import java.util.*;



public class MaxConnection
{
  // Get normal JDBC Connection to MAXIMO database 
  public static Connection getDBConnection() throws IOException, SQLException
  {
    String strFileContent = "";
	String temp;
	Connection myConnection = null;
	//BufferedReader brIn = new BufferedReader(new FileReader(System.getProperty("user.home")+"/max_meta_dir/max_meta_file"));
	
	
	BufferedReader brIn = new 
	                     BufferedReader
	                     (new FileReader("../../../mxes_meta_dir/mxes_meta_file"));
	while((temp = brIn.readLine()) != null)
	{
	 strFileContent += temp;
	}
	brIn.close();
	
	// Process file content with string tokenizer
	StringTokenizer stTokens = new StringTokenizer(strFileContent, "/@");
	String strUsername = stTokens.nextToken().trim();
	String strPassword = stTokens.nextToken().trim();
	String strDatabase = stTokens.nextToken().trim();
	
	// Read the max_fac.env file to find the line JDBC=....
	String strJDBC = "";
	brIn = new BufferedReader(new FileReader("../../../dat/max_fac.env"));
	while((temp = brIn.readLine()) != null)
	{
	 if(temp.indexOf("MAX_JDBC") != -1){
	 //interest in the stuff after the '=' sign
		strJDBC = temp.substring(temp.indexOf("=")+1);
		break;
 	 }
	}
	brIn.close();
	
	/*
	String strUsername= "maximo";
	String strPassword = "allset2g";   
	String strDatabase = "mmo7dev";
	
	String strPhysicalDBName="yamato.lbl.gov";
	
	String strJDBC="jdbc:oracle:thin:@" + strPhysicalDBName +  ":1521:" + strDatabase;
	*/
	
	// Register driver 
	DriverManager.registerDriver(new oracle.jdbc.driver.OracleDriver());
	/*establish connection*/
	myConnection = DriverManager.getConnection(strJDBC, strUsername, strPassword);
	
	return myConnection;
	
   }
  
 // Get normal JDBC Connection to lockshop database 
  public static Connection getLockshopDBConnection() throws IOException, SQLException
  {
    String strFileContent = "";
	String temp;
	Connection myConnection = null;
	
	/*******************************************************
	 * Activate it before moving to unix 
	 * make sure that ../dat/lockshop_meta_file contains
	 * username/password@shrprd
	 * 
	 * Also ../dat/max_fac.env shall contain 
	 * LOCKSHOP_JDBC=jdbc:oracle:thin:@voracious:1621:SHRPRD
	 * ******************************************************* 
	BufferedReader brIn = new 
	                     BufferedReader
	                     (new FileReader("../dat/lockshop_meta_file"));
	while((temp = brIn.readLine()) != null)
	{
	 strFileContent += temp;
	}
	brIn.close();
	
	// Process file content with string tokenizer
	StringTokenizer stTokens = new StringTokenizer(strFileContent, "/@");
	String strUsername = stTokens.nextToken().trim();
	String strPassword = stTokens.nextToken().trim();
	String strDatabase = stTokens.nextToken().trim();
	
	// Read the max_fac.env file to find the line JDBC=....
	String strJDBC = "";
	brIn = new BufferedReader(new FileReader("../dat/max_fac.env"));
	while((temp = brIn.readLine()) != null)
	{
	 if(temp.indexOf("LOCKSHOP_JDBC") != -1){
	 //interest in the stuff after the '=' sign
		strJDBC = temp.substring(temp.indexOf("=")+1);
		break;
 	 }
	}
	brIn.close();
	
	*/ 
	// Register driver 
	DriverManager.registerDriver(new oracle.jdbc.driver.OracleDriver());
	
	String strUsername= "lockadm";
	String strPassword = "lock12345";   
	String strDatabase = "shrdev";
	
	String strPhysicalDBName="luther.lbl.gov";
	
	String strJDBC="jdbc:oracle:thin:@" + strPhysicalDBName +  ":1621:" + strDatabase;
	
		
	myConnection = DriverManager.getConnection(strJDBC, strUsername, strPassword);
	
	return myConnection;
	
   } 
  
  
}
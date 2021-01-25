/***********************************************************
*  
* Program name:  MXServerConnection.java
*  
* Description :  Create a connection to the oracle database and 
*                to the MXServer depending upon the configuration
*                files.
* 
* Date Written : 24-OCT-2009	
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

import psdi.util.MXException;
import psdi.util.MXSession;

public class MXServerConnection
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
	                     (new FileReader("../dat/mxes_meta_file"));
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
	 if(temp.indexOf("MAX_JDBC") != -1){
	 //interest in the stuff after the '=' sign
		strJDBC = temp.substring(temp.indexOf("=")+1);
		break;
 	 }
	}
	brIn.close();
	
	
	// Register driver 
	DriverManager.registerDriver(new oracle.jdbc.driver.OracleDriver());
	/*establish connection*/
	myConnection = DriverManager.getConnection(strJDBC, strUsername, strPassword);
	
	return myConnection;
	
   }
//Get MXSession connection for MXServer for MBOs
  public static MXSession getMXSession() throws MXException, IOException
  {
	    
	String temp;
	BufferedReader brIn = new 	BufferedReader
	          (new FileReader("../dat/max_fac.env"));
		String strHostname="";
		String strMXServer="";
		String strUsername="";
		String strPassword="";
		
	while((temp = brIn.readLine()) != null)
	 {
		 if(temp.indexOf("MXES_HOSTNAME") != -1)
		  //interest in the stuff after the '=' sign
		  strHostname= temp.substring(temp.indexOf("=")+1);
		 
		 if(temp.indexOf("MXES_MXSERVERNAME") != -1)
			  //interest in the stuff after the '=' sign
			  strMXServer= temp.substring(temp.indexOf("=")+1);
		 if(temp.indexOf("MXES_MEA_USER") != -1)
			  //interest in the stuff after the '=' sign
		 	strUsername = temp.substring(temp.indexOf("=")+1);
					
	 	 if(temp.indexOf("MXES_MEA_PASSWORD") != -1)
		  //interest in the stuff after the '=' sign
	  	  strPassword = temp.substring(temp.indexOf("=")+1);	
	 }
	 System.out.println("Host: " + strHostname );
	 System.out.println("MXServer: " + strMXServer );
	 System.out.println("User: " + strUsername );
	 System.out.println("Password: " + strPassword );
	 
	 MXSession s = null;
     s = MXSession.getSession(); // get a session from MXServer

	 s.setHost(strHostname+ "/" +strMXServer);
	 s.setUserName(strUsername);
	 s.setPassword(strPassword);  
	            
	 s.connect(); // establish connection
	
	 System.out.println("Success. Connected to MXServer");
	 return s;	
   } // end of function 
	
//Get normal JDBC Connection to MAXIMO database 
  public static Connection getLockshopDBConnection() throws IOException, SQLException
  {
    String strFileContent = "";
	String temp;
	Connection myConnection = null;
	//BufferedReader brIn = new BufferedReader(new FileReader(System.getProperty("user.home")+"/max_meta_dir/max_meta_file"));
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
	
	
	// Register driver 
	DriverManager.registerDriver(new oracle.jdbc.driver.OracleDriver());
	/*establish connection*/
	//System.out.println("JDBC: " + strJDBC);
	//System.out.println("User: " + strUsername);
	//System.out.println("Password: " + strPassword);
	
	myConnection = DriverManager.getConnection(strJDBC, strUsername, strPassword);
	
	return myConnection;
	
   }
}
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


public class MaxConnection2
{
  // Get normal JDBC Connection to MAXIMO database 
  public static Connection getDBConnection() throws IOException, SQLException
  {
    String strFileContent = "";
	String temp;
	Connection myConnection = null;
	//BufferedReader brIn = new BufferedReader(new FileReader(System.getProperty("user.home")+"/max_meta_dir/max_meta_file"));
	/*BufferedReader brIn = new 
	                     BufferedReader
	                     (new FileReader("../../../mxes_meta_dir/mxes_meta_file"));
	while((temp = brIn.readLine()) != null)
	{
	 strFileContent += temp;
	}
	brIn.close();
	
	// Process file content with string tokenizer
	StringTokenizer stTokens = new StringTokenizer(strFileContent, "/@"); */
	
	String strUsername= "maximo";
	String strPassword = "allset2g";   
	String strDatabase = "mmodev";
	
	String strPhysicalDBName="luther";
	
	String strJDBC="jdbc:oracle:thin:@" + strPhysicalDBName +  ":1521:" + strDatabase;
	

	// Register driver 
	DriverManager.registerDriver(new oracle.jdbc.driver.OracleDriver());
	/*establish connection*/
	myConnection = DriverManager.getConnection(strJDBC, strUsername, strPassword);

	
	return myConnection;
	
   }
}
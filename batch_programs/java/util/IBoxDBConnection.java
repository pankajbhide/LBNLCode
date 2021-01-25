/***********************************************************
*  
* Program name:  IBoxDBConnection.java
*  
* Description :  Create a connection to the oracle database using 
*                the login/password from ibox_meta_dir/ibox_meta_file
*                
*        		 This program reads the username and password from 
*                ibox_meta_file and 'JDBC' entry in the file max.env
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

public class IBoxDBConnection
{
  Connection myConnection = null;
	
  public IBoxDBConnection() throws IOException, SQLException
  {

  	
    String strFileContent = "";
	String temp;
	//BufferedReader brIn = new BufferedReader(new FileReader(System.getProperty("user.home")+"/max_meta_dir/max_meta_file"));
	BufferedReader brIn = new 
	                     BufferedReader
	                     (new FileReader("../../../ibox_meta_dir/ibox_meta_file"));
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
	
	// Read the max.env file to find the line JDBC=....
	String strJDBC = "";
	brIn = new BufferedReader(new FileReader("../../../dat/max_fac.env"));
	while((temp = brIn.readLine()) != null)
	{
	 if(temp.indexOf("IBOX_JDBC") != -1){
	 //interest in the stuff after the '=' sign
		strJDBC = temp.substring(temp.indexOf("=")+1);
		break;
 	 }
	}
	brIn.close();
	
  	/*String strUsername ="intrasysadmin"; 
  	String strPassword = "ib0x$dev";
  	String strDatabase = "iboxdev";
  	String strPhysicalDBName="luther";
  	
  	String strJDBC="jdbc:oracle:thin:@" + strPhysicalDBName +  ":1621:" + strDatabase;
  	*/
  	
	// Register driver 
	DriverManager.registerDriver(new oracle.jdbc.driver.OracleDriver());
	/*establish connection*/
	myConnection = DriverManager.getConnection(strJDBC, strUsername, strPassword);
   }
	public Connection getConnection(){
		return myConnection;
	}
}
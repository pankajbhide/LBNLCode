import java.sql.*;

public class lbl_dbconn
{
   
    	Connection myConnection = null;
    	// Constructor
     	
    	public lbl_dbconn() throws SQLException
    	{
    	        String strUsername = "maximo";
    	       //String strPassword = "allset2g";
      		   //String strDatabase = "mmodev";
      		   //String strPhysicalDBName="luther.lbl.gov";
    		 	String strPassword = "allset7q";
    		    String strDatabase = "mmo7qa";
    		  String strPhysicalDBName="tinker.lbl.gov";
    		 //String strPassword = "balaji12";
    		  // String strDatabase = "mmoprd";
    		  //String strPhysicalDBName="voracious.lbl.gov";   			
    			/* Register driver */
    			DriverManager.registerDriver(new oracle.jdbc.driver.OracleDriver());
    			/*establish connection*/
    			myConnection = DriverManager.getConnection(
		        "jdbc:oracle:thin:@" + strPhysicalDBName + 
		        ":1521:" + strDatabase, strUsername, strPassword);	
    	}
    	public Connection getConnection(){
    		return myConnection;
    	}	
    }

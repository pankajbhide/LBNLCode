/*************************************************************************  
* Program name: ILblWriteUPD.java
* 
* Description : The static method writeLogger the command as
*                     argument. This command is separated by | and
*                     it should contain follwing elements (order is important)
*                     1) Server name e.g. syslog.lbl.gov
*                     2) Port# - 514
*                     3) Actual message that starts with number denoting
*                         FacilityLevel
* 
* 				 
* Date Written : July 5, 2011
*               
* Author       : Pankaj Bhide
* 
* Modification
* History      :  Reviewd by Jermey Peace(JP)
* *****************************************************************/
import java.net.DatagramPacket;
import java.net.DatagramSocket;
import java.net.InetAddress;
import java.util.StringTokenizer;

public class LblWriteUDP {


	public static void  writeLogger(String strCommand)

  {
    String strServername = "";
    String strLoggingInfo = "";
    int intPort = 0;
    StringTokenizer st;
    DatagramSocket clientSocket = null;
  
  	try
  	{
		// Tokenize string strCommand, based on "|"...

		// strCommand should be in this format: ServerName|ServerPort|FacilityLevel
  		st = new StringTokenizer(strCommand, "|");
  		
  		int i=0;  // set i to zero to iterate over tokens...
  		
  		while (st.hasMoreElements()) 

  		{
  		    String token = st.nextToken();
  		  	  
  		    if (i==0) strServername=token;
   		    if (i==1) intPort=Integer.parseInt(token);
   		    if (i==2) strLoggingInfo=token;
   		    i++;

  		} // end of while 

  	  	// Get the IP address of the server
      	InetAddress IPAddress = InetAddress.getByName(strServername);

       		// Create a datagram socket
    		clientSocket = new DatagramSocket();

  	  	// Convert logging string to array of bytes
     		byte[] theByteArray = strLoggingInfo.getBytes();

     		//Create DatagramSocket on specified port number
  		DatagramPacket sendPacket =  new DatagramPacket(theByteArray, 
  				                                            theByteArray.length, IPAddress, intPort);

  	                                
        // send UDP message...
    		clientSocket.send(sendPacket);

  	}  // end of try

    	catch (Exception e) {
   	  	e.fillInStackTrace(); // will only write error to console/stack, no notification generated...

    	}
    	finally
    	{	
    		// close all open objects...
    		if (clientSocket != null) 
	  	  		clientSocket.close();
  		
    	} // end of finally 
 
  } // end of method 
  

	// JP main never will be called...
	// Kept for quick testing
	//public static void main(String[] args) {
	//  writeLogger("istools.lbl.gov|514|<45>Test message. please ignore"); 
 //		}
	
}  // end of class 
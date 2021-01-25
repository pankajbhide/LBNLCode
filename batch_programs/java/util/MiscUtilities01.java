package util;

import java.io.BufferedReader;
import java.io.FileNotFoundException;
import java.io.FileReader;
import java.io.IOException;

public class MiscUtilities01
{
   public static String getConfigValue(String strConfigParam) throws IOException
   {
	 // Read the max_fac.env file and look for the parameter
	  String temp;
	  String strReturnvalue="";
		
	   //BufferedReader brIn = new BufferedReader(new FileReader("../../../dat/max_fac.env"));
	  
	   // Changed by Pankaj on 3/19/2010
	   // This program will launched from appserver:/apps/mxes/bears/bea9/user_projects/
	   // domains/MXServer/servers/mmo6prd/lbl_batch_programs/bin
	   // The environment file resides on ../dat directory	   

	   BufferedReader brIn = new BufferedReader(new FileReader("../dat/max_fac.env"));
		while((temp = brIn.readLine()) != null)
		{
		 if(temp.indexOf(strConfigParam) != -1){
		 //interest in the stuff after the '=' sign
			 strReturnvalue= temp.substring(temp.indexOf("=")+1);		
			 break;
		  }
		 }
		 if (brIn !=null) brIn.close();
 		 return strReturnvalue;
	 
   }
}

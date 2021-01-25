package lbl;

import java.util.*;
   
public class lbl_Pet2Mx_Rec{
		public String strPump, strReadingDate1, strReadingDate2;		
		public double dReadingNew, dReadingOld, dVeederNew, dVeederOld;
		public lbl_Pet2Mx_Rec(String strPump, String strReadingNew, String strReadingOld, String strVeederNew, String strVeederOld, String strReadingDate1, String strReadingDate2){
			this.strPump = strPump;
			this.dReadingNew = new Double(strReadingNew).doubleValue();
			this.dReadingOld = new Double(strReadingOld).doubleValue();
			this.dVeederNew = new Double(strVeederNew).doubleValue();
			this.dVeederOld = new Double(strVeederOld).doubleValue();			
			this.strReadingDate1 = strReadingDate1;
			this.strReadingDate2 = strReadingDate2;
	 	}
		public lbl_Pet2Mx_Rec(String strUnparsed){			
			StringTokenizer stTokens = new StringTokenizer(strUnparsed, ",");			
			strPump = stTokens.nextToken();
			dReadingNew = new Double(stTokens.nextToken()).doubleValue();
			dReadingOld = new Double(stTokens.nextToken()).doubleValue();
			dVeederNew = new Double(stTokens.nextToken()).doubleValue();
			dVeederOld = new Double(stTokens.nextToken()).doubleValue();
			strReadingDate1 = stTokens.nextToken();
		}
		public String toString(){
			String strReturn = "Pump: " + strPump + "\n";
			strReturn += "New reading: " + dReadingNew + "\n";
			strReturn += "Old reading " + dReadingOld + "\n";
			strReturn += "New veeder reading: " + dVeederNew + "\n";
			strReturn += "Old veeder reading: " + dVeederOld + "\n";
			strReturn += "ReadingDate1: " + strReadingDate1 + "\n";
			strReturn += "ReadingDate2: " + strReadingDate2 + "\n";			
			return strReturn;
		}
	}
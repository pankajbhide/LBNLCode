package lbl;

/***********************************************************************
 *  Modification History: Pankaj Bhide   01/09/07
 * 
 *                        Replaced product code 01-Diesel/02-Unleaded
 *                        
 *                        01/12/10 - Getter/setter methods for assetnumber
 *                      
 * 
 ********************************************************************/
public class PetroVendTrans{
		public String strDate, strTime, strTransNum, strAcctNum, strDriver, strVeh, strMilage, strKeyboard, strPump, strProduct, strSiteNum;
		double dQuantity, dPrice, dTotal;
		
         public String strAssetnum; // added by Pankaj 1/11/10
         public void setAssetnum(String strAssetnum1)
         {
        	 this.strAssetnum=strAssetnum1;
         }
         
         public String getAssetnum()
         {
        	 return this.strAssetnum;
         }
         
		public PetroVendTrans(String str){			
			strDate = str.substring(0, 6);
			strTime = str.substring(6, 10);
			strTransNum = str.substring(10, 14);
			strAcctNum = str.substring(14, 18);
			strDriver = str.substring(18, 22);
			strVeh = str.substring(22, 26);
			strMilage = str.substring(26, 32);
			strKeyboard = str.substring(32, 42);
			strPump = str.substring(42, 44);
			strProduct = str.substring(44, 46);
			dQuantity = new Double(str.substring(46, 51) + "." + str.substring(51, 54)).doubleValue();
			dPrice = new Double(str.substring(54, 55) + "." + str.substring(55, 58)).doubleValue();			
			dTotal = new Double(str.substring(58, 62) + "." + str.substring(62, 64)).doubleValue();
			strSiteNum = str.substring(64, 66);		
		}
		public String toString(){
			String strReturn = "Date: " + strDate + "\n";
			strReturn += "Time: " + strTime + "\n";
			strReturn += "TransNum: " + strTransNum + "\n";
			strReturn += "AcctNum: " + strAcctNum + "\n";
			strReturn += "Driver: " + strDriver + "\n";
			strReturn += "Vehicle: " + strVeh + "\n";
			strReturn += "Milage: " + strMilage + "\n";
			strReturn += "Keyboard: " + strKeyboard + "\n";
			strReturn += "Pump: " + strPump + "\n";
			strReturn += "Product: " + strProduct + "\n";
			strReturn += "Quantity: " + dQuantity + "\n";
			strReturn += "Price: " + dPrice + "\n";
			strReturn += "Total: " + dTotal + "\n";
			strReturn += "SiteNum: " + strSiteNum + "\n";
			return strReturn;
		}
		public String DecodeProduct(){
			String strDecodeProd = "";
			if(strProduct.equals("01")){
				//strDecodeProd = "UNLEADED";
			    strDecodeProd = "DIESEL"; // Pankaj 01/09/07
			    
			}else if(strProduct.equals("02")){
				// strDecodeProd = "DIESEL";
			    strDecodeProd="UNLEADED"; // Pankaj 01/09/07
			    
			}else if(strProduct.equals("03")){
				strDecodeProd = "ETHANOL";
			}else{
				strDecodeProd = "UNRECOGNIZED";
			}
			return strDecodeProd;
		}
		public String toHTMLString(){
			String strMessage = "";
			String chrDblquote = "\"";
			
	        strMessage += "<TD>" + strDate.substring(0, 2) + "/" + strDate.substring(2, 4) + "/" + strDate.substring(4, 6) + " " +strTime.substring(0,2)+ "/" + strTime.substring(2, 4) + "</TD>";        
	        strMessage += "<TD>" + strDriver + "</TD>";
	        strMessage += "<TD>" + strMilage + "</TD>";	        
	        //strMessage += "<TD>" + strPump + "</TD>";
	        // Replaced pump with vehicle license # 
	        strMessage += "<TD>" + strAssetnum + "</TD>";
	        strMessage += "<TD>" + DecodeProduct() + "</TD>";
	        strMessage += "<TD align=\"right\">" + dQuantity + "</TD>";        
	           			
			return strMessage;
		}	
		
	}				
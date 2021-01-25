package lbl;

import java.sql.*;

import java.io.*;
 
public class PetroVend2MaxUtil{
	public String GetMaxVar(String strVarName, Statement stmt) throws SQLException{
		String strReturnValue = "";
		try{
		//ResultSet rs = stmt.executeQuery("select varvalue from batch_maximo.lbl_maxvars where varname = '" + strVarName + "' and ORGID = 'LBNL' and SITEID = 'FAC'");
	    ResultSet rs = stmt.executeQuery("select varvalue from maximo.lbl_maxvars where varname = '" + strVarName + "' and ORGID = 'LBNL' and SITEID = 'FAC'");
		if(rs.next()){
			strReturnValue = rs.getString("varvalue");
		}
		if(rs!=null){rs.close();}			
		return strReturnValue;
		}catch(SQLException ex){
			throw ex;
		}
	}
	public String GetConfigVar(String strVarName, String strFileName){
		try{
			BufferedReader br = new BufferedReader(new FileReader(strFileName));
			String strTemp = "", strReturnVal="";
			while((strTemp = br.readLine()) != null){
				if(strTemp.indexOf(strVarName) > -1){					
					strReturnVal = strTemp.substring(strTemp.indexOf("=")+1).trim();
					break;
				}
			}
			if(br!=null){br.close();}
			return strReturnVal;
		}catch(IOException ex){
			System.out.println("Error occurs while reading " + strVarName + ".");
			ex.printStackTrace();
		}
		return "";
	}
}
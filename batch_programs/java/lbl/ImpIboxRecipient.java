package lbl;

/***********************************************************
*  
* Program name: ImpIboxRecipient.java
* 
* Description : This program performs following :
* 
* 				If "load_locationspec_data" is passed in as the 
*               third argument, this program load the "route"
* 	            information from iBox to Maximo.LocationSpec table.
* 
*               Regardless of what the argument is, it will iterate 
*               through the list of the employees in Maximo and 
*               update the correspondent information in iBox. 
* 
* Date Written : July 5, 2007
*               
* Author       : Pankaj Bhide
* 
* Modification
* History      : August 25, 2007, the program will now update name,
*                status location for every employee. 
*                
*                April 29, 2009  - Pankaj- Changes for MXES
*                
*                Sept 05, 2012 - Pankaj - Get Rotue from locationspec table using
*                packaged function. There would only be routes for building. All 
*                the rooms in the building will inherit the routes.
* **********************************************************************************/

import java.io.*;
import java.sql.*;
import util.IBoxDBConnection;
import util.MaxConnection;

public class ImpIboxRecipient{
	public static void main(String args[]){
		String strLogFile = "impiboxrecipient.log";
		
		String strOrgid, strSiteid;
		
		FileWriter fwLog = null;
		BufferedWriter bwLog = null;
						
		Connection connMaximo = null;
		Connection connIBox = null;
		PreparedStatement pstMaximo = null;
		PreparedStatement pstIBox = null;
		
		try{
			fwLog = new FileWriter(strLogFile);
			bwLog = new BufferedWriter(fwLog);			
			//bwLog.write("Program iBox mapping starts.\n");
			System.out.print("Program iBox mapping starts.\n");
			
			// Preparing a connection to Maximo
			//bwLog.write("Establishing connection to Maximo.\n");
			System.out.print("Establishing connection to Maximo.\n");
			
			connMaximo = MaxConnection.getDBConnection();
			if(connMaximo != null)
			{
				connMaximo.setAutoCommit(false);				
			}
			else
			{
				//bwLog.write("Failed to establish connection to Maximo.\n");
				System.out.print("Failed to establish connection to Maximo.\n");
			}
			
			// Preparing a connection to IBox
			//bwLog.write("Establishing connection to iBox.\n");
			System.out.print("Establishing connection to iBox.\n");
			connIBox = new IBoxDBConnection().getConnection();
			if(connIBox != null)
			{
				connIBox.setAutoCommit(false);				
			}
			else
			{
				//bwLog.write("Failed to establish connection to iBox.\n");
				System.out.print("Failed to establish connection to iBox.\n");				
			 }
			
			// Parse the command line arguments 
			
		    if (args.length >1)
		    {
		      strOrgid=args[0].trim();
		      strSiteid=args[1].trim();
		    }else
		    {
		    	strOrgid="LBNL";
		    	strSiteid="FAC";
		    } 
		   
		  if (args.length >2 )
		  {
			if(args[2] != null && args[2].length() > 1)
			{
			 if(args[2].equalsIgnoreCase("load_locationspec_data"))
			 {
				//bwLog.write("Loading route info from iBox to Maximo.locationspec table.\n");
				System.out.print("Loading route info from iBox to Maximo.locationspec table.\n");
				long lTotalRecord = loadLocationSpecData(connMaximo, connIBox,
						                                 strOrgid, strSiteid,bwLog);				
			 }					
			}
		   }	
			//bwLog.write("Updating employee and location info from Maximo to iBox recipient table.\n");
			System.out.print("Updating employee and location info from Maximo to iBox recipient table.\n");	
			loadRecipientInfo(connMaximo, connIBox, bwLog);
						
			connIBox.commit();
			//bwLog.write("Commit changes in iBox.\n");
			System.out.print("Commit changes in iBox.\n");
			connMaximo.commit();
			//bwLog.write("Commit changes in Maximo.\n");
			System.out.print("Commit changes in Maximo.\n");
			
			//bwLog.write("Program iBox mapping exits successfully.\n");
			System.out.print("Program iBox mapping exits successfully.\n");	
			if(connMaximo!=null)
				connMaximo.close();
			if(connIBox!=null)
				connIBox.close();
			if(bwLog!=null)
				bwLog.close();
			if(fwLog!=null)
				fwLog.close();
		}catch(Exception e){
			e.printStackTrace();			
		}
	}
	
  /*****************************************************************
   Method to Iterate through the list of location in iBox and 
   load the route information from iBox to Maximo locationspec table.
   *******************************************************************/
   public static long loadLocationSpecData(Connection connMax, 
           Connection connIBox,
           String strOrgid,
           String strSiteid,
           BufferedWriter bwLog)
      throws SQLException, IOException
      {
     
       String strClassstructureid=null;  
       String strMaxQuery3 = " select distinct  classstructureid from maximo.classstructure ";
       strMaxQuery3 +=" where upper(description) like '%LOCATIONS%' ";
       bwLog.write(strMaxQuery3);
       PreparedStatement psMax3=connMax.prepareCall(strMaxQuery3);
       ResultSet rsMax3 = null;
       rsMax3 = psMax3.executeQuery();
       while(rsMax3.next())
	   {
		strClassstructureid=rsMax3.getString(1);
	   }
     if (rsMax3 != null) rsMax3.close();
       
	String strIBoxQuery  =" select recipvar1 route, ";
	       strIBoxQuery +=" recipvar2 || '-' || recipvar3 location ";
	       strIBoxQuery +=" from recipient where status='Available' ";
	       
	       String strMaxQuery =" select alnvalue from maximo.locationspec ";
	       strMaxQuery       +=" where assetattrid = 'IB-ROUTE' ";  
	       strMaxQuery       +=" and location = ? and siteid = " + "'" + strSiteid +"'";
	       strMaxQuery       +=" and orgid = " + "'" + strOrgid + "'";
	       
	              
	        String strMaxQuery2  =" select location from maximo.locations ";
	              strMaxQuery2 +=" where location=? and  siteid = " + "'" + strSiteid +"'";
	              strMaxQuery2 +=" and orgid = " + "'" + strOrgid + "'";
	       	       
	              
		PreparedStatement psIBox = connIBox.prepareCall(strIBoxQuery);
		PreparedStatement psMax = connMax.prepareCall(strMaxQuery);
		PreparedStatement psMax2 = connMax.prepareCall(strMaxQuery2);
		PreparedStatement pstmt=null;
		
		Statement stMax = connMax.createStatement();
		
		ResultSet rsIBox = null;
		ResultSet rsMax = null;
		ResultSet rsMax2 = null;
		
		long lCounter = 0, lTotalFail = 0;
		if(psIBox != null)
		{
	    	rsIBox = psIBox.executeQuery();
				
			if(rsIBox != null)
			{				
		      String strLocation = null;
			  System.out.println("Processing...");
			  while(rsIBox.next())
			  {
				 strLocation = rsIBox.getString("location").trim();
				 psMax.setString(1, strLocation);
				 rsMax = psMax.executeQuery();
			    if(!rsMax.next()) // Record does not exist
			    {	
				  // Find out whether it is a valid location  
				 psMax2.setString(1,strLocation);
				
				 rsMax2=psMax2.executeQuery();
				 if (rsMax2.next())
				 {
				   
				    // Insert route into Maximo location specification
					String strInsert = "insert into maximo.locationspec ";
					       strInsert +=" (location, assetattrid, classstructureid, ";
					       strInsert +="  inheritedfromitem, itemspecvalchanged, " ;
					       strInsert +="  displaysequence, alnvalue, changedate, " ;
					       strInsert +="  changeby, orgid, siteid, locationspecid) ";						
						   strInsert +="  values ('" + strLocation + "', 'IB-ROUTE', ";
						   strInsert +="  '" + strClassstructureid + "'" + ", '0', " ;
						   strInsert +="  '0', 1, '" + rsIBox.getString("route") + "', SYSDATE,";
						   strInsert +="  'MAXIMO', " + "'" + strOrgid + "'," +" '" + strSiteid +"'";
						   strInsert +=" ,locationspecseq.nextval )";
						// System.out.println(strInsert);
						/*** need to take this out later*/
						/*** Hint: Some building-location in iBox are too long 
						 *   for Maximo to handle */
						if(strLocation.length() <= 10)
						{
						  stMax.executeUpdate(strInsert);
						  
						  
						  String strUpdate=" update maximo.locations ";
						  strUpdate  +=" set classstructureid=?  where location=? ";
						  strUpdate  +=" and orgid=" + "'" + strOrgid +"'";
						  strUpdate  +=" and siteid=" + "'" + strSiteid +"'";
						  pstmt = connMax.prepareStatement(strUpdate);
					  	  pstmt.setString(1,strClassstructureid);
					  	  pstmt.setString(2,strLocation);
						  pstmt.executeUpdate();
						  pstmt.close();
						  
						  lCounter++;
						} // if(strLocation.length() <= 10)
						else
						{
							lTotalFail++;
						} // if(strLocation.length() <= 10)
				     } // if ( rsMax2.next())
				     rsMax2.close();
					} // if(!rsMax.next())					
				} // while(rsIBox.next())
				//bwLog.write("Total record loaded into MAXIMO.LOCATIONSPEC: " + lCounter+ "\n");
				System.out.print("Total record loaded into MAXIMO.LOCATIONSPEC: " + lCounter + "\n");
				//bwLog.write("Total location records rejected when loading to MAXIMO.LOCATIONSPEC because of Location field length limitation: " + lTotalFail + "\n");
				System.out.print("Total location records rejected when loading to MAXIMO.LOCATIONSPEC because of Location field length limitation: " + lTotalFail + "\n");
				
				rsIBox.close();
				stMax.close();
				psMax.close();
				psIBox.close();				
			}	// if(rsIBox != null)		
		}	//if(psIBox != null)
		return lCounter;
	}
	/**	 * 
	 * 
	 * 1. Read records from Maximo.labor table
	 * 2. Check if record exists in recipient in iBox
	 * 3. If not
	 * 		3.1 Must be new employee, check if the location assigned to him/her exists in iBox (labor.worklocation != null and recipient.dynamic = 0)
	 * 			3.1.1 If location exist, INSERT employee record into iBox recipient table
	 * 			3.1.2 If location does not exist, INSERT employee record and location record into iBox recipient table
	 * 4. If record exists
	 * 		4.1 Check if employee has left LBNL (labor.la3 <> 'A')
	 * 			4.1.1	If employee has left LBNL, set recipient.status = 'Deleted'
	 * 			4.1.2	If employee has NOT left LBNL, check if his/her office has been changed (labor.worklocation = recipvar2-recipvar3?)
	 * 				4.1.2.1 If location is not changed, check other columns
	 * 				4.1.2.2	Check if work location of the employee exists in iBox (recipvar2 = building? and recipvar3 = room and recipient.dynamic = 0)
	 * 					4.1.2.2.1	If yes, check other columns
	 * 					4.1.2.2.2	If no, insert location record into iBox recipient table (dynamic = 0)	
	 */
	public static void loadRecipientInfo(Connection connMax, Connection connIBox, BufferedWriter bwLog) throws SQLException, IOException{
	    
	    String strIStatus="", strIUpdate="";
    	String strMaxQuery="select lab.laborcode, replace(person.displayname,'''', '''''') name, ";
    // Commented by Pankaj on 9/5/12	
    //	strMaxQuery +=" nvl(locspec.alnvalue,'N/A') alnvalue,"; 
   		strMaxQuery +=" loc.lo1 buildingnum, loc.lo3 roomnum, "; 
   		strMaxQuery +=" loc.description, ";  
   		strMaxQuery +=" person.droppoint, ";   
   		strMaxQuery +="	phone.phonenum, ";  
   		strMaxQuery +=" laborcraftrate.craft, ";  
   		strMaxQuery +=" email.emailaddress, ";  
   		strMaxQuery +="	person.location worklocation, ";  
		  strMaxQuery +=" decode(nvl(lab.la3,'A'),'T','T','A') status, ";     
	  	strMaxQuery +="  lbl_maximo_pkg.get_route(loc.location) alnvalue";
	  	strMaxQuery +=" from maximo.locations loc,  maximo.labor lab, ";
	  	strMaxQuery +=" maximo.person person, email email, phone, laborcraftrate ";  
	  	strMaxQuery +=" where email.personid=person.personid ";  
	  	strMaxQuery +=" and   email.type='WORK' ";   
		  strMaxQuery +=" and   email.isprimary='1' ";  
		  strMaxQuery +=" and   phone.personid=person.personid ";  
		  strMaxQuery +=" and   phone.type='WORK' ";  
		  strMaxQuery +=" and   phone.isprimary='1' ";  
		  strMaxQuery +=" and   laborcraftrate.laborcode=person.personid ";  
		 strMaxQuery +=" and   laborcraftrate.orgid=lab.orgid ";  
		  strMaxQuery +=" and   laborcraftrate.defaultcraft='1' ";  
		  strMaxQuery +=" and  loc.location = person.location ";  
		  strMaxQuery +=" and loc.orgid = lab.orgid ";     		
		  strMaxQuery +=" and person.personid=lab.laborcode  ";  
	   	   
		  
	    PreparedStatement psMax = connMax.prepareStatement(strMaxQuery);
		
		boolean bolEmployeeExists=false, bolLocationExists=false;
		
		String strIBoxQuery = "select r.empid, r.name," ;
		strIBoxQuery += " nvl(r.recipvar1,'N/A')  recipvar1, "; 
		strIBoxQuery += " nvl(r.recipvar2,'N/A')  recipvar2, "; 
		strIBoxQuery += " nvl(r.recipvar3,'N/A')  recipvar3, "; 
		strIBoxQuery += " nvl(r.recipvar4,'N/A')  recipvar4, "; 
		strIBoxQuery += " nvl(r.recipvar5,'N/A')  recipvar5, ";
		strIBoxQuery += " nvl(r.recipvar6,'N/A')  recipvar6, "; 
		strIBoxQuery += " nvl(r.recipvar7,'N/A')  recipvar7, "; 
		strIBoxQuery += " nvl(r.recipvar10,'N/A') recipvar10, "; 
	    strIBoxQuery += "r.download, r.dynamic, r.profileid, nvl(r.status,'Available') status ";
		strIBoxQuery += "from recipient r ";		
		
		//String strIBoxQueryEmp = strIBoxQuery + "where r.empid = ? and r.dynamic = 1";
		String strIBoxQueryEmp = strIBoxQuery + "where r.empid = ? ";
		String strIBoxQueryLoc = strIBoxQuery + "where r.empid = ? ";
						
		String strIBoxInsertLoc = "insert into recipient ";
		strIBoxInsertLoc += "(empid, name, recipvar1, recipvar2, recipvar3, recipvar7, download, dynamic, profileid, status, lastmodified) values ";
		strIBoxInsertLoc += " (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, sysdate)";
		
		String strIBoxInsertEmp = "insert into recipient ";
		strIBoxInsertEmp += "(empid, name, recipvar1, recipvar2, recipvar3, recipvar4, recipvar5, recipvar6, recipvar10, download, dynamic, profileid, status, lastmodified) values ";
		strIBoxInsertEmp += " (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, sysdate)";
							
		PreparedStatement psIBoxEmp = connIBox.prepareStatement(strIBoxQueryEmp);
		PreparedStatement psIBoxLoc = connIBox.prepareStatement(strIBoxQueryLoc);
		PreparedStatement psIBoxInsertLoc = connIBox.prepareStatement(strIBoxInsertLoc);
		PreparedStatement psIBoxInsertEmp = connIBox.prepareStatement(strIBoxInsertEmp);
		Statement stIBoxTemp = connIBox.createStatement();
		
		ResultSet rsMax = psMax.executeQuery();
		//bwLog.write("Gather list of employees in Maximo to sync with iBox.\n");
		System.out.print("Gather list of employees in Maximo to sync with iBox.\n");
		
		ResultSet rsIBoxEmp = null, rsIBoxLoc = null;
		String strEmpID = "", strWorkLoc = "", strBuildingNum="", strRoomNum = "";
		long lTotalRecordUpdate = 0, lTotalRecordInsertLoc = 0, lTotalRecordInsertEmp = 0;
		
		if(rsMax!=null)
		{
			System.out.println("Processing ...");
			while(rsMax.next())
			{								
				strEmpID = rsMax.getString("laborcode");
				strWorkLoc = rsMax.getString("worklocation");
				strBuildingNum = rsMax.getString("buildingnum");
				strRoomNum = rsMax.getString("roomnum");
				
				psIBoxEmp.setString(1, strEmpID);
				rsIBoxEmp = psIBoxEmp.executeQuery();				
				
				bolEmployeeExists=false;
				
				// Navigate through the employee details in iBox
				while(rsIBoxEmp.next())
				{
				  // System.out.println("processing: " + rsIBoxEmp.getString("name"));
				  bolEmployeeExists=true;				
				  strIUpdate="";
				
				  if (rsMax.getString("status").equals("T") &&
				      rsIBoxEmp.getString("status").equals("Available")) 
				   {
				       if (strIUpdate.length() == 0)
				         strIUpdate =" status='Deleted'";
				       else
				        strIUpdate +=" ,status='Deleted'";   
				   }
				          
				   if ((rsMax.getString("status").equals("A")) &&
				        rsIBoxEmp.getString("status").equals("Deleted")) 
				   {
				      if (strIUpdate.length() == 0)
				          strIUpdate  =" status='Available' "; 
				       else
				           strIUpdate +=" ,status='Available' "; 
				   }				  		
					// Check if route changed
					if(rsIBoxEmp.getString("recipvar1")!=null)
					{
					  if(!rsMax.getString("alnvalue").equals(rsIBoxEmp.getString("recipvar1")))
					  {	
						 if (! rsMax.getString("alnvalue").equals("N/A"))
						 {
						     if (strIUpdate.length() == 0)
						      strIUpdate =" recipvar1='" + rsMax.getString("alnvalue") + "' ";
						     else
						      strIUpdate +=" ,recipvar1='" + rsMax.getString("alnvalue") + "' ";   
						  } // if (! rsMax.getString("alnvalue").equals("N/A"))
						} // if(!rsMax.getString("alnvalue").
					 } // if(rsIBoxEmp.getString("recipvar1")!=null)
					
					// Check if building changed
					if(rsIBoxEmp.getString("recipvar2")!=null)
					{
				      if(!rsIBoxEmp.getString("recipvar2").equals(strBuildingNum))
					  {
				          if (strIUpdate.length() == 0)
				           strIUpdate =" recipvar2='" + strBuildingNum + "' ";
				          else
				          strIUpdate +=" ,recipvar2='" + strBuildingNum + "' ";
					   } // if(!rsIBoxEmp.getString("recipvar2").				
					 }  // if(rsIBoxEmp.getString("recipvar2")!=null		
					
					 // Check if room changed			
					 if(rsIBoxEmp.getString("recipvar3")!=null)
					 {
					  if(!rsIBoxEmp.getString("recipvar3").equals(strRoomNum))
					  {									
					      if (strIUpdate.length() == 0)
					        strIUpdate =" recipvar3 = '" + strRoomNum + "' ";
					      else
					        strIUpdate +=" ,recipvar3 = '" + strRoomNum + "' ";										
	      			   }						
     				  } // if(rsIBoxEmp.getString("recipvar3")!=null)

					// check if drop point changed  
					if(rsIBoxEmp.getString("recipvar4")!=null)
					{
					  if(!rsMax.getString("droppoint").equals(rsIBoxEmp.getString("recipvar4")))
					   {									
					      if (strIUpdate.length() == 0)
					        strIUpdate =" recipvar4 = '" + rsMax.getString("droppoint") + "' ";
					      else
					        strIUpdate +=" ,recipvar4 = '" + rsMax.getString("droppoint") + "' ";
					    }
				    } // if(rsIBoxEmp.getString("recipvar4")!=null)
					 // Check if phone changed
					if(rsIBoxEmp.getString("recipvar5")!=null)
				 	{
				      if(!rsMax.getString("phonenum").equals(rsIBoxEmp.getString("recipvar5")))
					   {									
     			          if (strIUpdate.length() == 0) 
	  			           strIUpdate =" recipvar5 = '" + rsMax.getString("phonenum") + "' "; 
     			          else
     			           strIUpdate +=" ,recipvar5 = '" + rsMax.getString("phonenum") + "' "; 
					   }
				      
					  } // if(rsIBoxEmp.getString("recipvar5")!=null
					
					 // Check if division changed	
				   	 if (rsIBoxEmp.getString("recipvar6")!=null)
					 {
					  if(!rsMax.getString("craft").equals(rsIBoxEmp.getString("recipvar6")))
					  {									
					      if (strIUpdate.length() == 0) 
					        strIUpdate ="  recipvar6 = '" + rsMax.getString("craft") + "' "; 		
					      else
					        strIUpdate +=" , recipvar6 = '" + rsMax.getString("craft") + "' "; 		
            		   }
					 } // if (rsIBoxEmp.getString("recipvar6")!=null								
				  	 
				   	 // check if email changed
				   	 if(rsIBoxEmp.getString("recipvar10")!=null)
					 {
					   if(!rsMax.getString("emailaddress").equals(rsIBoxEmp.getString("recipvar10")))
					 	{
					       if (strIUpdate.length() == 0) 
					         strIUpdate =" recipvar10 = '" + rsMax.getString("emailaddress") + "' ";
					       else
					         strIUpdate +=" , recipvar10 = '" + rsMax.getString("emailaddress") + "' ";
						}
					  } // if(rsIBoxEmp.getString("recipvar10")!=null
				   	 
				   	 // Perform the update
				   	 if (strIUpdate.length() >0)
				   	 {
				   	   String strTemp  =" update recipient set lastmodified=sysdate, ";
				   	   strTemp +=" name='"+ rsMax.getString("name") +"', ";
				   	   strTemp +=strIUpdate;
				   	   strTemp +=" where empid = '" + strEmpID + "'";
					  //System.out.println(strTemp );
				   	   stIBoxTemp.executeUpdate(strTemp);
				   	   lTotalRecordUpdate++;
				   	 } // if (strIUpdate.length() >0)
				   	 
				} // while(rsIBoxEmp.next())
				
			    if (bolEmployeeExists==false)
			    {
			       doInsertEmpIBox(rsMax, psIBoxInsertEmp);
			       lTotalRecordInsertEmp++;
		        }   
			    // Now check whether the location (building+room) exist
			    // in iBox
				psIBoxLoc.setString(1, rsMax.getString("buildingnum").trim() + "-" + rsMax.getString("roomnum").trim());						
				rsIBoxLoc = psIBoxLoc.executeQuery();
                
				bolLocationExists=false;				
				while(rsIBoxLoc.next())
				{
				    bolLocationExists=true;
				    if(rsIBoxLoc.getString("recipvar1")!=null)
				    {
 					 if(!rsIBoxLoc.getString("recipvar1").equals(rsMax.getString("alnvalue")))
 					 {										
					   stIBoxTemp.executeUpdate("update recipient set recipvar1 = '" + rsMax.getString("alnvalue") + "' where empid = '" + strBuildingNum+"-"+strRoomNum + "' and dynamic = 0");
					  }									
				    } // if(rsIBoxLoc.getString("recipvar1")!=null)
		
				    if(rsIBoxLoc.getString("recipvar7")!=null)
				    {
 					 if(!rsIBoxLoc.getString("recipvar7").equals(rsMax.getString("description")))
 					 {										
					   stIBoxTemp.executeUpdate("update recipient set recipvar7 = '" + rsMax.getString("description") + "' where empid = '" + strBuildingNum+"-"+strRoomNum + "' and dynamic = 0");
					  }									
				    } // if(rsIBoxLoc.getString("recipvar7")!=null
				
				  } // while(rsIBoxLoc.next())
				  if (bolLocationExists==false)
				  {
				    doInsertLocIBox(rsMax, psIBoxInsertLoc);
					lTotalRecordInsertLoc++;
				  }
				  
				 if(rsIBoxLoc!=null)
					rsIBoxLoc.close();
			 } // while(rsMax.next())
		    } // if(rsMax!=null)
			System.out.print("Total new location records inserted into iBox: " + lTotalRecordInsertLoc + "\n");
			System.out.print("Total new employee records inserted into iBox: " + lTotalRecordInsertEmp + "\n");
			System.out.print("Total employee records updated into iBox: " + lTotalRecordUpdate + "\n");
			
			
			//bwLog.write("Total new location records inserted into iBox: " + lTotalRecordInsertLoc + "\n");
			//bwLog.write("Total new employee records inserted into iBox: " + lTotalRecordInsertEmp + "\n");
			//bwLog.write("Total fields updated in iBox: " + lTotalFieldUpdate + "\n");
				
		
		if(rsMax!=null)
			rsMax.close();
		if(rsIBoxEmp!=null)
			rsIBoxEmp.close();		
		if(rsIBoxEmp!=null)
			psIBoxEmp.close();
		if(psIBoxLoc!=null)
			psIBoxLoc.close();
		if(psMax!=null)
			psMax.close();
		if(stIBoxTemp!=null)
			stIBoxTemp.close();			
	}
	
	public static void doInsertLocIBox(ResultSet rsMax, PreparedStatement psIBoxInsert) throws SQLException{
		
	    psIBoxInsert.setString(1, rsMax.getString("buildingnum").trim() + "-" + rsMax.getString("roomnum").trim()); 	//use buildingnum-roomnum for laborcode
		psIBoxInsert.setString(2, rsMax.getString("buildingnum").trim() + "-" + rsMax.getString("roomnum").trim());		//use buildingnum-roomnum for laborname		
		psIBoxInsert.setString(3, rsMax.getString("alnvalue"));		//recipvar1 = route (eg. upper, lower, middle...)
		psIBoxInsert.setString(4, rsMax.getString("buildingnum"));	//recipvar2 = building number
		psIBoxInsert.setString(5, rsMax.getString("roomnum"));		//recipvar3 = room number		
		psIBoxInsert.setString(6, rsMax.getString("description"));	//recripvar7 = location description		
		psIBoxInsert.setInt(7, 0);									//download = 0 (constant)
		psIBoxInsert.setInt(8, 0);									//dynamic = 0 for location
		psIBoxInsert.setInt(9, 1);									//profileid = 1 (constant)
		psIBoxInsert.setString(10, "Available");					//Status = 'Available' (constant for location)
		psIBoxInsert.executeUpdate();
	}
	public static void doInsertEmpIBox(ResultSet rsMax, PreparedStatement psIBoxInsert) throws SQLException{		
		psIBoxInsert.setString(1, rsMax.getString("laborcode"));	//laborcode
		psIBoxInsert.setString(2, rsMax.getString("name"));			//name		
		psIBoxInsert.setString(3, rsMax.getString("alnvalue"));		//recipvar1 = route (eg. upper, lower, middle...)
		psIBoxInsert.setString(4, rsMax.getString("buildingnum"));	//recipvar2 = building number
		psIBoxInsert.setString(5, rsMax.getString("roomnum"));		//recipvar3 = room number		
		psIBoxInsert.setString(6, rsMax.getString("droppoint"));	//recipvar4 = droppoint	(mail stop)	- only for employee info
		psIBoxInsert.setString(7, rsMax.getString("phonenum"));		//recipvar5 = phonenum	(office phone) - only for employee info		
		psIBoxInsert.setString(8, rsMax.getString("description"));	//recripvar7 = location description
		psIBoxInsert.setString(9, rsMax.getString("emailaddress"));	//recripvar10 =  (email address)
		psIBoxInsert.setInt(10, 0);									//download = 0 (constant)
		psIBoxInsert.setInt(11, 1);									//dynamic = 1 for employee info
		psIBoxInsert.setInt(12, 1);									//profileid = 1 (constant)
		psIBoxInsert.setString(13, "Available");					//Status = 'Available' (constant for location)
		psIBoxInsert.executeUpdate();
	}
}
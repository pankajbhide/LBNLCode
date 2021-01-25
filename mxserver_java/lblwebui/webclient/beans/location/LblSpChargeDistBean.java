/****************************************************************************
 *  Java Class File : LblSpChargeDistBean
 * 
 *  Description     :  Custom bean class for space_charge_distribution
 *   				                          
 *                      The method SPBULKUPD performs bulk update the 
 *                      selected records. It updates lbl_sp_charge_trans
 *                      table and sets the value of proj_act_id to the 
 *                      to_projact_id indicated by the user for the 
 *                      selected records.  
 *                    
 *  Author           : Pankaj Bhide
 *   
 *  Date written     :   30-AUG-17
 * 
 *  Modification 
 *  History          : 
 * *************************************************************/
package lblwebui.webclient.beans.location;

import java.rmi.RemoteException;
import java.util.Vector;



import psdi.mbo.MboConstants;
import psdi.mbo.MboRemote;
import psdi.mbo.MboSetRemote;
import psdi.security.UserInfo;
import psdi.server.MXServer;
import psdi.util.MXApplicationException;
import psdi.util.MXApplicationYesNoCancelException;
import psdi.util.MXException;
import psdi.webclient.system.beans.AppBean;
import psdi.webclient.system.beans.DataBean;
import psdi.webclient.system.beans.ResultsBean;
import psdi.webclient.system.controller.SessionContext;
import psdi.webclient.system.controller.Utility;
import psdi.webclient.system.controller.WebClientEvent;
import psdi.webclient.system.runtime.WebClientRuntime;
import psdi.webclient.system.session.WebClientSession;

public class LblSpChargeDistBean extends AppBean 
{

	Vector selectedRecords = new Vector();
	
	// Make sure that the user selected at-least one record from the list page
	public void initialize()
		    throws MXException, RemoteException
	{
		super.initialize();
		
		if (this.app.onListTab()) // Action needs to be invoked from list tab 
		{
		  if (this.app.getResultsBean().hasRecordsForAction()) // Records must be marked for action
		  {
			 this.selectedRecords = this.app.getResultsBean().getSelection(); // Get ref of selected records
			 if (this.selectedRecords.size() <= 0)
			  {
				throw new MXApplicationException("location", "lbl_spchrgrecordsnotselected");
			   }
					
		   }		
		}
		
	  } // end of method

     // Start performing the bulk updates 
	 public int SPBULKUPD()
			    throws MXException, RemoteException
     {
	    String strLogmessage = null;
	    
		this.selectedRecords = this.app.getResultsBean().getSelection();
	    int selRecCount = this.selectedRecords.size();
	    boolean boolFromProjActIdnull=false;
	    
				
		if (this.app.onListTab() && this.app.getResultsBean().hasRecordsForAction() && selRecCount > 0)
		{
			// Get the values of from proj/act id and to proj/act id and 
			// validate that they are not null and are not same
					
			// Get the underlying data bean which should be 'spbulkupd_ds'.
			DataBean bean = this.app.getDataBean("spbulkupd_ds");
			UserInfo ui = this.clientSession.getMXSession().getUserInfo();
					
			// Get user values from the dialog window.
			String strFromProjActID= bean.getString("FROM_PROJACT_ID");
			String strToProjActID  = bean.getString("TO_PROJACT_ID");
			String strMessage="lbl_spchrgefromglnull";
		    if (strFromProjActID == null ||strFromProjActID.length() ==0)
		    {
		    	if (ui.isInteractive())
                {
                  int userInput = MXApplicationYesNoCancelException.getUserInput(strMessage, getMXSession().getMXServerRemote(), ui);
                  switch (userInput)
                  {
                    case -1: 
                    	throw new MXApplicationYesNoCancelException(strMessage, "location", strMessage);
                    case 2: // Okay button
		                boolFromProjActIdnull=true;
		                break;
		            default: 
		            	break;
                  }
                }
		        if (! boolFromProjActIdnull)
		        {	
		        	WebClientEvent newEvent = new WebClientEvent("dialogclose", this.app.getCurrentPageId(), null, this.clientSession);
					this.clientSession.queueEvent(newEvent);
		        }
		    } // if (strFromProjActID == null ||strFromProjActID.length() ==0)
		   
		  
		   			
	       if (strToProjActID == null || strToProjActID.length()==0)
				throw new MXApplicationException("location", "lbl_spchrgtoprojnull");
					
		    if (strFromProjActID != null ||strFromProjActID.length() >0) 
		    { 
		    	 if (strFromProjActID.equals(strToProjActID))
		    		 throw new MXApplicationException("location", "lbl_spchrgfromtoprojsame");
		    }
				    
		    // Start processing the selected rooms
		    for (int i = 0; i < selRecCount; i++) 
		    {
		    	 MboRemote selLocationRec= (MboRemote) selectedRecords.get(i);
		    	 
		    	 String strLocation=selLocationRec.getString("location");
		    	 boolean boolDisabled=selLocationRec.getBoolean("disabled");
		    	 String strChargable=selLocationRec.getString("gisparam2");
		    	 String strBuilding=selLocationRec.getString("lo1");
		    	 String strFloor=selLocationRec.getString("lo2");
		    	 String strRoom=selLocationRec.getString("lo3");		    	 
		    	
		    	 // Process only active and chargeable rooms
		    	 if (boolDisabled==false && strChargable.equals("Y"))
		    	 {
		    		 
	
		    		 MboSetRemote lblSpChargeDistSet0=null ;
		    		 MboSetRemote lblSpChargeDistSet=null ;
		    		 MboSetRemote lblLocationsSet=null;
		    		 String strWhere=null;
		    		 
		    	     // From project/activity id not indicated
		    		 if (boolFromProjActIdnull==true)
		    		 {
		    	 
		    			 lblSpChargeDistSet = MXServer.getMXServer().getMboSet("lbl_sp_charge_dist", ui);
	 				     strWhere=" location='" + strLocation + "'";
	 				     lblSpChargeDistSet.setWhere(strWhere);
					   	 if (! lblSpChargeDistSet.isEmpty())
					   	 {
					   		lblSpChargeDistSet.deleteAll();
					   		lblSpChargeDistSet.save();
					   	
					   	 }
					   	MboRemote lblSpChargeDist=lblSpChargeDistSet.add();
					   	lblSpChargeDist.setValue("orgid", "LBNL",MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION_AND_NOACTION);
					   	lblSpChargeDist.setValue("siteid", "FAC",MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION_AND_NOACTION);
					   	lblSpChargeDist.setValue("location", strLocation,MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION_AND_NOACTION);
					   	lblSpChargeDist.setValue("proj_act_id", strToProjActID,MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION_AND_NOACTION);
					   	lblSpChargeDist.setValue("charged_to_percent", 100, MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION_AND_NOACTION);
					   	lblSpChargeDist.setValue("building_number", strBuilding, MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION_AND_NOACTION);
					   	lblSpChargeDist.setValue("floor_number", strFloor, MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION_AND_NOACTION);
					   	lblSpChargeDist.setValue("room_number", strRoom, MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION_AND_NOACTION);
					   	lblSpChargeDist.setValue("changeby",ui.getUserName(),MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION_AND_NOACTION);
					   	lblSpChargeDist.setValue("changedate",MXServer.getMXServer().getDate(),
		                                   MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION_AND_NOACTION);  
					   	lblSpChargeDistSet.save();
					   
					   	if (strLogmessage == null || strLogmessage.length()==0)
			   	        	strLogmessage ="Updated location " + strLocation + " with new proj/act id: " + strToProjActID +  System.getProperty("line.separator");
			   	        else 
			   	        	strLogmessage +="Updated location " + strLocation + " with new proj/act id: " + strToProjActID +  System.getProperty("line.separator");
					   	
					   	// Update locations with changeby and changedate
					   	lblLocationsSet = MXServer.getMXServer().getMboSet("locations", ui);
					    strWhere=" location='" + strLocation + "'";
	 				    lblLocationsSet.setWhere(strWhere);
					   	 if (! lblLocationsSet.isEmpty())
					   	 {
					   		lblLocationsSet.getMbo(0).setValue("changeby",ui.getUserName(),MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION_AND_NOACTION);
					   		lblLocationsSet.getMbo(0).setValue("changedate",MXServer.getMXServer().getDate(),
			                                   MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION_AND_NOACTION); 
					   		lblLocationsSet.save();
					   		lblLocationsSet.close();
					   	 }
					   		 
					   		 
					   	
					   	
					  	
		    		 } // if (boolFromProjActIdnull)
		    		 
		    		 else //  if (boolFromProjActIdnull==false)
		    		 {
					   	 lblSpChargeDistSet0 = MXServer.getMXServer().getMboSet("lbl_sp_charge_dist", ui);
	 				     strWhere=" location='" + strLocation + "'";
	 				     lblSpChargeDistSet0.setWhere(strWhere);
					   	 if (! lblSpChargeDistSet0.isEmpty())
					   	 {
					   	   for(int j=0; lblSpChargeDistSet0.getMbo(j) !=null;j++)
					       {
					   		MboRemote selSpChargeDistRec=lblSpChargeDistSet0.getMbo(j) ;
   				   		    String strProjActId = selSpChargeDistRec.getString("proj_act_id");
		    	 			    	 		    	 
   				   		    if (strProjActId.equals(strFromProjActID))
   				   		    { 
				    		 double dblCharged_to_percent=selSpChargeDistRec.getDouble("charged_to_percent");
				    		 // Check whether the ToProject id is already associated to
				    		 // that location, if it is then, update the charge to percent of that record
				    		 // and delete the record of FromProj id for that location.
						    		 
						 	 lblSpChargeDistSet = MXServer.getMXServer().getMboSet("lbl_sp_charge_dist", ui);
		 				     strWhere=" location='" + strLocation + "' and proj_act_id='" + strToProjActID +"'";
		 				    
						     lblSpChargeDistSet.setWhere(strWhere);
						   	 if (! lblSpChargeDistSet.isEmpty())
						   	 {
						   		
						   	   	lblSpChargeDistSet.getMbo(0).setValue("charged_to_percent",
						   	       (lblSpChargeDistSet.getMbo(0).getDouble("charged_to_percent") +
						   	        dblCharged_to_percent), 
						   	       	MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION_AND_NOACTION);				   	       	
						   	   	
		  		   	        	    lblSpChargeDistSet.save();
		  		   	        	    lblSpChargeDistSet.close();
		  		   	        	    lblSpChargeDistSet=null;	
						   	        	
						   	        lblSpChargeDistSet = MXServer.getMXServer().getMboSet("lbl_sp_charge_dist", ui);
		  		   	        	    strWhere=" location='" + strLocation + "' and proj_act_id='" + strFromProjActID +"'";
		  	 				    
		  		   	        	    lblSpChargeDistSet.setWhere(strWhere);
		  		   	        	    if (! lblSpChargeDistSet.isEmpty()) 		   	        	      		   	        	    
		  		   	        	    	lblSpChargeDistSet.getMbo(0).delete();
		  		   	        	    
		  		   	        	    lblSpChargeDistSet.save();
				   	        	    lblSpChargeDistSet.close();
				   	        	    lblSpChargeDistSet=null;	
		  		   	        	    				   	        
						   	        if (strLogmessage == null || strLogmessage.length()==0)
						   	        	strLogmessage ="Updated location " + strLocation + " with new proj/act id: " + strToProjActID +  System.getProperty("line.separator");
						   	        else 
						   	        	strLogmessage +="Updated location " + strLocation + " with new proj/act id: " + strToProjActID +  System.getProperty("line.separator");
						   	        
						   	        // Update locations with changeby and changedate
								   	lblLocationsSet = MXServer.getMXServer().getMboSet("locations", ui);
								    strWhere=" location='" + strLocation + "'";
				 				    lblLocationsSet.setWhere(strWhere);
								   	 if (! lblLocationsSet.isEmpty())
								   	 {
								   		lblLocationsSet.getMbo(0).setValue("changeby",ui.getUserName(),MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION_AND_NOACTION);
								   		lblLocationsSet.getMbo(0).setValue("changedate",MXServer.getMXServer().getDate(),
						                                   MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION_AND_NOACTION); 
								   		lblLocationsSet.save();
								   		lblLocationsSet.close();
								   	 }
						   	    }
						   	    else // toprojid not present
						   	    {
						   	    	lblSpChargeDistSet=null;
						   	    	
						   	    	lblSpChargeDistSet = MXServer.getMXServer().getMboSet("lbl_sp_charge_dist", ui);
						   	    	strWhere=" location='" + strLocation + "' and proj_act_id='" + strFromProjActID +"'";
						   	    					   	    	
						   	    	lblSpChargeDistSet.setWhere(strWhere);
						   	    	if (! lblSpChargeDistSet.isEmpty())
						   	    	{
							   		 	 				     
						   	    		lblSpChargeDistSet.getMbo(0).setValue("proj_act_id",strToProjActID,  
						   	      			MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION_AND_NOACTION);
						   	    		
						   	    		lblSpChargeDistSet.save();
						   	    		lblSpChargeDistSet.close();
						   	    		lblSpChargeDistSet=null;
						   	    		
							   	        if (strLogmessage == null || strLogmessage.length()==0)
							   	        	strLogmessage ="Updated location " + strLocation + " with new proj/act id: " + strToProjActID +  System.getProperty("line.separator");
							   	        else 
							   	        	strLogmessage +="Updated location " + strLocation + " with new proj/act id: " + strToProjActID +  System.getProperty("line.separator");
							   	        
							   	        
							   	        // Update locations with changeby and changedate
									   	lblLocationsSet = MXServer.getMXServer().getMboSet("locations", ui);
									    strWhere=" location='" + strLocation + "'";
					 				    lblLocationsSet.setWhere(strWhere);
									   	 if (! lblLocationsSet.isEmpty())
									   	 {
									   		lblLocationsSet.getMbo(0).setValue("changeby",ui.getUserName(),MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION_AND_NOACTION);
									   		lblLocationsSet.getMbo(0).setValue("changedate",MXServer.getMXServer().getDate(),
							                                   MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION_AND_NOACTION); 
									   		lblLocationsSet.save();
									   		lblLocationsSet.close();
									   	 }
						   	    	} 

				   	             } // // toprojid not present in the records 
						   	 	
						     } // if (strProjActId.equals(strFromProjActID))
   				   		    
					       } // for(int j=0; lblSpChargeDistSet.getMbo(j) !=null;j++)
					   	   
					   	   lblSpChargeDistSet0.close();
					   	   lblSpChargeDistSet0=null;
					   	   
					   	 } // if (! lblSpChargeDistSet.isEmpty())
					   	 
					   } // if (boolFromProjActIdnull==false)
		    		
		          	 } //  if (! boolDisabled && strChargable.equals("Y"))
				  } // for (int i = 0; i < selRecCount; i++)
				        
		    	if (strLogmessage != null )
		    		
		    	{
		    		MboSetRemote lblSpChargeUpdSet = MXServer.getMXServer().getMboSet("LBL_SP_CHARGE_DIST_UPD", ui);
		    	
			    	MboRemote newRecord=null;
			    	newRecord=lblSpChargeUpdSet.add();
			    	newRecord.setValue("orgid","LBNL", MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION_AND_NOACTION);
			    	newRecord.setValue("siteid","FAC", MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION_AND_NOACTION);
			    	newRecord.setValue("FROM_PROJACT_ID",strFromProjActID, MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION_AND_NOACTION);
			    	newRecord.setValue("TO_PROJACT_ID",strToProjActID, MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION_AND_NOACTION);
			    	newRecord.setValue("changeby",ui.getUserName(),MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION_AND_NOACTION);
			    	newRecord.setValue("changedate",MXServer.getMXServer().getDate(),
	                                   MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION_AND_NOACTION);
		            newRecord.setValue("description", "Project/Activity changed for locations", MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION_AND_NOACTION);	    	
			    	newRecord.setValue("DESCRIPTION_LONGDESCRIPTION", strLogmessage,      MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION_AND_NOACTION);
			    			    			    	
			    	lblSpChargeUpdSet.save();
			    	lblSpChargeUpdSet.close();
			    	lblSpChargeUpdSet=null;
		    	}
		    	
		    			    	
		    	
				} // if (selRecCount > 0)
			
				// This will close out the dialog window. 			  
				WebClientEvent newEvent = new WebClientEvent("dialogclose", this.app.getCurrentPageId(), null, this.clientSession);
				this.clientSession.queueEvent(newEvent);    			       
 	  return 1;
    }
}
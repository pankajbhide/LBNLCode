/*****************************************************************
 *  Java Class File : LblWorkorderAppBean
 * 
 *  Description     :  Custom work order app bean class
 *   				                                                       
 *                          The method LBLWO2WKTH allows user creating a 
 *                           walk-through template from an existing work order 
 *                           walk-through.                  
 *                    
 *   *  Author           : Pankaj Bhide
 *   
 * Date written     :   19-July-2013
 * 
 * Modification 
 * History          : 
 * *************************************************************/
package lblwebui.webclient.beans.workorder;

import java.rmi.RemoteException;

import lbl.app.lbl_walkthru.*;
import psdi.mbo.custapp.*;
import psdi.app.workorder.*;
import psdi.mbo.MboConstants;
import psdi.mbo.MboRemote;
import psdi.mbo.MboSetRemote;
import psdi.server.MXServer;
import psdi.util.MXApplicationException;
import psdi.util.MXException;
import psdi.util.logging.MXLogger;
import psdi.util.logging.MXLoggerFactory;
import psdi.webclient.system.beans.AppBean;
import psdi.webclient.system.beans.DataBean;
import psdi.webclient.system.controller.Utility;
import psdi.webclient.system.controller.WebClientEvent;

public class LBLWorkorderAppBean extends AppBean
{
	MXLogger mxLogger = MXLoggerFactory.getLogger("maximo.application.WOTRACK");
	public LBLWorkorderAppBean() {
	 	super();
		
		 	
	}

	public void initialize()
		throws MXException, RemoteException
	{
		
		super.initialize();
		
		
	DataBean appBean = this.app.getAppBean();
    MboRemote woMbo = appBean.getMbo();
    String[] parms = new String[1];
    parms[0] = appBean.getMbo().getString("wonum");
		
    
    String strLblWkthruid=woMbo.getString("lbl_wkthruid");
    if (strLblWkthruid==null || strLblWkthruid.length() ==0)
        throw new MXApplicationException("workorder", "lbl_wowkthrunull", parms);
    
    woMbo.setValue("lbl_wkthruid", strLblWkthruid,MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION);
	 
  		
	}
		
	public int LBLWO2WKTH() throws MXException, RemoteException
  {
	
	  // This will close out the dialog window. 
		Utility.sendEvent(new WebClientEvent("dialogclose", this.app.getCurrentPageId(), null, this.sessionContext));
    this.sessionContext.queueRefreshEvent();
    
   
    
		MboSetRemote WOWkthru=null,WOWkthruOps=null, WOWkthruHaz=null, WOWkthruMat=null, WOWkthruRes=null, WOWkthruFeedbk=null;
    
        
    // put your custom code here
	DataBean appBean = this.app.getAppBean();
    MboRemote woMbo = appBean.getMbo();
    String strNewWkthruid=null;
    
    
    //********************************************************************************
    // Start populating records into a set of Walk-through template tables
    //********************************************************************************
    
    // 1- LBL_WKTHRU
    
     MboSetRemote lblWkThruSet = MXServer.getMXServer().getMboSet("LBL_WKTHRU", woMbo.getUserInfo());
     LblWalkthruRemote lblWkthru=(LblWalkthruRemote) lblWkThruSet.add();
     strNewWkthruid=lblWkthru.getString("wkthruid");
     
      WOWkthru = woMbo.getMboSet("LBL_WO2WOWKTHRU");
	   
	   if( ! WOWkthru.isEmpty())
      {
       for(int i=0; WOWkthru.getMbo(i) !=null;i++)
       {
      	 
    	   lblWkthru.setValue("orgid", WOWkthru.getMbo(i) .getString("orgid"), MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION);
    	   lblWkthru.setValue("siteid",  WOWkthru.getMbo(i) .getString("siteid"), MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION);
    	   lblWkthru.setValue("wo_orgid", WOWkthru.getMbo(i) .getString("orgid"), MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION);
    	   lblWkthru.setValue("wo_siteid",  WOWkthru.getMbo(i) .getString("siteid"), MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION);
    	   lblWkthru.setValue("wonum",     WOWkthru.getMbo(i) .getString("wonum"), MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION);
    	   lblWkthru.setValue("description",WOWkthru.getMbo(i) .getString("description"),
    	  		                                   MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION);
    	  lblWkthru.setValue("DESCRIPTION_LONGDESCRIPTION",WOWkthru.getMbo(i) .getString("DESCRIPTION_LONGDESCRIPTION"),
            MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION);

    	  lblWkthru.setValue("WKTHRUID",strNewWkthruid,
          MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION);

    	  lblWkthru.setValue("PLANNING_REQD",WOWkthru.getMbo(i) .getString("PLANNING_REQD"),
         MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION);
    	  lblWkthru.setValue("PLANNING_REQD_LONGDESCRIPTION",WOWkthru.getMbo(i) .getString("PLANNING_REQD_LONGDESCRIPTION"),
         MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION);

    	 lblWkthru.setValue("ACCEPT_CRITERIA",WOWkthru.getMbo(i) .getString("ACCEPT_CRITERIA"),
         MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION);
    	 lblWkthru.setValue("ACCEPT_CRITERIA_LONGDESCRIPTION",WOWkthru.getMbo(i) .getString("ACCEPT_CRITERIA_LONGDESCRIPTION"),
         MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION);

   	   lblWkthru.setValue("FEEDREV_LESNLRN",WOWkthru.getMbo(i) .getString("FEEDREV_LESNLRN"),
          MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION);
     	 lblWkthru.setValue("FEEDREV_LESNLRN_LONGDESCRIPTION",WOWkthru.getMbo(i) .getString("FEEDREV_LESNLRN_LONGDESCRIPTION"),
          MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION);

   	   lblWkthru.setValue("SCOPE_OF_WORK",WOWkthru.getMbo(i) .getString("SCOPE_OF_WORK"),
          MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION);
       lblWkthru.setValue("SCOPE_OF_WORK_LONGDESCRIPTION",WOWkthru.getMbo(i) .getString("SCOPE_OF_WORK_LONGDESCRIPTION"),
          MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION);

        lblWkthru.setValue("ACCESS_LOCATION",WOWkthru.getMbo(i) .getString("ACCESS_LOCATION"),
          MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION);
    	  lblWkthru.setValue("ACCESS_LOCATION_LONGDESCRIPTION",WOWkthru.getMbo(i) .getString("ACCESS_LOCATION_LONGDESCRIPTION"),
          MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION);    	    	 
       } //   for(int i=0; WOWkthru.getMbo(i) !=null;i++)
      }  //  if( ! WOWkthru.isEmpty())  
	   
	   // 2- LBL_WKTHRUOPS
	    
	  MboSetRemote lblWkThruOpsSet = MXServer.getMXServer().getMboSet("LBL_WKTHRUOPS", woMbo.getUserInfo());
          
      WOWkthruOps = woMbo.getMboSet("LBL_WO2WOWKTHOPS");
	   
	   if( ! WOWkthruOps.isEmpty())
      {
       for(int i=0; WOWkthruOps.getMbo(i) !=null;i++)
       {
    	 MboRemote lblWkthruOps=lblWkThruOpsSet.add(); 
         lblWkthruOps.setValue("orgid", WOWkthruOps.getMbo(i).getString("orgid"), MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION);
         lblWkthruOps.setValue("siteid",  WOWkthruOps.getMbo(i).getString("siteid"), MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION);
         lblWkthruOps.setValue("wkthruid",  strNewWkthruid, MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION);
         lblWkthruOps.setValue("description",WOWkthruOps.getMbo(i).getString("description"),
      	  		                                   MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION);
         lblWkthruOps.setValue("DESCRIPTION_LONGDESCRIPTION",WOWkthruOps.getMbo(i).getString("DESCRIPTION_LONGDESCRIPTION"),
              MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION);

         lblWkthruOps.setValue("OPSEQUENCE",WOWkthruOps.getMbo(i).getInt("OPSEQUENCE"),
           MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION);
         lblWkthruOps.setValue("OPDURATION",WOWkthruOps.getMbo(i).getDouble("OPDURATION"),
           MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION);
	       } // for(int i=0; WOWkthruOps.getMbo(i) !=null;i++)
       } // if(! WOWkthruOps.isEmpty())
	   if (  WOWkthruOps !=null) {   WOWkthruOps.close(); WOWkthruOps=null;}
	   
	   // 3- LBL_WOWKTHRUHAZ
	    
      MboSetRemote lblWkThruHazSet = MXServer.getMXServer().getMboSet("LBL_WKTHRUHAZ", woMbo.getUserInfo());
     
      WOWkthruHaz = woMbo.getMboSet("LBL_WO2WOWKTHHAZ");
	   
	   if( ! WOWkthruHaz.isEmpty())
      {
       for(int i=0; WOWkthruHaz.getMbo(i) !=null;i++)
       {
    	 MboRemote lblWkthruHaz= lblWkThruHazSet.add();
      	 lblWkthruHaz.setValue("orgid", WOWkthruHaz.getMbo(i).getString("orgid"), MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION);
      	 lblWkthruHaz.setValue("siteid",  WOWkthruHaz.getMbo(i).getString("siteid"), MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION);
      	 lblWkthruHaz.setValue("wkthruid",  strNewWkthruid, MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION);          	
      	 lblWkthruHaz.setValue("hazardid",WOWkthruHaz.getMbo(i).getString("hazardid"),  
     	  		                                   MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION);          
	       } // for(int i=0; WOWkthruHaz(i) !=null;i++)
       } // if(! WOWkthruHaz.isEmpty())
	   if (  WOWkthruHaz !=null) {   WOWkthruHaz.close(); WOWkthruHaz=null;}
	   
	   // 4- LBL_WOWKTHRUMAT
	    
     MboSetRemote lblWkThruMatSet = MXServer.getMXServer().getMboSet("LBL_WKTHRUMAT", woMbo.getUserInfo());
     
     WOWkthruMat = woMbo.getMboSet("LBL_WO2WOWKTHMAT");
     if( ! WOWkthruMat.isEmpty())
     {
      for(int i=0; WOWkthruMat.getMbo(i) !=null;i++)
      {
       MboRemote lblWkthruMat= lblWkThruMatSet.add();      	
       lblWkthruMat.setValue("orgid", WOWkthruMat.getMbo(i).getString("orgid"), MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION);
       lblWkthruMat.setValue("siteid",  WOWkthruMat.getMbo(i).getString("siteid"), MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION);
       lblWkthruMat.setValue("wkthruid",  strNewWkthruid, MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION);            
       lblWkthruMat.setValue("itemnum",WOWkthruMat.getMbo(i).getString("itemnum"),
                           MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION);
       lblWkthruMat.setValue("quantity",WOWkthruMat.getMbo(i).getDouble("quantity"),
                             MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION); 
       lblWkthruMat.setValue("ITEMDESCRIPTION",WOWkthruMat.getMbo(i).getString("ITEMDESCRIPTION"),
                            MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION);
        lblWkthruMat.setValue("ITEMDESCRIPTION_LONGDESCRIPTION",WOWkthruMat.getMbo(i).getString("ITEMDESCRIPTION_LONGDESCRIPTION"),
                           MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION);
        lblWkthruMat.setValue("LOCATION_INFO",WOWkthruMat.getMbo(i).getString("LOCATION_INFO"),
                           MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION);
       } //for(int i=0; WOWkthruMat.getMbo(i) !=null;i++)
      } // if(! WOWkthruMat.isEmpty())
     if (  WOWkthruMat !=null) {   WOWkthruMat.close(); WOWkthruMat=null;}
     
     
     // 5- LBL_WOWKTHRURES

     MboSetRemote lblWkThruResSet = MXServer.getMXServer().getMboSet("LBL_WKTHRURES", woMbo.getUserInfo());
 
     WOWkthruRes = woMbo.getMboSet("LBL_WO2WOWKTHRESALL");
     if( ! WOWkthruRes.isEmpty())
     {
      for(int i=0; WOWkthruRes.getMbo(i) !=null;i++)
      {
    	MboRemote lblWkthruRes= lblWkThruResSet.add();
        lblWkthruRes.setValue("orgid", WOWkthruRes.getMbo(i).getString("orgid"), MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION);
        lblWkthruRes.setValue("siteid",  WOWkthruRes.getMbo(i).getString("siteid"), MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION);
        lblWkthruRes.setValue("wkthruid",  strNewWkthruid, MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION);
       
       	lblWkthruRes.setValue("resource_type", WOWkthruRes.getMbo(i).getString("resource_type"),
          MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION);
        lblWkthruRes.setValue("SEQUENCE", WOWkthruRes.getMbo(i).getInt("SEQUENCE"),
          MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION);
        lblWkthruRes.setValue("EHS_SUPPORT", WOWkthruRes.getMbo(i).getString("EHS_SUPPORT"),
          MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION);
        lblWkthruRes.setValue("EHS_SUPPORT_COMMENTS", WOWkthruRes.getMbo(i).getString("EHS_SUPPORT_COMMENTS"),
          MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION);
        lblWkthruRes.setValue("PERMITS", WOWkthruRes.getMbo(i).getString("PERMITS"),
          MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION);
        lblWkthruRes.setValue("PERMITS_COMMENTS", WOWkthruRes.getMbo(i).getString("PERMITS_COMMENTS"),
          MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION);
        lblWkthruRes.setValue("PERMITS_COMMENTS_LONGDESCRIPTION", WOWkthruRes.getMbo(i).getString("PERMITS_COMMENTS_LONGDESCRIPTION"),
          MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION);
        lblWkthruRes.setValue("DRAWINGS", WOWkthruRes.getMbo(i).getString("DRAWINGS"),
          MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION);
        lblWkthruRes.setValue("DRAWINGS_COMMENTS", WOWkthruRes.getMbo(i).getString("DRAWINGS_COMMENTS"),
          MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION);
        lblWkthruRes.setValue("CRAFT", WOWkthruRes.getMbo(i).getString("CRAFT"),
          MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION);
        lblWkthruRes.setValue("CRAFT_COMMENTS", WOWkthruRes.getMbo(i).getString("CRAFT_COMMENTS"),
          MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION);
        lblWkthruRes.setValue("CRAFT_COMMENTS_LONGDESCRIPTION", WOWkthruRes.getMbo(i).getString("CRAFT_COMMENTS_LONGDESCRIPTION"),
          MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION);
        lblWkthruRes.setValue("CRAFT_DURATION", WOWkthruRes.getMbo(i).getDouble("CRAFT_DURATION"),
          MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION);
        lblWkthruRes.setValue("EHS_SUPPORT_COMMENTS_LONGDESCRIPTION", WOWkthruRes.getMbo(i).getString("EHS_SUPPORT_COMMENTS_LONGDESCRIPTION"),
          MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION);
        lblWkthruRes.setValue("EHS_SUPPORT_CONT", WOWkthruRes.getMbo(i).getString("EHS_SUPPORT_CONT"),
          MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION);
        lblWkthruRes.setValue("PERSONID", WOWkthruRes.getMbo(i).getString("PERSONID"),
          MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION);
        lblWkthruRes.setValue("PERSON_PHONE", WOWkthruRes.getMbo(i).getString("PERSON_PHONE"),
          MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION);
        lblWkthruRes.setValue("PERSON_FUNCTION", WOWkthruRes.getMbo(i).getString("PERSON_FUNCTION"),
          MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION);
        lblWkthruRes.setValue("PERSON_FUNCTION_LONGDESCRIPTION", WOWkthruRes.getMbo(i).getString("PERSON_FUNCTION_LONGDESCRIPTION"),
          MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION);
        lblWkthruRes.setValue("PLAN_TEAM_DESC", WOWkthruRes.getMbo(i).getString("PLAN_TEAM_DESC"),
          MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION);
        lblWkthruRes.setValue("PLAN_TEAM_DESC_LONGDESCRIPTION", WOWkthruRes.getMbo(i).getString("PLAN_TEAM_DESC_LONGDESCRIPTION"),
          MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION);
        lblWkthruRes.setValue("PLAN_TEAM_DURATION", WOWkthruRes.getMbo(i).getDouble("PLAN_TEAM_DURATION"),
          MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION);
        lblWkthruRes.setValue("RES_DURATION", WOWkthruRes.getMbo(i).getDouble("RES_DURATION"),
          MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION);

      } // for(int i=0;  WOWkthruRes.getMbo(i) !=null;i++)
            } // if(!  WOWkthruRes.isEmpty())
       if (  WOWkthruRes !=null) {   WOWkthruRes.close(); WOWkthruRes=null;}
       
       // 5- LBL_WKTHRUFEEDBK

       MboSetRemote lblWkthruFeedbkSet = MXServer.getMXServer().getMboSet("LBL_WKTHRUFEEDBK", woMbo.getUserInfo());

       WOWkthruFeedbk = woMbo.getMboSet("LBL_WO2WOWKFEEDBACK");
       if( ! WOWkthruFeedbk.isEmpty())
       {
        for(int i=0; WOWkthruFeedbk.getMbo(i) !=null;i++)
        {
          MboRemote lblWkthruFeedbk= lblWkthruFeedbkSet.add();
          lblWkthruFeedbk.setValue("orgid", WOWkthruFeedbk.getMbo(i).getString("orgid"), MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION);
          lblWkthruFeedbk.setValue("siteid",  WOWkthruFeedbk.getMbo(i).getString("siteid"), MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION);
          lblWkthruFeedbk.setValue("wkthruid",  strNewWkthruid, MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION);
          lblWkthruFeedbk.setValue("FEEDBK_DTL",WOWkthruFeedbk.getMbo(i).getString("FEEDBK_DTL"),
              MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION);
       	 lblWkthruFeedbk.setValue("FEEDBK_DTL_LONGDESCRIPTION",WOWkthruFeedbk.getMbo(i).getString("FEEDBK_DTL_LONGDESCRIPTION"),
               MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION);
       	 lblWkthruFeedbk.setValue("FEEDBK_RESP",WOWkthruFeedbk.getMbo(i).getString("FEEDBK_RESP"),
             MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION);
       	 lblWkthruFeedbk.setValue("PERSONID",WOWkthruFeedbk.getMbo(i).getString("PERSONID"),
             MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION);
        	lblWkthruFeedbk.setValue("INITIATE_WO",WOWkthruFeedbk.getMbo(i).getBoolean("INITIATE_WO"),
             MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION);
        } //  for(int i=0; WOWkthruFeedbk.getMbo(i) !=null;i++)
       } if( ! WOWkthruFeedbk.isEmpty())
      if (  WOWkthruFeedbk !=null) {   WOWkthruFeedbk.close(); WOWkthruFeedbk=null;}
	   
	   lblWkThruSet.save();
	   lblWkThruOpsSet.save();
	   lblWkThruHazSet.save();
	   lblWkThruMatSet.save();
	   lblWkThruResSet.save();
	   lblWkthruFeedbkSet.save();
	   
	   Utility.showMessageBox(this.sessionContext.getCurrentEvent(), "Success", "New Walk-through template  "  + strNewWkthruid + " created.", 0);
	   
	   mxLogger.debug("PRB finised writing with walkthruid: " + strNewWkthruid);
       

	  
		
		
    
    
    return EVENT_HANDLED;
  }    
}

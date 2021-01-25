package lblwebui.webclient.beans.wcd;

import java.rmi.RemoteException;
import java.util.HashMap;

import psdi.mbo.MboConstants;
import psdi.mbo.MboRemote;
import psdi.mbo.MboSetRemote;
import psdi.server.MXServer;
import psdi.util.MXException;
import psdi.util.logging.MXLogger;
import psdi.util.logging.MXLoggerFactory;
import psdi.webclient.system.beans.DataBean;
import psdi.webclient.system.controller.AppInstance;
import psdi.webclient.system.controller.Utility;

public class WOWcdCondBean extends DataBean
{
  private MXLogger log;

 public WOWcdCondBean()
  {
          this.log = MXLoggerFactory.getLogger("maximo.application.lblwcdasmt");
 }

  protected void initialize()   throws MXException, RemoteException
    {
	      super.initialize();
	      
	      MboRemote wo = getParent().getMbo();
	      
	      MboSetRemote woWcdConditionSet = wo.getMboSet("LBL_WOWCDCONDITION");
	      	      
	      if (! woWcdConditionSet.isEmpty()) {return; }
	              
	      MboSetRemote wcdConditionSet = MXServer.getMXServer().getMboSet("LBL_WCDCONDITION", wo.getUserInfo());
	      MboSetRemote wcdSubCondSet = null;
	      wcdConditionSet.setWhere("ACTIVE = 1");
	      wcdConditionSet.setOrderBy("conditionnum");
	      wcdConditionSet.reset();
	          
	      MboRemote  wowcdCondition=null;
	      
	     //DataBean wowcdCondBean = this.app.getDataBean("main_table1");
	     // woWcdConditionSet = wowcdCondBean.getMboSet();
	      
	      
	      for (int i = 0; wcdConditionSet.getMbo(i) !=null; i++) 
	       {
	          MboRemote  wcdCondition= wcdConditionSet.getMbo(i);
	          wowcdCondition=woWcdConditionSet.addAtEnd();
	            
	          wowcdCondition.setValue("orgid", wo.getString("orgid"), MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION);
	          wowcdCondition.setValue("siteid", wo.getString("siteid"), MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION);
	          wowcdCondition.setValue("wonum", wo.getString("wonum"), MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION);
	          wowcdCondition.setValue("wcd_level", wcdCondition.getInt("wcd_level"), MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION);
	          wowcdCondition.setValue("LBL_WCDCONDITIONID", wcdCondition.getInt("LBL_WCDCONDITIONID"), MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION);
	          //wowcdCondition.setValue("points",0,MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION);
	          wowcdCondition.setValue("CONDITIONNUM", wcdCondition.getInt("CONDITIONNUM"), MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION);
	          wowcdCondition.setValue("changedate", MXServer.getMXServer().getDate(), MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION);
	          wowcdCondition.setValue("changeby", wo.getUserName(), MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION);
           if (wcdCondition.getBoolean("HASSUBCONDITION")) 
           {
            	 wcdSubCondSet = wcdCondition.getMboSet("LBL_WCDSUBCONDACTIVE");
            	 wcdSubCondSet.setOrderBy("conditionnum, subconditionnum");
            	 wcdSubCondSet.reset();
               if (! wcdSubCondSet.isEmpty()) {
               	for (int j = 0; wcdSubCondSet.getMbo(j) !=null; j++) 
               	{
	                	if (j >0) // Do not add for the first record as it was already added in condition
	                	{
	                		wowcdCondition=woWcdConditionSet.addAtEnd();	      	           
	      	            wowcdCondition.setValue("orgid", wo.getString("orgid"), MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION);
	      	            wowcdCondition.setValue("siteid", wo.getString("siteid"), MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION);
	      	            wowcdCondition.setValue("wonum", wo.getString("wonum"), MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION);
	      	            wowcdCondition.setValue("wcd_level", wcdCondition.getInt("wcd_level"), MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION);
	      	            wowcdCondition.setValue("LBL_WCDCONDITIONID", wcdCondition.getInt("LBL_WCDCONDITIONID"), MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION);
	      	            wowcdCondition.setValue("CONDITIONNUM", wcdCondition.getInt("CONDITIONNUM"), MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION);
	      	            //wowcdCondition.setValue("points",0,MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION);
	      	            wowcdCondition.setValue("changedate", MXServer.getMXServer().getDate(), MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION);
	      		          wowcdCondition.setValue("changeby", wo.getUserName(), MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION);
	                	} // if (j >0)
	                	 wowcdCondition.setValue("LBL_WCDSUBCONDID", wcdSubCondSet.getMbo(j).getString("LBL_WCDSUBCONDID"),
	                			                                   MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION);
	                	 wowcdCondition.setValue("SUBCONDITIONNUM", wcdSubCondSet.getMbo(j).getString("SUBCONDITIONNUM"),
                         MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION);
	                	
	               } // for (int j = 0; wcdSubCondSet.getMbo(j) !=null; j++) 
	             } // if (! wcdSubCondSet.isEmpty())   
	           	} //  if (wcdCondition.getBoolean("HASSUBCONDITION")) 
	          } // for (int i = 0; wcdConditionSet.getMbo(i) !=null; i++)
	      
	      if (wcdConditionSet != null) {wcdConditionSet.close();wcdConditionSet=null;} 
	      	      
	     	if (wcdSubCondSet != null) {	wcdSubCondSet.close();wcdSubCondSet=null;}
	     	
	     	//refreshTable();
	      //reloadTable();
	      
        } // end of method 
  
   }       

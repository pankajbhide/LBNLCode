/*****************************************************************
 *  Java Class File : LBLWOChangeStatusBean.java
 * 
 *  Description     : This class hides all the status values that
 *                    are changed via workflow.
 *                    
 *                    It also prevents non-admin users changing the status
 *                    of the work order beyond <n - defined as system property)
 *                  *  
 *                    The default class is 
 *                    (psdi.webclient.beans.workorder.WOChangeStatusBean)
 *                    
 *                    This requires a jar file psdi_webclient.jar that can be
 *                    prepared by jaring all the resources under  
 *                    $MAX_DIR\applications\maximo\maximouiweb\
 *                    webmodule\WEB-INF\classes
 *  
 *  Author           : Pankaj Bhide
 * 
 * Date written     :  23-DEC-2015
 * 
 * Modification 
 * *********************************************************************************************/

package lblwebui.webclient.beans.workorder;

import java.rmi.RemoteException;
import java.text.DateFormat;
import java.text.SimpleDateFormat;
import java.util.*;

import psdi.app.workorder.WORemote;
import psdi.mbo.*;
import psdi.security.UserInfo;
import psdi.server.MXServer;
import psdi.util.*;
import psdi.util.logging.MXLogger;
import psdi.util.logging.MXLoggerFactory;
import psdi.webclient.beans.common.ChangeStatusBean;
import psdi.webclient.system.beans.DataBean;
import psdi.webclient.system.beans.ResultsBean;
import psdi.webclient.system.controller.*;
 
public class LBLWOChangeStatusBean extends psdi.webclient.beans.workorder.WOChangeStatusBean
{
    
    
    public synchronized MboSetRemote getList(int nRow, String attribute)
                throws MXException, RemoteException
    {
     
     MXLogger mxLogger = MXLoggerFactory.getLogger("maximo.application.WOTRACK");
	
     String strAppname=this.sessionContext.getCurrentApp().getApp();	
     if (strAppname.equalsIgnoreCase("WOTRACK") ||
     	 strAppname.equalsIgnoreCase("FACWOTRACK"))	 
      {    	   	
    	  
       MXServer mxserver=null;
       String strUserid="", strFacAdminusers="";
       
       MboSetRemote currentList=super.getList(nRow,attribute);
      
       strUserid=app.getResultsBean().getMboSet().getUserInfo().getUserName().toUpperCase();
      
       mxserver = MXServer.getMXServer();
       Properties mxProp = mxserver.getConfig();            
       strFacAdminusers = mxProp.getProperty("lbl.fac_admin_logins").toUpperCase();
       
       // Admin users can change any status except WREL
       if (strFacAdminusers !=null && strFacAdminusers.length() >0)
       {
    	  
    	   List<String> list = Arrays.asList(strFacAdminusers.split(","));
    	   if (list.contains(strUserid))  // Fac Admin users 
    	   {
    		  if( ! currentList.isEmpty())
 		      {
 		       for(int i=0; currentList.getMbo(i) !=null;i++)
 		       {
 		           if (currentList.getMbo(i).getString("value").equals("WREL"))
 		           	   currentList.remove(i);
 		       } 		          
 		        
    	     } //if( ! currentList.isEmpty())
    		      		   
    		   return currentList;
    	   }
    	   else
    	   {
    		   // Exclude all status values with description like '%WF% and WREL for non-admin users
			    //currentList.setWhere(" DOMAINID='WOSTATUS' and upper(description) not like '%WF%'");
			    //currentList.reset();
    		   if( ! currentList.isEmpty())
    		      {
    		       for(int i=0; currentList.getMbo(i) !=null;i++)
    		       {
    		           if (currentList.getMbo(i).getString("description").contains("WF") ||
    		        	   currentList.getMbo(i).getString("value").equals("WREL"))
    		           {
    		        	   currentList.remove(i);
    		        	   mxLogger.debug("PRB removed row");
    		           }
    		        	   
    		       } 
    		      }
			    return currentList;
    	   }
        } // if (strFacAdminusers !=null && strFacAdminusers.length() >0)
      }
    
    	 return super.getList(nRow,attribute);
    	 
     
     }
   
} 

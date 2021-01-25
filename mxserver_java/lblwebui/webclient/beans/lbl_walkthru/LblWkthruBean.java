package lblwebui.webclient.beans.lbl_walkthru;


import java.rmi.RemoteException;

import lbl.app.lbl_walkthru.LblWalkthruRemote;
import psdi.webclient.system.beans.*;
import psdi.mbo.MboRemote;
import psdi.server.MXServer;
import psdi.util.MXException;
import psdi.util.logging.FixedLoggerNames;
import psdi.util.logging.MXLogger;
import psdi.util.logging.MXLoggerFactory;
import psdi.webclient.beans.common.StatefulAppBean;
import psdi.webclient.system.beans.DataBean;

import psdi.webclient.system.controller.*;

import psdi.webclient.system.runtime.WebClientRuntime;
import psdi.webclient.system.session.WebClientSession;


  

public class LblWkthruBean extends DataBean {
	
 public int WkthruDup() throws RemoteException, MXException 
  {
       
  	  	
	 MXLogger appLog = MXLoggerFactory.getLogger(FixedLoggerNames.LOGGERNAME_APP + ".TesisUcretSec");
  	 //DataBean appBean = Utility.getDataSource(sessionContext, app.getAppHandler());
  	 
  	
     DataBean appBean = this.app.getAppBean();
   	 appBean.duplicateMbo();
  	 
  	 // LblWalkthruRemote lblWkthru = (LblWalkthruRemote)appBean.getMbo();
  	 // LblWalkthruRemote duplblWkthru=(LblWalkthruRemote) lblWkthru.duplicate();
  		  	    	   	 
  	 
     appBean.save();
      
     // Utility.sendEvent(new WebClientEvent("dialogclose", app.getCurrentPageId(), null, sessionContext));
     WebClientRuntime.sendEvent(new WebClientEvent("dialogclose", this.app.getCurrentPageId(), null, this.clientSession));
      Utility.showMessageBox(sessionContext.getCurrentEvent(), "system", "duprecord", null);
     //   appBean.fireDataChangedEvent();
      sessionContext.queueRefreshEvent();
    
      	    
    return 1;

    	
      }
 
}

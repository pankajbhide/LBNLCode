/*****************************************************************
 *  Java Class File : LBLKeyWoChangeStatusBean.java
 * 
 *  Description     : This class shows only the statuses that are used by lockshop workorder 
 *  				  using domain LBL_LOCKWOSTATUS
 *   				   
 *                    The default class is 
 *                    (psdi.webclient.beans.workorder.WOChangeStatusBean)
 *                    
 *                    Extended Class - LBLWOChangeStatusBean.java
 *  
 *  Author           : Praveen Muramalla
 * 
 * Date written     :  09-DEC-2010
 * 
 * Modification 
 * History          : 
 * *************************************************************/

package lblwebui.webclient.beans.workorder;
import java.rmi.RemoteException;

import psdi.mbo.MboSetRemote;
import psdi.util.MXException;

public class LBLKeyWOChangeStatusBean extends LBLWOChangeStatusBean{

    public LBLKeyWOChangeStatusBean(){
    	super();
    }  
    public synchronized MboSetRemote getList(int nRow, String attribute)
        throws MXException, RemoteException{

    	if(app.getApp().equalsIgnoreCase("LBL_WO")){    		
            MboSetRemote currentList = super.getList(nRow, attribute);
            if(!currentList.isEmpty()){
            	currentList.setWhere(" DOMAINID='WOSTATUS' and value in ( select value from alndomain where domainid = 'LBL_LOCKWOSTATUS')");
//              currentList.reset();
            	currentList.setOrderBy("DESCRIPTION");
            	currentList.reset();
            }
            return currentList;            
        }else{
        	return super.getList(nRow, attribute);
        }
    	
    } 
}

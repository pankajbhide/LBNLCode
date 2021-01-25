package lbl.app.lbl_walkthru; 

import psdi.server.MXServer;
import psdi.util.MXException;
import java.rmi.RemoteException;
import psdi.mbo.MboConstants;
import psdi.mbo.MboRemote;
import psdi.mbo.MboSet;
import psdi.mbo.Mbo;
import psdi.mbo.MboSetRemote;
import psdi.mbo.MboValue;
import psdi.mbo.MboValueInfo;
import psdi.mbo.SqlFormat;
import psdi.util.logging.MXLogger;
import psdi.util.logging.MXLoggerFactory;

public class LblWalkthru extends  psdi.mbo.custapp.CustomMbo implements MboConstants, LblWalkthruRemote {

	final private String APPLOGGER = "maximo.application.LBLWKTHRU";
	private MXLogger log;

	public LblWalkthru(MboSet mboSet0) throws RemoteException, MXException {
		super(mboSet0);
		log = MXLoggerFactory.getLogger(APPLOGGER);
	} 
	
	
  
 
	 
	 // Duplicate walk-through
	 public MboRemote duplicate() throws MXException, RemoteException
   {
		 
		 
		 String strOrigwalkthruid=this.getString("wkthruid");
		 MboRemote dupLblWalkthru = copy();
		 String strWkthruid=dupLblWalkthru.getString("wkthruid");
		 
		 
		 MboRemote newRecord=null;
		 MboSetRemote mbosetremote1=null;
		 
		 // Copy walk-through hazards
	   
	 SqlFormat sqlformat =null;
	 
	 		 
	 sqlformat = new SqlFormat(getUserInfo(), "siteid=:1 and wkthruid = :2 " );
     sqlformat.setObject(1, "LBL_WKTHRUHAZ", "SITEID",this.getString("siteid"));         
     sqlformat.setObject(2, "LBL_WKTHRUHAZ", "WKTHRUID",strOrigwalkthruid);
                     
     mbosetremote1 = getMboSet("LblWalkthru_duplicate_wkthruhazard", "LBL_WKTHRUHAZ", sqlformat.format());
     
     
     if(! mbosetremote1.isEmpty())
     {
     
    	
    	
	    MboSetRemote newdupSet1=this.getMboSet("LBL_WKTHRU2WKTHHAZ"); 

	    
	   for(int i=0; mbosetremote1.getMbo(i) !=null;i++)
       {
	  	    newRecord=newdupSet1.add(); 
    	 	newRecord.setValue("orgid", mbosetremote1.getMbo(i).getString("orgid"), MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION);
     		newRecord.setValue("siteid", mbosetremote1.getMbo(i).getString("siteid"), MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION);
     		newRecord.setValue("hazardid", mbosetremote1.getMbo(i).getString("hazardid"), MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION);
     		newRecord.setValue("wkthruid",strWkthruid, MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION);    
     		newRecord.setValue("changedate", MXServer.getMXServer().getDate(), MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION);
     		newRecord.setValue("changeby", getUserName(), MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION);
     	} // for(int i=0; mbosetremote1(i) !=null;i++)
	   
     }  //  if(! mbosetremote1.isEmpty())
    
	   // Copy walk-through materials
     
     sqlformat = new SqlFormat(getUserInfo(), "siteid=:1 and wkthruid = :2 " );
     sqlformat.setObject(1, "LBL_WKTHRUMAT", "SITEID",this.getString("siteid"));         
     sqlformat.setObject(2, "LBL_WKTHRUMAT", "WKTHRUID",strOrigwalkthruid);
                     
     mbosetremote1 = getMboSet("LblWalkthru_duplicate_wkthrumat", "LBL_WKTHRUMAT", sqlformat.format());
     
               
     if(! mbosetremote1.isEmpty())
     {
     
	    MboSetRemote newdupSet1=this.getMboSet("LBL_WKTHRU2WKTHMAT"); 
	   	   
	   for(int i=0; mbosetremote1.getMbo(i) !=null;i++)
     {
    		newRecord=newdupSet1.add(); //
     		newRecord.setValue("orgid", mbosetremote1.getMbo(i).getString("orgid"), MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION);
     		newRecord.setValue("siteid", mbosetremote1.getMbo(i).getString("siteid"), MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION);
     		newRecord.setValue("itemnum", mbosetremote1.getMbo(i).getString("itemnum"), MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION);
     		newRecord.setValue("LOCATION_INFO", mbosetremote1.getMbo(i).getString("LOCATION_INFO"), MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION);
     		newRecord.setValue("wkthruid",strWkthruid, MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION);    
     		newRecord.setValue("changedate", MXServer.getMXServer().getDate(), MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION);
     		newRecord.setValue("changeby", getUserName(), MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION);
     		newRecord.setValue("quantity",mbosetremote1.getMbo(i).getDouble("quantity"),  
            MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION);
     		newRecord.setValue("ITEMDESCRIPTION",mbosetremote1.getMbo(i).getString("ITEMDESCRIPTION"),  
            MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION);
     		newRecord.setValue("ITEMDESCRIPTION_LONGDESCRIPTION",mbosetremote1.getMbo(i).getString("ITEMDESCRIPTION_LONGDESCRIPTION"),  
            MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION);        
    	} // for(int i=0; newdupSet.getMbo(i) !=null;i++)
     }  //   if(! mbosetremote1.isEmpty())
     
     
	    // Copy walk-through operations
     
     sqlformat = new SqlFormat(getUserInfo(), "siteid=:1 and wkthruid = :2 " );
     sqlformat.setObject(1, "LBL_WKTHRUOPS", "SITEID",this.getString("siteid"));         
     sqlformat.setObject(2, "LBL_WKTHRUOPS", "WKTHRUID",strOrigwalkthruid);
                     
     mbosetremote1 = getMboSet("LblWalkthru_duplicate_wkthruops", "LBL_WKTHRUOPS", sqlformat.format());
                    
     if(! mbosetremote1.isEmpty())
     {
       
       MboSetRemote newdupSet1= this.getMboSet("LBL_WKTHRU2WKTHOPS");
	     for(int i=0; mbosetremote1.getMbo(i) !=null;i++)
       {
   	  	newRecord=newdupSet1.add(); //
    		newRecord.setValue("orgid", mbosetremote1.getMbo(i).getString("orgid"), MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION);
    		newRecord.setValue("siteid", mbosetremote1.getMbo(i).getString("siteid"), MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION);
    		newRecord.setValue("description",mbosetremote1.getMbo(i).getString("description"),  
                                         MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION);
    		newRecord.setValue("DESCRIPTION_LONGDESCRIPTION",mbosetremote1.getMbo(i).getString("DESCRIPTION_LONGDESCRIPTION"),  
                                        MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION);
     		newRecord.setValue("wkthruid",strWkthruid, MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION);    
    		newRecord.setValue("OPSEQUENCE",mbosetremote1.getMbo(i).getInt("OPSEQUENCE"),  
                                        MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION);
    		newRecord.setValue("OPDURATION",mbosetremote1.getMbo(i).getDouble("OPDURATION"),  
                                        MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION);
    		
    		newRecord.setValue("CRAFT",mbosetremote1.getMbo(i).getString("CRAFT"),  
                    MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION);
    		
    		newRecord.setValue("quantity",mbosetremote1.getMbo(i).getInt("quantity"),  
                    MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION);
	   } //   for(int i=0; mbosetremote1.getMbo(i) !=null;i++)
   } //  if(! mbosetremote1.isEmpty())
     
	   
	   // Copy walk-through resources
     sqlformat = new SqlFormat(getUserInfo(), "siteid=:1 and wkthruid = :2  and resource_type is not null" );
     sqlformat.setObject(1, "LBL_WKTHRURES", "SITEID",this.getString("siteid"));         
     sqlformat.setObject(2, "LBL_WKTHRURES", "WKTHRUID",strOrigwalkthruid);
                     
     mbosetremote1 = getMboSet("LblWalkthru_duplicate_wkthrures", "LBL_WKTHRURES", sqlformat.format());
     
                   
     if(! mbosetremote1.isEmpty())
     {
    	 MboSetRemote newdupSet1= this.getMboSet("LBL_WKTHRU2WKTHRES_ALL");
	    for(int i=0; mbosetremote1.getMbo(i) !=null;i++)
      {
   	  	newRecord=newdupSet1.add(); //
    		newRecord.setValue("orgid", mbosetremote1.getMbo(i).getString("orgid"), MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION);
    		newRecord.setValue("siteid", mbosetremote1.getMbo(i).getString("siteid"), MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION);
    		newRecord.setValue("resource_type",mbosetremote1.getMbo(i).getString("resource_type"),  
                                         MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION);
    		newRecord.setValue("wkthruid",strWkthruid, MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION); 
    		newRecord.setValue("SEQUENCE",mbosetremote1.getMbo(i).getInt("SEQUENCE"),  
                                         MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION);
    		newRecord.setValue("EHS_SUPPORT",mbosetremote1.getMbo(i).getString("EHS_SUPPORT"),  
                                        MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION);
    		newRecord.setValue("EHS_SUPPORT_COMMENTS",mbosetremote1.getMbo(i).getString("EHS_SUPPORT_COMMENTS"),  
                                       MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION);
    		// JIRA EF-4443
    		newRecord.setValue("ehs_support_cont",mbosetremote1.getMbo(i).getString("ehs_support_cont"),  
                    MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION);
    		// JIRA EF-6856
			newRecord.setValue("PERMIT_NUMBER",mbosetremote1.getMbo(i).getString("PERMIT_NUMBER"),  
                                       MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION);
    		newRecord.setValue("PERMITS",mbosetremote1.getMbo(i).getString("PERMITS"),  
                                       MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION);
			newRecord.setValue("PERMIT_RESPONSIBLE_INDIVIDUAL",mbosetremote1.getMbo(i).getString("PERMIT_RESPONSIBLE_INDIVIDUAL"),  
                                       MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION);
    		newRecord.setValue("PERMITS_COMMENTS",mbosetremote1.getMbo(i).getString("PERMITS_COMMENTS"),  
                                        MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION);
			newRecord.setValue("PERMITS_COMMENTS_LONGDESCRIPTION",mbosetremote1.getMbo(i).getString("PERMITS_COMMENTS_LONGDESCRIPTION"),  
                                        MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION);
			//							
    		newRecord.setValue("DRAWINGS",mbosetremote1.getMbo(i).getString("DRAWINGS"),  
                                        MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION);
    		newRecord.setValue("DRAWINGS_COMMENTS",mbosetremote1.getMbo(i).getString("DRAWINGS_COMMENTS"),  
                                        MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION);
    		newRecord.setValue("CRAFT",mbosetremote1.getMbo(i).getString("CRAFT"),  
                                       MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION);
    		newRecord.setValue("CRAFT_DURATION",mbosetremote1.getMbo(i).getString("CRAFT_DURATION"),  
                                       MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION);
       		newRecord.setValue("RES_DURATION",mbosetremote1.getMbo(i).getString("res_duration"),  
    	            MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION);
    		newRecord.setValue("PLAN_TEAM_DESC",mbosetremote1.getMbo(i).getString("PLAN_TEAM_DESC"),  
    	            MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION);
    		newRecord.setValue("PLAN_TEAM_DURATION",mbosetremote1.getMbo(i).getString("PLAN_TEAM_DURATION"),  
    	            MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION);  
    		
    		newRecord.setValue("CRAFT_COMMENTS",mbosetremote1.getMbo(i).getString("CRAFT_COMMENTS"),  
                                      MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION);
    		newRecord.setValue("PERSONID",mbosetremote1.getMbo(i).getString("PERSONID"),  
            MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION);
    		newRecord.setValue("PERSON_FUNCTION",mbosetremote1.getMbo(i).getString("PERSON_FUNCTION"),  
            MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION);
    		newRecord.setValue("PERSON_PHONE",mbosetremote1.getMbo(i).getString("PERSON_PHONE"),  
            MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION);
    		
      } //    for(int i=0; mbosetremote1.getMbo(i) !=null;i++)
    }  //  if(! mbosetremote1.isEmpty())
     
     // Copy walk-through feedback
     sqlformat = new SqlFormat(getUserInfo(), "siteid=:1 and wkthruid = :2  " );
     sqlformat.setObject(1, "LBL_WKTHRUFEEDBK", "SITEID",this.getString("siteid"));         
     sqlformat.setObject(2, "LBL_WKTHRUFEEDBK", "WKTHRUID",strOrigwalkthruid);
                     
     mbosetremote1 = getMboSet("LblWalkthru_duplicate_wkthrufeed", "LBL_WKTHRUFEEDBK", sqlformat.format());
     
                   
     if(! mbosetremote1.isEmpty())
     {
    	 MboSetRemote newdupSet1= this.getMboSet("LBL_WKTHRU2FEEDBK");
	    for(int i=0; mbosetremote1.getMbo(i) !=null;i++)
      {
   	  	newRecord=newdupSet1.add(); //
    		newRecord.setValue("orgid", mbosetremote1.getMbo(i).getString("orgid"), MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION);
    		newRecord.setValue("siteid", mbosetremote1.getMbo(i).getString("siteid"), MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION);
    		newRecord.setValue("wkthruid",strWkthruid,  
                                         MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION);
    		newRecord.setValue("feedbk_dtl",mbosetremote1.getMbo(i).getString("feedbk_dtl"),  
                    MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION);
    		
    		newRecord.setValue("feedbk_resp",mbosetremote1.getMbo(i).getString("feedbk_resp"),  
                    MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION);

    		newRecord.setValue("personid",mbosetremote1.getMbo(i).getString("personid"),  
                    MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION);

    		newRecord.setValue("initiate_wo",mbosetremote1.getMbo(i).getBoolean("initiate_wo"),  
                    MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION);
      }	
     }
     
	   	  
		 return   dupLblWalkthru;
   }

public void delete(long accessModifier) throws MXException, RemoteException
{	    
    

	MboSetRemote delSet=this.getMboSet("LBL_WKTHRU2WKTHHAZ");
	
	if (! delSet.isEmpty())
		delSet.deleteAll(2L);
	
	delSet=this.getMboSet("LBL_WKTHRU2WKTHHAZ");
	if (! delSet.isEmpty())
		delSet.deleteAll(2L);
	
	delSet=this.getMboSet("LBL_WKTHRU2WKTHMAT");
	if (! delSet.isEmpty())
		delSet.deleteAll(2L);
	
	delSet=this.getMboSet("LBL_WKTHRU2WKTHOPS");
	if (! delSet.isEmpty())
		delSet.deleteAll(2L);
	
	delSet=this.getMboSet("LBL_WKTHRU2WKTHRES_ALL");
	if (! delSet.isEmpty())
		delSet.deleteAll(2L);

	super.delete(accessModifier);

}
	 
protected boolean skipCopyField(MboValueInfo mvi)   throws RemoteException, MXException
{
    if(mvi.getName().equalsIgnoreCase("wkthruid"))
         return true;
    else
    return false;
}

}//class 
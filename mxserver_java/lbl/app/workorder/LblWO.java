package lbl.app.workorder;
/*************************************************************************
*  Java Class File : LblWO.java
* 
*  Description     : Extended JAVA class of IBM delivered WO.class
*                    framework class
*
*  
*  Author           : Pankaj Bhide
* 
* Date written      : August 18, 2015 
* 
*                     Aug 5 2019 Pankaj - Deleted from wosafetylink if the 
*                     corresponding hazard does not exist in safetylexicon
* 	
* 				      Feb 29, 2020 Pankaj - Added a new method that allows
*                     sending email (with HTML body) and attachments.
* 
* 
* Purpose           : Original class=psdi.app.workorder.WOSet 
* ****************************************************************************/

import java.rmi.*; 
import java.text.DateFormat;
import java.text.SimpleDateFormat;
import java.util.*;

import psdi.server.MXServer;
import psdi.util.*;
import psdi.util.logging.MXLogger;
import psdi.util.logging.MXLoggerFactory;
import psdi.workflow.WorkFlowServiceRemote;
import psdi.mbo.*;
import psdi.app.workorder.*;

import javax.activation.DataHandler;
import javax.activation.DataSource;
import javax.activation.FileDataSource;
import javax.mail.BodyPart;
import javax.mail.Message;
import javax.mail.Multipart;
import javax.mail.Session;
import javax.mail.Transport;
import javax.mail.internet.InternetAddress;
import javax.mail.internet.MimeBodyPart;
import javax.mail.internet.MimeMessage;
import javax.mail.internet.MimeMultipart;


public class LblWO extends WO implements MboConstants,LblWORemote {
  
  
    final private String APPLOGGER = "maximo.service.WORKORDER"; 
	private MXLogger log;

  
 public LblWO(MboSet ms) throws MXException,RemoteException
   {
        super(ms);    	
	    log = MXLoggerFactory.getLogger(APPLOGGER);
	} 

//*******************************************************************
// Method to populate the records into wohazard collection
// based on the hazards associated with the location
// and work control hazard specified in the work order
//*******************************************************************
synchronized public void custom_trigger_safety_components()
                                   throws MXException, RemoteException
{
     log.debug("PRB Enetered into custom trigger method");
	 MboRemote newWosafetylink=null ;
	 String strHazardid=null,strSource=null,strSafetyplanid=null;
	   
	
   //***************************************************
   // If work order is duplicated, the framework will 
   // duplicate hazards from the base work order. 
   // Therefore, do not copy them using this custom class.
   //***************************************************
	 
   
    
   if  (super.getDuplicated() && isNew())
   	return;
         
   strSafetyplanid=getString("SAFETYPLANID");
   if (strSafetyplanid != null &&  strSafetyplanid.length() >0)
	    return;

   
   /*********************************************************************
     Create a new hash table that will contain hazards to be
     attached to the work order.

	 The hash table's key would be the hazardid and its associated
     data element would be the source from which the hazard is
     captured (e.g. LBL - if it has been copied using the
     custom class 
    *********************************************************************/ 

     Hashtable setHazards= new Hashtable();

    // The value=LBL in the column titled "LBL_WOSL01" indicates
    // that the hazard is added via custom class, else manually
    // entered by the user 

    // Populate hash table with the hazards associated with 
    // the location specified in the work order
     log.debug("PRB About to find out hazard for location ");
     
    setHazards=custom_populate_safety_ht(getString("orgid"),getString("siteid"),
    		   getString("wonum"),getString("location"), getString("assetnum"),
    		   setHazards);
    
     WoSafetyLinkSetRemote mbowosafetylinkSet=(WoSafetyLinkSetRemote)
     this.getMboSet(WOSetRemote.WOSAFETYLINK);

     // Now add the rows from the hash table to wosafetylink collection
     log.debug("PRB size of Hazardset: " + setHazards.size());
     
     if(setHazards.size() >0)
     {
   	    Vector v = new Vector(setHazards.keySet());
   	    Collections.sort(v);
   	    for (Enumeration e = v.elements(); e.hasMoreElements();)
   	    {
   	      strHazardid= (String)e.nextElement();
   		  strSource  = (String)setHazards.get(strHazardid);
   		  
   		  log.debug("PRB hazardid: " + strHazardid);
   		  log.debug("PRB source: "   + strSource);
   		  

   		  if (strSource !=null )
   		  {
    		/*****************************************************************
   			 Process only non-tagout enabled hazards in this phase
   			****************************************************************/
   		    // Derive other values from hazard table

	        String strWhere2    ="  orgid=:1 ";
  	               strWhere2   +="  and hazardid=:2 ";
  	       SqlFormat sqlformat = new SqlFormat(getUserInfo(), strWhere2);
  	       sqlformat.setObject(1, "HAZARD", "orgid", getString("orgid"));
  	       sqlformat.setObject(2, "HAZARD", "hazardid", strHazardid);

           String strLink="Lbl_custom_insert_wohazard_save_hazard_" + strHazardid;

           MboSetRemote mbohazardSet	= getMboSet(strLink,"HAZARD",
           		                                    sqlformat.format());  	              	       
   	       // Do not participate in transaction management
   	       mbohazardSet.setFlag(MboConstants.DISCARDABLE,true);

   	       if(! mbohazardSet.isEmpty())  
   	       {
   	    	  log.debug("PRB Hazard found in hazard table");
   	    	  
   	        if (! mbohazardSet.getMbo(0).getBoolean("TAGOUTENABLED"))
   	         {
   	            // Insert only if hazard does not exist in the collection
    	         if (! doesHazardExist(strHazardid, mbowosafetylinkSet))
    	         {
    	           // Insert a new row into wosafetylink collection
          		   newWosafetylink=mbowosafetylinkSet.add(); // add new empty record

          		   newWosafetylink.setValue("orgid", getString("orgid"),
          		  		                                     MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION);
          		   newWosafetylink.setValue("siteid", getString("siteid"),
          		  		                                     MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION);
          		   newWosafetylink.setValue("wonum", getString("wonum"),
          		  		                                     MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION);
          		   newWosafetylink.setValue("hazardid", strHazardid,
          		  		                                      MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION);
          		            		   
          		   newWosafetylink.setValue("lbl_wosl01",strSource,
          		  		                                      MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION);

          		  log.debug("PRB added record for hazard  "   + strHazardid + " in wosafetylink");  		
          		   // Get access to WOHAZARD collection
          		   WoHazardSetRemote wohazardSet2= (WoHazardSetRemote)
          		                    newWosafetylink.getMboSet(WoSafetyLinkSetRemote.WOHAZARD);
          		
          		   // Insert into wohazard collection      	 
          	       MboRemote newWohazard=wohazardSet2.add(); // add new empty record

          	       newWohazard.setValue("orgid",  getString("orgid"), MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION);
          	       newWohazard.setValue("siteid", getString("siteid"), MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION);
          	       newWohazard.setValue("wonum", getString("wonum"), MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION);
          	       newWohazard.setValue("hazardid", strHazardid, MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION);
          	       newWohazard.setValue("LBL_HAZ01","LBL",MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION);

          	       newWohazard.setValue("haz20", "N", MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION);
    		      		  
    	           newWohazard.setValue("PRECAUTIONENABLED",
    	                                                  mbohazardSet.getMbo(0).getBoolean("PRECAUTIONENABLED"),
    	                                                  MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION);
    	           newWohazard.setValue("HAZMATENABLED",
    	                                                  mbohazardSet.getMbo(0).getBoolean("HAZMATENABLED"),
    	                                                  MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION);
    	           newWohazard.setValue("TAGOUTENABLED",
    	                                                   mbohazardSet.getMbo(0).getBoolean("TAGOUTENABLED"),
    	                                                   MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION);

    	           log.debug("PRB added record for hazard  "   + strHazardid + " in wohazard");   

    	             
    	           } //  if (! doesHazardExist(strHazardid, mbowosafetylinkSet))
    	        } //     if (! mbohazardSet.getMbo(0).getBoolean("TAGOUTENABLED"))
    	       } //  if(! mbohazardSet.isEmpty())

   	       if (mbohazardSet !=null) { mbohazardSet.close(); mbohazardSet=null; } 

   	    } // if (strSource !=null)

 	   }  //  for (Enumeration e = v.elements(); e.hasMoreElements();

  	      if (v !=null ) { v=null;}
      } // if( setHazards.size() >0)

         // Do not close set created via relationship
         //if (mbowosafetylinkSet !=null ) { mbowosafetylinkSet.close(); mbowosafetylinkSet=null;}

         if (setHazards !=null) { setHazards=null;}


         //*******************************
         // BringTAGOUT ENABLED
         // hazards to the work order
         //*******************************
         
    

       	 LblCopyLOTOHazards();

   
        //*****************************************************************
        // Delete unwanted hazard records from wosafetylink table
        //*****************************************************************

         LblSyncWOSafety(getString("orgid"), getString("siteid"), getString("wonum"),
        		         getString("location"), getString("assetnum"));     		    		                        

 
     
   }  // end of method custom_trigger_safety_components

	/***************************************************
	  Attach safety components to hash table based on 
	  the location and value of work control hazard.
	 ***********************************************/
		public  Hashtable custom_populate_safety_ht(String strOrgid, 
				                         String strSiteid,
				                         String strWonum,
		                                 String strLocation,
		                                 String strAssetnum,                                   
		                                 Hashtable setHazards)
		       throws RemoteException, MXException 
		{
		   String strWhere;  
		/********************************************************************
		  Get non tagoutenabled hazards from SAFETYLEXICON
		  for the given location and add this to setHazards
		 ********************************************************************/
		
			strWhere   =" siteid=:1 "; 
			strWhere +=" and (location=:2 "; // As per index
			strWhere +=" or assetnum=:4 )" ;
			strWhere +=" and orgid=:3 " ;
			strWhere +=" and hazardid in ";
			strWhere +=" (select distinct b.hazardid from hazard b where b.tagoutenabled=0) ";
			
			SqlFormat sqlformat = new SqlFormat(getUserInfo(), strWhere);
			sqlformat.setObject(1, "SAFETYLEXICON", "siteid", strSiteid);
			sqlformat.setObject(2, "SAFETYLEXICON", "location", strLocation);
			sqlformat.setObject(3, "SAFETYLEXICON", "orgid", strOrgid);
			sqlformat.setObject(4, "SAFETYLEXICON", "assetnum", strAssetnum);
			
			 
			String strLink="Lbl_custom_populate_safety_ht_sfc1_"  + strLocation;
			
			 MboSetRemote mbosafetylexiconSet=getMboSet(strLink, "SAFETYLEXICON",sqlformat.format());
			// Do not participate in transaction management
			mbosafetylexiconSet.setFlag(MboConstants.DISCARDABLE,true);
			
			if(! mbosafetylexiconSet.isEmpty())
			{
				 for(int i=0; mbosafetylexiconSet.getMbo(i) !=null; i++)
			    {
					// if hazard is not added to the set, then, add the hazard
					// to the set
			
			 	    if (! setHazards.containsKey((String) mbosafetylexiconSet.getMbo(i).getString("hazardid")))
			 	         	    	setHazards.put(mbosafetylexiconSet.getMbo(i).getString("hazardid"),"LBL");
				     }//  for(int i=0; mbosafetylexiconSet.getMbo(i) !=null; i++)
			}   //if(! mbosafetylexiconSet.isEmpty())
			if (mbosafetylexiconSet !=null) { mbosafetylexiconSet.close(); mbosafetylexiconSet=null; } 
			
			return setHazards;
			} // end of method
			
	/******************************************************************************
	  Method to check whether the hazard exists in the collection or not.
	 ******************************************************************************/
	 boolean doesHazardExist(String strHazard, MboSetRemote mboCollection)
	                 throws RemoteException, MXException
	  {
	
	 	boolean boolReturn=false;
	
	 	for(int i=0; mboCollection.getMbo(i) !=null; i++)
	 	{
	 		 if (! mboCollection.getMbo(i).toBeDeleted())
	 		 {
	 			 if (mboCollection.getMbo(i).getString("hazardid").equals(strHazard))
	 			 {
	 				 boolReturn=true;
	 			   break;
	 			 } // if (mboCollection.getMbo(i).getString("hazardid").equals(strHazard))
	 		 } // if (! mboCollection.getMbo(i).toBeDeleted())
	
	 	} // for(int i=0; mboCollection.getMbo(i) !=null; i++)
	
		  return boolReturn;
	
	  } // end of method

 //*****************************************************************
 // Delete unwanted hazard records from wosafetylink table
 //*****************************************************************
 public void LblSyncWOSafety(String strOrgid,
                             String strSiteid,
                             String strWonum,
                             String strLocation,
                             String strAssetnum
 		                                         )
                  throws RemoteException, MXException
 {

   
   WoSafetyLinkSetRemote mboWoSafetylinkSet=(WoSafetyLinkSetRemote)
   this.getMboSet(WOSetRemote.WOSAFETYLINK);


 	if (! mboWoSafetylinkSet.isEmpty())
 	{
     for(int i=0; mboWoSafetylinkSet.getMbo(i) !=null ; i++)
     {

  	 		 if (! mboWoSafetylinkSet.getMbo(i).toBeDeleted() &&
  				mboWoSafetylinkSet.getMbo(i).getString("lbl_wosl01").equals("LBL"))
  		    {

  		   	 String strWhere   =" siteid=:1 ";
                    strWhere          += " and (location=:2 ";
                    strWhere          +="  or assetnum=:3)  ";
                    strWhere          +=" and hazardid=:4 ";
          SqlFormat sqlformat = new SqlFormat(getUserInfo(), strWhere);

           sqlformat.setObject(1, "SAFETYLEXICON", "siteid",  mboWoSafetylinkSet.getMbo(i).getString("siteid"));
           sqlformat.setObject(2, "SAFETYLEXICON", "location",strLocation);
           sqlformat.setObject(3, "SAFETYLEXICON", "assetnum", strAssetnum);
           sqlformat.setObject(4, "SAFETYLEXICON", "hazardid", mboWoSafetylinkSet.getMbo(i).getString("hazardid"));

          String    strLink2    ="LblSyncWOSafety_safetylexicon" +  "_" +  mboWoSafetylinkSet.getMbo(i).getString("location") + "_";
                    strLink2  +=mboWoSafetylinkSet.getMbo(i).getString("assetnum") + "_";;
                    strLink2  +=mboWoSafetylinkSet.getMbo(i).getString("hazardid") ;

            MboSetRemote mbosafetylexiconSet=getMboSet(strLink2, "SAFETYLEXICON",sqlformat.format());

               //  Do  not participate in transaction management
              mbosafetylexiconSet.setFlag(MboConstants.DISCARDABLE,true);
              
             if ( mbosafetylexiconSet.isEmpty())
             {

             	mboWoSafetylinkSet.getMbo(i).delete(MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION);

              } // if ( mbosafetylexiconSet.isEmpty())

             // Delete unwanted tagout enabled hazards that might have been associated with different
             // asset
             if (mboWoSafetylinkSet.getMbo(i).getString("assetnum") !=null &&
             		mboWoSafetylinkSet.getMbo(i).getString("assetnum").length() > 0 &&
             		! mboWoSafetylinkSet.getMbo(i).getString("assetnum").equals(strAssetnum))
             {

             	mboWoSafetylinkSet.getMbo(i).delete(MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION);
             }

             if (mbosafetylexiconSet !=null) { mbosafetylexiconSet.close(); mbosafetylexiconSet=null; }

  		    } // if (! mboWoSafetylink.getMbo(i).toBeDeleted() &&
  		     // mboWoSafetylink.getMbo(i).getString("lbl_wosl01").equals("LBL"))
    } // if (! mboWoSafetylinkSet.isEmpty())
   } // for(int i=0; mboWoSafetylink.getMbo(i) !=null; i++)

 	if (mboWoSafetylinkSet !=null) { mboWoSafetylinkSet.close(); mboWoSafetylinkSet=null;}
 	
 } // end of method

	 /***************************************************************************
	 Attach LOTO hazards to the work order based upon the value of
	 assetnum specified on the work order
	***************************************************************************/
	public  void LblCopyLOTOHazards() throws RemoteException, MXException
	{
	
	  String strWhere;
	  MboRemote newWosafetylink=null;
	  String strSiteid=getString("siteid");
	  String strOrgid=getString("orgid");
	  String strAssetnum=getString("assetnum");
	  String strWonum=getString("wonum");
	
	  
	  //Create an ArrayList object for tagouts
	  ArrayList arrayListTagout = new ArrayList();
	
	
	  WoSafetyLinkSetRemote mbowosafetylinkSet=(WoSafetyLinkSetRemote)
	                        this.getMboSet(WOSetRemote.WOSAFETYLINK);
	
	  //*************************************************************
	  // Get tagoutenabled hazards from SAFETYLEXICON
	  // for the given assetnum
	  // and the tagout hazards explicitly recorded by the user
	  //*************************************************************
	
	  strWhere   =" siteid=:1 ";
	  strWhere +=" and assetnum=:2 "; // As per index
	  strWhere +=" and orgid=:3 " ;
	  strWhere +=" and hazardid in ";
	  strWhere +=" (select distinct b.hazardid from hazard b where b.tagoutenabled=1) ";
	
	
	  SqlFormat sqlformat = new SqlFormat(getUserInfo(), strWhere);
	  sqlformat.setObject(1, "SAFETYLEXICON", "siteid", strSiteid);
	  sqlformat.setObject(2, "SAFETYLEXICON", "assetnum", strAssetnum);
	  sqlformat.setObject(3, "SAFETYLEXICON", "orgid", strOrgid);
	
	  String strLink="LblCopyLOTOHazard_SFLexicon" +  "_" + strAssetnum;
	  MboSetRemote mbosafetylexiconSet=getMboSet(strLink, "SAFETYLEXICON",sqlformat.format());
	
	   // Do not participate in transaction management
	  mbosafetylexiconSet.setFlag(MboConstants.DISCARDABLE,true);
	
	  if(! mbosafetylexiconSet.isEmpty())
	  {
	 	 for(int i=0; mbosafetylexiconSet.getMbo(i) !=null; i++)
	 	 {
	
	 	   /**********************************************************
	 	 	Insert a new row into WOSAFETYLINK collection
	 		for LOTO Hazard
	 	    ***********************************************************/
	
	    // Insert only if hazard does not exist in the collection
	
	 	String strHazardid=mbosafetylexiconSet.getMbo(i).getString("hazardid");
	 	String strTagoutid=mbosafetylexiconSet.getMbo(i).getString("tagoutid");
	    String strAsset= mbosafetylexiconSet.getMbo(i).getString("assetnum");
	
	    if (strHazardid==null || strHazardid.length() ==0)
	    	strHazardid="_";
	
	    if (strTagoutid==null || strTagoutid.length() ==0)
	    	strTagoutid="_";
	
	    if (strAsset==null || strAsset.length() ==0)
	    	strAsset="_";
	
	
	    if (! doesHazardTagoutExist(strHazardid,
	                                strTagoutid,
	                                strAsset,
	    		                    mbowosafetylinkSet))
	    {
			   newWosafetylink=mbowosafetylinkSet.add(); // add new empty record
	
			   newWosafetylink.setValue("orgid", strOrgid, MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION);
			   newWosafetylink.setValue("siteid", strSiteid, MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION);
			   newWosafetylink.setValue("wonum", strWonum, MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION);
			   newWosafetylink.setValue("hazardid",  mbosafetylexiconSet.getMbo(i).getString("hazardid"),
	  		                                                        MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION);
			   newWosafetylink.setValue("tagoutid", mbosafetylexiconSet.getMbo(i).getString("tagoutid"),
	                                                              MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION);
			   newWosafetylink.setValue("applyseq",mbosafetylexiconSet.getMbo(i).getString("applyseq"),
	                                                              MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION);
			   newWosafetylink.setValue("removeseq",mbosafetylexiconSet.getMbo(i).getString("removeseq"),
	                                                              MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION);
	
			   newWosafetylink.setValue("assetnum",mbosafetylexiconSet.getMbo(i).getString("assetnum"),
			                                                   	  MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION);
	
			   newWosafetylink.setValue("tagoutassetnum",mbosafetylexiconSet.getMbo(i).getString("assetnum"),
	     	  MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION);
	
			   //newWosafetylink.setValue("wosafetydatasource","WO",MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION);
			   newWosafetylink.setValue("lbl_wosl01", "LBL",
			  		                                     MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION);
			   newWosafetylink.setValue("lbl_wosl02","LBL",  MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION);
	
	
		    if( mbosafetylexiconSet.getMbo(i).getString("assetnum") !=null &&
			 		 mbosafetylexiconSet.getMbo(i).getString("assetnum").length() > 0)
	          {
			  	   MboSetRemote assetSet = null;
		           MboRemote assetMbo = null;
	
	         SqlFormat sqf = new SqlFormat(getUserInfo(), "assetnum = :1 and siteid=:2");
	         sqf.setObject(1, "asset", "assetnum", mbosafetylexiconSet.getMbo(i).getString("assetnum"));
	         sqf.setObject(2, "asset", "siteid", strSiteid);
	         assetSet = getMboSet("LBL_getasset", "asset", sqf.format());
	         if(assetSet != null && !assetSet.isEmpty())
	           assetMbo = assetSet.getMbo(0);
	         if(assetMbo != null)
	         {
	        	 newWosafetylink.setValue("assetdescription", assetMbo.getString("description"),
	        			 MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION);
	        	 newWosafetylink.setValue("tagoutassetdescription", assetMbo.getString("description"),
	        			 MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION);
	
	        	 newWosafetylink.setValue("assetdescription_longdescription", assetMbo.getString("description_longdescription"),
	        			 MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION);
	        	 newWosafetylink.setValue("tagoutassetdescription_longdescription", assetMbo.getString("description_longdescription"),
	        			 MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION);
	         }
	         if (assetSet !=null) { assetSet.close(); assetSet=null; }
	     }  // valid asset number
	
	      else // if assetnum is null
	      {
	      	 newWosafetylink. setValueNull("assetdescription",
	      			 MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION);
	      	 newWosafetylink. setValueNull("tagoutassetdescription",
	      			 MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION);
	      	 newWosafetylink. setValueNull("tagoutassetdescription_longdescription",
	      			 MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION);
	       } // end of else
	
	
			/*************************************************
			  Insert into WOHAZARD collection (LOTO)
			*************************************************/
			String strWhere2=null;
	
			if (mbosafetylexiconSet.getMbo(i).getString("tagoutid") !=null &&
			  		mbosafetylexiconSet.getMbo(i).getString("tagoutid").length() > 0)
			 {
			    // Get access to WOHAZARD collection
			     WoHazardSetRemote wohazardSet2= (WoHazardSetRemote)
			                     newWosafetylink.getMboSet(WoSafetyLinkSetRemote.WOHAZARD);
	
			    if ( ! doesHazardExist(mbosafetylexiconSet.getMbo(i).getString("hazardid"),
			      		 wohazardSet2) )
			     {
	
		       MboRemote newWohazard=wohazardSet2.add(); // add new empty record
	
		       newWohazard.setValue("orgid", strOrgid, MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION);
		       newWohazard.setValue("siteid", strSiteid, MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION);
		       newWohazard.setValue("wonum", strWonum, MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION);
		       newWohazard.setValue("hazardid", mbosafetylexiconSet.getMbo(i).getString("hazardid"),
		      		                                               MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION);
		        newWohazard.setValue("LBL_HAZ01","LBL",MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION);
		      // newWohazard.setValue("LBL_HAZ02","LBL",MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION);
	
		       newWohazard.setValue("assetnum",mbosafetylexiconSet.getMbo(i).getString("assetnum"),
		      		 MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION);
	
	
		       // Derive other values from hazard table
	           strWhere2    ="  orgid=:1 ";
		       strWhere2 +="  and hazardid=:2 ";
		       sqlformat = new SqlFormat(getUserInfo(), strWhere2);
		       sqlformat.setObject(1, "HAZARD", "orgid", strOrgid);
		       sqlformat.setObject(2, "HAZARD", "hazardid", mbosafetylexiconSet.getMbo(i).getString("hazardid"));
	
	           strLink="LblCopyLOTOHazards_getHazardinfo" +  "_" + mbosafetylexiconSet.getMbo(i).getString("hazardid");
	
	           MboSetRemote mbohazardSet	= getMboSet(strLink,"HAZARD",sqlformat.format());
	
		       // Do not participate in transaction management
		       mbohazardSet.setFlag(MboConstants.DISCARDABLE,true);
	
		       if(! mbohazardSet.isEmpty())
		       {
		           newWohazard.setValue("PRECAUTIONENABLED",
		           mbohazardSet.getMbo(0).getBoolean("PRECAUTIONENABLED"),MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION);
		           newWohazard.setValue("HAZMATENABLED",
		           mbohazardSet.getMbo(0).getBoolean("HAZMATENABLED"),MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION);
		           newWohazard.setValue("TAGOUTENABLED",
		           mbohazardSet.getMbo(0).getBoolean("TAGOUTENABLED"),MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION);
		           /*
		           newWohazard.setValue("description",
		          		 mbohazardSet.getMbo(0).getString("description"),MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION);
	
		           newWohazard.setValue("hazardtype",
		          		 mbohazardSet.getMbo(0).getString("hazardtype"),MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION);
	
	
		           newWohazard.setValue("DESCRIPTION_LONGDESCRIPTION",
		          		                                mbohazardSet.getMbo(0).getString("DESCRIPTION_LONGDESCRIPTION"),
		          		                                MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION);
		           */
		          newWohazard.setValue("haz20", "N",   MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION);
		         } //  if(! mbohazardSet.isEmpty())
	
		          if (mbohazardSet !=null) { mbohazardSet.close(); mbohazardSet=null; } //added by Pankaj 03/08/10
		         // Do not close the set created via relationship
		         //   if (wohazardSet2 !=null) wohazardSet2.close();  // just close; do not set to null
			   } //  if ( ! doesHazardExist(mbosafetylexiconSet.getMbo(i).getString("hazardid"), wohazardSet2) )
	
		       //*************************************************
			   // Insert into WOTAGOUT collection (LOTO)
			   //*************************************************
	
		       // Derive other values from tagout  table
		       strWhere2    ="  siteid=:1 ";
			   strWhere2 +="   and tagoutid=:2 ";  // as per index
	
			   sqlformat = new SqlFormat(getUserInfo(), strWhere2);
			   sqlformat.setObject(1, "TAGOUT", "siteid", strSiteid);
			   sqlformat.setObject(2, "TAGOUT", "tagoutid", mbosafetylexiconSet.getMbo(i).getString("tagoutid"));
	
	          strLink="LblCopyLOTOHazards_getTagoutinfo" +  "_" + mbosafetylexiconSet.getMbo(i).getString("tagoutid");
	
		       MboSetRemote mboTagoutSet	= getMboSet(strLink,"TAGOUT",sqlformat.format());
	
		 	    // Do not participate in transaction management
		       mboTagoutSet.setFlag(MboConstants.DISCARDABLE,true);
		       MboRemote newWoTagout=null;
	
			     if(! mboTagoutSet.isEmpty())
			     {
	
			    	// Get access to WOTAGOUT collection
			        WoTagOutSetRemote wotagoutSet= (WoTagOutSetRemote)
			                     newWosafetylink.getMboSet(WoSafetyLinkSetRemote.WOTAGOUT);
	
			        boolean boolInsertWOTAGOUT=true;
	
			        String strTemp1=mbosafetylexiconSet.getMbo(i).getString("tagoutid");
			        if (strTemp1==null || strTemp1.length()==0) boolInsertWOTAGOUT=false;
	
			        if (boolInsertWOTAGOUT)
			        {
			        	  if (arrayListTagout.isEmpty())
			          	 	 arrayListTagout.add(strTemp1);
			        	  else
			        	  {
			        	     if (arrayListTagout.contains(strTemp1))
			        	  			 boolInsertWOTAGOUT=false;
			        	    else
			        	  		  arrayListTagout.add(strTemp1);
			        	   }  // else if (arrayListTagout.isEmpty())
			          } // if (boolInsertWOTAGOUT
	
			      newWoTagout=null;
			      if  (boolInsertWOTAGOUT)
			      {
	
			          newWoTagout=wotagoutSet.add(); // add new empty record
	
			          newWoTagout.setValue("orgid", strOrgid, MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION);
			          newWoTagout.setValue("siteid", strSiteid, MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION);
			          newWoTagout.setValue("wonum", strWonum, MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION);
			          newWoTagout.setValue("tagoutid",  mbosafetylexiconSet.getMbo(i).getString("tagoutid"),
		            	                              MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION);
	
			          newWoTagout.setValue("description", mboTagoutSet.getMbo(0).getString("description"),
	                                       MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION);
			          newWoTagout.setValue("location", mboTagoutSet.getMbo(0).getString("location"),
	                                       MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION);
			          newWoTagout.setValue("requiredstate", mboTagoutSet.getMbo(0).getString("requiredstate"),
	                                       MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION);
			          newWoTagout.setValue("assetnum", mboTagoutSet.getMbo(0).getString("assetnum"),
	                                       MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION);
	
			          newWoTagout.setValue("DESCRIPTION_LONGDESCRIPTION",
		            		                mboTagoutSet.getMbo(0).getString("DESCRIPTION_LONGDESCRIPTION"),
	                                        MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION);
	
			          newWoTagout.setValue("ASSETDESCRIPTION_LONGDESCRIPTION",
	                                       mboTagoutSet.getMbo(0).getString("ASSETDESCRIPTION_LONGDESCRIPTION"),
	                                       MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION);
	
			          newWoTagout.setValue("LBL_SOURCE","LBL",
	                                MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION);
			        } //  if (! boolInsertWOTAGOUT)
		        }    // if(! mboTagoutSet.isEmpty())
	
			    if (mboTagoutSet != null) { mboTagoutSet.close(); mboTagoutSet=null ;}
	
		
			  //****************************************************
			  // Insert into WOTAGLOCK collection (LOTO)
			  //***************************************************
	
	 	     if (newWoTagout !=null )
	   	     {
	 		     strWhere2    ="  siteid=:1 ";
			     strWhere2   +="   and tagoutid=:2 ";  // as per index
	
			     sqlformat = new SqlFormat(getUserInfo(), strWhere2);
			     sqlformat.setObject(1, "TAGLOCK", "siteid", strSiteid);
			     sqlformat.setObject(2, "TAGLOCK", "tagoutid", mbosafetylexiconSet.getMbo(i).getString("tagoutid"));
	
	             strLink="LblCopyLOTOHazards_getTagLock" +  "_" + mbosafetylexiconSet.getMbo(i).getString("tagoutid");
	
		         MboSetRemote mboTagLockSet	= getMboSet(strLink,"TAGLOCK",sqlformat.format());
	
		 	     // Do not participate in transaction management
		         mboTagLockSet.setFlag(MboConstants.DISCARDABLE,true);
	
		     	 WoTagLockSetRemote wotaglockSet= (WoTagLockSetRemote)
	             newWoTagout.getMboSet(WoTagOutSetRemote.WOTAGLOCK);
	
			     if(! mboTagLockSet.isEmpty())
			     {
	
			     	 for(int j=0; mboTagLockSet.getMbo(j) !=null; j++)
			     	 {
	
	                  MboRemote newWoTaglock=wotaglockSet.add(); // add new empty record
	                  newWoTaglock.setValue("orgid", strOrgid, MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION);
	                  newWoTaglock.setValue("siteid", strSiteid, MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION);
	                  newWoTaglock.setValue("wonum", strWonum, MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION);
	                  newWoTaglock.setValue("tagoutid", mbosafetylexiconSet.getMbo(i).getString("tagoutid"),
	        		                                 MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION);
	                  newWoTaglock.setValue("lockoutid",mboTagLockSet.getMbo(j).getString("lockoutid"),
	                                            MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION);
	                  newWoTaglock.setValue("applyseq",mboTagLockSet.getMbo(j).getString("applyseq"),
	                                             MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION);
	                  newWoTaglock.setValue("removeseq", mboTagLockSet.getMbo(j).getString("removeseq"),
	        		                                 MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION);
	                  newWoTaglock.setValue("LBL_SOURCE","LBL",
	                                              MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION);
	
	
	                 //***************************************************
	                 // Insert into WOLOCKOUT collection LOTO
	                 //***************************************************
	                  String strWhere3    ="  siteid=:1 ";
			                 strWhere3 +="   and lockoutid=:2 ";  // as per index
	
			          sqlformat = new SqlFormat(getUserInfo(), strWhere3);
			          sqlformat.setObject(1, "LOCKOUT", "siteid", strSiteid);
			          sqlformat.setObject(2, "LOCKOUT", "lockoutid", mboTagLockSet.getMbo(j).getString("lockoutid"));
	
	                 strLink="LblCopyLOTOHazards_getLockout" +  "_" +mboTagLockSet.getMbo(j).getString("lockoutid");
		             MboSetRemote mboLockoutSet	= getMboSet(strLink,"LOCKOUT",sqlformat.format());
	
		 	         // Do not participate in transaction management
		             mboLockoutSet.setFlag(MboConstants.DISCARDABLE,true);
	
		   	         WoLockOutSetRemote wolockoutset= (WoLockOutSetRemote)
	                 newWoTaglock.getMboSet(WoTagLockSetRemote.WOLOCKOUT);
	
		   	         MboRemote newWoLockout=wolockoutset.add();
	
			         if(! mboLockoutSet.isEmpty())
			         {
			   	       for(int k=0; mboLockoutSet.getMbo(k) !=null; k++)
			     	   {
				      	  newWoLockout.setValue("orgid", strOrgid, MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION);
	                      newWoLockout.setValue("siteid", strSiteid, MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION);
	                      newWoLockout.setValue("wonum", strWonum, MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION);
	                      newWoLockout.setValue("lockoutid", mboLockoutSet.getMbo(k).getString("lockoutid"),
	           		                                  MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION);
	                      newWoLockout.setValue("description", mboLockoutSet.getMbo(k).getString("description"),
	                                               MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION);
	                      newWoLockout.setValue("devicedescription", mboLockoutSet.getMbo(k).getString("devicedescription"),
	                                               MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION);
	                      newWoLockout.setValue("requiredstate", mboLockoutSet.getMbo(k).getString("requiredstate"),
	                                               MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION);
	                      newWoLockout.setValue("assetnum", mboLockoutSet.getMbo(k).getString("assetnum"),
	                                               MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION);
	                      newWoLockout.setValue("location", mboLockoutSet.getMbo(k).getString("location"),
	                                               MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION);
	                      newWoLockout.setValue("LBL_SOURCE", "LBL",
	                                               MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION);
	
	                      newWoLockout.setValue("DESCRIPTION_LONGDESCRIPTION",
	          		                                 mboLockoutSet.getMbo(k).getString("description_longdescription"),
	          		                                 MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION);
	
	                      newWoLockout.setValue("DEVICEDESCRIPTION_LONGDESCRIPTION",
	          		                                mboLockoutSet.getMbo(k).getString("DEVICEDESCRIPTION_LONGDESCRIPTION"),
	          		                                MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION);
			   	  	 } // 	   	 for(int k=0; mboLockoutSet.getMbo(k) !=null; k++)
			     } // if(! mboLockoutSet.isEmpty())
	
	            // Collection created via relationship should not be closed
			    // if (wolockoutset !=null) wolockoutset.close();
			    if (mboLockoutSet != null) { mboLockoutSet.close(); mboLockoutSet=null; }
	       } // 	 for(int j=0; mboTagLockSet.getMbo(j) !=null; j++)
		  }	 //     if(! mboTagLockSet.isEmpty())
	 	       if (mboTagLockSet !=null) { mboTagLockSet.close(); mboTagLockSet=null; }
  	   } //  if (newWoTagout !=null )
   	  } //   if ( mbosafetylexiconSet.getMbo(i).getString("tagoutid") !=null && mbosafetylexiconSet.getMbo(i).getString("tagoutid").length() > 0)
	 } //  if (! doesHazardTagoutExist(mbosafetylexiconSet.getMbo(i).getString("hazardid"), mbowosafetylinkSet))
	}  // for(int i=0; mbosafetylexiconSet.getMbo(i) !=null; i++)
   } // //   if(! mbosafetylexiconSet.isEmpty())
	if (arrayListTagout !=null) {arrayListTagout.clear();arrayListTagout=null;} 
	// if (mbosafetylexiconSet !=null) {mbosafetylexiconSet.close(); 
	//Do not close the set created via relationship
	//if (mbowosafetylinkSet !=null) { mbowosafetylinkSet.close(); mbowosafetylinkSet=null; }
 } // end of method
	 
	
		
	 //******************************************************************************
	 // Method to check whether the TAGOUT exists in the collection or not.
	// ******************************************************************************
	 boolean doesHazardTagoutExist(String strHazardid,
	 		                                             String strTagoutid,
	 		                                             String strAssetnum,
	 		                                            MboSetRemote mboCollection) 
	                 throws RemoteException, MXException
			 {
	 	
	 	boolean boolReturn=false;
			  
	 	for(int i=0; mboCollection.getMbo(i) !=null; i++)
	 	{
	 		 if (! mboCollection.getMbo(i).toBeDeleted())
	 		 {
	 				String strHazardid1=mboCollection.getMbo(i).getString("hazardid");
	      		String strTagoutid1=mboCollection.getMbo(i).getString("tagoutid"); 
	         String strAsset1= mboCollection.getMbo(i).getString("assetnum");
	
	         if (strHazardid1==null || strHazardid1.length() ==0)
	         	strHazardid1="_";
	
	         if (strTagoutid1==null || strTagoutid1.length() ==0)
	         	strTagoutid1="_";
	
	         if (strAsset1==null || strAsset1.length() ==0)
	         	strAsset1="_";
	
	 			 
	 			 if ((strHazardid1 + strTagoutid1 +strAsset1). 
	 					 equals(strHazardid + strTagoutid +strAssetnum) )
	 			 {
	 				 boolReturn=true;
	 			   break;
	 			 } // if ((mboCollection.getMbo(i).getString("hazardid") + mboCollection.getMbo(i).getString("tagoutid")).
	 		 } // if (! mboCollection.getMbo(i).toBeDeleted())
	
	 	} // for(int i=0; mboCollection.getMbo(i) !=null; i++)
	 	
				return boolReturn;
							 
			 } // end of method
	

/**************************************************************
 *  Send email to various recipients with specified mime type 
***************************************************************/	
 public void  LblSendMail(String sHost, String sFrom, String sTo, String sCC, 
		                  String sSubject, String sContentType, String sContent)
	          throws Exception
	 		 {
 		        String host = sHost;
 		        String from = sFrom;

	 		         
	 		    String to[]= sTo.split(",");
	 		    String cc[]= sCC.split(",");

	 		      

	 		     try
	 		     {
	 		          int i = 0;
	 		          Properties props = System.getProperties();
	 		          props.put("mail.smtp.host", host);
	 		          Session session = Session.getDefaultInstance(props, null);
	 		          MimeMessage message = new MimeMessage(session);
	 		          message.setFrom(new InternetAddress(from));
	 		          for(i = 0; i < to.length; i++)
	 		          {
	 		             if (to[i] !=null && to[i].length() >0)
	 		                message.addRecipient(javax.mail.Message.RecipientType.TO, new InternetAddress(to[i]));
	 		          }

	 		          for(i = 0; i < cc.length; i++)
	 		          {
	 		                if (cc[i] !=null && cc[i].length() >0)
	 		                message.addRecipient(javax.mail.Message.RecipientType.CC, new InternetAddress(cc[i]));
	 		           }

	 		            message.setSubject(sSubject);
	 		            if (sContentType.equalsIgnoreCase("HTML"))
	 		          	     message.setContent(sContent,"text/html");
	 		          	    else message.setContent(sContent,"text/plain");

	 		            Transport.send(message);
	 		        }
	 		        catch(Exception e)
	 		        {
	 		            log.debug("Error in MailUtil(cc): " + e.getMessage());
	 		        }
	   }
  
 /*****************************************************************
	 *  Send email to various recipients with specified mime type 
	 *  with file attachment.
	***************************************************************/	
	 public  void  LblSendMailAttachment(String sHost, String sFrom, String sTo, String sCC, 
			                  String sSubject, String sContentType, String sContent, String sFilename)
		          throws Exception
		 		 {
	 		        String host = sHost;
	 		        String from = sFrom;

		 		         
		 		    String to[]= sTo.split(",");
		 		    String cc[]= sCC.split(",");

		 		      

		 		     try
		 		     {
		 		          int i = 0;
		 		          Properties props = System.getProperties();
		 		          props.put("mail.smtp.host", host);
		 		          Session session = Session.getDefaultInstance(props, null);
		 		          MimeMessage message = new MimeMessage(session);
		 		          message.setFrom(new InternetAddress(from));
		 		          for(i = 0; i < to.length; i++)
		 		          {
		 		             if (to[i] !=null && to[i].length() >0)
		 		                message.addRecipient(javax.mail.Message.RecipientType.TO, new InternetAddress(to[i]));
		 		          }

		 		          for(i = 0; i < cc.length; i++)
		 		          {
		 		                if (cc[i] !=null && cc[i].length() >0)
		 		                message.addRecipient(javax.mail.Message.RecipientType.CC, new InternetAddress(cc[i]));
		 		           }

		 		            message.setSubject(sSubject);
		 		           

		 		           
		 		            Multipart multi = new MimeMultipart();
		 		            BodyPart textBodyPart = new MimeBodyPart();
		 		         
		 		           if (sContentType.equalsIgnoreCase("HTML"))
		 		        	  textBodyPart.setContent(sContent,"text/html");
		 		          	    else  textBodyPart.setContent(sContent,"text/plain");
		 		           	multi.addBodyPart(textBodyPart);
		 		            
		 		            
	 		                DataSource fds = new FileDataSource(sFilename);
	 		                BodyPart fileBodyPart = new MimeBodyPart();
	 		                fileBodyPart.setDataHandler(new DataHandler(fds));
	 		                fileBodyPart.setFileName(sFilename);
	 		                multi.addBodyPart(fileBodyPart);
	 		          
	 		                message.setContent(multi);
	 		                message.saveChanges();
	 		                Transport.send(message);
		 		           
		 		            
		 		            
		 		            
		 		            Transport.send(message);
		 		        }
		 		        catch(Exception e)
		 		        {
		 		            System.out.println("Error in MailUtil(cc): " + e.getMessage());
		 		        }
		   }
	  
	 
 
 /*************************************
   Overridden work order change status
  ************************************/
  public void changeStatus(String status, Date date, String memo, long l)
     throws MXException, RemoteException
  {
 	String strNewStatus=status;
 	
 	
 	
    String strReleaseStatus=null;
    
  	if (getMboValue("orgid").getString().equals("LBNL") &&
 		getMboValue("siteid").getString().equals("FAC"))
  	{
  	 // No extra processing for cancel.
   	 if (strNewStatus.equals("CAN"))
   	 {
    	   super.changeStatus(strNewStatus, date, memo, l);
    	   return;
   	 } // if (status.equals("CAN"))
   	 
   	 /***************************************************************************** 
   	  * If the new status of the work order is equal to SCHD or any status beyond
   	  * INPRG, COMP, and, if the lbl_release_Status=REQUIRED, then set the new status
   	  * to WREL
   	  * 
   	  * For PM work orders (only parents) and for non PM work order (only leaf
 	    node work orders)
   	  ******************************************************************************/
   	 
   	 if  (strNewStatus.equals("SCHD"))
   		  //getTranslator().toInternalString("WOSTATUS", strNewStatus).equalsIgnoreCase("INPRG") ||
   	      //getTranslator().toInternalString("WOSTATUS", strNewStatus).equalsIgnoreCase("COMP")  ||
   	      //getTranslator().toInternalString("WOSTATUS", strNewStatus).equalsIgnoreCase("CLOSE") || 
   	      
      { 
   		 
   		 /***************************************************************** 
   		  * At the time of changing the status of the work order, the values
   		    in workorder.lbl_release_status and locations.lbl_rel_reqd can be
   	 	    inconsistent. Therefore, we need to execute getReleaseStatus method
   	 	    to find out the latest status of the work order.
   	 	   ******************************************************************/
   		strReleaseStatus=getReleaseStatus(strNewStatus);
   		
   		
   	       	       		 
   	   // For PM work orders change status to WREL if release is required
   	 	 if (getMboValue("worktype").getString().toLowerCase().startsWith("pm"))
   	 	 {		       	  		   		
       	    if ((strReleaseStatus.equals("REQUIRED")  ||
       	    	 strReleaseStatus.equals("REQUEST FOR INFORMATION")) && 
       	    	! strNewStatus.equals("WREL")) 
       	    { 	
       	    	
       	         strNewStatus="WREL";
       	         
       	    }
       	         	                
         } // PM work orders
   	   else // For non-PM work orders, if the work order is at leaf node, change to WREL if rel reqd 
   	   {
   		          
   	  		  	  if (! getMboValue("hasChildren").getBoolean())
   	  		  	  {
   	  		  		  if (strReleaseStatus.equals("REQUIRED") && ! strNewStatus.equals("WREL"))	    		 	  		  			      	        	      	        	    
   	  	   			        strNewStatus="WREL";   	
   	  		  	   	  		  	 	  		  	
   	  		  	      if (strReleaseStatus.equals("REQUEST FOR INFORMATION") && ! strNewStatus.equals("WREL"))
   	  		  	                                  
    	   			        strNewStatus="WREL";   	
   	  	   	   	        	   
   	  		  	  	
   	  		  	  } //if (! getMboValue("hasChildren").getBoolean())

   	     }  // end of else for pm work orders
   	 	 
   	          	 	      	 	 
  	  } // if  ( ! getTranslator().toInternalString("WOSTATUS", strNewStatus).....
  	} // orgid=LBNL and siteid=FAC
  	
  	// Now allow framework to perform change status
  	
  	
	super.changeStatus(strNewStatus, date, memo, l);  // other org and site
	
	/*****************************************************************************
	* The following is for MRO work flow 
	* 			
	*****************************************************************************/
	// Find out whether the status is eligible for MRO workflow
	/* boolean boolWFInitiate=true;
	
    String strWhere    ="  domainid='LBL_WOWKFLSTATUS'";
   	       strWhere   +=" and value=:1";  

   	SqlFormat  sqlformat = new SqlFormat(getUserInfo(), strWhere);
	   		   sqlformat.setObject(1, "ALNDOMAIN", "value", strNewStatus);
	   
	String     strLink="LblALNDomainwkflow";

    MboSetRemote mboALNDomainSet=getMboSet(strLink,"ALNDOMAIN",sqlformat.format());

   // Do not participate in transaction management
    mboALNDomainSet.setFlag(MboConstants.DISCARDABLE,true);
    if(! mboALNDomainSet.isEmpty()) 
	{
   	  strWhere =" ownerid=:1 and assignstatus='ACTIVE' and ownertable='WORKORDER' " ;
      strWhere +=" and processname in (select  b.processname from wfprocess b where b.processname like 'FA%' and b.enabled=1) ";
  
      sqlformat = new SqlFormat(getUserInfo(), strWhere);
      sqlformat.setObject(1, "WFASSIGNMENT", "ownerid", Integer.toString(getInt("workorderid")));
      strLink="LBLWO2WFAssignment";

      MboSetRemote mboWFassignmentSet=getMboSet(strLink,"WFASSIGNMENT",sqlformat.format());

	// Do not participate in transaction management
    mboWFassignmentSet.setFlag(MboConstants.DISCARDABLE,true);
	if(! mboWFassignmentSet.isEmpty()) 
		boolWFInitiate=false;
	
	mboWFassignmentSet.close();
	mboWFassignmentSet=null;

	if (boolWFInitiate)
	{
		MXServer mx = MXServer.getMXServer();
		WorkFlowServiceRemote wfsr = (WorkFlowServiceRemote)mx.lookup("WORKFLOW");
		wfsr.initiateWorkflow("FAMRO", this);
	} // if (boolWFInitiate)
	
 }
    if (mboALNDomainSet != null) { mboALNDomainSet.close(); mboALNDomainSet=null; }
    */

  }    // end of method  	    	 
  
//********************************************
//Get release status for the location
//*********************************************
public String getReleaseStatus(String strStatus) throws
                     RemoteException, MXException
{

		String strReturn="UNKNOWN";
		String strRelReqd="";
		String strWhere="";
		String strRoute="";

		 if (getString("orgid").equals("LBNL") &&
		 	 getString("siteid").equals("FAC"))
		{
			
			 // For task work order, the release status is always not required.
	 	        if (getBoolean("istask"))
		    	  return "NOT REQUIRED";
	 	        
	 	     // If location is not specified, return unknown   
	 	       if (isNull("location"))
	 	    	  return "UNKNOWN";
	 	    
	 	      if (strStatus.equals("WREL")) 
	   	          return "WAITING RELEASE";
	   	 	   	 	 
	   	 	   if  (strStatus.equals("REL"))
	   	 	      return "RELEASED";
	   	 	      
	           if  (strStatus.equals("RFI"))
	   	 	       return "REQUEST FOR INFORMATION";
	           
	           
	   	/********* Commented 	       	 	 
	 	       	 	       
	       // Do not find out release status if the release status is  WAITING RELEASE 
			if (getString("lbl_release_status") !=null)
			{
			  if (getString("lbl_release_status").equals("RELEASED") ||
	              getString("lbl_release_status").equals("WAITING RELEASE"))				    	  						  
			  {
				   // IF the status of the work order is one among the value
				   // indicated in ALNDOMAIN LBL_WOSTATREREL, then, 
				   // it can be sent to WREL.
				  
				   strWhere   =" domainid='LBL_WOSTATREREL'";
				   strWhere +="  and value=:1";
				   
				    SqlFormat sqlformat1 = new SqlFormat(getUserInfo(), strWhere);
			        sqlformat1.setObject(1, "ALNDOMAIN", "value", strStatus);
			   	  	    
			        MboSetRemote alnDomainSet= (MboSetRemote) getMboSet(
			    		 "LBLWO_getReleaseStatus_ALNDOMAIN", "ALNDOMAIN", sqlformat1.format());

				   // Do not participate in transaction management
			        alnDomainSet.setFlag(MboConstants.DISCARDABLE,true);
			  			
			       if (alnDomainSet.isEmpty())
			       {
			        alnDomainSet.close();
			      	alnDomainSet=null;
			      	sqlformat1=null;
			      	strWhere=null;
			      	return getString("lbl_release_status");
			       }
			       else
			       {	   
			    	   alnDomainSet.close();
				       alnDomainSet=null;
				       sqlformat1=null;
				       strWhere=null;
			       } // need to evaluate further as the user indicated re-release 
					
			     } // if (getString("lbl_release_status").equals("RELEASED"))  

			
			  if (getString("lbl_release_status").equals("REQUEST FOR INFORMATION") &&		  
			     ( getString("location").equals(getMboValue("location").getPreviousValue().asString()) &&  
				   getString("worktype").equals(getMboValue("worktype").getPreviousValue().asString()) &&
				   getString("commoditygroup").equals(getMboValue("commoditygroup").getPreviousValue().asString())))				  					
				 return getString("lbl_release_status");
						  
			} commented until here ***/	
	           
			// If the work order reaches beyond INPRG, then do not derive
			// release status. Return the release status as it is.

		   // strWhere   =" domainid='WOSTATUS' and maxvalue in ('INPRG','COMP','CLOSE') ";
	       // After the implementation of workflow SCHD will become synonymn for APPR, therefore
	       // it needs to be checked separately 
	           
	           
	           
	       strWhere   =" domainid='WOSTATUS' and (maxvalue in ('INPRG','COMP','CLOSE')) ";
	       // Instead of hardcoding the values look into the ALNDomains and skip the release process
	       //strWhere +="  OR (domainid='WOSTATUS' and value in ('SCHD','ASSIGNED')))"; 	           
		   strWhere +=" and value=:1";
		   
		    SqlFormat sqlformat1 = new SqlFormat(getUserInfo(), strWhere);
	        sqlformat1.setObject(1, "SYNONYMDOMAIN", "value", strStatus);
	   	  	    
	        MboSetRemote synDomainSet= (MboSetRemote) getMboSet(
	    		 "LBLWO_getReleaseStatus_SYNONYMDOMAIN", "SYNONYMDOMAIN", sqlformat1.format());

		   // Do not participate in transaction management
	       synDomainSet.setFlag(MboConstants.DISCARDABLE,true);
	  			
	       if ( ! synDomainSet.isEmpty())
	       {
	      	synDomainSet.close();
	      	synDomainSet=null;
	      	sqlformat1=null;
	      	strWhere=null;
	      	return getString("lbl_release_status");
	      }	
	       
	       // Added on May 13,2019 after the implementation of datasplice
	       // supervisor view for WASSIGN
	       // IF the status of the work order is one among the value
		   // indicated in ALNDOMAIN=LBL_STOPWREL, then, no need to re-evaluate.
	       // JIRA EF-9542
	       
		    
		   strWhere   =" domainid='LBL_STOPWREL'";
		   strWhere +="  and value=:1";
		   
		    sqlformat1 = new SqlFormat(getUserInfo(), strWhere);
	        sqlformat1.setObject(1, "ALNDOMAIN", "value", strStatus);
	   	  	    
	        MboSetRemote alnDomainSet= (MboSetRemote) getMboSet(
	    		 "LBLWO_getReleaseStatus_ALNDOMAIN1", "ALNDOMAIN", sqlformat1.format());

		   // Do not participate in transaction management
	        alnDomainSet.setFlag(MboConstants.DISCARDABLE,true);
	  			
	       if (! alnDomainSet.isEmpty())
	       {
	        alnDomainSet.close();
	      	alnDomainSet=null;
	      	sqlformat1=null;
	      	strWhere=null;
	      	return getString("lbl_release_status");
	       }
	       else
	       {	   
	    	   alnDomainSet.close();
		       alnDomainSet=null;
		       sqlformat1=null;
		       strWhere=null;
	       } // need to evaluate further as the user indicated re-release  
	       
	       
	       
			
	    // Find out whether the location requires release
	  	 strWhere   =" siteid=:1 ";
	  	 strWhere +="  and location=:2 ";

	  	 SqlFormat sqlformat = new SqlFormat(getUserInfo(), strWhere);
	                 sqlformat.setObject(1, "LOCATIONS", "siteid",  getString("siteid"));
	   	             sqlformat.setObject(2, "LOCATIONS", "location", getString("location"));

	  	  MboSetRemote locationsSet= (MboSetRemote) getMboSet("LblWO_getReleaseStatus_locations", "LOCATIONS", sqlformat.format());
	  	  // Do not participate in transaction management
	  	  locationsSet.setFlag(MboConstants.DISCARDABLE,true);

	       if ( ! locationsSet.isEmpty())
	           strRelReqd=locationsSet.getMbo(0).getString("lbl_rel_reqd");
   
	       
	       if (locationsSet !=null)
	      {
	      	locationsSet.close();
	      	locationsSet=null;
	      	sqlformat=null;    	
	      	strWhere=null;
	      }
	      if (strRelReqd !=null && strRelReqd.equals("N"))
	  	    return "NOT REQUIRED";
	      
	      //  Now check whether the location belongs to infrastructure system.
	      //  If it belongs to, then, release_status=NOT REQUIRED
	        strWhere =" siteid =:1 and location=:2 and :2  in (select b.location from locancestor b where b.siteid=:1  and b.ancestor='I' and b.location=:2) ";

	        sqlformat = new SqlFormat(getUserInfo(), strWhere);
	        sqlformat.setObject(1, "LOCATIONS", "siteid", getString("siteid"));
	  	    sqlformat.setObject(2, "LOCATIONS", "location", getString("location"));

	  	  locationsSet= (MboSetRemote) getMboSet("LblWO_getReleaseStatus_locations_infrastrucure", "LOCATIONS", sqlformat.format());
	  	  // Do not participate in transaction management
	  	  locationsSet.setFlag(MboConstants.DISCARDABLE,true);

	        if ( ! locationsSet.isEmpty())
	        {
	    		locationsSet.close();
	    		locationsSet=null;
	    		strWhere=null;
	    		sqlformat=null;
	    		return "NOT REQUIRED";
	    	  } // if ( ! locationsSet.isEmpty())
	    	  else
	    	  {
	    		locationsSet.close();
	           	locationsSet=null;
	           	strWhere=null;
	          	sqlformat=null;
	    	   }
	       		  
		 // Look for the value of commodity group (service group) in alndomain=LBL_EXEMPT_REL_SG
	     // If found, then, return not required.    
		
		  if (getString("commoditygroup") !=null && getString("commoditygroup").length() >0)
			 {
				strWhere   =" domainid='LBL_EXEMPT_REL_SG' ";
	  		    strWhere  +=" and value=:1";

	  		  sqlformat = new SqlFormat(getUserInfo(), strWhere);
	  	      sqlformat.setObject(1, "ALNDOMAIN", "value", getString("commoditygroup"));

	  	       alnDomainSet= (MboSetRemote) getMboSet(
	  	    		 "LblWO_getReleaseStatus_ALNDOMAINCG", "ALNDOMAIN", sqlformat.format());

	  		   // Do not participate in transaction management
	  	       alnDomainSet.setFlag(MboConstants.DISCARDABLE,true);
	  	      if ( ! alnDomainSet.isEmpty())
	  	      {
	  	      	alnDomainSet.close();
	  	      	alnDomainSet=null;
	  	        sqlformat=null;
	  	        strWhere=null;
	  	      	return "NOT REQUIRED";
	  	      }
	  	      if (alnDomainSet !=null ) { alnDomainSet.close();	alnDomainSet=null; }

			 } //if (strCommoditygroup !=null && strCommoditygroup.length() >0)

	     
		  if (getString("worktype") !=null && getString("worktype").length() >0)
	  	  {

		   // Find out whether the work type requires release
			 strWhere   =" orgid=:1 ";
		     strWhere +="  and worktype=:2 ";

		     	  	 sqlformat = new SqlFormat(getUserInfo(), strWhere);
	                 sqlformat.setObject(1, "WORKTYPE", "orgid", getString("orgid"));
		             sqlformat.setObject(2, "WORKTYPE", "worktype", getString("worktype"));

		    MboSetRemote worktypeSet= (MboSetRemote) getMboSet("LblWO_getReleaseStatus_worktype", "WORKTYPE", sqlformat.format());

		   // Do not participate in transaction management
		   worktypeSet.setFlag(MboConstants.DISCARDABLE,true);


	       if ( ! worktypeSet.isEmpty())
	          strRelReqd=worktypeSet.getMbo(0).getString("lbl_rel_reqd");
	    
	       
	       // if null, then release is required
	       if (strRelReqd.equals("") || strRelReqd.length() ==0)
	    	   strRelReqd="Y";  
	       

	    
	       if (worktypeSet !=null)
	       {
	    	  worktypeSet.close();
	          worktypeSet=null;
	          sqlformat=null;
	          strWhere=null;
	       }
	       if (strRelReqd !=null && strRelReqd.equals("N"))
		      return "NOT REQUIRED";
		 }  // if (Worktype !=null && worktype.length() >0)


         // Parent work order and not PM work order
	      if (getBoolean("haschildren"))	    	 
	      {
	  	    if ( getString("worktype") !=null &&
	  			 ! getString("worktype").toLowerCase().startsWith("pm"))
	  		  return "NOT REQUIRED";

	  	  /* JIRA EF-3263 Logic of finding out whether the release required
	  	   * for PM work orders having routes is restored from rel 6.2.6 
	       */
	  	  /* if ((getString("worktype").toLowerCase().startsWith("pm")) &&
	  	       getString("route") !=null && getString("route").length() >0)
	  	   	   return "NOT REQUIRED";*/
	   		
		  	 if (getString("pmnum") !=null && getString("pmnum").length() >0)
		  	 {
		  		   // Find out whether the PM is generated from route
		 		    
	  		     strWhere   =" siteid=:1 ";
   	  		     strWhere  +=" and pmnum=:2 ";
		  		   
		  		 sqlformat = new SqlFormat(getUserInfo(), strWhere);
		  	     sqlformat.setObject(1, "PM", "siteid", getString("siteid"));
		  	     sqlformat.setObject(2, "PM", "pmnum", getString("pmnum"));
		  	     
		  	     MboSetRemote pmSet= (MboSetRemote) getMboSet("LblWO_getReleaseStatus_PM_route", "PM", sqlformat.format());
		 
		  		  // Do not participate in transaction management 
		  		  pmSet.setFlag(MboConstants.DISCARDABLE,true);
		 	  			
		  	      if ( ! pmSet.isEmpty())
		  	      	strRoute=pmSet.getMbo(0).getString("route");

		  	        if (pmSet !=null)
		  	        {
		  	        	pmSet.close();
		  	      	    pmSet=null;
		  	         }
		  	       if (strRoute !=null && strRoute.length()>0)
		  	  	      return "NOT REQUIRED";
		  		 } // if (strPmnum !=null  || strPmnum.length()>0 
	  	    	  		
	  	 } // HasChildren

    
     if (strRelReqd.equals("Y"))
     {
      //  If release is required, then, check at-least one authorizer is active
      // for that location
   
      strWhere    ="  location=:1 "; 
	   strWhere   +="  and personid is not null";
	   strWhere   += " and location in (select b.location from lbl_auth_release b, person c ";
	   strWhere   +="  where b.location=:1 and b.personid=c.personid and c.lbl_status='A')";

	   sqlformat = new SqlFormat(getUserInfo(), strWhere);
	   sqlformat.setObject(1, "LBL_AUTH_RELEASE", "location", getString("location"));
	 
	   
	   MboSetRemote lblAuthReleaseSet= (MboSetRemote) getMboSet("LblWO_getReleaseStatus_lbl_auth_release", "LBL_AUTH_RELEASE", sqlformat.format());
		   // Do not participate in transaction management
     	lblAuthReleaseSet.setFlag(MboConstants.DISCARDABLE,true);

        if ( ! lblAuthReleaseSet.isEmpty())
              strReturn="REQUIRED";
        else
              strReturn="UNKNOWN";
      
        
        if (lblAuthReleaseSet !=null)
        {
       	 lblAuthReleaseSet.close();
       	 lblAuthReleaseSet=null;
       	 strWhere=null;
       	 sqlformat=null;
         }            
       } // if (RelReqd != null && RelReqd.equals("Y"))         
      
		} //if (Orgid.equals("LBNL") && Siteid.equals("FAC"))   
    return strReturn;
    
}   // end of getReleaseStatus()
  

//*********************************************************************************
// Method to sync hazards to work order releated hazard collection.
// Used by WPC sork order walk-through hazards and noun-verb hazards
//**********************************************************************************
public static void wpc_sync_wohazards(MboRemote mboWo,
		                                                MboRemote mboSource,
		                                                String strHazardid,
		                                                String strOperation) 
                   throws RemoteException, MXException
{

	  MboRemote newWosafetylink=null;
	  
	// Get access to wosafetylink collection
	  
	WoSafetyLinkSetRemote mbowosafetylinkSet=(WoSafetyLinkSetRemote) 
    mboWo.getMboSet(WOSetRemote.WOSAFETYLINK);


  //******************
	// Adding hazard
	//******************
	if (strOperation.equalsIgnoreCase("ADD"))
	{
		
		// If hazard already exists in the collection then mark its source 
		// lbl_wosl01 as WPC, so that it will not be deleted by the program
		
		boolean boolHazExists=false;
		
		boolHazExists=UtilDoesHazardExist(strHazardid, mbowosafetylinkSet);
		
		if (boolHazExists)
		{
    	for(int i=0; mbowosafetylinkSet.getMbo(i) !=null; i++)
    	{
    		 if (! mbowosafetylinkSet.getMbo(i).toBeDeleted())
    		 {
    			 if (mbowosafetylinkSet.getMbo(i).getString("hazardid").equals(strHazardid))
    			 {
    				 mbowosafetylinkSet.getMbo(i).setValue("lbl_wosl01", "WPC",
    						 MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION);
    				
    			   break;
    			 } // if (mbowosafetylinkSet(i).getString("hazardid").equals(strHazard))
    		 } // if (! mbowosafetylinkSet(i).toBeDeleted())
    		
    	} // for(int i=0; mbowosafetylinkSet(i) !=null; i++)
		} // 	if (doesHazardExist(strHazardid, mbowosafetylinkSet))

    // Insert only if hazard does not exist in the collection
		if (! boolHazExists)
    {	 
			
 	   // Insert a new row into wosafetylink collection
		     newWosafetylink=mbowosafetylinkSet.add(); // add new empty record
		
	  	   newWosafetylink.setValue("orgid", mboWo.getString("orgid"), 
		  		                                     MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION);
		     newWosafetylink.setValue("siteid", mboWo.getString("siteid"), 		  		 
		  		                                     MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION);
		     newWosafetylink.setValue("wonum", mboWo.getString("wonum"),
		  		                                     MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION);
		     newWosafetylink.setValue("hazardid", strHazardid, 
		  		                                      MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION);
		     newWosafetylink.setValue("lbl_wosl01","WPC",
         MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION);
		    //newWosafetylink.setValue("location", strLocation, MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION);     		
		    //newWosafetylink.setValue("wosafetydatasource","WO",MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION);
		    
		     // Get access to WOHAZARD collection
		      WoHazardSetRemote wohazardSet2= (WoHazardSetRemote)      		      
		                    newWosafetylink.getMboSet(WoSafetyLinkSetRemote.WOHAZARD);
		
	       // Insert into wohazard collection      	 
     MboRemote newWohazard=wohazardSet2.add(); // add new empty record
   
     newWohazard.setValue("orgid",  mboWo.getString("orgid"),  MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION);
     newWohazard.setValue("siteid", mboWo.getString("siteid"),  MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION);
	     newWohazard.setValue("wonum",mboWo.getString("wonum"), MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION);
	     newWohazard.setValue("hazardid", strHazardid, MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION);
	       
	       //newWohazard.setValue("wosafetydatasource","WO",MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION);      	        	     
	       newWohazard.setValue("haz20", "N", MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION);
 		  
       newWohazard.setValue("PRECAUTIONENABLED",
                                           true,
                                           MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION);
       newWohazard.setValue("HAZMATENABLED",
                                           false,
                                           MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION);
       newWohazard.setValue("TAGOUTENABLED",
                                            false,
                                            MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION);
	       newWohazard.setValue("LBL_HAZ01","WPC",
	      		                                 MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION);
	       
    } //  if (! doesHazardExist(strHazardid, mbowosafetylinkSet))
	} //if (strOperation.equalsIgnoreCase("ADD"))

  //**********************
	// Deleting hazard
	//**********************
	if (strOperation.equalsIgnoreCase("DELETE"))
	{
 
	  // Check to see whether there are more than 1 record in LBL_WOCRAFTVNHAZ collection
     //  for the given combination of work order and hazard id. If more than 1 records are present,
	 // and is not marked for deletion then it indicates that the hazard is used by multiple craft-verb-nouns. 
	 // In this case, do not delete  the hazard from work order hazards collection
		  		
		
	  int intNumberofSameHazards=0;	
	  String strTemp1="", strTemp2="";
		strTemp1= mboWo.getString("siteid") + mboWo.getString("wonum") +  strHazardid; 
	  
	  MboSetRemote mboThisSet=mboSource.getThisMboSet();
    
	  if (mboThisSet !=null && mboThisSet.count() >0)
	  {
	  	  
	    for(int i=0; mboThisSet.getMbo(i) !=null ; i++)
      {
	  	    strTemp2=mboThisSet.getMbo(i).getString("siteid") +mboThisSet.getMbo(i).getString("wonum") + 
	  	    mboThisSet.getMbo(i).getString("hazardid");
	  	  
	  	  
	  	    if ((strTemp1.equalsIgnoreCase(strTemp2)) &&
	  	    		(! mboThisSet.getMbo(i).toBeDeleted()))
	  	    	intNumberofSameHazards++;
      }    // for(int i=0; mboThisSet.getMbo(i) !=null ; i++)	
	    	 
     } // if (mboThisSet !=null && mboThisSet.count() >0)
	  

		
		  if (intNumberofSameHazards >1)
		  		  	  return;  // Do not delete record from work order hazard collection
		    		    		  
		  // Also check whether the hazard exists in LBL_WOWKTHRUHAZ table for the same
		  // work order. If exists, then, do not delete the record
		 String strWhere    ="  siteid=:1 ";
 	   strWhere  +="  and  wonum=:2 ";
 	   strWhere  += " and hazardid=:3";

 	   SqlFormat sqlformat = new SqlFormat(mboWo.getUserInfo(), strWhere);
 	   sqlformat.setObject(1, "LBL_WOWKTHRUHAZ", "siteid", mboWo.getString("siteid"))  ;
 	   sqlformat.setObject(2, "LBL_WOWKTHRUHAZ", "wonum", mboWo.getString("wonum"))  ;
 	   sqlformat.setObject(3, "LBL_WOWKTHRUHAZ", "hazardid",strHazardid);
 		     
 		  MboSetRemote setLblwowkthruhaz= (MboSetRemote) mboWo.getMboSet("LblUtil01_getHazardcountLBL_WOWKTHRUHAZ1", "LBL_WOWKTHRUHAZ", sqlformat.format());

  	   		
 		  if (setLblwowkthruhaz.count() >0)
 		  {
 		  	  if ( setLblwowkthruhaz !=null) {setLblwowkthruhaz.close(); setLblwowkthruhaz=null;}
 		  	  return;  // Do not delete record from work order hazard collection
 		  }
 		  if ( setLblwowkthruhaz !=null) {setLblwowkthruhaz.close(); setLblwowkthruhaz=null;}
		   		  
		  
     if (! mbowosafetylinkSet.isEmpty())
	    {
       for(int i=0; mbowosafetylinkSet.getMbo(i) !=null ; i++)
       {
  	   
    	 // Check whether the hazard can be deleted or not  (based upon location,asset and 
    	 // work control hazard
 	 		 if (! mbowosafetylinkSet.getMbo(i).toBeDeleted() &&
 	 				   mbowosafetylinkSet.getMbo(i).getString("hazardid").equals(strHazardid) &&
 	 				 ( mbowosafetylinkSet.getMbo(i).getString("lbl_wosl01").equals("LBL") ||
 	 					 mbowosafetylinkSet.getMbo(i).getString("lbl_wosl01").equals("WPC")) 
 	 		     )
 		    {
 			  
 		   	 strWhere            =" siteid=:1 "; 
         strWhere          += " and (location=:2 ";
         strWhere          +="  or assetnum=:3)  "; 
         strWhere          +=" and hazardid=:4 "; 
         sqlformat = new SqlFormat(mboWo.getUserInfo(), strWhere);  

          sqlformat.setObject(1, "SAFETYLEXICON", "siteid",  mboWo.getString("siteid"));
          sqlformat.setObject(2, "SAFETYLEXICON", "location",mboWo.getString("location"));
          sqlformat.setObject(3, "SAFETYLEXICON", "assetnum", mboWo.getString("assetnum"));
          sqlformat.setObject(4, "SAFETYLEXICON", "hazardid", strHazardid);

         String strLink2    ="LblUtil01_wohazards_safetylexicon1" +  "_" +  mbowosafetylinkSet.getMbo(i).getString("location") + "_";
                   strLink2  +=mbowosafetylinkSet.getMbo(i).getString("assetnum") + "_";; 
                   strLink2  +=mbowosafetylinkSet.getMbo(i).getString("hazardid") ; 
         
           MboSetRemote mbosafetylexiconSet=mboWo.getMboSet(strLink2, "SAFETYLEXICON",sqlformat.format());

            //  Do  not participate in transaction management
           mbosafetylexiconSet.setFlag(MboConstants.DISCARDABLE,true);
   
            if ( mbosafetylexiconSet.isEmpty() &&
            		 UtilCanDeleteHazard(mboWo, mboWo.getString("siteid"),	 
            				                       mbowosafetylinkSet.getMbo(i).getString("hazardid"), 
            				                       mboWo.getString("lbl_workcntrhazard")) )
            {
            

              	 mbowosafetylinkSet.getMbo(i).delete(MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION);
             } // if ( mbosafetylexiconSet.isEmpty())
            if (mbosafetylexiconSet !=null) { mbosafetylexiconSet.close(); mbosafetylexiconSet=null; }
 		    } // Check whether the hazard can be deleted or not 
      } // for(int i=0; mbowosafetylinkSet.getMbo(i) !=null ; i++)
	  }  // if (! mbowosafetylinkSet.isEmpty()) 
	} //     	if (strOperation.equalsIgnoreCase("DELETE"))
	
   //*******************************************
	// Deleting hazard from walk through
	//*****************************************
	if (strOperation.equalsIgnoreCase("DELETE_WOWKTHRU"))
	{
 
	  // Check to see whether there is a record in LBL_WOCRAFTVNHAZ table
   //  for the given combination of work order and hazard id. If more than 1 records are present, 
   // then it indicates that the hazard is used by multiple craft-verb-nouns. 
	 // In this case, do not delete  the hazard from work order hazards collection
		
		 String strWhere    ="  siteid=:1 ";
	   strWhere  +="  and  wonum=:2 ";
	   strWhere  += " and hazardid=:3";

	   SqlFormat sqlformat = new SqlFormat(mboWo.getUserInfo(), strWhere);
	   sqlformat.setObject(1, "LBL_WOCRAFTVNHAZ", "siteid", mboWo.getString("siteid"))  ;
	   sqlformat.setObject(2, "LBL_WOCRAFTVNHAZ", "wonum", mboWo.getString("wonum"))  ;
	   sqlformat.setObject(3, "LBL_WOCRAFTVNHAZ", "hazardid",strHazardid);
		     
		  MboSetRemote setLblwocraftvnhaz= (MboSetRemote) mboWo.getMboSet("LblUtil01_getHazardcountLBL_WOCRAFTVNHAZ2", "LBL_WOCRAFTVNHAZ", sqlformat.format());
		  
		  if (setLblwocraftvnhaz.count() >0)
		  {
		  	  if ( setLblwocraftvnhaz !=null) {setLblwocraftvnhaz.close(); setLblwocraftvnhaz=null;}
		  	  return;  // Do not delete record from work order hazard collection
		  }
		  if ( setLblwocraftvnhaz !=null) {setLblwocraftvnhaz.close(); setLblwocraftvnhaz=null;}
		  
		    		  
     if (! mbowosafetylinkSet.isEmpty())
	    {
       for(int i=0; mbowosafetylinkSet.getMbo(i) !=null ; i++)
       {
  	   
    	 // Check whether the hazard can be deleted or not  (based upon location,asset and 
    	 // work control hazard
 	 		 if (! mbowosafetylinkSet.getMbo(i).toBeDeleted() &&
 	 				   mbowosafetylinkSet.getMbo(i).getString("hazardid").equals(strHazardid) &&
 	 				 ( mbowosafetylinkSet.getMbo(i).getString("lbl_wosl01").equals("LBL") ||
 	 					 mbowosafetylinkSet.getMbo(i).getString("lbl_wosl01").equals("WPC")) 
 	 		     )
 		    {
 			  
 		   	 strWhere            =" siteid=:1 "; 
         strWhere          += " and (location=:2 ";
         strWhere          +="  or assetnum=:3)  "; 
         strWhere          +=" and hazardid=:4 "; 
         sqlformat = new SqlFormat(mboWo.getUserInfo(), strWhere);  

          sqlformat.setObject(1, "SAFETYLEXICON", "siteid",  mboWo.getString("siteid"));
          sqlformat.setObject(2, "SAFETYLEXICON", "location",mboWo.getString("location"));
          sqlformat.setObject(3, "SAFETYLEXICON", "assetnum", mboWo.getString("assetnum"));
          sqlformat.setObject(4, "SAFETYLEXICON", "hazardid", strHazardid);

         String strLink2    ="LblUtil01_wohazards_safetylexicon2" +  "_" +  mbowosafetylinkSet.getMbo(i).getString("location") + "_";
                   strLink2  +=mbowosafetylinkSet.getMbo(i).getString("assetnum") + "_";; 
                   strLink2  +=mbowosafetylinkSet.getMbo(i).getString("hazardid") ; 
         
           MboSetRemote mbosafetylexiconSet=mboWo.getMboSet(strLink2, "SAFETYLEXICON",sqlformat.format());

            //  Do  not participate in transaction management
           mbosafetylexiconSet.setFlag(MboConstants.DISCARDABLE,true);
             
            if ( mbosafetylexiconSet.isEmpty() &&
            		 UtilCanDeleteHazard(mboWo, mboWo.getString("siteid"),	 
            				                       mbowosafetylinkSet.getMbo(i).getString("hazardid"), 
            				                       mboWo.getString("lbl_workcntrhazard")) )
            {
              	 mbowosafetylinkSet.getMbo(i).delete(MboConstants.NOACCESSCHECK | MboConstants.NOVALIDATION);
             } // if ( mbosafetylexiconSet.isEmpty())
            if (mbosafetylexiconSet !=null) { mbosafetylexiconSet.close(); mbosafetylexiconSet=null; }
 		    } // Check whether the hazard can be deleted or not 
      } // for(int i=0; mbowosafetylinkSet.getMbo(i) !=null ; i++)
	  }  // if (! mbowosafetylinkSet.isEmpty()) 
	} //     	if (strOperation.equalsIgnoreCase("DELETE_WOWKTHRU"))
	
	
	
 } // end of method

//******************************************************************************
// Method to check whether the hazard exists in the collection or not.
// ******************************************************************************
static boolean UtilDoesHazardExist(String strHazard, MboSetRemote mboCollection) 
                throws RemoteException, MXException
	 {
	
	boolean boolReturn=false;

	
	for(int i=0; mboCollection.getMbo(i) !=null; i++)
	{
	 if (! mboCollection.getMbo(i).toBeDeleted())
		 {
		
			 if (mboCollection.getMbo(i).getString("hazardid").equals(strHazard))
			 {
				 boolReturn=true;
			   break;
			 } // if (mboCollection.getMbo(i).getString("hazardid").equals(strHazard))
		 } // if (! mboCollection.getMbo(i).toBeDeleted())
	} // for(int i=0; mboCollection.getMbo(i) !=null; i++)
	
	
		return boolReturn;			  
					 
	 } // end of method

//**************************************************************
//  Method to check whether the hazard can be deleted
// in sync method
// **************************************************************
public static  boolean UtilCanDeleteHazard(MboRemote mboWo,
		                                               String strSiteid,
		                                               String strHazardid, 
		                                               String strLbl_workcntrhazard)
            throws RemoteException, MXException 
{
	  boolean boolReturn=true;
	  
	  if (strLbl_workcntrhazard !=null && 
	  		(strLbl_workcntrhazard.equals("2") || strLbl_workcntrhazard.equals("4")))
	  {
	  				  	
	  	String strWhere=null;
	     
	     strWhere   = " siteid=:1 ";
	     strWhere +="  and hazardid =:5";
	 	   strWhere += " and location is null and assetnum is null and hazardid in ";
	  	 strWhere += "	(SELECT X.HAZARDID "; 
	  	 strWhere += "	 FROM SAFETYLEXICON X ";
	     strWhere += "	 WHERE X.SITEID=:2" + " AND X.SAFETYLEXICONID IN " ;
	     strWhere += "	 (SELECT Y.SAFETYLEXICONID FROM SPLEXICONLINK Y " ;
	     strWhere += "	  WHERE  Y.SITEID=:3 " + " AND Y.SPWORKASSETID IN (SELECT Z.SPWORKASSETID ";
	     strWhere += "	  FROM   SPWORKASSET Z ";
	     strWhere += "	  WHERE  Z.SITEID=:4"  + " AND Z.SAFETYPLANID='FAWC-1')))";
	     
	     SqlFormat sqlformat = new SqlFormat(mboWo.getUserInfo(), strWhere);
	     
	     sqlformat.setObject(1, "SAFETYLEXICON", "siteid", strSiteid);
	     sqlformat.setObject(2, "SAFETYLEXICON", "siteid", strSiteid);
	     sqlformat.setObject(3, "SAFETYLEXICON", "siteid", strSiteid);
	     sqlformat.setObject(4, "SPWORKASSET", "siteid", strSiteid);
	     sqlformat.setObject(5, "SAFETYLEXICON", "hazardid", strHazardid);
	     		     
	     String strLink="LblUtil01_canDeleteHazard" + "_" + strLbl_workcntrhazard + "_" ;
	               strLink +=strHazardid;
	     
	     MboSetRemote mbosafetylexiconSet1= mboWo.getMboSet(strLink, "SAFETYLEXICON",sqlformat.format());
	     // Do not participate in transaction management
	     mbosafetylexiconSet1.setFlag(MboConstants.DISCARDABLE,true);
	     
	     if ( ! mbosafetylexiconSet1.isEmpty())
	    	  boolReturn=false;
	    	 
	     if (mbosafetylexiconSet1 !=null) { mbosafetylexiconSet1.close(); mbosafetylexiconSet1=null; }
	  	
	  } //if (strLbl_workcntrhazard !=null && 
		 // (strLbl_workcntrhazard.equals("2") || strLbl_workcntrhazard.equals("4")))
	  
	  return boolReturn;
}
}	





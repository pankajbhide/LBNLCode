/*
 * Copyright(c) Interloc Solutions, Inc.  All rights reserved.
 *
 * 09-Oct-2008	Rohith Ramamurthy	Created
 */
package com.interlocsolutions.maximo.iface.psfsc88;

import java.rmi.RemoteException;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.text.SimpleDateFormat;
import java.util.Iterator;
import java.util.List;

import org.jdom.CDATA;
import org.jdom.Document;
import org.jdom.Element;
import org.jdom.Namespace;
import org.jdom.output.XMLOutputter;

//import psdi.iface.mic.MicConstants;
import psdi.mbo.MboRemote;
import psdi.mbo.MboSetRemote;
import psdi.security.ConnectionKey;
import psdi.server.MXServer;
import psdi.util.MXApplicationException;
import psdi.util.MXException;

/**
*	PeopleSoft specific utility methods used by Outbound Interfaces.
*/
public class PSOutExt extends PSExt
{
	//private static int num=0;
    protected static final String DATE = "yyyy-MM-dd";
    protected static final String TIME = "HH:mm:ss.SSSSSS";
    protected static final String DATETIME = "yyyy-MM-dd'T'HH:mm:ss.SSSSSSZ";
    
    protected static Connection connPS = null;
    protected static String psDBOwner = null;


	/**
	* Constructor.
	*/
	public PSOutExt()
	{
	}
	
	/**
     * Adds a field to the field type portion of the XML with the proper field
     * name and type.
     * 
     *  @param
     *           name Give the Name of the field.
     * @param type
     *            Give the ps field type for the field.
     * @param parent
     *            Give the element the field will be added to.
     *  
     */
	public void createPSField(String name, String type, Element parent)
	{
	    integrationLogger.debug("Entering ERPOutExt.createPSField ");
	    
		Element psfield = new Element(name);
		psfield.setAttribute("type",type);
		parent.addContent(psfield);
		
		integrationLogger.debug("Leaving ERPOutExt.createPSField ");
		
	}
	
	/**
	*	Creates a XML field and adds a value to the field.
	*
	*	
	*	@param name Give the Name of the content to add.
	*	@param data Give the field value to map to name.
	*	@param parent Give the element to add the field and data to.
	*
	*/
	public void setPSField(String name, String data, Element parent)
	{
	    integrationLogger.debug("Entering ERPOutExt.setPSField ");
	    
		Element psfield = new Element(name);
		psfield.setText(data);
		parent.addContent(psfield);	
		
		integrationLogger.debug("Leaving ERPOutExt.setPSField ");
	
	}

	/**
	*	Contructs the structure of PeopleSoft XML needed for all outgoing
	*   transactions having the required header info.
	*
	*	
	*	@param name Give the Name of the Message.
	*	
	*	@return	the record structure element
	*
	*/
	public Element createPSRecordStructure(String  name)
	{
	    integrationLogger.debug("Entering ERPOutExt.createPSRecordStructure ");
	    
		Element psrecord = new Element(name);
		psrecord.setAttribute("class","R");

		integrationLogger.debug("Leaving ERPOutExt.createPSRecordStructure ");
		
		return psrecord;
	}

	/**
     * Contructs the structure of PeopleSoft XML needed for all outgoing
     * transactions having the required header info.
     * 
     *  @param
     *           psInterfaceData Top level of the PeopleSoft XML that the header
     *           info will be added to.
     * @return a Document Object representing the PeopleSoft XML.
     *  
     */
	public  Document buildPSXML(Element psInterfaceData) throws MXException
	{
		integrationLogger.debug("Entering ERPOutExt.buildPSHeader ");
		
		String extIface = getIfaceName();
		//Document psDoc = new Document();
		Element request = new Element("IBRequest");
		Document psDoc = new Document(request);
		
		//psDoc.setRootElement(request);
		
		//09.29.2008 Changed the interface names as per LBNL
        if(extIface.equals("MX_REQUISITION_IN"))
        	setPSField("ExternalOperationName",extIface+".VERSION_1",request);
            //values.put("ExternalOperationName", "MX_REQUISITION_IN.VERSION_1");
        if(extIface.equals("ITEM_SYNC"))
        	setPSField("ExternalOperationName",extIface+".VERSION_1",request);
            //values.put("ExternalOperationName", "ITEM_SYNC.VERSION_1");

		//setPSField("MessageName",extIface,request);

		Element from = new Element("From");
			
		setPSField("RequestingNode",getMaxIfaceControl().getValueControl(getExtSystem(),"FROM_NODE"),from);
		request.addContent(from);

		Element to = new Element("To");
				
		setPSField("DestinationNode",getMaxIfaceControl().getValueControl(getExtSystem(),"TO_NODE"),to);
		request.addContent(to);

		setPSField("MessageVersion","VERSION_1",request);

		Element contentSections = new Element("ContentSections");
		Element contSection = new Element("ContentSection");

		setPSField("NonRepudiation","",contSection);
		
		//for PR do not wrap now since we will split this later in the handler.
		Element data = new Element("Data");
		 if(extIface.equals("MX_REQUISITION_IN"))
		 {
			 data.addContent(psInterfaceData);
			 contSection.addContent(data);
		 }
		 else
		 {
			 CDATA psData = wrapPSXMLInCData(psInterfaceData);
			 data.addContent(psData);
			 contSection.addContent(data);
		 }

		contentSections.addContent(contSection);
		request.addContent(contentSections);

		integrationLogger.debug("Leaving ERPOutExt.buildPSHeader ");

		return psDoc;

	}// end buildPSHeader


	/**
	 * Method to wrap peoplesoft xml into a CData object for PS to accept our post.
	 *
	 * @param node the element that will be wrapped in CData
	 * 
	 * @return CData wrapped element
	 */
	public CDATA wrapPSXMLInCData(Element node)
	{
		integrationLogger.debug("Entering ERPOutExt.wrapPSXMLInCData ");
		//System.out.println("++++++++++++ Node is " +node);
		
		String xmlTag = "<?xml version=\"1.0\"?> ";
		String cDataString = null;
		String elementAsString = null;
			
		//outputter to get text in format needed for CDATA 
		XMLOutputter xotp = new XMLOutputter();
		elementAsString = xotp.outputString(node);
		
		cDataString = xmlTag + elementAsString;
		
		//add xmlTag and all data to the CDATA object
		CDATA cData = new CDATA(cDataString);
				
		integrationLogger.debug("Leaving ERPOutExt.wrapPSXMLInCData ");
		
		return cData;
		

	}

	/**
	*	Method to create the PSCAMA record, needed for transactions going to PSoft.
	*
	*	
	*	@return	an Element Object having the structure of PSCAMA record.
	*
	*/
	public Element createPSCAMAStruc()
	{
		integrationLogger.debug("Entering ERPOutExt.createPSCAMAStruc ");

		Element pscama = createPSRecordStructure("PSCAMA");

		createPSField("LANGUAGE_CD","CHAR",pscama);
		createPSField("AUDIT_ACTN","CHAR",pscama);
		createPSField("BASE_LANGUAGE_CD","CHAR",pscama);
		createPSField("PROCESS_INSTANCE","NUMBER",pscama);

		integrationLogger.debug("Leaving ERPOutExt.createPSCAMAStruc ");

		return pscama;
	}

	/**
	*	To Populate the PSCAMA record with Valid values.
	*
	*	
	*	@param action Give the type of action, whether its an add, update or delete.
	*	@return	a Element Object having the PSCAMA data.
	*
	*/
	public Element fillPSCAMAStruc(String action, boolean isfull) throws MXException, RemoteException
	{
	    integrationLogger.debug("Entering ERPOutExt.fillPSCAMAStruc ");
		Element pscama = createPSRecordStructure("PSCAMA");

		if (isfull)
		{
			setPSField("LANGUAGE_CD", getMaxIfaceControl().getXREFControlValue(getExtSystem(), "LANG_XREF", null, null, getUserInfo().getLangCode(), true),pscama);
			setPSField("AUDIT_ACTN",action,pscama);
			setPSField("PROCESS_INSTANCE","0",pscama);

		}
		else
		{
			setPSField("AUDIT_ACTN",action,pscama);
		}
		
		integrationLogger.debug("Leaving ERPOutExt.fillPSCAMAStruc ");
		
		return pscama;

	}

	/**
	*	To Populate the Gl Chartfield names in the FieldTypes section on PS XML.
	*
	*	
	*	@param psrecname Element name of PSXML where the chartfield names are being populated.
	*
	*	@return	a List of String having PS Chartfield names as defined in the XREF control.
	*/
	
	public List getPSChartFieldNames(Element psrecname) throws MXException
	{
		String name;
		integrationLogger.debug("Entering ERPOutExt.getPSChartFieldNames ");
		
		List cfnames = getMaxIfaceControl().getXREFControlValues(getExtSystem(),"COA_XREF");
		Iterator itr = cfnames.iterator();

		while(itr.hasNext())
		{
			name = (String)itr.next();
			createPSField(name,"CHAR",psrecname);
		}
		
		integrationLogger.debug("Leaving ERPOutExt.getPSChartFieldNames ");
		
		return cfnames;
	}
	
	/**
	*	To Populate the GL Chartfield Values in the PS XML.
	*
	*	
	*	@param glacct Name of the  IRs GL account field like GLDEBITACCT etc
	*	@param psrecname Element name of PSXML where the chartfield names are being populated.
	*	@param cfnames Staring List having chartfield names as defined in the XREF control.
	*
	*	@return	a List of String having PS Chartfield names as defined in the XREF control.
	*/
		
	public void getPSChartFieldValues(Element glacct,Element psrecname,List cfnames) throws MXException
	{
		String psname,value;
				
		integrationLogger.debug("Entering ERPOutExt.getPSChartFieldValues ");
		
//		List glcomps = glacct.getChildren("GLCOMP",Namespace.getNamespace(MicConstants.MRO_NAMESPACE));
		List glcomps = glacct.getChildren("GLCOMP",Namespace.getNamespace("http://www.ibm.com/maximo"));
		
		Iterator itr = glcomps.iterator();

		while(itr.hasNext())
		{			
			Element compvalue = (Element)itr.next();
			psname = getMaxIfaceControl().getXREFControlValue(getExtSystem(),"COA_XREF", null, null, compvalue.getAttributeValue("glorder"), true);
			
			cfnames.remove(psname);
			
			value = compvalue.getText();
			
			if (isStringNotNull(value))
			{
				if (value.equals("*"))
					value = "";
			}
										
			setPSField(psname,value,psrecname);
		}
		
		itr = cfnames.iterator();
		
		while(itr.hasNext())
		{			
			psname = (String)itr.next();
			setPSField(psname,"",psrecname);
		}
		
		integrationLogger.debug("Leaving ERPOutExt.getPSChartFieldValues ");
		
	}
	
	/**
	*	Method to Convert MAXIMO data format to a PS date format
	*
	*	
	*	@param mxdatecol Maximo date column
	*	@return	a String having date in YYYY_MM_DD format 
	*/
	public String getPSDate(String mxdatecol)
	{
		String psdate;
		
		if(mxdatecol == null || mxdatecol == "")
		{
			psdate = mxdatecol;
		}
		else
		{
			int i = mxdatecol.indexOf("T");
			psdate = mxdatecol.substring(0,i);
		}

		return psdate;
	}
	
	/**  
	 *	Method to Convert MAXIMO data time format to a PS date time format
	 *
	 *	
	 *	@param mxdatecol Maximo date column
	 *	@return	a String having date in YYYY_MM_DD HH:MM:SS.sss format 
	 */
	public String getPSDateTime(String mxdatecol)
	{
		String psdate;
		if(mxdatecol == null || mxdatecol == "")
		{
			psdate = mxdatecol;
		}
		else
		{
			mxdatecol.replace('T', ' ');
			mxdatecol.replace('-', '.');
			psdate = mxdatecol;
		}

		return psdate;
	} 

	/** 
	 *	Method to get MAXIMO time for PeopleSoft time field.
	 *
	 *	
	 *	@param mxdatecol Maximo date column
	 *	@return	a String having date in YYYY_MM_DD format 
	 */
	public String getPSTime(String mxdatecol)
	{
		String psdate;
	
		if(mxdatecol == null || mxdatecol == "")
		{
			psdate = mxdatecol;
		}
		else
		{
			int i = mxdatecol.indexOf("T");
			mxdatecol.replace('-', '.');
			psdate = mxdatecol.substring(i+1,mxdatecol.length());
		}
		
		integrationLogger.debug("Leaving ERPOutExt.getPSTime ");

		return psdate.trim();
	}

	/**
	*	Method to Convert MAXIMO data format to a PS date format.
	*   The date can be formatted to one of three formats:  
	*   DATE = "yyyy-MM-dd";
    *	TIME = "HH:mm:ss";
    *   DATETIME = "yyyy-MM-dd HH:mm:ss";
	*
	*	
	*	@param mxDateCol Maximo date column value
	*   @param format PeopleSoft format for the date.  Should be DATE, TIME or DATETIME.
	*	@return	a String having date in YYYY_MM_DD format 
	*/
	public String getPSDateTime(java.util.Date mxDateCol, String format) throws MXException
	{
	    integrationLogger.debug("Entering ERPOutExt.getPSDateTime ");
	    
	    if(mxDateCol == null || !isStringNotNull(mxDateCol.toString()))
	    {
	        return null;
	    }
	    
		String psDate = null;
		
        SimpleDateFormat sdf2 = new SimpleDateFormat(format);
        
        if(format.equals(DATE) || format.equals(TIME) || format.equals(DATETIME))
        {
	        try
	        {
	            psDate = sdf2.format(mxDateCol);
	        }
	        catch (Exception pe)
	        {
	            String[] params = {mxDateCol.toString()};
	            throw new MXApplicationException("iface", "ps-invaliddate", params);
	        }
        }
        else
        {
            String[] params = {mxDateCol.toString()};
            throw new MXApplicationException("iface", "ps-invaliddate", params);
        }
        
        integrationLogger.debug("Leaving ERPOutExt.getPSDateTime ");

		return psDate;
	}
	
	/**
	*	Method to separate the vendor and vendor_loc values from MAXIMO Vendor id.
	*
	*	
	*	@param vendor MAXIMO Vendor Column
	*   @param psrecname PS Xml tag name where the fields need to be set.	
	*/
	public void deconcatPSVendor(String vendor,Element psrecname) throws MXException 
	{
	    integrationLogger.debug("Entering ERPOutExt.deconcatPSVendor ");
	    
		//	Separate the Vendor and Location fields
	 	int i = 0;
		if ((vendor != null) && (! vendor.trim().equals("")))
		{
			 i =  vendor.indexOf(getMaxIfaceControl().getValueControl(getExtSystem(),"VNDR_LOC_DELIM"));
		 	if (i != -1)
		 	{
				setPSField("VENDOR_ID", vendor.substring(0,i),psrecname);
				setPSField("VNDR_LOC",vendor.substring(i + 1),psrecname);
			 }
		 	else
			 {
				setPSField("VENDOR_ID",vendor,psrecname);
				setPSField("VNDR_LOC","",psrecname);
		 	 }
	 	}
	 	else
	 	{
			setPSField("VENDOR_ID","",psrecname);
			setPSField("VNDR_LOC","",psrecname);
		}
		
		integrationLogger.debug("Leaving ERPOutExt.deconcatPSVendor ");
	}
	
	/**
	 *  Builds the Msgdata  part of the PeopleSoft xml.
	 *
	 *  @param transarea transarea portion of PeopleSoft XML.
	 *
	 *  @return Element having Msgdata portion of the PS XML.
	 */
	public Element buildPSMsgArea(Element transarea)
	{
	    integrationLogger.debug("Entering ERPOutExt.buildPSMsgArea ");
	    
		Element msg = new Element("MsgData");
		Element transaction = new Element("Transaction");

		msg.addContent(transaction);
		transarea.addContent(msg);

		integrationLogger.debug("Leaving ERPOutExt.buildPSMsgArea ");
		
		return transaction;

	}// end buildPSMsgArea

	/**
	 * Check item status in item table and throw exception if items is not
	 * active.
	 * 
	 * @param itemnum Item number
	 * @param currLine Current line number for PR or PO
	 * @param lineId Current line id number
	 * @param lineType Either "POLINE" or "PRLINE"
	 * @param purMbo Current PR Mbo
	 * 
	 * @exception MXException 
	 * @exception RemoteException
	 */
	public void checkItemStatus(String itemnum, String currLine, long lineId ,String lineType,MboRemote purMbo) throws MXException, RemoteException
	{
		integrationLogger.debug("Entering ERPOutExt.checkItemStatus ");
		
		//String lineNum = null;
		
		//get the mbo set
		MboSetRemote lineSet = purMbo.getMboSet(lineType);
		MboRemote line = null;
		
		line = lineSet.getMboForUniqueId(lineId);
		
		//get the item Mbo set for the current line
		MboSetRemote itemSet = line.getMboSet("ITEM");

		// move to the item that is on the PRLINE/POLINE
		MboRemote item = itemSet.moveFirst();

		// check if item is active
		if (item != null)
		{
						 
			//Throw exception if the item is not active
			if (isStringNotNull(item.getString("OWNERSYSID"))
					 &&
				 (item.getString("OWNERSYSID").equals(getExtSystem()))
				 	&&
				(!itemSet.getBoolean("EXT_ACTIVE")))
			{
				String[] params = {itemnum, currLine};
				throw new MXApplicationException("iface", "ps-itemnotactive", params);
			}
		}

		integrationLogger.debug("Leaving ERPOutExt.checkItemStatus ");
	}	
	
	/**
     * Check inventory to see if it is owned by external system for the PO 
     * or PR line.  If the inventory is owned by the external system then 
     * return true. 
     * 
     * @param storeLoc STORELOC value from MAXIMO data
     * @param currLine Line number from PR or PO
     * @param lineID Current line id number
     * @param lineType Either "PRLINE" or "POLINE"
     * @param prMbo Current PR Mbo
     * 
     * @exception MXException 
     * @exception RemoteException
     */
    protected boolean checkInventory(String storeLoc, long lineID, String lineType, MboRemote purMbo) throws MXException, RemoteException
    {
        integrationLogger.debug("Entering ERPOutExt.checkInventory ");

        //String lineNum = null;
        boolean mapInventory = false;
        
        if(!isStringNotNull(storeLoc))
        {
            return mapInventory;
        }
        
        //get the mbo set
		MboSetRemote lineSet = purMbo.getMboSet(lineType);
		MboRemote line = null;
		
		line = lineSet.getMboForUniqueId(lineID);
		
		//get the item Mbo set for the current line
		MboSetRemote inventorySet = line.getMboSet("INVENTORY");

		// move to the item that is on the PRLINE/POLINE
		MboRemote inventory = inventorySet.moveFirst();

		// check if item is active
		if ((inventory != null)
				 &&
			(isStringNotNull(inventory.getString("OWNERSYSID"))
				&&
			(inventory.getString("OWNERSYSID").equals(getExtSystem()))))
		{
			mapInventory = true;
			 
		}
		
		integrationLogger.debug("Leaving ERPOutExt.checkInventory ");

		return mapInventory;

	}
    
    /**
	 * retrieve program code from PeopleSoft for a PRLINE with non-STORE category code. 
	 * 
	 * @param orgID Org Id of PR
	 * @param refWo Work order number from PR Line
	 * 
	 * @exception MXException 
	 * @exception RemoteException
	 */
    public String retrieveProgramCodeForNonStoreCatCode(String orgID, String refWo)
    throws MXException, RemoteException
	{
    	integrationLogger.debug("Starting retrieveProgramCodeForNonStoreCatCode");
	    PreparedStatement sel = null;
	    ResultSet rset = null;
	    String programCode = "";
	    integrationLogger.debug("orgID = '" + orgID + "'");
	    integrationLogger.debug("refWo = '" + refWo + "'");
	    String sql = "SELECT  PROGRAM_CODE FROM    " + psDBOwner + ".PS_PROJECT_STATUS A  " + "WHERE   BUSINESS_UNIT ='" + orgID + "' " + "AND     PROJECT_ID    = '" + refWo + "' " + "AND     EFFDT = (SELECT  MAX(EFFDT)  " + "FROM " + psDBOwner + ".PS_PROJECT_STATUS " + "WHERE  PROJECT_ID = A.PROJECT_ID " + "AND   EFFDT      <= SYSDATE) " + "AND     EFFSEQ =(SELECT MAX(EFFSEQ)  " + "FROM " + psDBOwner + ".PS_PROJECT_STATUS " + "WHERE  PROJECT_ID = A.PROJECT_ID " + "AND   EFFDT      <= SYSDATE)";
	    integrationLogger.debug("sql = '" + sql + "'");
	    try
	    {
	        sel = connPS.prepareStatement(sql);
	        rset = sel.executeQuery();
	        rset.next();
	        programCode = rset.getString(1);
	        integrationLogger.debug("programCode = '" + programCode + "'");
	        rset.close();
	        sel.close();
	    }
	    catch(Exception e)
	    {
	        integrationLogger.debug("NOPCforNonStoreCC for refwo - "+refWo);
	    }
	    finally
	    {
	        try
	        {
	            sel.close();
	            rset.close();
	        }
	        catch(Exception e)
	        {
	        	integrationLogger.debug(this, e);
	        }
	    }
	    return programCode;
	}
    
    /**
	 * retrieve class field from PeopleSoft for a PRLINE with non-STORE category code. 
	 * 
	 * @param orgID Org Id of PR
	 * @param refWo Work order number from PR Line
	 * 
	 * @exception MXException 
	 * @exception RemoteException
	 */
    public String retrieveClassFldForNonStoreCatCode(String orgID, String refWo)
    throws MXException, RemoteException
	{
    	integrationLogger.debug("Starting retrieveClassFldForNonStoreCatCode");
	    PreparedStatement sel = null;
	    ResultSet rset = null;
	    String classFld = "";
	    integrationLogger.debug("orgID = '" + orgID + "'");
	    integrationLogger.debug("refWo = '" + refWo + "'");
	    String sql = "SELECT  CLASS_FLD FROM    " + psDBOwner + ".PS_PROJECT_STATUS A  " + "WHERE   BUSINESS_UNIT ='" + orgID + "' " + "AND     PROJECT_ID    = '" + refWo + "' " + "AND     EFFDT = (SELECT  MAX(EFFDT)  " + "FROM " + psDBOwner + ".PS_PROJECT_STATUS " + "WHERE  PROJECT_ID = A.PROJECT_ID " + "AND   EFFDT      <= SYSDATE) " + "AND     EFFSEQ =(SELECT MAX(EFFSEQ)  " + "FROM " + psDBOwner + ".PS_PROJECT_STATUS " + "WHERE  PROJECT_ID = A.PROJECT_ID " + "AND   EFFDT      <= SYSDATE)";
	    integrationLogger.debug("sql = '" + sql + "'");
	    try
	    {
	        sel = connPS.prepareStatement(sql);
	        rset = sel.executeQuery();
	        rset.next();
	        classFld = rset.getString(1);
	        integrationLogger.debug("classFld = '" + classFld + "'");
	        rset.close();
	        sel.close();
	    }
	    catch(Exception e)
	    {
	        integrationLogger.debug("NOCFforNonStoreCC for refwo - "+refWo);
	    }
	    finally
	    {
	        try
	        {
	            sel.close();
	            rset.close();
	        }
	        catch(Exception e)
	        {
	        	integrationLogger.debug(this, e);
	        }
	    }
	    return classFld;
	}
    
    /**
	 * retrieve fund code from PeopleSoft for a PRLINE with non-STORE category code. 
	 * 
	 * @param orgID Org Id of PR
	 * @param refWo Work order number from PR Line
	 * 
	 * @exception MXException 
	 * @exception RemoteException
	 */
    public String retrieveFundCodeForNonStoreCatCode(String orgID, String refWo)
    throws MXException, RemoteException
	{
    	integrationLogger.debug("Starting retrieveFundCodeForNonStoreCatCode");
	    PreparedStatement sel = null;
	    ResultSet rset = null;
	    String fundCode = "";
	    integrationLogger.debug("orgID = '" + orgID + "'");
	    integrationLogger.debug("refWo = '" + refWo + "'");
	    String sql = "SELECT  FUND_CODE FROM    " + psDBOwner + ".PS_PROJECT_STATUS A  " + "WHERE   BUSINESS_UNIT ='" + orgID + "' " + "AND     PROJECT_ID    = '" + refWo + "' " + "AND     EFFDT = (SELECT  MAX(EFFDT)  " + "FROM " + psDBOwner + ".PS_PROJECT_STATUS " + "WHERE  PROJECT_ID = A.PROJECT_ID " + "AND   EFFDT      <= SYSDATE) " + "AND     EFFSEQ =(SELECT MAX(EFFSEQ)  " + "FROM " + psDBOwner + ".PS_PROJECT_STATUS " + "WHERE  PROJECT_ID = A.PROJECT_ID " + "AND   EFFDT      <= SYSDATE)";
	    integrationLogger.debug("sql = '" + sql + "'");
	    try
	    {
	        sel = connPS.prepareStatement(sql);
	        rset = sel.executeQuery();
	        rset.next();
	        fundCode = rset.getString(1);
	        integrationLogger.debug("fundCode = '" + fundCode + "'");
	        rset.close();
	        sel.close();
	    }
	    catch(Exception e)
	    {
	        String params[] = {
	            refWo
	        };
	        integrationLogger.debug("NOFCforNonStoreCC for refwo - "+params);
	    }
	    finally
	    {
	        try
	        {
	            sel.close();
	            rset.close();
	        }
	        catch(Exception e)
	        {
	        	integrationLogger.debug(this, e);
	        }
	    }
	    return fundCode;
	}
    
    /**
	 * retrieve Project Id from PeopleSoft for a PRLINE with non-STORE category code. 
	 * 
	 * @param orgID Org Id of PR
	 * @param refWo Work order number from PR Line
	 * 
	 * @exception MXException 
	 * @exception RemoteException
	 */
    public String retrieveProjectIDForNonStoreCatCode(String orgID, String refWo)
    throws MXException, RemoteException
	{
	    integrationLogger.debug("Starting retrieveProjectIDForNonStoreCatCode");
	    PreparedStatement sel = null;
	    ResultSet rset = null;
	    String projectID = "";
	    integrationLogger.debug("orgID = '" + orgID + "'");
	    integrationLogger.debug("refWo = '" + refWo + "'");
	    String sql = "SELECT  PROJECT_ID FROM    " + psDBOwner + ".PS_PROJECT_STATUS A  " + "WHERE   BUSINESS_UNIT ='" + orgID + "' " + "AND     PROJECT_ID    = '" + refWo + "' " + "AND     EFFDT = (SELECT  MAX(EFFDT)  " + "FROM " + psDBOwner + ".PS_PROJECT_STATUS " + "WHERE  PROJECT_ID = A.PROJECT_ID " + "AND   EFFDT      <= SYSDATE) " + "AND     EFFSEQ =(SELECT MAX(EFFSEQ)  " + "FROM " + psDBOwner + ".PS_PROJECT_STATUS " + "WHERE  PROJECT_ID = A.PROJECT_ID " + "AND   EFFDT      <= SYSDATE)";
	    integrationLogger.debug("sql = '" + sql + "'");
	    try
	    {
	        sel = connPS.prepareStatement(sql);
	        rset = sel.executeQuery();
	        rset.next();
	        projectID = rset.getString(1);
	        integrationLogger.debug("projectID = '" + projectID + "'");
	        rset.close();
	        sel.close();
	    }
	    catch(Exception e)
	    {
	        String params[] = {
	            refWo
	        };
	        integrationLogger.debug("No projectID for refwo - "+params+e.getMessage());;
	    }
	    finally
	    {
	        try
	        {
	            sel.close();
	            rset.close();
	        }
	        catch(Exception e)
	        {
	        	integrationLogger.debug(e.getMessage());
	        }
	    }
	    integrationLogger.debug("Leaving retrieveProjectIDForNonStoreCatCode");
	    return projectID;
	}
    
    /**
     * Check LBL table to get the program code for a PRLINE with category code STORE. 
     * 
     * @param glDebitAcct PR line charge account.
     * @param orgID Org Id of PR
     * @param siteID Site Id of PR
     * @param itemNum Item number on the PR Line.
     * 
     * @exception MXException 
     * @exception RemoteException
     */
    public String retrieveProgramCodeForStoreCatCode(String glDebitAcct, String orgID, String siteID, String itemNum)
    throws MXException, RemoteException
	{
    	integrationLogger.debug("Starting retrieveProgramCodeForStoreCatCode");
    	ConnectionKey c = new ConnectionKey(getUserInfo());
        Connection conn = MXServer.getMXServer().getDBManager().getConnection(c);
	    //IfaceUtil iUtil = new IfaceUtil(getUserInfo());
	    PreparedStatement sel = null;
	    ResultSet rset = null;
	    String programCode = "";
	    String itemGroup = itemNum.substring(0, 2);
	    integrationLogger.debug("glDebitAcct = '" + glDebitAcct + "'");
	    integrationLogger.debug("orgID = '" + orgID + "'");
	    integrationLogger.debug("siteID = '" + siteID + "'");
	    integrationLogger.debug("itemNum = '" + itemNum + "'");
	    integrationLogger.debug("itemGroup = '" + itemGroup + "'");
	    //Connection conn = iUtil.getConnection();
	    String sql = "SELECT PROGRAM_CODE FROM LBL_ITEMGROUP_PROGRAM_CODE WHERE ITEMGROUP='" + itemGroup + "' " + "AND   ACCOUNT='" + glDebitAcct + "' " + "AND   ORGID='" + orgID + "' " + "AND   SITEID='" + siteID + "' " + "AND   EFFECTIVE_DATE = (SELECT MAX(B.EFFECTIVE_DATE) " + "FROM  LBL_ARCHIVE.LBL_ITEMGROUP_PROGRAM_CODE B " + "WHERE B.ITEMGROUP='" + itemGroup + "' " + "AND   B.ACCOUNT='" + glDebitAcct + "' " + "AND   B.ORGID='" + orgID + "' " + "AND   B.SITEID='" + siteID + "') ";
	    integrationLogger.debug("sql = '" + sql + "'");
	    try
	    {
	        sel = conn.prepareStatement(sql);
	        rset = sel.executeQuery();
	        rset.next();
	        programCode = rset.getString(1);
	        integrationLogger.debug("programCode = '" + programCode + "'");
	        rset.close();
	        sel.close();
	    }
	    catch(Exception e)
	    {
	        String params[] = {
	            itemGroup, glDebitAcct
	        };
	        throw new MXApplicationException("iface", "NOPCforStoreCC", params);
	    }
	    finally
	    {
	        try
	        {
	            sel.close();
	            rset.close();
	            conn.close();
	        }
	        catch(Exception e)
	        {
	        	integrationLogger.debug(this, e);
	        }
	    }
	    integrationLogger.debug("Leaving retrieveProgramCodeForStoreCatCode");
	    return programCode;
	}
    
    
    /**
     * Open a connection to the PS Database. 
     * 
     * 
     * @exception MXException 
     * @exception RemoteException
     * @exception SQLException
     * @exception ClassNotFoundException
     */
    public void setPSDBConnection()
    throws MXException, RemoteException, SQLException, ClassNotFoundException
	{
	    try
	    {
	    	integrationLogger.debug("Starting setPSDBConnection");
	    	//get all parameters for a DB connection.
	    	        
	        integrationLogger.debug("got mxserver");
	        String driver = getMaxIfaceControl().getValueControl(getExtSystem(),"PS_DRIVER");
	        integrationLogger.debug("driver:  " + driver);
	        String url = getMaxIfaceControl().getValueControl(getExtSystem(),"PS_URL");;
	        integrationLogger.debug("url:  " + url);
	        String user = getMaxIfaceControl().getValueControl(getExtSystem(),"PS_USERNAME");;
	        integrationLogger.debug("user:  " + user);
	        String password = getMaxIfaceControl().getValueControl(getExtSystem(),"PS_PASSWORD");;
	        integrationLogger.debug("password:  " + password);
	        psDBOwner = getMaxIfaceControl().getValueControl(getExtSystem(),"PS_OWNER");;
	        integrationLogger.debug("psDBOwner:  " + psDBOwner);
	        Class.forName(driver);
	        connPS = DriverManager.getConnection(url, user, password);
	    }
	    catch(Exception e)
	    {
	        String params[] = {
	            e.getMessage()
	        };
	        integrationLogger.debug(params);
	    }
	    integrationLogger.debug("Leaving setPSDBConnection");
	}
    
    /**
     * Close the connection to the PS Database. 
     * 
     * 
     * @exception MXException 
     * @exception RemoteException
     * @exception SQLException
     * @exception ClassNotFoundException
     */
    public void closePSDBConnection()
    throws MXException, RemoteException, SQLException, ClassNotFoundException
	{
    	integrationLogger.debug("Starting closePSDBConnection");
	    try
	    {
	        connPS.close();
	        connPS = null;
	    }
	    catch(Exception e)
	    {
	    	integrationLogger.debug("Error in closePSDBConnection: " + e.getMessage());
	    }
	    integrationLogger.debug("Leaving closePSDBConnection");
	}
    
    private static int num = 0;
    
    /**
     * Get a new number.
     * 
     *  @return integer
     */
    public static synchronized int nextNum()
    {
        num++;
        if(num == 0xf4240)
        {
            num = 1;
        }
        return num;
    }
}
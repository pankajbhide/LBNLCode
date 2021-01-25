/*
 * Copyright(c) Interloc Solutions, Inc.  All rights reserved.
 *
 * 09-Oct-2008	Rohith Ramamurthy	Created
 * 
 * 
 * 05-MAR-2010 Pankaj Bhide - Fixed the values of elements required by PeopleSoft
 */
package com.interlocsolutions.maximo.iface.psfsc88;

import java.rmi.RemoteException;
import java.text.SimpleDateFormat;
import java.util.Date;

import org.jdom.Document;
import org.jdom.Element;

import psdi.iface.mic.StructureData;
import psdi.util.MXException;

/**
 *  Maps MAXIMO Item to PeopleSoft MX6_ITEM_TOPS message structure.
 */
public class ItemOutExt extends PSOutExt
{
	private String description;
	private String longDescription;
	private String psSETID;

	public ItemOutExt()
	{

	}

	/**
	 *	Maps MAXIMO data to PeopleSoft Item.
	 *
	 *	@return PeopleSoft MX6_ITEM_TOPS message data.
	 *	
	 */
	public StructureData setDataOut(StructureData exitData) throws MXException, RemoteException
	{
		integrationLogger.debug("Entering ItemOutExt.setDataOut ");

		/*if(exitData.isCurrentDataNull("PS_ITEMCATEGORY"))
		{
			throw new MXSystemException("iface","ps-noitemcat");
		}*/
		
		Element transdata = new Element(this.ifaceName);
		transdata.addContent(buildPSFieldArea());

		Element msg = new Element("MsgData");
		transdata.addContent(msg);

		Element transaction = new Element("Transaction");
		msg.addContent(transaction);

		buildMasterItem(transaction, exitData);
		
		Document psdoc = buildPSXML(transdata);
//		StructureData psData = new StructureData(psdoc, getAdapterType(), false);
		StructureData psData = new StructureData(psdoc);
		
		integrationLogger.debug("Leaving ItemOutExt.setDataOut ");
		
		return psData;
	}

	/**
	 *	Builds the field area of the MX6_ITEM_TOPS message.
	 *
	 *	@return Element containing all field types.
	 *	
	 */
	private Element buildPSFieldArea()
	{
		integrationLogger.debug("Entering ItemOutExt.buildPSFieldArea ");

		// These are the PS fields which we are mapping data to

		Element master = createPSRecordStructure("MASTER_ITEM_EVW");
		Element inv = createPSRecordStructure("INV_ITM_EVW");
		Element invUOM = createPSRecordStructure("INV_ITM_UOM_EVW");
		Element pur = createPSRecordStructure("PUR_ITM_ATR_EVW");
		
		//MASTER_ITEM_EVW table
		createPSField("SETID", "CHAR", master);
		createPSField("INV_ITEM_ID", "CHAR", master);
		createPSField("CM_GROUP", "CHAR", master);
		createPSField("DESCR60", "CHAR", master);
		createPSField("ITM_STATUS_CURRENT", "CHAR", master);
		createPSField("ITM_STATUS_FUTURE", "CHAR", master);
		createPSField("ITM_STAT_DT_FUTURE", "DATE", master);
		createPSField("ORIG_OPRID", "CHAR", master);
		createPSField("UNIT_MEASURE_STD", "CHAR", master);
		createPSField("CATEGORY_CD", "CHAR", master);

		//INV_ITEM_EVW table
		createPSField("SETID", "CHAR", inv);
		createPSField("INV_ITEM_ID", "CHAR", inv);
		createPSField("DESCR254", "CHAR", inv);
		createPSField("INTL_HAZARD_ID", "CHAR", inv);
		createPSField("MSDS_ID", "CHAR", inv);

		//INV_ITM_UOM_EVW table
		createPSField("SETID", "CHAR", invUOM);
		createPSField("INV_ITEM_ID", "CHAR", invUOM);
		createPSField("UNIT_OF_MEASURE", "CHAR", invUOM);
		createPSField("DFLT_UOM_STOCK", "CHAR", invUOM);

		//PUR_ITM_ATR_EVW table
		createPSField("SETID", "CHAR", pur);
		createPSField("INV_ITEM_ID", "CHAR", pur);
		createPSField("DESCR", "CHAR", pur);
		createPSField("DESCR254_MIXED", "CHAR", pur);
		createPSField("DESCRSHORT", "CHAR", pur);
		createPSField("PRICE_LIST", "NUMBER", pur);
		createPSField("INSPECT_CD", "CHAR", pur);
		createPSField("USE_CAT_SRC_CNTL", "CHAR", pur);

		Element ftypes = new Element("FieldTypes");
		ftypes.addContent(master);
		ftypes.addContent(inv);
		ftypes.addContent(invUOM);
		ftypes.addContent(pur);

		ftypes.addContent(createPSCAMAStruc());

		integrationLogger.debug("Leaving ItemOutExt.buildPSFieldArea ");
		
		return ftypes;

	} // end buildPSFieldArea

	/**
     * Builds the MASTER_ITEM_EVW record of the MX6_ITEM_TOPS message.
     * 
     * @param transaction
     *            Reference to transaction portion of the peoplesoft xml.
     * @param in
     *            Reference to Maximos item data.
     * 
     * @exception MXException
     *                MAXIMO exception
     * @exception RemoteException
     *                Remote exception
     */
    private void buildMasterItem(Element transaction, StructureData in)
            throws MXException, RemoteException
    {
        integrationLogger.debug("Entering ItemOutExt.buildMasterItem ");

        Element item = createPSRecordStructure("MASTER_ITEM_EVW");

        //Get the description and long description for all levels
        //description = setDescription(in, "DESCRIPTION");
        if(!in.isCurrentDataNull("DESCRIPTION"))
        {
            if(in.getCurrentData("DESCRIPTION").trim().length() > 60)
            {
            	description = in.getCurrentData("DESCRIPTION").substring(0, 59);
            } else
            {
            	description = in.getCurrentData("DESCRIPTION");
            }
        } else
        {
        	description = " ";
        }
        
        //longDescription = setDescription(in, "DESCRIPTION_LONGDESCRIPTION");
        if(in.getCurrentData("DESCRIPTION_LONGDESCRIPTION") != null && !in.getCurrentData("DESCRIPTION_LONGDESCRIPTION").trim().equals(""))
        {
            if(in.getCurrentData("DESCRIPTION_LONGDESCRIPTION").trim().length() > 254)
            {
            	longDescription = in.getCurrentData("DESCRIPTION_LONGDESCRIPTION").substring(0, 253);
            } else
            {
            	longDescription = in.getCurrentData("DESCRIPTION_LONGDESCRIPTION");
            }
        } else
        {
        	longDescription = description;
        }
        
        //psSETID = getMaxIfaceControl().getXREFControlValue(getExtSystem(),
        //    "ITEMSET_SETID", null, null, in.getCurrentData("ITEMSETID"), true);

        psSETID="LBNL";  // Pankaj - Required by PeopleSoft 3/5/10 
        
        setPSField("SETID", psSETID, item);
        setPSField("INV_ITEM_ID", in.getCurrentData("ITEMNUM"), item);
        setPSField("CM_GROUP",getMaxIfaceControl().getValueControl(getExtSystem(),"ITEM_CM_GROUP"),item);
        setPSField("DESCR60", description, item);
        
        if(in.getAction().substring(0,1).equalsIgnoreCase("A"))
        {
        	setPSField("ITM_STATUS_CURRENT","1", item);
        	setPSField("ITM_STATUS_FUTURE","", item);
        	setPSField("ITM_STAT_DT_FUTURE","", item);
        }else if(in.getAction().substring(0,1).equalsIgnoreCase("C")||in.getAction().substring(0,1).equalsIgnoreCase("R"))
        {
        	setPSField("ITM_STATUS_CURRENT","1", item);
        	setPSField("ITM_STATUS_FUTURE"," ", item);
        	setPSField("ITM_STAT_DT_FUTURE","", item);
        }else if(in.getAction().substring(0,1).equalsIgnoreCase("D"))
        {
        	setPSField("ITM_STATUS_CURRENT"," ", item);
        	setPSField("ITM_STATUS_FUTURE","4", item);
        	SimpleDateFormat simpledateformat = new SimpleDateFormat("yyyy-MM-dd");
        	setPSField("ITM_STAT_DT_FUTURE",simpledateformat.format(new Date()), item);
        }
        
        setPSField("ORIG_OPRID","MAXIMO", item);
        //setPSField("UNIT_MEASURE_STD", in.getCurrentData("IN26"), item);
        setPSField("UNIT_MEASURE_STD", in.getCurrentData("ISSUEUNIT"), item);
        
        String s1 = in.getCurrentData("IN21");
        if(s1 == null || s1.trim().equals(""))
        {
            s1 = null;
        }
        String s2 = getMaxIfaceControl().getValueControl(getExtSystem(),"ITEM_CAT_DFLT");
        if(s1 == null && s2 != null && !s2.equals("USER_DEFINED"))
        {
        	setPSField("CATEGORY_CD", s2, item);
        } else
        {
        	setPSField("CATEGORY_CD", s1, item);
        }

        transaction.addContent(item);
        transaction.addContent(fillPSCAMAStruc(in.getAction().substring(0, 1),
            true));

        buildInvItem(item, in);
        buildInvItemUOM(item, in);
        buildPurItm(item, in);
        //buildLangDescr(item, in);
        //buildLangLongDescr(item, in);

        integrationLogger.debug("Leaving ItemOutExt.buildMasterItem ");

    } // end buildPSDataArea

	/**
	 *	Builds the INV_ITM_EVW record of the MX6_ITEM_TOPS message.
	 *
	 *	@param masterItem Reference to MASTER_ITEM_EVW record of the peoplesoft xml.
	 *	@param in Reference to Maximos item data.
     *
	 *	@exception MXException	MAXIMO exception
	 *	@exception RemoteException Remote exception
	 */
	private void buildInvItem(Element masterItem, StructureData in) throws MXException, RemoteException
	{
		integrationLogger.debug("Entering ItemOutExt.buildInvItem ");
		
		Element invItm = createPSRecordStructure("INV_ITM_EVW");

		setPSField("SETID", psSETID, invItm);
		setPSField("INV_ITEM_ID", in.getCurrentData("ITEMNUM"), invItm);
		setPSField("DESCR254", longDescription, invItm);
		setPSField("INTL_HAZARD_ID", "", invItm);
		setPSField("MSDS_ID", in.getCurrentData("MSDSNUM"), invItm);

		masterItem.addContent(invItm);
		masterItem.addContent(fillPSCAMAStruc(in.getAction().substring(0, 1), true));
		
		integrationLogger.debug("Leaving ItemOutExt.buildInvItem ");

	} // end buildPSDataArea

	/**
	 *	Builds the INV_ITM_UOM_EVW record of the MX6_ITEM_TOPS message.
	 *
	 *	@param masterItem Reference to MASTER_ITEM_EVW record of the peoplesoft xml.
	 *	@param in Reference to Maximos item data.
     *
	 *	@exception MXException	MAXIMO exception
	 *	@exception RemoteException Remote exception
	 */
	private void buildInvItemUOM(Element masterItem, StructureData in) throws MXException, RemoteException
	{
		integrationLogger.debug("Entering ItemOutExt.buildInvItemUOM ");
		
		Element invItmUOM = createPSRecordStructure("INV_ITM_UOM_EVW");

		setPSField("SETID", psSETID, invItmUOM);
		setPSField("INV_ITEM_ID", in.getCurrentData("ITEMNUM"), invItmUOM);
		//setPSField("UNIT_OF_MEASURE", in.getCurrentData("IN26"), invItmUOM);
		setPSField("UNIT_OF_MEASURE", in.getCurrentData("ISSUEUNIT"), invItmUOM);
		setPSField("DFLT_UOM_STOCK", "Y", invItmUOM);
		
		masterItem.addContent(invItmUOM);
		masterItem.addContent(fillPSCAMAStruc(in.getAction().substring(0, 1), true));
		
		integrationLogger.debug("Leaving ItemOutExt.buildInvItemUOM ");
		
	} // end buildPSDataArea

	/**
	 *	Builds the PUR_ITM_ATR_EVW record of the MX6_ITEM_TOPS message.
	 *
	 *	@param masterItem - Reference to MASTER_ITEM_EVW record of the peoplesoft xml.
	 *	@param in - Reference to Maximos item data.
	 *
	 *	@return - Object having data in PeopleSoft specific format.
	 *
	 *	@exception MXException MAXIMO exception
	 *	@exception RemoteException Remote exception
	 */
	private void buildPurItm(Element masterItem, StructureData in) throws MXException, RemoteException
	{
		integrationLogger.debug("Entering ItemOutExt.buildPurItm ");

		Element purItm = createPSRecordStructure("PUR_ITM_ATR_EVW");

		setPSField("SETID", psSETID, purItm);
		setPSField("INV_ITEM_ID", in.getCurrentData("ITEMNUM"), purItm);
		
		if(in.getCurrentDataAsDouble("IN23") == 0.0D)
        {
			setPSField("PRICE_LIST", "0.0", purItm);
		} else
        {
			setPSField("PRICE_LIST", in.getCurrentData("IN23"), purItm);
        }
		
		if(!in.isCurrentDataNull("DESCRIPTION"))
		{
			if(description.trim().length()>30)
			{
				setPSField("DESCR", description.substring(0, 29), purItm);
			}else
			{
				setPSField("DESCR", description, purItm);
			}
			if(description.trim().length()>10)
			{
				setPSField("DESCRSHORT", description.substring(0, 9), purItm);
			}else
			{
				setPSField("DESCRSHORT", description, purItm);
			}
		}else
		{
			setPSField("DESCR", " ", purItm);
			setPSField("DESCRSHORT", " ", purItm);
		}
		
		setPSField("DESCR254_MIXED", longDescription, purItm);
		
		//setPSField("INSPECT_CD", in.getCurrentData("INSPECTIONREQUIRED"), purItm);
		// Required by PeopleSoft - Pankaj 3/5/10
		
		setPSField("INSPECT_CD", "N", purItm);
		setPSField("USE_CAT_SRC_CNTL", "Y", purItm);
		
		masterItem.addContent(purItm);
		masterItem.addContent(fillPSCAMAStruc(in.getAction().substring(0, 1), true));
		
		integrationLogger.debug("Leaving ItemOutExt.buildPurItm ");
		
	} // end buildPSDataArea

//	/**
//	 * 	Returns description or empty string if null(required field in PS)
//	 *  
//	 * @param in reference to Maximo data
//	 * @param name Name of description column
//	 * 
//	 * @return description 
//	 */
//	public String setDescription(StructureData in, String name)
//	{
//		integrationLogger.debug("Entering ItemOutExt.setDescription ");
//		
//		String desc;
//
//		if (in.isCurrentDataNull(name))
//		{
//			desc = " ";
//		}
//		else
//		{
//			desc = in.getCurrentData(name);
//		}
//
//		integrationLogger.debug("Leaving ItemOutExt.setDescription ");
//		
//		return desc;
//
//	}
}

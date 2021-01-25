/*
 * Copyright(c) Interloc Solutions, Inc.  All rights reserved.
 *
 * 09-Oct-2008	Rohith Ramamurthy	Created
 * 
 * 16-May-2014  Praveen Muramalla Modified
 * 				FSM Changes to set LBL_DEPT_CODE and LBL_FUND_CODE
 * 
 * 10-Aug-2016  Pankaj Bhide JIRA EF-4082
 */
package com.interlocsolutions.maximo.iface.psfsc88;

import java.rmi.RemoteException;
import java.util.Iterator;
import java.util.List;

import org.jdom.Document;
import org.jdom.Element;

import psdi.iface.mic.StructureData;
import psdi.mbo.MboRemote;
import psdi.mbo.MboSetRemote;
import psdi.server.MXServer;
import psdi.util.MXApplicationException;
import psdi.util.MXException;

/**
 * 
 * Maps MAXIMO PR to PeopleSoft MX6_PR_TOPS message structure.
 */
public class PROutExt extends PSOutExt
{
    //private List cfNames;

    private boolean headerComment;
    private boolean isStore;
    int grp_seq=0;

    public PROutExt()
    {

    }

    /**
     * Maps MAXIMO data to PeopleSoft PR.
     * 
     * @param exitData
     *            Reference to MAXIMO PR data.
     * 
     * @return PeopleSoft MX6_PR_TOPS message data.
     */
    public StructureData setDataOut(StructureData exitData) throws MXException,
            RemoteException
    {
        integrationLogger.debug("Entering PROutExt.setDataOut ");
        //HAQ
        exitData.breakData();
        checkStatus(exitData, "PRSEND", exitData.getCurrentData("ORGID"), exitData
            .getCurrentData("SITEID"));
        
        //boolean firstRecord;
        Element transdata = new Element(getIfaceName());
        transdata.addContent(buildPSFieldArea());

        // We don't have to ceate the transaction level here for PRs.
        //PRs are a special case with multiple transaction nodes in PS Xml.

        Element msg = new Element("MsgData");
        transdata.addContent(msg);

        //set the header comment so each PR will only set the header
        // comment once
        headerComment = false;
        buildReqLoad(msg, exitData);

        //Create a document by passing the CDATA as a string
        Document psdoc = buildPSXML(transdata);
//      StructureData psData = new StructureData(psdoc, getAdapterType(), false);
        StructureData psData = new StructureData(psdoc);

        integrationLogger.debug("Leaving PROutExt.setDataOut ");

        return psData;
    }

    /**
     * Builds the field area of the MX6_ITEM_TOPS message.
     * 
     * @return Element containing all field types.
     * 
     * @throws MXException
     *             MAXIMO exception
     */
    private Element buildPSFieldArea() throws MXException
    {
        integrationLogger.debug("Entering PROutExt.buildPSFieldArea ");

        // These are the PS fields which we are mapping data to
        Element reqLoadSeg = createPSRecordStructure("PO_REQLOAD_SEG");

        createPSField("LOADER_BU", "CHAR", reqLoadSeg);
        createPSField("GROUP_SEQ_NUM", "NUMBER", reqLoadSeg);
        createPSField("REQUESTOR_ID", "CHAR", reqLoadSeg);
        createPSField("DUE_DT", "DATE", reqLoadSeg);
        createPSField("INV_ITEM_ID", "CHAR", reqLoadSeg);
        createPSField("CALC_PRICE_FLG", "CHAR", reqLoadSeg);
        createPSField("DESCR254_MIXED", "CHAR", reqLoadSeg);
        createPSField("UNIT_OF_MEASURE", "CHAR", reqLoadSeg);
        createPSField("CURRENCY_CD", "CHAR", reqLoadSeg);
        createPSField("VENDOR_ID", "CHAR", reqLoadSeg);
        createPSField("QTY_REQ", "NUMBER", reqLoadSeg);
        createPSField("PRICE_REQ", "NUMBER", reqLoadSeg);
        createPSField("LOCATION", "CHAR", reqLoadSeg);
        createPSField("SHIPTO_ID", "CHAR", reqLoadSeg);
        createPSField("MX_ORIGIN", "CHAR", reqLoadSeg);
        createPSField("REQ_ID", "CHAR", reqLoadSeg);
        createPSField("LINE_NBR", "NUMBER", reqLoadSeg);        
        createPSField("BUSINESS_UNIT_PC", "CHAR", reqLoadSeg);
        createPSField("PROJECT", "CHAR", reqLoadSeg);
        createPSField("BUSINESS_UNIT_IN", "CHAR", reqLoadSeg);
        
        createPSField("PROJECT_ID", "CHAR", reqLoadSeg);

        // Added by Pankaj JIRA EF-4082
        createPSField("ACTIVITY_ID", "CHAR", reqLoadSeg);
        createPSField("BUSINESS_UNIT_GL", "CHAR", reqLoadSeg);

        createPSField("PROGRAM_CODE", "CHAR", reqLoadSeg);
        createPSField("FUND_CODE", "CHAR", reqLoadSeg);
        createPSField("CLASS_FLD", "CHAR", reqLoadSeg);
        createPSField("DEPTID", "CHAR", reqLoadSeg);
        createPSField("BUYER_ID", "CHAR", reqLoadSeg); //HAQ
        
        /*createPSField("CATEGORY_ID", "CHAR", reqLoadSeg);
        createPSField("MX_SITE", "CHAR", reqLoadSeg);
        createPSField("MX_HDR_SITE", "CHAR", reqLoadSeg);*/


        //		ADD GL SEGMENTS
        //cfNames = getPSChartFieldNames(reqLoadSeg);

        Element commentFT = createPSRecordStructure("PO_RQLD_CMT_SEG");

        createPSField("LOADER_BU", "CHAR", commentFT);
        createPSField("GROUP_SEQ_NUM", "NUMBER", commentFT);
        createPSField("COMMENT_SEQ", "NUMBER", commentFT);
        createPSField("COMMENT_REQ_TYPE", "CHAR", commentFT);
        createPSField("DESCR254", "CHAR", commentFT);
        createPSField("PUBLIC_FLG", "CHAR", commentFT);
        createPSField("ALLOW_MODIFY", "CHAR", commentFT);
        createPSField("RECV_VIEW_FLG", "CHAR", commentFT);
        createPSField("VCHR_VIEW_FLG", "CHAR", commentFT);

        //category code record
        //Element itemCatFT = createPSRecordStructure("MX6_ITM_CAT");
        Element itemCatFT = createPSRecordStructure("MX_ITM_CAT");
        createPSField("CATEGORY_CD", "CHAR", itemCatFT);

        Element ftypes = new Element("FieldTypes");
        ftypes.addContent(reqLoadSeg);
        ftypes.addContent(commentFT);
        ftypes.addContent(itemCatFT);
        ftypes.addContent(createPSCAMAStruc());

        integrationLogger.debug("Leaving PROutExt.buildPSFieldArea ");

        return ftypes;

    } // end buildPSFieldArea

    /**
     * Builds the PO_REQLOAD_SEG record of the MX6_PR_TOPS message.
     * 
     * @param msg
     *            Reference to MsgData portion of the peoplesoft xml.
     * @param in
     *            Reference to Maximos item data.
     * 
     * @exception MXException
     *                MAXIMO exception
     * @exception RemoteException
     *                Remote exception
     */
    private void buildReqLoad(Element msg, StructureData in)
            throws MXException, RemoteException
    {
        integrationLogger.debug("Entering PROutExt.buildReqLoad ");

        boolean notMapped = true; //is pr header not mapped?

        MboRemote prMbo = in.getCurrentMbo();

        if (!prMbo.isNull("sendersysid"))
        {
            throw new MXApplicationException("iface", "skip_transaction");
        }

        Element transaction = null;

        Element reqLoad = createPSRecordStructure("PO_REQLOAD_SEG");
        Element newReqLoad = null;

        List allPRLines = in.getChildrenData("PRLINE");

        Iterator itr = allPRLines.iterator();

        if (allPRLines.isEmpty())
        {
            throw new MXApplicationException("iface", "skip_transaction");
        }
        else
        {
        	//HAQ - Refactored
            //while (itr.hasNext())
        	for (int i = 0; i < allPRLines.size(); i++)
            {
            	//HAQ - Added Element cast
                //Element mxPRLine = (Element)itr.next();

                //Create a new transaction element for every PR line
                transaction = new Element("Transaction");
                msg.addContent(transaction);

                //only map the header once for each PR
                //Then copy the PR header mapping to each line
                if (notMapped)
                {
                    mapReqLoad(reqLoad, in);
                    newReqLoad = (Element)reqLoad.clone();
                    notMapped = false;
                }
                else
                {
                    newReqLoad = (Element)reqLoad.clone();
                }
                //HAQ - refactored
                //in.setAsCurrent(mxPRLine);
                in.setAsCurrent(allPRLines, i);
                buildReqLoadLine(newReqLoad, in, prMbo);

                transaction.addContent(newReqLoad);
                transaction.addContent(fillPSCAMAStruc(in.getAction()
                        .substring(0, 1), true));
            }
        }

        integrationLogger.debug("Leaving PROutExt.buildReqLoad ");

    } // end buildPSDataArea

    /**
     * Maps the PO_REQLOAD_SEG record only mapping the PR header fields.
     * 
     * @param reqLoad
     *            Reference to PO_REQLOAD_SEG record of the peoplesoft xml.
     * @param in
     *            Reference to Maximos PR data.
     * 
     * @exception MXException
     *                MAXIMO exception
     * @exception RemoteException
     *                Remote exception
     */
    private void mapReqLoad(Element reqLoad, StructureData in)
            throws MXException, RemoteException
    {
        integrationLogger.debug("Entering PROutExt.mapReqLoad ");
        
        
        String prnum = in.getCurrentData("PRNUM");
        /*String purchBU = null;
        
        if(!in.isCurrentDataNull("PR1"))
        {
            purchBU = in.getCurrentData("PR1");
        } else if(getMaxIfaceControl().getValueControl(getExtSystem(),"PURCH_BU") != null)
        {
        	purchBU = getMaxIfaceControl().getValueControl(getExtSystem(),"PURCH_BU");
        }

        if (in.isCurrentDataNull("PS_PURCH_BU"))
        {
            throw new MXApplicationException("iface", "ps-nopobu");
        }*/

        if (in.isCurrentDataNull("SHIPTO"))
        {
            String[] params = { prnum };
            throw new MXApplicationException("iface", "ps-noshipto", params);
        }

        setPSField("SHIPTO_ID", in.getCurrentData("SHIPTO"), reqLoad);
        //setPSField("LOADER_BU", in.getCurrentData("PS_PURCH_BU"), reqLoad);
        setPSField("LOADER_BU", getMaxIfaceControl().getValueControl(getExtSystem(),"PURCH_BU"), reqLoad);
        setPSField("REQUESTOR_ID", in.getCurrentData("REQUESTEDBY"), reqLoad);
        setPSField("CURRENCY_CD", in.getCurrentData("CURRENCYCODE"), reqLoad);
        setPSField("VENDOR_ID", getVendorID(in.getCurrentData("VENDOR")),
            reqLoad);
        setPSField("REQ_ID", in.getCurrentData("PRNUM"), reqLoad);
        //setPSField("MX_HDR_SITE", in.getCurrentData("SITEID"), reqLoad);
        setPSField("MX_ORIGIN", in.getCurrentData("SITEID"), reqLoad);
        grp_seq=nextNum();
        setPSField("GROUP_SEQ_NUM",String.valueOf(grp_seq),reqLoad);
        setPSField("BUYER_ID",in.getCurrentData("LBL_REQUESTEDBY"),reqLoad); //HAQ

        integrationLogger.debug("Leaving PROutExt.mapReqLoad ");

    } // end mapReqLoad

    /**
     * Maps the MAXIMO PR line fields to the PO_REQLOAD_SEG.
     * 
     * @param reqLoad
     *            Reference to PO_REQLOAD_SEG record of the peoplesoft xml.
     * @param in
     *            Reference to Maximos PR data.
     * @param prMbo
     *            Reference to the current PR Mbo.
     * 
     * @exception MXException
     *                MAXIMO exception
     * @exception RemoteException
     *                Remote exception
     */
    private void buildReqLoadLine(Element reqLoad, StructureData in,
            MboRemote prMbo) throws MXException, RemoteException
    {
        integrationLogger.debug("Entering PROutExt.mapReqLoadLine ");

        String siteId = in.getParentData("SITEID");
        //String psLocation = in.getCurrentData("PS_LOCATION");
        String psLocation = in.getCurrentData("RLIN2");
        String prLineNum = in.getCurrentData("PRLINENUM");
        String itemNum = in.getCurrentData("ITEMNUM");
        String calc_price_flg = "Y";
        String lineType = MXServer.getMXServer().getMaximoDD().getTranslator()
                .toInternalString("LINETYPE", in.getCurrentData("LINETYPE"),
                    siteId, MXServer.getMXServer().getOrganization(siteId));
        
        boolean mapInvBU = checkInventory(in.getCurrentData("STORELOC"), in
                .getCurrentDataAsLong("PRLINEID"), "PRLINE", prMbo);

        buildItemCat(reqLoad, in);

        if (isStringNotNull(psLocation))
        {
            setPSField("LOCATION", psLocation, reqLoad);
        }
        else
        {
            String[] params = { in.getCurrentData("PRLINENUM") };
            throw new MXApplicationException("iface", "ps-nolocation", params);

        }

        if (isStringNotNull(in.getCurrentData("ORDERUNIT")))
        {
            setPSField("UNIT_OF_MEASURE", in.getCurrentData("ORDERUNIT"),
                reqLoad);
        }
        else
        {
            throw new MXApplicationException("iface", "ps-noorderunit");
        }

        //Don't map itemnum for external, tool or standard service line types
        //these itemnums will not exist in PeopleSoft
        if (!lineType.equals("ITEM") && !lineType.equals("SPORDER"))
        {
            itemNum = null;
            calc_price_flg = "N";
        }
        
        if(lineType.equalsIgnoreCase("ITEM"))
        {
        	calc_price_flg = "N";
        }

        if (isStringNotNull(itemNum))
        {
            checkItemStatus(itemNum, prLineNum, in
                    .getCurrentDataAsLong("PRLINEID"), "PRLINE", prMbo);
        }

        if (in.isCurrentDataNull("REQDELIVERYDATE"))
        {
            setPSField("DUE_DT", getPSDate(in.getParentData("REQUIREDDATE")),
                reqLoad);
        }
        else
        {
            setPSField("DUE_DT",
                getPSDate(in.getCurrentData("REQDELIVERYDATE")), reqLoad);
        }

        setPSField("INV_ITEM_ID", itemNum, reqLoad);
        setPSField("CALC_PRICE_FLG", calc_price_flg, reqLoad);
        setPSField("DESCR254_MIXED", in.getCurrentData("DESCRIPTION"), reqLoad);
        setPSField("QTY_REQ", in.getCurrentData("ORDERQTY"), reqLoad);
        setPSField("PRICE_REQ", in.getCurrentData("UNITCOST"), reqLoad);
        setPSField("LINE_NBR", in.getCurrentData("PRLINENUM"), reqLoad);
        /*setPSField("BUSINESS_UNIT_GL", getMaxIfaceControl()
                .getXREFControlValue(getExtSystem(), "ORGID_GLBU", null, null,
                    in.getCurrentData("ORGID"), true), reqLoad);*/
        setPSField("BUSINESS_UNIT_PC", getMaxIfaceControl().getValueControl(getExtSystem(),"PROJECT_BU"), reqLoad);
        
       // Commented by Pankaj JIRA EF-4082 
       // setPSField("PROJECT", in.getGL("GLDEBITACCT"), reqLoad);
        
        setPSField("PROJECT", "",reqLoad); // Set blank JIRA EF-4082
        
       
        //setPSField("MX_SITE", siteId, reqLoad);

        if (mapInvBU)
        {
            setPSField("BUSINESS_UNIT_IN", getMaxIfaceControl()
                    .getXREFControlValue(getExtSystem(), "INVLOC_INVBU", null,
                        siteId, in.getCurrentData("STORELOC"), true), reqLoad);
        }

        //Element debitAcct = in.getCurrentDataAsElement("GLDEBITACCT");

        //call method to map gldebitacct if gldebitacct exists
        /*if (debitAcct != null)
        {
            getPSChartFieldValues(debitAcct, reqLoad, cfNames);
        }*/
        
        buildCommentSeg(reqLoad, in);
        
        /*************************************************************************
         *  The following portion was added by Pankaj for adding project/activity 
         * related information from PS remote view. This information will be added
         * to XML Message
         * JIRA EF- 4082
         *************************************************************************/
        String PROJECT_ID = "";
        String ACTIVITY_ID =""; 
        String FUND_CODE = "";
        String DEPT_CODE = "";
        String PROJ_BU="";
        
        String CLASS_FLD = "";
        String PROGRAM_CODE = "";
        
        // Get project/activity id
        String glDebitAcct = in.getGL("GLDEBITACCT");
        
        String[] parts = glDebitAcct.split("\\.");
        PROJECT_ID = parts[0]; 
        ACTIVITY_ID= parts[1]; 
        String strWhere="";
        
        // Derive other information from PeopleSoft remote view 
        // based upon project and activity id
        strWhere  = " BUSINESS_UNIT='LBNL' and ";
        strWhere += " PROJECT_ID='"  + PROJECT_ID   + "' and ";
		strWhere +="  ACTIVITY_ID='" + ACTIVITY_ID  + "' and ";
		strWhere +="  EFFDT = (SELECT MAX(P_ED.EFFDT) ";
		strWhere +="  FROM MAXIMO.LBL_V_PS_ORGPRJ_ACT P_ED ";           
        strWhere +="  WHERE P_ED.BUSINESS_UNIT='LBNL'" ;
        strWhere +="  AND P_ED.PROJECT_ID = '"  + PROJECT_ID  + "'";
        strWhere +="  AND P_ED.ACTIVITY_ID ='" + ACTIVITY_ID  + "'"; 
        strWhere +="  AND P_ED.EFFDT <= SYSDATE) ";  

    	MboSetRemote mbosetremote = MXServer.getMXServer().getMboSet("LBL_V_PS_ORGPRJ_ACT", getUserInfo());
		mbosetremote.reset();
		mbosetremote.setWhere(strWhere); 		
		
		integrationLogger.debug("strWhere: " + strWhere);
		if (!mbosetremote.isEmpty()) 
		{
			MboRemote myMbo = (MboRemote) mbosetremote.getMbo(0);
		 	PROJ_BU   = myMbo.getString("PROJ_BUS_UNIT").trim();
			FUND_CODE = myMbo.getString("FUND_CODE").trim();
			DEPT_CODE = myMbo.getString("DEPT_CODE").trim();
		}
         if (mbosetremote !=null) {mbosetremote.close(); mbosetremote=null ;}  
        
        /* Pankaj -----  The following block is not used any more         
        //call the procedure for adding all the LBNL custom fields.
        //this involves querying from PS tables; seems moronic but client
        //wants it.
        String PROJECT_ID = "";
        String ACTIVITY_ID =""; // Added by Pankaj JIRA EF-4082
        String FUND_CODE = "";
        String CLASS_FLD = "";
        String DEPTID = "";
        String PROGRAM_CODE = "";
        
        itemNum = in.getCurrentData("ITEMNUM");
        String orgID = in.getParentData("ORGID");
        String glDebitAcct = in.getGL("GLDEBITACCT");
        String refWO = in.getCurrentData("REFWO");
        
        // FSM Changes for retrieving LBL_FUND_CODE and LBL_DEPT_CODE
        
        integrationLogger.debug("----------  FSM Changes  ----------");
        integrationLogger.debug("----------  FSM Changes  >>>>> GLDebitAcct = " + glDebitAcct);
        
        String Lbl_Fund_code=" ";
        String Lbl_Dept_Code=" ";
        
        if(isStore){
        	
            if(glDebitAcct != null && glDebitAcct.length()>=0){

            	// Find related ChartofAccounts records for the GLDEBITACCT
				String strWhere = " orgid='LBNL' and";
				strWhere += " GLACCOUNT='" + glDebitAcct + "'";

				MboSetRemote mbosetremote = MXServer.getMXServer().getMboSet("CHARTOFACCOUNTS", getUserInfo());
				mbosetremote.reset();
				mbosetremote.setWhere(strWhere);

				// If the collection is not empty, retrieve the LBL_FUND_CODE
				// and LBL_DEPT_CODE

				if (!mbosetremote.isEmpty()) {
					MboRemote chartofaccounts = (MboRemote) mbosetremote.getMbo(0);
					Lbl_Fund_code = chartofaccounts.getString("LBL_FUND_CODE").trim();
					Lbl_Dept_Code = chartofaccounts.getString("LBL_DEPT_CODE").trim();
					
			        integrationLogger.debug("----------  FSM Changes  >>>>> LBL FUND CODE = " + Lbl_Fund_code);
			        integrationLogger.debug("----------  FSM Changes  >>>>> LBL DEPT CODE = " + Lbl_Dept_Code);
				}           	

				if (mbosetremote !=null) mbosetremote.close();
            }   
        		       	
        	//PROJECT_ID = " ";
            // Changed by Pankaj JIRA EF-4082
            String[] parts = glDebitAcct.split("\\.");
            PROJECT_ID = parts[0]; 
            ACTIVITY_ID= parts[1]; 
            
            FUND_CODE = Lbl_Fund_code;
            CLASS_FLD = " ";
            DEPTID = Lbl_Dept_Code;
            //PROGRAM_CODE = retrieveProgramCodeForStoreCatCode(glDebitAcct, orgID, siteId, itemNum);
            PROGRAM_CODE = " ";
        } else
        {
            try
            {
                setPSDBConnection();
            }
            catch(Exception e)
            {
            	integrationLogger.debug(e.getMessage());
            }
            PROJECT_ID = retrieveProjectIDForNonStoreCatCode(orgID, refWO);
            FUND_CODE = retrieveFundCodeForNonStoreCatCode(orgID, refWO);
            CLASS_FLD = retrieveClassFldForNonStoreCatCode(orgID, refWO);
            DEPTID = "";
            PROGRAM_CODE = retrieveProgramCodeForNonStoreCatCode(orgID, refWO);
            try
            {
                closePSDBConnection();
            }
            catch(Exception e) { }
        }
        
        
        the comment block not used anymore ends here **********/
         
         
        setPSField("PROJECT_ID",  PROJECT_ID, reqLoad); // JIRA EF-4082
        setPSField("ACTIVITY_ID", ACTIVITY_ID, reqLoad); // JIRA EF-4082
        setPSField("FUND_CODE",   FUND_CODE, reqLoad);      
        setPSField("DEPTID",      DEPT_CODE, reqLoad);
        setPSField("BUSINESS_UNIT_GL", PROJ_BU, reqLoad);
        setPSField("CLASS_FLD",    CLASS_FLD, reqLoad);
        setPSField("PROGRAM_CODE", PROGRAM_CODE, reqLoad);
        // Set additional elements as per Janet L
        setPSField("RESOURCE_TYPE", "PROCU", reqLoad);
        setPSField("RESOURCE_CATEGORY", "60010", reqLoad);
        setPSField("BUSINESS_UNIT_PC", PROJ_BU, reqLoad);
         

        integrationLogger.debug("Leaving PROutExt.mapReqLoadLine ");

    }

    /**
     * Builds the PO_RQLD_CMT_SEG record of the MX6_PR_TOPS message.
     * 
     * @param reqLoad
     *            Reference to MASTER_ITEM_EVW record of the peoplesoft xml.
     * @param in
     *            Reference to Maximos pr header data.
     * 
     * @exception MXException
     *                MAXIMO exception
     * @exception RemoteException
     *                Remote exception
     */
    private void buildCommentSeg(Element reqLoad, StructureData in)
            throws MXException, RemoteException
    {
        integrationLogger.debug("Entering PROutExt.buildCommentSeg ");

        int comments = 2; //1 for header and 1 for line
        String description = in.getCurrentData("DESCRIPTION");
        String hdrDesc = in.getParentData("DESCRIPTION");

        if (isStringNotNull(in.getParentData("DESCRIPTION_LONGDESCRIPTION")))
        {
            hdrDesc = hdrDesc + " "
                    + in.getParentData("DESCRIPTION_LONGDESCRIPTION");
        }

        //Only map the header comment once for each PR, if headerComment
        //is true than comment has been mapped previously
        if (headerComment)
        {
            comments = 1;
        }

        //create a header and line comment if necessary
        for (int i = 0; i < comments; i++)
        {
            if ((headerComment && isStringNotNull(description))
                    || (!headerComment && isStringNotNull(hdrDesc)))
            {
                Element commentSeg = createPSRecordStructure("PO_RQLD_CMT_SEG");

                setPSField("LOADER_BU", getMaxIfaceControl().getValueControl(getExtSystem(),"PURCH_BU"),commentSeg);
                setPSField("GROUP_SEQ_NUM",String.valueOf(grp_seq),commentSeg);
                setPSField("COMMENT_SEQ", Integer.toString(i), commentSeg);

                //if header comment is already mapped then create only line
                // comment
                //else create the hdr comment
                if (headerComment)
                {
                    setPSField("COMMENT_REQ_TYPE", "LIN", commentSeg);
                    setPSField("DESCR254", in.getCurrentData("DESCRIPTION"),
                        commentSeg);
                }
                else
                {
                    setPSField("COMMENT_REQ_TYPE", "HDR", commentSeg);
                    setPSField("DESCR254", hdrDesc, commentSeg);
                    headerComment = true;
                }

                setPSField("PUBLIC_FLG", "Y", commentSeg);
                setPSField("ALLOW_MODIFY", "Y", commentSeg);
                setPSField("RECV_VIEW_FLG", "N", commentSeg);
                setPSField("VCHR_VIEW_FLG", "N", commentSeg);

                reqLoad.addContent(commentSeg);
                reqLoad.addContent(fillPSCAMAStruc("A", false));
            }
        }

        integrationLogger.debug("Leaving PROutExt.buildCommentSeg ");
    }

    /**
     * Builds the MX6_ITM_CAT record on the PeopleSoft PR xml.
     * 
     * @param reqLoad
     *            Reference to the PO_REQLOAD_SEG.
     * @param in
     *            Reference to Maximo Data.
     * 
     * @exception MXException
     *                MAXIMO exception
     * @exception RemoteException
     *                Remote exception
     */
    private void buildItemCat(Element reqLoad, StructureData in)
            throws MXException, RemoteException
    {
        integrationLogger.debug("Entering PROutExt.buildItemCat ");

        Element itemCat = createPSRecordStructure("MX_ITM_CAT");
        //String catCode = in.getCurrentData("PS_ITEMCATEGORY");
        String catCode = in.getCurrentData("RLIN3");

        //Make sure a category code exists on each line, this is required by
        //PeopleSoft. If it does not exist then use the interface control. 
        if (catCode == null || catCode.trim().equals(""))
        {
            /*String[] params = { in.getCurrentData("PRLINENUM") };
            throw new MXApplicationException("iface", "ps-nocategorycode",
                    params);*/
        	catCode = getMaxIfaceControl().getValueControl(getExtSystem(),"ITEM_CAT_DFLT");
        }

        setPSField("CATEGORY_CD", catCode, itemCat);
        
        if(catCode.equalsIgnoreCase("STORE"))
        	isStore = true;

        //add this record as a child to the PO_REQLOAD_SEG
        reqLoad.addContent(itemCat);
        reqLoad.addContent(fillPSCAMAStruc("A", false));

        integrationLogger.debug("Leaving PROutExt.buildItemCat ");

    } // end buildPSDataArea

    /**
     * Removes the location from the end of the vendor.
     * 
     * @param vendorID
     *            Company value on PR
     * 
     * @exception MXException
     *  
     */
    public String getVendorID(String vendorID) throws MXException
    {
        integrationLogger.debug("Entering PROutExt.getVendorID ");

        int delimiterIndex = vendorID.indexOf(getMaxIfaceControl()
                .getValueControl(getExtSystem(), "VNDR_LOC_DELIM"));

        if (delimiterIndex != -1)
        {
            vendorID = vendorID.substring(0, delimiterIndex);
        }

        integrationLogger.debug("Leaving PROutExt.getVendorID ");

        return vendorID;

    }

}
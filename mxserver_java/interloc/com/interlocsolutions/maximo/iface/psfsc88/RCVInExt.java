/*
 * Copyright(c) Interloc Solutions, Inc.  All rights reserved.
 *
 * 09-Oct-2008	Rohith Ramamurthy	Created
 */
package com.interlocsolutions.maximo.iface.psfsc88;

import java.rmi.RemoteException;
import java.util.Iterator;
import java.util.List;

import org.jdom.Document;
import org.jdom.Element;

import psdi.iface.mic.MicConstants;
import psdi.iface.mic.MicUtil;
import psdi.iface.mic.StructureData;
import psdi.server.MXServer;
import psdi.util.MXApplicationException;
import psdi.util.MXException;

/**
 * Process PeopleSoft receipts.
 */
public class RCVInExt extends PSInExt
{
    /*
     * Constructor.
     */
    public RCVInExt()
    {
        // super();
    }

    /**
     * Maps the PeopleSoft receipts to MAXIMO receipts.
     * 
     * @param exitData
     *            PeopleSoft receipt data
     * 
     * @return MAXIMO and PeopleSoft data as a StructureData object.
     */
    public StructureData setDataIn(StructureData exitData) throws MXException,
            RemoteException
    {
        integrationLogger.debug("Entering RCVInExt.setDataIn ");

        List comments = null;

//        StructureData irData = new StructureData(getIntPointName(),
//                getExtSystem(), 1, false);
        StructureData irData = 
        		new StructureData(this.messageType, this.mosName, MicUtil.getMaxVar("BASELANGUAGE"), 1, false, false);
        // HAQ
        irData.breakData();
        //irData.setPrimaryObject("MATRECTRANS");

        Document psxml = exitData.getData();

        Element messageRoot = psxml.getRootElement();

        Element rcvHdr = messageRoot.getChild("GENERIC").getChild("MsgData")
                .getChild("Transaction").getChild("RECV_HDR");

        if (rcvHdr != null)
        {
            comments = rcvHdr.getChildren("RECV_COMMENT_FS");
        }

        if (rcvHdr == null)
        {
            String[] param = { "RECV_HDR" };
            throw new MXApplicationException("iface", "ps-nopsxmltag", param);
        }
        else
        {

            Element rcvShipLine = rcvHdr.getChild("RECV_LN_SHIP");
            if (rcvShipLine != null)
            {
                List allDistLines = rcvShipLine.getChildren("RECV_LN_DISTRIB");

                mapReceipt(rcvShipLine, allDistLines, comments, irData);
                irData.setParentAsCurrent();

            }
        }

        integrationLogger.debug("Leaving RCVInExt.setDataIn ");

        return irData;
    }

    /**
     * Maps all levels of PeopleSoft Receipt to MAXIMO Receipt.
     * 
     * @param rcvShipLine
     *            Reference to PeopleSoft receipt line/ship.
     * @param allDistLines
     *            Reference to all PeopleSoft distribution lines for this
     *            line/ship.
     * 
     * @param comments
     *            Reference to all PeopleSoft comment lines for this receipt
     *            header.
     * @param irData
     *            Reference to MAXIMO data.
     * 
     * @exception MXException
     *                MAXIMO exception
     * @exception RemoteException
     *                Remote exception
     */
    public void mapReceipt(Element rcvShipLine, List allDistLines,
            List comments, StructureData irData) throws MXException,
            RemoteException
    {
        integrationLogger.debug("Entering RCVInExt.mapReceipt ");

        boolean receipt = true;
        //String siteID = rcvShipLine.getChildText("MX_SITE");
        String siteID = rcvShipLine.getChildText("MX_ORIGIN");
        //String qtyAccept = rcvShipLine.getChildText("MX_QTY_SH_ACCPT");
        String qtyAccept = rcvShipLine.getChildText("QTY_SH_ACCPT");
        //String qtyReturn = rcvShipLine.getChildText("MX_QTY_SH_RTN");
        String qtyReturn = rcvShipLine.getChildText("QTY_SH_RTN");
        String desc = rcvShipLine.getChildText("DESCR254_MIXED");
        float qty = 0;
        float absoluteQty = 0;

        if (qtyReturn.equals("0"))
        {
        	//02.05.09 rohithr
        	//for multiline receipt cancels from PS.
        	//if(rcvShipLine.getParent().getChildText("RECV_STATUS").equalsIgnoreCase("X"))
        	if(rcvShipLine.getChildText("RECV_SHIP_STATUS").equalsIgnoreCase("X"))
        	{
        		//this is a cancelled receipt in PS.
        		//treated as a return in Maximo.
        		qty = -1 * Float.parseFloat(qtyAccept);
                absoluteQty = Math.abs(qty);
        		
        	}
        	else
        	{
        		qty = Float.parseFloat(qtyAccept);
                absoluteQty = Math.abs(qty);
        	}
        }
        else
        {
            //add negative sign so we can determine if this is a return or
            //regular receipt
            qty = -1 * Float.parseFloat(qtyReturn);
            absoluteQty = Math.abs(qty);

        }

        irData.setCurrentData("PONUM", rcvShipLine.getChildText("PO_ID"));
        /*irData.setCurrentData("POLINENUM", createLineNumber(rcvShipLine
                .getChildText("LINE_NBR"), rcvShipLine
                .getChildText("SCHED_NBR")));*/
        irData.setCurrentData("POLINENUM", rcvShipLine.getChildText("LINE_NBR"));

        //quantity greater than zero will be an issue else a return
        if (qty > 0)
        {
            irData.setCurrentData("ISSUETYPE", MXServer.getMXServer()
                    .getMaximoDD().getTranslator().toExternalDefaultValue(
                        "ISSUETYP", "RECEIPT", siteID,
                        MXServer.getMXServer().getOrganization(siteID)));
        }
        else
        {
            irData.setCurrentData("ISSUETYPE", MXServer.getMXServer()
                    .getMaximoDD().getTranslator().toExternalDefaultValue(
                        "ISSUETYP", "RETURN", siteID,
                        MXServer.getMXServer().getOrganization(siteID)));
            receipt = false;
        }

        //map all necessary fields.
        irData.setCurrentData("SITEID", siteID);
        irData.setCurrentData("POSITEID", siteID);
        irData.setCurrentData("ITEMNUM", rcvShipLine
                .getChildText("INV_ITEM_ID"));
        //irData.setCurrentData("ACTUALDATE", getDateTime(rcvShipLine.getChildText("RECEIPT_DTTM")));
        irData.setCurrentData("ACTUALDATE", getMXDateTime(rcvShipLine.getChildText("RECEIPT_DTTM")));

        if (rcvShipLine.getChildText("AMT_ONLY_FLG").equalsIgnoreCase("Y")
                && !isStringNotNull(rcvShipLine.getChildText("INV_ITEM_ID")))
        {
            irData.setCurrentData("AMTTORECEIVE", rcvShipLine
                    .getChildText("PRICE_PO"));
        }
        else
        {
            //String mxSent = rcvShipLine.getChildText("MX_SENT_RECV");
            //if (isStringNotNull(mxSent) && mxSent.equals("1") && receipt)
        	if (receipt)
            {
                String qtyReceived = rcvShipLine
                        .getChildText("QTY_SH_RECVD_SUOM");
                irData.setCurrentData("RECEIPTQUANTITY", qtyReceived); //required
                irData.setCurrentData("REJECTQTY", rcvShipLine
                        .getChildText("QTY_SH_REJCT_SUOM"));
                //irData.setCurrentData("QTYTORECEIVE", qtyReceived);
            }
            else
            {
                irData.setCurrentData("RECEIPTQUANTITY", absoluteQty); //required
                //irData.setCurrentData("QTYTORECEIVE", absoluteQty); //May
                // not need
                // to map
                // this.
                irData.setCurrentData("REJECTQTY", "0"); //required - always
                // zero
            }

            irData.setCurrentData("ACCEPTEDQTY", absoluteQty); //required
            irData.setCurrentData("RECEIVEDUNIT", rcvShipLine
                    .getChildText("UNIT_MEASURE_STD"));
        }

        irData.setCurrentData("CONVERSION", "1");
        irData.setCurrentData("PACKINGSLIPNUM", rcvShipLine
                .getChildText("PACKSLIP_NO"));
        
        if(desc != null && desc.length() > 100)
        {
            desc = desc.substring(0, 100);
        }
        
        irData.setCurrentData("DESCRIPTION", desc);

        /*irData.setCurrentData("REMARK", getRecComment(comments, rcvShipLine
                .getChildText("RECV_LN_NBR")));*/
        irData.setCurrentData("REMARK", "PS:"+rcvShipLine.getChildText("RECEIVER_ID"));
        
        if (rcvShipLine.getChildText("INSPECT_CD").equals("Y"))
        {
            irData.setCurrentData("INSPECTED", MicConstants.sYes);
        }
        else
        {
            irData.setCurrentData("INSPECTED", MicConstants.sNo);
        }

        setSysIDIn(irData);
        //HAQ added EXTERNALREFID for Receipts
        irData.setCurrentData("EXTERNALREFID", getExtSystem());

        mapAssetLine(allDistLines, irData);

        integrationLogger.debug("Leaving RCVInExt.mapReceipt ");
    }

    /**
     * Maps the data needed from the distribution line and asset line.
     * 
     * @param distLines
     *            Reference to PeopleSoft distribution lines.
     * @param irData
     *            Reference to MAXIMO data.
     * 
     * @exception MXException
     *                MAXIMO exception
     * @exception RemoteException
     *                Remote exception
     */
    public void mapAssetLine(List distLines, StructureData irData)
            throws MXException
    {
        integrationLogger.debug("Entering RCVInExt.mapAssetLine ");

        String tobin = null;
        String storeroom = null;
        boolean mapped = false;

        //HAQ
        //Iterator itrDist = distLines.iterator();

        //while (itrDist.hasNext() && !mapped)
        for (int i = 0; i < distLines.size(); i++)
        {
            //HAQ
        	//Element distLine = (Element)itrDist.next();
        	if (mapped)
        		break;
        	Element distLine = (Element)distLines.get(i);
            List assetLines = distLine.getChildren("RECV_LN_ASSET");
            String status = distLine.getChildText("RECV_DS_STATUS");
            //String invBU = distLine.getChildText("BUSINESS_UNIT_IN");
            String invBU = distLine.getChildText("BUSINESS_UNIT_PO");

            storeroom = getMaxIfaceControl().getXREFControlValue(
                getExtSystem(), "INVLOC_INVBU", null,
                irData.getCurrentData("SITEID"), invBU, false);

            if (!assetLines.isEmpty() || (invBU != null && !invBU.equals("")))
            {
                //HAQ
            	//Iterator itrAsset = assetLines.iterator();

                //while (!mapped && itrAsset.hasNext())
            	for (int j = 0; j < assetLines.size(); j++)
                {
                    //HAQ
            		//Element assetLine = (Element)itrAsset.next();
            		if (mapped)
                		break;
            		Element assetLine = (Element)assetLines.get(j);
                    String storageArea = assetLine.getChildText("STORAGE_AREA");

                    if (storageArea != null && !storageArea.equals(""))
                    {
                        if (tobin == null || !status.equals("X"))
                        {
                            tobin = mapBinnum(storageArea, assetLine
                                    .getChildText("STOR_LEVEL_1"), assetLine
                                    .getChildText("STOR_LEVEL_2"), assetLine
                                    .getChildText("STOR_LEVEL_3"), assetLine
                                    .getChildText("STOR_LEVEL_4"));

                            if (!status.equals("X"))
                            {
                                irData.setCurrentData("TOSTORELOC", storeroom);
                                irData.setCurrentData("TOBIN", tobin);
                                mapped = true;
                            }

                        }
                    }
                }
            }
        }

        integrationLogger.debug("Leaving RCVInExt.mapAssetLine ");

    }

    /**
     * Get the latest comment from the comment record. First try to get the
     * "LIN" comment but if the "LIN" comment does not exist then get the "HDR"
     * comment.  If the comment is greater than 50 characters then the comment is 
     * substringed to 50 characters.
     * 
     * @param comments
     *            Reference to PeopleSoft comment record.
     * @param lineNumber
     *            Line number for the PO or receipt line.
     * 
     * @return The description field from the comment record with the latest
     *         date.
     *  
     */
    public String getRecComment(List comments, String lineNumber)
            throws MXException
    {
        String comment = null;

        comment = getComment(comments, "LIN", "RECV", lineNumber);

        if (comment == null)
        {
            comment = getComment(comments, "HDR", "RECV", lineNumber);
        }

        if (comment != null && comment.length() > 50)
        {
            comment = comment.substring(0, 50);
        }

        return comment;
    }

}
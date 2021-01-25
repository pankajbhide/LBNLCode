/*
 * Copyright(c) Interloc Solutions, Inc.  All rights reserved.
 *
 * 09-Oct-2008	Rohith Ramamurthy	Created
 * 
 * 03-Mar-2010  Pankaj Bhide If po_status is C, then set its
 *                           value to CLOSE for avoiding the error
 *                           Error is: Could not change PO XXX status to C. 
 *                           Status C is unknown.
 *                           
 * 22-May-2017 Pankaj Bhide  Add revision comments if the PO already exists
 *                           in MAXIMO    
 *                                                                         */
package com.interlocsolutions.maximo.iface.psfsc88;

import java.util.*;
import java.io.BufferedOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.net.CookieHandler;
import java.net.CookieManager;
import java.net.CookiePolicy;
import java.net.HttpURLConnection;
import java.net.URL;
import java.net.URLConnection;
import java.rmi.*;

import psdi.server.MXServer;
import psdi.util.*;
import psdi.iface.mic.*;
import psdi.iface.router.Util;
import psdi.iface.util.XMLUtils;
import psdi.iface.webservices.WSCallClient;
import psdi.iface.webservices.WebServicesUtil;
import psdi.mbo.MboConstants;
import psdi.mbo.MboRemote;
import psdi.mbo.MboSetRemote;
import psdi.mbo.SqlFormat;

import org.jdom.*;
import org.jdom.output.XMLOutputter;

/**
 * Process PeopleSoft PO.
 */
public class POInExt extends PSInExt
{
    boolean prNotMapped = true;
    String siteID;
    String orgID;
    public static final String MX_PURCHASE_ORDER = "MX_PURCHASE_ORDER";
    public static final String MX_RECEIPT = "MX_RECEIPT";
    public static final String MX_VOUCHER = "MX_VOUCHER";

    /*
     * Constructor.
     */
    public POInExt()
    {
        // super();
    }

    /**
     * Map the PeopleSoft PO to MAXIMO PO.
     * 
     * @param exitData
     *            Reference to the PeopleSoft PO.
     * 
     * @return MAXIMO PO
     */
    public StructureData setDataIn(StructureData exitData) throws MXException,
            RemoteException
    {
          integrationLogger.debug("PRB Entering POInExt.setDataIn");
        
        integrationLogger.debug("Entering POInExt.setDataIn ");

//        StructureData irData = new StructureData(getIntPointName(),
//                getExtSystem(), 1, false);
        
        StructureData irData = new StructureData(this.messageType, this.mosName, MicUtil.getMaxVar("BASELANGUAGE"), 1, false, false);
        // HAQ
        irData.breakData();
        //irData.setPrimaryObject("PO");

        Document psxml = exitData.getData();
        //HAQ - Start 3-to-1 WebService fork
        String subject = psxml.getRootElement().getChild("header").getChildText("subject");
        if (!subject.equalsIgnoreCase(MX_PURCHASE_ORDER)) {
        	MicUtil.INTEGRATIONLOGGER.debug("POInExt:: Subject = " + subject);
        	callWebService(psxml);
        	MicUtil.INTEGRATIONLOGGER.debug("POInExt:: Skipping transaction due to 3:1 processing");
        	throw new MXApplicationException("iface", "skip_transaction");
        }
        
        Element messageHeader = psxml.getRootElement();
        Element poHdr = messageHeader.getChild("GENERIC").getChild("MsgData")
                .getChild("Transaction").getChild("PO_HDR");

        List comments = poHdr.getChildren("PO_COMMENTS_FS");
        
        
        if (poHdr != null)
        {
            mapPO(poHdr, comments, irData);
        }
        else
        {
            String[] param = {"PO_HDR"};
            throw new MXApplicationException("iface", "ps-nopsxmltag", param);
        }

        List allPOLines = poHdr.getChildren("PO_LINE");

        if (!allPOLines.isEmpty())
        {

            //irData.moveToFirstNoun();
        	//HAQ
            //Iterator itr = allPOLines.iterator();
            //while (itr.hasNext())
        	for (int i = 0; i < allPOLines.size(); i++)
            {
                //HAQ
        		//Element poLine = (Element)itr.next();
        		Element poLine = (Element)allPOLines.get(i);
        		List allSchedLines = poLine.getChildren("PO_LINE_SHIP");

                if (!allSchedLines.isEmpty())
                {
                    //HAQ
                	//Iterator itrSch = allSchedLines.iterator();
                    //while (itrSch.hasNext())
                	for (int j = 0; j < allSchedLines.size(); j++)
                    {
                        //HAQ
                		//Element schedLine = (Element)itrSch.next();
                		Element schedLine = (Element)allSchedLines.get(j);
                        List allDistLines = schedLine
                                .getChildren("PO_LINE_DISTRIB");

                        mapPOLine(poLine, schedLine, allDistLines, comments,
                            irData);
                        irData.setParentAsCurrent();
                    }
                }
            }
        }
        else if(poHdr.getChildText("MX_SENT").equals("C"))
        {
            //this is the case when a PO is dispatched then closed
            //before it is sent to MAXIMO.  Two transactions will come
            //to MAXIMO, one to insert the PO as approved and one 
            //to change the status to closed.  The status change PO will
            //have no lines so this is the reason that it will be a status change.
            irData.setCurrentData("STATUSIFACE", MicConstants.sYes);
        }

        integrationLogger.debug("Leaving POInExt.setDataIn ");
        
          integrationLogger.debug("PRB Leaving POInExt.setDataIn ");
        

         integrationLogger.debug("PRB output message started" );
         
         // save it to a file:
         
         XMLOutputter out = new XMLOutputter();
         java.io.FileWriter writer;
         
				try 
				{
					writer = new java.io.FileWriter("po.xml");
				  out.output(irData.getData(), writer);
	         writer.flush();
	         writer.close();
	         
	         XMLOutputter outputter = new XMLOutputter();
	         outputter.output(irData.getData(), System.out);
      
	         
				}
				catch (IOException e1) {
					// TODO Auto-generated catch block
					e1.printStackTrace();
				}
       
       
         integrationLogger.debug("PRB output message finished" );
         

        return irData;
    }

    /**
     * Calls Maximo Enterprise Service based on the message type being received.
     * Currently there are 3 inbound messages from PeopleSoft to Maximo: PO, Invoice and Receipts.
     * 
     * @author Haq Khan
     * @param psxml
     * @throws RemoteException 
     */
    public void callWebService(Document psxml) throws RemoteException {
    	String serviceName = null;
    	String service = null;
    	String subject = psxml.getRootElement().getChild("header").getChildText("subject");
    	byte data[] = null;
    	
    	if (subject != null && !subject.equalsIgnoreCase("")) {
    		if (subject.equalsIgnoreCase(MX_RECEIPT)) {
    			serviceName = "SyncMXRECEIPT";
    			//service = "PSFT_MX_RECEIPT";
    			service = MXServer.getMXServer().getConfig().getProperty("lbl."+MX_RECEIPT);
    			MicUtil.INTEGRATIONLOGGER.debug("POInExt:: Service = " + service);
    		}
    		if (subject.equalsIgnoreCase(MX_VOUCHER)) {
    			serviceName = "SyncMXINVOICE";
    			//service = "PSFT_MX_VOUCHER";
    			service = MXServer.getMXServer().getConfig().getProperty("lbl."+MX_VOUCHER);
    			MicUtil.INTEGRATIONLOGGER.debug("POInExt:: Service = " + service);
    		}
    		
        	//Call Maximo Enterprise Web Service
        	try {
        		boolean success = false;
        		data = XMLUtils.convertDocumentToBytes(psxml);
        		
        		/*
        		WSCallClient callClient = new WSCallClient();
        		MicUtil.INTEGRATIONLOGGER.debug("POInExt:: Calling WS");
        		MicUtil.INTEGRATIONLOGGER.debug("POInExt:: Service Name = " + serviceName + "; Service = " +service);
        		byte[] resp = callClient.invokeWebService(serviceName, WebServicesUtil.getMEAWebAPPURL()+"services/"+service, data, null, "IT-BS-MXINTADM", "Everyone$Enjoy3", "processDocument", null, null, null, null, null, 0, 0, null);
        		MicUtil.INTEGRATIONLOGGER.debug("POInExt:: WS response is null=" + (resp == null));
        		if (resp != null) {
        			MicUtil.INTEGRATIONLOGGER.debug("POInExt:: WS has response");
        			success = true;
        			throw new MXApplicationException("iface", "skip_transaction");
        		}
        		*/
        		
        		//HTTP Post Code Start
        		MicUtil.INTEGRATIONLOGGER.debug("POInExt:: URL = " + WebServicesUtil.getMEAWebAPPURL()+"esqueue/"+getExtSystem()+"/"+service);
        		CookieHandler.setDefault(new CookieManager(null, CookiePolicy.ACCEPT_ALL));
        		BufferedOutputStream outStream = null;
        		InputStream inStream = null;
        		URL postURL = new URL(WebServicesUtil.getMEAWebAPPURL()+"esqueue/"+getExtSystem()+"/"+service);
        		URLConnection con = postURL.openConnection();
        		((HttpURLConnection)con).setRequestMethod("POST");
        		int setCntLength = data.length;
				//setDefaultRequestProperty(setCntLength);
        		con.setRequestProperty("Content-Type","text/xml");
        		con.setRequestProperty ("Authorization", "Basic " + MXServer.getMXServer().getConfig().getProperty("lbl.HTTPAUTH"));
        		con.setRequestProperty ("Content-Length", Integer.toString(setCntLength));
        		con.setDoOutput(true);
        		con.setUseCaches(false);
        		con.setAllowUserInteraction(false);
        		
        		outStream = new BufferedOutputStream(con.getOutputStream());
			    outStream.write(data);
				outStream.flush();

				inStream = con.getInputStream();
			    byte[] responseBody = Util.getByteArrayFromInputStream(inStream);
			    MicUtil.INTEGRATIONLOGGER.debug("POInExt:: responseBody = " + responseBody);
			    MicUtil.INTEGRATIONLOGGER.debug("POInExt:: Should skip transaction due to 3:1 processing");
			    //throw new MXApplicationException("iface", "skip_transaction");
        		//End HTTP Code
        		
        	} catch (MXException e1) {
        		MicUtil.INTEGRATIONLOGGER.error("POInExt:: MXException");
        		e1.printStackTrace();
        	} catch (Exception e) {
        		MicUtil.INTEGRATIONLOGGER.error("POInExt:: Exception");
        		e.printStackTrace();
        	}
    	}
	}

	/**
     * Builds the PO header part of the PeopleSoft PO xml.
     * 
     * @param poHdr
     *            PeopleSoft PO header data.
     * @param comments
     *            PeopleSoft comments record.
     * @param irData
     *            MAXIMO PO data.
     * 
     * @exception MXException
     *                MAXIMO exception
     * @exception RemoteException
     *                Remote exception
     */

    public void mapPO(Element poHdr, List comments, StructureData irData)
            throws MXException, RemoteException
    {
        int intRevisionnum=0;
        
    	integrationLogger.debug("Entering POInExt.mapPO ");
         integrationLogger.debug("PRB Entering POInExt.mapPO  ");
        siteID = getMaxIfaceControl().getXREFControlValue(
            getExtSystem(), "SITEID_PURCHBU", null, null,
            poHdr.getChildText("BUSINESS_UNIT"), false);
        orgID = MXServer.getMXServer().getOrganization(siteID);
        
        String lastDate = getMXDateTime(poHdr.getChildText("LAST_DTTM_UPDATE"));
        //String lastDate = getDateTime(poHdr.getChildText("LAST_DTTM_UPDATE"));
        //irData.setCurrentData("PS_PURCH_BU", poHdr.getChildText("BUSINESS_UNIT"));
        irData.setCurrentData("PONUM", poHdr.getChildText("PO_ID"));
        irData.setCurrentData("POTYPE", MXServer.getMXServer().getMaximoDD()
                .getTranslator().toExternalDefaultValue("POTYPE", "STD", siteID, orgID));
        irData.setCurrentData("SITEID", siteID);
        irData.setCurrentData("DESCRIPTION", poHdr.getChildText("PO_REF"));
        irData.setCurrentData("PURCHASEAGENT", poHdr.getChildText("BUYER_ID"));
        irData.setCurrentData("ORDERDATE", getMXDate(poHdr.getChildText("PO_DT")));

        // Added by Pankaj on 3/3/10
        String strStatus=poHdr.getChildText("PO_STATUS").trim();
        
        irData.setCurrentData("STATUS", getMaxIfaceControl()
                .getXREFControlValue(getExtSystem(), "POSTATUS", orgID, siteID,
                 strStatus,false));
	        
        //****************************************************
        // Added by Pankaj on 5/22/17  JIRA EF-5980 
        // Add revision comments if the PO already exists. 
        // This is required for MAXIMO 7.6
        // If PO is closed then get the latest revision and send
        // that revision number with close. 
        //*****************************************************
    
        MboSetRemote sqfPOSet = MXServer.getMXServer().getMboSet("PO",
                getUserInfo());
        
        // Do not participate in transaction management
        sqfPOSet.setFlag(MboConstants.DISCARDABLE,true);

        SqlFormat sqfPO = new SqlFormat(getUserInfo(),
                         "siteid = :1 and ponum = :2 order by revisionnum desc");
          sqfPO.setObject(1, "PO", "SITEID", siteID);
          sqfPO.setObject(2, "PO", "PONUM", poHdr.getChildText("PO_ID"));
            
          sqfPOSet.setWhere(sqfPO.format());
          sqfPOSet.reset();

          if (! sqfPOSet.isEmpty())
           {
            	if (strStatus.equals("C")) 
                	strStatus="CLOSE";
            	
            	intRevisionnum=sqfPOSet.getMbo(0).getInt("revisionnum");
            	if (strStatus.equals("CLOSE"))
            		irData.setCurrentData("REVISIONNUM", intRevisionnum);
          
                irData.setCurrentData("REVCOMMENTS", "Comments from PeopleSoft");                          
           }  // if PO already exists in PS
            
         if (sqfPOSet !=null) { sqfPOSet.close(); sqfPOSet=null; }
                     
        // Commented the following line by Pankaj 3/3/10
        //irData.setCurrentData("STATUS", getMaxIfaceControl()
        //        .getXREFControlValue(getExtSystem(), "POSTATUS", orgID, siteID,
        //            poHdr.getChildText("PO_STATUS"), false));
        
        irData.setCurrentData("VENDOR", concatMXVendor(poHdr
                .getChildText("VENDOR_ID"), poHdr.getChildText("VNDR_LOC")));
        irData.setCurrentData("PAYMENTTERMS", poHdr
                .getChildText("PYMNT_TERMS_CD"));
        irData.setCurrentData("BILLTO", poHdr.getChildText("BILL_LOCATION"));
        irData
                .setCurrentData("CURRENCYCODE", poHdr
                        .getChildText("CURRENCY_CD"));
        irData.setCurrentData("STATUSDATE", lastDate);
        irData.setCurrentData("CHANGEDATE", lastDate);
        irData.setCurrentData("EXCHANGEDATE", getMXDate(poHdr.getChildText("RATE_DATE")));
        irData.setCurrentData("EXCHANGERATE", calculateExchangerate(poHdr
                .getChildText("RATE_MULT"), poHdr.getChildText("RATE_DIV")));
        irData.setCurrentData("EXCHANGEDATE", getMXDate(poHdr.getChildText("RATE_DATE")));

        if (!comments.isEmpty())
        {
            irData.setCurrentData("DESCRIPTION_LONGDESCRIPTION", getComment(comments, "HDR", "PO", "0"));
        }

        setSysIDIn(irData);
        
        integrationLogger.debug("Leaving POInExt.mapPO ");
          integrationLogger.debug("PRB Leaving POInExt.mapPO");
    }

    /**
     * Builds the PO line.
     * 
     * @param poLine
     *            Reference to PeopleSoft PO line data.
     * @param schedLine
     *            Reference to PeopleSoft schedule line.
     * @param distLines
     *            Reference to PeopleSoft distribution lines.
     * @param comments
     *            Reference to PeopleSoft comments record.
     * @param irData
     *            Reference to MAXIMO PO data.
     * 
     * @exception MXException
     *                MAXIMO exception
     * @exception RemoteException
     *                Remote exception
     */

    public void mapPOLine(Element poLine, Element schedLine, List distLines,
            List comments, StructureData irData) throws MXException,
            RemoteException
    {
        integrationLogger.debug("Entering POInExt.mapPOLine ");
          integrationLogger.debug("PRB Entering POInExt.mapPOLine");
        boolean issue = true;
        String description = poLine.getChildText("DESCR254_MIXED");
        String itemNum = poLine.getChildText("INV_ITEM_ID");
        String[] taxTags = { "SALETX_AMT", "USETAX_AMT", "VAT_AMT" };
        
        irData.createChildrenData("POLINE", true);
        
        prNotMapped = true;

        //Calculate tax and maps the prnum
        double[] taxAmounts = calculateTax(taxTags, distLines, irData);
        double salesTax = taxAmounts[0];
        double useTax = taxAmounts[1];
        double vatTax = taxAmounts[2];

        //map prnum and prlinenum from distrib lines. Grab first line with
        // prnum
        if (prNotMapped)
        {
            if (isStringNotNull(itemNum))
            {
                irData.setCurrentData("LINETYPE", MXServer.getMXServer()
                        .getMaximoDD().getTranslator().toExternalDefaultValue(
                            "LINETYPE", "ITEM", siteID, orgID));
            }
            else
            {
                irData.setCurrentData("LINETYPE", MXServer.getMXServer()
                        .getMaximoDD().getTranslator().toExternalDefaultValue(
                            "LINETYPE", "SERVICE", siteID, orgID));
            }
        }

        irData.setCurrentData("SITEID", siteID);
        //irData.setCurrentData("TOSITEID", schedLine.getChildText("MX_SITE"));
        irData.setCurrentData("TOSITEID", siteID);
        irData.setCurrentData("ITEMNUM", itemNum);
        irData.setCurrentData("DESCRIPTION_LONGDESCRIPTION", getComment(comments, "LIN", "PO", schedLine.getChildText("LINE_NBR")));
        irData.setCurrentData("CATALOGCODE", poLine
                .getChildText("VNDR_CATALOG_ID"));
        irData.setCurrentData("ORDERUNIT", poLine
                .getChildText("UNIT_OF_MEASURE"));
        irData.setCurrentData("REQDELIVERYDATE", getMXDate(schedLine.getChildText("DUE_DT")));

        if (poLine.getChildText("AMT_ONLY_FLG").equalsIgnoreCase("N")
                || isStringNotNull(itemNum))
        {
            irData.setCurrentData("ORDERQTY", schedLine.getChildText("QTY_PO"));
        }

        irData.setCurrentData("UNITCOST", schedLine.getChildText("PRICE_PO"));
        irData.setCurrentData("LINECOST", schedLine
                .getChildText("MERCHANDISE_AMT"));
        //irData.setCurrentData("PS_ITEMCATEGORY", schedLine.getChildText("MX_CATEGORY_CD"));
        
        /*irData.setCurrentData("POLINENUM", createLineNumber(poLine
                        .getChildText("LINE_NBR"), schedLine
                        .getChildText("SCHED_NBR")));*/
        irData.setCurrentData("POLINENUM", poLine.getChildText("LINE_NBR"));

        irData.setCurrentData("TAX1CODE", schedLine.getChildText("TAX_CD_SUT"));
        irData.setCurrentData("TAX2CODE", schedLine.getChildText("TAX_CD_VAT"));

        if (salesTax != 0 || useTax != 0)
        {
            if (salesTax != 0)
            {
                irData.setCurrentData("TAX1", salesTax);
            }
            else if (useTax != 0)
            {
                irData.setCurrentData("TAX1", useTax);
            }
            else
            {
                irData.setCurrentData("TAX1", "0");
            }
        }

        if (vatTax != 0)
        {
            irData.setCurrentData("TAX2", vatTax);
        }
        else
        {
            irData.setCurrentData("TAX2", "0");
        }

        if (description != null && description.length() > 80)
        {
            irData.setCurrentData("DESCRIPTION", description.substring(0, 80));
        }
        else
        {
            irData.setCurrentData("DESCRIPTION", description);
        }

        //map the inspected flag from PeopleSoft
        if (poLine.getChildText("INSPECT_CD").equals("Y"))
        {
            irData.setCurrentData("INSPECTIONREQUIRED", MicConstants.sYes);
        }
        else
        {
            irData.setCurrentData("INSPECTIONREQUIRED", MicConstants.sNo);
        }

        if (prNotMapped)
        {
            irData.setCurrentData("REFWO", schedLine
                    .getChildText("MX_WONUM_KEY"));
            irData.setCurrentData("ISSUE", MicConstants.sYes);
        }
        else
        {
            issue = checkIssue(irData, irData.getCurrentData("TOSITEID"));
        }

        mapPOCost(distLines, irData, issue, prNotMapped);

        integrationLogger.debug("Leaving POInExt.mapPOLine ");
          integrationLogger.debug("PRB Leaving POInExt.mapPOLine ");
    }

    /**
     * Maps the PeopleSoft distribution lines to the MAXIMO POCOST table.
     * 
     * @param distLines
     *            Reference to the PeopleSoft distribution lines.
     * @param irData
     *            Reference to MAXIMO Data.
     * 
     *  
     */
    public void mapPOCost(List distLines, StructureData irData, boolean issue, boolean prNotMapped)
            throws MXException
    {
        integrationLogger.debug("Entering POInExt.mapPOCost ");
         integrationLogger.debug("PRB Entering POInExt.mapPOCost ");


        boolean loop = true; //Do we need to map more than one POCOST?
        boolean mapDebit = true;  //Do we need to map the gldebitacct to the POLINE?
       
        if (!distLines.isEmpty())
        {
        	//HAQ
            //Iterator itrDist = distLines.iterator();
            //while (itrDist.hasNext() && loop)
        	for (int i = 0; i < distLines.size(); i++)
            {
                //HAQ
        		if (!loop)
                	break;
        		//Element distLine = (Element)itrDist.next();
        		Element distLine = (Element)distLines.get(i);

                irData.createChildrenData("POCOST", true);

                if (issue)
                {
                    irData.setCurrentData("QUANTITY", distLine
                            .getChildText("QTY_PO"));
                    irData.setCurrentData("LINECOST", distLine
                            .getChildText("MERCHANDISE_AMT"));
                }
                else
                {
                    irData.setCurrentData("PERCENTAGE", "100");
                    loop = false;
                }
                irData.setCurrentData("PONUM", distLine.getChildText("PO_ID"));
                irData.setCurrentData("COSTLINENUM", distLine
                        .getChildText("DISTRIB_LINE_NUM"));
                //setMXGLAccount(irData, "GLDEBITACCT", distLine);
                setLBNLGLAccount(irData, "GLDEBITACCT", distLine);
                irData.setCurrentData("SITEID", siteID);
                                
                irData.setParentAsCurrent();
                
                if(prNotMapped && mapDebit)
                {
                    //setMXGLAccount(irData, "GLDEBITACCT", distLine);
                	setLBNLGLAccount(irData, "GLDEBITACCT", distLine);
                    mapDebit = false;
                }
                
            }
           
        }
        
        integrationLogger.debug("Leaving POInExt.mapPOCost ");
        
        
          integrationLogger.debug("PRB Leaving POInExt.mapPOCost ");
    }

    /**
     * Calculate the tax by looping through the distribution lines and summing
     * the taxes. Also maps the PRNUM to the MAXIMO POLINE. Done here since a
     * looping through the distrib lines to sum up the tax to map to the POLINE.
     * 
     * @param taxTag
     *            Reference to the tag of the taxes to calculate.
     * @param distribLines
     *            Reference to all of the distribution lines.
     * @param irData
     *            Reference to the MAXIMO data.
     * 
     * @return tax amount.
     *  
     */
    public double[] calculateTax(String[] taxTag, List distribLines,
            StructureData irData) throws MXException
    {
        integrationLogger.debug("Entering POInExt.calculateTax ");

        double[] taxAmount = { 0, 0, 0 };

        if (!distribLines.isEmpty())
        {
            //HAQ
        	//Iterator itrDist = distribLines.iterator();
            //while (itrDist.hasNext())
        	for (int j = 0; j < distribLines.size(); j++)
            {
                //HAQ
            	//Element distribLine = (Element)itrDist.next();
            	Element distribLine = (Element)distribLines.get(j);

                for (int i = 0; i < taxTag.length; i++)
                {
                    String tax = distribLine.getChildText(taxTag[i]);
                    if (tax != null && !tax.equals(""))
                    {
                        taxAmount[i] = taxAmount[i] + Double.parseDouble(tax);
                    }
                }

                if (prNotMapped)
                {
                    prNotMapped = mapPRNum(distribLine, irData);
                }

            }
        }

        integrationLogger.debug("Leaving POInExt.calculateTax ");

        return taxAmount;
    }

    /**
     * Maps the PR number by looping through the distribution lines to find a PR
     * number. Since the PR number is at the distribution level in PeopleSoft
     * and in MAXIMO the PR number is at the PO line level one PR number is
     * allowed per Ship line. Loop through the distributions until a PR number
     * is found or return.
     * 
     * @param distLine
     *            Reference to PeopleSoft distribution lines Data.
     * @param irData
     *            Reference to Maximos PR data.
     * 
     * @return True if PR is mapped or false if PR is not mapped.
     */
    public boolean mapPRNum(Element distLine, StructureData irData)
            throws MXException
    {
        integrationLogger.debug("Entering POInExt.mapPRNum ");
      integrationLogger.debug("PRB Entering POInExt.mapPRNum ");

        String prnum = null;
        boolean prNotSet = true;

        prnum = distLine.getChildText("REQ_ID");

        if (prnum != null && !prnum.equals(""))
        {
            irData.setCurrentData("PRNUM", prnum);
            irData.setCurrentData("PRLINENUM", distLine
                    .getChildText("REQ_LINE_NBR"));
            prNotSet = false;
        }

        integrationLogger.debug("Leaving POInExt.mapPRNum ");
        integrationLogger.debug("PRB Leaving POInExt.mapPRNum ");

        return prNotSet;

    }

    /**
     * Check the PRLINE referenced on the PO and check if the line is a direct
     * issue. Only direct issue lines should have the distributions mapped.
     * 
     * @param irData
     *            Reference to MAXIMO data.
     * @param toSite
     *            Reference to the SITEID for
     * 
     * @exception RemoteException
     *                Remote Exception
     * @exception MXException
     *                MAXIMO Exception
     * @return True if the line is a direct issue line else false.
     *  
     */
    public boolean checkIssue(StructureData irData, String toSite)
            throws RemoteException, MXException
    {
        integrationLogger.debug("Entering POInExt.checkIssue ");

        boolean issue = false;

        MboSetRemote prLineSet = MXServer.getMXServer().getMboSet("PRLINE",
            getUserInfo());
        SqlFormat sqfPRLine = new SqlFormat(getUserInfo(),
                "siteid = :1 and prnum = :2 and " + "prlinenum = :3");
        sqfPRLine.setObject(1, "PRLINE", "SITEID", toSite);
        sqfPRLine.setObject(2, "PRLINE", "PRNUM", irData.getCurrentData("PRNUM"));
        sqfPRLine.setObject(3, "PRLINE", "PRLINENUM", irData.getCurrentData("PRLINENUM"));
        prLineSet.setWhere(sqfPRLine.format());
        
        prLineSet.reset();

        if (!prLineSet.isEmpty())
        {
            MboRemote prLine = prLineSet.moveFirst();
            if (prLine.getBoolean("issue"))
            {
                issue = true;
            }
        }

        integrationLogger.debug("Leaving POInExt.checkIssue ");

        return issue;
    }

}
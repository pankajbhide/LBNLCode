/*
 * Copyright(c) Interloc Solutions, Inc.  All rights reserved.
 *
 * 09-Oct-2008	Rohith Ramamurthy	Created
 */
package com.interlocsolutions.maximo.iface.psfsc88;

import java.rmi.RemoteException;
import java.text.ParseException;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.Iterator;
import java.util.List;

import org.jdom.Element;

import psdi.iface.mic.MicUtil;
import psdi.iface.mic.StructureData;
import psdi.util.MXApplicationException;
import psdi.util.MXException;

/**
 * PeopleSoft specific utility methods used by inbound Interfaces.
 */
public class PSInExt extends PSExt
{
    /**
     * Constructor.
     */
    public PSInExt()
    {
    }

    /**
     * Set external system statements for inbound transactions
     * 
     * @param irData
     *            reference to MAXIMO data
     *  
     */
    public void setSysIDIn(StructureData irData)
    {
        integrationLogger.debug("Entering ERPInExt.setSYSIDIn ");

        //These 3 fields are need to be mapped for every transaction coming
        // into Maximo
        // so its being done at this super class level as coding them here just
        // once will take care
        // for all transactions , rather than coding them in each transaction.
        irData.setCurrentData("OWNERSYSID", getExtSystem());
        irData.setCurrentData("SOURCESYSID", getExtSystem());

        integrationLogger.debug("Leaving ERPInExt.setSYSIDIn ");

    }

    /**
     * Method to convert the GL components from PeopleSoft message to Maximo GL string
     * 
     * @param in Message in Maximo format
     * @param accname Name of the GL account in field in Maximo.
     * @param psrecname Element in the PS message that contains the GL components.
     * 
     */
    public void setLBNLGLAccount(StructureData in, String accname,
            Element psrecname) throws MXException
    {
        integrationLogger.debug("Entering ERPInExt.setLBNLGLAccount ");

        String name;
        String glorder;

        List cfnames = getMaxIfaceControl().getXREFControlValues(
            getExtSystem(), "COA_XREF");

        if (cfnames.isEmpty())
        {
            throw new MXApplicationException("iface", "nocoaxref");
        }

        String[] values = new String[cfnames.size()];

        Iterator itr = cfnames.iterator();

        while (itr.hasNext())
        {
            name = (String)itr.next();
            MicUtil.INTEGRATIONLOGGER.debug(name);
            //glorder = getMaxIfaceControl().getXREFControlValue(getExtSystem(),"COA_XREF", null, null, name, false);
            glorder = getMaxIfaceControl().getXREFControlValue(getExtSystem(),
                "COA_XREF", null, null, "PROJECT", false);

            //String value = psrecname.getChildText(name);
            String value = psrecname.getChildText("ACCOUNT");
            if (value == null)
                value = "";

            values[Integer.parseInt(glorder)] = value.trim();
        }
        // have to handle if compvalues are null replace with ****
        boolean setDummy = false;
        for (int j = values.length - 1; j >= 0; j--)
        {
            if (!values[j].trim().equals(""))
                setDummy = true;
            else if (setDummy)
                values[j] = "*";

        }

        in.setGL(accname, values);

        integrationLogger.debug("Leaving ERPInExt.setLBNLGLAccount ");
    }
    
    /**
     * Method to convert the GL components from PeopleSoft message to Maximo GL string
     * 
     * @param in Message in Maximo format
     * @param accname Name of the GL account in field in Maximo.
     * @param psrecname Element in the PS message that contains the GL components.
     * 
     */
    public void setMXGLAccount(StructureData in, String accname,
            Element psrecname) throws MXException
    {
        integrationLogger.debug("Entering ERPInExt.setMXGLAccount ");

        String name;
        String glorder;

        List cfnames = getMaxIfaceControl().getXREFControlValues(
            getExtSystem(), "COA_XREF");

        if (cfnames.isEmpty())
        {
            throw new MXApplicationException("iface", "nocoaxref");
        }

        String[] values = new String[cfnames.size()];

        Iterator itr = cfnames.iterator();

        while (itr.hasNext())
        {
            name = (String)itr.next();
            glorder = getMaxIfaceControl().getXREFControlValue(getExtSystem(),
                "COA_XREF", null, null, name, false);

            String value = psrecname.getChildText(name);
            if (value == null)
                value = "";

            values[Integer.parseInt(glorder)] = value.trim();
        }
        // have to handle if compvalues are null replace with ****
        boolean setDummy = false;
        for (int j = values.length - 1; j >= 0; j--)
        {
            if (!values[j].trim().equals(""))
                setDummy = true;
            else if (setDummy)
                values[j] = "*";

        }

        in.setGL(accname, values);

        integrationLogger.debug("Leaving ERPInExt.setMXGLAccount ");
    }

    /**
     * Method to cocatenate PS vendor id and vendor_loc fields to map to MAXIMO
     * Vendor id.
     * 
     *  @param
     *           vendor PS Vendor field
     * @param location
     *            PS Vendor Location field.
     * @return String having the cocatenated value
     *  
     */
    public String concatMXVendor(String vendor, String location)
            throws MXException
    {
        integrationLogger.debug("Entering ERPInExt.concatMXVendor ");

        //Cocatenate the Vendor and Location fields to a MAXIMO Vendor column
        String mxvendor = null;

        if ((isStringNotNull(vendor)) && (isStringNotNull(location)))
        {
            mxvendor = vendor
                    + getMaxIfaceControl().getValueControl(getExtSystem(),
                        "VNDR_LOC_DELIM") + location;
        }

        integrationLogger.debug("Leaving ERPInExt.concatMXVendor ");

        return mxvendor;
    }

    /**
     * Create PO line number in MAXIMO. MAXIMO PO line number is a combination
     * of PeopleSoft PO line number and PO schedule line number.
     * 
     * @param lineNum
     *            Reference to PeopleSoft PO line number.
     * @param schedNum
     *            Reference to PeopleSoft schedule line number.
     * 
     * @return MAXIMO PO line number
     *  
     */
    public String createLineNumber(String lineNum, String schedNum)
    {
        integrationLogger.debug("Entering ERPInExt.createLineNumber ");

        String newLineNum;
        int lineLength = lineNum.length();
        int schedLength = schedNum.length();

        for (int i = lineLength; i < 5; i++)
        {
            lineNum = 0 + lineNum.trim();
        }

        for (int i = schedLength; i < 3; i++)
        {
            schedNum = 0 + schedNum.trim();
        }

        newLineNum = 1 + lineNum + schedNum;

        integrationLogger.debug("Leaving ERPInExt.createLineNumber ");

        return newLineNum;
    }

    /**
     * Maps storage area and levels to MAXIMO binnum for incoming inventory.
     * 
     * @param storageArea
     *            Reference to PeopleSoft STORAGE_AREA.
     * @param level1
     *            Reference to PeopleSoft STOR_LEVEL_1.
     * @param level2
     *            Reference to PeopleSoft STOR_LEVEL_2.
     * @param level3
     *            Reference to PeopleSoft STOR_LEVEL_3.
     * @param level4
     *            Reference to PeopleSoft STOR_LEVEL_4.
     * 
     * @exception MXException
     *                MAXIMO exception
     * @exception RemoteException
     *                Remote exception
     * 
     * @return new binnum
     */
    public String mapBinnum(String storageArea, String level1, String level2,
            String level3, String level4) throws MXException
    {
        integrationLogger.debug("Entering ERPInExt.mapBinnum ");

        String binnum = null;
        String binDelimiter = getMaxIfaceControl().getValueControl(
            getExtSystem(), "TOBIN_DELIMITER");
        binnum = storageArea + binDelimiter + level1 + binDelimiter + level2
                + binDelimiter + level3 + binDelimiter + level4;

        while (binnum.endsWith(binDelimiter))
        {
            //System.out.println("value of binnum = " + binnum);
            binnum = binnum.substring(0, (binnum.length() - binDelimiter
                    .length()));
        }

        integrationLogger.debug("Leaving ERPInExt.mapBinnum ");

        return binnum;

    }

    /**
     * Maps date time from PeopleSoft to a MEA date time format.
     * 
     * @param dateTime
     *            Reference to PeopleSoft date/time value.
     * 
     * @return date time string
     */
    public String getDateTime(String dateTime)
    {
        integrationLogger.debug("Entering ERPInExt.getDateTime ");

        int substringPosition = dateTime.indexOf(".");
        String newDateTime = dateTime.substring(0, substringPosition);
        newDateTime = newDateTime + dateTime.substring(26, 31);

        integrationLogger.debug("Leaving ERPInExt.getDateTime ");

        return newDateTime;
    }
    
    /**
     * Maps date from PeopleSoft to a MEA date format.
     * 
     * @param dateIn
     *            Reference to PeopleSoft date value.
     * 
     * @return date string
     */
    public String getMXDateTime(String dateIn)
    {
    	integrationLogger.debug("Entering PSInExt.getMXDate ");
    	//2007-03-16T11:06:30.000000-0600
    	String newDate = dateIn;
    	String s1 = "yyyy-MM-dd'T'HH:mm:ss";
    	String s2 = "yyyy-MM-dd'T'HH:mm:ss.SSSSSSZ";
    	try
    	{
	    	if(isStringNotNull(newDate))
	    	{
	    		Date dTmp = new SimpleDateFormat(s2).parse(dateIn);
	        	newDate = new SimpleDateFormat(s1).format(dTmp);
	    	}   	
    	}catch(ParseException pe)
    	{
    		integrationLogger.debug("Parse exception in PSInExt.getMXDate");
    	}
    	integrationLogger.debug("newdate is - "+newDate);
    	integrationLogger.debug("Leaving PSInExt.getMXDate ");
    	
    	return newDate;
    }
    
    /**
     * Maps date from PeopleSoft to a MEA date format.
     * 
     * @param dateIn
     *            Reference to PeopleSoft date value.
     * 
     * @return date string
     */
    public String getMXDate(String dateIn)
    {
    	integrationLogger.debug("Entering PSInExt.getMXDate ");
    	String newDate = dateIn;
    	String s1 = "yyyy-MM-dd'T'HH:mm:ss";
    	    	
    	try
    	{
	    	if(isStringNotNull(newDate))
	    	{
	    		Date dTmp = new SimpleDateFormat("yyyy-MM-dd").parse(dateIn);
	        	newDate = new SimpleDateFormat(s1).format(dTmp);
	        	newDate = newDate.toString()+"-07:00";
	    	}  	
    	}catch(ParseException pe)
    	{
    		integrationLogger.debug("Parse exception in PSInExt.getMXDate");
    	}
    	integrationLogger.debug("newdate is - "+newDate);
    	integrationLogger.debug("Leaving PSInExt.getMXDate ");
    	
    	return newDate;
    }

    /**
     * Calculate PO exchange rate by dividing the rate multiple by the rate
     * divisor.
     * 
     * @param rateMult
     *            Reference to PeopleSoft rate multiple.
     * @param rateDiv
     *            Reference to PeopleSoft rate divisor.
     * 
     * @return The exchangerate that will be mapped to MAXIMO.
     *  
     */
    public String calculateExchangerate(String rateMult, String rateDiv)
    {
        integrationLogger.debug("Entering ERPInExt.calculateExchangerate ");

        double dRateMult = Double.parseDouble(rateMult);
        double dRateDiv = Double.parseDouble(rateDiv);
        double exchangeRate = 1;

        if ((dRateDiv > 0) && (dRateMult > 0))
        {
            exchangeRate = dRateDiv / dRateMult  ;
        }

        integrationLogger.debug("Leaving ERPInExt.calculateExchangerate ");

        return Double.toString(exchangeRate);
    }

    /**
     * Get the latest comment from the comment record. Gets the comment based on
     * the type of transaction and the comment type. The record is effective
     * dated so we get the comment with the latest dated if more than one row
     * meets the comment type and transaction type criteria.
     * 
     * @param comments
     *            Reference to PeopleSoft comment record.
     * @param commentType
     *            LIN for line comment and HDR for header comment.
     * @param transType
     *            PO for PO transaction and RECV for receipt transaction.
     * @param lineNumber
     *            Line number for the PO or receipt line.
     * 
     * @return The description field from the comment record with the latest
     *         date.
     *  
     */
    public String getComment(List comments, String commentType,
            String transType, String lineNumber) throws MXException
    {
        integrationLogger.debug("Entering ERPInExt.getComment ");

        String recvLine = "RECV_LN_NBR";
        String poLine = "LINE_NBR";
        String lineTag = null;
        String description = null;
        Date commentDate = null;
        Date nextDate = null;

        if (transType.equals("PO") && commentType.equals("LIN"))
        {
            lineTag = poLine;
        }
        else if(transType.equals("RECV") && commentType.equals("LIN"))
        {
            lineTag = recvLine;
        }

        if (!comments.isEmpty())
        {

            //HAQ
        	//Iterator itrComm = comments.iterator();

            //Get the latest comment date before today
            //while (itrComm.hasNext())
        	for (int i = 0; i < comments.size(); i++)
            {

        		//HAQ
                //Element commentLine = (Element)itrComm.next();
        		Element commentLine = (Element)comments.get(i);

                if (commentLine.getChildText("COMMENT_TYPE")
                        .equals(commentType)
                        && (lineTag == null || commentLine
                                .getChildText(lineTag).equals(lineNumber)))
                {
                    if (commentDate == null)
                    {
                        commentDate = getCommentDate(commentLine
                                .getChildText("COMMENT_ID"));
                        description = commentLine.getChildText("COMMENTS_2000");
                    }
                    else
                    {
                        nextDate = getCommentDate(commentLine
                                .getChildText("COMMENT_ID"));
                    }

                    if (commentDate != null && commentDate.before(nextDate))
                    {
                        commentDate = nextDate;
                        description = commentLine.getChildText("COMMENTS_2000");
                    }
                }
            }
        }

        integrationLogger.debug("Leaving ERPInExt.getComment ");

        return description;
    }

    /**
     * Get the date into the format of a DATE object so dates can be compared.
     * 
     * @param date
     *            Reference to a date.
     * 
     * @return Date object ready to be compared.
     *  
     */
    public Date getCommentDate(String date) throws MXException
    {
        integrationLogger.debug("Entering ERPInExt.getCommentDate ");

        Date commentDate = null;
        String pattern = "yyyy.MM.dd HH:mm:ss.SSS";
        SimpleDateFormat sdf = new SimpleDateFormat(pattern);

        try
        {
            commentDate = sdf.parse(date);
        }
        catch (ParseException pe)
        {
            commentDate = null;
        }

        integrationLogger.debug("Leaving ERPInExt.getCommentDate ");

        return commentDate;
    }

}// end class

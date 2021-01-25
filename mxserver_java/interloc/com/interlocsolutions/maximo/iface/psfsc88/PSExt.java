/*
 * Copyright(c) Interloc Solutions, Inc.  All rights reserved.
 *
 * 09-Oct-2008	Rohith Ramamurthy	Created
 */
package com.interlocsolutions.maximo.iface.psfsc88;

import org.jdom.output.Format;
import org.jdom.output.XMLOutputter;

import psdi.iface.mic.MicUtil;
import psdi.iface.mic.StructureData;
import psdi.iface.migexits.ExternalExit;
import psdi.util.MXException;
import psdi.util.logging.MXLogger;


/**
*	External Exit Super class for PeopleSoft Integration.
*/
public class PSExt extends ExternalExit
{
	public static final MXLogger integrationLogger  = MicUtil.INTEGRATIONLOGGER;
		
	/**
	* Constructor.
	*/
	public PSExt()
	{
	}
	
	/**
	 *
	 * Check if the given String is null or empty String.
	 *
	 * @param instr String to be checked
	 *
	 * @return true if the string is not null false otherwise
	 */
	public boolean isStringNotNull(String instr)
	{
	    integrationLogger.debug("Entering ERPExt.isStringNotNull ");
	    
		if ((instr != null) && (! instr.trim().equals("")))
		{
				return true;
		}
				
		integrationLogger.debug("Leaving ERPExt.isStringNotNull ");
		
		return false;
	}


	/**
	* Substring a field from start to end.  Method first checks
	* to make sure the string is not null or empty.
	* 
	* 
	* @param instr field to substring
	* @param start first position of substring
	* @param end last position of substring
	* 
	* @return new string
	*
	*/
	public String doSubstring(String instr,int start,int end)
	{
	    integrationLogger.debug("Entering ERPExt.doSubstring ");
	    
		String outstr = null;
		
		if ( isStringNotNull(instr))
		{
			if (instr.trim().length() > end)
			{
				outstr = instr.substring(start,end);
			}
			else
			{
				outstr = instr;
			}
		}
		else
		{
			outstr = "";
		}
			
		integrationLogger.debug("Leaving ERPExt.doSubstring ");
		
		return outstr;
	}
	
	/**
	 * Prints XML message in log file
	 * 
	 * @author Haq Khan
	 * @param sData
	 * @throws MXException
	 */
	public void printStructureData(StructureData sData) throws MXException
    {
        integrationLogger.debug("Entering PSExt.printStructureData ");

		XMLOutputter od = new XMLOutputter(Format.getPrettyFormat());
		integrationLogger.debug("--------------------------------------------------------");
		integrationLogger.debug(od.outputString(sData.getData()).toString());
		integrationLogger.debug("--------------------------------------------------------");

        integrationLogger.debug("Leaving PSExt.printStructureData ");
        return;
    }

}

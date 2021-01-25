/*
 * Copyright(c) Interloc Solutions, Inc.  All rights reserved.
 *
 * 09-Oct-2008	Rohith Ramamurthy	Created
 * 
 * 09-July-2014 Praveen Muramalla 
 * 				Updated to retrieve the destination node 
 * 				from maximo.properties files
 */
package com.interlocsolutions.maximo.iface.psfsc88;

import java.rmi.RemoteException;
import java.util.HashMap;
import java.util.Map;
import java.util.Properties;

import org.jdom.Document;
import org.jdom.Element;

import psdi.iface.util.XMLUtils;

import psdi.server.MXServer;
import psdi.util.MXException;
import psdi.util.logging.MXLogger;
import psdi.iface.gateway.Interpreter;
import psdi.iface.mic.MicUtil;

/**
 * Interpreter class for the PSFSC84 adapter.
 * Defaults SENDER, IFACETYPE, and INTERFACE on the inbound message
 * 
 * @author rohithr
 *
 */
public class PSFSC88Interpreter extends Interpreter {

	protected Map props = null;
	protected Map xmlTags = new HashMap();
	protected Map xmlRootNodeProps = new HashMap();
	protected Map constProps = new HashMap();
	public static final MXLogger integrationLogger  = MicUtil.INTEGRATIONLOGGER;

	
	/**
	 * Constructor
	 * 
	 * @param props
	 */
	public PSFSC88Interpreter(Map props)
	{
		super(props);
	}


	/**
	 * Adds SENDER, IFACETYPE, and INTERFACE on the inbound message
	 * 
	 * @param extData the inbound message
	 * @return Map hash map containing message header information
	 * 
	 * @throws MXException
	 */
	public Map interpreteMessage(byte[] extData) throws MXException
	{
        if (integrationLogger.isDebugEnabled())
        {
        	integrationLogger.debug("PSFTInterpreter.interpreteMessage() - entering");
        }

		//set the name of the message
		Document doc = XMLUtils.convertBytesToDocument(extData);
		Element psHeader = doc.getRootElement().getChild("header");
		String interfaceName = psHeader.getChildText("subject");
        if (integrationLogger.isDebugEnabled())
        {
        	integrationLogger.debug("Interface Name is - "+interfaceName);
        }

		// Commented to retrieve PS Node dynamically
        // String sender = "PSFT_EP";
        
        MXServer mxserver = null;
		try {
			mxserver = MXServer.getMXServer();
		} catch (RemoteException e1) {
			e1.printStackTrace();
		}
		Properties mxProp = mxserver.getConfig();
		String sender = mxProp.getProperty("lbl.lbl_default_psnode");

		HashMap returnMap = new HashMap(3);
		//returnMap.put("SENDER","PSFT_EP");
		returnMap.put("SENDER",sender);
		returnMap.put("IFACETYPE","PSFSC88");
		returnMap.put("INTERFACE",interfaceName);
        if (integrationLogger.isDebugEnabled())
        {
        	integrationLogger.debug("PSFTInterpreter.interpreteMessage() - leaving");
        }
		return returnMap;
	}
}

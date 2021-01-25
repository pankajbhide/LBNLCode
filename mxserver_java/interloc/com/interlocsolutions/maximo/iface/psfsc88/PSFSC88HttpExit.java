/*
 * Copyright(c) Interloc Solutions, Inc.  All rights reserved.
 *
 * 09-Oct-2008	Rohith Ramamurthy	Created
 */
package com.interlocsolutions.maximo.iface.psfsc88;

import java.util.Map;

import psdi.util.*;
import psdi.iface.mic.*;

import org.jdom.*;

import psdi.iface.util.XMLUtils;
import psdi.iface.router.DefaultHTTPExit;

/**
 *  This Class handles the HTTP Response recieved from PS.
 */ 
 
public class PSFSC88HttpExit extends DefaultHTTPExit
{
	public PSFSC88HttpExit()
    {
		//super();
    }

/**
  * Processes the response information. This method checks whether the response code is
  * a sucess code or not. 
  * 
  * @param responseCode Response code.
  * @param responseMsg Response Message.
  * @param msgBodyData Response body in byte array.
  *
  * @exception throws MXException if the response is not as expected
  */
//    public void processResponseData(int responseCode, String responseMsg, byte[] msgBodyData) throws MXException
//    {
//		MicUtil.INTEGRATIONLOGGER.debug("Entering PSFSC88HttpExit.processResponseData ");
//		
//        try
//        {
//			MicUtil.INTEGRATIONLOGGER.debug(" Response recd from PS is *************"+new String(msgBodyData));
//
//  			if(responseCode == 200)
//            {
//               Document replydoc = XMLUtils.convertBytesToDocument(msgBodyData);
//			   String reply = replydoc.getRootElement().getAttributeValue("type");
//
//				if (! reply.equalsIgnoreCase("success"))
//				{
//					String statuscode = replydoc.getRootElement().getChildText("StatusCode");
//					String messageset = replydoc.getRootElement().getChildText("MessageSet");
//					String messageid = replydoc.getRootElement().getChildText("MessageID");
//					String defmessage = replydoc.getRootElement().getChildText("DefaultMessage");
//					MicUtil.INTEGRATIONLOGGER.error("Http Post to PeopleSoft Failed:\n\n Statuscode is = "+statuscode+
//													"\n Messageset is :"+ messageset+
//													"\n Messageid is :"+ messageid+
//													"\n Default Message is: "+defmessage);
//					throw new MXSystemException("iface","could_not_sucessfully_sent");
//				}
//            }
//
//        }
//        catch (Exception e)
//        {
//            System.err.println("Exception in PSFSC88HttpExit"+ e);
//			MicUtil.INTEGRATIONLOGGER.debug("Exception in PSFSC88HttpExit"+ e);
//            throw new MXSystemException("iface","could_not_sucessfully_sent");
//        }
//    }
/* HAQ - removed
public Map getHeaderProperties(Map arg0, byte[] arg1, Map arg2) {
	// TODO Auto-generated method stub
	return null;
}

public Map getURLProperties(Map arg0, byte[] arg1, Map arg2) {
	// TODO Auto-generated method stub
	return null;
}
*/

@Override
public byte[] processResponseData(int responseCode, String responseMsg, byte[] msgBodyData)
		throws MXException {
	MicUtil.INTEGRATIONLOGGER.debug("Entering PSFSC88HttpExit.processResponseData ");
	
    try
    {
		MicUtil.INTEGRATIONLOGGER.debug(" Response recd from PS is *************"+new String(msgBodyData));

			if(responseCode == 200)
        {
           Document replydoc = XMLUtils.convertBytesToDocument(msgBodyData);
		   String reply = replydoc.getRootElement().getAttributeValue("type");

			if (! reply.equalsIgnoreCase("success"))
			{
				String statuscode = replydoc.getRootElement().getChildText("StatusCode");
				String messageset = replydoc.getRootElement().getChildText("MessageSet");
				String messageid = replydoc.getRootElement().getChildText("MessageID");
				String defmessage = replydoc.getRootElement().getChildText("DefaultMessage");
				MicUtil.INTEGRATIONLOGGER.error("Http Post to PeopleSoft Failed:\n\n Statuscode is = "+statuscode+
												"\n Messageset is :"+ messageset+
												"\n Messageid is :"+ messageid+
												"\n Default Message is: "+defmessage);
				throw new MXSystemException("iface","could_not_sucessfully_sent");
			}
        }

    }
    catch (Exception e)
    {
        System.err.println("Exception in PSFSC88HttpExit"+ e);
		MicUtil.INTEGRATIONLOGGER.debug("Exception in PSFSC88HttpExit"+ e);
        throw new MXSystemException("iface","could_not_sucessfully_sent");
    }

	return null;
}

/* HAQ - removed
@Override
public Map<String, String> transformPayloadToFormData(Map<String, ?> arg0,
		byte[] arg1, Map<String, MaxEndPointPropInfo> arg2) {
	// TODO Auto-generated method stub
	return null;
}
*/


}
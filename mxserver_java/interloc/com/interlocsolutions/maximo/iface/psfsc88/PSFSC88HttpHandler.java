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
import java.util.*;
import java.io.*;
import java.net.*;

import org.jdom.*;
import org.jdom.output.Format;
import org.jdom.output.XMLOutputter;

import psdi.server.MXServer;
import psdi.util.*;
import sun.misc.BASE64Encoder;
import psdi.iface.mic.*;
import psdi.iface.router.*;

/**
 * HTTPHandler send xml data thro HTTP post to a given url.  It Supports
 * both HTTP and HTTPS. HTTPHandler sends data in a format
 * Content-Type = text/xml. There is no userinteraction such as popping
 * a dialog box as the property "allowUserInteraction" is set to false.
 * The protocol must always try to get a fresh copy of the object as the
 * property "useCaches" is set to false.
 *
 * This Class Implements RouterHandler Interface.
 * Added extends BaseRouterHandler - Haq
 *
 * @author rohithr
 * @version 1.0
 */

public class PSFSC88HttpHandler extends HTTPHandler implements RouterHandler
{
	private		URLConnection con = null;
	//private		Map httpInfo = null; //HAQ - Removed
	private static List props = new ArrayList(4);
	
	/* HAQ
	public static final String HTTPEXIT = "HTTPEXIT";
	public static final String URL = "URL";
	public static final String USERNAME = "USERNAME";
	public static final String PASSWORD = "PASSWORD";
	
	
	static
	{
		props.add(new RouterPropsInfo(HTTPEXIT));
		props.add(new RouterPropsInfo(URL));
		props.add(new RouterPropsInfo(USERNAME));
		props.add(new RouterPropsInfo(PASSWORD,true));
	}
	*/
	
	//HAQ - Added
	static 
    {
        props = new ArrayList(7);
        CookieHandler.setDefault(new CookieManager(null, CookiePolicy.ACCEPT_ALL));
        props.add(new RouterPropsInfo("HTTPEXIT"));
        props.add(new RouterPropsInfo("HTTPMETHOD"));
        props.add(new RouterPropsInfo("HEADERS"));
        props.add(new RouterPropsInfo("COOKIES"));
        props.add(new RouterPropsInfo("URL"));
        props.add(new RouterPropsInfo("READTIMEOUT"));
        props.add(new RouterPropsInfo("CONNECTTIMEOUT"));
        props.add(new RouterPropsInfo("USERNAME"));
        props.add(new RouterPropsInfo("PASSWORD", true));
    }
	
	
	public PSFSC88HttpHandler()
	{
	}
	
	/**
	 * Constructor from Superclass
	 * 
	 * @author Haq Khan
	 * @param endPointInfo
	 */
	public PSFSC88HttpHandler(MaxEndPointInfo endPointInfo) {
		super(endPointInfo);
	}

	/** 
	 * Main method for HTTP Post/Get
	 * 
	 * @author Haq Khan
	 * @see psdi.iface.router.HTTPHandler#invoke(java.util.Map, byte[])
	 */
	@Override
	public byte[] invoke(Map map, byte[] arg1) throws MXException {
		//super.invoke(map, arg1);
		sendData(map, arg1);
		return null;
	}
	
	/**
	* Sends data to a given url which is specified in 'destinationMap' HashMap. The destinationName
	* interfaceName may not be used in this Handler. But it may be used in other handler.
	*
	* HAQ - Removed destinationMap as the contents are covered by Map endPointPropVals.
	* 
	* @param data the xml transaction in byte array
	* @exception MXException if there's a problem in opening the connection,
	* writing to the connection, reading from the connection
	*/

	public void sendData(Map metaData, byte[] data)
		throws MXException
    {
		/* HAQ - Removed
		if(destinationMap == null)
			throw new MXSystemException("iface", "mapping_information_not_found");

		this.httpInfo = destinationMap;
		*/
		
		BufferedOutputStream outStream = null;
		InputStream inStream = null;
		
		//shit starts
//		StructureData sd = new StructureData(data, "PSFSC88", false);
		StructureData sd = new StructureData(data);
		Document psxml = sd.getData();
		Element msgHeader = psxml.getRootElement();
		//Element intName = msgHeader.getChild("IBRequest");
		
		//1.get the xml file and get count on the number of <transaction> sections.
		//List allPRLines = msgHeader.getChild("ContentSections").getChild("ContentSection")
		//					.getChild("Data").getChild("MX_REQUISITION_IN").getChild("MsgData").getChildren("Transaction");
		    

		
		MicUtil.INTEGRATIONLOGGER.debug("this is the data stream"+data.toString());
		MicUtil.INTEGRATIONLOGGER.debug("this is the structure data"+psxml.toString());
		MicUtil.INTEGRATIONLOGGER.debug("getRootElement - "+psxml.toString());
		
		//if not PR then normal processing.
		if(!msgHeader.getChildText("ExternalOperationName").equalsIgnoreCase("MX_REQUISITION_IN.VERSION_1"))
		{
			 try
		        {					
				    HTTPExit exit = getExitInstance();

		            String url = getUrl();
		            Map urlProps = exit.getURLProperties(metaData, data, endPointPropVals);
		            if(urlProps != null)
		            {
		                url = addURLProps(url, urlProps);
		            }
					URL postURL = new URL(url);

					con = postURL.openConnection();
					
					int setCntLength = data.length;
					setDefaultRequestProperty(setCntLength);
					
					Map headerProps = exit.getHeaderProperties(metaData, data, endPointPropVals);
		            if(headerProps != null)
		            {
		                setHeaderProperties(con, headerProps);
		            }

					outStream = new BufferedOutputStream(con.getOutputStream());
				    outStream.write(data);
					outStream.flush();

					inStream = con.getInputStream();
				    byte[] responseBody = Util.getByteArrayFromInputStream(inStream);
					// According to www spec the response status will be always first in the header
					//get the first response value to find out the response status code and msg
					String resMsg = con.getHeaderField(0);
					HashMap resHeader =  parseResponseStatusLine(resMsg);

					String resLine = (String)resHeader.get("ReasonLine");
					String temp = (String)resHeader.get("StatusCode");
					MicUtil.INTEGRATIONLOGGER.debug(temp);
				    int resCode = Integer.parseInt((String)(resHeader.get("StatusCode")));
				    exit.processResponseData(resCode, resLine, responseBody);

		        }
		        catch (IOException ioe)
		        {
					//MicUtil.INTEGRATIONLOGGER.error(ioe);
		            throw new MXSystemException("iface", "could_not_connect", ioe);
		        }
		        catch (Exception e)
		        {
					//MicUtil.INTEGRATIONLOGGER.error(e);
			        if(e instanceof MXException)
			            throw (MXException)e;
			        else
			            throw new MXSystemException("iface", "could_not_send", e);            
		        }
		        finally
		        {
		             //Always close the streams, no matter what.
		            try {
						if(outStream != null)
							outStream.close();
						if(inStream != null)
						    inStream.close();
		                //write code to close the connection.
		            }
		            catch (Exception e)
		            {
						MicUtil.INTEGRATIONLOGGER.error(e);
		            }
		        }
		}
		else
		{//following section is only for PR.
			
			//1.get the xml file and get count on the number of <transaction> sections.
			List allPRLines = msgHeader.getChild("ContentSections").getChild("ContentSection")
								.getChild("Data").getChild("MX_REQUISITION_IN").getChild("MsgData").getChildren("Transaction");
			
			//2.in a loop copy the entire <TRANSACTION> section from the xml.
			 if (!allPRLines.isEmpty())
		        {
		            //HAQ - Refactored from Iterator to for loop
				 	//Iterator itr = allPRLines.iterator();
		            //while (itr.hasNext())
				 	for (int i = 0; i < allPRLines.size(); i++)
		            {
		            	//2a.clone the original XML and then remove entire MsgData section
		            	Document newPSxml = (Document)psxml.clone();
		            	Element head = newPSxml.getRootElement();
		            	//Element msgData = head.getChild("ContentSections").getChild("ContentSection")
						//.getChild("Data");
		            	//boolean detach = msgData.removeChild("MX_REQUISITION_IN");
		            	
		            	//HAQ - Refactored
		            	//Element prLine = (Element)itr.next();
		            	Element prLine = (Element)allPRLines.get(i);
		            	
		            	//created mx_req_in
		            	Element base = new Element("MX_REQUISITION_IN");
		            	
		            	//added field types
		            	//HAQ - Nasty bug
		            	//base.addContent(head.getChild("ContentSections").getChild("ContentSection")
						//		.getChild("Data").getChild("MX_REQUISITION_IN").getChild("FieldTypes").detach());
		            	base.addContent((Element)head.getChild("ContentSections").getChild("ContentSection")
								.getChild("Data").getChild("MX_REQUISITION_IN").getChild("FieldTypes").clone());		            	
		            	//add the transaction.
		            	Element msg = new Element("MsgData");		            	
		            	//HAQ - Nasty bug
		            	//msg.addContent(prLine.detach());
		            	msg.addContent((Element)prLine.clone());
		            	base.addContent(msg);
		            	
		            	//2b.enclose the copied <transaction> section in CDATA
		            	CDATA cData = wrapPSXMLInCData(base);
		            	
		            	
		            	//build the header all over again.
		            	Element request = new Element("IBRequest");
		            	setPSField("ExternalOperationName", "MX_REQUISITION_IN.VERSION_1", request);
		            	
		            	Element from = new Element("From");
		    			setPSField("RequestingNode","MX_HTTP",from);
		        		request.addContent(from);
		        		
		        		Element to = new Element("To");
		        		
		        		// Commented to retrieve PS Node dynamically
		        		// setPSField("DestinationNode","PSFT_EP",to);
		        		
			        	MXServer mxserver = null;
						try {
							mxserver = MXServer.getMXServer();
						} catch (RemoteException e1) {
							e1.printStackTrace();
						}
						Properties mxProp = mxserver.getConfig();
						setPSField("DestinationNode", mxProp.getProperty("lbl.lbl_default_psnode"), to);
		        		
		        		request.addContent(to);
		        		
		        		setPSField("MessageVersion","VERSION_1",request);
		        		
		        		//2c.put this section in the newly cloned message.
		        		Element contentSections = new Element("ContentSections");
		        		Element contSection = new Element("ContentSection");
		        		setPSField("NonRepudiation","",contSection);
		        		Element data1= new Element("Data");
		        		data1.addContent(cData);
		        		contSection.addContent(data1);
		        		contentSections.addContent(contSection);
		        		request.addContent(contentSections);
		        		
		        		//3.convert back into byte[] and send the file.
		                // 
		        		Document psxml2 = new Document(request);
//		            	StructureData sd1 = new StructureData(psxml2, "PSFSC88", false);
		            	StructureData sd1 = new StructureData(psxml2);
		            	byte[] newData = sd1.getDataAsBytes();
		            	
		            	//HAQ - output message for debugging
		            	XMLOutputter op = new XMLOutputter(Format.getPrettyFormat());
		            	MicUtil.INTEGRATIONLOGGER.debug(op.outputString(psxml2));
		            	
		            	//send file
		            	try
				        {					
						    HTTPExit exit = getExitInstance();
		            		//PSFSC88HttpExit exit = (PSFSC88HttpExit)getExitInstance();

				            String url = getUrl();
				            //Map urlProps = exit.getURLProperties(metaData, data, destinationMap);
				            Map urlProps = exit.getURLProperties(metaData, newData, endPointPropVals);
				            if(urlProps != null)
				            {
				                url = addURLProps(url, urlProps);
				            }
							URL postURL = new URL(url);

							con = postURL.openConnection();
							
							int setCntLength = newData.length;
							setDefaultRequestProperty(setCntLength);
							
							Map headerProps = exit.getHeaderProperties(metaData, newData, endPointPropVals);
				            if(headerProps != null)
				            {
				                setHeaderProperties(con, headerProps);
				            }

							outStream = new BufferedOutputStream(con.getOutputStream());
						    outStream.write(newData);
							outStream.flush();

							inStream = con.getInputStream();
						    byte[] responseBody = Util.getByteArrayFromInputStream(inStream);
							// According to www spec the response status will be always first in the header
							//get the first response value to find out the response status code and msg
							String resMsg = con.getHeaderField(0);
							HashMap resHeader =  parseResponseStatusLine(resMsg);

							String resLine = (String)resHeader.get("ReasonLine");
							String temp = (String)resHeader.get("StatusCode");
							MicUtil.INTEGRATIONLOGGER.debug(temp);
						    int resCode = Integer.parseInt((String)(resHeader.get("StatusCode")));
						    exit.processResponseData(resCode, resLine, responseBody);

				        }
				        catch (IOException ioe)
				        {
							//MicUtil.INTEGRATIONLOGGER.error(ioe);
				            throw new MXSystemException("iface", "could_not_connect", ioe);
				        }
				        catch (Exception e)
				        {
							//MicUtil.INTEGRATIONLOGGER.error(e);
					        if(e instanceof MXException)
					            throw (MXException)e;
					        else
					            throw new MXSystemException("iface", "could_not_send", e);            
				        }
				        finally
				        {
				             //Always close the streams, no matter what.
				            try {
								if(outStream != null)
									outStream.close();
								if(inStream != null)
								    inStream.close();
				                //write code to close the connection.
				            }
				            catch (Exception e)
				            {
								MicUtil.INTEGRATIONLOGGER.error(e);
				            }
				        }
		            	//end send file
		            }
		        } 
		}
		//shit ends
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
	 
	    
		Element psfield = new Element(name);
		psfield.setText(data);
		parent.addContent(psfield);	
		
	
	
	}
	
	/**
	 * Method to wrap peoplesoft xml into a CData object for PS to accept our post.
	 *
	 * @param node the element that will be wrapped in CData
	 * 
	 * @return CData wrapped element
	 */
	public CDATA wrapPSXMLInCData(Element node)
	{
		
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
				
		
		
		return cData;
		

	}
    
	/* HAQ - Exists in superclass
	public List getProperties()
	{
		return props;
	}
	*/
	
	private void setHeaderProperties(URLConnection con, Map props)
	{
	    Iterator itr = props.keySet().iterator();
	    while(itr.hasNext())
	    {
	        String propName = (String)itr.next();
	        String value = (String)props.get(propName);
	        con.setRequestProperty(propName,value);
	        //buf.append("&"+propName+"="+URLEncoder.encode(value,"UTF-8"));
	    }
	    
	}
	
	private String addURLProps(String url, Map props) throws Exception
	{
	    Iterator itr = props.keySet().iterator();
	    StringBuffer buf = new StringBuffer(url);
	    boolean amp = false;
	    while(itr.hasNext())
	    {
	        String propName = (String)itr.next();
	        String value = (String)props.get(propName);
	        if(amp)
	        {
	            buf.append("&"+propName+"="+URLEncoder.encode(value,"UTF-8"));
	        }
	        else
	        {
	            amp = true;
	            buf.append("?"+propName+"="+URLEncoder.encode(value,"UTF-8"));
	        }
	    }
	    
	    return buf.toString();
	}

    private HTTPExit getExitInstance() throws Exception
    {
	    String HttpResponseExit = getHttpExitName();
	      if(HttpResponseExit == null)
	        HttpResponseExit = "psdi.iface.router.DefaultHTTPExit";
	    Object objExit = null;
	    try
	    {
	        Class exitClass = Class.forName(HttpResponseExit);
	        objExit = exitClass.newInstance();
	    }
	    catch(ClassNotFoundException ce)
	    {
			//MicUtil.INTEGRATIONLOGGER.error(ce);
	        throw new MXSystemException("iface", "response_class_not_found",ce);
	    }
	    catch(InstantiationException ie)
	    {
			//MicUtil.INTEGRATIONLOGGER.error(ie);
		   throw new MXSystemException("iface", "could_not_instantiate_response_class", ie);
	    }
	    return ((HTTPExit)objExit);
	    

    }

    
	/**
	* Returns the HTTPEXIT name from the map.
	*
	* @return HTTPEXIT name from the map. If there is no data in the map, it returns 'null'
	*/
    /* HAQ - Exists in superclass
	public String getHttpExitName()
    {
        return (httpInfo.get(HTTPEXIT))== null ? null : ((String)httpInfo.get(HTTPEXIT)).trim();
    }
	*/
    
	/**
	* Returns the url from the map.
	*
	* @return url from the map. If there is no data in the map, it returns 'null'
	*/
    /* HAQ - Exists in superclass
    public String getUrl()
    {
        return (httpInfo.get(URL))== null ? null : ((String)httpInfo.get(URL)).trim();
    }
    */

	/**
	* Returns the user name from the map.
	*
	* @return user name from the map. If there is no data in the map, it returns 'null'
	*/
    /* HAQ - Exists in superclass
    public String getUserName()
    {
        return (httpInfo.get(USERNAME))== null ? null : ((String)httpInfo.get(USERNAME)).trim();
    }
    */

	/**
	* Returns the password from the map.
	*
	* @return password from the map. If there is no data in the map, it returns 'null'
	*/
    private String getPassword()
    {
        //HAQ
    	//return (httpInfo.get(PASSWORD))== null ? null : ((String)httpInfo.get(PASSWORD)).trim();
    	return getPropertyValue("PASSWORD");
    }

	/**
	* parse the Response Header status line. According to W3C specs, the response
	* status will be always first in the Response Header. This method gets the
	* first response value to find out the Response Status Code and message.
	* Also it detects and finds the HTTP/0.9 Responses.
	*
	* @param headers the first Response status in a String format.
	*
	* @exception Exception if there's a problem in parsing the response. If it is
	* HTTP 0.9 reponse then it should be encoded with ISO 8859_1 character
	* encoding. Otherwise it will throw a UnsupportedEncodingException.
	*
	* @return a HashMap which contains 'Version', 'StatusCode', 'ReasonLine' elements.
	*/
	private HashMap parseResponseStatusLine(String headers) throws Exception
    {
		HashMap statusInfo = new HashMap();
		String sts_line = null;
		StringTokenizer lines = new StringTokenizer(headers, "\r\n");
		StringTokenizer elem = null;
		String Version    = "";
		int StatusCode = 0;
		String ReasonLine = "";
		// Detect and handle HTTP/0.9 responses
		if (!headers.regionMatches(true, 0, "HTTP/", 0, 5)  &&
			!headers.regionMatches(true, 0, "HTTP ", 0, 5))
		{
		    Version    = "HTTP/0.9";
		    StatusCode = 200;
		    ReasonLine = "OK";
			byte[] Data = headers.getBytes("8859_1");
			MicUtil.INTEGRATIONLOGGER.debug(Data.toString());
		}
		else
		{       // get the status line
			try
			{
			    sts_line = lines.nextToken();
			    elem     = new StringTokenizer(sts_line, " \t");
    		    Version    = elem.nextToken();
			    StatusCode = Integer.valueOf(elem.nextToken()).intValue();
			    if (Version.equalsIgnoreCase("HTTP"))	// NCSA bug
				Version = "HTTP/1.0";
			}
			catch (NoSuchElementException e)
			{
				throw new Exception("Invalid HTTP status line received: " +	sts_line);
			}
			try{ ReasonLine = elem.nextToken("").trim();}
			catch (NoSuchElementException e){ReasonLine = ""; }
		}
		statusInfo.put("Version", Version);
		statusInfo.put("StatusCode", String.valueOf(StatusCode));
		statusInfo.put("ReasonLine", ReasonLine);
		return statusInfo;
	}

	/**
	* encode the username and password with BASE64Encoder
	*
	* @param userName - a String
	* @param password - a String
	*
	* @return encoded string
	*
	*/
	public static String encode (String userName, String password)
	{
		BASE64Encoder enc = new sun.misc.BASE64Encoder();
		return(enc.encode((userName+":"+password).getBytes()));
	}
	/**
	* Set the default request property of the Url Connection. Some
	* of the value of default request property is given below
	*
	* "Content-Type"		-	text/xml
	* "DoOutput"			-	true
	* "DoInput"				-	true
	* "UseCache"			-	false
	* "AllowUserInteraction"-	false
	*
	* @param length the Content-Length of the data.
	*/
	private void setDefaultRequestProperty(int length) throws Exception
	{
		String userName = getUserName();
		String password = getPassword();
		String encodedUserPwd = "";


		con.setRequestProperty("Content-Type","text/xml");

		if(userName != null && password != null)
		{
			encodedUserPwd = encode(userName, password);
			con.setRequestProperty ("Authorization", "Basic " + encodedUserPwd);
		}
		con.setRequestProperty ("Content-Length", Integer.toString(length));
		con.setDoOutput(true);
		con.setUseCaches(false);
		con.setAllowUserInteraction(false);

	}

}

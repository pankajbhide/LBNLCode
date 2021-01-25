/*
 * Copyright(c) Interloc Solutions, Inc.  All rights reserved.
 *
 * 09-Oct-2008	Rohith Ramamurthy	Created
 * 
 * 03-Mar-2010  Pankaj Get the vendor from purchase order which
 *                     was previously synchronized into MAXIMO.
 *                     
 *                     For a few date columns, use method getMxDate()
 */
package com.interlocsolutions.maximo.iface.psfsc88;

import java.util.*;
import java.rmi.*;

import psdi.util.*;
import psdi.iface.mic.*;
import psdi.mbo.MboRemote;
import psdi.mbo.MboSetRemote;
//import psdi.mbo.MboSetRemote;
//import psdi.mbo.SqlFormat;
import psdi.app.site.*;
import psdi.server.*;

import org.jdom.*;

/**
 *	Process PeopleSoft Vouchers.
 */
public class InvoiceInExt extends PSInExt
{
	boolean mapAbs=false; 
	String orgid = null;
	String siteid = null;
    String strCompany=null;
	
     /* Constructor.
     */
    public InvoiceInExt()
    {
    }
    
	/**
	*	Builds MAXIMO IR from PeopleSoft ER.
	*	This method is called by mea's ExitProcessor
	*
	*	@param exitData Reference to ER Data.
	*	@return irData Maximo IrData
	*
	*	@exception MXException MAXIMO exception
	*	@exception RemoteException Remote exception
	*/
    public StructureData setDataIn(StructureData exitData) throws MXException, RemoteException
    {    	 	
		integrationLogger.debug("Entering InvoiceInExt.setDataIn ");
				
		Document psxml = exitData.getData();
		Element psheader = psxml.getRootElement();
		
		Element voucher = psheader.getChild("GENERIC").getChild("MsgData").getChild("Transaction").getChild("VOUCHER");
		
		if(voucher == null)
		{
			String[] params = {"VOUCHER"};
			throw new MXSystemException("iface","ps-nopsxmltag",params);
		}

		List vchLine = voucher.getChildren("VOUCHER_LINE");

		if (vchLine == null)
		{
			String[] params = {"VOUCHER_LINE"};
			throw new MXSystemException("iface","ps-nopsxmltag",params);
		}

//		StructureData irData= new StructureData(getIntPointName(),getExtSystem(),0,false);
		StructureData irData = new StructureData(this.messageType, this.mosName, MicUtil.getMaxVar("BASELANGUAGE"), 1, false, false);
		// HAQ
        irData.breakData();
		//irData.addIntObject();
		//irData.setPrimaryObject("INVOICE");

		//setInvoiceData(irData,voucher);
		//Changed by Pankaj on 3/10/2010
		//Added vchLine argument to the method
		setInvoiceData(irData,voucher, vchLine);
				
		//Iterate over the voucher line items....
		
		 Element vline = null;
		 //HAQ
		 //Iterator itr = vchLine.iterator();
		 
		 //while (itr.hasNext())
		 for (int i = 0; i < vchLine.size(); i++)
		 {
			 //HAQ
			 //vline = (Element)itr.next();
			 vline = (Element)vchLine.get(i);
			 irData.createChildrenData("INVOICELINE",true);
			setInvLines(irData,vline);
			irData.setParentAsCurrent();
		 }
		printStructureData(irData);
		integrationLogger.debug("Leaving InvoiceInExt.setDataIn ");
		
		return irData;
		
    } // end method

	/**
	*	Maps the Invoice Level fields of MAXIMO from PeopleSoft ER.
	*
	*	@param struc Reference to MAXIMO IR being mapped.
	*	@param voucher Reference to PS Voucher Hdr record
	*
	*	@exception MXException MAXIMO exception
	*	@exception RemoteException Remote exception
	*/
	public void setInvoiceData(StructureData struc, Element voucher,
			List voucherline) throws MXException,RemoteException
	{
		integrationLogger.debug("Entering InvoiceInExt.setInvoiceData");
		
		struc.setCurrentData("SITEID",getMaxIfaceControl().getXREFControlValue(getExtSystem(), "SITEID_APBU", null, null, 
													voucher.getChildText("BUSINESS_UNIT"), false));
		
		//get siteid
		siteid = struc.getCurrentData("SITEID");
		
		//get the org for the above siteid
		orgid = ((SiteServiceRemote) MXServer.getMXServer().lookup("SITE")).
			 								getOrgForSite(struc.getCurrentData("SITEID"),getUserInfo());
		struc.setCurrentData("CURRENCYCODE",voucher.getChildText("TXN_CURRENCY_CD"));
		struc.setCurrentData("CHANGEDATE",getMXDate(voucher.getChildText("LAST_UPDATE_DT")));
		struc.setCurrentData("CHANGEBY",voucher.getChildText("OPRID_LAST_UPDT"));
		//HAQ
		struc.setCurrentData("POSITEID",siteid);
		struc.setCurrentData("TOSITEID",siteid);
		
		String desc = voucher.getChildText("DESCR254_MIXED");
		if (isStringNotNull(desc))
		{
			if (desc.length() > 100)
			{
				struc.setCurrentData("INVOICEDESC",desc.substring(0,100).trim());
			}
			else
			{
				struc.setCurrentData("INVOICEDESC",desc);
			}
		}

		String voucherStyle=voucher.getChildText("VOUCHER_STYLE");
		if(voucherStyle !=null && voucherStyle.equals("CORR"))
		{
			String strCredit = MXServer.getMXServer().getMaximoDD().getTranslator().toExternalDefaultValue("INVTYPE", "CREDIT",struc.getCurrentData("SITEID"),orgid);
			struc.setCurrentData("DOCUMENTTYPE",strCredit );
			mapAbs=true;
		}
		
		struc.setCurrentData("DUEDATE", getMXDate(voucher.getChildText("DUE_DT")));
		struc.setCurrentData("ENTERDATE", getMXDate(voucher.getChildText("ENTERED_DT")));
		struc.setCurrentData("ENTERBY",voucher.getChildText("OPRID"));	
		struc.setCurrentData("EXCHANGEDATE",getMXDate(voucher.getChildText("INVOICE_DT")));
		
		double div = Double.parseDouble(voucher.getChildText("RATE_MULT")) / Double.parseDouble(voucher.getChildText("RATE_DIV"));
		struc.setCurrentData("EXCHANGERATE",div);
		
		struc.setCurrentData("INVOICEDATE",getMXDate(voucher.getChildText("INVOICE_DT")));
		struc.setCurrentData("INVOICENUM",voucher.getChildText("VOUCHER_ID"));
		struc.setCurrentData("ORIGINVOICENUM",voucher.getChildText("VOUCHER_ID_RELATED"));	
		struc.setCurrentData("PAID",voucher.getChildText("PAY_AMT"));
		struc.setCurrentData("PAYMENTTERMS",voucher.getChildText("PYMNT_TERMS_CD"));
		struc.setCurrentData("STATUSDATE",getMXDate(voucher.getChildText("LAST_UPDATE_DT")));
		//		Read the maxvalue from Valuelist  for IVSTATUS.
		struc.setCurrentData("STATUS",MXServer.getMXServer().getMaximoDD().getTranslator().toExternalDefaultValue("IVSTATUS", "APPR",struc.getCurrentData("SITEID"),orgid));
		
		//*********************************************************************
		//  Get the vendor from po.company that was previously synchronized 
		// in MAXIMO.  (06/01/18)
		//*******************************************************************
	
		 
        String strPonum=null;
        
        Element vline = null;
		//HAQ
        //Iterator itr = voucherline.iterator();
		 
		 //while (itr.hasNext())
         for (int j = 0; j < voucherline.size(); j++)
		 {
        	 //HAQ
			 //vline = (Element)itr.next();
        	 vline = (Element)voucherline.get(j);
			 strPonum=vline.getChildText("PO_ID").trim();
			 break;  // get the first one
		 }
		 
         // Find out whether the record exists in PO MBO Collection   
        String strWhere  =" orgid='LBNL' and siteid='FAC' and";
        strWhere +=" ponum='"+ strPonum + "'";
        
        MboSetRemote mbosetremote= MXServer.getMXServer().getMboSet("PO", getUserInfo());
        mbosetremote.reset();
        mbosetremote.setWhere(strWhere);
         
        // If the collection is not empty, then it is a valid PO against
        // which the voucher would be synchronized     
        if( !mbosetremote.isEmpty())
        {
           for(int i=0; i< mbosetremote.count(); i++)
            {
         	  MboRemote po=(MboRemote)mbosetremote.getMbo(i);
              strCompany = po.getString("vendor").trim();
            }
        }           	
        if (mbosetremote !=null) mbosetremote.close();
        
		//if (strCompany !=null && strCompany.length() >0)
		//	struc.setCurrentData("VENDOR",strCompany);
		//else // if company on po is not good, then, take from XML (may not happen)
		//	struc.setCurrentData("VENDOR",concatMXVendor(voucher.getChildText("VENDOR_ID"),voucher.getChildText("VNDR_LOC")));
			
		//Commented by Pankaj 3/3/10
		//struc.setCurrentData("VENDOR",concatMXVendor(voucher.getChildText("VENDOR_ID"),voucher.getChildText("VNDR_LOC")));

        // Pankaj June 1, 18 - Keep same vendor indicated on XML 
        struc.setCurrentData("VENDOR",concatMXVendor(voucher.getChildText("VENDOR_ID"),voucher.getChildText("VNDR_LOC")));
		
		
		struc.setCurrentData("VENDORINVOICENUM",voucher.getChildText("INVOICE_ID"));
		// Changed by Pankaj 3/3/10
		struc.setCurrentData("DISCOUNTDATE",getMXDate(voucher.getChildText("DSCNT_DUE_DT")));
		//struc.setCurrentData("DISCOUNTDATE",voucher.getChildText("DSCNT_DUE_DT"));
	
		//	To set the ownersysid etc...	
		setSysIDIn(struc);	

		integrationLogger.debug("Leaving InvoiceInExt.setInvoiceData");

	}//end setInvoiceData

	/**
	*	Create InvoiceLines of Maximo from VoucherLines of Peoplesoft.
	*
	*	@param struc Reference to MAXIMO IR being mapped.
	*	@param line Reference to PS Voucher line details.
	*	
	*	@exception MXException MAXIMO exception
	*	@exception RemoteException  Remote exception
	*/
	public void setInvLines(StructureData struc,Element line) throws MXException, RemoteException
	{
		integrationLogger.debug("Entering InvoiceInExt.createInvLines");

		//struc.setCurrentData("SITEID",line.getChildText("MX_SITE"));
		struc.setCurrentData("SITEID",line.getChildText("MX_ORIGIN"));
		struc.setCurrentData("DESCRIPTION",line.getChildText("DESCR"));
		struc.setCurrentData("ENTERDATE", struc.getParentData("ENTERDATE"));
		struc.setCurrentData("ENTERBY",struc.getParentData("ENTERBY"));	
		struc.setCurrentData("INVOICELINENUM", line.getChildText("VOUCHER_LINE_NUM"));
		struc.setCurrentData("INVOICEUNIT",line.getChildText("UNIT_OF_MEASURE"));
		struc.setCurrentData("ITEMNUM",line.getChildText("INV_ITEM_ID"));
		//HAQ
		struc.setCurrentData("IVOL_POSITEID",line.getChildText("MX_ORIGIN"));
		struc.setCurrentData("POSITEID",line.getChildText("MX_ORIGIN"));
		//struc.setCurrentData("POREVISIONNUM","0");
		
		//if (! isStringNotNull(line.getChildText("MX_SITE")))
		if (! isStringNotNull(line.getChildText("MX_ORIGIN")))
		{
			// Invoice is not linked to a MAXIMO created PR
			struc.setCurrentDataNull("ITEMNUM");
			struc.setCurrentData("LINETYPE",MXServer.getMXServer().getMaximoDD().getTranslator().
											toExternalDefaultValue("LINETYPE", "SERVICE",struc.getParentData("SITEID"),orgid));
		}
		
		struc.setCurrentData("PONUM",line.getChildText("PO_ID"));
		
		if (isStringNotNull(line.getChildText("PO_ID")))
		{
			String poowner = getPOOwner(line);
			
			if (isStringNotNull(poowner))
			{
			    if (poowner.equals(getExtSystem()))
			    {
			        //struc.setCurrentData("POLINENUM",createLineNumber(line.getChildText("LINE_NBR"),line.getChildText("SCHED_NBR")));
			    	struc.setCurrentData("POLINENUM",line.getChildText("LINE_NBR"));
			    }
			    struc.setCurrentData("POLINENUM", line.getChildText("LINE_NBR"));
			}
			else
			{
			    struc.setCurrentData("POLINENUM", line.getChildText("LINE_NBR"));
			}
		}
		    
		struc.setCurrentData("UNITCOST",line.getChildText("UNIT_PRICE"));	
		
		
		//*************************************************
        // Pankaj June 1,2018 Get Vendor from voucher line		
		//*************************************************
		//struc.setCurrentData("VENDOR",struc.getParentData("VENDOR"));
		
		if (isStringNotNull(line.getChildText("VENDOR_ID")))
			struc.setCurrentData("VENDOR",concatMXVendor(line.getChildText("VENDOR_ID"),line.getChildText("VNDR_LOC")));
		else
			struc.setCurrentData("VENDOR",strCompany);
		
					
		if ((MXFormat.stringToInt(line.getChildText("QTY_VCHR")) != 0))
		{
			if(mapAbs)
			{
				double qtyVchr= Double.parseDouble(line.getChildText("QTY_VCHR"));
				struc.setCurrentData("INVOICEQTY",Math.abs(qtyVchr));
			}
			else
			{
				struc.setCurrentData("INVOICEQTY",line.getChildText("QTY_VCHR"));
			}
		
		}
		else
		{
			struc.setCurrentDataNull("INVOICEQTY");
		}
				
		if(isStringNotNull(line.getChildText("MERCHANDISE_AMT")))
		{
			if (mapAbs)
			{
				double mAmt= Double.parseDouble(line.getChildText("MERCHANDISE_AMT"));
				struc.setCurrentData("LINECOST",Math.abs(mAmt));
			}
			else
			{
				struc.setCurrentData("LINECOST",line.getChildText("MERCHANDISE_AMT"));
			}
		}
			
		// Now Process the Voucher Distributions
		List vchAcctLine = line.getChildren("VCHR_ACCTG_LINE");
		if (vchAcctLine == null)
		{
			String[] params = {"VCHR_ACCTG_LINE"};
			throw new MXSystemException("iface","ps-nopsxmltag",params);
		}

		String tempval = null;
		double sumMiscAmt  = 0.0;
		double sumFrtAmt  = 0.0;
		double sumUTaxAmt  = 0.0;
		double sumSTaxAmt = 0.0;
		double addsums = 0.0;
		double sumVatAmt=0.0;
		//double sumDisAmt=0.0;
	
		Element vAcctLine = null;
		//HAQ
		//Iterator itr = vchAcctLine.iterator();
 		//while (itr.hasNext())
		for (int i = 0; i < vchAcctLine.size(); i++)
		{
			//HAQ
			//vAcctLine = (Element)itr.next();
			vAcctLine = (Element)vchAcctLine.get(i);
			tempval = vAcctLine.getChildText("MISC_AMT");
			sumMiscAmt = sumMiscAmt + Double.parseDouble(tempval);
			tempval = vAcctLine.getChildText("FREIGHT_AMT");
			sumFrtAmt = sumFrtAmt + Double.parseDouble(tempval);
			tempval = vAcctLine.getChildText("VAT_INV_AMT");
			sumVatAmt = sumVatAmt + Double.parseDouble(tempval);
			tempval = vAcctLine.getChildText("SALETX_AMT");
			sumSTaxAmt = sumSTaxAmt + Double.parseDouble(tempval);
			tempval = vAcctLine.getChildText("USETAX_AMT");
			sumUTaxAmt = sumUTaxAmt + Double.parseDouble(tempval);
			//tempval = vAcctLine.getChildText("DSCNT_AMT");
			//sumDisAmt = sumDisAmt + Double.parseDouble(tempval);
		}
		
		addsums = sumMiscAmt + sumFrtAmt;
		struc.setCurrentData("PRORATECOST",new Double(addsums).toString());
					
		if(sumSTaxAmt != 0.0)
		{
			if(mapAbs)
			{
				struc.setCurrentData("TAX1",Math.abs(sumSTaxAmt));
			}
			else
			{
				struc.setCurrentData("TAX1",sumSTaxAmt);
			}
						
			struc.setCurrentData("TAX1CODE",((Element)vchAcctLine.get(0)).getChildText("TAX_CD_SUT"));
		}

		if(sumUTaxAmt != 0.0)
		{
			if(mapAbs)
			{
				struc.setCurrentData("TAX1",Math.abs(sumUTaxAmt));
			}
			else
			{
				struc.setCurrentData("TAX1",sumUTaxAmt);
			}
				
			struc.setCurrentData("TAX1CODE",((Element)vchAcctLine.get(0)).getChildText("TAX_CD_SUT"));
		}

		if(sumVatAmt != 0.0)
		{
			if(mapAbs)
			{
				struc.setCurrentData("TAX2",Math.abs(sumVatAmt));
			}
			else
			{
				struc.setCurrentData("TAX2",sumVatAmt);
			}
		
			struc.setCurrentData("TAX2CODE",((Element)vchAcctLine.get(0)).getChildText("TAX_CD_VAT"));
		}
		
		//added new custom stuff for LBNL
		//double totalVariance = 0.0;
		//totalVariance = addsums-sumDisAmt;
		
		if (line.getChild("MX_PRICE_VAR") != null)
		{
			addsums = 0;
			tempval = line.getChild("MX_PRICE_VAR").getChildText("PRICE");
			addsums = addsums + Double.parseDouble(tempval);
			
			/*tempval = line.getChild("MX_PRICE_VAR").getChildText("MX_TAX_VAR");
			addsums = addsums + Double.parseDouble(tempval);*/
			
			//totalVariance += addsums;
			struc.setCurrentData("PRICEVAR",addsums);
			//struc.setCurrentData("PRICEVAR",totalVariance);
		}
		
		
		
		// Now create INVOICECOST record per invoiceline.
				
		Element vAcctline = null;
		//HAQ
		//Iterator itr1 = vchAcctLine.iterator();
 
		 //while (itr1.hasNext())
		for (int i = 0; i < vchAcctLine.size(); i++)
		 {
			//HAQ
			//vAcctline = (Element)itr1.next();
			 vAcctline = (Element)vchAcctLine.get(i);
			struc.createChildrenData("INVOICECOST",true);
			setInvCost(struc,line,vAcctline);
			struc.setParentAsCurrent();
		 }
			
		 integrationLogger.debug("Leaving InvoiceInExt.setInvLines");

	 }// end setInvLines
	
	/**
	*	Create the InvoiceCost details of Maximo for every Invoice Line.
	*
	*	@param struc Reference to MAXIMO IR being mapped.
	*	@param line Reference to PS Voucher line details.
	*	@param vchAcctLine Reference to PS Accounting line details.
	*	
	*	@exception MXException MAXIMO exception
	*	@exception RemoteException  Remote exception
	*/	
	public void setInvCost(StructureData struc ,Element line,Element vchAcctLine) throws MXException, RemoteException
	{
		integrationLogger.debug("Entering InvoiceInExt.setInvCost");

		struc.setCurrentData("COSTLINENUM",vchAcctLine.getChildText("DISTRIB_LINE_NUM"));
		struc.setCurrentData("VENDOR",struc.getParentData("VENDOR"));
		//struc.setCurrentData("REFWO",line.getChildText("MX_WONUM"));
		struc.setCurrentData("UNITCOST",line.getChildText("UNIT_PRICE"));
		//HAQ
		struc.setCurrentData("POSITEID",struc.getParentData("SITEID"));
		struc.setCurrentData("TOSITEID",struc.getParentData("SITEID"));
		
		//setMXGLAccount(struc,"GLDEBITACCT",vchAcctLine);
		setLBNLGLAccount(struc,"GLDEBITACCT",vchAcctLine);
		//String [] values = new String[1];
		//values[0] = vchAcctLine.getChildText("ACCOUNT");
		//struc.setGL("GLDEBITACCT", values);
		

		if(isStringNotNull(vchAcctLine.getChildText("MERCHANDISE_AMT")))
		{
			if (mapAbs)
			{
				double amount= Double.parseDouble(vchAcctLine.getChildText("MERCHANDISE_AMT"));
				struc.setCurrentData("LINECOST",Math.abs(amount));
			}
			else
			{
				struc.setCurrentData("LINECOST",vchAcctLine.getChildText("MERCHANDISE_AMT"));
			}
		}

/*		if(isStringNotNull(vchAcctLine.getChildText("MONETARY_AMOUNT")))
		{
			if (mapAbs)
			{
				double amount= Double.parseDouble(vchAcctLine.getChildText("MONETARY_AMOUNT"));
				struc.setCurrentData("LINECOST",Math.abs(amount));
			}
			else
			{
				struc.setCurrentData("LINECOST",vchAcctLine.getChildText("MONETARY_AMOUNT"));
			}
		}
		*/
		if ((MXFormat.stringToInt(vchAcctLine.getChildText("QTY_VCHR"))) != 0)
		{
			if(mapAbs)
			{
				double qtyVchr= Double.parseDouble(vchAcctLine.getChildText("QTY_VCHR"));
				struc.setCurrentData("QUANTITY",Math.abs(qtyVchr));
			}
			else
				struc.setCurrentData("QUANTITY",vchAcctLine.getChildText("QTY_VCHR"));
		}
		else
		{
			struc.setCurrentDataNull("QUANTITY");
		}
			
		integrationLogger.debug("Leaving InvoiceInExt.setInvCost");
	}
	
	/**
	*	Checks the MX database to see if PO is owned by MX or PS.
	*
	*	@param line Reference to PS Voucher Line.
	*	@return String Having the value of PO.Ownersysid
	*
	*	@exception MXException MAXIMO exception
	*	@exception RemoteException Remote exception
	*/
	private String getPOOwner(Element line) throws MXException, RemoteException
	{
		integrationLogger.debug("Entering InvoiceInExt.getPOOwner");
		MboSetRemote mboSet= null;
		try
		{
			mboSet = MXServer.getMXServer().getMboSet("PO", userInfo);
			mboSet.setWhere("ponum = '"+line.getChildText("PO_ID")+"' and siteid = '"+siteid+"'");
			mboSet.reset(); //HAQ - bug fix
			//HAQ
			integrationLogger.debug("InvoiceInExt.getPOOwner...isEmpty(): " + mboSet.isEmpty());
			if (!mboSet.isEmpty()) {
				if (mboSet.moveFirst().isNull("OWNERSYSID"))
				{
					return null;
				}
				else 
				{
				    return mboSet.moveFirst().getString("OWNERSYSID");
				}
			} else {
				return null;
			}
				
			
		}
		finally
		{
			mboSet.close();
			integrationLogger.debug("Leaving InvoiceInExt.getPOOwner");
		}
	}
	
}//end class

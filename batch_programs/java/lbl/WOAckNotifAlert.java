package lbl;

import java.io.BufferedWriter;
import java.io.FileWriter;
import java.io.PrintWriter;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.text.SimpleDateFormat;
import java.util.Date;

import util.MailUtil;
import util.MaxConnection;


/****************************************************************
 * 
 * Program name: WOAckNotifAlert.java * Description : This program sends the
 * email notifications in following circumstances:
 * 
 * Acknowledgement-The work order is created, the reportedby, supervisor,
 * location, supervisor leadcraft are identified.
 * 
 * Notification to requester/and customer for feedback when the work order is
 * completed.
 * 
 * Date Written : 12-February-2007
 * 
 * Author : Pankaj Bhide
 * 
 * Modification History : Pankaj Bhide - 6/3/07 - Prevent null pointer error, if
 * the supervisor phone is null.
 * 
 * Pankaj Bhide - 6/24/07 - Do not write to file. - Extra logging in phase-4 -
 * Go back 1 day prior for getting the candidate records for ack and notify
 * 
 * Pankaj Bhide - 8/9/07 Please change the wording on the automated feedback
 * email form from
 * 
 * Please click on this link to record your feedback the work. --- change to
 * Please click on this link to record your feedback for the work performed.
 * 
 * Pankaj Bhide -10/4/07 In the notification email to the customer, change the
 * position of the hyperlink which will allow customer to submit the feedback.
 * 
 * Pankaj Bhide - 06/06/08 Fixed spelling mistake for acknowledgment.
 * 
 * Pankaj Bhide - 04/27/09 Changes for MXES
 * 
 * Pankaj Bhide - 07/28/10 Changes for new feedback requirements.
 * 
 * 1) The contents in WO_FEEDBACK_WHERE are revamped.
 * 
 * 2) The worklog records are updated after the notifications are sent to the
 * customers.
 * 
 * Pankaj Bhide - 08/17/10 Send link in the acknowlegement email notifying the
 * customer about the work order visibility.
 * 
 * Pankaj Bhide - 09/16/10 Minor change in the notification email text as
 * suggested by Heather Pinto
 * 
 * Pankaj Bhide - 09/18/10 In case of notification, insert/update record into
 * lbl_woacknotify table only if the work order is completed.
 * 
 * Pankaj Bhide - 10/21/10 Added union for generating feedback requests as we
 * are not updating lbl_woacknotify table in case the work order is not
 * completed (this resulted not sending any feedback request).
 * 
 * Pankaj Bhide - 04/20/11 RT#93720 Do not send email to requester for work
 * order feedback.
 * 
 * Pankaj Bhide - 02/19/13 WOR-2 changes - Print lead, lead name, lead phone if
 * present on work order.
 * 
 * Pankaj Bhide - 10/29/15 - Changes for MAXIMO 7.6
 * 
 * Pankaj Bhide - 5/2/16 JIRA EF-3492 - Do not send link for submitting
 * feedback.
 * 
 * Pankaj Bhide - 6/24/16 JIRA EF-3895 - Send only work order acknowlegements
 * 
 * Pankaj Bhide - 8/24/18 JIRA EF-8422 - Mark sender of the emails to
 * fam@lbl.gov instead of wrc@lbl.gov
 * 
 * Pankaj Bhide - 9/14/18 JIRA EF-9491 - Misc formatting revisions
 * ******************************************************************************************************************/
public class WOAckNotifAlert {

	public static void main(String[] args) throws SQLException, Exception {

		// Changes for MXES
		if (args.length == 0) {
			System.out.println("WOAckNotifAlert <orgid> <siteid>");
			System.exit(1);
		}

		String strOrgid = args[0].trim();
		String strSiteid = args[1].trim();

		if (strOrgid.length() == 0)
			strOrgid = "LBNL";

		if (strSiteid.length() == 0)
			strSiteid = "FAC";

		PrintWriter printWriter = null;
		FileWriter fileOutStrm = null;
		BufferedWriter bufWriter = null;
		Connection myConnection;
		Statement myStatement1 = null;
		PreparedStatement pstmt, pstmt2 = null;
		String strSelectStat1 = null, strUpdLblInterface = null;
		ResultSet Rs1 = null;
		String strSelectStat2 = null;
		String strFeedbackwhere = null, strLastDateTime = null, strStartDateTime = null;
		int intInserted = 0, intReccount = 0;
		String strApplicationenv = null, strTestuserid = null;
		String strWoFeedbackURL = null, strWoacknowlegewhere = null;
		String strWRCManagersEmail = null, strPlantOpsManagersEmail = null;
		Date dtLastDateTime = null, dtformatted_dateack = null, dtformatted_datenoitf = null;
		String strWOVisibilityURL = null;
		String strSelectStat1_2 = "", strSelectStat1_3 = "", strSelectStat4 = "", strSelectStat5 = "";
		String strProgram_startdatetime = "";

		// Output log file
		/*
		 * try { fileOutStrm=new FileWriter("lbl_wo_ack_notify.log", true);
		 * bufWriter =new BufferedWriter(fileOutStrm); printWriter=new
		 * PrintWriter(bufWriter); } catch (Exception ex) {
		 * System.out.println("IO Exception: " + ex); System.exit(1); }
		 */

		Date now = new Date();
		// printWriter.println("Program started at :" + now);
		System.out.println("Program started at :" + now);

		try {
			// Acquire db connect object
			// Use MaxConnection class for Unix
			myConnection = MaxConnection.getDBConnection();

			// Use MaxConnection2 class for testing on windows
			// myConnection = MaxConnection2.getDBConnection();

			myConnection.setAutoCommit(false);
		} finally {
		}

		// Firstly get the contents of the where conditions and the
		// last date/time when the program was executed
		strSelectStat1 = " select varname, varvalue,  to_char(sysdate,'MM/DD/YYYY HH24:MI:SS') as program_startdatetime ";
		strSelectStat1 += " from lbl_maxvars ";
		strSelectStat1 += " where  varname in ('WO_FEEDBACK_WHERE',";
		strSelectStat1 += " 'WO_ACKNOTIFY_LASTDATE','APPLICATION_ENV', ";
		strSelectStat1 += " 'TEST_USER_ID', 'WO_FEEDBACK_URL', 'WO_ACKNOWLEDGE_WHERE', ";
		strSelectStat1 += " 'WO_ACKNOTIFY_STARTDATE','WRC_MANAGERS_EMAIL','PLANTOPS_MANAGERS_EMAIL',";
		strSelectStat1 += " 'WO_VISIBILITY' )";
		strSelectStat1 += "  and orgid=" + "'" + strOrgid + "'";
		strSelectStat1 += "  and siteid=" + "'" + strSiteid + "'";
		myStatement1 = myConnection.createStatement();
		Rs1 = myStatement1.executeQuery(strSelectStat1);

		intReccount = 0;
		// Browse through the record set
		while (Rs1.next()) {
			intReccount++;
			if (intReccount == 1)
				strProgram_startdatetime = Rs1
						.getString("program_startdatetime");

			if (Rs1.getString("varname").equals("WO_ACKNOTIFY_STARTDATE"))
				strStartDateTime = Rs1.getString("varvalue");

			if (Rs1.getString("varname").equals("WO_ACKNOTIFY_LASTDATE"))
				strLastDateTime = Rs1.getString("varvalue");

			if (Rs1.getString("varname").equals("WO_FEEDBACK_WHERE"))
				strFeedbackwhere = Rs1.getString("varvalue");

			if (Rs1.getString("varname").equals("APPLICATION_ENV"))
				strApplicationenv = Rs1.getString("varvalue");

			if (Rs1.getString("varname").equals("TEST_USER_ID"))
				strTestuserid = Rs1.getString("varvalue");

			if (Rs1.getString("varname").equals("WO_FEEDBACK_URL"))
				strWoFeedbackURL = Rs1.getString("varvalue");

			if (Rs1.getString("varname").equals("WO_VISIBILITY"))
				strWOVisibilityURL = Rs1.getString("varvalue");

			if (Rs1.getString("varname").equals("WO_ACKNOWLEDGE_WHERE"))
				strWoacknowlegewhere = Rs1.getString("varvalue");

			if (Rs1.getString("varname").equals("WRC_MANAGERS_EMAIL"))
				strWRCManagersEmail = Rs1.getString("varvalue");

			if (Rs1.getString("varname").equals("PLANTOPS_MANAGERS_EMAIL"))
				strPlantOpsManagersEmail = Rs1.getString("varvalue");

		} // while(Rs1.next())
		if (Rs1 != null)
			Rs1.close();

		if (intReccount != 10) {
			// printWriter.println("Key rows missing in lbl_maxvars table. Contact support");
			System.out
					.println("Key rows missing in lbl_maxvars table. Contact support");
			if (myConnection != null)
				myConnection.close();
			System.exit(1);
		}
		// System.out.println(strProgram_startdatetime);
		// ******************************************************
		// ************PHASE -1**********************************
		// Start sending the acknowledgements to the requesters
		// ******************************************************
		strSelectStat1 = "  select workorder.wonum, ";
		strSelectStat1 += " workorder.orgid, workorder.siteid, ";
		strSelectStat1 += " workorder.status, ";
		strSelectStat1 += " to_char(workorder.statusdate,'DD-Mon-YYYY HH24:MI:SS') statusdatetime, ";
		strSelectStat1 += " nvl(b.status,'NULL') status_copied";
		strSelectStat1 += " from maximo.workorder workorder, batch_maximo.LBL_WOACKNOTIFY b ";
		strSelectStat1 += " where workorder.orgid=b.orgid(+) and workorder.siteid=b.siteid(+) and workorder.wonum=b.wonum(+) ";
		strSelectStat1 += " and workorder.reportdate >= to_date('"
				+ strLastDateTime + "', 'MM/DD/YYYY HH24:MI:SS') ";
		// Added by Pankaj - prevent sending multiple acknowlegements
		strSelectStat1 += " and b.dateacknowledged is null ";
		strSelectStat1 += " and workorder.orgid=" + "'" + strOrgid + "'";
		strSelectStat1 += " and workorder.siteid=" + "'" + strSiteid + "'";
		strSelectStat1 += strWoacknowlegewhere;
		strSelectStat1 += " order by workorder.statusdate, workorder.wonum ";

		// System.out.println(strSelectStat1);
		// printWriter.println("Phase-1 Ack started at :" + now);
		System.out.println("Phase-1 Ack started at :" + now);

		Rs1 = myStatement1.executeQuery(strSelectStat1);

		// Browse through the record set.
		while (Rs1.next()) {
			// Process the record only if they are not already
			// inserted into LBL_WOACKNOTIFY table OR
			// The work order is recently canceled and its status is not
			// reflected in LBL_WOACKNOTIFY table.

			if ((Rs1.getString("status_copied").equals("NULL"))
					|| ((Rs1.getString("status").equals("CAN")) && (!Rs1
							.getString("status_copied").equals("CAN")))) {

				// Insert/update record in LBL_WOACKNOTIFY table
				writeDBTables(myConnection, Rs1.getString("orgid"),
						Rs1.getString("siteid"), Rs1.getString("wonum"),
						Rs1.getString("status"),
						Rs1.getString("statusdatetime"),
						strProgram_startdatetime, "ACKNOWLEDGE");
			} // if ( (Rs1.getString("status_copied").equals("NULL")) ||
				// ((Rs1.getString("status").equals("CAN")) &&
				// (! Rs1.getString("status_copied").equals("CAN"))))
		} // while(Rs1.next())
		if (Rs1 != null)
			Rs1.close();
		if (myStatement1 != null)
			myStatement1.close();

		// ----------------PHASE -2----------------------
		// Now start sending the feedback NOTIFYs after the
		// work orders are completed.
		//

		/*********
		 * Phase 2 and phase 3 has been discontinued until further notice
		 * 
		 * strSelectStat1 ="  select workorder.wonum,  "; strSelectStat1
		 * +=" workorder.orgid, workorder.siteid, "; strSelectStat1
		 * +=" workorder.status,  "; strSelectStat1
		 * +=" to_char(workorder.statusdate,'Month, DD, YYYY') statusdate, ";
		 * strSelectStat1 +=
		 * " to_char(workorder.statusdate,'DD-Mon-YYYY HH24:MI:SS') statusdatetime "
		 * ; strSelectStat1 +=
		 * " from maximo.workorder workorder, batch_maximo.LBL_WOACKNOTIFY b  ";
		 * strSelectStat1 +=
		 * " where workorder.orgid=b.orgid and workorder.siteid=b.siteid and workorder.wonum=b.wonum "
		 * ; strSelectStat1
		 * +=" and b.DATEACKNOWLEDGED is not null and b.datenotified is null ";
		 * strSelectStat1 +=" and workorder.changedate >= (to_date('"+
		 * strLastDateTime + "', 'MM/DD/YYYY HH24:MI:SS') -1) "; strSelectStat1
		 * +=" and workorder.orgid=" + "'" + strOrgid +"'" ; strSelectStat1
		 * +=" and workorder.siteid=" + "'" + strSiteid +"'"; strSelectStat1 +=
		 * strFeedbackwhere ;
		 * 
		 * //System.out.println(strSelectStat1);
		 * 
		 * // printWriter.println("Phase-2 Notification started at :" + now);
		 * System.out.println("Phase-2 Notification started at :" + now);
		 * myStatement1 = myConnection.createStatement();
		 * Rs1=myStatement1.executeQuery(strSelectStat1);
		 * 
		 * // Browse through the record set. while(Rs1.next()) { //
		 * Insert/update record in LBL_WOACKNOTIFY table
		 * 
		 * writeDBTables(myConnection, Rs1.getString("orgid"),
		 * Rs1.getString("siteid"), Rs1.getString("wonum"),
		 * Rs1.getString("status"), Rs1.getString("statusdatetime"), "NOTIFY");
		 * 
		 * } // while(Rs1.next()) if (Rs1 != null) Rs1.close(); if (myStatement1
		 * != null) myStatement1.close();
		 * 
		 * //-------------------------------------------------------
		 * //-------------------PHASE -3----------------------------- // Now
		 * start sending the ALERTS to the supervisors // if indicated by the
		 * requester/customer in the feedback
		 * //------------------------------------------------------
		 * 
		 * strSelectStat1 =" select workorder.wonum, workorder.description, ";
		 * strSelectStat1
		 * +=" b.customerid, b.comments, b.rowid, b.orgid, b.siteid,";
		 * strSelectStat1
		 * +=" b.contact_name, b.contact_details, b.wofeedbackid, ";
		 * strSelectStat1 +=
		 * " maximo.lbl_maximo_pkg.GET_EMPLOYEE_NAME(b.CUSTOMERID) customer_name, "
		 * ; strSelectStat1 +=
		 * " maximo.lbl_maximo_pkg.GET_EMPLOYEE_NAME(workorder.supervisor) supervisor_name, "
		 * ; strSelectStat1 +=" email.emailaddress supervisor_email ";
		 * strSelectStat1 +=
		 * " from maximo.workorder workorder, batch_maximo.lbl_wofeedbackcomments b, maximo.email email "
		 * ; strSelectStat1 +=
		 * " where workorder.orgid=b.orgid and workorder.siteid=b.siteid and workorder.wonum=b.wonum "
		 * ; strSelectStat1
		 * +=" and email.personid=workorder.supervisor and email.type='WORK' ";
		 * strSelectStat1
		 * +=" and b.RESPTOCOMMENTS ='1' and b.ALERTEMAILSENT is null   ";
		 * strSelectStat1 +=" and workorder.orgid=" + "'" + strOrgid +"'" ;
		 * strSelectStat1 +=" and workorder.siteid=" + "'" + strSiteid +"'";
		 * strSelectStat1 +=" order by workorder.wonum, b.wofeedbackid";
		 * 
		 * //System.out.println(strSelectStat1); //
		 * printWriter.println("Phase-3 Alerts started at :" + now);
		 * 
		 * System.out.println("Phase-3 Alerts started at :" + now); myStatement1
		 * = myConnection.createStatement();
		 * Rs1=myStatement1.executeQuery(strSelectStat1);
		 * 
		 * // Browse through the record set. while(Rs1.next()) {
		 * updateFeedbackAlert(myConnection, Rs1.getString("orgid"),
		 * Rs1.getString("siteid"), Rs1.getString("wonum"),
		 * Rs1.getString("customerid"), Rs1.getString("rowid"),
		 * Rs1.getString("wofeedbackid"));
		 * 
		 * System.out.println(
		 * "*** About to prepare alert e-mail for work order: " +
		 * Rs1.getString("wonum") + " customer: " +Rs1.getString("customerid"));
		 * sendFeedbackAlertEmail(myConnection, strOrgid, strSiteid,
		 * Rs1.getString("wonum"), Rs1.getString("description"),
		 * Rs1.getString("customerid"), Rs1.getString("comments"),
		 * Rs1.getString("customer_name"), Rs1.getString("supervisor_name"),
		 * Rs1.getString("supervisor_email"), Rs1.getString("contact_name"),
		 * Rs1.getString("contact_details"), strApplicationenv, strTestuserid,
		 * strWRCManagersEmail, strPlantOpsManagersEmail,
		 * Rs1.getString("wofeedbackid")); } if (Rs1 != null) Rs1.close(); if
		 * (myStatement1 != null) myStatement1.close();
		 **************/

		// **************** PHASE 4 *************************************
		// Now start sending the e-mails (Acknowledgement, notification)
		// **************************************************************
		strSelectStat1 = "  select workorder.wonum, workorder.description, ";
		strSelectStat1 += " workorder.orgid, workorder.siteid, ";
		strSelectStat1 += " nvl(workorder.supervisor,' ') supervisor, workorder.reportedby, ";
		strSelectStat1 += " workorder.wo1, workorder.status , workorder.location, ";
		strSelectStat1 += " nvl(workorder.glaccount,' ') glaccount, to_char(workorder.statusdate,'Month DD, YYYY') statusdate, ";
		strSelectStat1 += " to_char(workorder.statusdate,'DD-Mon-YYYY HH24:MI:SS') statusdatetime, ";
		strSelectStat1 += " nvl(to_char(workorder.reportdate,'Month DD, YYYY'),' ') reportdate,";
		strSelectStat1 += " nvl(to_char(workorder.TARGSTARTDATE, 'Month DD, YYYY'),' ') TARGSTARTDATE,";
		strSelectStat1 += " nvl(to_char(workorder.TARGCOMPDATE, 'Month DD, YYYY'),' ') TARGCOMPDATE,";
		strSelectStat1 += " workorder.leadcraft, ";

		// Added by Pankaj on 2/1/13 WOR-2
		strSelectStat1 += " workorder.lead, ";
		strSelectStat1 += " nvl(maximo.lbl_maximo_pkg.GET_EMPLOYEE_NAME(workorder.lead),' ') lead_name, ";

		strSelectStat1 += " nvl(maximo.lbl_maximo_pkg.GET_EMPLOYEE_NAME(workorder.leadcraft),' ') leadcraftname, ";
		strSelectStat1 += " nvl(maximo.lbl_maximo_pkg.GET_EMPLOYEE_NAME(workorder.supervisor),' ') supervisor_name, ";
		strSelectStat1 += " nvl(maximo.lbl_maximo_pkg.GET_EMPLOYEE_NAME(workorder.lbl_fammanager),' ') fam_name, "; // Added JIRA EF-8495
		strSelectStat1 += " maximo.lbl_maximo_pkg.GET_EMPLOYEE_NAME(workorder.reportedby) reportedby_name, ";
		strSelectStat1 += " maximo.lbl_maximo_pkg.GET_EMPLOYEE_NAME(workorder.wo1) wo1_name, ";
		// strSelectStat1
		// +=" nvl(maximo.LBL_GET_LDTEXT(workorder.workorderid,'WORKORDER'),'NULL') ldtext, ";
		// JIRA EF-6741 Replaced the function LBL_GET_LDTEXT with
		// lbl_maximo_pkg.GET_LONGDESCRIPTION
		strSelectStat1 += " nvl(lbl_maximo_pkg.GET_LONGDESCRIPTION(workorder.workorderid, 'WORKORDER','DESCRIPTION'),'NULL') ldtext, ";
		// strSelectStat1 +=" decode(greatest(nvl(b.DATEACKNOWLEDGED, " +
		// "to_date('"+ strLastDateTime + "', 'MM/DD/YYYY HH24:MI:SS')), ";
		// strSelectStat1 += "to_date('"+ strLastDateTime +
		// "', 'MM/DD/YYYY HH24:MI:SS')), b.DATEACKNOWLEDGED,'YES','NO') ack, ";
		// strSelectStat1 +=" decode(greatest(nvl(b.DATENOTIFIED, " +
		// "to_date('"+ strLastDateTime + "', 'MM/DD/YYYY HH24:MI:SS')), ";
		// strSelectStat1 +=" to_date('"+ strLastDateTime +
		// "', 'MM/DD/YYYY HH24:MI:SS')), b.DATENOTIFIED,'YES','NO') notify, ";

		// Find out whether the ack/notify was sent based on the PL/SQL function
		strSelectStat1_2 = " to_char(b.dateacknowledged,'MM/DD/YYYY HH24:MI:SS') formatted_dateack, ";
		strSelectStat1_2 += " to_char(b.datenotified,'MM/DD/YYYY HH24:MI:SS')     formatted_datenotif, ";
		strSelectStat1_2 += " maximo.lbl_maximo_pkg.ack_notify_sent(b.DATEACKNOWLEDGED) ack, ";
		strSelectStat1_2 += " maximo.lbl_maximo_pkg.ack_notify_sent(b.DATENOTIFIED) notify ";
		strSelectStat1_2 += " from maximo.workorder workorder, batch_maximo.LBL_WOACKNOTIFY b  ";
		strSelectStat1_2 += " where workorder.orgid=b.orgid and workorder.siteid=b.siteid and workorder.wonum=b.wonum ";
		// strSelectStat1_2
		// +=" and workorder.wo1 is not null and workorder.reportedby is not null and workorder.supervisor is not null "
		// ;
		strSelectStat1_2 += " and workorder.wo1 is not null and workorder.reportedby is not null  ";

		strSelectStat1_2 += " and ( b.DATEACKNOWLEDGED =" + " to_date('"
				+ strProgram_startdatetime + "', 'MM/DD/YYYY HH24:MI:SS')) ";

		// JIRA EF-3895 strSelectStat1_2 +=" or    b.DATENOTIFIED     >" +
		// " to_date('"+ strLastDateTime + "', 'MM/DD/YYYY HH24:MI:SS')) ";
		// The condition is not required for Lana's request to send the
		// notification even if the ack is not sent
		// strSelectStat1 +=" and b.DATEACKNOWLEDGED is not null  ";
		strSelectStat1_2 += " and workorder.orgid=" + "'" + strOrgid + "'";
		strSelectStat1_2 += " and workorder.siteid=" + "'" + strSiteid + "'";

		strSelectStat1_3 = " ";
		/*
		 * Commented JIRA EF-3895 strSelectStat1_3 = " union "; strSelectStat1_3
		 * += strSelectStat1 + "  null, null, 'No' , 'YES' "; strSelectStat1_3
		 * +=" from maximo.workorder workorder "; strSelectStat1_3 +=
		 * " where workorder.wo1 is not null and workorder.reportedby is not null and workorder.supervisor is not null "
		 * ; strSelectStat1_3 +=" and orgid='" + strOrgid +"' and siteid='" +
		 * strSiteid +"'"; strSelectStat1_3 +=" and workorder.wonum in ";
		 * strSelectStat1_3 +=
		 * " (select b.recordkey from worklog b where B.CLASS='WORKORDER'  AND   B.LOGTYPE='WOFEEDBACK'  AND   "
		 * ; strSelectStat1_3 +=
		 * " B.LBL_WOFEEDREQDT >= (SELECT TO_DATE(D.VARVALUE,'MM/DD/YYYY HH24:MI:SS') -1 "
		 * ; strSelectStat1_3 +=
		 * " FROM  LBL_MAXVARS D WHERE D.VARNAME='WO_ACKNOTIFY_LASTDATE' AND b.ORGID=workorder.ORGID  "
		 * ; strSelectStat1_3 +=
		 * " AND  b.SITEID=workorder.SITEID)  AND  B.LBL_WOFEEDREQDT <= SYSDATE AND B.lbl_wofeedsentdt is null ) "
		 * ;
		 */
		strSelectStat4 += " order by 1 ";

		strSelectStat5 = strSelectStat1 + strSelectStat1_2 + strSelectStat1_3
				+ strSelectStat4;
		// System.out.println(strSelectStat5);
		// printWriter.println("Phase-4 Sending emails started at :" + now);
		System.out.println("Phase-4 Sending emails started at :" + now);

		myStatement1 = myConnection.createStatement();
		Rs1 = myStatement1.executeQuery(strSelectStat5);
		SimpleDateFormat df = new SimpleDateFormat("MM/dd/yyyy HH:mm:ss");

		// Browse through the record set.
		while (Rs1.next()) {
			dtLastDateTime = df.parse(strLastDateTime);

			// Send acknowledgement
			/*
			 * if (Rs1.getString("formatted_dateack") != null) {
			 * dtformatted_dateack=df.parse(Rs1.getString("formatted_dateack"));
			 * if (dtformatted_dateack.after(dtLastDateTime))
			 */

			// Send acknowledgement
			if (Rs1.getString("ack") != null
					&& Rs1.getString("ack").equals("YES")) {
				System.out.println("***Preparing Ack e-mail(customer) for "
						+ Rs1.getString("wonum") + "-" + Rs1.getString("wo1"));
				sendEmail(
						myConnection,
						Rs1.getString("wonum"),
						("CUSTOMER"),
						Rs1.getString("wo1"), // customer id
						Rs1.getString("wo1_name"), // customer name
						Rs1.getString("reportedby"),
						Rs1.getString("reportedby_name"),
						Rs1.getString("lead"), // WOR-2
						Rs1.getString("lead_name"), // WOR-2
						Rs1.getString("supervisor"),
						Rs1.getString("supervisor_name"),
						Rs1.getString("fam_name"),  // JIRA EF-8495			
						Rs1.getString("status"), Rs1.getString("location"),
						Rs1.getString("glaccount"),
						Rs1.getString("statusdate"),
						Rs1.getString("description"), Rs1.getString("ldtext"),
						strApplicationenv, strTestuserid, strWoFeedbackURL,
						"ACKNOWLEDGE", Rs1.getString("reportdate"),
						Rs1.getString("TARGSTARTDATE"),
						Rs1.getString("TARGCOMPDATE"),
						Rs1.getString("leadcraft"),
						Rs1.getString("leadcraftname"), strOrgid, // Added by
																	// Pankaj
																	// 8/17/10
						strSiteid, strWOVisibilityURL);

				if (!Rs1.getString("wo1").equals(Rs1.getString("reportedby"))) {
					System.out
							.println("***Preparing Ack e-mail(reportedby) for "
									+ Rs1.getString("wonum") + "-"
									+ Rs1.getString("reportedby"));
					sendEmail(
							myConnection,
							Rs1.getString("wonum"),
							("REPORTEDBY"),
							Rs1.getString("wo1"), // customer id
							Rs1.getString("wo1_name"), // customer name
							Rs1.getString("reportedby"),
							Rs1.getString("reportedby_name"),
							Rs1.getString("lead"), // WOR-2
							Rs1.getString("lead_name"), // WOR-2
							Rs1.getString("supervisor"),
							Rs1.getString("supervisor_name"),
							Rs1.getString("fam_name"),  // JIRA EF-8495								
							Rs1.getString("status"), Rs1.getString("location"),
							Rs1.getString("glaccount"),
							Rs1.getString("statusdate"),
							Rs1.getString("description"),
							Rs1.getString("ldtext"), strApplicationenv,
							strTestuserid, strWoFeedbackURL, "ACKNOWLEDGE",
							Rs1.getString("reportdate"),
							Rs1.getString("TARGSTARTDATE"),
							Rs1.getString("TARGCOMPDATE"),
							Rs1.getString("leadcraft"),
							Rs1.getString("leadcraftname"), strOrgid, // Added
																		// by
																		// Pankaj
																		// 8/17/10
							strSiteid, strWOVisibilityURL);
				} // if (!
					// Rs1.getString("wo1").equals(Rs1.getString("reportedby")))
			} // if (Rs1.getString("ack").equals("YES"))
		} // while(Rs1.next())

		/*
		 * if (Rs1.getString("formatted_datenotif") != null) {
		 * dtformatted_datenoitf=df.parse(Rs1.getString("formatted_datenotif"));
		 * if (dtformatted_datenoitf.after(dtLastDateTime))
		 */

		/**************************
		 * Commented as per JIRA EF-3895 // Send Notifications
		 * 
		 * if (Rs1.getString("notify") != null &&
		 * Rs1.getString("notify").equals("YES")) { // New send feedback NOTIFY
		 * email
		 * 
		 * 
		 * System.out.println("***Preparing Notify(customer) e-mail for " +
		 * Rs1.getString("wonum") + "-" + Rs1.getString("wo1"));
		 * sendEmail(myConnection, Rs1.getString("wonum"), ("CUSTOMER"),
		 * Rs1.getString("wo1"), Rs1.getString("wo1_name"),
		 * Rs1.getString("reportedby"), Rs1.getString("reportedby_name"),
		 * Rs1.getString("lead"), // WOR-2 Rs1.getString("lead_name"), // WOR-2
		 * Rs1.getString("supervisor"), Rs1.getString("supervisor_name"),
		 * Rs1.getString("status"), Rs1.getString("location"),
		 * Rs1.getString("glaccount"), Rs1.getString("statusdate"),
		 * Rs1.getString("description"), Rs1.getString("ldtext"),
		 * strApplicationenv, strTestuserid, strWoFeedbackURL, "NOTIFY",
		 * Rs1.getString("reportdate"), Rs1.getString("schedstart"),
		 * Rs1.getString("schedfinish"), Rs1.getString("leadcraft"),
		 * Rs1.getString("leadcraftname"), strOrgid, // Added by Pankaj 8/17/10
		 * strSiteid, strWOVisibilityURL);
		 * 
		 * 
		 * // Changed by Pankaj on 4/20/11 as RT# 93720 // Do not send
		 * notification to reportedby
		 * 
		 * 
		 * if (! Rs1.getString("wo1").equals(Rs1.getString("reportedby"))) {
		 * System.out.println("***Preparing Notify(reporedby) e-mail for " +
		 * Rs1.getString("wonum") + "-" + Rs1.getString("reportedby"));
		 * sendEmail(myConnection, Rs1.getString("wonum"), ("REPORTEDBY"),
		 * Rs1.getString("wo1"), Rs1.getString("wo1_name"),
		 * Rs1.getString("reportedby"), Rs1.getString("reportedby_name"),
		 * Rs1.getString("supervisor"), Rs1.getString("supervisor_name"),
		 * Rs1.getString("status"), Rs1.getString("location"),
		 * Rs1.getString("glaccount"), Rs1.getString("statusdate"),
		 * Rs1.getString("description"), Rs1.getString("ldtext"),
		 * strApplicationenv, strTestuserid, strWoFeedbackURL, "NOTIFY",
		 * Rs1.getString("reportdate"), Rs1.getString("schedstart"),
		 * Rs1.getString("schedfinish"), Rs1.getString("leadcraft"),
		 * Rs1.getString("leadcraftname"), strOrgid, // Added by Pankaj 8/17/10
		 * strSiteid, strWOVisibilityURL); } // if (!
		 * Rs1.getString("wo1").equals(Rs1.getString("reportedby"))) Till here
		 * Pankaj 4/20/11
		 **********/

		if (Rs1 != null)
			Rs1.close();
		if (myStatement1 != null)
			myStatement1.close();

		// Now update work log table with feedback sent date
		updtWorklog(myConnection, strOrgid, strSiteid);

		System.out.println("Phase-5 About to update lbl_maxvars");
		// Now update the row in lbl_maxvars table
		// with the last executed date/time.
		updLBLMaxvars(myConnection, strOrgid, strSiteid,
				"WO_ACKNOTIFY_LASTDATE", strProgram_startdatetime);

		now = new Date();
		// printWriter.println("Program ended at :" + now);
		System.out.println("Program ended at :" + now);
		if (myStatement1 != null)
			myStatement1.close();

		myConnection.commit();
		if (myConnection != null)
			myConnection.close();
		// printWriter.close();

	} // main

	/****************************************************
	 * Method to update the table lbl_wofeedbackcomments
	 * 
	 * @throws SQLException
	 ****************************************************/
	private static void updateFeedbackAlert(Connection myConnection,
			String strOrgid, String strSiteid, String strWonum,
			String strCustomerid, String strRowid, String strWOFeedbackid)
			throws SQLException {
		String strUpdate = null;
		PreparedStatement pstmt = null;

		strUpdate = " update batch_maximo.lbl_wofeedbackcomments ";
		strUpdate += "  set ALERTEMAILSENT=sysdate ";
		strUpdate += " where orgid=? and siteid=? ";
		strUpdate += " and wonum=? and customerid=? and  rowid=? and wofeedbackid=?";

		pstmt = myConnection.prepareStatement(strUpdate);
		pstmt.setString(1, strOrgid);
		pstmt.setString(2, strSiteid);
		pstmt.setString(3, strWonum);
		pstmt.setString(4, strCustomerid);
		pstmt.setString(5, strRowid);
		pstmt.setString(6, strWOFeedbackid);

		pstmt.executeUpdate();
		if (pstmt != null)
			pstmt.close();

	}

	/******************************************************************
	 * Method to send the email to supervisor, if desired by the customer
	 * 
	 * @throws SQLException
	 **********************************************************************/
	private static void sendFeedbackAlertEmail(Connection myConnection,
			String strOrgid, String strSiteid, String strWonum,
			String strDescription, String strCustomerid, String strComments,
			String strCustomername, String strSupervisorname,
			String strSupervisoremail, String strContactname,
			String strContactdetails, String strApplicationenv,
			String strTestuserid, String strWRCManagersEmail,
			String strPlantOpsManagersEmail, String strWOFeedbackid)
			throws Exception {

		String strSubjectline = "";
		String strBody = "", strFooter = "";
		String strSelect = null;
		int intRecCount = 0;
		String strCopyTo = strWRCManagersEmail + ',' + strPlantOpsManagersEmail;
		String strSupervisorid = null;

		// In case of non-production environment, subject line prefixed by TEST
		// and email body ends with non-production data disclaimer

		if (!strApplicationenv.equalsIgnoreCase("PRODUCTION")) {
			strSubjectline = "[TEST] ";
			strFooter += "<BR><BR><B>[This email is generated from the TEST data and it does not represent the actual data.]</B>";

			// Get the email address of the supervisor
			strSupervisorid = strTestuserid;

			strSelect = " select emailaddress from maximo.email  ";
			strSelect += " where personid=? ";
			strSelect += " and type='WORK'";
			PreparedStatement pstmt = myConnection.prepareStatement(strSelect);
			pstmt.setString(1, strSupervisorid);

			ResultSet Rs = pstmt.executeQuery();
			while (Rs.next()) {
				strSupervisoremail = Rs.getString("emailaddress");
				strCopyTo = "";
			}
			if (Rs != null)
				Rs.close();
			if (pstmt != null)
				pstmt.close();

		} // if (! strApplicationenv.equals("PRODUCTION"))

		strSubjectline += "Contact the customer for the work order " + strWonum
				+ " feedback";
		strBody = "<html><head><title>Work order feedback comments from the customer</title></head>";
		strBody += "<BODY><TABLE><TR><TD>";
		strBody += "Dear " + strSupervisorname + ",</TD></TR>";
		strBody += "<TR><TD>&nbsp;</TD></TR>";
		strBody += "<TR><TD> The feedback in connection with the work order# "
				+ strWonum;
		strBody += " provided by " + strCustomername
				+ ", indicates that you should contact him/her.</TD></TR>";
		strBody += "<TR><TD>&nbsp;</TD></TR>";
		strBody += "<TR><TD> Given below are the details of the work order: </TD></TR>";
		strBody += "<TR><TD>&nbsp;</TD></TR>";
		strBody += "<TR><TD>";
		strBody += "<TABLE border=2 align=left>";
		strBody += "<TR><TD><B>Work order#</B></TD>" + "<TD><B>" + strWonum
				+ "</B></TD></TR>";
		strBody += "<TR><TD><B>Description</B></TD>" + "<TD><B>"
				+ strDescription + "</B></TD></TR>";
		strBody += "<TR><TD><B>Feedback comments</B></TD>" + "<TD><B>"
				+ strComments + "<B></TD></TR>";

		// Get the Work order feedback details

		strSelect = " select b.text, a.value, b.minimum_value, b.maximum_value ";
		strSelect += " from batch_maximo.lbl_wofeedback a, batch_maximo.lbl_feedback b ";
		strSelect += " where a.orgid=b.orgid and a.siteid=b.siteid ";
		strSelect += " and   a.id=b.id and b.feed_type='WRC' and b.disabled='N' ";
		strSelect += " and   a.wonum=? and a.customerid=? ";
		strSelect += " and   a.orgid=" + "'" + strOrgid + "'";
		strSelect += " and   a.siteid=" + "'" + strSiteid + "'";
		strSelect += " and   a.wofeedbackid=?";
		strSelect += " order by b.sort_seq ";

		PreparedStatement pstmt = myConnection.prepareStatement(strSelect);
		pstmt.setString(1, strWonum);
		pstmt.setString(2, strCustomerid);
		pstmt.setString(3, strWOFeedbackid);

		ResultSet Rs = pstmt.executeQuery();

		intRecCount = 0;
		while (Rs.next()) {
			intRecCount++;
			if (intRecCount == 1) {
				strBody += "<TR><TD><B>Feedback Details</B></TD>";
				strBody += "<TD><TABLE border=1>";
				strBody += "<TR><TH><B>Criteria</B></TH><TH><B>0-Unknown/1-Strongly disagree/5-Strongly agree</B></TH></TR>";
			} // if (intRecCount==1)
			strBody += "<TR><TD><B>" + Rs.getString("text") + "</B></TD>";
			strBody += "<TD><B>" + Rs.getString("value") + "</B></TD></TR>";

		} // while(Rs.next())

		if (intRecCount > 0)
			strBody += " </TABLE></TD></TR>";

		if (Rs != null)
			Rs.close();
		if (pstmt != null)
			pstmt.close();

		strBody += "<TR><TD><B>Contact Name</B></TD>" + "<TD><B>"
				+ strContactname + "<B></TD></TR>";
		strBody += "<TR><TD><B>Contact Details</B></TD>" + "<TD><B>"
				+ strContactdetails + "<B></TD></TR>";
		strBody += "</TABLE>";
		strBody += "</TD></TR><TR><TD><p>&nbsp;</TD></TR><TR><TD>";

		strBody += "Thank you.";
		strBody += "</TD></TR></TABLE>";
		strBody += "<P><P>" + strFooter + "</BODY>";

		// Now send e-mail (alert)
		System.out.println("*** About the send alert e-mail to "
				+ strSupervisoremail + " for work order#: " + strWonum);
		if (strSupervisoremail != null && strSupervisoremail.length() > 0)
			MailUtil.SendMail("smtp.lbl.gov",
			// "WRC@lbl.gov",
					"fam@lbl.gov", // JIRA EF-8422
					strSupervisoremail, strCopyTo, // CC
					strSubjectline, "HTML", strBody);
	}

	/* Method to insert/update the rows in LBL_WOACKNOTIFY table */
	private static void writeDBTables(Connection myConnection, String strOrgid,
			String strSiteid, String strWonum, String strStatus,
			String strStatusdate, String strDateTime, String strType)
			throws SQLException {

		int intReccnt = 0;
		String strSelect = null, strDML = null;
		PreparedStatement pstmt = null;
		ResultSet Rs = null;

		String strStatusdateFormatted = "to_date('" + strStatusdate
				+ "','DD-Mon-YYYY HH24:MI:SS')";
		String strDateTimeFormatted = "to_date('" + strDateTime
				+ "','MM/DD/YYYY HH24:MI:SS')";

		strSelect = " select count(*) ";
		strSelect += " from batch_maximo.LBL_WOACKNOTIFY";
		strSelect += " where orgid=? and siteid=? and wonum=? ";
		pstmt = myConnection.prepareStatement(strSelect);

		pstmt.setString(1, strOrgid);
		pstmt.setString(2, strSiteid);
		pstmt.setString(3, strWonum);

		Rs = pstmt.executeQuery();

		// Browse through the record set
		while (Rs.next()) {
			intReccnt = Rs.getInt(1);
		}

		// System.out.println("Wonum: " + strWonum + " Count: " + intReccnt);

		if (Rs != null)
			Rs.close();
		if (pstmt != null)
			pstmt.close();

		// In case of notify, update this table only when
		// the work order is completed. This way, the notification
		// will be sent after completion of the work order without
		// requiring any date to be scheduled
		// Pankaj 09/18/10

		String strDML2 = "";

		if (intReccnt > 0) {
			strDML = " update batch_maximo.LBL_WOACKNOTIFY ";
			strDML += " set status=?, statusdate=" + strStatusdateFormatted;

			if (strType.equals("ACKNOWLEDGE"))
				strDML2 = " , dateacknowledged=" + strDateTimeFormatted;

			if (strType.equals("NOTIFY")
					&& (strStatus.equals("COMP") || strStatus.equals("WCLOSE") || strStatus
							.equals("CLOSE")))
				strDML2 = ", DATENOTIFIED=sysdate ";

			if (strDML2 != null && strDML2.length() > 0) {
				strDML += strDML2;
				strDML += " where orgid=? and siteid=? and wonum=? ";

				// System.out.println("in update:" + strDML);

				pstmt = myConnection.prepareStatement(strDML);
				pstmt.setString(1, strStatus);
				pstmt.setString(2, strOrgid);
				pstmt.setString(3, strSiteid);
				pstmt.setString(4, strWonum);
				pstmt.executeUpdate();
			} // if (strDML2 != null && strDML2.length() >0)
		} // if (intReccnt >0)
		else {
			strDML2 = "";
			// Now insert the record in batch_maximo.lbl_wocomments
			strDML = " insert into batch_maximo.LBL_WOACKNOTIFY (";
			strDML += " orgid, siteid, wonum, status, ";
			strDML += " statusdate ";

			if (strType.equals("ACKNOWLEDGE"))
				strDML2 = ", dateacknowledged ";

			// For notify insert into this table only if status is completed
			if (strType.equals("NOTIFY")
					&& (strStatus.equals("COMP") || strStatus.equals("WCLOSE") || strStatus
							.equals("CLOSE")))

				strDML2 = ", DATENOTIFIED  ";

			if (strDML2 != null && strDML2.length() > 0) {
				strDML += strDML2;
				strDML += ") values  ";
				strDML += "(?, ?, ?, ?, ";
				strDML += strStatusdateFormatted + "," + strDateTimeFormatted
						+ ") ";

				pstmt = myConnection.prepareStatement(strDML);
				pstmt.setString(1, strOrgid);
				pstmt.setString(2, strSiteid);
				pstmt.setString(3, strWonum);
				pstmt.setString(4, strStatus);
				pstmt.executeUpdate();
			} // if (strDML2 !=null && strDML2.length() >0)
			if (pstmt != null)
				pstmt.close();
			// System.out.println(strDML);
		}
	} // end of method

	// Method to update work log for work order feedback sent date
	private static void updtWorklog(Connection myConnection, String strOrgid,
			String strSiteid) throws SQLException {
		PreparedStatement pstmt2 = null;
		String strDML = "";

		// Added by Pankaj on 7/28/10
		// Update the rows in work log table whose feedback is now sent

		strDML = " update maximo.worklog ";
		strDML += " set  LBL_WOFEEDSENTDT=sysdate ";
		strDML += " where orgid='" + strOrgid + "' and siteid='" + strSiteid
				+ "'";
		strDML += " and   lbl_wofeedsentdt is null ";
		strDML += " and   worklogid in ";
		strDML += " (select b.worklogid ";
		strDML += " FROM  WORKORDER A, WORKLOG B ";
		strDML += " WHERE A.ORGID=B.orgid ";
		strDML += " AND   A.SITEID=B.SITEID ";
		strDML += " AND   A.WONUM=B.recordkey ";
		strDML += " AND   A.STATUS !='CAN' ";
		strDML += " AND   A.wo1 IS NOT NULL AND A.REPORTEDBY IS NOT NULL ";
		strDML += " AND   B.CLASS='WORKORDER' ";
		strDML += " AND   B.LOGTYPE='WOFEEDBACK' ";
		strDML += " AND   B.LBL_WOFEEDREQDT >= (SELECT TO_DATE(D.VARVALUE,'MM/DD/YYYY HH24:MI:SS') -1 FROM ";
		strDML += " LBL_MAXVARS D WHERE D.VARNAME='WO_ACKNOTIFY_LASTDATE' AND D.ORGID=A.ORGID ";
		strDML += " AND  D.SITEID=A.SITEID) ";
		strDML += " AND  B.LBL_WOFEEDREQDT <= SYSDATE AND B.lbl_wofeedsentdt is null) ";

		// System.out.println(strDML);
		pstmt2 = myConnection.prepareStatement(strDML);
		pstmt2.executeUpdate();
		if (pstmt2 != null)
			pstmt2.close();

	}

	/*****************************************************
	 * Method to compose the email and send the email to the customer
	 * 
	 * @throws Exception
	 *****************************************************/
	private static void sendEmail(Connection myConnection, String strWonum,
			String strTo, String strCustomerid, String strCustomername,
			String strReportedby, String strReportedbyname, String strLead,
			String strLeadname, String strSupervisor,
			String strSupervisor_name, String strFAMName, String strStatus, String strLocation,
			String strGlaccount, String strStatusdate, String strDescription,
			String strLdtext, String strApplicationenv, String strTestuserid,
			String strWoFeedbackURL, String strType, String strReportdate,
			String strSchedstart, String strSchedfinish, String strLeadcraft,
			String strLeadcraftname, String strOrgid, // Added by Pankaj on
														// 8/17/10
			String strSiteid, String strWOVisibilityURL) throws Exception {
		String strSubjectline = "";
		String strFooter = "";
		String strCustomeremail = "";
		String strBody = null;
		String strSupervisorphone = "";
		String strCustomerlinkid = "";
		String strLeadphone = "";

		strCustomerlinkid = strCustomerid; // used for hyperlink

		if (!strApplicationenv.equalsIgnoreCase("PRODUCTION")) {

			strCustomerid = strTestuserid;
			strReportedby = strTestuserid;

			strSubjectline = "[TEST] ";
			strFooter += "<TR><TD>&nbsp;</TD></TR><TR><TD><B>[This email is generated from the TEST data and it does not represent the actual data.]</TD></TR>";
		}

		if (strType.equals("ACKNOWLEDGE")) {
			strSubjectline += "Acknowledgment of Facilities Work Order "
					+ strWonum;
			if (strStatus.equals("CAN"))
				strSubjectline += " [CANCELED]";
		} else // notify
		{
			// strSubjectline +="Facilities Work Order " + strWonum +
			// " completed";
			strSubjectline += "Feedback requested on Facilities Work Order "
					+ strWonum;
		}

		// Get the email address of the customer or reportedby
		PreparedStatement pstmt;
		ResultSet Rs;

		String strSelect = " select emailaddress from maximo.email";
		strSelect += " where personid=?  and type='WORK' ";
		pstmt = myConnection.prepareStatement(strSelect);

		if (strTo.equals("CUSTOMER"))
			pstmt.setString(1, strCustomerid);

		if (strTo.equals("REPORTEDBY"))
			pstmt.setString(1, strReportedby);

		Rs = pstmt.executeQuery();
		while (Rs.next()) {
			strCustomeremail = Rs.getString("emailaddress");
		}
		if (Rs != null)
			Rs.close();

		strSelect = " select phonenum from maximo.phone";
		strSelect += " where personid=?  and type='WORK' and isprimary='1' ";
		pstmt = myConnection.prepareStatement(strSelect);

		// Now get supervisor contact details
		pstmt.setString(1, strSupervisor);
		Rs = pstmt.executeQuery();
		while (Rs.next()) {
			strSupervisorphone = Rs.getString("phonenum");
		}
		if (Rs != null)
			Rs.close();

		// Now get lead phone
		pstmt.setString(1, strLead);
		Rs = pstmt.executeQuery();
		while (Rs.next()) {
			strLeadphone = Rs.getString("phonenum");
		}
		if (Rs != null)
			Rs.close();
		if (pstmt != null)
			pstmt.close();

		if (strType.equals("ACKNOWLEDGE")) {
			strBody = "<html><head><title>Work order Acknowledgment</title></head>";
			strBody += "<BODY><TABLE><TR><TD>";

			if (strTo.equals("REPORTEDBY"))
				strBody += "Dear " + strReportedbyname + ",";
			else if (strTo.equals("CUSTOMER"))
				strBody += "Dear " + strCustomername + ",";

			if (strStatus.equals("CAN")) {
				strBody += "<BR><BR> This following work order has been canceled.";
			} else {
				strBody += "<BR><BR> Facilities has received your work request.";

			}

			strBody += "<BR><BR><TABLE BORDER=2 ALIGN=LEFT>";
			strBody += "<TR><TD><B>Work Order Number</B></TD><TD><B>"
					+ strWonum + "</B></TD></TR>";
			strBody += "<TR><TD><B>Date Requested</B></TD><TD><B>"
					+ strReportdate + "</B></TD></TR>";
			strBody += "<TR><TD><B>Requestor</B></TD><TD><B>"
					+ strReportedbyname + "</B></TD></TR>";
			strBody += "<TR><TD><B>Customer/Client</B></TD><TD><B>"
					+ strCustomername + "</B></TD></TR>";
			strBody += "<TR><TD><B>Requested work</B></TD><TD><B>"
					+ strDescription + "</B></TD></TR>";
			if (strLdtext != null && !strLdtext.equals("*****************")) {
				strBody += "<TR><TD><B> Description</B></TD><TD><B>"
						+ strLdtext + "</B></TD></TR>";

			}
			strBody += "<TR><TD><B>Location</B></TD><TD><B>" + strLocation
					+ "</B></TD></TR>";
			strBody += "<TR><TD><B>Date Needed</B></TD><TD><B>"
					+ strSchedfinish + "</B></TD></TR>";
			strBody += "<TR><TD><B>Project ID</B></TD><TD><B>" + strGlaccount
					+ "</B></TD></TR>";
			
			strBody += "<TR><TD><B>FAM</B></TD><TD><B>" + strFAMName
					+ "</B></TD></TR>";  // JIRA EF-8495
			
			/****************************************************************** 
			 * Facilities requested to remove the lead and supervisor. Instead 
			    print FAM JIRA EF-8495
			 
			if (strLead != null && strLead.length() > 0) {

				if (strLeadphone != null && strLeadphone.length() > 0)
					strBody += "<TR><TD><B>Lead</B></TD><TD><B>" + strLead
							+ " -  " + strLeadname + " (" + strLeadphone
							+ ")</B></TD></TR>"; // WOR-2
				else
					strBody += "<TR><TD><B>Lead</B></TD><TD><B>" + strLead
							+ " -  " + strLeadname + "</B></TD></TR>"; // WOR-2
			}

			strBody += "<TR><TD><B>Supervisor</B></TD><TD><B>" + strSupervisor
					+ " - " + strSupervisor_name + "</B>";
			// Added on 6/3/07 prevent null pointer error, if the
			// the supervisor phone is null
			if (strSupervisorphone != null && strSupervisorphone.length() > 0)
				strBody += "  <B>(" + strSupervisorphone + ")</B>";
				strBody += "</TD></TR>";
			*********************Till here JIRA EF-8495*********/
			
			
			
			strBody += "</TABLE>";

			strBody += "</TD></TR><TR><TD>&nbsp;</TD></TR><TR><TD>";

			strBody += "<A href=" + strWOVisibilityURL + "?orgid=" + strOrgid
					+ "&siteid=" + strSiteid + "&wonum=" + strWonum + ">";
			strBody += "<B>Please click on this link to find out the latest status of this work order.</B>";
			strBody += "</A>";

			strBody += "</TD></TR><TR><TD>&nbsp;</TD></TR><TR><TD>";

			if (!strStatus.equals("CAN"))
				/* JIRA EF-8495 Different text 
				strBody += "We will contact you and/or perform the work shortly. ";

			strBody += "If you have any questions or this is urgent, ";
			strBody += "please contact the Work Request Center at x6274.";
			strBody += "<BR><BR> Thank you. ";  */
			// JIRA EF-8495 
			strBody += "Please contact the Facilities Area Manager (FAM) identified above for any clarifications.";
			strBody += "<BR><BR> Thank you. ";  
						
			strBody += strFooter;
			strBody += "</TD></TR></TABLE></BODY></HTML>";
		} // if (strType.equals("ACKNOWLEDGE"))

		if (strType.equals("NOTIFY")) {
			// strBody
			// ="<html><head><title>Work order Completed. Please provide feedback.</title></head>";

			// strBody
			// ="<html><head><title>Please give us your feedback against the Facilities Work order </title></head>";
			// JIRA EF-3492
			strBody = "<html><head><title>Work order Completed. </title></head>";

			strBody += "<body><TABLE><TR><TD>";
			if (strTo.equals("REPORTEDBY"))
				strBody += "Dear " + strReportedbyname + ",</TD></TR>";
			else if (strTo.equals("CUSTOMER"))
				strBody += "Dear " + strCustomername + ",</TD></TR>";

			strBody += "<TR><TD>&nbsp;</TD></TR>";

			if (strStatus.equals("COMP") || strStatus.equals("WCLOSE")
					|| strStatus.equals("CLOSE"))
				strBody += "<TR><TD>The Facilities Division is pleased to inform you that the work requested below was completed on "
						+ strStatusdate + ".</TD></TR> ";
			// else -- JIRA EF-3492
			// strBody
			// +="<TR><TD>The Facilities Division requests you to provide your feedback for the work requested below. </TD></TR>";

			strBody += "<TR><TD>&nbsp;</TD></TR>";

			/*
			 * Commented - per JIRA EF-3492 strBody +="<TR><TD>";
			 * 
			 * strBody
			 * +="We would appreciate it if you could take a few moments to let us "
			 * ; strBody
			 * +="know how well the Facilities Division addressed your needs. ";
			 * strBody +="</TD></TR>";
			 * 
			 * strBody +="<TR><TD>&nbsp;</TD></TR>" ;
			 * 
			 * strBody +="<TR><TD>"; if (strTo.equals("REPORTEDBY")) strBody
			 * +="<A href=" + strWoFeedbackURL +
			 * "?action=validate&wonum="+strWonum
			 * +"&customerid="+strReportedby+">"; if (strTo.equals("CUSTOMER"))
			 * strBody +="<A href=" + strWoFeedbackURL +
			 * "?action=validate&wonum="+strWonum
			 * +"&customerid="+strCustomerlinkid+">";
			 * 
			 * strBody +=
			 * "<B>Please click on this link to record your feedback for the work performed.</B>"
			 * ; strBody +="</A>"; strBody +="</TD></TR><TR><TD></TD></TR>" ;
			 * ***************************
			 */

			strBody += "<TR><TD>";
			strBody += "<TABLE align=left border=2>";
			strBody += "<TR><TD><B>Work Order Number</B></TD> " + "<TD><B>"
					+ strWonum + "</B></TD></TR>";
			strBody += "<TR><TD><B>Description</B></TD>" + "<TD><B>"
					+ strDescription + "</B></TD></TR>";
			strBody += "<TR><TD><B>Location</B></TD>" + "<TD><B>" + strLocation
					+ "</B></TD></TR>";

			if (strLead != null && strLead.length() > 0) // WOR-2
			{

				if (strLeadphone != null && strLeadphone.length() > 0)
					strBody += "<TR><TD><B>Lead</B></TD><TD><B>" + strLead
							+ " -  " + strLeadname + " (" + strLeadphone
							+ ")</B></TD></TR>"; // WOR-2
				else
					strBody += "<TR><TD><B>Lead</B></TD><TD><B>" + strLead
							+ " -  " + strLeadname + "</B></TD></TR>"; // WOR-2
			}
			strBody += "<TR><TD><B>Supervisor</B></TD><TD><B>" + strSupervisor
					+ " -  " + strSupervisor_name + "</B>";
			if (strSupervisorphone != null && strSupervisorphone.length() > 0)
				strBody += "  <B>(" + strSupervisorphone + ")</B>";
			strBody += "<TR><TD><B>Work Order Status</B></TD>" + "<TD><B>"
					+ strStatus + "</B></TD></TR>";
			strBody += "<TR><TD><B>Work Order Status Date</B></TD>" + "<TD><B>"
					+ strStatusdate + "</B></TD></TR>";
			strBody += "</TD></TR>";
			strBody += "</TABLE>";
			strBody += "</TD></TR>";

			strBody += "<TR><TD>&nbsp;</TD></TR><TR><TD>";
			strBody += "We are committed to serving you and are continuously  ";
			strBody += "working to improve our service.";
			strBody += "</TD></TR><TR><TD>&nbsp;</TD></TR><TR><TD>";
			strBody += "Thank you.</TD></TR>";
			strBody += strFooter;
			strBody += "</TD></TR></TABLE></BODY></HTML>";
		} // if (strType.equals("NOTIFY"))

		// Now send e-mail
		System.out.println("***About to send e-mail for work order " + strWonum
				+ "(" + strStatus + ") to " + strCustomeremail);
		if (strCustomeremail != null && strCustomeremail.length() > 0)
			MailUtil.SendMail("smtp.lbl.gov",
			// "WRC@lbl.gov",
					"fam@lbl.gov", // JIRA EF-8422
					strCustomeremail, strSubjectline, "HTML", strBody);
	}

	/****************************************************************
	 * Method to update the record in lbl_maxvars table to indicate the last
	 * date/time stamp when the program was executed
	 * 
	 * @throws SQLException
	 ****************************************************************/
	private static void updLBLMaxvars(Connection myConnection, String strOrgid,
			String strSiteid, String strVarname, String strDateTime)
			throws SQLException {
		String strUpdate = null;
		PreparedStatement pstmt = null;

		strUpdate = " update lbl_maxvars ";
		strUpdate += "  set varvalue='" + strDateTime + "'";
		strUpdate += "  where orgid=" + "'" + strOrgid + "'";
		strUpdate += "  and   siteid=" + "'" + strSiteid + "'";
		strUpdate += " and varname=? ";
		// System.out.println(strUpdate);
		pstmt = myConnection.prepareStatement(strUpdate);
		pstmt.setString(1, strVarname);
		pstmt.executeUpdate();
		if (pstmt != null)
			pstmt.close();

	}

} // class


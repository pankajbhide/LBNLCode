package lbl;

/*Written by: James Nguyen
 *Date: 12/20/06
 *FilenName: PetroVend2Max.java
 *Function: Read input files from the Petrovend system
 *          Insert into a staging table.
 *          Validate the transaction
 *          Insert into MAXIMO matusetrans
 *          Update MAXIMO invbalances table
 *          Update MAXIMO equipments table
 * 			Updating Export date in staging table 
 *          Generate record file in HTML format
 *          Email HTML file to responsible people
 * 
 * Modification
 * History:   Pankaj Bhide 
 *  
 *            If the meterreading is equal to ??????, then, set it to 
 *            zero and report the error. (01/03/07).
 * 
 *            Use Sequence lbl_petrovend_seq1 instead of maxseq. (01/03/07)
 * 
 *            Get Run control from lbl_petrovend_seq2 and attach to staging table.
 * 
 * *            May 08, 2009 - Pankaj - Changes required for MXES
 * 
 *              Dec 18, 2009 - Pankaj - Fixed meterreading issues
 *              
 *              Nov 30, 2015 - Pankaj - MAXIMO 7.6 changes
 *              
 *              Aug 14, 2020 - Pankaj - MAXIMO 7.6.1.1 changes
 */
import java.awt.BorderLayout;
import java.awt.GridLayout;
import java.awt.event.ActionEvent;
import java.awt.event.ActionListener;
import java.io.BufferedReader;
import java.io.BufferedWriter;
import java.io.File;
import java.io.FileReader;
import java.io.FileWriter;
import java.io.IOException;
import java.math.BigDecimal;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.Properties;

import javax.mail.Message;
import javax.mail.Session;
import javax.mail.Transport;
import javax.mail.internet.InternetAddress;
import javax.mail.internet.MimeMessage;
import javax.swing.JButton;
import javax.swing.JFrame;
import javax.swing.JLabel;
import javax.swing.JPanel;
import javax.swing.JPasswordField;
import javax.swing.JScrollPane;
import javax.swing.JTextArea;
import javax.swing.JTextField;
import javax.swing.SwingConstants;

import oracle.jdbc.OracleDriver;

public class PetroVend2Max{
	//declare and initilize local objects
	PetroVend2MaxUtil petroVend2MaxUtil = new PetroVend2MaxUtil();
	JFrame mainProgramFrame;
	JPanel mainProgramPanel;
	JLabel userNameLabel, passwordLabel;
	JTextField userNameTextField;
	JPasswordField passwordField;
	JButton processButton, exitButton;
	String dbString, usernameString, passwordString, strUnixEnvName, strDBEnvName;
	JTextArea outputTextArea;
	String strMaxMeterFile = "", strTransactFile = "", strLogFile = "", strLogDir = "";
	
	//String strDatFileLocal = "C:\\lbl_pv2mx\\dat\\config.dat", strDatFileShared = "Q:\\lbl_pv2mx_dev\\dat\\config.dat";
	String strDatFileLocal = "C:\\lbnl\\mxes\\development\\batch_programs\\fac\\java\\dat\\config.dat";
	String strDatFileShared = "V:\\Facilities\\PetroVend2MXES\\dat\\config.dat";

	
	
	String strDieselTank = "", strUnleadedTank = "";
	JPanel scrollPanelWrapper;
	JLabel labelQuestion;
	ActionListener alButtonProcess, alButtonExit;
	String strTodayDate = "", strLatestReading = "", strAssetnum = "", strItemNum = "", strDateFileFormat = "";
	String strHTMLFileLocation = "", strHTMLFileName = "Petrovend2MaxOutput";
	String strDateMessageFormat = ""; //fileformat = YYYYMMDDHH24MISS; messageformat = MM/DD/YYYY HH24:MI:SS
	String strLineError = ""; //error output
	double dStandardCost = 0.0, dBalance = 0.0;
	int iInputLineNum = 0, iTotalError = 0, iTotalSuccess = 0;
	double dULMileLimit = 0.0, dDMileLimit = 0.0, dEMileLimit = 0.0;
	long lngRuncontrol=0;

	//These objects hold historical records in MAXMETER.DLY file
	//lbl_Pet2Mx_Rec mmdDieselFileRecord, mmdUnleadedFileRecord, mmdDieselDBRecord, mmdUnleadedDBRecord; 
	
	Connection myConnection = null;
	Statement mainStatement = null;
	
	public PetroVend2Max(){
		//create and set up new window
		mainProgramFrame = new JFrame("Petrovend to Maximo Interface Program");
		mainProgramFrame.setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
		//prompt size (width, length)
		mainProgramFrame.setSize(400, 300);
		//prompt upper left coordinate
		mainProgramFrame.setLocation(300,150);
		mainProgramFrame.setResizable(true);		
		
		//create and set up panel
		mainProgramPanel = new JPanel(new BorderLayout());
		addDBConWidgets();
		
		//display the window		
		mainProgramFrame.setVisible(true);
	}
	
	public void addDBConWidgets(){
		userNameLabel = new JLabel("Maximo Username: ", SwingConstants.LEFT);
		passwordLabel = new JLabel("Maximo Password: ", SwingConstants.LEFT);
		
		userNameTextField = new JTextField("", 20);
		userNameTextField.setText("") ;
		passwordField = new JPasswordField("", 20);
		passwordField.setText("");
		passwordField.setEchoChar('*');
		
		outputTextArea = new JTextArea();
		outputTextArea.setAutoscrolls(true);
		outputTextArea.setEditable(false);
		outputTextArea.setLineWrap(false);
		
		scrollPanelWrapper = new JPanel(new BorderLayout());
		JScrollPane scrollPane = new JScrollPane(outputTextArea);
		scrollPanelWrapper.add(new JLabel("Program Output:"), BorderLayout.NORTH);
		scrollPanelWrapper.add(scrollPane, BorderLayout.CENTER);
		
		JPanel panelWest = new JPanel(new GridLayout(2, 1));
		panelWest.add(userNameLabel);
		panelWest.add(passwordLabel);
		JPanel panelEast = new JPanel(new GridLayout(2, 1));
		panelEast.add(userNameTextField);
		panelEast.add(passwordField);
		JPanel panelTop = new JPanel(new BorderLayout());
		panelTop.add(panelWest, BorderLayout.WEST);
		panelTop.add(panelEast, BorderLayout.CENTER);
		
		processButton = new JButton("Login");
		//set processButton handler
		alButtonProcess = new myLoginHandler();		
		processButton.addActionListener(alButtonProcess);
		
		//set cancel handler
		exitButton = new JButton("Exit");		
		alButtonExit = new myExitHandler();
		exitButton.addActionListener(alButtonExit);
		JPanel panelBottom = new JPanel(new GridLayout(2, 3));		
		panelBottom.add(processButton);
		panelBottom.add(exitButton);		
		panelBottom.add(new JLabel());		
		panelBottom.add(new JLabel());		
		panelBottom.add(new JLabel());		
		panelBottom.add(new JLabel());
		
		panelTop.add(panelBottom, BorderLayout.SOUTH);	
				
		mainProgramPanel.add(panelTop, BorderLayout.NORTH);
		mainProgramPanel.add(scrollPanelWrapper, BorderLayout.CENTER);
		mainProgramFrame.getContentPane().add(mainProgramPanel);
	}
		
	public static void main(String[] args){		
		//Schedule a job for the event-dispatching thread:
		//creating and showing this application's GUI.
		try {
			javax.swing.SwingUtilities.invokeLater(new Runnable() {
				public void run() {
					createAndShowGUI();
				}
			});
		} catch (Exception e) {
			e.printStackTrace();
			return;
		}
	}
	public static void createAndShowGUI() {
		try {			
			//javax.swing.JFrame.setDefaultLookAndFeelDecorated(true);
			PetroVend2Max mainProgram = new PetroVend2Max();

		} catch (Exception e) {
			System.out.println("An error has accurred.");
			e.printStackTrace();
			return;
		}
	}
	
	public void SetOutput(String str){
		outputTextArea.setText(outputTextArea.getText() + str + "\n");
		mainProgramPanel.repaint();
	}
	
	public class myExitHandler implements ActionListener {
		public void actionPerformed(ActionEvent event){
			//do more clean up here//			
			try{
				if(mainStatement != null){
					mainStatement.close();				
				}
				if(myConnection != null){
					myConnection.close();
				}
			}catch(Exception e){}
			System.exit(0);
		}
	}
	
	public class myLoginHandler implements ActionListener{
		public void actionPerformed(ActionEvent event){
			outputTextArea.setText("");//clear output
			String username = userNameTextField.getText();
			char[] password = passwordField.getPassword();
			String strDBParams = "";
			try{
				//check if local config file exists
				File fLocalDatFile = new File(strDatFileLocal);
				File fSharedDatFile = new File(strDatFileShared);
				//loading variables stored in files
				if(fLocalDatFile.exists()){
					strDBParams = petroVend2MaxUtil.GetConfigVar("dbparam", strDatFileLocal);
				}else if(fSharedDatFile.exists()){
					strDBParams = petroVend2MaxUtil.GetConfigVar("dbparam", strDatFileShared);					
				}else{
					SetOutput("Unable to locate config.dat file.");
					return;
				}
				
				//now connect to the DB that SAID in the production environment//
				DriverManager.registerDriver(new OracleDriver());
				SetOutput("Logging " + userNameTextField.getText().trim() + " into " + strDBParams + ".");
				myConnection = DriverManager.getConnection("jdbc:oracle:thin:@" + strDBParams, userNameTextField.getText(), new String(password));
				myConnection.setAutoCommit(false);
				mainStatement = myConnection.createStatement();
				//delete password//
				for (int i = 0; i < password.length; i++) {
					password[i] = '\0';
				}				
				SetOutput("Login OK.");
				//if the login is invalid, shouldn't get here
				
				//clear main frame//				
				JPanel panelYesNo = new JPanel(new GridLayout(1, 3));
				processButton.removeActionListener(alButtonProcess);
				alButtonProcess = new MaxMeterYes();
				processButton.addActionListener(alButtonProcess);				
				processButton.setText("Yes");
				
				exitButton.removeActionListener(alButtonExit);
				alButtonExit = new myExitHandler();
				exitButton.addActionListener(alButtonExit);
				exitButton.setText("No");
				panelYesNo.add(processButton);
				panelYesNo.add(exitButton);
				panelYesNo.add(new JLabel());
								
				JPanel panelTop1 = new JPanel(new GridLayout(3, 1));
				labelQuestion = new JLabel("About to insert records into Maximo. Are you sure?");				
				panelTop1.add(labelQuestion);
				panelTop1.add(panelYesNo);
				
				mainProgramPanel.removeAll();
				mainProgramPanel.add(panelTop1, BorderLayout.NORTH);
				mainProgramPanel.add(scrollPanelWrapper);
				mainProgramFrame.getContentPane().add(mainProgramPanel);				
			}catch(Exception ex){
				SetOutput("Error: Either the username or password is unrecognized. Please try again.");
				return;
			}
		}		
	}
	
	public class MaxMeterYes implements ActionListener{				
		public void actionPerformed(ActionEvent event){			
			try{
				//disable the buttons
				processButton.setEnabled(false);
				exitButton.setEnabled(false);
				mainProgramPanel.repaint();				
				SetOutput("Reading historical records...");
				InitializeDBStoredVaribles();				
				//ReadFile(); //read the record file of old meter reading/new meter reading
				//ReadDB(); //read DB for current meter reading
				SetOutput("Processing input file...");
				//Now process the Transact file (insert into staging table, write output file and emailing//
				if(ProcessPVTransacts()){
					SetOutput("Inserting into MAXIMO tables...");
					InsertMainDB();
					if(CopyFile2Log()){
						SetOutput("Input file copied to log directory.");
					}
					SendEmail();
					SetOutput("Program finished. Please check your email for the log file.");
				}
				DisplayFinalMessage();			
			}catch(Exception e){
				SetOutput("An error has occured in the program. Please contact support.");
				e.printStackTrace();
				DisplayFinalMessage();
				try{
					if(mainStatement != null){
						mainStatement.close();				
					}
					if(myConnection != null){
						myConnection.rollback();
						myConnection.close();
					}
				}catch(Exception ex){
					ex.printStackTrace();
					System.exit(0);
				}
			}			
			
			//read from database
		}
	
		/*
		 * The K800 version of Petrovend no longer produce this file		 
		public void ReadFile() throws IOException{
			try{
				BufferedReader br = new BufferedReader(new FileReader(strMaxMeterFile));
				mmdDieselFileRecord = new lbl_Pet2Mx_Rec(br.readLine());
				//SetOutput("Diesel: " + "\n" + mmdDieselFileRecord);
				mmdUnleadedFileRecord = new lbl_Pet2Mx_Rec(br.readLine());
				//SetOutput("Unleaded: " + "\n" + mmdDieselFileRecord);
				if(br != null){br.close();}
			}catch(IOException e){
				SetOutput("Error: Program cannot locate file: " + strMaxMeterFile);
				throw e;
			}
		}
		*/
		
		public String GetTodayDate() throws SQLException{
			String strReturnVal = "";			
			ResultSet rs = mainStatement.executeQuery("select to_char(sysdate, 'DD-MON-YYYY') from dual");
			if(rs.next()){
				strReturnVal = rs.getString(1);
			}
			if(rs!=null){rs.close();}				
			return strReturnVal;						
		}
		
		//read meter reading from Database for Unleaded and Diesel
		/*
		 * The version K800 of petrovend no longer requires this step
		public void ReadDB() throws SQLException{
			String sql = "select meterreading, meterreading2, to_char(readingdate, 'DD-MON-YYYY') readingdate1, to_char(readingdate2, 'DD-MON-YYYY') readingdate2 from maximo.equipment where eqnum in ('" + strDieselTank + "', '" + strUnleadedTank + "') order by eqnum";			
			try{
				ResultSet rs = mainStatement.executeQuery(sql);
				if(rs.next()){				
					mmdUnleadedDBRecord = new lbl_Pet2Mx_Rec("01", rs.getString(1), "0", rs.getString(2), "0", rs.getString(3), rs.getString(4));					
				}else{
					SetOutput("An error occurs while reading Unleaded entry from Database.\n" + sql);
				}
				if(rs.next()){
					//only use the new reading fields. the old reading field is initialized to 0.
					//the reason is the object lbl_Pet2Max_Rec 'shares' the functionality to read from file
					//which as new old veedernew veederold
					mmdDieselDBRecord = new lbl_Pet2Mx_Rec("02", rs.getString(1), "0", rs.getString(2), "0", rs.getString(3), rs.getString(4));
				}else{
					SetOutput("An error occurs while reading Diesel entry from Database.\n" + sql);
				}				
				if(rs!=null){rs.close();}
			}catch(SQLException ex){
				throw ex;
			}
		}		
		*/
		
		/* Process the transact file
		 * Create HTML file header
		 * For each line in the transact file
		 * 1. Read into a lbl_PetTrans object
		 * 2. Validate the data. If there are any error, append the error to an error String
		 * 3. Insert the line into the staging table
		 * 4. Create the HTML table line
		 * 
		 * When done, close the HTML file and send email to the responsible people 
		 */
		
		public boolean ProcessPVTransacts() throws IOException, SQLException{
			BufferedReader br = null;			
			String strTemp = "";			
			PetroVendTrans trans;			
			ResultSet rsTemp = null;
			File Pet2MaxHTMLFile = null;
			FileWriter fw = null;
			BufferedWriter bw = null;
			BufferedReader brEmail = null;
			String strFileContent = "", chrDblquote = "\"";
			//reset the total line num
			iInputLineNum = 0;		
			iTotalError=0;
			
			String strThisassetnum="";
			
			File fTemp = new File(strTransactFile);
			if(fTemp.exists()){
				br = new BufferedReader(new FileReader(strTransactFile));
			}else{
				SetOutput("Error: Progam cannot locate file: " + strTransactFile);
				return false;
			}				
			strHTMLFileLocation = petroVend2MaxUtil.GetMaxVar("PETROVEND2MXES_HTMLFILELOCATION", mainStatement);
			//get current date format for file name and for header in the HTML file				
			rsTemp = mainStatement.executeQuery("select to_char(sysdate, 'YYYYMMDDHH24MISS') date_format, to_char(sysdate, 'MM/DD/YYYY HH24:MI:SS') date_format_head from dual");
			rsTemp.next();
			strDateFileFormat = rsTemp.getString("date_format");
			strDateMessageFormat = rsTemp.getString("date_format_head");
			strHTMLFileName = strHTMLFileLocation + strHTMLFileName + strDateFileFormat + ".html";				 
			if(rsTemp!=null){rsTemp.close();}
			
			//initiate Pet2MaxHTMLFile//
			Pet2MaxHTMLFile = new File(strHTMLFileName);
			fw = new FileWriter(Pet2MaxHTMLFile);
			bw = new BufferedWriter(fw);
			//prepare HTML file header//
			strFileContent = "<HTML>\n<HEAD>\n<TITLE>Log of Pet2Max Interface (" + strDateMessageFormat + ")</TITLE>\n</HEAD>\n<BODY>\n";
			strFileContent += "<P align=" + chrDblquote + "center" + chrDblquote + "><FONT face=" + chrDblquote + "Arial" + chrDblquote + " size=" + chrDblquote + "4" + chrDblquote + ">";
			strFileContent += "Lawrence Berkeley National Laboratory</FONT></P>\n";
			strFileContent += "<P align=" + chrDblquote + "center" + chrDblquote + "><FONT face=" + chrDblquote + "Arial" + chrDblquote + " size=" + chrDblquote + "4" + chrDblquote + ">";
			strFileContent += "Log of Maximo-Petrovend Interface</FONT></P>\n";
			strFileContent += "</HEAD>\n<BODY>\n<FONT face=" + chrDblquote + "Arial" + chrDblquote + ">\n<TABLE border = \"1\">\n";
			//prepare HTML table header
			//strFileContent += "<TR><TH>#</TH><TH>Trans Date/Time</TH><TH>Fuel Card</TH><TH>Meter Read</TH><TH>PumpID</TH><TH>Prod</TH><TH>Quantity</TH<TH>Message</TH></TR>\n";
			strFileContent += "<TR><TH>#</TH><TH>Trans Date/Time</TH><TH>Fuel Card</TH><TH>Meter Read</TH><TH>AssetNum</TH><TH>Prod</TH><TH>Quantity</TH<TH>Message</TH></TR>\n";

			strFileContent += "";
			GetMileLimit();
			GetRuncontrol(); // Added by Pankaj 01/03/07
			
			while((strTemp = br.readLine()) != null){										
				iInputLineNum++;					
				trans = new PetroVendTrans(strTemp);					
				strTodayDate = GetTodayDate();	
				
				// Added by Pankaj 1/11/10
				strThisassetnum=getAssetnum(trans);
				trans.setAssetnum(strThisassetnum);
				
				CheckForDuplicate(trans);
				ValidateDate(trans);				
				if(Math.abs(trans.dQuantity) <= 0){
					strLineError += "Error line: " + iInputLineNum + " - Invalid quantity. (" + trans.dQuantity + ").\n";						
				}					
				if(!trans.strPump.equals("01") && !trans.strPump.equals("02") && !trans.strPump.equals("03")){
					strLineError += "Error line: " + iInputLineNum + " - Invalid pump number. (" + trans.strPump + ").\n";
				}
				//assign strItemNum to DIESEL/ UNLEADED or ETHANEL
				strItemNum = trans.DecodeProduct();
				//PrintDebug("before check meter reading");
				if(CheckFuelCard(trans)){//also grab strAssetnum and strLatestReading (number of lastest reading)
					CheckMeterReading(trans, strLatestReading);
					dStandardCost = GetStandardCost(trans);
				}
				
				//PrintDebug("after check meter reading");
												
				CheckBalExist(trans);					
				//insert into staging table
				
				InsertStagingDB(trans, strItemNum, strAssetnum, dStandardCost, dBalance);
				//PrintDebug("after insert staging");
				//write to HTML file
				strFileContent += "<TR><TD>" + iInputLineNum + "</TD>" + trans.toHTMLString();
				if(strLineError.equals("")){
					strLineError = "Valid";
				}else{
					iTotalError++;
				}
				strFileContent += "<TD>" + strLineError + "</TD></TR>\n";
				//reset for next transaction
				strLineError = "";
			}
										
			//append file footer//
			strFileContent += "</TABLE>\n</FONT>\n<P align=" + chrDblquote + "center" + chrDblquote + "><FONT face=" + chrDblquote + "Arial" + chrDblquote + " size=" + chrDblquote + "4" + chrDblquote + ">";
			strFileContent += "Log generated at: " + strDateMessageFormat + "</FONT></P>\n";				
			strFileContent += "</BODY>\n</HTML>\n";
			//PrintDebug(strFileContent);
			bw.write(strFileContent);				
			if(bw != null) bw.close();
			if(fw != null) fw.close();				
			if(br != null) br.close();
			return true;
		}
		public boolean ValidateDate(PetroVendTrans transac) throws SQLException{			
			String strHour = transac.strTime.substring(0, 2);
			String strMin = transac.strTime.substring(2, 4);
			boolean bRet = true;
			//use RR format for Century
			String strSql = "select to_date('" + transac.strDate + " " + strHour + ":" + strMin + "', 'YYMMDD HH24:MI') from dual";			
			String strDummy = "";			
			ResultSet rsTemp = mainStatement.executeQuery(strSql);
			rsTemp.next();
			if(rsTemp.getString(1) == null){
				strLineError += "Error line: " + iInputLineNum + " - Incorrect Date/Time format. (" + transac.strDate + " " + transac.strTime + ")\n";
				bRet = false;
			}				
			if(rsTemp!=null){rsTemp.close();}	
			return bRet;
		}
		
		public String getAssetnum(PetroVendTrans transac) throws SQLException
		{
	  	  String strAssetnum=""; 
	   	  String strSql = " select a.assetnum ";
	             strSql +=" from maximo.asset a, maximo.lbl_vehiclespec b ";
	             strSql +=" where a.orgid=b.orgid and a.siteid=b.siteid ";
	             strSql +=" and   a.assetnum=b.assetnum ";
	             strSql +=" and   a.orgid='LBNL' and a.siteid='FAC' ";
	             strSql +=" and   a.serialnum='" + transac.strDriver + "'";
		//PrintDebug("strSql: " + strSql);			
		ResultSet rsTemp = mainStatement.executeQuery(strSql);
		if(rsTemp.next()){
			strAssetnum = rsTemp.getString("assetnum");
			
		}
		if(rsTemp!=null) rsTemp.close();
		
		
		return strAssetnum;
	   } // end of getAssetnum
		
		
		public boolean CheckFuelCard(PetroVendTrans transac) throws SQLException{
			boolean bRet = true;
			//String strSql = "select a.serialnum, a.assetnum, from maximo.asset a, maximo.assetmeter b  where a.orgid=b.orgid and a.siteid.b.siteid and a.orgid='LBNL' and a.siteid='FAC' and a.assetnum=b.assetnum and b.metername = 'FLEET' and a.serialnum = '" + transac.strDriver + "'";
			String strSql = " select a.serialnum, a.assetnum, ";
			       strSql +=" nvl(replace(b.lastreading,','),0) lastreading ";  // Added by Pankaj on 12/18/09 to take care of commas in meterreading
			       strSql +=" from maximo.asset a, maximo.assetmeter b  where a.orgid=b.orgid  and a.siteid=b.siteid and a.assetnum=b.assetnum and b.orgid='LBNL' and b.siteid='FAC' and b.metername='FLEET' and a.serialnum='" + transac.strDriver + "'";
			//PrintDebug("strSql: " + strSql);			
			ResultSet rsTemp = mainStatement.executeQuery(strSql);
			if(rsTemp.next()){
				strAssetnum = rsTemp.getString("assetnum");
				strLatestReading = rsTemp.getString("lastreading");				
			}else{				
				strAssetnum = "";
				strLatestReading = "";
				strLineError += "Error line: " + iInputLineNum + " - Incorrect Fuelcard (" + transac.strDriver + ").\n";
				bRet = false;
			}
			if(rsTemp!=null){rsTemp.close();}
			return bRet;
		}
		public boolean CheckMeterReading(PetroVendTrans trans, String strLatestReading){
			double dTempReading = 0;
			String strTempMeterReading = trans.strMilage.trim();			
			boolean bRet = true;
			//PrintDebug("reading: " + strTempMeterReading + "  pre reading: " + strLatestReading + "  " + iInputLineNum);
			
			
			if(strTempMeterReading.equals("000000") || strTempMeterReading.equals("??????") || strTempMeterReading.equals("")){
				 strLineError += "Error line: " + iInputLineNum + " - Invalid meter reading. (" + strTempMeterReading + ")\n";
				 bRet = false;
			}
			if(strTempMeterReading.indexOf("?")>0){
				strLineError += "Error line: " + iInputLineNum + " - Invalid meter reading. (" + strTempMeterReading + ")\n";
				bRet = false;
			}
			
            // Perform this casting after checking the correctness of the contents
			// and if the contents are numeric, then, only perform the subsequent
			// checks.
			// Pankaj 01/08/07
		   if (bRet)
		   {
			double dLatestReading = new Double(strLatestReading).doubleValue();
			
			dTempReading = new Double(strTempMeterReading).doubleValue();
			if(Math.abs(dTempReading) <= 0){
				strLineError += "Error line: " + iInputLineNum + " - Zero/negative meter reading. (" + dTempReading + ")\n";
				bRet = false;
			}
			if(dTempReading < dLatestReading){
				strLineError += "Error line: " + iInputLineNum + " - Latest reading " + dTempReading + " less than previous reading " + dLatestReading + ".\n";
				bRet = false;
			}			
			if(strItemNum.equals("DIESEL")){				
				if(dTempReading > dLatestReading + dDMileLimit){					
					strLineError += "Error line: " + iInputLineNum + " - Invalid meter reading. Reason: Reading exceeds limit of(" + dDMileLimit + ") from last record.\n";
					bRet = false;
				}
			}else if(strItemNum.equals("UNLEADED")){				
				if(dTempReading > dLatestReading + dULMileLimit){
					strLineError += "Error line: " + iInputLineNum + " - Invalid meter reading. Reason: Reading exceeds limit of(" + dULMileLimit + ") from last record.\n";
					bRet = false;
				}
			}else if(strItemNum.equals("ETHANOL")){				
				if(dTempReading > dLatestReading + dEMileLimit){
					strLineError += "Error line: " + iInputLineNum + " - Invalid meter reading. Reason: Reading exceeds limit of(" + dEMileLimit + ") from last record.\n";
					bRet = false;
				}
			}
		   } // bRet is true
			return bRet;
		}
		public double GetStandardCost(PetroVendTrans trans) throws SQLException{
			double dReturnVal = 0.0;
			String strSql = "select stdcost from maximo.invcost where itemnum = '" + strItemNum + "' and location = 'FLEET'";
			ResultSet rs;			
			rs = mainStatement.executeQuery(strSql);
			if(rs.next()){
				dReturnVal = rs.getDouble(1);
			}
			if(rs!=null){rs.close();}
			return dReturnVal;
		}		
		public boolean CheckForDuplicate(PetroVendTrans trans) throws SQLException{			
			ResultSet rs = null;
			String strSql = "select rowstamp from batch_maximo.lbl_petrovend_staging where fuelcard = '" + trans.strDriver + "' and ";			
			strSql += "to_char(transdate, 'YYMMDD HH24MI') = '" + trans.strDate + " " + trans.strTime + "'";
			//PrintDebug("check dup: " + strSql);
			rs = mainStatement.executeQuery(strSql);				
			if(!rs.next()){			
				//good, no record found					
				if(rs!=null){rs.close();}
				return true;
			}				
			if(rs!=null){rs.close();}				
			strLineError += "Error line: " + iInputLineNum + " - Duplicated entry.\n";
			return false;
		}
		
		public boolean CheckBalExist(PetroVendTrans trans) throws SQLException{
			ResultSet rs = null;
			String strSql = "";
			boolean bRet = true;
			strSql = "select curbal from maximo.invbalances where itemnum = '" + strItemNum + "' and location = 'FLEET'";			
			rs = mainStatement.executeQuery(strSql);
			if(rs.next()){
				dBalance = rs.getDouble(1);					
			}else{
				dBalance = 0.0;
				strLineError = "Error line: " + iInputLineNum + " - No curbal in MAXIMO INVBALANCES table for " + strItemNum + "";
				bRet = false;
			}
			if(rs!=null){rs.close();}
			return bRet;
		}
				
		public void InsertStagingDB(PetroVendTrans trans, String strItemNum, String strAssetnum, double dStandardCost, double dBalance) throws SQLException{
			double dLineCost = dStandardCost * trans.dQuantity;			
			String strSql = "", strSqlInsert, strNextSeqNum = "", strWhereDate = "", strFinancialPeriod = "", strIsValid = "";
			ResultSet rs = null;
			double dTransQty = trans.dQuantity * -1;
			
			BigDecimal bdRounder = new BigDecimal(dLineCost);
			bdRounder = bdRounder.setScale(2, BigDecimal.ROUND_HALF_UP);
			dLineCost = bdRounder.doubleValue();

			if(strLineError.equals("")){
				strIsValid = "Y";				
			}else{
				strIsValid = "N";
			}		 
			 
			// Changed by Pankaj - use a new sequence 01/03/07
			strSql = "select maximo.lbl_petrovend_seq1.nextval from dual";
			//PrintDebug(strSql);
			
			rs = mainStatement.executeQuery(strSql);
			
			rs.next();
			strNextSeqNum = rs.getString(1);
			if(rs!=null){rs.close();}
			
			//get financial period given the transaction date//
			//prepare where clause
			strWhereDate = "to_date('" + trans.strDate + " " + trans.strTime + "', 'YYMMDD HH24MI')";			
			strWhereDate = "trunc(" + strWhereDate + ") between trunc(b.periodstart) and trunc(b.periodend) ";
		
			strSql = "select a.financialperiod from financialperiods a where a.financialperiod = ";
			strSql += "(select min(b.financialperiod) from financialperiods b where " + strWhereDate + ")";
			
			rs = mainStatement.executeQuery(strSql);
			// Put in loop Pankaj 01/03/07
			if(rs.next())
			{
			   strFinancialPeriod = rs.getString(1);
			}
			if(rs!=null){rs.close();}
			
			// Added by Pankaj 01/03/07
			String strTempMileage=null;
			if (trans.strMilage != null && trans.strMilage.trim().indexOf("?") >=0)
			    strTempMileage="0"; 
		    else
		        strTempMileage=trans.strMilage;
		   
			//prepare insert statement into staging table
			strSqlInsert = "insert into batch_maximo.lbl_petrovend_staging(";
			strSqlInsert += "rowstamp, insertdate, transdate, transnum, ";
			strSqlInsert += "acctnum, fuelcard, vehnum, ";
			strSqlInsert += "lastreading, keyboard, pump, product,";
			strSqlInsert +=	"quantity, unitcost, linecost, siteid, ";
			strSqlInsert += "itemnum, assetnum, financialperiod,";
			strSqlInsert += "isvalid, errortext, exportmessage, exportdate, runcontrol) values ";				
			strSqlInsert += "('" + strNextSeqNum + "', sysdate, to_date('" + trans.strDate + " " + trans.strTime + "', 'YYMMDD HH24MI'),'" + trans.strTransNum + "','";
			strSqlInsert += trans.strAcctNum + "','" + trans.strDriver + "','" + trans.strVeh + "',";
			//strSqlInsert += trans.strMilage + ",'" + trans.strKeyboard + "','" + trans.strPump + "','" + trans.strProduct + "',";
			strSqlInsert += strTempMileage + ",'" + trans.strKeyboard + "','" + trans.strPump + "','" + trans.strProduct + "',";
			strSqlInsert += trans.dQuantity + ", " + dStandardCost + ", " + dLineCost + ",'" + trans.strSiteNum + "',";				
			strSqlInsert += "'" + strItemNum + "', '" + strAssetnum + "', '" + strFinancialPeriod + "',";
			strSqlInsert += "'" + strIsValid + "', '" + strLineError + "', null, null, " + lngRuncontrol +")";
			//PrintDebug("insert staging: " + strSqlInsert);
			mainStatement.executeUpdate(strSqlInsert);
		}
		
		public void InsertMainDB() throws SQLException{
			//insert into maximo.matusetrans
			//update maximo.invbalances
			//update maximo.equipment
			Statement stmtTemp = null;
			ResultSet rs = null, rsSequenceNum = null, rsBalance = null, rsSetId=null;			 			  
			String strSqlInsert = "", strSeqNum = "", strItemNum = "", strStagingRowStamp = "", strAssetnum = "", strSetId="";
			double dBalance = 0.0, dQuantity = 0.0, dMeterReading = 0.0, dLineCost = 0.0, dUnitCost = 0.0;
			iTotalSuccess = 0;
			
							
			//prepare select statement to read from staging table//
			String strSqlSelect = "select rowstamp,to_char(a.transdate, 'YYMMDD HH24MI') transdate, transnum, ";
			strSqlSelect += "acctnum, fuelcard, vehnum, lastreading, keyboard,";
			strSqlSelect += "pump, product, quantity, unitcost, linecost,";
			strSqlSelect += "siteid, itemnum, assetnum, financialperiod, isvalid ";
			strSqlSelect += "from batch_maximo.lbl_petrovend_staging a where ";
			strSqlSelect += "a.exportdate is null and a.isValid = 'Y'";
			
			//PrintDebug("strselect: " + strSqlSelect);
			//stmtTemp = myConnection.createStatement();
			
			
			//rsSetId = stmtTemp.executeQuery("select setid from maximo.sets where settype='ILBNL'");
			//rsSetId.next();
			//strSetId= rsSequenceNum.getString("setid");
			//if(rsSetId!=null){rsSetId.close();}
			strSetId="ILBNL"; 
		
			
			rs = mainStatement.executeQuery(strSqlSelect);				
			while(rs.next()){
				//get sequence number for matusetrans					
			    //rsSequenceNum = stmtTemp.executeQuery("select maximo.maxseq.nextval seqnum from dual");
			    // Use seq number specifically created for matusetrans
			    // Pankaj 01/03/07
				
				stmtTemp = myConnection.createStatement();
				rsSequenceNum = stmtTemp.executeQuery("select maximo.matusetransseq.nextval seqnum from dual");
				rsSequenceNum.next();
				strSeqNum = rsSequenceNum.getString("seqnum");
				if(rsSequenceNum!=null) rsSequenceNum.close();
				
				dMeterReading = rs.getDouble("lastreading");
				strItemNum = rs.getString("itemnum");
				strStagingRowStamp = rs.getString("rowstamp");
				strAssetnum = rs.getString("assetnum");
				dQuantity = rs.getDouble("quantity") * -1;
				dUnitCost = rs.getDouble("unitcost");
				dLineCost = Math.abs(dQuantity * dUnitCost);
									
				//get dBalance from maximo.invbalances
				
				rsBalance = stmtTemp.executeQuery("select curbal from maximo.invbalances where itemnum = '" + strItemNum + "' and location = 'FLEET' and orgid = 'LBNL' and siteid = 'FAC'");
				rsBalance.next();
				dBalance = rsBalance.getDouble("curbal");
				if(rsBalance!=null){rsBalance.close();}
				
				//PrintDebug("old balance: " + dBalance);
				//PrintDebug("dQuantity: " + dQuantity);
				//PrintDebug("new balance: " + (dBalance + dQuantity));
				//PrintDebug("dMeter: " + dMeterReading);
				
				String strMemo="Run Control-" + lngRuncontrol;
				//prepare insert statement to insert into matuse trans table
				strSqlInsert = "insert into maximo.matusetrans (itemnum, storeloc, transdate,";
				strSqlInsert += " actualdate, quantity, curbal, physcnt, unitcost,";
				strSqlInsert += " actualcost, conversion, assetnum, enterby, ";
				strSqlInsert += " issuetype, linecost, currencycode, sparepartadded, matusetransid, ";
				strSqlInsert += " financialperiod, outside, rollup, orgid, siteid, enteredastask, memo, ";
				strSqlInsert += " hasld, langcode, linetype, tositeid, itemsetid, CONSIGNMENT, "; // 7.6
				strSqlInsert += " wpitemid "; // 7.6.1.1
				strSqlInsert += 		") values ";
				strSqlInsert += "('" + strItemNum + "','FLEET', to_date('" + rs.getString("transdate") + "', 'YYMMDD HH24MI'),";					
				strSqlInsert += "sysdate," + dQuantity + "," + dBalance + ", 0," + dUnitCost + ",";					
				strSqlInsert += dUnitCost + ",1,'" + strAssetnum + "', 'FLEET',";
				strSqlInsert += "'ISSUE', " + dLineCost + ",'USD',";
				strSqlInsert += " 0,'" + strSeqNum  + "','" + rs.getString("financialperiod") + "',0,0,'LBNL', 'FAC',0, '" + strMemo + "' , ";
				strSqlInsert += " 0, 'EN','ITEM','FAC', 'ILBNL',0, "; // 7.6 
				strSqlInsert += " 0"; // 7.6.1.1
				strSqlInsert +=  " )";	
				
				//System.out.println(strSqlInsert);
				//PrintDebug("strinsert matusetrans: " + strSqlInsert);
				stmtTemp.executeUpdate(strSqlInsert);
								
				
				strSqlInsert = "update maximo.invbalances set curbal = " + (dBalance + dQuantity) + " where itemnum = '" + strItemNum + "' and location = 'FLEET' and siteid = 'FAC' and orgid = 'LBNL'";
				//PrintDebug("strUpdate invbal: " + strSqlInsert);
				stmtTemp.executeUpdate(strSqlInsert);
				
				//PrintDebug("strinsert: " + strSqlInsert);
				stmtTemp.executeUpdate(strSqlInsert);					
				if(rsSequenceNum!=null){rsSequenceNum.close();}
														
				strSqlInsert = "update maximo.assetmeter set lastreading= " + dMeterReading + ", lastreadingdate = SYSDATE ";
				strSqlInsert += " where assetnum= '" + strAssetnum + "' and metername = 'FLEET'";
				//PrintDebug("strUpdate equip: " + strSqlInsert);
				
				stmtTemp.executeUpdate(strSqlInsert);
				
				//update export date in staging table
				strSqlInsert = "update batch_maximo.lbl_petrovend_staging set exportdate = sysdate where rowstamp = '" + strStagingRowStamp + "'";
				//PrintDebug("strInsert: " + strSqlInsert);
				stmtTemp.executeUpdate(strSqlInsert);					
				iTotalSuccess++;
			}			
			myConnection.commit();
			//myConnection.rollback();
			//PrintDebug("out of while");
			SetOutput("Sucessfully entered " + iTotalSuccess + " out of " + iInputLineNum + " - Total Error: " + iTotalError);
			if(rs!=null){rs.close();}				
			if(stmtTemp!=null)stmtTemp.close();
		}
		/*
		 * The K800 version of Petrovend no longer produce this file
		public void WriteToFile() throws IOException{
			try{
				BufferedWriter out = new BufferedWriter(new FileWriter(strMaxMeterFile, false));
				//file content
				//new reading is from the data base
				//old reading is from the new reading of the previous file record.
				String strFC = "01, " + mmdDieselDBRecord.dReadingNew + ", " + mmdDieselFileRecord.dReadingNew + ", " + mmdDieselDBRecord.dVeederNew + ", " + mmdDieselFileRecord.dVeederNew + ", " + strTodayDate + "\n";
				strFC =        "02, " + mmdUnleadedDBRecord.dReadingNew + ", " + mmdUnleadedFileRecord.dReadingNew + ", " + mmdUnleadedDBRecord.dVeederNew + ", " + mmdDieselFileRecord.dReadingNew + ", " + strTodayDate + "\n";								
				out.write(strFC);
				if(out!=null){out.close();}
			}catch(IOException ex){
				throw ex;
			}					
		}
		*/
		public void AppendToLogFile() throws IOException{
			String strLine = "";
			try{
				BufferedReader in = new BufferedReader(new FileReader(strMaxMeterFile));
				BufferedWriter out = new BufferedWriter(new FileWriter(strLogFile, true));
				while((strLine = in.readLine()) != null){
					out.write(strLine + "\n");
				}			
				if(in!=null){in.close();}
				if(out!=null){out.close();}
			}catch(IOException ex){
				throw ex;
			}			
		}
		public void PrintDebug(String str){
			System.out.println(str);
		}
		public void DisplayFinalMessage(){
		 	//turn on the processbutton
		 	processButton.setEnabled(true);
		 	JPanel panelYesNo = new JPanel(new GridLayout(1, 3));
			processButton.removeActionListener(alButtonProcess);
			alButtonProcess = new myExitHandler();
			processButton.addActionListener(alButtonProcess);				
			processButton.setText("Finish");			
			panelYesNo.add(processButton);	
			panelYesNo.add(new JLabel());
			panelYesNo.add(new JLabel());
							
			JPanel panelTop1 = new JPanel(new GridLayout(3, 1));
			labelQuestion = new JLabel("Program Finish.");				
			panelTop1.add(labelQuestion);
			panelTop1.add(panelYesNo);
			
			mainProgramPanel.removeAll();
			mainProgramPanel.add(panelTop1, BorderLayout.NORTH);
			mainProgramPanel.add(scrollPanelWrapper);
			mainProgramFrame.getContentPane().add(mainProgramPanel);	
		 }
		 
		 public boolean CopyFile2Log() throws IOException{		 	
		 	//File fOld = new File(strTransactFile);
		 	String strNewFile = strLogDir + "TRANSACT_" + strDateFileFormat + ".log";
		 	//return fOld.renameTo(new File(strNewFile));		 	
		 	BufferedReader brTemp = new BufferedReader(new FileReader(strTransactFile));
		 	BufferedWriter bwTemp = new BufferedWriter(new FileWriter(strNewFile));
		 	String strTemp = "";
		 	while((strTemp = brTemp.readLine()) != null){
		 		bwTemp.write(strTemp+"\n");		 		
		 	}
		 	if(brTemp!=null){brTemp.close();}
		 	if(bwTemp!=null){bwTemp.close();}
		 	return true;
		 }
		 public void InitializeDBStoredVaribles() throws SQLException{
		 	try{
			 	strMaxMeterFile = petroVend2MaxUtil.GetMaxVar("PET2MAX_MAXMETERFILE", mainStatement);
			 	strTransactFile = petroVend2MaxUtil.GetMaxVar("PETROVEND2MXES_TRANSACTFILE", mainStatement);
			 	strLogDir = petroVend2MaxUtil.GetMaxVar("PETROVEND2MXES_LOGDIR", mainStatement);
			 	strDieselTank = petroVend2MaxUtil.GetMaxVar("PETROVEND2MXES_DIESELTANK", mainStatement);
				strUnleadedTank = petroVend2MaxUtil.GetMaxVar("PETROVEND2MXES_UNLEADEDTANK", mainStatement);
		 	}catch(SQLException e){
		 		SetOutput("Error: Failed to load program variables.");		 		
		 		throw e;
		 	}
		 }		 
		 public void SendEmail() throws IOException, Exception{
		 	String strFileContent = "", strTempLine = "";
		 	try{		 				 	
		 		BufferedReader br = new BufferedReader(new FileReader(strHTMLFileName));
		 		while((strTempLine = br.readLine())!= null){
		 			strFileContent += strTempLine;
		 		}
		 		if(br!=null){br.close();}
		 	}
		 	catch(IOException ex){
		 		SetOutput("Error: Cannot read HTML file to email.");
		 		throw ex;
		 	}catch(Exception ex){
		 		throw ex;
		 	}
			//send email//
			//get email address//				
			//String strSelectEmail = "select emailaddress from maximo.email where personid in (";
		 	
			//String strSelectEmail = " select varvalue from batch_maximo.lbl_maxvars where varname = 'PETROVEND2MXES_NOTIFY' ";
		 	String strSelectEmail = " select varvalue from maximo.lbl_maxvars where varname = 'PETROVEND2MXES_NOTIFY' ";
			strSelectEmail += " and orgid='LBNL' and siteid='FAC' ";
			
			//PrintDebug("email address: " + strSelectEmail);
			ResultSet rsEmailAddress = mainStatement.executeQuery(strSelectEmail);				
			String strSubject = "Maximo-Petrovend Interface Log - Generate at " + strDateMessageFormat;
			String strEmailAddress = "";
			while(rsEmailAddress.next()){
				try{
					strEmailAddress = rsEmailAddress.getString("varvalue");
					//PrintDebug("address: " + rsEmailAddress.getString("pagepin"));
					DoSendMail("smtp.lbl.gov", "meauser@lbl.gov", strEmailAddress, strSubject, "HTML", strFileContent);
					SetOutput("Sent email to " + strEmailAddress + ".");
				}catch(Exception e){
					SetOutput("Error in sending email to " + strEmailAddress + ".");
					e.printStackTrace();
				}
			}	
		 }
		 public void DoSendMail (String sHost,String sFrom, String sTo, String sSubject, String sContentType, String sContent) throws Exception {
		    String host = sHost;
		    String from = sFrom;
		    String to =   sTo;

		    //Get system properties
		    Properties props = System.getProperties();
		    //Setup mail server
		    props.put("mail.smtp.host", host);
		    //Get session
		    Session session = Session.getDefaultInstance(props, null);
		    //Define message
		    MimeMessage message = new MimeMessage(session);
		    //Set the from address
		    message.setFrom(new InternetAddress(from));
		    //Set the to address
		    message.addRecipient(Message.RecipientType.TO, 
		    new InternetAddress(to));
		    //Set the subject
		    message.setSubject(sSubject);

		    if(sContentType.equalsIgnoreCase("HTML"))
		     message.setContent(sContent,"text/html");
		    else message.setContent(sContent,"text/plain");
		    
		     //Send message
		    Transport.send(message);	
		}
		 
		public void GetMileLimit() throws SQLException{
			try{
				ResultSet rsTemp = mainStatement.executeQuery("select itemnum, sstock from maximo.inventory where location = 'FLEET' and orgid = 'LBNL' and siteid = 'FAC' and itemnum in ('UNLEADED', 'DIESEL', 'ETHANOL') order by itemnum");
				while(rsTemp.next()){
					if(rsTemp.getString("itemnum").equals("DIESEL")){
						dDMileLimit = rsTemp.getDouble("sstock");
					}else if(rsTemp.getString("itemnum").equals("UNLEADED")){
						dULMileLimit = rsTemp.getDouble("sstock");
					}else if(rsTemp.getString("itemnum").equals("ETHANOL")){
						dEMileLimit = rsTemp.getDouble("sstock");
					}else{
						SetOutput("Error: Unrecognize feul type.");
					}	
				}
				rsTemp.close();
			}catch(SQLException ex){
				SetOutput("Error: Failed to read fuel type mile limit.");
				throw ex;
			}
		}
	}
	public void GetRuncontrol() throws SQLException{
		try{
			ResultSet rsTemp = mainStatement.executeQuery("select maximo.lbl_petrovend_seq2.nextval from dual");
			while(rsTemp.next()){
			    lngRuncontrol=rsTemp.getLong(1);				
			}
			rsTemp.close();
		}catch(SQLException ex){
			SetOutput("Error: Failed to get next seq from lbl_petrvend_seq2.");
			throw ex;
		}
	}
	
}
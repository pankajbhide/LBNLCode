package lbl.app.lbl_walkthru; 

import psdi.util.MXException; 
import psdi.mbo.MboServerInterface;
import java.rmi.RemoteException;
import psdi.mbo.MboSet;
import psdi.mbo.Mbo;
import psdi.util.logging.MXLogger;
import psdi.util.logging.MXLoggerFactory;

public class LblWalkthruSet extends psdi.mbo.custapp.CustomMboSet implements LblWalkthruSetRemote {

	final private String APPLOGGER = "maximo.application.LBL_WALKTHRU";
	private MXLogger log;

	public LblWalkthruSet(MboServerInterface mboServerInterface0)
			throws RemoteException, MXException {
		super(mboServerInterface0);
		log = MXLoggerFactory.getLogger(APPLOGGER);
	}

	protected Mbo getMboInstance(MboSet mboSet0) throws MXException,
			RemoteException {
		log.debug("LblWalkthruSet.getMboInstance");
		return new LblWalkthru(mboSet0);
	} 

}//class 
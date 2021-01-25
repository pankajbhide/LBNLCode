/**
 *  LblWOSet for WORKORDER table 
 */

package lbl.app.workorder; 
 
import java.rmi.*;
import java.util.*;
import psdi.util.*;
import psdi.mbo.*;
import psdi.app.workorder.*;
  
public class LblWOSet extends WOSet implements LblWOSetRemote
{
	/** Construct the set 
	*
	* @param ms The MboServerInterface
	* 
	*/
	public LblWOSet(MboServerInterface ms) throws MXException, RemoteException
	{
		super(ms);
                
	} 

	/** Factory method to create a LblWO object. 
	 *
	 * @param ms The LblWO.
	 * @return an  object in the set LblWOSet.
	 */
	protected Mbo getMboInstance(MboSet ms) throws MXException, RemoteException
	{
		return new LblWO(ms);
	}
	//
	// checks if it is valid to add a new Mbo
	// throws an MXException it is is invalid
	//
	public void canAdd() throws MXException
	{
		super.canAdd();
	}
    //
    // set up any non-persistent fields that are not defined in the database
    // in maxsyscolumns2
    //
    public void initDataDictionary() 
    {
        super.initDataDictionary(); //
            
        // get this MboSet DD information
        //MboSetInfo msi = getMboSetInfo();
            
        //--create non persistent field - and register it


    }

}

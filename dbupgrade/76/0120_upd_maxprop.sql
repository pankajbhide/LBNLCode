
update maxpropvalue set propvalue='tivoli09',changeby='PBHIDE', changedate=sysdate where propname='mxe.webclient.skin';
update maxprop      set changeby='PBHIDE', changedate=sysdate where propname='mxe.webclient.skin';

update maxpropvalue set propvalue='smtp.lbl.gov',changeby='PBHIDE', changedate=sysdate where propname='mail.smtp.host';
update maxprop      set changeby='PBHIDE', changedate=sysdate where propname='mail.smtp.host';

update maxpropvalue set propvalue='mmofac.lbl.gov',changeby='PBHIDE', changedate=sysdate where propname='mxe.help.host';
update maxprop      set changeby='PBHIDE', changedate=sysdate where propname='mxe.help.host';


update maxpropvalue set propvalue='https' ,changeby='PBHIDE', changedate=sysdate where propname='mxe.help.protocol';
update maxprop      set changeby='PBHIDE', changedate=sysdate where propname='mxe.help.protocol';

update maxpropvalue set propvalue='443' ,changeby='PBHIDE', changedate=sysdate where propname='mxe.help.port';
update maxprop      set changeby='PBHIDE', changedate=sysdate where propname='mxe.help.port';

update maxpropvalue set propvalue='pbhide@lbl.gov' ,changeby='PBHIDE', changedate=sysdate where propname='mxe.adminEmail';
update maxprop      set changeby='PBHIDE', changedate=sysdate where propname='mxe.adminEmail';

update maxpropvalue set propvalue='1' ,changeby='PBHIDE', changedate=sysdate where propname='mxe.adminmode.logoutmin';
update maxprop      set changeby='PBHIDE', changedate=sysdate where propname='mxe.adminmode.logoutmin';

update maxpropvalue set propvalue='/apps/mxes/DOCLINKS/default' ,changeby='PBHIDE', changedate=sysdate where propname='mxe.doclink.doctypes.defpath';
update maxprop      set changeby='PBHIDE', changedate=sysdate where propname='mxe.doclink.doctypes.defpath';

update maxpropvalue set propvalue='/apps/mxes/DOCLINKS' ,changeby='PBHIDE', changedate=sysdate where propname='mxe.doclink.doctypes.topLevelPaths';
update maxprop      set changeby='PBHIDE', changedate=sysdate where propname='mxe.doclink.doctypes.topLevelPaths';

update maxpropvalue set propvalue='1' ,changeby='PBHIDE', changedate=sysdate where propname='webclient.enabledoclinkonload';
update maxprop      set changeby='PBHIDE', changedate=sysdate where propname='webclient.enabledoclinkonload';

update maxpropvalue set propvalue='/apps/mxes/DOCLINKS=https://mmofac.lbl.gov' ,changeby='PBHIDE', changedate=sysdate where propname='mxe.doclink.path01';
update maxprop      set changeby='PBHIDE', changedate=sysdate where propname='mxe.doclink.path01';

update maxpropvalue set propvalue='20' ,changeby='PBHIDE', changedate=sysdate where propname='mxe.doclink.maxfilesize';
update maxprop      set changeby='PBHIDE', changedate=sysdate where propname='mxe.doclink.maxfilesize';

update maxpropvalue set propvalue='0' ,changeby='PBHIDE', changedate=sysdate where propname='mxe.report.AttachDoc.validateURL';
update maxprop      set changeby='PBHIDE', changedate=sysdate where propname='mxe.report.AttachDoc.validateURL';

-- To verify with Ravi L 
update maxpropvalue set propvalue='http://mmofac.lbl.gov:9080/meaweb' ,changeby='PBHIDE', changedate=sysdate where propname='mxe.int.webappurl';
update maxprop      set changeby='PBHIDE', changedate=sysdate where propname='mxe.int.webappurl';

--- To verify with Ravi L 
update maxpropvalue set propvalue='/apps/mxes/mmofac02/IBM/WebSphere/AppServer/profiles/ctgAppSrv01/globaldir' ,changeby='PBHIDE', changedate=sysdate where propname='mxe.int.globaldir';
update maxprop      set changeby='PBHIDE', changedate=sysdate where propname='mxe.int.globaldir';

update maxpropvalue set propvalue='0' ,changeby='PBHIDE', changedate=sysdate where propname='mxe.webclient.logging.CorrelationEnabled';
update maxprop      set changeby='PBHIDE', changedate=sysdate where propname='mxe.webclient.logging.CorrelationEnabled';

update maxpropvalue set propvalue='0' ,changeby='PBHIDE', changedate=sysdate where propname='mxe.mboCount';
update maxprop      set changeby='PBHIDE', changedate=sysdate where propname='mxe.mboCount';

update maxpropvalue set propvalue='36000' ,changeby='PBHIDE', changedate=sysdate where propname='mxe.cronTaskMonitorInterval';
update maxprop      set changeby='PBHIDE', changedate=sysdate where propname='mxe.cronTaskMonitorInterval';


update maxpropvalue set propvalue='1' where propname='mxe.useAppServerSecurity';
update maxprop      set changeby='PBHIDE', changedate=sysdate where propname='mxe.useAppServerSecurity';

update maxpropvalue set propvalue='0' where propname='mxe.AllowLDAPUsers'; 
update maxprop      set changeby='PBHIDE', changedate=sysdate where propname='mxe.AllowLDAPUsers';

update maxpropvalue set propvalue='0' where propname='mxe.LDAPUserMgmt'; 
update maxprop      set changeby='PBHIDE', changedate=sysdate where propname='mxe.LDAPUserMgmt';

update maxpropvalue set propvalue='0' where propname='mxe.logging.CorrelationEnabled'; 
update maxprop      set changeby='PBHIDE', changedate=sysdate where propname='mxe.logging.CorrelationEnabled';


update maxpropvalue set propvalue='0' where propname='mxe.mbocount'; 
update maxprop      set changeby='PBHIDE', changedate=sysdate where propname='mxe.mbocount';


update maxpropvalue set propvalue='IT-BS-MXINTADM' where propname='mxe.int.dfltuser';
update maxprop      set changeby='PBHIDE', changedate=sysdate where propname='mxe.int.dfltuser';

update crontaskinstance set active=0 where instancename in ('InvResResTypeUpdateCronTask',
'WOMaterialStatusUpdateCronTask','ConsignmentInvoiceCronTask',
'AssetTopoCacheCron','SLROUTECLEANUP');
------------------

update maxpropvalue set propvalue='0' where propname='mxe.webclient.async';
update maxprop      set changeby='PBHIDE', changedate=sysdate where propname='mxe.webclient.async';

update maxpropvalue set propvalue='1000' where propname='mxe.webclient.ClientEventQueue.timeout';
update maxprop      set changeby='PBHIDE', changedate=sysdate where propname='mxe.webclient.ClientEventQueue.timeout';

update maxpropvalue set propvalue='0' where propname='mxe.webclient.ClientEventQueue.threshold';
update maxprop      set changeby='PBHIDE', changedate=sysdate where propname='mxe.webclient.ClientEventQueue.threshold';

update maxpropvalue set propvalue='50' where propname='mxe.report.reportsInAPage';
update maxprop      set changeby='PBHIDE', changedate=sysdate where propname='mxe.report.reportsInAPage';

----

update maxpropvalue set propvalue='0' where propname='mxe.webclient.verticalLabels';
update maxprop      set changeby='PBHIDE', changedate=sysdate where propname='mxe.webclient.verticalLabels';


-------------
update maxpropvalue set propvalue='true' where propname='webclient.enabledoclinkonload';
update maxprop      set changeby='PBHIDE', changedate=sysdate where propname='mxe.webclient.verticalLabels';
---------------------------------------------------------------------------------
update MAXPROPVALUE set propvalue=0 where propname='mxe.enableConcurrentCheck';

commit;


update maxpropvalue set propvalue='1000' where propname='webclient.maxselectrows';
update maxprop      set changeby='PBHIDE', changedate=sysdate where propname='webclient.maxselectrows';




commit;





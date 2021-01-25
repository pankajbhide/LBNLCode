
---------------------
update maxattributecfg set domainid=null where objectname='LABTRANS' and attributename='LT3';
update maxattribute set domainid=null where objectname='LABTRANS' and attributename='LT3';

commit;

---------------------

-- deleting maximo 5 archive tables 
delete MAXOBJECTCFG where OBJECTNAME 
in ('A_EQUIPMENT','A_INVENTORY','A_INVBALANCES','A_TOOLTRANS','A_WORKORDER','A_MATRECTRANS','A_MATUSETRANS','A_EQUIPMENTSPEC','A_INVTRANS','A_LOCATIONS','APPLAUNCH','TOOL','MOTORS','PUMPS','VALVES');

delete MAXOBJECT where OBJECTNAME 
in ('A_EQUIPMENT','A_INVENTORY','A_INVBALANCES','A_TOOLTRANS','A_WORKORDER','A_MATRECTRANS','A_MATUSETRANS','A_EQUIPMENTSPEC','A_INVTRANS','A_LOCATIONS','APPLAUNCH','TOOL','MOTORS','PUMPS','VALVES');

delete from MAXTABLECFG where TABLENAME
in ('A_EQUIPMENT','A_INVENTORY','A_INVBALANCES','A_TOOLTRANS','A_WORKORDER','A_MATRECTRANS','A_MATUSETRANS','A_EQUIPMENTSPEC','A_INVTRANS','A_LOCATIONS','APPLAUNCH','TOOL','MOTORS','PUMPS','VALVES');

delete from MAXTABLE where TABLENAME
in ('A_EQUIPMENT','A_INVENTORY','A_INVBALANCES','A_TOOLTRANS','A_WORKORDER','A_MATRECTRANS','A_MATUSETRANS','A_EQUIPMENTSPEC','A_INVTRANS','A_LOCATIONS','APPLAUNCH','TOOL','MOTORS','PUMPS','VALVES');

delete from MAXATTRIBUTECFG where OBJECTNAME  
in ('A_EQUIPMENT','A_INVENTORY','A_INVBALANCES','A_TOOLTRANS','A_WORKORDER','A_MATRECTRANS','A_MATUSETRANS','A_EQUIPMENTSPEC','A_INVTRANS','A_LOCATIONS','APPLAUNCH','TOOL','MOTORS','PUMPS','VALVES');

delete from MAXATTRIBUTE where OBJECTNAME  
in ('A_EQUIPMENT','A_INVENTORY','A_INVBALANCES','A_TOOLTRANS','A_WORKORDER','A_MATRECTRANS','A_MATUSETRANS','A_EQUIPMENTSPEC','A_INVTRANS','A_LOCATIONS','APPLAUNCH','TOOL','MOTORS','PUMPS','VALVES');

Delete From maxsyskeys Where ixname In (Select name From maxsysindexes Where tbname in ('A_EQUIPMENT','A_INVENTORY','A_INVBALANCES','A_TOOLTRANS','A_WORKORDER','A_MATRECTRANS','A_MATUSETRANS','A_EQUIPMENTSPEC','A_INVTRANS','A_LOCATIONS','APPLAUNCH','TOOL','MOTORS','PUMPS','VALVES'));

Delete From maxsysindexes Where tbname in
 ('A_EQUIPMENT','A_INVENTORY','A_INVBALANCES','A_TOOLTRANS','A_WORKORDER','A_MATRECTRANS','A_MATUSETRANS','A_EQUIPMENTSPEC','A_INVTRANS','A_LOCATIONS','APPLAUNCH','TOOL','MOTORS','PUMPS','VALVES');

commit;


alter table invtrans modify (newcost number(15,5));

alter table invtrans modify (oldcost number(15,5));

ALTER TABLE MODLABAVAIL 
 MODIFY (
  LABORCODE NULL,
  REASONCODE NULL,
  ORGID NULL

 );

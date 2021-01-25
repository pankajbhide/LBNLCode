ALTER TABLE INVOICETRANS 
 ADD (
  lbl_linecost NUMBER (15, 5)
 )
 MODIFY (
  LINECOST NULL

 );


update invoicetrans set lbl_linecost=linecost;

update invoicetrans set linecost=null;

commit;

ALTER TABLE INVOICETRANS 
 MODIFY (
  linecost NUMBER (15, 5)

 );

update invoicetrans set linecost=lbl_linecost;

commit;

ALTER TABLE INVOICETRANS 
 MODIFY (
  LINECOST NOT NULL

 );
 
alter table invoicetrans drop column lbl_linecost;


update maxattribute set scale=5 where objectname='INVOICETRANS' and attributename='LINECOST';

update maxattributecfg set scale=5 where objectname='INVOICETRANS' and attributename='LINECOST';

commit;

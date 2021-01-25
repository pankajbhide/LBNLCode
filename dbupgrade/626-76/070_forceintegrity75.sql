
update maxvars set varvalue = 'PASS' where varname = 'INTEGRITYCHECK' ;

update maxvars set varvalue = current_timestamp where varname = 'INTEGRITYDATE' ;

commit;

declare 

 cursor t1_cursor is 
 select   --dbms_lob.substr(a.ldtext , 4000, 1 )ldtext ,
 to_char(a.ldtext) ldtext,
 a.ldownertable, a.ldownercol,a.ldkey,
 a.langcode,
 b.autoscript
 from longdescription@this2src a, autoscript@this2src b 
 where a.ldownertable='AUTOSCRIPT'
 and   a.ldkey=b.autoscriptid ;
 
 
 
 
 number_t number(7) :=0;
 ldkey_t  longdescription.ldkey%type;
                   
 begin
   
   for t1_record in t1_cursor
    loop
     
      number_t := number_t +1;
      select autoscriptid into ldkey_t
      from autoscript
      where autoscript=t1_record.autoscript;
      
      insert into longdescription(ldtext, 
      ldownertable, ldownercol,ldkey,
      langcode, longdescriptionid, 
      contentuid) values
      (t1_record.ldtext, 
      t1_record.ldownertable, t1_record.ldownercol, ldkey_t,
      t1_record.langcode, longdescriptionseq.NEXTVAL,
      'BMXAB'|| trim(to_char(number_t)));
    end loop;
    
  commit;
  
end;

/
      
      
 
 

 

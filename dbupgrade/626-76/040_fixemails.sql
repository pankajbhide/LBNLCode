declare cursor duplicate_email_cur  is
  select * from email
  where trim(emailaddress) is null 
  for update;
  
begin
   for duplicate_email_rec in duplicate_email_cur
   
    loop
    
       update email
       set emailaddress=trim(to_char(duplicate_email_rec.emailid)) || '.@lbl.gov'
       where current of duplicate_email_cur;
       
   end loop;
   
commit;

end;
/




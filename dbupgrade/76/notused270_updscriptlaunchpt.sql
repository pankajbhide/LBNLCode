
declare cursor scriptlaunchpoint_cur 
 is 
 select * from 
   scriptlaunchpoint@this2src;

begin

  for scriptlaunchpoint_rec in scriptlaunchpoint_cur
  
   loop
   

    update scriptlaunchpoint
    set objectevent=scriptlaunchpoint_rec.objectevent
    where 
    launchpointname=scriptlaunchpoint_rec.launchpointname
    and autoscript=scriptlaunchpoint_rec.autoscript
    and launchpointtype=scriptlaunchpoint_rec.launchpointtype
    and objectname=scriptlaunchpoint_rec.objectname
    and nvl(attributename,'X')=nvl(scriptlaunchpoint_rec.attributename,'X');
    
 end loop; 

commit;

end;

/

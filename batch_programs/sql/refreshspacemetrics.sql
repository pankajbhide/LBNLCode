/*****************************************************************************
 PROGRAM NAME           : refreshspacemetrics.SQL

 DATE WRITTEN           : 01-sep-2016

 AUTHOR                 : PANKAJ BHIDE

 USAGE                  : 
                           
                          
 PURPOSE                : program to refresh the data into lbl_space_metrics
                          table.                  
*****************************************************************************/
WHENEVER SQLERROR EXIT 1 ROLLBACK;

DECLARE
 
 t_dv_id dv.dv_id%type;
 t_bl_id rm.bl_id%type;
 t_fl_id rm.fl_id%type;
 t_rm_id rm.rm_id%type;
 t_sp_metrics_group lbl_job_codes.sp_metrics_group%type;
 t_group1_matin  lbl_space_metrics.group1_matin%type;
 t_group2_matin  lbl_space_metrics.group2_matin%type;
 t_group3_matin  lbl_space_metrics.group3_matin%type;
 t_group4_matin  lbl_space_metrics.group4_matin%type;
 t_group5_matin  lbl_space_metrics.group5_matin%type;
 t_group6_matin  lbl_space_metrics.group6_matin%type;
 
 t_group1_matout  lbl_space_metrics.group1_matout%type;
 t_group2_matout  lbl_space_metrics.group2_matout%type;
 t_group3_matout  lbl_space_metrics.group3_matout%type;
 t_group4_matout  lbl_space_metrics.group4_matout%type;
 t_group5_matout  lbl_space_metrics.group5_matout%type;
 t_group6_matout  lbl_space_metrics.group6_matout%type;
 t_assigned_sf    lbl_space_metrics.assigned_sf%type;
 t_row_count      number(5);
 t_group1_count   lbl_space_metrics.group1_count%type; 
 t_group2_count   lbl_space_metrics.group2_count%type;
 t_group3_count   lbl_space_metrics.group3_count%type;
 t_group4_count   lbl_space_metrics.group4_count%type;
 t_group5_count   lbl_space_metrics.group5_count%type;
 t_group6_count   lbl_space_metrics.group6_count%type;
 
 CURSOR div_cursor is 
       select dv_id,name from afm.dv 
       --where dv_id='AC'
       order by dv_id;
 
 /* look for all the active rooms of a given division - exclude bldg 0000 */
 cursor rmmatin_cursor is 
       select * from rm 
       where rm.dv_id=t_dv_id 
       and   rm.lbl_inactive=0 
       and   rm.bl_id not in ('0000');
       
 /* look for all the active employees for a given room */
 cursor emmatin_cursor is
       select * from em
       where bl_id=t_bl_id and fl_id=t_fl_id and rm_id=t_rm_id
       and  em.status='A';
       
 /* look all the employees of a given division excluding bldg 0000 */
 cursor emmatout_cursor is
       select * from em
       where  em.dv_id=t_dv_id
       and    em.status='A'
       and    em.bl_id not in ('0000');
       
 /* get the details of given room */
 cursor rmmatout_cursor is 
       select * from rm 
       where rm.bl_id=t_bl_id and rm.fl_id=t_fl_id and rm.rm_id=t_rm_id
       and   rm.lbl_inactive=0;
 
 /* count of active employees group by metrics_group for a given division */
 cursor group_count_cur is
     select b.sp_metrics_group, count(*) group_count
     from  em a, lbl_job_codes b
     where a.dv_id=t_dv_id
     and   a.status='A'
     and   a.lbl_jobcode=b.job_code
     and   a.bl_id not in ('0000')
     group by b.sp_metrics_group
     order by b.sp_metrics_group;
     
 /* cursor for calculating totals */  
 cursor totals_cur is select * from lbl_space_metrics for update; 
 
 begin
 
   -- intial processing
   delete from lbl_space_metrics;
   
   execute immediate 'create index i_em_idx1 on em(bl_id, fl_id, rm_id, status)';
   execute immediate 'create index i_em_idx2 on em(dv_id, status,lbl_jobcode)';
 
   
   DBMS_STATS.GATHER_TABLE_STATS(
                           OWNNAME=>'AFM', 
                           TABNAME=>'EM',
                           ESTIMATE_PERCENT=>DBMS_STATS.AUTO_SAMPLE_SIZE,
                           CASCADE=>TRUE); 
                       
   execute immediate 'create index i_rm_idx1 on rm(bl_id, fl_id, rm_id, lbl_inactive)';
   execute immediate 'create index i_rm_idx2 on rm(dv_id, lbl_inactive, rm_cat, area)';
      
   DBMS_STATS.GATHER_TABLE_STATS(
                           OWNNAME=>'AFM', 
                           TABNAME=>'RM',
                           ESTIMATE_PERCENT=>DBMS_STATS.AUTO_SAMPLE_SIZE,
                           CASCADE=>TRUE);                            
   
 
 
   -- start reading divisions
   
    for div_record in div_cursor
    
      loop -- div outer loop 
      
      t_dv_id :=div_record.dv_id;
      
      
      -- get group counts 
      for group_count_rec in group_count_cur       
       loop
       
        begin
         select 1 into t_row_count
         from lbl_space_metrics
         where division=t_dv_id;
         
         exception when no_data_found  then
           insert into lbl_space_metrics (division) values (t_dv_id);
        end;
        
        
        if (group_count_rec.sp_metrics_group='1') then
          update lbl_space_metrics 
          set group1_count=group_count_rec.group_count
          where division=t_dv_id;        
        elsif (group_count_rec.sp_metrics_group='2') then
          update lbl_space_metrics 
          set group2_count=group_count_rec.group_count
          where division=t_dv_id;       
        elsif (group_count_rec.sp_metrics_group='3') then
          update lbl_space_metrics 
          set group3_count=group_count_rec.group_count
          where division=t_dv_id;             
        elsif (group_count_rec.sp_metrics_group='4') then
          update lbl_space_metrics 
          set group4_count=group_count_rec.group_count
          where division=t_dv_id;                
        elsif (group_count_rec.sp_metrics_group='5') then
          update lbl_space_metrics 
          set group5_count=group_count_rec.group_count
          where division=t_dv_id;
        else
          update lbl_space_metrics 
          set group6_count=group_count_rec.group_count
          where division=t_dv_id;
        end if;
      end loop;
      
      
      
      
      -- find out count of maxtrix-in for the division      
      for rmmatin_record in rmmatin_cursor
      
       loop -- rmmatin loop 
         t_bl_id :=rmmatin_record.bl_id;
         t_fl_id :=rmmatin_record.fl_id;
         t_rm_id :=rmmatin_record.rm_id;
     
         
           for emmatin_record in emmatin_cursor
           
            loop -- emmatin loop
              -- division differs from room to employee
              -- which indicates the employee is sitting in another divisions
              -- space.
              if (emmatin_record.dv_id !=t_dv_id) then
              
               -- get space metrix group code
               t_sp_metrics_group := null;
               
               begin 
                 select sp_metrics_group 
                 into t_sp_metrics_group
                 from lbl_job_codes a
                 where a.job_code=emmatin_record.lbl_jobcode;
                 
                 -- 1 -- 
                 if (t_sp_metrics_group='1') then
                  begin
                    select nvl(group1_matin,0)
                    into t_group1_matin
                    from lbl_space_metrics
                    where division=t_dv_id;
                    
                    
                    update lbl_space_metrics
                    set group1_matin=t_group1_matin + 1 , group1='1'
                    where division=t_dv_id;
                    
                   exception when no_data_found  then
                     insert into lbl_space_metrics
                     (division, group1, group1_matin) 
                     values
                     (t_dv_id, '1',1);
                   end;
                  end if;
                  
                 -- 2 -- 
                 if (t_sp_metrics_group='2') then
                  begin
                    select nvl(group2_matin,0)
                    into t_group2_matin
                    from lbl_space_metrics
                    where division=t_dv_id;
                    
                    
                    update lbl_space_metrics
                    set group2_matin=t_group2_matin + 1, group2='2'
                    where division=t_dv_id;
                    
                    
                   exception when no_data_found  then 
                     insert into lbl_space_metrics
                     (division, group2, group2_matin) 
                     values
                     (t_dv_id, '2',1);
                   end;
                  end if;
                  
                 -- 3 -- 
                 if (t_sp_metrics_group='3') then
                  begin
                    select nvl(group3_matin,0)
                    into t_group3_matin
                    from lbl_space_metrics
                    where division=t_dv_id;
                                        
                    update lbl_space_metrics
                    set group3_matin=t_group3_matin + 1, group3='3'
                    where division=t_dv_id;
                    
                   exception when no_data_found  then 
                     insert into lbl_space_metrics
                     (division, group3, group3_matin) 
                     values
                     (t_dv_id, '3',1);
                   end;
                  end if;
                  
                 -- 4 -- 
                 if (t_sp_metrics_group='4') then
                  begin
                    select nvl(group4_matin,0)
                    into t_group4_matin
                    from lbl_space_metrics
                    where division=t_dv_id;
                    
                    
                    update lbl_space_metrics
                    set group4_matin=t_group4_matin + 1, group4='4'
                    where division=t_dv_id;
                    
                   exception when no_data_found  then
                     insert into lbl_space_metrics
                     (division, group4, group4_matin) 
                     values
                     (t_dv_id, '4',1);
                   end;
                  end if;
                  
                  -- 5 -- 
                 if (t_sp_metrics_group='5') then
                  begin
                    select nvl(group5_matin,0)
                    into t_group5_matin
                    from lbl_space_metrics
                    where division=t_dv_id;
                    
                    
                    update lbl_space_metrics
                    set group5_matin=t_group5_matin + 1, group5='5'
                    where division=t_dv_id;
                    
                   exception when no_data_found  then 
                     insert into lbl_space_metrics
                     (division, group5, group5_matin) 
                     values
                     (t_dv_id, '5',1);
                   end;
                 end if;                                    
                 
               exception when no_data_found  then 
                  begin
                    select nvl(group6_matin,0)
                    into t_group6_matin
                    from lbl_space_metrics
                    where division=t_dv_id;
                    
                    
                    update lbl_space_metrics
                    set group6_matin=t_group6_matin + 1, group6='6'
                    where division=t_dv_id;
                    
                    
                   exception when no_data_found  then 
                     insert into lbl_space_metrics
                     (division, group6, group6_matin) 
                     values
                     (t_dv_id, '6',1);
                 end;
              end ;   
             end if;   -- if (emmatin_record.dv_id !=t_dv_id) 
             
           end loop; -- emmatin loop
                       
    end loop;  -- -- rmmatin loop 
    
  --***********************************************  
  -- find out count of maxtrix-out for the division      
      for emmatout_record in emmatout_cursor
      
       loop -- emmatout loop 
         t_bl_id :=emmatout_record.bl_id;
         t_fl_id :=emmatout_record.fl_id;
         t_rm_id :=emmatout_record.rm_id;
         
          for rmmatout_record in rmmatout_cursor
           
            loop -- rmmatout loop
            
              if (rmmatout_record.dv_id !=t_dv_id) then
              
               -- get space metrix group code
               t_sp_metrics_group := null;
               
               begin 
                 select sp_metrics_group 
                 into t_sp_metrics_group
                 from lbl_job_codes a
                 where a.job_code=emmatout_record.lbl_jobcode;
                 
                 -- 1 -- 
                 if (t_sp_metrics_group='1') then
                  begin
                    select nvl(group1_matout,0)
                    into t_group1_matout
                    from lbl_space_metrics
                    where division=t_dv_id;
                    
                    
                    update lbl_space_metrics
                    set group1_matout=t_group1_matout + 1 , group1='1'
                    where division=t_dv_id;
                    
                   exception when no_data_found  then
                     insert into lbl_space_metrics
                     (division, group1, group1_matout) 
                     values
                     (t_dv_id, '1',1);
                   end;
                  end if;
                  
                  -- 2 -- 
                 if (t_sp_metrics_group='2') then
                  begin
                    select nvl(group2_matout,0)
                    into t_group2_matout
                    from lbl_space_metrics
                    where division=t_dv_id;
                    
                    
                    update lbl_space_metrics
                    set group2_matout=t_group2_matout + 1 , group2='2'
                    where division=t_dv_id;
                    
                   exception when no_data_found  then
                     insert into lbl_space_metrics
                     (division, group2, group1_matout) 
                     values
                     (t_dv_id, '2',1);
                   end;
                  end if;
                  
                 -- 3 -- 
                 if (t_sp_metrics_group='3') then
                  begin
                    select nvl(group3_matout,0)
                    into t_group3_matout
                    from lbl_space_metrics
                    where division=t_dv_id;
                    
                    
                    update lbl_space_metrics
                    set group3_matout=t_group3_matout + 1 , group3='3'
                    where division=t_dv_id;
                    
                   exception when no_data_found  then
                     insert into lbl_space_metrics
                     (division, group3, group3_matout) 
                     values
                     (t_dv_id, '3',1);
                   end;
                  end if;
                  
                 -- 4 -- 
                 if (t_sp_metrics_group='4') then
                  begin
                    select nvl(group4_matout,0)
                    into t_group4_matout
                    from lbl_space_metrics
                    where division=t_dv_id;
                    
                    
                    update lbl_space_metrics
                    set group4_matout=t_group4_matout + 1 , group4='4'
                    where division=t_dv_id;
                    
                   exception when no_data_found  then
                     insert into lbl_space_metrics
                     (division, group4, group4_matout) 
                     values
                     (t_dv_id, '4',1);
                   end;
                  end if;
                  
                 -- 5 -- 
                 if (t_sp_metrics_group='5') then
                  begin
                    select nvl(group5_matout,0)
                    into t_group5_matout
                    from lbl_space_metrics
                    where division=t_dv_id;
                    
                    
                    update lbl_space_metrics
                    set group5_matout=t_group5_matout + 1 , group5='5'
                    where division=t_dv_id;
                    
                   exception when no_data_found  then
                     insert into lbl_space_metrics
                     (division, group5, group5_matout) 
                     values
                     (t_dv_id, '5',1);
                   end;
                  end if;
                  
                 exception when no_data_found  then 
                  begin
                    select nvl(group6_matout,0)
                    into t_group6_matout
                    from lbl_space_metrics
                    where division=t_dv_id;
                    
                    
                    update lbl_space_metrics
                    set group6_matout=t_group6_matout + 1, group6='6'
                    where division=t_dv_id;
                    
                    
                   exception when no_data_found  then 
                     insert into lbl_space_metrics
                     (division, group6, group6_matout) 
                     values
                     (t_dv_id, '6',1);
                 end;
              end;   
              
             end if;   -- if (emmatout_record.dv_id !=t_dv_id) 
          end loop; -- -- rmmatout loop
        end loop; -- emmatout loop 
  
     
     -- find out total assigned sq ft for that division   
     t_assigned_sf :=0;
     t_row_count :=0;
     
     select sum(area) 
     into t_assigned_sf
     from rm
     where dv_id=t_dv_id
     and   lbl_inactive=0
     and   rm_cat in ('OFFICE')
     and   bl_id not in ('0000') ;
     --and   rm_type not in ('COMMON','SUPPORT','SERV','VERT');
          
     select count(*) 
     into t_row_count
     from lbl_space_metrics
     where division=t_dv_id;
     
     if (t_row_count=0) then
         insert into lbl_space_metrics
         (division, assigned_sf) 
         values
         (t_dv_id, t_assigned_sf);
     else
         update lbl_space_metrics set assigned_sf=t_assigned_sf where division=t_dv_id;
     end if;
        
 
  end loop;   -- div outer loop 
  
  execute immediate 'drop index i_em_idx1 ';
  execute immediate 'drop index i_em_idx2 ';
  
  execute immediate 'drop index i_rm_idx1 ';
  execute immediate 'drop index i_rm_idx2 ';


-- start calculating totals 
-- pass -1 
for totals_rec in totals_cur

 loop 
 
    update lbl_space_metrics
    set group1_total=nvl(totals_rec.group1_count,0)+nvl(totals_rec.group1_matin,0) - nvl(totals_rec.group1_matout,0),
        group1_totsqft=(nvl(totals_rec.group1_count,0)+nvl(totals_rec.group1_matin,0) - nvl(totals_rec.group1_matout,0)) *140,
        group2_total=nvl(totals_rec.group2_count,0)+nvl(totals_rec.group2_matin,0) - nvl(totals_rec.group2_matout,0),
        group2_totsqft=(nvl(totals_rec.group2_count,0)+nvl(totals_rec.group2_matin,0) - nvl(totals_rec.group2_matout,0)) *120,
        group3_total=nvl(totals_rec.group3_count,0)+nvl(totals_rec.group3_matin,0) - nvl(totals_rec.group3_matout,0),
        group3_totsqft=(nvl(totals_rec.group3_count,0)+nvl(totals_rec.group3_matin,0) - nvl(totals_rec.group3_matout,0)) *100,
        group4_total=nvl(totals_rec.group4_count,0)+nvl(totals_rec.group4_matin,0) - nvl(totals_rec.group4_matout,0),
        group4_totsqft=(nvl(totals_rec.group4_count,0)+nvl(totals_rec.group4_matin,0) - nvl(totals_rec.group4_matout,0)) *64,
        group5_total=nvl(totals_rec.group5_count,0)+nvl(totals_rec.group5_matin,0) - nvl(totals_rec.group5_matout,0),
        group5_totsqft=(nvl(totals_rec.group5_count,0)+nvl(totals_rec.group5_matin,0) - nvl(totals_rec.group5_matout,0)) *48,
        group6_total=nvl(totals_rec.group6_count,0)+nvl(totals_rec.group6_matin,0) - nvl(totals_rec.group6_matout,0),
        group6_totsqft=(nvl(totals_rec.group6_count,0)+nvl(totals_rec.group6_matin,0) - nvl(totals_rec.group6_matout,0)) *1,
        
        tot_matin=nvl(totals_rec.group1_matin,0) + nvl(totals_rec.group2_matin,0) + nvl(totals_rec.group3_matin,0)  + 
                  nvl(totals_rec.group4_matin,0) + nvl(totals_rec.group5_matin,0) + nvl(totals_rec.group6_matin,0) ,
                  
        tot_matout=nvl(totals_rec.group1_matout,0) + nvl(totals_rec.group2_matout,0) + nvl(totals_rec.group3_matout,0)  + 
                   nvl(totals_rec.group4_matout,0) + nvl(totals_rec.group5_matout,0) + nvl(totals_rec.group6_matout,0),
        changedate=sysdate
                   
        
    where division=totals_rec.division;
   end loop;

 -- pass -2    
 for totals_rec in totals_cur

  loop 
    update lbl_space_metrics
    set groups_total= nvl(totals_rec.group1_total,0) +nvl(totals_rec.group2_total,0) + nvl(totals_rec.group3_total,0) +
                      nvl(totals_rec.group4_total,0) + nvl(totals_rec.group5_total,0) + nvl(totals_rec.group6_total,0) ,
                      
        sqft_total = totals_rec.group1_totsqft + totals_rec.group2_totsqft + totals_rec.group3_totsqft + totals_rec.group4_totsqft 
                   + totals_rec.group5_totsqft + totals_rec.group6_totsqft,
                   
        util_factor=(totals_rec.group1_totsqft + totals_rec.group2_totsqft + totals_rec.group3_totsqft + totals_rec.group4_totsqft 
                     + totals_rec.group5_totsqft + totals_rec.group6_totsqft) * .10,
                     
        mod_reqd=(totals_rec.group1_totsqft + totals_rec.group2_totsqft + totals_rec.group3_totsqft + totals_rec.group4_totsqft 
                     + totals_rec.group5_totsqft + totals_rec.group6_totsqft) + 
                     ( (totals_rec.group1_totsqft + totals_rec.group2_totsqft + totals_rec.group3_totsqft + totals_rec.group4_totsqft 
                     + totals_rec.group5_totsqft + totals_rec.group6_totsqft) * .10),
                     
        diff_sqft=nvl(totals_rec.assigned_sf,0) - 
        ((totals_rec.group1_totsqft + totals_rec.group2_totsqft + totals_rec.group3_totsqft + totals_rec.group4_totsqft 
                     + totals_rec.group5_totsqft + totals_rec.group6_totsqft) + 
                     ( (totals_rec.group1_totsqft + totals_rec.group2_totsqft + totals_rec.group3_totsqft + totals_rec.group4_totsqft 
                     + totals_rec.group5_totsqft + totals_rec.group6_totsqft) * .10))
     where division=totals_rec.division;
  end loop;
 
 -- pass -3    
 for totals_rec in totals_cur

  loop    
      
     if (nvl(totals_rec.assigned_sf,0) > 0) then   
     
       update lbl_space_metrics      
       set under_over=(nvl(totals_rec.mod_reqd,0) -   nvl(totals_rec.assigned_sf,0))/totals_rec.assigned_sf
       where division=totals_rec.division;
       
     end if;
     
  end loop;
    
    
            
        
        



commit;
  
END;

/




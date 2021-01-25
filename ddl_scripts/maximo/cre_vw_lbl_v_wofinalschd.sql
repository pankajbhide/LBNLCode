-- Start of DDL Script for View MAXIMO.LBL_V_WOFINALSCHD
-- Generated 1/8/2021 12:22:15 PM from MAXIMO@MMOPRD

CREATE OR REPLACE VIEW lbl_v_wofinalschd2 (
   wonum,
   description,
   estdur,
   schedstart,
   schedfinish,
   location,
   fammanager,
   noofpeople )
BEQUEATH DEFINER
AS
Select W.WONUM,
--W.PARENT,W.STATUS,W.STATUSDATE,W.WORKTYPE,W.LEADCRAFT,
W.DESCRIPTION,
--W.LOCATION,W.JPNUM,
W.ESTDUR,--W.PMNUM,
--W.TARGCOMPDATE,W.TARGSTARTDATE,
W.SCHEDSTART,
W.SCHEDFINISH,
W.LOCATION,
P.DisplayName as FAMManager,
(select sum(wp.quantity) from maximo.wplabor wp where wp.wonum=w.wonum)
--,W.SUPERVISOR,W.ORGID,W.SITEID,W.ISTASK,W.ASSETNUM,W.WORKORDERID,W.LBL_RELEASE_STATUS,W.LBL_PLANNER,W.SNECONSTRAINT,W.FNLCONSTRAINT,W.LBL_FAMMANAGER, 
--&SelectFields&                                              
--P.DisplayName as FAMManagerDisplayName, S.DisplayName as SupervisorDisplayName, tp.DisplayName as DefaultPlannerName,  

/*case when l.SCOPE_OF_WORK is null then w.description
else  l.SCOPE_OF_WORK
end as SCOPE_OF_WORK,

case when w.worktype like 'PM%' then w.description else l.Scope_Of_Work end as CombinedDescription,
case when w.worktype = 'PROJ' then 'PROJECTS'
     when w.worktype = 'PM' then 'PMs'
     when w.worktype = 'PM-C' then 'COORD PMs'
     when w.worktype = 'PM-CC' then 'Code Complaint PMs'
else 'CMR, Etc'
end as WorkTypeText,
case when w.targstartdate is not null and w.lbl_release_status in ('RELEASED','WAITING RELEASE')  then w.targstartdate else w.sneconstraint end as "__Sched_StartNoEarlierThan",
case when w.targcompdate is not null and w.lbl_release_status in ('RELEASED','WAITING RELEASE')  then w.targcompdate else w.fnlconstraint end as "__Sched_FinishNoLaterThan"     */                                                                                                     
FROM (
        select * From workorder WT
        where ((wt.istask = 0 and wt.worktype like 'PM%') or (wt.worktype not like 'PM%')) and exists
        (
                Select * From WOAncestor A
                Where Exists
                        (Select * From WorkOrder W Where
                                (
                                  (
                                  schedstart between 
                                  (select (sysdate- live_relative_days_from)  from  solufy.sol_schedule_info where name='Final Schedule')
                                 -- (select x.fromdate from solufy.sol_schedulebaseline x where x.baselinedate=(select max(y.baselinedate) from solufy.sol_schedulebaseline y where y.baselinetype='Lock')  )
                                   and 
                                 -- (select x.todate from solufy.sol_schedulebaseline x where x.baselinedate=(select max(y.baselinedate) from solufy.sol_schedulebaseline y where y.baselinetype='Lock'))         
                                 (select (sysdate+ live_relative_days_to)  from  solufy.sol_schedule_info where name='Final Schedule')

      
                                  ) OR
                                  (schedfinish between
                                    (select (sysdate- live_relative_days_from)  from  solufy.sol_schedule_info where name='Final Schedule')

                                  --(select x.fromdate from solufy.sol_schedulebaseline x where x.baselinedate=(select max(y.baselinedate) from solufy.sol_schedulebaseline y where y.baselinetype='Lock')  )
                                   and 
                                  --(select x.todate from solufy.sol_schedulebaseline x where x.baselinedate=(select max(y.baselinedate) from solufy.sol_schedulebaseline y where y.baselinetype='Lock'))       
                                    (select (sysdate+ live_relative_days_to)  from  solufy.sol_schedule_info where name='Final Schedule')

      
                                  )
                                 
                                )  
                                AND W.Parent IS NULL  AND W.Wonum = A.Ancestor
                               -- &Filter& 
                                 AND (( (W.STATUS in ('REL','ASSIGNED','SCHD','APPR','WREL','INPRG','WASSIGN')) 
                                 AND  (W.LEADCRAFT in ('FAOMG','FAOMH','FAOML','FAOMP','FAOMP1','FAOMP2','FAOMP3','FATSC','FATSD','FATSE','FATSE1','FATSE2','FATSF',
                                 'FATSH','FATSL','FATSP','FATSR','FMCS','VENDOR'))  AND  (W.SITEID ='FAC') ) )  /*EndFilter*/
                        )  And A.WONum = WT.WONum
        )                
)  W
LEFT JOIN Person p on W.LBL_FAMManager = P.Personid
LEFT JOIN Person s on W.Supervisor = s.Personid
LEFT JOIN MAXIMO.LBL_WOWKTHRU l on w.siteid = l.siteid and w.wonum = l.wonum
LEFT JOIN PersonGroupTeam t on w.LBL_PLANNER_GROUP = t.PersonGroup and t.GroupDefault = 1
LEFT JOIN Person tp on t.RespPartyGroup = tp.personid
/

-- Grants for View
GRANT SELECT ON lbl_v_wofinalschd2 TO public
/

-- End of DDL Script for View MAXIMO.LBL_V_WOFINALSCHD2


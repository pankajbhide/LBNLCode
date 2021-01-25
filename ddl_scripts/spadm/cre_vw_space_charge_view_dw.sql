CREATE OR REPLACE VIEW space_charge_view_dw (
   transaction_dt,
   location,
   locality,
   report_category,
   org_level_1_code,
   org_level_2_code,
   org_level_3_code,
   org_level_4_code,
   fiscal_year,
   accounting_period,
   building_number,
   floor_number,
   room_number,
   use,
   detail,
   occupied_area,
   occupied_area_metric,
   charged_to_percent,
   adjusted_area,
   adjusted_area_metric,
   monetary_amount,
   proj_act_id,
   project_id,
   activity_id,
   old_project_id,
   area,
   occupied_percent,
   assignment_status,
   inactive,
   chargeable,
   lbl_pi,
   lbl_comments,
   count_em,
   cap_em )
BEQUEATH DEFINER
AS
select a.transaction_dt,
       a.location,
       a.locality,
       a.report_category,
       a.org_level_1_code,
       a.org_level_2_code,
       a.org_level_3_code,
       a.org_level_4_code,
       a.fiscal_year,
       a.accounting_period,
       a.building_number,
       a.floor_number,
       a.room_number,
       a.use,
       a.detail,
       a.occupied_area,
       a.occupied_area_metric,
       a.charged_to_percent,
       a.adjusted_area,
       a.adjusted_area_metric,
       a.monetary_amount,
       nvl(a.proj_act_id,' ') as proj_act_id,
       nvl(substr(a.proj_act_id,1,6),' ') as project_id,
       nvl(substr(a.proj_act_id,8,3),' ') as activity_id,
       nvl(a.project_id,' ') as old_project_id,
       a.area,
       a.occupied_percent,
       a.assignment_status,
       a.inactive,
       a.chargeable,
       a.lbl_pi,
       a.lbl_comments,
       a.count_em,
       a.cap_em
 from (

-- Get historical space data details and project/charge data details
-- snapshot of space data is taken monthly per maximo.financialperiods table
SELECT ALL
h.transaction_dt,
h.LOCATION,
h.locality,
h.report_category,
c.PROJECT_ID,
h.org_level_1_code,
h.org_level_2_code,
h.org_level_3_code,
h.org_level_4_code,
to_number(substr(f.financialperiod,1,4)) as fiscal_year,
to_number(substr(f.financialperiod,5,2)) as accounting_period,
h.BUILDING_NUMBER,
h.FLOOR_NUMBER,
h.ROOM_NUMBER,
h.CURRENT_USE USE,
h.CURRENT_USE_DETAIL DETAIL,
h.AREA*(h.OCCUPIED_PERCENT/100) OCCUPIED_AREA,
round(h.AREA*(h.OCCUPIED_PERCENT/100)*0.0929,2) OCCUPIED_AREA_METRIC,
c.CHARGED_TO_PERCENT,
round(h.AREA*(h.OCCUPIED_PERCENT/100)*(c.CHARGED_TO_PERCENT/100),2) adjusted_area,
round(h.AREA*(h.OCCUPIED_PERCENT/100)*
(c.CHARGED_TO_PERCENT/100)*0.0929,2) ADJUSTED_AREA_METRIC,
c.MONETARY_AMOUNT,
c.proj_act_id,
h.AREA,
h.OCCUPIED_PERCENT,
h.assignment_status,
to_number(h.inactive) inactive,
h.chargeable,
h.lbl_pi,
h.lbl_comments,
h.count_em,
h.cap_em
FROM spadm.SPACE_CHARGE_TRANS_DETAIL c,
     spadm.SPACE_HISTORICAL_INFO h,
     maximo.financialperiods f
where c.transaction_dt(+) = h.transaction_dt
and c.location(+) = h.location
and h.transaction_dt between f.periodstart and f.periodend

UNION ALL

-- Get current space data details
select
null as transaction_dt,
r.location,
b.locality,
b.report_category,
d.project_id,
r.org_level_1_code,
r.org_level_2_code,
r.org_level_3_code,
r.org_level_4_code,
to_number(substr(f2.financialperiod,1,4)) fiscal_year,
to_number(substr(f2.financialperiod,5,2)) accounting_period,
r.building_number,
r.floor_number,
r.room_number,
r.LBL_RMCAT use,
SUBSTR(r.LBL_RMTYPE,INSTR(r.LBL_RMTYPE,'-')+1) detail,
r.AREA*(r.OCCUPIED_PERCENT/100) occupied_area,
round(r.AREA*(r.OCCUPIED_PERCENT/100)*0.0929,2) occupied_area_metric,
d.charged_to_percent,
round(r.AREA*(r.OCCUPIED_PERCENT/100)*(d.CHARGED_TO_PERCENT/100),2) adjusted_area,
round(r.AREA*(r.OCCUPIED_PERCENT/100)*(d.CHARGED_TO_PERCENT/100)*0.0929,2) adjusted_area_metric,
round(space_package.get_recharge_rate(r.current_use,b.report_category)*r.AREA*r.OCCUPIED_PERCENT/100*d.CHARGED_TO_PERCENT/100,2) monetary_amount,
d.proj_act_id,
r.AREA,
r.OCCUPIED_PERCENT,
r.assignment_status,
r.inactive,
r.chargeable,
ac.lbl_pi,
ac.lbl_comments,
ac.count_em,
ac.cap_em
from spadm.space_charge_distribution d,
     spadm.space_room r,
     spadm.space_building b,
     maximo.financialperiods f2,
     afm.rm@archibus23 ac
where d.building_number(+) = r.building_number
and d.floor_number(+) = r.floor_number
and d.room_number(+) = r.room_number
and r.building_number = b.building_number
and r.building_number=ac.bl_id
and r.floor_number=ac.fl_id
and r.room_number=ac.rm_id
and f2.financialperiod=(select min(f3.financialperiod)
                        from maximo.financialperiods f3
                        where nvl(closedby,' ') not like '%SPA01%')
) a
/

-- Grants for View
GRANT SELECT ON space_charge_view_dw TO public
/
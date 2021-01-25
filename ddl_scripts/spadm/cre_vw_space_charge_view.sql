-- Start of DDL Script for View SPADM.SPACE_CHARGE_VIEW
-- Generated 11-Sep-2017 12:15:15 from SPADM@MMODEV

CREATE OR REPLACE VIEW space_charge_view (
   location,
   locality,
   report_category,
   project_id,
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
   lbl_pi,   -- JIRA EF- 6544 
   count_em,
   cap_em,
   lbl_comments
    )
AS
SELECT ALL
SPACE_HISTORICAL_INFO.LOCATION,
space_historical_info.locality,
space_historical_info.report_category,
SPACE_CHARGE_TRANS_DETAIL.PROJECT_ID,
space_historical_info.org_level_1_code,
space_historical_info.org_level_2_code,
space_historical_info.org_level_3_code,
space_historical_info.org_level_4_code,
SPACE_CHARGE_TRANS_DETAIL.FISCAL_YEAR,
SPACE_CHARGE_TRANS_DETAIL.ACCOUNTING_PERIOD,
SPACE_CHARGE_TRANS_DETAIL.BUILDING_NUMBER,
SPACE_CHARGE_TRANS_DETAIL.FLOOR_NUMBER,
SPACE_CHARGE_TRANS_DETAIL.ROOM_NUMBER,
SPACE_HISTORICAL_INFO.CURRENT_USE USE,
SPACE_HISTORICAL_INFO.CURRENT_USE_DETAIL DETAIL,
SPACE_HISTORICAL_INFO.AREA*(SPACE_HISTORICAL_INFO.OCCUPIED_PERCENT/100) OCCUPIED_AREA,
round(SPACE_HISTORICAL_INFO.AREA*(SPACE_HISTORICAL_INFO.OCCUPIED_PERCENT/100)*0.0929,2) OCCUPIED_AREA_METRIC,
SPACE_CHARGE_TRANS_DETAIL.CHARGED_TO_PERCENT,
round(SPACE_HISTORICAL_INFO.AREA*(SPACE_HISTORICAL_INFO.OCCUPIED_PERCENT/100)*(SPACE_CHARGE_TRANS_DETAIL.CHARGED_TO_PERCENT/100),2) adjusted_area,
round(SPACE_HISTORICAL_INFO.AREA*(SPACE_HISTORICAL_INFO.OCCUPIED_PERCENT/100)*
(SPACE_CHARGE_TRANS_DETAIL.CHARGED_TO_PERCENT/100)*0.0929,2) ADJUSTED_AREA_METRIC,
SPACE_CHARGE_TRANS_DETAIL.MONETARY_AMOUNT,
SPACE_CHARGE_TRANS_DETAIL.proj_act_id,
SPACE_HISTORICAL_INFO.lbl_pi,   -- JIRA EF- 6544 
SPACE_HISTORICAL_INFO.count_em,
SPACE_HISTORICAL_INFO.cap_em,
SPACE_HISTORICAL_INFO.lbl_comments
FROM SPACE_CHARGE_TRANS_DETAIL, SPACE_HISTORICAL_INFO
where space_charge_trans_detail.transaction_dt = space_historical_info.transaction_dt
and space_charge_trans_detail.location = space_historical_info.location
--and space_historical_info.inactive='N'
and space_historical_info.inactive=0
and space_historical_info.chargeable='Y'
union
select
space_room.location,
space_building.locality,
space_building.report_category,
space_charge_distribution.project_id,
space_room.org_level_1_code,
space_room.org_level_2_code,
space_room.org_level_3_code,
space_room.org_level_4_code,
--iss.current_fiscal_year fiscal_year,
--iss.current_fiscal_month accounting_period,
to_number(substr(a.financialperiod,1,4)) fiscal_year,
to_number(substr(a.financialperiod,5,2)) accounting_period,
space_charge_distribution.building_number,
space_charge_distribution.floor_number,
space_charge_distribution.room_number,

-- JIRA EF-3898 
--space_room.current_use use,
--space_room.current_use_detail detail,

space_room.LBL_RMCAT use,
SUBSTR(SPACE_ROOM.LBL_RMTYPE,INSTR(SPACE_ROOM.LBL_RMTYPE,'-')+1) detail, 

space_room.AREA*(SPACE_room.OCCUPIED_PERCENT/100) occupied_area,
round(space_room.AREA*(SPACE_room.OCCUPIED_PERCENT/100)*0.0929,2) occupied_area_metric,
space_charge_distribution.charged_to_percent,
round(space_room.AREA*(SPACE_room.OCCUPIED_PERCENT/100)*(SPACE_charge_distribution.CHARGED_TO_PERCENT/100),2) adjusted_area,
round(space_room.AREA*(SPACE_room.OCCUPIED_PERCENT/100)*(SPACE_charge_distribution.CHARGED_TO_PERCENT/100)*0.0929,2) adjusted_area_metric,
round(space_package.get_recharge_rate(space_room.current_use,
space_building.report_category)*
space_room.AREA*SPACE_room.OCCUPIED_PERCENT/100*SPACE_charge_distribution.CHARGED_TO_PERCENT/100
,2) monetary_amount,
space_charge_distribution.proj_act_id,
ac.lbl_pi,   -- JIRA EF- 6544 
ac.count_em,
ac.cap_em,
ac.lbl_comments
from space_charge_distribution, space_room, space_building, maximo.financialperiods a, afm.rm@archibus23 ac
where space_charge_distribution.building_number = space_room.building_number
and space_charge_distribution.floor_number = space_room.floor_number
and space_charge_distribution.room_number = space_room.room_number
and space_room.building_number = space_building.building_number
and space_room.building_number=ac.bl_id
and space_room.floor_number=ac.fl_id
and space_room.room_number=ac.rm_id
--and space_room.inactive='N'
and space_room.inactive=0
and space_room.chargeable='Y'
and a.financialperiod=(select min(b.financialperiod) from maximo.financialperiods b
where nvl(closedby,' ') not like '%SPA01%')
/

-- Grants for View
GRANT SELECT ON space_charge_view TO public
/

-- End of DDL Script for View SPADM.SPACE_CHARGE_VIEW


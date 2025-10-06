create or replace table rna_limit.trading__mirror_locker_identification
as 
--withdrawals and deposits

with 
depo_info as (
select 
  user_uid
, sum(deposit_ext_sum_usd_amt) as deposit_ext_sum_usd_amt --Succeeded EXTERNAL Deposit USD
, sum(deposit_ext_cnt) as deposit_ext_cnt                 --Succeeded EXTERNAL Deposit COUNT
, sum(deposit_int_sum_usd_amt) as deposit_int_sum_usd_amt --Succeeded INTERNAL Deposit USD (transfer from another user)
, sum(deposit_int_cnt) as deposit_int_cnt                 --Succeeded INTERNAL Deposit COUNT (transfer from another user)
, sum(withdrawal_ext_sum_usd_amt) as withdrawal_ext_sum_usd_amt --Succeeded EXTERNAL Withdrawal USD
, sum(withdrawal_ext_cnt) as withdrawal_ext_cnt                 --Succeeded EXTERNAL Withdrawal COUNT
, sum(withdrawal_int_sum_usd_amt) as withdrawal_int_sum_usd_amt --Succeeded INTERNAL Withdrawal USD (transfer from another user)
, sum(withdrawal_int_cnt) as withdrawal_int_cnt                 --Succeeded INTERNAL Withdrawal COUNT (transfer from another user)
-------https://confluence.exness.io/display/BI/dm.user_balance_d_agg

from dm.user_balance_d_agg bal
where 1=1 
and fact_date >= '2022-05-01'::date
and fact_date <= '2022-05-11'::date
group by user_uid

), 

-----------------------------------------------------------------------------------
---- trade information

trade_aggs as (
select 
  user_uid
, sum(volume_closed_usd) as sum_volume_closed_usd
, sum(profit_usd) as profit_usd
---
, sum(volume) as sum_volume_closed_lot  -- Order volume in lots. (warning) One unit corresponds to 1/100 lot (warning)
, max(volume) as max_volume_closed_lot  -- Order volume in lots. (warning) One unit corresponds to 1/100 lot (warning)
, count(volume_closed_usd) as cnt_orders_closed
, count(case when volume <= 100 then 1 else Null end) as cnt_closed_orders_less_1_lot  -- Order volume in lots. (warning) One unit corresponds to 1/100 lot (warning)

from 
  public.orders_mt4 a
-------------- https://confluence.exness.io/display/BI/stg.orders_mt4
 
where 1 = 1
  and date(a.close_time) >= '2022-05-11' 
  and date(a.close_time) < '2022-05-12'
  and a.cmd in (0, 1, 2, 3, 4, 5, 6) 
  and a.volume_closed_usd is not Null

group by user_uid

union ALL 

select 
  user_uid
, sum(volume_closed_usd) as sum_volume_closed_usd
, sum(profit_usd) as profit_usd
---
, sum(volume_closed) as sum_volume_closed_lot  -- Order volume in lots. (warning) One unit corresponds to 1/100 lot (warning)
, max(volume_closed) as max_volume_closed_lot  -- Order volume in lots. (warning) One unit corresponds to 1/100 lot (warning)
, count(volume_closed_usd) as cnt_orders_closed
, count(case when volume_closed >= 100 then 1 else Null end) as cnt_closed_orders_less_1_lot  -- Order volume in lots. (warning) One unit corresponds to 1/100 lot (warning)


from 
  public.deals_mt5 dmt5
----------------https://confluence.exness.io/display/BI/stg.deals_mt5
  
where 1 = 1
  and date(dmt5.time) >= '2022-05-11'
  and date(dmt5.time) < '2022-05-12'
  and dmt5.action in (0, 1)
  and dmt5.entry in (1)

group by user_uid
),

total_aggs as (
select 
  user_uid
, round(sum(sum_volume_closed_usd), 2) as sum_volume_closed_usd
, round(sum(profit_usd), 2) as profit_usd
---
, sum(sum_volume_closed_lot) as sum_volume_closed_lot  
, max(max_volume_closed_lot) as max_volume_closed_lot  
, sum(cnt_orders_closed) as cnt_orders_closed
, sum(cnt_closed_orders_less_1_lot) as cnt_closed_orders_less_1_lot

from trade_aggs
group by user_uid

)

select total_aggs.*
, deposit_ext_sum_usd_amt --Succeeded EXTERNAL Deposit USD
, deposit_ext_cnt                 --Succeeded EXTERNAL Deposit COUNT
, deposit_int_sum_usd_amt --Succeeded INTERNAL Deposit USD (transfer from another user)
, deposit_int_cnt                 --Succeeded INTERNAL Deposit COUNT (transfer from another user)
, withdrawal_ext_sum_usd_amt --Succeeded EXTERNAL Withdrawal USD
, withdrawal_ext_cnt                 --Succeeded EXTERNAL Withdrawal COUNT
, withdrawal_int_sum_usd_amt --Succeeded INTERNAL Withdrawal USD (transfer from another user)
, withdrawal_int_cnt                 --Succeeded INTERNAL Withdrawal COUNT (transfer from another user)

from total_aggs

left join depo_info
on depo_info.user_uid = total_aggs.user_uid

-------------

--select * from rna_limit.trading__mirror_locker_identification
create or REPLACE  view rna_limit.trading__v_mirror_lockers_result
as
with 
mid_data as (
select
  case 
 	when cnt_orders_closed != 0 and sum_volume_closed_lot/cnt_orders_closed > max_volume_closed_lot 
 	then sum_volume_closed_lot/cnt_orders_closed
 	else max_volume_closed_lot
  end as past_24_hr_max 
, case 
	when deposit_ext_sum_usd_amt + deposit_int_sum_usd_amt != 0
	then profit_usd/(deposit_ext_sum_usd_amt + deposit_int_sum_usd_amt) 
	else 0
  end as profit_coef
, cnt_closed_orders_less_1_lot as over_1_coef
--, ' ' as sep_col
, t1.*
from rna_limit.trading__mirror_locker_identification as t1
)

select 
  CASE 
	 when past_24_hr_max >= 31 
	     and (profit_coef >= 0.79 or profit_coef <= -0.49)
	     and over_1_coef <= 6
	 then 'high'
	 
	 when past_24_hr_max >= 11 
	     and (profit_coef >= 0.49 or profit_coef <= -0.39)
	     and over_1_coef <= 9
	 then 'medium'
	 else 'low'
  end as possibility_error
, mid_data.*

from mid_data


--
select *
from rna_limit.trading__v_mirror_lockers_result
where possibility_error = 'high'



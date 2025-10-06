---первые два непустых uuid выглядят подходящими

select count(1), uuid  from research.mms_response_events mre where comment = 'margin no money (precheck)'
and date = '2022-10-21'
group by uuid
order by count(1) desc

--04504363-7d54-40da-b75e-0e32467daac5
--737eab28-4ac6-4d24-8a2c-7f1f515914bc

------
select 
    mt4.user_uid as user_uid
  , account_currency
  , mt4.symbol as symbol
  , volume
  , cmd
  , open_price
  , toDateTime(open_time) as deal_time
  , toStartOfDay(toDateTime(open_time)) as dt
  , close_price
  , close_price - open_price as price_change
  , profit
  , open_time
  , close_time
  , (close_time - open_time) as duration_sec
  , close_xr_account_currency_to_usd
  , spread_revenue_usd
  , open_xr_account_currency_to_usd
   from xdata.trade_mt4_extra_full mt4 
   where 1=1
--   and open_time is not NULL
--   and close_time is not NULL
--   and close_time != 0
   and cmd in (0,1)
   and open_time >= toDateTime('2022-09-01 00:00:00')
   and user_uid in ('04504363-7d54-40da-b75e-0e32467daac5', '737eab28-4ac6-4d24-8a2c-7f1f515914bc')
 order by user_uid, open_time
   
---
 
with 
woody as (
select uuid,
 count(1) as cnt,
 row_number() over(order by cnt desc) as rn
from research.mms_response_events mre 
where comment = 'margin no money (precheck)'
  and date = '2022-10-21'
group by uuid
order by count(1) desc
)
select 
    mt4.user_uid as user_uid
  , rn
    -- , toStartOfMonth(toDateTime(open_time)) as dt
  , sum(profit) as profit
   from xdata.trade_mt4_extra_full mt4 
   join woody w on mt4.user_uid = w.uuid and w.rn<20
   where 1=1
--   and open_time is not NULL
--   and close_time is not NULL
--   and close_time != 0
   and cmd in (0,1)
   and open_time >= toDateTime('2021-01-01 00:00:00')
   and user_uid in (select uuid from woody where rn <= 20)
group by user_uid, rn      --, dt
order by rn --, dt   
 
  
--------
---- woodpeckers
----
----
select response_result, comment, count(*) as cnt
from research.mms_response_events mre 
where 1=1
  and response_result in  (2)
  --and comment = 'margin no money (precheck)'
  and date = '2022-10-21'
  --and uuid in ('04504363-7d54-40da-b75e-0e32467daac5', '737eab28-4ac6-4d24-8a2c-7f1f515914bc')
group by response_result, comment
order by cnt desc
--  order by uuid, login, request_time 

--------

with base_table as (
	select uuid
	, login 
	, comment
	, request_time
	, lagInFrame(comment) over (partition by uuid, login order by request_time) as prev_comment
	from research.mms_response_events mre 
	where 1=1--comment = 'margin no money (precheck)'
	  and date = '2022-10-21'
	  --and login not in (100504962)
	  --and uuid in ('04504363-7d54-40da-b75e-0e32467daac5', '737eab28-4ac6-4d24-8a2c-7f1f515914bc')
),
swap as (
select uuid
	, login 
	, comment
	, request_time
	, prev_comment
	, sum(case when comment=prev_comment and comment = 'margin no money (precheck)' then 1 else 0 end) over(partition by uuid, login order by request_time) as incidents
from base_table
)
select uuid
 , login
 , max(incidents) as max_incidents
from swap
group by uuid, login
having max_incidents > 100
order by max_incidents desc

-----

---- пытаемся найти инциденты и их количество



select login 
  , sum(case when response_result= 2 then 1 else 0 end) as cnt_reset_req
  , sum(1) as cnt_req
  , cnt_reset_req/cnt_req as part_reset_req
from research.mms_response_events mre 
where 1=1
  --and response_result = 2
  and date = '2022-10-21'
  and uuid != ''
group by login
having cnt_reset_req > 10
order by part_reset_req desc, cnt_reset_req desc
--, response_result, comment
--  order by uuid, login, request_time 

---------
select toDateTime(request_time/1e3), toDateTime(request_time /1e3) - 60, * 
from research.mms_response_events mre
-----

with logins as (

select
    toStartOfMinute(toDateTime(request_time/1e3)) as scoring_time
--  , comment
  , login 
  , sum(case when response_result= 2 then 1 else 0 end) as cnt_reset_req
  , sum(1) as cnt_req
  , cnt_reset_req/cnt_req as part_reset_req
from research.mms_response_events mre 
where 1=1
  and response_result in (1,2,3)
  and date = '2022-10-21'
  and uuid != ''
group by     
    scoring_time
--  , comment
  , login 
having cnt_reset_req > 1 --and part_reset_req < 1

)
--select count(distinct login) from login
select scoring_time
, comment
, count(login) as cnt_logins
from logins
group by scoring_time, comment
order by scoring_time
--order by scoring_time, part_reset_req desc, cnt_reset_req desc

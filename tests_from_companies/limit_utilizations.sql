--select * from rna_limit.trading_limit_utilization_2022_05_20 limit 100
-- select symbol, count(*) from rna_limit.trading_limit_utilization_2022_05_20 group by symbol order by count(*)

-- drop table rna_limit.trading_limit_utilization_2022_05_20
create table rna_limit.trading_limit_utilization_2022_05_20 as

with start_point as 
-- take period before zero point
-- marked all rows as last minute timestamp of this period
-- 
(select 
  user_uid
, '2022-01-10 23:59:0000'::timestamp as date_deal
, symbol
, case when cmd in (0, 2, 4) then 'buy' else 'sell' end as first_deal_way
, sum(case when cmd in (0, 2, 4) then volume_opened_usd else -volume_opened_usd end) as volume_opened_usd
, 0 as start_profit
from 
  public.orders_mt4 a
 
where 1 = 1
  and date(a.open_time) >= '2022-01-01' 
  and date(a.open_time) < '2022-01-11'
  and a.cmd in (0, 1, 2, 3, 4, 5, 6) 
  and date(a.close_time) >= '2022-01-11'
  and symbol in ('AUS200','US30','FR40','DE30','HK50','JP225','USTEC','US500','STOXX50','UK100')

group by user_uid, date_deal, symbol, first_deal_way

union ALL 

select 
  user_uid
, '2022-01-10 23:59:0000'::timestamp as date_deal
, symbol
, case 
	when entry = 0 and action = 0  then 'buy' 
	when entry = 0 and action = 1  then 'sell' 
	when entry = 1 and action = 0  then 'sell' 
	when entry = 1 and action = 1  then 'buy'  
  end as first_deal_way
, sum(case 
	when entry = 0 and action = 0  then volume_usd  
	when entry = 0 and action = 1  then volume_usd  
	when entry = 1 and action = 0  then - volume_usd - profit_usd 
	when entry = 1 and action = 1  then - volume_usd - profit_usd  
  end)  as volume_usd
, 0 as start_profit
from 
  public.deals_mt5 dmt5
 
where 1 = 1
  and date(dmt5.time) >= '2022-01-01'
  and date(dmt5.time) < '2022-01-11'
  and symbol in ('AUS200','US30','FR40','DE30','HK50','JP225','USTEC','US500','STOXX50','UK100')
  and dmt5.action in (0, 1)
  and dmt5.entry in (0, 1)

group by user_uid, date_deal, symbol, first_deal_way
),

next_deals AS 
(
select 
  user_uid
, a.open_time
, symbol
, case when cmd in (0, 2, 4) then 'buy' else 'sell' end as first_deal_way
, case when cmd in (0, 2, 4) then volume_opened_usd else -volume_opened_usd end as volume_opened_usd
, 0 
from 
  public.orders_mt4 a
 
where 1 = 1
  and date(a.open_time) >= '2022-01-11' 
  and a.cmd in (0, 1, 2, 3, 4, 5, 6) 
  and symbol in ('AUS200','US30','FR40','DE30','HK50','JP225','USTEC','US500','STOXX50','UK100')
  
  union ALL 
  
  select 
  user_uid
, a.close_time 
, symbol
, case when cmd in (0, 2, 4) then 'buy' else 'sell' end as first_deal_way
, case when cmd in (0, 2, 4) then -volume_opened_usd else volume_opened_usd end as volume_opened_usd
, profit_usd 
from 
  public.orders_mt4 a
 
where 1 = 1
  and date(a.open_time) >= '2022-01-11' 
  and a.close_time is not Null 
  and a.cmd in (0, 1, 2, 3, 4, 5, 6) 
  and symbol in ('AUS200','US30','FR40','DE30','HK50','JP225','USTEC','US500','STOXX50','UK100')

--CMD - Trade Command Types
--0	OP_BUY A market Buy order.
--1	OP_SELL A market Sell order.
--2	OP_BUY_LIMIT A pending Buy Limit order.
--3	OP_SELL_LIMIT A pending Sell Limit order.
--4	OP_BUY_STOP A pending Buy Stop order.
--5	OP_SELL_STOP A pending Sell Stop order. 
  
union ALL 

select 
  user_uid
, dmt5.time as date_deal
, symbol
, case 
	when entry = 0 and action = 0  then 'buy' 
	when entry = 0 and action = 1  then 'sell' 
	when entry = 1 and action = 0  then 'sell' 
	when entry = 1 and action = 1  then 'buy'  
  end as first_deal_way
, case 
	when entry = 0 and action = 0  then volume_usd  
	when entry = 0 and action = 1  then volume_usd  
	when entry = 1 and action = 0  then - volume_usd - profit_usd 
	when entry = 1 and action = 1  then - volume_usd - profit_usd  
  end  as volume_usd
, 0 as start_profit
from 
  public.deals_mt5 dmt5
 
where 1 = 1
  and date(dmt5.time) >= '2022-01-11'
  and symbol in ('AUS200','US30','FR40','DE30','HK50','JP225','USTEC','US500','STOXX50','UK100')
  and dmt5.action in (0, 1)
  and dmt5.entry in (0, 1)
),

concat_rows as 
(
select *
from 
	(select * from start_point
	union all
	select * from next_deals) as main

),

uid_seg as (
select 
  user_uid
, trading_date 
, max(client_value_segment_ccode) as segment
from 
  rptbi.sse_trading_dm_rpt
where 1=1
  and trading_date >= '2022-01-01'
  and client_value_segment_ccode in ('0','1','2','3','4','5')
group by user_uid, trading_date 
)


select base.*
, Sum(volume_opened_usd) 
  OVER(partition BY base.user_uid, symbol
           ORDER BY date_deal ASC rows UNBOUNDED PRECEDING ) as cumsum
, Sum(volume_opened_usd) 
  OVER(partition BY base.user_uid, symbol, first_deal_way
           ORDER BY date_deal ASC rows UNBOUNDED PRECEDING ) as cumsum_way
, uid_seg.segment
from concat_rows base

left join uid_seg 
  on uid_seg.user_uid = base.user_uid 
  and uid_seg.trading_date = date(base.date_deal)

order by base.user_uid, symbol, date_deal, first_deal_way



with raw_data as (
select
  regexp_replace(symbol, '[empkfzc]$', '') as symbol_reg
, contract_size
, case
    when dm.entry = 0 
    then (symbol_ask - symbol_bid) / power(0.1, Digits-1) 
    else null
  end as spread_pips
, case 
	when dm.entry = 0
	then round((symbol_ask - symbol_bid) * (contract_size * xr_quote_currency_to_usd), 2)
	else null
  end as spread_usd
, volume_usd
from public.deals_mt5 dm
where date(dm.time) >= '2022-04-01'
and date(dm.time) < '2022-04-15'
AND regexp_replace(symbol, '[empkfzc]$', '') IN ('XAUUSD','EURUSD','GBPUSD','USDJPY','GBPJPY','BTCUSD','USOIL','USDCAD','GBPAUD','AUDUSD')
and dm.action in (0, 1)
and symbol_ask != symbol_bid
and dm.entry in (0, 1, 3)
--limit 100

union all 

--from mt4
select  
  regexp_replace(symbol,'[empkfzc]$', '') as symbol_reg
, contract_size
, (open_symbol_ask - open_symbol_bid) / power(0.1, Digits-1) as spread_pips
, round((open_symbol_ask - open_symbol_bid) * (contract_size * open_xr_quote_currency_to_usd), 2) as spread_usd
, volume_opened_usd + volume_closed_usd as volume_usd
from public.orders_mt4 om 
where date(om.open_time) >= '2022-04-01'
and date(om.open_time) < '2022-04-15'
AND regexp_replace(symbol,'[empkfzc]$', '') IN ('XAUUSD','EURUSD','GBPUSD','USDJPY','GBPJPY','BTCUSD','USOIL','USDCAD','GBPAUD','AUDUSD')
and om.cmd in (0, 1)
and open_symbol_ask != open_symbol_bid
--limit 100
)

select 
  symbol_reg
, case when contract_size = 1000 and symbol_reg != 'USOIL' then 'cent' else 'standart' end as type_account
, contract_size
, sum(volume_usd) as tv_sum
, avg(spread_pips) as avg_spread_pip
, approximate_percentile(spread_pips using parameters percentile = 0.80) as spread_pip_80_perc
, approximate_percentile(spread_pips using parameters percentile = 0.95) as spread_pip_95_perc
, avg(spread_usd) as avg_spread_usd
, approximate_percentile(spread_usd using parameters percentile = 0.80) as spread_usd_80_perc
, approximate_percentile(spread_usd using parameters percentile = 0.95) as spread_usd_95_perc

from  raw_data

group by 1,2 
order by tv_sum




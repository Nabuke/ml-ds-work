with ('XAUUSD','GBPUSD','EURUSD','USDJPY'
,'GBPJPY','BTCUSD','USOIL','USDCAD'
,'USDCHF','GBPAUD','AUDUSD','EURJPY'
,'US30','EURAUD','AUDCAD','USTEC'
,'EURGBP','AUDJPY','GBPNZD','GBPCAD') as symbols_need,
symbol_swaps as (
    select symbol||'m' as full_symbol, * from bi_sandbox.trading__swap_free_quotes
    union all
    select symbol||'c' as full_symbol, * from bi_sandbox.trading__swap_free_quotes
    union all
    select symbol||'z' as full_symbol, * from bi_sandbox.trading__swap_free_quotes
    union all
    select symbol||'r' as full_symbol, * from bi_sandbox.trading__swap_free_quotes
    union all
    select symbol||'p' as full_symbol, * from bi_sandbox.trading__swap_free_quotes
    union all
    select symbol||'e' as full_symbol, * from bi_sandbox.trading__swap_free_quotes
    union all
    select symbol as full_symbol, * from bi_sandbox.trading__swap_free_quotes
    ),
    clear_swap_free_profiles as
             (select uid,
                     argMax(muslim,updated) as muslim,
                     argMax(status,updated) as status,
                     toDate(updated) as updated_day
             from xdata.swap_free_profiles
             where updated >= toDateTime('2022-01-30 00:00:00')
             AND updated < toDateTime('2022-02-02 00:00:00')
             group by uid, updated_day
    ),
     full_tbl as (select
                        toDate(rollover_mt_time) as roll_date,
                        toDateTime(open_time) as new_open_time,
                        toDateTime(rollover_mt_time) as new_roll_time,
                        case  when action = 0 then 'Ask' when action = 1 then 'Bid' end as side,
                        *,
                        volume_lots,
                        to_usd
                 from xdata.charged_swaps_daily
                 where toDateTime(rollover_mt_time) >= toDateTime('2021-01-01 00:00:00')
                 AND toDateTime(rollover_mt_time) < toDateTime('2022-12-30 00:00:00')
                 and rollover_default_value_usd = 0
                   AND lower(server_name) like '%real%'
                 and symbol in symbols_need
    ),
     data_for_calc as (
     select roll_date,
            q.dt,
            new_open_time,
            new_roll_time,
            full_tbl.side,
            toYYYYMM(new_roll_time) as Year_month,
            full_tbl.user_uid,
            login,
            ticket,
            full_tbl.symbol as symbol,
--             q.full_symbol,
            status,
            muslim,
            rollover_default_value_usd,
            q.value as value,
            rollover_actual_value_usd,
            volume_lots,
            to_usd
         from full_tbl
         left join clear_swap_free_profiles
         on toUUID(full_tbl.user_uid) = clear_swap_free_profiles.uid and full_tbl.date = clear_swap_free_profiles.updated_day
         left join symbol_swaps q
         on toDate(q.dt) = full_tbl.roll_date
                and q.full_symbol = full_tbl.symbol
                and q.side = full_tbl.side
          where q.dt is not Null
         )
select symbol, count(*) from full_tbl
group by symbol


;
     select    Year_month,
               symbol,
               muslim,
               sum(abs(value) * volume_lots * to_usd) as swap_charged,
               sum(rollover_default_value_usd) as defaut_sum_usd,
               sum(rollover_actual_value_usd) as actual_sum_usd,
               (actual_sum_usd -defaut_sum_usd) as Swap_loss_usd
     from data_for_calc
     group by Year_month,
               symbol,
               muslim
--      having swap_charged > 0
--      order by  symbol,
--                Year_month,
--                muslim



----;


select distinct symbol
from bi_sandbox.trading__swap_free_quotes
where symbol in ((select distinct symbol
--                         toDate(rollover_mt_time) as roll_date,
--                         toDateTime(open_time) as new_open_time,
--                         toDateTime(rollover_mt_time) as new_roll_time,
--                         case  when action = 0 then 'Ask' when action = 1 then 'Bid' end as side,
--                         *,
--                         volume_lots,
--                         to_usd
                 from xdata.charged_swaps_daily
                 where toDateTime(rollover_mt_time) >= toDateTime('2022-01-25 00:00:00')
                 AND toDateTime(rollover_mt_time) < toDateTime('2022-02-02 00:00:00')
                 and rollover_default_value_usd = 0
                   AND lower(server_name) like '%real%'))

with ('XAUUSD','GBPUSD','EURUSD','USDJPY'
,'GBPJPY','BTCUSD','USOIL','USDCAD'
,'USDCHF','GBPAUD','AUDUSD','EURJPY'
,'US30','EURAUD','AUDCAD','USTEC'
,'EURGBP','AUDJPY','GBPNZD','GBPCAD') as symbols,
 unique_symbols as
(select distinct symbol
--                         toDate(rollover_mt_time) as roll_date,
--                         toDateTime(open_time) as new_open_time,
--                         toDateTime(rollover_mt_time) as new_roll_time,
--                         case  when action = 0 then 'Ask' when action = 1 then 'Bid' end as side,
--                         *,
--                         volume_lots,
--                         to_usd
                 from xdata.charged_swaps_daily
                 where toDateTime(rollover_mt_time) >= toDateTime('2021-01-01 00:00:00')
                 AND toDateTime(rollover_mt_time) < toDateTime('2022-02-30 00:00:00')
                 and rollover_default_value_usd = 0
                   AND lower(server_name) like '%real%')
select * from
unique_symbols
where symbol in symbols
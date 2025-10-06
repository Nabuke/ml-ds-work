with mt5_close as
          (select close.date
                , close.user_uid
                , close.login
                , close.position_id
                , argMax(close.profit, close.updated) as profit
                , argMax(close.spread_revenue_usd, close.updated) as spread_revenue_usd
                , argMax(close.xr_account_currency_to_usd, close.updated) as xr_account_currency_to_usd
                , argMax(close.time_msc , close.updated) as time_msc
          from  xdata.deals_mt5_extra close
          where close.action in (0, 1)
            and close.entry = 1
            and close.time_msc is not NULL
            and lower(close.server_name) like '%%real%%'
            and (close.comment not like 'close hedge by%%' or comment is null)
            and close.date >= toDate(%(scoring_date)s) - 1
            and close.date < toDate(%(scoring_date)s) 
            and close.login not in (46000004, 45002204, 46000006)
      group by close.date, close.login, close.position_id, close.user_uid),
     mt5_open as 
          (select open.login
                , open.reason
                , open.position_id
                , argMax(open.time_msc, open.updated) as time_msc
          from xdata.deals_mt5_extra open
          where open.action in (0, 1)
            and open.entry = 0
            and lower(open.server_name) like '%%real%%'
            and (open.comment not like 'close hedge by%%' or comment is null)
            and open.date >= toDate(%(scoring_date)s) - 1
            and open.date < toDate(%(scoring_date)s) 
            and open.login not in (46000004, 45002204, 46000006)
    group by open.login, open.position_id, open.reason),
     trades as 
          (select 'mt4' as mt
                 , mt4.user_uid
                 , mt4.reason
                 , mt4.profit
                 , mt4.spread_revenue_usd
                 , mt4.spread_revenue_usd / mt4.open_xr_account_currency_to_usd as spread_in_account_cur
                 , mt4.close_time - mt4.open_time as duration
          from xdata.trade_mt4_extra_full mt4
          where 1=1
            and open_time is not NULL
            and close_time is not NULL
            and close_time != 0
            and cmd in (0,1)
            and lower(server) like '%%real%%'
            and (mt4.comment not like 'close hedge by%%' or comment is null)
            and toDate(open_time) >= toDate(%(scoring_date)s) - 1
            and toDate(open_time) < toDate(%(scoring_date)s) 
          union all
          select 'mt5' as mt
                , mt5_close.user_uid
                , mt5_open.reason
                , mt5_close.profit
                , mt5_close.spread_revenue_usd
                , mt5_close.spread_revenue_usd / mt5_close.xr_account_currency_to_usd as spread_in_account_cur
                , mt5_close.time_msc - mt5_open.time_msc as duration
          from mt5_close
               inner join mt5_open
                    on mt5_open.login = mt5_close.login
                    and mt5_open.position_id=mt5_close.position_id),
     user_agg as 
          (select mt
                , user_uid
                , count(user_uid) as cnt_deals
                , sum(case when profit between -0.01 and 0 then 1 else 0 end) as cnt_0_profit_deals
                , sum(case when spread_in_account_cur < 0.005 then 1 else 0 end) as 	cnt_0_spread_acc_cur
               from trades
               group by mt, user_uid),
     metrics as
          (select mt
                , user_uid
                , cnt_deals
                , cnt_0_spread_acc_cur
                , cnt_0_profit_deals
          from user_agg
          where 1 = 1
               and (cnt_0_profit_deals > 10 or cnt_0_spread_acc_cur > 10)
               and cnt_0_profit_deals / cnt_deals > 0.1 
               and cnt_0_spread_acc_cur / cnt_deals > 0.4 )
select distinct toDateTime(%(scoring_date)s) as fact_timest, user_uid
from metrics



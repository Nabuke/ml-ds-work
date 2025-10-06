--Active user. Find a user with the higher amount of profit from trading activity and
--calculate some metrics for him. The expected output format is as follows:
---ID of this user
---His country code
---His profit
---Total amount of deals
---Amount of profitable deals
---The most popular trading instrument (symbol). The position with the highest
---amount of opened orders for this user
---The symbol with the highest level of profit
---The symbol with the highest level of loss

with cte1 as (
	select user_id 
	from ( 
		select user_id 
		, sum(profit_usd) as total_profit
		, rank() over(order by sum(profit_usd) desc) as rank
		from orders
		group by user_id
		) as user_sum_profit
	where rank=1
),
cte2 as (
	select user_id
	, symbol
	, count(profit_usd) as cnt_deals
	, count(case when profit_usd>0 then 1 else null end) as cnt_profit_deals 
	, sum(profit_usd) as sum_profit
	, first_value(symbol) over(partition by user_id order by sum(profit_usd) asc) as symbol_loss
	, first_value(symbol) over(partition by user_id order by sum(profit_usd) desc) as symbol_profit
	, first_value(symbol) over(partition by user_id order by count(profit_usd) desc) as symbol_populare
	
	from orders o
	where user_id = (select user_id from cte1)
	
	group by user_id, symbol
)

select cte2.user_id
	, user_info.country
	, sum(sum_profit) as sum_profit 
	, sum(cnt_deals) as cnt_deals 
	, sum(cnt_profit_deals) as cnt_profit_deals 
	, symbol_populare 
	, symbol_profit
	, symbol_loss
from cte2 

join (select country_code as country
           , user_id 
      from users 
      where user_id = (select user_id from cte1)
	) as user_info
on user_info.user_id = cte2.user_id

group by cte2.user_id
    , user_info.country 
    , symbol_populare 
	, symbol_profit
	, symbol_loss 

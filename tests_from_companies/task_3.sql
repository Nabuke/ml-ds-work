--User’s funnel. Calculate the following metrics for each user-
--
--User ID
--Country
--Registration datetime

--Date and time of the first deposit
--Amount of the first deposit

--Profit / loss of the first trade
--Date and time of the first trade (if any)

--Total deposit for the first 30 days since registration
--Total withdrawal for the first 30 days after registration
--Total profit / loss for the first 30 days after registration

--TOTAL profit / loss for the user’s lifetime

with first_trade as (
	select user_id, profit_usd, open_time, close_time
	, row_number() over(partition by user_id order by open_time, close_time) as rn
	from orders
),
first_deposit as ( 
	select user_id
	, operation_time
	, sum(operation_amount_usd) as operation_amount_usd 
	, rank() over(partition by user_id order by operation_time) 
	from balance
	where operation_type = 'deposit'
	group by user_id, operation_time 
),
first_30_days_profit as (
	select o.user_id 
	, sum(profit_usd) as profit_30_days
	from orders o 
	inner join users u
	on u.user_id = o.user_id 
	and u.registration_time + interval '30' day >= o.close_time
	group by o.user_id 
),
first_30_days_balance as (
	select b.user_id
	, sum(case when operation_type = 'deposit'
	      then operation_amount_usd else 0 end) as deposit_30_days
	, sum(case when operation_type = 'withdrawal' 
	      then operation_amount_usd else 0 end) as withdrawal_30_days
	from balance b  
	inner join users u
	on u.user_id = b.user_id 
	and u.registration_time + interval '30' day >= b.operation_time
	group by b.user_id 
),
total_profit as (
	select user_id
	, sum(profit_usd) as total_profit 
	from orders o2
	group by user_id
)
select u.user_id 
	, u.country_code as country
	, u.registration_time 

	, ft.profit_usd as first_deal_profit
	, ft.open_time as first_deal_open_time
	
	, fd.operation_amount_usd as sum_first_deposit
	, fd.operation_time as dt_first_deposit
	
	, f30dprofit.profit_30_days
	, f30dbalance.deposit_30_days 
	, f30dbalance.withdrawal_30_days 
	
	, tp.total_profit 
	from (select users.*
		  , row_number() over(partition by user_id order by registration_time) as user_reg_num 
		  from users) u 
	
	left join first_trade ft
	on u.user_id = ft.user_id 
	and ft.rn=1
	
	left join first_deposit fd
	on u.user_id = fd.user_id 
	and fd.rank=1
	
	left join first_30_days_profit f30dprofit
	on u.user_id = f30dprofit.user_id 
	
	left join first_30_days_balance f30dbalance
	on u.user_id = f30dbalance.user_id 
	
	left join total_profit tp
	on u.user_id = tp.user_id 
	
	where u.user_reg_num = 1
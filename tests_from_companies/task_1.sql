--Only the source code of SQL queries is expected from you as a result of this task. You do not
--need to send the results of queries execution, only the queries itself. It is expected that there
--would be 3 separate SQL queries, one (and only one) for each of subtasks A, B and C.
--A. Statistics by country. Calculate the following metrics for each country from database:
--
--Total number of users from this country
--Amount of users who made at least one deposit
--Average amount of deposit for the country
--Average amount of withdrawal for the country
--Provide the output sorted by number of users.

with cte1 as (
	select user_id
	, case when operation_type = 'deposit'
	      then operation_amount_usd else null end as deposit
	, case when operation_type = 'withdrawal' 
	      then operation_amount_usd else null end as withdrawal
	
	from balance b
)

select u.country_code 
	, count(distinct u.user_id) as cnt_users
	, count(distinct cte1.user_id) as cnt_users_with_money
	, avg(deposit) as avg_deposit
	, avg(withdrawal) as avg_withdrawal
from (select users.*
		  , row_number() over(partition by user_id order by registration_time) as user_reg_num 
		  from users) u 

left join cte1
on cte1.user_id = u.user_id 

where u.user_reg_num = 1
group by u.country_code
order by cnt_users desc nulls last 


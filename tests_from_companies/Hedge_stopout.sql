WITH 
base AS(
SELECT 
  user_uid,
  login,
  TIME,
  date(date_trunc('MONTH', TIME)) as date,
  conditional_true_event(COMMENT like 'D-NULL') 
  OVER (PARTITION BY login ORDER BY TIME, CASE WHEN COMMENT like 'D-NULL' THEN 1 ELSE 0 END ASC) AS stopout_group,
  action,
  COMMENT,
  symbol,
  CASE WHEN action = 0 THEN  volume
      WHEN action = 1 THEN -volume
  END AS volume_dif

FROM public.deals_mt5 dm
WHERE 1=1
  AND TIME >= '2021-06-01'::TIMESTAMP
  AND TIME <  '2022-06-01'::TIMESTAMP  --'2022-06-01 00:00:00'
  AND (COMMENT like '[so%'
       OR COMMENT like 'D-NULL')
  --and user_uid = '6bdce9fd-1b7c-42d3-84ee-06d4bd61d578'
  AND lower(SERVER_NAME) LIKE '%real%'
  and login not in (46000004, 45002204, 46000006) --remove liquidity providers
  and (login in (select acc.code from ra_dm.account_dim acc)
     or login in
        (46000009, 46000010, 46000012,
         46000013))                                --remove test accounts, but remain B2B
   ----------------------------------end of excluding>>
),

t2 AS
(SELECT
  user_uid,
  date,
  symbol,
  stopout_group,
  SUM(ABS(volume_dif)) AS sum_abs,
  ABS(SUM(volume_dif)) AS abs_sum
FROM BASE

WHERE COMMENT NOT LIKE 'D-NULL'
GROUP BY 
  user_uid,
  date,
  stopout_group,
  symbol
)

select 
   date,
   count(distinct CASE when sum_abs != abs_sum then user_uid || stopout_group else Null END) as cnt_hedge_so,
   count(distinct user_uid || stopout_group) as cnt_total_so
 FROM
  t2
  GROUP BY date
  order by date










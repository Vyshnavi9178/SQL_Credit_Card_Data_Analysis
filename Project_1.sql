-- SQL Portfolio project:

-- Have downloaded credit card transactions dataset from below link : https://www.kaggle.com/datasets/thedevastator/analyzing-credit-card-spending-habits-in-india

-- The data shows credit card transactions in India across different cities.

-- Basic findigs of dataset.

select * from credit_card_transcations;

select min(transaction_date), max(transaction_date) from credit_card_transcations; -- 2013-10-04 to 2015-05-26

select distinct card_type from credit_card_transcations; -- silver, signature, gold, platinum

select distinct card_type from credit_card_transcations; -- Entertinement, Food, Bills, Fuel, Travel, Grocery




-- 1- write a query to print top 5 cities with highest spends and their percentage contribution of total credit card spends 
with cte as 
(select top 5 city,sum(amount) as total_amount
from credit_card_transcations
group by city
order by total_amount desc),
cte2 as
(select sum(CAST(amount AS BIGINT)) as total_spend
from credit_card_transcations)

select cte.*, cte2.total_spend, round(( total_amount * 1.0 /total_spend * 100),2) as perc_cont
from cte
inner join cte2
on 1=1;

-- 2- write a query to print highest spend month and amount spent in that month for each card type
with cte as
(select card_type,datepart(year,transaction_date) as yt, datepart(month,transaction_date) as mt, sum(amount) as total_amount
from credit_card_transcations
group by card_type,datepart(year,transaction_date), datepart(month,transaction_date)),

cte2 as
( select *, rank() over (partition by card_type order by total_amount desc) as rn from cte)

select * from cte2 
where rn = 1;

-- 3- write a query to print the transaction details(all columns from the table) for each card type when
-- it reaches a cumulative of 1000000 total spends(We should have 4 rows in the o/p one for each card type)

with cte as
(select *,sum(amount) over (partition by card_type order by transaction_date , transaction_id) as total_amount
from credit_card_transcations),

cte2 as 
(select *, rank() over (partition by card_type order by total_amount) as ran
from cte where total_amount >= 1000000)

select * from cte2
where ran = 1;

-- 4- write a query to find city which had lowest percentage spend for gold card type

with cte as
(select city ,coalesce(sum(amount),0) as gold_amount
from credit_card_transcations
where card_type = 'gold'
group by city)

cte2 as 
(select city,sum(amount) as total_amnt_all
from credit_card_transcations
group by city)

select top 1 cte.*,cte2.* , round((coalesce(gold_amount,0)* 1.0 / total_amnt_all) * 100.0,2) as perc
from cte2
left join cte
on cte.city = cte2.city
order by perc asc;


-- 5- write a query to print 3 columns:  city, highest_expense_type , lowest_expense_type (example format : Delhi , bills, Fuel)


with cte as
(select city, exp_type, sum(amount) as total_amount
from credit_card_transcations
group by city, exp_type),

cte2 as
(select *, rank() over ( partition by city order by total_amount desc) as rn_desc,
 rank() over ( partition by city order by total_amount asc) as rn_asc
from cte)

select city, MAX(case when rn_desc = 1 then exp_type end) as high_exp_type,
MAX(case when rn_asc = 1 then exp_type end) as low_exp_type
from cte2
group by city;


-- 6- write a query to find percentage contribution of spends by females for each expense type

with cte as
(select exp_type, sum(amount) as F_total_amt
from credit_card_transcations
where gender = 'F'
group by exp_type),

cte2 as
(select exp_type, sum(CAST(amount AS BIGINT)) as total_amt 
from credit_card_transcations
group by exp_type)

select cte.*, cte2.total_amt ,((F_total_amt * 1.0 / total_amt ))  as perc
from cte 
inner join cte2
on cte.exp_type = cte2.exp_type;


-- 7- which card and expense type combination saw highest month over month growth in Jan-2014

with cte as 
(select card_type,exp_type, datepart(year,transaction_date) as yo,datepart(month,transaction_date) as mo,
sum(amount) as total_amount
from credit_card_transcations
group by card_type,exp_type, datepart(year,transaction_date),datepart(month,transaction_date)),
-- order by yo,mo),

cte2 as
(select *, lag(total_amount,1) over ( partition by card_type,exp_type order by yo,mo) as prev_month_amt
from cte)

select top 1 * , (total_amount - prev_month_amt)   as mom_growth
from cte2
where yo= 2014 and mo= 1 and prev_month_amt is not null
order by mom_growth desc;


-- 7- which card and expense type combination saw highest month over month growth percent in Jan-2014


with cte as 
(select card_type,exp_type, datepart(year,transaction_date) as yo,datepart(month,transaction_date) as mo,
sum(amount) as total_amount
from credit_card_transcations
group by card_type,exp_type, datepart(year,transaction_date),datepart(month,transaction_date)),
-- order by yo,mo),

cte2 as
(select *, lag(total_amount,1) over ( partition by card_type,exp_type order by yo,mo) as prev_month_amt
from cte)

select top 1 * , (total_amount - prev_month_amt) * 1.0 / prev_month_amt * 100   as mom_growth
from cte2
where yo= 2014 and mo= 1 and prev_month_amt is not null
order by mom_growth desc;


-- 9- during weekends which city has highest total spend to total no of transcations ratio

select top 1 city,sum(amount) as total_amount, count(1) as no_of_tran,
sum(amount) / count(1) as ratio
from credit_card_transcations
where datepart(weekday,transaction_date) = 1 or datepart(weekday,transaction_date) = 7
group by city
order by ratio desc;


-- 10- which city took least number of days to reach its 500th transaction after the first transaction in that city

with cte as (
select *
,row_number() over(partition by city order by transaction_date,transaction_id) as rn
from credit_card_transcations)

select top 1 city,datediff(day,min(transaction_date),max(transaction_date)) as datediff1
from cte
where rn=1 or rn=500
group by city
having count(1)=2
order by datediff1
UPDATE customer_registered  
SET stopdate = NULL WHERE stopdate = '';


alter table customer_registered  
modify column stopdate datetime null;


alter table customer_registered  
modify column create_date datetime;


alter table customer_transaction  
modify column purchase_date datetime;


select * from customer_transaction ct


-- Calculate time since last transaction


create view recency_rank as 
(select customerID, 
datediff('2022-09-01',max(date(purchase_date)))as day_num,
row_number() over(order by datediff('2022-09-01',max(date(purchase_date)))) as row_num
from customer_transaction ct 
where customerID != 0
group by CustomerID 
)

-- Calculate Recency score (R)
create temporary table R as (
select customerID, 
case when day_num between 0 and (select day_num from recency_rank  
						where row_num = (select round(count(distinct customerID)*0.25,0) from customer_transaction ct)) 
	then 4
	when day_num between (select day_num from recency_rank  
						where row_num = (select round(count(distinct customerID)*0.25,0) from customer_transaction ct))
		 				and (select day_num from recency_rank 
						where row_num = (select round(count(distinct customerID)*0.5,0) from customer_transaction ct))
	then 3
	when day_num between (select day_num from recency_rank 
						where row_num = (select round(count(distinct customerID)*0.5,0) from customer_transaction ct))
		 				and (select day_num from recency_rank  
						where row_num = (select round(count(distinct customerID)*0.75,0) from customer_transaction ct))
	then 2 else 1 end as R
from recency_rank)

-- Calculate Frequency Score (F)

create view frequency_rank  as(
select ct.customerID, 
coalesce (count(ct.purchase_date)/timestampdiff(month,cr.create_date,coalesce(cr.stopdate,cast('2022-09-01'as date))),count(ct.purchase_date))as purchase_num,
row_number() over(order by (count(distinct purchase_date))) as row_num
from customer_transaction ct 
join customer_registered cr 
on ct.customerID = cr.ID
where customerID != 0
group by customerID
);

create temporary table F as (
select customerID,
case when purchase_num between 0 and (select purchase_num from frequency_rank 
						where row_num = (select round(count(distinct customerID)*0.25,0) from frequency_rank)) 
	then 1
	when purchase_num between (select purchase_num from frequency_rank  
						where row_num = (select round(count(distinct customerID)*0.25,0) from frequency_rank ))
		 				and (select purchase_num from frequency_rank 
						where row_num = (select round(count(distinct customerID)*0.5,0) from frequency_rank ))
	then 2
	when purchase_num between (select purchase_num from frequency_rank
						where row_num = (select round(count(distinct customerID)*0.5,0) from frequency_rank ))
		 				and (select purchase_num from frequency_rank 
						where row_num = (select round(count(distinct customerID)*0.75,0) from frequency_rank ))
	then 3 else 4 end as F
from frequency_rank )

-- Calculate Monetary score (M)

create view revenue as(
select CustomerID,
coalesce (Sum(GMV)/timestampdiff(month,cr.create_date,coalesce(cr.stopdate,cast('2022-09-01'as date))),SUM(GMV)) as revenue,
row_number() over(order by Sum(GMV)) as row_num
from customer_transaction ct
join customer_registered cr 
on ct.customerID = cr.ID
where CustomerID !=0
group by CustomerID) ;

create temporary table M as (
select customerID,
case when revenue between 0 and (select revenue from revenue  
						where row_num = (select round(count(distinct customerID)*0.25,0) from revenue)) 
	then 1
	when revenue between (select revenue from revenue  
						where row_num = (select round(count(distinct customerID)*0.25,0) from revenue ))
		 				and (select revenue from revenue 
						where row_num = (select round(count(distinct customerID)*0.5,0) from revenue ))
	then 2
	when revenue between (select revenue from revenue
						where row_num = (select round(count(distinct customerID)*0.5,0) from revenue ))
		 				and (select revenue from revenue 
						where row_num = (select round(count(distinct customerID)*0.75,0) from revenue ))
	then 3 else 4 end as M
from revenue)


-- Joining all table to get final result (RFM) score
create table RFM_result as(
select count(customerID) as number_customer,RFM
from (
select R.customerID,concat(R,F,M) as RFM  from R 
join F using (customerID)
join M using (customerID))rfm
group by RFM 
order by count(customerID) desc)


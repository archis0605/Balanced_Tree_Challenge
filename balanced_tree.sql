-- High Level Sales Analysis
/* What was the total quantity sold for all products?*/
select sum(qty) as total_quantity_sold
from sales;
-- A total of 45,216 items were sold by Balanced Tree Clothing Company.

/* What is the total generated revenue for all products before discounts?*/
select sum(qty * price) as total_revenue_before_discounts
from sales;
-- This brings the total revenue generated across all products, excluding discounts, to $1,289,453.

/* What was the total discount amount for all products?*/
select round(sum(qty * price * discount/100), 2) as total_discount
from sales;
-- Balanced Tree Clothing Company has given its customers $156,229.14 in discounts for all products.

-- Transaction Analysis
/* How many unique transactions were there?*/
select count(distinct txn_id) as total_unique_transaction
from sales;

/* What is the average unique products purchased in each transaction? */
with cte as (
	select txn_id, count(distinct product_id) as unique_product
	from sales
	group by 1)
select round(avg(unique_product)) as avg_unique_products
from cte;

/* What are the 25th, 50th and 75th percentile values for the revenue per transaction?*/
with cte1 as (
	select txn_id, qty, price,
		row_number() over(partition by txn_id order by price) as row_num,
		count(*) over(partition by txn_id) as product_cnt     
	from balanced_tree.sales),
cte2 as (
	select *, 
		floor(product_cnt * 0.25) as 25th_percentile_index,
		floor(product_cnt * 0.5) as 50th_percentile_index,
		floor(product_cnt * 0.75) as 75th_percentile_index
	from cte1),
cte3 as (
	select txn_id, (qty*price) as 25th_percentile_revenue
	from cte2
	where row_num = 25th_percentile_index),
cte4 as (
	select txn_id, (qty*price) as 50th_percentile_revenue
	from cte2
	where row_num = 50th_percentile_index),
cte5 as (
	select txn_id, (qty*price) as 75th_percentile_revenue
	from cte2
	where row_num = 75th_percentile_index)
select c3.txn_id, 25th_percentile_revenue, 50th_percentile_revenue, 75th_percentile_revenue
from cte3 c3
inner join cte4 c4 using(txn_id)
inner join cte5 c5 using(txn_id);

/* What is the average discount value per transaction?*/
with cte as (
	select txn_id, round(sum(qty * price * discount/100), 2) as total_discount
	from sales
	group by 1)
select round(avg(total_discount),1) as avg_discount_per_txn
from cte;

/* What is the percentage split of all transactions for members vs non-members?*/
select 
	if(members = 't', "Members", "Non-Members") as type_of_members, 
	round(count(*)*100/(select count(*) from sales),1) as prcnt
from sales
group by 1;

/* What is the average revenue for member transactions and non-member transactions?*/
select 
	if(members = 't', "Members", "Non-Members") as type_of_members, 
	round(avg(qty*price),1) as average_rev
from sales
group by 1;

-- Product Analysis
/* What are the top 3 products by total revenue before discount?*/
select distinct s.product_id, product_name, sum(s.qty * s.price) as total_revenue
from sales s
inner join product_details p using(product_id)
group by 1,2
order by 3 desc
limit 3;

/* What is the total quantity, revenue and discount for each segment?*/
with qty_details as (
	select segment_name, sum(qty) as total_quantity
	from sales s
	inner join product_details p using(product_id)
	group by 1),
rev_details as (
	select segment_name, sum(s.qty*s.price) as total_revenue
	from sales s
	inner join product_details p using(product_id)
	group by 1),
discount_details as (
	select segment_name, round(sum(s.qty*s.price*s.discount/100),2) as total_discount
	from sales s
	inner join product_details p using(product_id)
	group by 1)
select *
from qty_details as q
inner join rev_details r using(segment_name)
inner join discount_details d using(segment_name);

/* What is the top selling product for each segment?*/
with cte as (
	select p.segment_name, p.product_name, sum(qty) as sold_quantity
	from sales s
	inner join product_details p using(product_id)
	group by 1,2),
cte1 as (
	select *,
		dense_rank() over(partition by segment_name order by sold_quantity desc) as rnk
	from cte)
select segment_name, product_name, sold_quantity
from cte1
where rnk = 1;

/* What is the total quantity, revenue and discount for each category?*/
with qty_details as (
	select category_name, sum(qty) as total_quantity
	from sales s
	inner join product_details p using(product_id)
	group by 1),
rev_details as (
	select category_name, sum(s.qty*s.price) as total_revenue
	from sales s
	inner join product_details p using(product_id)
	group by 1),
discount_details as (
	select category_name, round(sum(s.qty*s.price*s.discount/100),2) as total_discount
	from sales s
	inner join product_details p using(product_id)
	group by 1)
select *
from qty_details as q
inner join rev_details r using(category_name)
inner join discount_details d using(category_name);

/* What is the top selling product for each category?*/
with cte as (
	select p.category_name, p.product_name, sum(qty) as sold_quantity
	from sales s
	inner join product_details p using(product_id)
	group by 1,2),
cte1 as (
	select *,
		dense_rank() over(partition by category_name order by sold_quantity desc) as rnk
	from cte)
select category_name, product_name, sold_quantity
from cte1
where rnk = 1;

/* What is the percentage split of revenue by product for each segment?*/
with cte1 as (
	select segment_name, product_name, sum(s.qty * s.price) as total_revenue
	from sales s
	inner join product_details p using(product_id)
	group by 1,2
	order by 1),
cte2 as (
	select *, sum(total_revenue) over(partition by segment_name) as segment_rev
	from cte1)
select segment_name, product_name, round(total_revenue*100/segment_rev, 1) as prcnt
from cte2;

/* What is the percentage split of revenue by segment for each category?*/
with cte1 as (
	select category_name, segment_name,
    sum(s.qty*s.price) as t_rev
	from sales s
	inner join product_details p using(product_id)
	group by 1,2
	order by 1),
cte2 as (
	select *,
    sum(t_rev) over(partition by category_name) as c_rev
	from cte1)
select category_name, segment_name, round(t_rev*100/c_rev, 1) as prcnt
from cte2;

/* What is the percentage split of total revenue by category?*/
with c_details as (
	select category_name, sum(s.qty * s.price) as t_rev
	from sales s
	inner join product_details p using(product_id)
	group by 1),
cte as (
	select sum(t_rev) as total
    from c_details)
select category_name, 
	round(t_rev*100/(select total from cte),1) as prcnt
from c_details;
    
/* What is the total transaction “penetration” for each product? 
(hint: penetration = number of transactions where at least 1 quantity
 of a product was purchased divided by total number of transactions)*/
with cte as (
	select count(distinct txn_id) as total_txn 
    from sales)
select p.product_name,
	round(count(*)*100/(select total_txn from cte),1) as penetrate
from sales s
right join product_details p using(product_id)
where s.qty >= 1
group by 1;
 
/* What is the most common combination of at least 1 quantity of any 3 products in a 1 single transaction?*/
with cte as (
	select s.product_id, p.product_name, s.qty, s.price,
		s.discount, s.members, s.txn_id, s.start_txn_time
    from sales s
    inner join product_details p using(product_id))
select c1.product_name as first_product, c2.product_name as second_product, 
	c3.product_name as third_product, count(*) as common_cnt       
from cte c1
inner join cte c2 
on c2.txn_id = c1.txn_id and c1.product_id < c2.product_id
inner join cte c3 
on c3.txn_id = c1.txn_id and c2.product_id < c3.product_id
group by 1, 2, 3
order by 4 desc
limit 1;

-- Reporting Challenge
/* Write a single SQL script that combines all of the previous questions
 into a scheduled report that the Balanced Tree team can run at the 
 beginning of each month to calculate the previous month’s values.

Imagine that the Chief Financial Officer (which is also Danny) has asked
for all of these questions at the end of every month.

He first wants you to generate the data for January only - but then he also
wants you to demonstrate that you can easily run the same analysis for 
February without many changes (if at all).

Feel free to split up your final outputs into as many tables as you 
need - but be sure to explicitly reference which table outputs relate 
to which question for full marks.*/
create table monthly_report as (
	select month(start_txn_time) as month, 
		s.product_id, p.product_name,
		sum(qty) as sold, sum(qty*s.price) as total_rev,
		round(sum((discount*qty*s.price*0.01)),2) as total_discount,
		round(count(distinct txn_id)*100/(select count(distinct txn_id) from sales),2) as penetration,
		round(sum(case when members = 't' then 1 else 0 end)*100/count(*),2) as member_txn,
		round(sum(case when members = 'f' then 1 else 0 end)*100/count(*),2) as non_member_txn,
		round(avg(case when members = 't' then (qty*s.price) end),2) as avg_rev_member,
		round(avg(case when members = 'f' then (qty*s.price) end),2) as avg_rev_non_member
	from sales s 
	inner join product_details p using(product_id)
	group by 1, 2, 3
	order by 1);
    
-- For January
call schedule_report(1);
    
-- For February
call schedule_report(2);

-- For March
call schedule_report(3);
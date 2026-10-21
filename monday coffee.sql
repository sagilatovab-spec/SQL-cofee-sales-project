##Monday cofee-data analysis

##Coffee Consumers Count
##How many people in each city are estimated to consume coffee, given that 25% of the population does?
select city_name,round((population*0.25)/1000000,2) as coffe_cons_in_mil,city_rank
from city
order by 2 desc;

##Total Revenue from Coffee Sales
##What is the total revenue generated from coffee sales across all cities in the last quarter of 2023?
select ct.city_name,sum(total) as total_revenue 
from sales as s
join customers as c
on s.customer_id=c.customer_id
join city as ct
on ct.city_id=c.city_id
where extract(quarter from s.sale_date)=4 and extract(year from s.sale_date)=2023
group by ct.city_name
order by 2 desc;

##Sales Count for Each Product
##How many units of each coffee product have been sold?-each order 1 quantity
select p.product_name, count(s.sale_id) as total_orders
from products as p 
left join sales as s
on s.product_id=p.product_id
group by 1 order by 2 desc;

##Average Sales Amount per City
##What is the average sales amount per customer in each city?-city naem, cust num, total sales
select ct.city_name,sum(s.total) as total_revenue, count(distinct s.customer_id) as total_cust, 
round(sum(s.total)/count(distinct s.customer_id),2) as per_cust_city_avg_sale
from sales as s
join customers as c
on s.customer_id=c.customer_id
join city as ct
on ct.city_id=c.city_id
group by ct.city_name
order by 2 desc;

##City Population and Coffee Consumers
##Provide a list of cities along with their populations and estimated coffee consumers-cit name, cur cust, coffe cons
select city_name, population,round((population*0.25)/1000000,2) as coffe_cons_in_mil, count(c.city_id) as city_cust
from city as ct
join customers as c
on c.city_id=ct.city_id
group by c.city_id
order by 4;

##Top Selling Products by City
##What are the top 3 selling products in each city based on sales volume?
select *
from
(
select ct.city_name, p.product_name, count(s.sale_id) as totl_ord,
 dense_rank() over(partition by ct.city_name order by count(s.sale_id) desc) as rankk 
from customers c
join sales s
on c.customer_id=s.customer_id
join city as ct
on c.city_id=ct.city_id
join products p
on s.product_id=p.product_id
group by 1, 2
) as tab1
where rankk<4;

##Customer Segmentation by City
##How many unique customers are there in each city who have purchased coffee products?
select ct.city_name, count(distinct s.customer_id)
from customers c
join sales s
on c.customer_id=s.customer_id
join city ct
on c.city_id=ct.city_id
group by 1;

##Average Sale vs Rent
##Find each city and their average sale per customer and avg rent per customer
with city_table as 
(
 select ct.city_name, count(distinct s.customer_id) as cust_num, round(sum(s.total)/count(distinct s.customer_id),2) as avg_sale
 from customers c
 join sales s
 on c.customer_id=s.customer_id
 join city ct
 on c.city_id=ct.city_id
 group by 1
 ),
city_rent
as
 (
select city_name, estimated_rent
from city
)
select cr.city_name,cr.estimated_rent,ct.cust_num,ct.avg_sale,round(estimated_rent/cust_num,2) as avg_rent
from city_rent cr
join city_table ct
on cr.city_name=ct.city_name;

##Monthly Sales Growth
##Sales growth rate: Calculate the percentage growth (or decline) in sales over different time periods (monthly) in each city
with tab2
as (
select ct.city_name,extract(month from sale_date) as monthh, extract(year from sale_date) as yearr,sum(s.total) as total_month_sales
from customers c
join sales s
on c.customer_id=s.customer_id
join city ct
on c.city_id=ct.city_id
group by 1,2,3
order by 1,3,2),
tab3 as
(
select city_name,monthh,yearr,total_month_sales,lag(total_month_sales,1) over(partition by city_name order by yearr,monthh) as last_month_sale
from tab2
)
select city_name,monthh,yearr,total_month_sales,last_month_sale,round(((total_month_sales-last_month_sale)/last_month_sale)*100,2) as growth_ratio
from tab3;

##Market Potential Analysis
##Identify top 3 city based on highest sales, return city name, total sale, total rent, total customers, estimated coffee consumer
with city_table as 
(
 select ct.city_name, count(distinct s.customer_id) as cust_num, sum(s.total) as revenue, round(sum(s.total)/count(distinct s.customer_id),2) as avg_sale
 from customers c
 join sales s
 on c.customer_id=s.customer_id
 join city ct
 on c.city_id=ct.city_id
 group by 1
 ),
city_rent
as
 (
select city_name, estimated_rent, round((population*0.25)/1000000,2) as coffee_cons_mil
from city
)
select cr.city_name, revenue,coffee_cons_mil,ct.cust_num,cr.estimated_rent,ct.avg_sale,round(estimated_rent/cust_num,2) as avg_rent
from city_rent cr
join city_table ct
on cr.city_name=ct.city_name
order by 2 desc

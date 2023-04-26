/* SQL queries to draw insights */
==================================================
/* 1) What is the total amount each customer spent on Zomato? */
select s.userid,sum(p.price) as total_amount from sales s inner join product p
on s.product_id = p.product_id group by s.userid order by userid 

/* 2) How many days has each customer visited Zomato? */
select distinct userid,count(created_date) as days_visited from sales group by userid

/* 3) What was the first product purchased by each customer? */
select * from
(select *,rank() over(partition by userid order by created_date) rnk from sales) s
where rnk = 1

/* 4) What is the most purchased item on the menu and how many times was it purchased
by all the customers? */
select Top 1 cast(p.product_name as nvarchar(50)) product_name,count(s.product_id) as times_purchased 
from product p 
inner join sales s on p.product_id = s.product_id group by cast(p.product_name as nvarchar(50))
order by count(s.product_id) desc

/* 5) Which item was the most popular for each customer? */
select * from
(select *, rank() over (partition by userid order by cnt desc) rnk from
(select userid,product_id,count(product_id) cnt from sales group by userid,product_id)
a)b where rnk =1 

/* 6) Which item was first purchased by customer after they became a member? */
select * from
(select *, rank() over (partition by userid order by created_date) rnk from 
(select s.created_date,g.gold_signup_date,p.product_name,s.userid from product p inner join sales s
on p.product_id = s.product_id inner join goldusers_signup g on s.userid = g.userid
where s.created_date > g.gold_signup_date)b)c where rnk =1  order by gold_signup_date 

/* 7) Which item was purchased just before the customer became a member? */
select * from
(select *, rank() over (partition by userid order by created_date) rnk from 
(select s.userid,s.created_date,s.product_id,g.gold_signup_date from sales s
inner join goldusers_signup g on
 s.userid = g.userid and s.created_date <=g.gold_signup_date)b)c where rnk =1 
 order by created_date desc
 
 /* 8) What is the total orders and amount spent for each member before they
 became a gold member? */
 select s.userid,count(s.product_id) as total_orders,sum(p.price) as amount_spent from sales s inner join 
 product p on p.product_id = s.product_id inner join goldusers_signup g
 on g.userid = s.userid where s.created_date < g.gold_signup_date group by s.userid

 /* 9) If buying each product generates points for example $5 =2 zomato points and
 each product has different purchasing points for example for p1 $5 =1 zomato point,
 for p2 $10 = 5 zomato points and p3 $5= 1 zomato point, $2 = 1 zomato point,
 Calculate points collected by each customer and for which product most points have
 been collected till now? */
 select e.*,amount/points as zomato_points from
 (select d.*,case
  when product_id = 1 then 5
  when product_id = 2 then 10 
  when product_id = 3 then 5 else 0
  end as points from
  (select s.userid,s.product_id,sum(price) amount from
  (select s.*,p.price from sales s inner join product p on p.product_id=s.product_id)
  s group by product_id,userid)d)e

  /* 10) In the first one year after a customer joins the gold program(including their 
  joining date) irrespective of what the customer has purchased they earn 5 zomato
  points for every $10 spent. Who earned more and what was their points earnings in
  the first year? */
  select g.gold_signup_date,dateadd(year,1,g.gold_signup_date) 
  oneyear_after_gold_signup_date,
  g.userid,(sum(p.price)/10) * 5 as zomato_points from goldusers_signup g
  inner join sales s on s.userid = g.userid inner join product p on 
  s.product_id = p.product_id where s.created_date between g.gold_signup_date
  and dateadd(year,1,g.gold_signup_date) 
  group by g.userid,g.gold_signup_date,dateadd(year,1,g.gold_signup_date)
  order by (sum(p.price)/10) * 5 desc

  /* 11) Rank all the transactions of the customers */
  select *,Row_number() over(partition by userid order by count(userid)) 
  rnk from sales group by userid,created_date,product_id

  /* 12) rank all the transactions for each gold member, for non member mark NA */
  select e.*,case when rnk=0 then 'NA' else rnk end as rnkk from
  (select s.*,cast((case when gold_signup_date is null then 0
  else rank() over (partition by userid order by created_date desc)end)as varchar)
  as rnk from 
  (select s.userid,s.created_date,s.product_id,g.gold_signup_date from sales s
  left join goldusers_signup g on g.userid = s.userid 
  and s.created_date>=g.gold_signup_date)s)e
  
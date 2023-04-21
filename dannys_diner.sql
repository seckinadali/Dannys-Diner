-- Danny's Diner Exercises

-- 1. What is the total amount each customer spent at the restaurant?
select
  sales.customer_id,
  sum(menu.price) as total_spent
from dannys_diner.sales
left join dannys_diner.menu
on sales.product_id = menu.product_id
group by sales.customer_id
order by sales.customer_id;

-- 2. How many days has each customer visited the restaurant?
select
  customer_id,
  count(distinct order_date)
from dannys_diner.sales
group by customer_id
order by customer_id;

-- 3. What was the first item from the menu purchased by each customer?
with purchase_cte as (
  select
    sales.customer_id,
    menu.product_name,
    dense_rank() over (
      partition by sales.customer_id
      order by sales.order_date
    ) as purchase_order
  from dannys_diner.sales
  left join dannys_diner.menu
  on sales.product_id = menu.product_id
)
select
  customer_id,
  product_name
from purchase_cte
where purchase_order = 1;

-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
select
  menu.product_name,
  count(sales.order_date) as total_purchases
from dannys_diner.sales
left join dannys_diner.menu
on sales.product_id = menu.product_id
group by menu.product_name
order by total_purchases desc
limit 1;

-- 5. Which item(s) was the most popular for each customer?
with cte as (
  select
    sales.customer_id,
    menu.product_name,
    count(sales.order_date) as total_purchases,
    dense_rank() over (
      partition by sales.customer_id
      order by count(sales.order_date) desc
    ) as purchase_count_order
  from dannys_diner.sales
  left join dannys_diner.menu
  on sales.product_id = menu.product_id
  group by sales.customer_id, menu.product_name
)
select
  customer_id,
  product_name,
  total_purchases
from cte
where purchase_count_order = 1;

-- 6. Which item was purchased first by the customer after they became a member and what date was it?
with cte as (
  select
    sales.customer_id,
    menu.product_name,
    members.join_date,
    sales.order_date,
    dense_rank() over (
      partition by sales.customer_id
      order by sales.order_date
    ) as order_date_rank
  from dannys_diner.sales
  left join dannys_diner.menu
  on sales.product_id = menu.product_id
  left join dannys_diner.members
  on sales.customer_id = members.customer_id
  where sales.order_date >= members.join_date
)
select
  customer_id,
  product_name,
  order_date
from cte
where order_date_rank = 1;

-- 7. Which item was purchased just before the customer became a member and when?
with cte as (
  select
    sales.customer_id,
    menu.product_name,
    members.join_date,
    sales.order_date,
    dense_rank() over (
      partition by sales.customer_id
      order by sales.order_date desc
    ) as order_date_rank
  from dannys_diner.sales
  left join dannys_diner.menu
  on sales.product_id = menu.product_id
  left join dannys_diner.members
  on sales.customer_id = members.customer_id
  where sales.order_date < members.join_date
)
select
  customer_id,
  product_name,
  order_date
from cte
where order_date_rank = 1;

-- 8. What is the total items and amount spent for each member before they became a member?
select
  sales.customer_id,
  count(distinct sales.product_id) as total_purchases,
  sum(menu.price) as total_spent
from dannys_diner.sales
left join dannys_diner.menu
on sales.product_id = menu.product_id
left join dannys_diner.members
on sales.customer_id = members.customer_id
where sales.order_date < members.join_date
group by sales.customer_id;

-- 9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
select
  sales.customer_id,
  sum(
    case
      when menu.product_name = 'sushi'
      then 20 * menu.price
      else 10 * menu.price
    end
  ) as points
from dannys_diner.sales
left join dannys_diner.menu
on sales.product_id = menu.product_id
group by sales.customer_id
order by sales.customer_id;

-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
select
  sales.customer_id,
  sum(
    case
      when menu.product_name = 'sushi'
        or sales.order_date between members.join_date and members.join_date + 6
      then 20 * menu.price
      else 10 * menu.price
    end
  ) as points
from dannys_diner.sales
left join dannys_diner.menu
on sales.product_id = menu.product_id
left join dannys_diner.members
on sales.customer_id = members.customer_id
where sales.order_date < '2021-02-01'
group by sales.customer_id
order by sales.customer_id;

-- 11. Membership table
select
  sales.customer_id,
  sales.order_date,
  menu.product_name,
  menu.price,
  case
    when sales.order_date >= members.join_date
    then 'Y' else 'N'
  end as member
from dannys_diner.sales
left join dannys_diner.menu
on sales.product_id = menu.product_id
left join dannys_diner.members
on sales.customer_id = members.customer_id
order by sales.customer_id, sales.order_date

-- 12. Membership table with ranking
with cte as (
  select
    sales.customer_id,
    sales.order_date,
    menu.product_name,
    menu.price,
    case
      when sales.order_date >= members.join_date
      then 'Y' else 'N'
    end as member
  from dannys_diner.sales
  left join dannys_diner.menu
  on sales.product_id = menu.product_id
  left join dannys_diner.members
  on sales.customer_id = members.customer_id
  order by sales.customer_id, sales.order_date
)
select
  *,
  case
    when member = 'Y' then
      dense_rank() over (
        partition by customer_id, member
        order by order_date
      )
    else null
  end as ranking
from cte;

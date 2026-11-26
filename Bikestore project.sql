create database Project;
select * from brands;
select * from categories;
select * from customers;
select * from order_items;
select * from orders;
select * from products;
select * from staffs;
select * from stocks;
select * from stores;

# BIKESTORES SQL ANALYSIS: 12 BUSINESS QUESTIONS
# SALES & REVENUE

# Q1. How has monthly revenue trended from 2016 to 2018, and what is the month-over-month growth rate?
WITH monthly AS (
    SELECT DATE_FORMAT(o.order_date, '%Y-%m') AS month,
           ROUND(SUM(oi.quantity * oi.list_price * (1 - oi.discount)), 2) AS revenue
    FROM orders o
    JOIN order_items oi ON oi.order_id = o.order_id
    WHERE o.order_status = 4
    GROUP BY DATE_FORMAT(o.order_date, '%Y-%m')
)
SELECT month,
       revenue,
       LAG(revenue) OVER (ORDER BY month) AS prev_month_revenue,
       ROUND((revenue - LAG(revenue) OVER (ORDER BY month))
             / LAG(revenue) OVER (ORDER BY month) * 100, 1) AS mom_growth_pct
FROM monthly
ORDER BY month;

# Q2. Which store generates the most revenue, and what are its order count and average order value?
SELECT s.store_name,
       s.state,
       COUNT(DISTINCT o.order_id) AS total_orders,
       ROUND(SUM(oi.quantity * oi.list_price * (1 - oi.discount)), 2) AS revenue,
       ROUND(SUM(oi.quantity * oi.list_price * (1 - oi.discount))
             / COUNT(DISTINCT o.order_id), 2) AS avg_order_value,
       ROUND(100 * SUM(oi.quantity * oi.list_price * (1 - oi.discount))
             / SUM(SUM(oi.quantity * oi.list_price * (1 - oi.discount))) OVER (), 1) AS revenue_share_percentage
FROM orders o
JOIN order_items oi ON oi.order_id = o.order_id
JOIN stores s       ON s.store_id = o.store_id
WHERE o.order_status = 4
GROUP BY s.store_id, s.store_name, s.state
ORDER BY revenue DESC;

# Q3. What are the top 10 products by revenue, and what share of total revenue do they contribute?
-- Revenue = quantity * list_price * (1 - discount), completed orders only

WITH product_rev AS (
    SELECT p.product_name,
           SUM(oi.quantity) AS units_sold,
           SUM(oi.quantity * oi.list_price * (1 - oi.discount)) AS revenue
    FROM order_items oi
    JOIN orders o   ON o.order_id = oi.order_id
    JOIN products p ON p.product_id = oi.product_id
    WHERE o.order_status = 4
    GROUP BY p.product_id, p.product_name
)
SELECT product_name,
       units_sold,
       ROUND(revenue, 2) AS revenue,
       ROUND(100 * revenue / SUM(revenue) OVER (), 2) AS pct_of_total,
       ROUND(100 * SUM(revenue) OVER (ORDER BY revenue DESC) / SUM(revenue) OVER (), 2) AS cumulative_pct
FROM product_rev
ORDER BY revenue DESC
LIMIT 10; 

# Q4. Which brands and categories earn the most revenue, and how does each rank within its store?
SELECT b.brand_name,
       SUM(oi.quantity) AS units_sold,
       ROUND(SUM(oi.quantity * oi.list_price * (1 - oi.discount)), 2) AS revenue,
       ROUND(100 * SUM(oi.quantity * oi.list_price * (1 - oi.discount))
             / SUM(SUM(oi.quantity * oi.list_price * (1 - oi.discount))) OVER (), 1) AS revenue_share_pct,
       RANK() OVER (ORDER BY SUM(oi.quantity * oi.list_price * (1 - oi.discount)) DESC) AS brand_rank
FROM order_items oi
JOIN orders o   ON o.order_id = oi.order_id
JOIN products p ON p.product_id = oi.product_id
JOIN brands b   ON b.brand_id = p.brand_id
WHERE o.order_status = 4
GROUP BY b.brand_id, b.brand_name
ORDER BY revenue DESC;
WITH store_cat AS (
    SELECT s.store_name,
           c.category_name,
           SUM(oi.quantity * oi.list_price * (1 - oi.discount)) AS revenue
    FROM order_items oi
    JOIN orders o     ON o.order_id = oi.order_id
    JOIN stores s     ON s.store_id = o.store_id
    JOIN products p   ON p.product_id = oi.product_id
    JOIN categories c ON c.category_id = p.category_id
    WHERE o.order_status = 4
    GROUP BY s.store_name, c.category_name
)
SELECT store_name,
       category_name,
       ROUND(revenue, 2) AS revenue,
       ROUND(100 * revenue / SUM(revenue) OVER (PARTITION BY store_name), 1) AS pct_of_store_revenue,
       DENSE_RANK() OVER (PARTITION BY store_name ORDER BY revenue DESC) AS rank_in_store
FROM store_cat
ORDER BY store_name, rank_in_store;

# Q5. How much revenue is lost to discounts, and which categories are discounted most heavily?
SELECT c.category_name,
       ROUND(SUM(oi.quantity * oi.list_price), 2) AS gross_revenue,
       ROUND(SUM(oi.quantity * oi.list_price * oi.discount), 2) AS discount_given,
       ROUND(SUM(oi.quantity * oi.list_price * (1 - oi.discount)), 2) AS net_revenue,
       ROUND(100 * SUM(oi.quantity * oi.list_price * oi.discount)
             / SUM(oi.quantity * oi.list_price), 2) AS effective_discount_pct
FROM order_items oi
JOIN orders o     ON o.order_id = oi.order_id
JOIN products p   ON p.product_id = oi.product_id
JOIN categories c ON c.category_id = p.category_id
WHERE o.order_status = 4
GROUP BY c.category_id, c.category_name
ORDER BY discount_given DESC;

# Q6. Who are the top 10 customers by lifetime spend, and which city and state are they from?
SELECT c.customer_id,
       CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
       c.city,
       c.state,
       COUNT(DISTINCT o.order_id) AS total_orders,
       ROUND(SUM(oi.quantity * oi.list_price * (1 - oi.discount)), 2) AS lifetime_spend
FROM customers c
JOIN orders o       ON o.customer_id = c.customer_id
JOIN order_items oi ON oi.order_id = o.order_id
WHERE o.order_status = 4
GROUP BY c.customer_id, c.first_name, c.last_name, c.city, c.state
ORDER BY lifetime_spend DESC
LIMIT 10;

# Q7. What percentage of customers are repeat buyers (2+ orders) versus one-time buyers?
WITH cust_orders AS (
    SELECT customer_id, COUNT(*) AS order_count
    FROM orders
    WHERE order_status = 4
    GROUP BY customer_id
)
SELECT CASE WHEN order_count = 1 THEN 'One-time buyer'
            WHEN order_count = 2 THEN 'Repeat (2 orders)'
            ELSE 'Loyal (3+ orders)' END AS customer_type,
       COUNT(*) AS customers,
       ROUND(100 * COUNT(*) / SUM(COUNT(*)) OVER (), 1) AS pct_of_buyers
FROM cust_orders
GROUP BY customer_type
ORDER BY customers DESC;

# Q8. Segment customers into High, Medium and Low value tiers based on total spend, and show the revenue contribution of each tier.?
WITH cust_spend AS (
    SELECT o.customer_id,
           SUM(oi.quantity * oi.list_price * (1 - oi.discount)) AS spend
    FROM orders o
    JOIN order_items oi ON oi.order_id = o.order_id
    WHERE o.order_status = 4
    GROUP BY o.customer_id
),
tiered AS (
    SELECT customer_id, spend,
           NTILE(3) OVER (ORDER BY spend DESC) AS tile
    FROM cust_spend
)
SELECT CASE tile WHEN 1 THEN 'High value'
                 WHEN 2 THEN 'Medium value'
                 ELSE 'Low value' END AS tier,
       COUNT(*) AS customers,
       ROUND(MIN(spend), 2) AS min_spend,
       ROUND(MAX(spend), 2) AS max_spend,
       ROUND(SUM(spend), 2) AS tier_revenue,
       ROUND(100 * SUM(spend) / SUM(SUM(spend)) OVER (), 1) AS revenue_share_pct
FROM tiered
GROUP BY tile
ORDER BY tile;

# Q9. What is the average days-to-ship per store, and what percentage of completed orders shipped after the required date?
SELECT s.store_name,
       COUNT(*) AS completed_orders,
       ROUND(AVG(DATEDIFF(o.shipped_date, o.order_date)), 2) AS avg_days_to_ship,
       SUM(o.shipped_date > o.required_date) AS late_orders,
       ROUND(100 * SUM(o.shipped_date > o.required_date) / COUNT(*), 1) AS late_pct
FROM orders o
JOIN stores s ON s.store_id = o.store_id
WHERE o.order_status = 4
  AND o.shipped_date IS NOT NULL
GROUP BY s.store_id, s.store_name
ORDER BY late_pct DESC;

#Q10. Which staff members generate the most revenue, and what is the total revenue of each manager's team?
SELECT CONCAT(e.first_name, ' ', e.last_name) AS staff_name,
       IFNULL(CONCAT(m.first_name, ' ', m.last_name), '(Top-level manager)') AS manager_name,
       st.store_name,
       COUNT(DISTINCT o.order_id) AS orders_handled,
       ROUND(SUM(oi.quantity * oi.list_price * (1 - oi.discount)), 2) AS revenue,
       RANK() OVER (ORDER BY SUM(oi.quantity * oi.list_price * (1 - oi.discount)) DESC) AS revenue_rank
FROM staffs e
LEFT JOIN staffs m  ON m.staff_id = e.manager_id
JOIN stores st      ON st.store_id = e.store_id
JOIN orders o       ON o.staff_id = e.staff_id AND o.order_status = 4
JOIN order_items oi ON oi.order_id = o.order_id
GROUP BY e.staff_id, e.first_name, e.last_name, m.first_name, m.last_name, st.store_name
ORDER BY revenue_rank;
WITH staff_rev AS (
    SELECT o.staff_id,
           SUM(oi.quantity * oi.list_price * (1 - oi.discount)) AS revenue
    FROM orders o
    JOIN order_items oi ON oi.order_id = o.order_id
    WHERE o.order_status = 4
    GROUP BY o.staff_id
)
SELECT CONCAT(m.first_name, ' ', m.last_name) AS manager_name,
       COUNT(e.staff_id) AS direct_reports,
       ROUND(SUM(IFNULL(sr.revenue, 0)), 2) AS team_revenue,
       ROUND(AVG(sr.revenue), 2) AS avg_revenue_per_selling_report
FROM staffs m
JOIN staffs e          ON e.manager_id = m.staff_id
LEFT JOIN staff_rev sr ON sr.staff_id = e.staff_id
GROUP BY m.staff_id, m.first_name, m.last_name
ORDER BY team_revenue DESC;

# Q11. Which products have low stock (e.g. under 5 units) in a store but are among its best sellers?
WITH store_sales AS (
    SELECT o.store_id, oi.product_id, SUM(oi.quantity) AS units_sold
    FROM orders o
    JOIN order_items oi ON oi.order_id = o.order_id
    WHERE o.order_status = 4
    GROUP BY o.store_id, oi.product_id
),
ranked AS (
    SELECT *,
           RANK() OVER (PARTITION BY store_id ORDER BY units_sold DESC) AS sales_rank
    FROM store_sales
)
SELECT s.store_name,
       p.product_name,
       r.units_sold,
       r.sales_rank,
       IFNULL(sk.quantity, 0) AS stock_on_hand
FROM ranked r
JOIN stores s   ON s.store_id = r.store_id
JOIN products p ON p.product_id = r.product_id
LEFT JOIN stocks sk ON sk.store_id = r.store_id AND sk.product_id = r.product_id
WHERE r.sales_rank <= 20
  AND IFNULL(sk.quantity, 0) < 5
ORDER BY s.store_name, r.sales_rank;

#Q12. Which products are in stock but have never been sold (dead stock), and how many units are tied up?
SELECT s.store_name,
       p.product_name,
       b.brand_name,
       sk.quantity AS units_in_stock,
       ROUND(sk.quantity * p.list_price, 2) AS capital_tied_up
FROM stocks sk
JOIN stores s   ON s.store_id = sk.store_id
JOIN products p ON p.product_id = sk.product_id
JOIN brands b   ON b.brand_id = p.brand_id
LEFT JOIN order_items oi ON oi.product_id = sk.product_id
WHERE oi.product_id IS NULL
  AND sk.quantity > 0
ORDER BY capital_tied_up DESC;




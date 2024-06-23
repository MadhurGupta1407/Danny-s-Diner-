use dannys_diner;

  select * from sales;
  select * from members;
  select * from menu;
  
-- 1. What is the total amount each customer spent at the restaurant?
SELECT customer_id, SUM(price)
FROM Sales S
JOIN Menu M ON S.product_id = M.product_id
GROUP BY customer_id;

-- 2. How many days has each customer visited the restaurant?
SELECT customer_id, COUNT(DISTINCT order_date) AS Days
FROM Sales
GROUP BY customer_id;

-- 3. What was the first item from the menu purchased by each customer?
WITH CTE AS (
    SELECT customer_id, product_name, order_date, 
		   ROW_NUMBER() OVER(PARTITION BY customer_id ORDER BY order_date) AS rn
    FROM Sales S
    JOIN Menu M ON S.product_id = M.product_id
)
SELECT customer_id, product_name, order_date
FROM CTE
WHERE rn = 1;


-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
SELECT product_name, COUNT(M.product_id) AS Order_Placed
FROM Sales S
JOIN Menu M ON S.product_id = M.product_id
GROUP BY product_name
ORDER BY Order_Placed DESC
LIMIT 1;

-- 5. Which item was the most popular for each customer?
WITH CTE AS (
    SELECT s.customer_id, m.product_name, COUNT(m.product_name) AS Count, 
           ROW_NUMBER() OVER(PARTITION BY s.customer_id ORDER BY COUNT(m.product_name) DESC) AS Rn
    FROM sales s
    JOIN menu m ON s.product_id = m.product_id
    GROUP BY s.customer_id, m.product_name
)
SELECT customer_id, product_name AS Most_Fav, Count AS Order_Placed
FROM CTE
WHERE Rn = 1;



-- 6. Which item was purchased first by the customer after they became a member?
WITH CTE AS (
    SELECT s.customer_id, m.product_name, 
		ROW_NUMBER() OVER(PARTITION BY s.customer_id ORDER BY s.order_date) AS rn
    FROM sales s
    JOIN members mem ON s.customer_id = mem.customer_id
    JOIN menu m ON s.product_id = m.product_id
    WHERE mem.join_date <= s.order_date
)
SELECT customer_id, product_name
FROM CTE
WHERE rn = 1;


-- 7. Which item was purchased just before the customer became a member?
WITH CTE AS (
    SELECT s.customer_id, m.product_name, 
		   ROW_NUMBER() OVER(PARTITION BY s.customer_id ORDER BY s.order_date DESC) AS rn
    FROM sales s
    JOIN members mem ON s.customer_id = mem.customer_id
    JOIN menu m ON s.product_id = m.product_id
    WHERE mem.join_date > s.order_date
)
SELECT customer_id, product_name
FROM CTE
WHERE rn = 1;


-- 8. What is the total items and amount spent for each member before they became a member?
SELECT s.customer_id, COUNT(product_name) AS Total_Items, SUM(price) AS Amount_Spent
FROM sales s
JOIN members mem ON s.customer_id = mem.customer_id
JOIN menu m ON s.product_id = m.product_id
WHERE order_date < join_Date
GROUP BY s.customer_id;



-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
WITH CTE AS (
    SELECT *, 
           CASE 
               WHEN product_name = 'sushi' THEN price * 10 * 2
               ELSE price * 10
           END AS Points
    FROM Menu
)
SELECT s.customer_id, SUM(Points) AS Total_Points
FROM Sales S
JOIN CTE ON S.product_id = CTE.product_id
GROUP BY s.customer_id;


	-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
SELECT s.customer_id,
       SUM(CASE WHEN s.order_date BETWEEN MEM.join_Date AND DATE_ADD(mem.join_date, INTERVAL 7 DAY) THEN 2 * m.price*10 ELSE m.price*10 END) AS total_points
FROM sales s
JOIN menu m ON s.product_id = m.product_id
JOIN members mem ON s.customer_id = mem.customer_id
WHERE s.order_date <= '2021-01-31'
GROUP BY s.customer_id;


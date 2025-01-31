SELECT * FROM walmart;

SELECT COUNT(*) FROM walmart;

SELECT payment 
  from walmart
  group by payment

SELECT COUNT(DISTINCT branch)
  FROM walmart;
  
SELECT MIN(quantity) FROM walmart;

--different payment methods and number of transactions with the quantity sold
SELECT payment,
COUNT(*) as no_payments,
SUM(quantity) as no_qty_sold
FROM walmart
GROUP BY payment

--Identifying the highest rated category in each branch, displaying branch and category
SELECT *
FROM
(   SELECT
         branch,
		 "product line",
		 AVG(rating) as avg_rating,
		 RANK() OVER(PARTITION BY branch ORDER BY AVG(rating) DESC) as rank
		 FROM walmart
		 GROUP BY 1, 2
		 ) as subquery
		 WHERE rank = 1;

--busiest day for each branch based on number of transactions
WITH branch_transaction_counts AS (
    SELECT
        branch,
        TO_CHAR(TO_DATE(date, 'DD/MM/YYYY'), 'Day') AS day_name,  -- Ensure correct format
        COUNT(*) AS no_transactions,
        RANK() OVER (PARTITION BY branch ORDER BY COUNT(*) DESC) AS rank
    FROM walmart
    GROUP BY branch, TO_CHAR(TO_DATE(date, 'DD/MM/YYYY'), 'Day')
)
SELECT *
FROM branch_transaction_counts
WHERE rank = 1;


 --to get the total quantity of items sold per payment and list both of them
SELECT payment,
SUM(quantity) as no_qty_sold
FROM walmart
GROUP BY payment

--get th avg,mim,max rating of each product line for each city and list the city with all of these
SELECT 
  city,
  "product line",
  MIN(rating) as min_rating,
  MAX(rating) as max_rating,
  AVG(rating) as avg_rating
 FROM walmart
 GROUP BY 1, 2 

--Calculation of total profit for each product line and list the highest from lowest profit
WITH product_profit AS (
    SELECT 
        "product line",
        SUM(total - cogs) AS total_profit,  -- Assuming total revenue and cost of goods sold (COGS)
        (SUM(total - cogs) / SUM(total)) * 100 AS profit_margin
    FROM walmart
    GROUP BY "product line"
)
SELECT 
    "product line", 
    total_profit, 
    profit_margin,
    CASE 
        WHEN total_profit = (SELECT MAX(total_profit) FROM product_profit) THEN 'Highest Profit'
        WHEN total_profit = (SELECT MIN(total_profit) FROM product_profit) THEN 'Lowest Profit'
        ELSE NULL
    END AS profit_category
FROM product_profit
ORDER BY total_profit DESC;

--most common payment method for each branch
WITH cte
AS
(SELECT
  branch,
  payment,
  COUNT(*) as total_trans,
  RANK() OVER(PARTITION BY branch ORDER BY COUNT(*) DESC) as rank
 FROM walmart
 GROUP BY 1, 2
)	
SELECT *
FROM cte
WHERE rank = 1

--categorize sales into 3 groups (as in morning,afternoon and evening) and total invoices in each shift 
SELECT
branch,
  CASE 
    WHEN EXTRACT(HOUR FROM(time::time)) < 12 THEN 'morning'
	WHEN EXTRACT(HOUR FROM(time::time)) BETWEEN 12 AND 17 THEN 'afternoon'
	ELSE 'evening'
  END day_time,
  COUNT(*)
FROM walmart
GROUP BY 1, 2
ORDER BY 1, 3 DESC

--finding the highest and lowest revenues in year 2019
SELECT 
    MAX(total) AS highest_revenue, 
    MIN(total) AS lowest_revenue
FROM walmart
WHERE EXTRACT(YEAR FROM TO_DATE(date, 'DD/MM/YY')) = 2019;

--dates with highest and lowest revenues in 2019
WITH daily_sales AS (
    SELECT 
        TO_DATE(date, 'DD/MM/YY') AS record_date, 
        SUM(total) AS daily_revenue
    FROM walmart
    WHERE EXTRACT(YEAR FROM TO_DATE(date, 'DD/MM/YY')) = 2019
    GROUP BY TO_DATE(date, 'DD/MM/YY')
)
SELECT 
    record_date, 
    daily_revenue,
    CASE 
        WHEN daily_revenue = (SELECT MAX(daily_revenue) FROM daily_sales) THEN 'Highest Revenue Day'
        WHEN daily_revenue = (SELECT MIN(daily_revenue) FROM daily_sales) THEN 'Lowest Revenue Day'
    END AS revenue_category
FROM daily_sales
WHERE daily_revenue IN (
    (SELECT MAX(daily_revenue) FROM daily_sales)
    UNION 
    (SELECT MIN(daily_revenue) FROM daily_sales)
);

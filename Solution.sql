-- MondayCoffee -- Data Analysis 

SELECT * FROM city;
SELECT * FROM products;
SELECT * FROM customers;
SELECT * FROM sales;




-- Q.1 Coffee Consumers Count
-- This query helps identify:
-- Market size potential in each city by estimating coffee drinkers
-- Prioritize cities for marketing spend based on consumer volume
-- Compare city rank with actual coffee consumption potential
SELECT 
    city_name,
    ROUND(
    (population * 0.25)/1000000, 
    2) as coffee_consumers_in_millions,
    city_rank
FROM city
ORDER BY 2 DESC;


-- Q.2 Total Revenue from Coffee Sales
-- This query helps identify:
-- Seasonal performance across cities (Q4 holiday season impact)
-- Revenue hotspots to focus business operations
-- Benchmark for future Q4 performance comparisons
SELECT 
    ci.city_name,
    SUM(s.total) as total_revenue
FROM sales as s
JOIN customers as c
ON s.customer_id = c.customer_id
JOIN city as ci
ON ci.city_id = c.city_id
WHERE 
    EXTRACT(YEAR FROM s.sale_date)  = 2023
    AND
    EXTRACT(quarter FROM s.sale_date) = 4
GROUP BY 1
ORDER BY 2 DESC;


-- Q.3 Sales Count for Each Product
-- This query helps identify:
-- Product popularity and customer preferences
-- Inventory planning and production focus areas
-- Potential candidates for discontinuation or promotion
SELECT 
    p.product_name,
    COUNT(s.sale_id) as total_orders
FROM products as p
LEFT JOIN
sales as s
ON s.product_id = p.product_id
GROUP BY 1
ORDER BY 2 DESC;


-- Q.4 Average Sales Amount per City
-- This query helps identify:
-- Customer spending patterns by location
-- Potential for premium product introduction in high-spending cities
-- Cities where customers may need more incentives to increase spend
SELECT 
    ci.city_name,
    SUM(s.total) as total_revenue,
    COUNT(DISTINCT s.customer_id) as total_cx,
    ROUND(
            SUM(s.total)::numeric/
                COUNT(DISTINCT s.customer_id)::numeric
            ,2) as avg_sale_pr_cx
    
FROM sales as s
JOIN customers as c
ON s.customer_id = c.customer_id
JOIN city as ci
ON ci.city_id = c.city_id
GROUP BY 1
ORDER BY 2 DESC;


-- Q.5 City Population and Coffee Consumers (25%)
-- This query helps identify:
-- Market penetration by comparing actual customers to potential
-- Growth opportunities in under-penetrated markets
-- Saturation levels in different cities
WITH city_table as 
(
    SELECT 
        city_name,
        ROUND((population * 0.25)/1000000, 2) as coffee_consumers
    FROM city
),
customers_table
AS
(
    SELECT 
        ci.city_name,
        COUNT(DISTINCT c.customer_id) as unique_cx
    FROM sales as s
    JOIN customers as c
    ON c.customer_id = s.customer_id
    JOIN city as ci
    ON ci.city_id = c.city_id
    GROUP BY 1
)
SELECT 
    customers_table.city_name,
    city_table.coffee_consumers as coffee_consumer_in_millions,
    customers_table.unique_cx
FROM city_table
JOIN 
customers_table
ON city_table.city_name = customers_table.city_name;


-- Q6 Top Selling Products by City
-- This query helps identify:
-- Regional product preferences for localized marketing
-- Potential for product bundling strategies
-- Inventory distribution optimization opportunities
SELECT * 
FROM 
(
    SELECT 
        ci.city_name,
        p.product_name,
        COUNT(s.sale_id) as total_orders,
        DENSE_RANK() OVER(PARTITION BY ci.city_name ORDER BY COUNT(s.sale_id) DESC) as rank
    FROM sales as s
    JOIN products as p
    ON s.product_id = p.product_id
    JOIN customers as c
    ON c.customer_id = s.customer_id
    JOIN city as ci
    ON ci.city_id = c.city_id
    GROUP BY 1, 2
) as t1
WHERE rank <= 3;



-- Q.7 Customer Segmentation by City
-- This query helps identify:
-- Customer base concentration in different regions
-- Market saturation levels by geography
-- Potential for customer acquisition campaigns
SELECT * FROM products;

SELECT 
    ci.city_name,
    COUNT(DISTINCT c.customer_id) as unique_cx
FROM city as ci
LEFT JOIN
customers as c
ON c.city_id = ci.city_id
JOIN sales as s
ON s.customer_id = c.customer_id
WHERE 
    s.product_id IN (1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14)
GROUP BY 1;


-- Q.8 Average Sale vs Rent
-- This query helps identify:
-- Cost-effectiveness of operations in each city
-- Pricing strategy adjustments needed based on local costs
-- Profitability by geographic market
WITH city_table
AS
(
    SELECT 
        ci.city_name,
        SUM(s.total) as total_revenue,
        COUNT(DISTINCT s.customer_id) as total_cx,
        ROUND(
                SUM(s.total)::numeric/
                    COUNT(DISTINCT s.customer_id)::numeric
                ,2) as avg_sale_pr_cx
        
    FROM sales as s
    JOIN customers as c
    ON s.customer_id = c.customer_id
    JOIN city as ci
    ON ci.city_id = c.city_id
    GROUP BY 1
    ORDER BY 2 DESC
),
city_rent
AS
(SELECT 
    city_name, 
    estimated_rent
FROM city
)
SELECT 
    cr.city_name,
    cr.estimated_rent,
    ct.total_cx,
    ct.avg_sale_pr_cx,
    ROUND(
        cr.estimated_rent::numeric/
                                    ct.total_cx::numeric
        , 2) as avg_rent_per_cx
FROM city_rent as cr
JOIN city_table as ct
ON cr.city_name = ct.city_name
ORDER BY 4 DESC;


-- Q.9 Monthly Sales Growth
-- This query helps identify:
-- Sales trends and seasonal patterns
-- Growth or decline markets needing attention
-- Effectiveness of monthly marketing campaigns
WITH
monthly_sales
AS
(
    SELECT 
        ci.city_name,
        EXTRACT(MONTH FROM sale_date) as month,
        EXTRACT(YEAR FROM sale_date) as YEAR,
        SUM(s.total) as total_sale
    FROM sales as s
    JOIN customers as c
    ON c.customer_id = s.customer_id
    JOIN city as ci
    ON ci.city_id = c.city_id
    GROUP BY 1, 2, 3
    ORDER BY 1, 3, 2
),
growth_ratio
AS
(
        SELECT
            city_name,
            month,
            year,
            total_sale as cr_month_sale,
            LAG(total_sale, 1) OVER(PARTITION BY city_name ORDER BY year, month) as last_month_sale
        FROM monthly_sales
)
SELECT
    city_name,
    month,
    year,
    cr_month_sale,
    last_month_sale,
    ROUND(
        (cr_month_sale-last_month_sale)::numeric/last_month_sale::numeric * 100
        , 2
        ) as growth_ratio

FROM growth_ratio
WHERE 
    last_month_sale IS NOT NULL;


-- Q.10 Market Potential Analysis
-- This query helps identify:
-- High-potential markets for expansion
-- Cost-to-revenue ratios by location
-- Strategic priorities for resource allocation
WITH city_table
AS
(
    SELECT 
        ci.city_name,
        SUM(s.total) as total_revenue,
        COUNT(DISTINCT s.customer_id) as total_cx,
        ROUND(
                SUM(s.total)::numeric/
                    COUNT(DISTINCT s.customer_id)::numeric
                ,2) as avg_sale_pr_cx
        
    FROM sales as s
    JOIN customers as c
    ON s.customer_id = c.customer_id
    JOIN city as ci
    ON ci.city_id = c.city_id
    GROUP BY 1
    ORDER BY 2 DESC
),
city_rent
AS
(
    SELECT 
        city_name, 
        estimated_rent,
        ROUND((population * 0.25)/1000000, 3) as estimated_coffee_consumer_in_millions
    FROM city
)
SELECT 
    cr.city_name,
    total_revenue,
    cr.estimated_rent as total_rent,
    ct.total_cx,
    estimated_coffee_consumer_in_millions,
    ct.avg_sale_pr_cx,
    ROUND(
        cr.estimated_rent::numeric/
                                    ct.total_cx::numeric
        , 2) as avg_rent_per_cx
FROM city_rent as cr
JOIN city_table as ct
ON cr.city_name = ct.city_name
ORDER BY 2 DESC;





-- Recomendation
-- City 1: Pune
-- 	1.Average rent per customer is very low.
-- 	2.Highest total revenue.
-- 	3.Average sales per customer is also high.

-- City 2: Delhi
-- 	1.Highest estimated coffee consumers at 7.7 million.
-- 	2.Highest total number of customers, which is 68.
-- 	3.Average rent per customer is 330 (still under 500).

-- City 3: Jaipur
-- 	1.Highest number of customers, which is 69.
-- 	2.Average rent per customer is very low at 156.
-- 	3.Average sales per customer is better at 11.6k.
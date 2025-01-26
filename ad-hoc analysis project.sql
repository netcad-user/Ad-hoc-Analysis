-- -- Codebasics SQL portfolio project resume challenge 4 --

--Request 1--
 select distinct market from dim_customer
 where customer ="Atliq Exclusive" and region = "APAC";
 
--Request 2--

WITH unique_products AS (
    SELECT 
        COUNT(DISTINCT CASE WHEN fiscal_year = 2020 THEN product_code END) AS unique_products_2020,
        COUNT(DISTINCT CASE WHEN fiscal_year = 2021 THEN product_code END) AS unique_products_2021
    FROM 
        fact_sales_monthly
)


SELECT 
    unique_products_2020,
    unique_products_2021,
    ROUND(((unique_products_2021 - unique_products_2020) / unique_products_2020) * 100, 2) AS percentage_chg
FROM 
    unique_products;
    
--Request 3--
select distinct (segment), count(product) as product_count from dim_product
group by segment
order by product_count desc

--Request 4--

WITH unique_products_by_segment AS (
    
    SELECT 
        dp.segment,
        COUNT(DISTINCT CASE WHEN fsm.fiscal_year = 2020 THEN fsm.product_code END) AS product_count_2020,
        COUNT(DISTINCT CASE WHEN fsm.fiscal_year = 2021 THEN fsm.product_code END) AS product_count_2021
    FROM 
        fact_sales_monthly fsm
    JOIN 
        dim_product dp ON fsm.product_code = dp.product_code
    WHERE 
        fsm.fiscal_year IN (2020, 2021)
    GROUP BY 
        dp.segment
)


SELECT 
    segment,
    product_count_2020,
    product_count_2021,
    (product_count_2021 - product_count_2020) AS difference
FROM 
    unique_products_by_segment
ORDER BY 
    difference DESC;
--Request 5--
SELECT
    dp.product_code,
    dp.product,
    fmc.manufacturing_cost
FROM
    fact_manufacturing_cost fmc
JOIN
    dim_product dp ON fmc.product_code = dp.product_code
WHERE
    fmc.manufacturing_cost = (
        -- Sub-query to get the highest manufacturing cost
        SELECT MAX(manufacturing_cost)
        FROM fact_manufacturing_cost
    )
   OR fmc.manufacturing_cost = (
        -- Sub-query to get the lowest manufacturing cost
        SELECT MIN(manufacturing_cost)
        FROM fact_manufacturing_cost
    );
--Request 6--
SELECT
    dc.customer_code,
    dc.customer,
    ROUND(AVG(fpd.pre_invoice_discount_pct), 2) AS average_discount_percentage
FROM
    fact_pre_invoice_deductions fpd
JOIN
    dim_customer dc ON fpd.customer_code = dc.customer_code
WHERE
    fpd.fiscal_year = 2021
    AND dc.market = 'India'
GROUP BY
    dc.customer_code, dc.customer
ORDER BY
    average_discount_percentage DESC
LIMIT 5;

--Request 7--

SELECT 
    MONTH(fsm.date) AS Month,
    YEAR(fsm.date) AS Year,
    ROUND(SUM(fgp.gross_price * fsm.sold_quantity), 2) AS Gross_Sales_Amount
FROM 
    fact_sales_monthly fsm
JOIN 
    dim_customer dc ON fsm.customer_code = dc.customer_code
JOIN 
    fact_gross_price fgp ON fsm.product_code = fgp.product_code 
                        AND fsm.fiscal_year = fgp.fiscal_year
WHERE 
    dc.customer = 'Atliq Exclusive'
GROUP BY 
    YEAR(fsm.date), MONTH(fsm.date)
ORDER BY 
    Year, Month;
    
    SELECT 
    Month_Name, 
    Year, 
    Gross_Sales_Amount
FROM (
    SELECT 
        MONTH(fsm.date) AS Month,
        YEAR(fsm.date) AS Year,
        ROUND(SUM(fgp.gross_price * fsm.sold_quantity), 2) AS Gross_Sales_Amount
    FROM 
        fact_sales_monthly fsm
    JOIN 
        dim_customer dc ON fsm.customer_code = dc.customer_code
    JOIN 
        fact_gross_price fgp ON fsm.product_code = fgp.product_code 
                            AND fsm.fiscal_year = fgp.fiscal_year
    WHERE 
        dc.customer = 'Atliq Exclusive'
    GROUP BY 
        YEAR(fsm.date), MONTH(fsm.date)
) AS sales_data
JOIN (
    SELECT 1 AS Month, 'January' AS Month_Name
    UNION ALL SELECT 2, 'February'
    UNION ALL SELECT 3, 'March'
    UNION ALL SELECT 4, 'April'
    UNION ALL SELECT 5, 'May'
    UNION ALL SELECT 6, 'June'
    UNION ALL SELECT 7, 'July'
    UNION ALL SELECT 8, 'August'
    UNION ALL SELECT 9, 'September'
    UNION ALL SELECT 10, 'October'
    UNION ALL SELECT 11, 'November'
    UNION ALL SELECT 12, 'December'
) AS months ON sales_data.Month = months.Month
ORDER BY 
    Year, sales_data.Month desc



-- Request 8--
WITH SalesWithQuarter AS (
    SELECT 
        CASE 
            
            WHEN MONTH(date) IN (9, 10, 11) THEN 'Q1'
            
            WHEN MONTH(date) IN (12, 1, 2) THEN 'Q2'
            
            WHEN MONTH(date) IN (3, 4, 5) THEN 'Q3'
            
            WHEN MONTH(date) IN (6, 7, 8) THEN 'Q4'
        END AS Quarter,
        sold_quantity
    FROM 
        fact_sales_monthly
    WHERE 
        fiscal_year = 2020
)

SELECT 
    Quarter,
    SUM(sold_quantity) AS total_sold_quantity
FROM 
    SalesWithQuarter
GROUP BY 
    Quarter
ORDER BY 
    total_sold_quantity DESC;
    
--Request 9--

WITH ChannelSales AS (
    SELECT 
        dc.channel,
        ROUND(SUM(fgp.gross_price * fsm.sold_quantity) / 1000000, 2) AS gross_sales_mln
    FROM 
        fact_sales_monthly fsm
    JOIN 
        dim_customer dc ON fsm.customer_code = dc.customer_code
    JOIN 
        fact_gross_price fgp ON fsm.product_code = fgp.product_code 
                            AND fsm.fiscal_year = fgp.fiscal_year
    WHERE 
        fsm.fiscal_year = 2021
    GROUP BY 
        dc.channel
),
TotalSales AS (
    SELECT 
        SUM(gross_sales_mln) AS total_gross_sales_mln
    FROM 
        ChannelSales
)

SELECT 
    cs.channel,
    cs.gross_sales_mln,
    ROUND((cs.gross_sales_mln / ts.total_gross_sales_mln) * 100, 2) AS percentage
FROM 
    ChannelSales cs, TotalSales ts
ORDER BY 
    cs.gross_sales_mln DESC;
    
--- Request 10 --

WITH ProductSales AS (
    SELECT 
        dp.division,
        fsm.product_code,
        dp.product,
        SUM(fsm.sold_quantity) AS total_sold_quantity,
        RANK() OVER (PARTITION BY dp.division ORDER BY SUM(fsm.sold_quantity) DESC) AS rank_order
    FROM 
        fact_sales_monthly fsm
    JOIN 
        dim_product dp ON fsm.product_code = dp.product_code
    WHERE 
        fsm.fiscal_year = 2021
    GROUP BY 
        dp.division, fsm.product_code, dp.product
)

SELECT 
    division,
    product_code,
    product,
    total_sold_quantity,
    rank_order
FROM 
    ProductSales
WHERE 
    rank_order <= 3
ORDER BY 
    division, rank_order;









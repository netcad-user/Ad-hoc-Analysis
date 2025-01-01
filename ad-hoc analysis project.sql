-- -- Codebasics SQL portfolio project resume challenge 4 --

# Provide the list of markets in which customer "Atliq Exclusive" operates its
# business in the APAC region.
 select distinct market from dim_customer
 where customer ="Atliq Exclusive" and region = "APAC";
 
# What is the percentage of unique product increase in 2021 vs. 2020? The
# final output contains these fields

WITH unique_products AS (
    -- Get unique product count for 2020 and 2021
    SELECT 
        COUNT(DISTINCT CASE WHEN fiscal_year = 2020 THEN product_code END) AS unique_products_2020,
        COUNT(DISTINCT CASE WHEN fiscal_year = 2021 THEN product_code END) AS unique_products_2021
    FROM 
        fact_sales_monthly
)

-- Calculate percentage change
SELECT 
    unique_products_2020,
    unique_products_2021,
    ROUND(((unique_products_2021 - unique_products_2020) / unique_products_2020) * 100, 2) AS percentage_chg
FROM 
    unique_products;
    
#Provide a report with all the unique product counts for each segment and
#sort them in descending order of product counts. The final output contains
#2 fields
select distinct (segment), count(product) as product_count from dim_product
group by segment
order by product_count desc

#Which segment had the most increase in unique products in
#2021 vs 2020? The final output contains these fields;

WITH unique_products_by_segment AS (
    -- Get unique product counts by segment for 2020 and 2021
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

-- Calculate difference and get the segment with the most increase
SELECT 
    segment,
    product_count_2020,
    product_count_2021,
    (product_count_2021 - product_count_2020) AS difference
FROM 
    unique_products_by_segment
ORDER BY 
    difference DESC;
#Get the products that have the highest and lowest manufacturing costs.
#The final output should contain these fields

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
#Generate a report which contains the top 5 customers who received an
#average high pre_invoice_discount_pct for the fiscal year 2021 and in the
#Indian market.
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

#Get the complete report of the Gross sales amount for the customer “Atliq
#Exclusive” for each month. This analysis helps to get an idea of low and
#high-performing months and take strategic decisions.
#The final report contains these columns:Month
#Year
#Gross sales Amount

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



#In which quarter of 2020, got the maximum total_sold_quantity? The final
#output contains these fields sorted by the total_sold_quantity,
#Quarter
#total_sold_quantity

WITH SalesWithQuarter AS (
    SELECT 
        CASE 
            -- Fiscal Q1: September to November (09 to 11 of the previous year)
            WHEN MONTH(date) IN (9, 10, 11) THEN 'Q1'
            -- Fiscal Q2: December to February (12 of previous year to 02 of current year)
            WHEN MONTH(date) IN (12, 1, 2) THEN 'Q2'
            -- Fiscal Q3: March to May (03 to 05 of current year)
            WHEN MONTH(date) IN (3, 4, 5) THEN 'Q3'
            -- Fiscal Q4: June to August (06 to 08 of current year)
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
    
#Which channel helped to bring more gross sales in the fiscal year 2021
#and the percentage of contribution? The final output contains these fields,
#channel
#gross_sales_mln
#percentage

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
    
#Get the Top 3 products in each division that have a high
#total_sold_quantity in the fiscal_year 2021? The final output contains these
#fields,
#division
#product_code
#product
#total_sold_quantity
#rank_order

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









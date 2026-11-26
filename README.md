# Bike-Retail-Sales-Operations-Analysis
SQL analysis of a 3-store bicycle retailer in MySQL: 12 business questions on sales, customers, shipping and inventory using JOINs, CTEs and window functions.
# 🚲 BikeStores Sales & Operations Analysis (MySQL)

SQL analysis of a 3-store bicycle retailer: 12 business questions on sales, customers, shipping and inventory using JOINs, CTEs and window functions.

## ⭐ Summary 
- **Situation:** A bicycle retailer with 3 stores had sales, customer and inventory data across 9 tables (1,615 orders, 1,445 customers, 321 products) but no clear view of what drives revenue.
- **Task:** Validate the data and answer 12 business questions on revenue, customers, operations and stock.
- **Action:** Checked data quality, then wrote 14 MySQL queries using multi-table JOINs, CTEs, window functions (`LAG`, `RANK`, `NTILE`) and self-joins. Revenue = `quantity × list_price × (1 − discount)` on completed orders only ($6.66M).
- **Result:** Found concentration, retention and fulfilment problems (below).

## 📊 Key findings
- **One store drives 70.6% of revenue** (Baldwin Bikes, NY), and **Trek alone brings 58.8%**.
- **0% repeat customers:** every customer bought only once, a clear retention gap.
- **26–37% of orders ship late**, even though the average shipping time is about 2 days.
- **Top third of customers generate 65.9% of revenue.**
- **Discounts cost about $775K (10.4%)** of gross sales, applied almost evenly across categories.
- **16 best sellers are nearly out of stock**, while one 2018 model has about **$242K of unsold stock**.

## ▶️ How to run
1. Run `01_setup_bikestores.sql` (change the CSV folder path first). It creates the tables and loads the data.
2. Run `02_business_queries.sql` to see all 12 analyses.

## 🛠️ Skills
MySQL · CTEs · Window functions · Joins · Data validation · Business analysis


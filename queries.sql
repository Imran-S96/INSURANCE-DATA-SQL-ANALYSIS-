-- CREATE VIEW COMBINING TABLES

CREATE VIEW VIEW_INSURANCE AS(
SELECT *
FROM CUSTOMERS
LEFT JOIN POLICIES USING(customer_id)
LEFT JOIN CLAIMS USING(policy_id));

-- 📊 1. Business Intelligence (BI) Team
-- Q1: What is the average claim amount by region?

SELECT 
    region, 
    ROUND(AVG(claim_amount),2) AS avg_claim_amount
FROM VIEW_INSURANCE
WHERE region IS NOT NULL
GROUP BY region;

-- Q2: How many total policies are active in the current year per region?

SELECT COUNT(*) AS total_current_policies
FROM VIEW_INSURANCE
WHERE policy_end_date >= '2025-01-01';

-- Q3: Which vehicle types have the highest average claim amounts?

SELECT 
    vehicle_type, 
    ROUND(AVG(claim_amount),2) AS avg_claims_amount
FROM VIEW_INSURANCE
WHERE vehicle_type IS NOT NULL
GROUP BY vehicle_type
ORDER BY AVG(claim_amount) DESC ;

-- Q4: What is the trend of claims over the past 12 months? (month-wise count or amount)

SELECT
    TO_CHAR(claim_date, 'YYYY-MM') AS claim_month,
    COUNT(*) AS total_claims,
    SUM(claim_amount) AS total_claim_amount
FROM claims
WHERE claim_date >= DATEADD(MONTH, -12, CURRENT_DATE)
GROUP BY TO_CHAR(claim_date, 'YYYY-MM')
ORDER BY claim_month;


-- Q5: What is the total premium collected by payment frequency?

SELECT
    payment_frequency,
    SUM(premium_amount) AS total_premium_collected,
    COUNT(*) AS total_policies
FROM policies
GROUP BY payment_frequency
ORDER BY total_premium_collected DESC;


-- 💼 2. Underwriting Team
-- Q6: What’s the average coverage amount for different vehicle types?

SELECT 
    vehicle_type, 
    ROUND(AVG(coverage_amount),2) AS avg_coverage_amount
FROM VIEW_INSURANCE
GROUP BY vehicle_type; 


-- Q7: How many policies have expired without any claims?

SELECT COUNT(*) AS count_policy_no_claim
FROM VIEW_INSURANCE
WHERE policy_id IS NOT NULL AND claim_id IS NULL;

-- Q8: Find customers with multiple high-value claims (e.g., over £7,500 each).

WITH CTE_HIGH_VALUE_CLAIMS AS (
SELECT 
    customer_id, 
    claim_amount, 
    RANK() OVER (PARTITION BY customer_id ORDER BY claim_amount) AS rnk
FROM VIEW_INSURANCE
WHERE claim_amount > 7500)

SELECT customer_id
FROM CTE_HIGH_VALUE_CLAIMS
GROUP BY customer_id
HAVING COUNT(rnk) > 1;

-- Q9: What’s the average age of customers who submitted a claim vs. those who didn’t?

SELECT 
    ROUND(AVG(FLOOR(DATEDIFF(day, date_of_birth, CURRENT_DATE) / 365.25)),1) AS avg_age, 
    'Y' AS claimed
FROM VIEW_INSURANCE
WHERE claim_id IS NOT NULL

UNION ALL

SELECT 
    ROUND(AVG(FLOOR(DATEDIFF(day, date_of_birth, CURRENT_DATE) / 365.25)),1) AS avg_age, 
    'N' AS claimed
FROM VIEW_INSURANCE
WHERE claim_id IS NULL;

-- 🕵️‍♀️ 3. Fraud Investigation Team
-- Q10: How many claims are marked as fraud per region?

SELECT 
    region, 
    COUNT(fraud_flag) AS true_fraud_count
FROM VIEW_INSURANCE
WHERE fraud_flag = 'True'
GROUP BY region;

-- Q11: Are there agents who are linked to a higher number of fraudulent claims?

WITH FRAUD_CLAIMS AS(
SELECT 
    agent_id, 
    COUNT(fraud_flag) AS true_fraud_count
FROM VIEW_INSURANCE
WHERE fraud_flag = 'True'
GROUP BY agent_id
ORDER BY COUNT(fraud_flag) DESC)

SELECT *
FROM FRAUD_CLAIMS
WHERE true_fraud_count > 10 ;

-- Q12: What incident types are more likely to be flagged as fraud?

SELECT 
    incident_type, 
    COUNT(fraud_flag) AS true_fraud_count
FROM VIEW_INSURANCE
WHERE fraud_flag = 'True'
GROUP BY incident_type
ORDER BY COUNT(fraud_flag) DESC


-- Q13: What’s the fraud rate (fraudulent claims ÷ total claims) by region?

SELECT 
    region,
    (SUM(CASE WHEN fraud_flag = 'True' THEN claim_amount ELSE 0 END) /
    SUM(claim_amount)) AS fraud_rate
FROM VIEW_INSURANCE
WHERE fraud_flag IS NOT NULL
GROUP BY region;

 
-- 📞 4. Customer Service Team
-- Q14: List all customers who have pending or rejected claims in the last 6 months.

SELECT DISTINCT 
    customer_id,
    customer_name,
    gender,
    date_of_birth,
    claim_status,
    claim_date
FROM VIEW_INSURANCE
WHERE claim_status IN ('Under Review', 'Rejected')
  AND claim_date >= DATEADD(MONTH, -6, CURRENT_DATE)
ORDER BY claim_date DESC;


-- Q15: Which customers have had more than 2 claims in the last year?

SELECT 
    customer_id,
    customer_name,
    COUNT(claim_id) AS claim_count
FROM VIEW_INSURANCE
WHERE claim_date >= DATEADD(YEAR, -1, CURRENT_DATE)
GROUP BY customer_id, customer_name
HAVING COUNT(claim_id) > 2
ORDER BY claim_count DESC;


-- Q16: What’s the average resolution rate per claim status?

SELECT 
    claim_status,
    COUNT(*) AS total_claims,
    ROUND(AVG(claim_amount),2) AS avg_claim_amount
FROM claims
GROUP BY claim_status;


-- 🧮 5. Finance Team
-- Q17: What is the total premium vs. total claims paid per region?

SELECT 
    region,
    SUM(premium_amount) AS total_premium,
    SUM(claim_amount) AS total_claims
FROM VIEW_INSURANCE
WHERE region IS NOT NULL AND claim_status = 'Approved'
GROUP BY region;

-- Q18: Identify policies where claim amount exceeds coverage amount.

SELECT policy_id
FROM VIEW_INSURANCE
WHERE coverage_amount < claim_amount ;

-- Q19: What’s the total value of claims still under review?

SELECT SUM(claim_amount) AS sum_total_claims
FROM VIEW_INSURANCE
WHERE claim_status = 'Under Review';


-- 🔍 6. General Ad-Hoc Analysis
-- Q20: Who are the top 10 customers by total claim amount?

SELECT 
    customer_id, 
    SUM(claim_amount) AS total_claim_amount
FROM VIEW_INSURANCE
WHERE claim_amount IS NOT NULL
GROUP BY customer_id
ORDER BY SUM(claim_amount) DESC
LIMIT 10;

-- Q21: What’s the claim frequency by gender or age group?

SELECT 
    gender, 
    COUNT(claim_id) AS claim_frequency 
FROM VIEW_INSURANCE
WHERE claim_id IS NOT NULL
GROUP BY gender;



-- Q22: How many claims are made per policy type per region?

SELECT 
    region, 
    policy_type, COUNT(claim_id) AS claims_count
FROM VIEW_INSURANCE
WHERE claim_id IS NOT NULL
GROUP BY region, policy_type;


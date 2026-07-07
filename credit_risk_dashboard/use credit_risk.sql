 use credit_risk;
CREATE TABLE credit_risk_clean AS
SELECT 
    CASE 
        WHEN person_age > 90 THEN NULL 
        ELSE person_age 
    END AS applicant_age,
    
    CASE 
        WHEN person_emp_length > 50 THEN NULL
        ELSE person_emp_length
    END AS employment_length,
    
    person_income AS annual_income,
    person_home_ownership AS housing_status,
    loan_intent,
    loan_amnt AS loan_amount,
    
    COALESCE(loan_int_rate, (SELECT AVG(loan_int_rate) FROM credit_risk_dataset)) AS interest_rate,
    
    loan_status AS is_default, 
    
    ROUND((loan_amnt / NULLIF(person_income, 0)), 4) AS debt_to_income_ratio,
    
    CASE 
        WHEN loan_status = 1 THEN 'High Risk (Defaulted)'
        WHEN (loan_amnt / NULLIF(person_income, 0)) > 0.35 THEN 'Medium Risk (High DTI)'
        ELSE 'Low Risk'
    END AS risk_segment
FROM credit_risk_dataset;

select * from credit_risk_clean LIMIT 10;


-- 1. Remove the old table if it exists so it doesn't cause an error
DROP TABLE IF EXISTS credit_risk_clean;

2. Create the clean table
CREATE TABLE credit_risk_clean AS
SELECT
    CASE
        WHEN person_age > 90 THEN NULL
        ELSE person_age
    END AS applicant_age,
    
    CASE
        WHEN person_emp_length > 50 THEN NULL
        ELSE person_emp_length
    END AS employment_length,
    
    person_income AS annual_income,
    person_home_ownership AS housing_status,
    loan_intent,
    loan_amnt AS loan_amount,
    COALESCE(loan_int_rate, (SELECT AVG(loan_int_rate) FROM credit_risk_dataset)) AS loan_int_rate,-- 
    loan_status AS is_default,
    ROUND((loan_amnt / NULLIF(person_income, 0)), 4) AS debt_to_income_ratio,
    
    CASE
        WHEN loan_status = 1 THEN 'High Risk (Defaulted)'
        WHEN (loan_amnt / NULLIF(person_income, 0)) > 0.35 THEN 'Medium Risk'
        ELSE 'Low Risk'
    END AS risk_segment
FROM credit_risk_dataset;

-- 3. View the results (spelling fixed here)
SELECT * FROM credit_risk_clean LIMIT 10;

USE credit_risk;

-- 1. Recreate the clean table safely
DROP TABLE IF EXISTS credit_risk_clean;

CREATE TABLE credit_risk_clean AS
SELECT
    CASE
        WHEN person_age > 90 THEN NULL
        ELSE person_age
    END AS applicant_age,
    
    CASE
        WHEN person_emp_length > 50 THEN NULL
        ELSE person_emp_length
    END AS employment_length,
    
    person_income AS annual_income,
    person_home_ownership AS housing_status,
    loan_intent,
    loan_amnt AS loan_amount,
    COALESCE(loan_int_rate, (SELECT AVG(loan_int_rate) FROM credit_risk_dataset)) AS loan_int_rate,
    loan_status AS is_default,
    ROUND((loan_amnt / NULLIF(person_income, 0)), 4) AS debt_to_income_ratio,
    
    CASE
        WHEN loan_status = 1 THEN 'High Risk (Defaulted)'
        WHEN (loan_amnt / NULLIF(person_income, 0)) > 0.35 THEN 'Medium Risk'
        ELSE 'Low Risk'
    END AS risk_segment
FROM credit_risk_dataset;

SELECT 
    risk_segment, 
    COUNT(*) AS total_applicants,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM credit_risk_clean), 2) AS percentage
FROM credit_risk_clean
GROUP BY risk_segment
ORDER BY total_applicants DESC;
SELECT 
    loan_intent, 
    COUNT(*) AS total_loans,
    SUM(is_default) AS total_defaults,
    ROUND(AVG(is_default) * 100, 2) AS default_rate_percentage
FROM credit_risk_clean
GROUP BY loan_intent
ORDER BY default_rate_percentage DESC;
SELECT 
    is_default,
    ROUND(AVG(annual_income), 2) AS avg_annual_income,
    ROUND(AVG(loan_amount), 2) AS avg_loan_amount,
    ROUND(AVG(debt_to_income_ratio) * 100, 2) AS avg_dti_percentage
FROM credit_risk_clean
GROUP BY is_default;


SELECT 
    loan_intent, 
    COUNT(*) AS total_loans,
    SUM(is_default) AS total_defaults,
    ROUND(AVG(is_default) * 100, 2) AS default_rate_percentage
FROM credit_risk_clean
GROUP BY loan_intent
ORDER BY default_rate_percentage DESC;


SELECT 
    CASE 
        WHEN debt_to_income_ratio <= 0.15 THEN 'Low DTI (<=15%)'
        WHEN debt_to_income_ratio <= 0.35 THEN 'Medium DTI (16-35%)'
        ELSE 'High DTI (>35%)'
    END AS dti_bucket,
    COUNT(*) AS borrower_count,
    ROUND(AVG(is_default) * 100, 2) AS default_rate_percentage
FROM credit_risk_clean
GROUP BY dti_bucket
ORDER BY dti_bucket;
SELECT 
    housing_status, 
    COUNT(*) AS total_borrowers,
    ROUND(AVG(is_default) * 100, 2) AS default_rate_percentage,
    ROUND(AVG(annual_income), 0) AS avg_income
FROM credit_risk_clean
GROUP BY housing_status
ORDER BY default_rate_percentage DESC;


SELECT 
    COUNT(*) AS total_rows,
    SUM(CASE WHEN applicant_age IS NULL THEN 1 ELSE 0 END) AS null_ages,
    SUM(CASE WHEN employment_length IS NULL THEN 1 ELSE 0 END) AS null_employment_lengths,
    SUM(CASE WHEN loan_int_rate IS NULL THEN 1 ELSE 0 END) AS null_interest_rates,
    SUM(CASE WHEN debt_to_income_ratio IS NULL THEN 1 ELSE 0 END) AS null_dti_ratios
FROM credit_risk_clean;


CREATE OR REPLACE VIEW v_credit_risk_analytics AS
SELECT * FROM credit_risk_clean;
SELECT * FROM v_credit_risk_analytics LIMIT 10;
SELECT 
    risk_segment,
    COUNT(*) AS total_customers,
    ROUND(AVG(applicant_age), 1) AS avg_age,
    ROUND(AVG(annual_income), 0) AS avg_income,
    ROUND(AVG(loan_amount), 0) AS avg_loan,
    ROUND(AVG(loan_int_rate), 2) AS avg_interest_rate
FROM v_credit_risk_analytics
GROUP BY risk_segment;
SELECT 
    housing_status,
    loan_intent,
    COUNT(*) AS loan_count,
    ROUND(AVG(is_default) * 100, 2) AS default_rate_percentage,
    ROUND(AVG(loan_amount), 0) AS avg_loan_size
FROM v_credit_risk_analytics
GROUP BY housing_status, loan_intent
HAVING loan_count > 5
ORDER BY default_rate_percentage DESC;
WITH RankedBorrowers AS (
    SELECT 
        loan_intent,
        annual_income,
        loan_amount,
        risk_segment,
        DENSE_RANK() OVER (PARTITION BY loan_intent ORDER BY annual_income DESC) as income_rank
    FROM v_credit_risk_analytics
)
SELECT * 
FROM RankedBorrowers 
WHERE income_rank <= 3;

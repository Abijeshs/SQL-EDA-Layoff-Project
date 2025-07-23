-- 📊 EXPLORATORY DATA ANALYSIS (EDA) ON LAYOFF DATASET

-- 1. View the Cleaned Data
SELECT * FROM layoffs_staging2;

-- 2. Find Maximum Layoffs
SELECT 
    MAX(total_laid_off) AS max_laid_off,
    MAX(percentage_laid_off) AS max_percentage_laid_off
FROM layoffs_staging2;

-- 3. Companies with 100% Layoffs
SELECT *
FROM layoffs_staging2
WHERE percentage_laid_off = 1
ORDER BY total_laid_off DESC;

-- 4. Total Layoffs by Company
SELECT 
    company, 
    SUM(total_laid_off) AS total_laid_off
FROM layoffs_staging2
GROUP BY company
ORDER BY total_laid_off DESC;

-- 5. Earliest and Latest Layoff Dates
SELECT 
    MIN(`date`) AS starting_date, 
    MAX(`date`) AS ending_date
FROM layoffs_staging2;

-- 6. Total Layoffs by Country
SELECT 
    country, 
    SUM(total_laid_off) AS total_laid_off
FROM layoffs_staging2
GROUP BY country
ORDER BY total_laid_off DESC;

-- 7. Year-wise Layoffs
SELECT 
    YEAR(`date`) AS year, 
    SUM(total_laid_off) AS total_laid_off
FROM layoffs_staging2
GROUP BY YEAR(`date`)
ORDER BY total_laid_off DESC;

-- 8. Month-wise Layoffs with Rolling Total
WITH monthly_layoffs AS (
    SELECT 
        MONTH(`date`) AS month, 
        SUM(total_laid_off) AS total_laid_off
    FROM layoffs_staging2
    WHERE MONTH(`date`) IS NOT NULL
    GROUP BY MONTH(`date`)
)
SELECT 
    month, 
    total_laid_off,
    SUM(total_laid_off) OVER (ORDER BY month) AS rolling_total
FROM monthly_layoffs;

-- 9. Company-Wise Layoffs by Year
SELECT 
    company, 
    YEAR(`date`) AS year, 
    SUM(total_laid_off) AS total_laid_off
FROM layoffs_staging2
GROUP BY company, YEAR(`date`)
ORDER BY total_laid_off DESC;

-- 10. Top 5 Companies with Highest Layoffs per Year (Using Ranking)
WITH company_year_summary AS (
    SELECT 
        company, 
        YEAR(`date`) AS year, 
        SUM(total_laid_off) AS total_laid_off
    FROM layoffs_staging2
    GROUP BY company, YEAR(`date`)
),
company_year_ranked AS (
    SELECT 
        *, 
        DENSE_RANK() OVER (PARTITION BY year ORDER BY total_laid_off DESC) AS rank
    FROM company_year_summary
    WHERE year IS NOT NULL
)
SELECT *
FROM company_year_ranked
WHERE rank <= 5;
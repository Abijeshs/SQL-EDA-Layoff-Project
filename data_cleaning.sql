-- 🧹 DATA CLEANING SCRIPT FOR LAYOFF DATASET

-- 1. Load Initial Data
SELECT * FROM layoffs;

-- 2. Create Staging Table
CREATE TABLE layoffs_staging LIKE layoffs;

-- Insert data into staging table
INSERT INTO layoffs_staging
SELECT * FROM layoffs;

-- 3. Identify Duplicates Using ROW_NUMBER
SELECT *,
ROW_NUMBER() OVER (PARTITION BY company, industry, total_laid_off, `date`, stage, country, funds_raised_millions) AS row_num
FROM layoffs_staging;

-- 4. Create CTE for duplicate identification
WITH duplicate_cte AS (
    SELECT *,
    ROW_NUMBER() OVER (PARTITION BY company, industry, total_laid_off, `date`, stage, country, funds_raised_millions) AS row_num
    FROM layoffs_staging
)
SELECT * FROM duplicate_cte
WHERE row_num > 1;

-- 5. Create Cleaned Table (layoffs_staging2) with row numbers
CREATE TABLE layoffs_staging2 (
    company TEXT,
    location TEXT,
    industry TEXT,
    total_laid_off INT DEFAULT NULL,
    percentage_laid_off TEXT,
    `date` TEXT,
    stage TEXT,
    country TEXT,
    funds_raised_millions INT DEFAULT NULL,
    row_number INT
);

-- Insert with row numbers
INSERT INTO layoffs_staging2
SELECT *,
ROW_NUMBER() OVER (PARTITION BY company, industry, total_laid_off, `date`, stage, country, funds_raised_millions) AS row_number
FROM layoffs_staging;

-- 6. Remove Duplicates
DELETE FROM layoffs_staging2
WHERE row_number > 1;

-- 7. Standardize Company Names (Remove Extra Spaces)
UPDATE layoffs_staging2
SET company = TRIM(company);

-- 8. Standardize Industry Names
SELECT DISTINCT industry FROM layoffs_staging2 ORDER BY industry;

-- Fix inconsistent naming (example: 'Crypto')
UPDATE layoffs_staging2
SET industry = 'Crypto'
WHERE industry LIKE 'Crypto%';

-- 9. Standardize Country Names
UPDATE layoffs_staging2
SET country = TRIM(TRAILING '.' FROM country)
WHERE country LIKE 'United States%';

-- 10. Convert `date` from TEXT to DATE
UPDATE layoffs_staging2
SET `date` = STR_TO_DATE(`date`, '%m/%d/%Y');

-- Change column datatype
ALTER TABLE layoffs_staging2
MODIFY COLUMN `date` DATE;

-- 11. Handle Null and Blank Values in 'industry'
UPDATE layoffs_staging2
SET industry = NULL
WHERE industry = '';

-- Update NULL industries by looking up non-null values of same company
UPDATE layoffs_staging2 t1
JOIN layoffs_staging2 t2 ON t1.company = t2.company
SET t1.industry = t2.industry
WHERE (t1.industry IS NULL OR t1.industry = '')
  AND t2.industry IS NOT NULL;

-- 12. Remove records with no layoff data
DELETE FROM layoffs_staging2
WHERE total_laid_off IS NULL
  AND percentage_laid_off IS NULL;

-- 13. Drop Temporary Column
ALTER TABLE layoffs_staging2
DROP COLUMN row_number;

-- ✅ Cleaned Data Ready
SELECT * FROM layoffs_staging2;

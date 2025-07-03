-- Comprehensive fix for performa number conflicts
-- This script should be run in your Supabase SQL editor

-- Step 1: Drop the existing trigger
DROP TRIGGER IF EXISTS trigger_generate_performa_number ON stock_performas;

-- Step 2: Temporarily remove the unique constraint
ALTER TABLE stock_performas DROP CONSTRAINT IF EXISTS stock_performas_performa_number_key;

-- Step 3: Create a temporary table to fix existing performa numbers
CREATE TEMP TABLE temp_performa_fix AS
SELECT 
    id,
    user_id,
    created_at,
    'PERF-' || TO_CHAR(created_at, 'YYYYMMDD') || '-' || 
    LPAD((ROW_NUMBER() OVER (PARTITION BY user_id, DATE(created_at) ORDER BY created_at))::TEXT, 4, '0') as new_performa_number
FROM stock_performas
WHERE performa_number IS NOT NULL;

-- Step 4: Update existing performa numbers using the temp table
UPDATE stock_performas 
SET performa_number = temp_performa_fix.new_performa_number
FROM temp_performa_fix
WHERE stock_performas.id = temp_performa_fix.id;

-- Step 5: Drop the temp table
DROP TABLE temp_performa_fix;

-- Step 6: Re-add the unique constraint
ALTER TABLE stock_performas ADD CONSTRAINT stock_performas_performa_number_key UNIQUE (performa_number);

-- Step 7: Update the function to be user-specific
CREATE OR REPLACE FUNCTION generate_performa_number()
RETURNS TRIGGER AS $$
DECLARE
    next_number INTEGER;
BEGIN
    -- Get the next number for this user on this date
    SELECT COALESCE(MAX(CAST(SUBSTRING(performa_number FROM 18) AS INTEGER)), 0) + 1
    INTO next_number
    FROM stock_performas 
    WHERE user_id = NEW.user_id 
    AND DATE(created_at) = CURRENT_DATE
    AND performa_number LIKE 'PERF-' || TO_CHAR(CURRENT_DATE, 'YYYYMMDD') || '-%';
    
    -- Generate the new performa number
    NEW.performa_number := 'PERF-' || TO_CHAR(NOW(), 'YYYYMMDD') || '-' || 
        LPAD(next_number::TEXT, 4, '0');
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Step 8: Recreate the trigger
CREATE TRIGGER trigger_generate_performa_number
  BEFORE INSERT ON stock_performas
  FOR EACH ROW
  EXECUTE FUNCTION generate_performa_number(); 
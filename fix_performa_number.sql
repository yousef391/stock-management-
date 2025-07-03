-- Fix performa number generation to be user-specific
-- This script should be run in your Supabase SQL editor

-- Drop the existing trigger first
DROP TRIGGER IF EXISTS trigger_generate_performa_number ON stock_performas;

-- Update the function to be user-specific
CREATE OR REPLACE FUNCTION generate_performa_number()
RETURNS TRIGGER AS $$
BEGIN
  NEW.performa_number := 'PERF-' || TO_CHAR(NOW(), 'YYYYMMDD') || '-' || 
    LPAD((COALESCE((SELECT COUNT(*) FROM stock_performas WHERE user_id = NEW.user_id AND DATE(created_at) = CURRENT_DATE), 0) + 1)::TEXT, 4, '0');
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Recreate the trigger
CREATE TRIGGER trigger_generate_performa_number
  BEFORE INSERT ON stock_performas
  FOR EACH ROW
  EXECUTE FUNCTION generate_performa_number(); 
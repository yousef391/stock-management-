-- Drop existing stock_performas table if it exists
DROP TABLE IF EXISTS stock_performas CASCADE;

-- Create stock_performas table with JSONB for multiple products
CREATE TABLE stock_performas (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  type TEXT NOT NULL CHECK (type IN ('in', 'out')),
  items JSONB NOT NULL, -- Array of products with their details
  pdf_url TEXT,
  performa_number VARCHAR(50) UNIQUE NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE stock_performas ENABLE ROW LEVEL SECURITY;

-- Create RLS policies
CREATE POLICY "Users can view their own performas" ON stock_performas
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own performas" ON stock_performas
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own performas" ON stock_performas
  FOR UPDATE USING (auth.uid() = user_id);

-- Create function to generate user-specific performa number
CREATE OR REPLACE FUNCTION generate_performa_number()
RETURNS TRIGGER AS $$
BEGIN
  NEW.performa_number := 'PERF-' || TO_CHAR(NOW(), 'YYYYMMDD') || '-' || 
    LPAD((COALESCE((SELECT COUNT(*) FROM stock_performas WHERE user_id = NEW.user_id AND DATE(created_at) = CURRENT_DATE), 0) + 1)::TEXT, 4, '0');
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to auto-generate performa number
CREATE TRIGGER trigger_generate_performa_number
  BEFORE INSERT ON stock_performas
  FOR EACH ROW
  EXECUTE FUNCTION generate_performa_number();

-- Create function to update updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for updated_at
CREATE TRIGGER trigger_update_stock_performas_updated_at
  BEFORE UPDATE ON stock_performas
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

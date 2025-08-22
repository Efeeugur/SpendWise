-- SpendWise Database Schema
-- Comprehensive structure for all user data with CRUD operations
-- Version 1.0

-- Enable necessary extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Users table - Core user information
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email TEXT UNIQUE NOT NULL,
    encrypted_password TEXT,
    full_name TEXT,
    display_name TEXT,
    avatar_url TEXT,
    avatar_data BYTEA,
    is_guest BOOLEAN DEFAULT FALSE,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    last_login_at TIMESTAMP WITH TIME ZONE,
    
    -- Constraints
    CONSTRAINT email_format CHECK (email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'),
    CONSTRAINT valid_names CHECK (full_name IS NOT NULL OR display_name IS NOT NULL OR is_guest = TRUE)
);

-- User preferences table - App settings and preferences
CREATE TABLE user_preferences (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    
    -- Theme and appearance
    theme_preference TEXT DEFAULT 'system' CHECK (theme_preference IN ('system', 'light', 'dark')),
    language_preference TEXT DEFAULT 'en' CHECK (language_preference IN ('en', 'tr')),
    
    -- Currency settings
    default_currency TEXT DEFAULT 'TRY' CHECK (default_currency IN ('TRY', 'USD', 'EUR', 'GBP')),
    
    -- Financial settings
    monthly_spending_limit DECIMAL(15,2) CHECK (monthly_spending_limit >= 0),
    notifications_enabled BOOLEAN DEFAULT TRUE,
    smart_recommendations_enabled BOOLEAN DEFAULT TRUE,
    
    -- Security settings
    security_type TEXT DEFAULT 'none' CHECK (security_type IN ('none', 'password', 'biometric', 'both')),
    security_password_hash TEXT,
    
    -- Dashboard customization
    home_cards JSONB DEFAULT '["lastExpenses", "monthlySummary", "categoryDistribution"]',
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    UNIQUE(user_id)
);

-- Categories table - Dynamic categories for income/expense
CREATE TABLE categories (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    type TEXT NOT NULL CHECK (type IN ('income', 'expense')),
    icon_name TEXT,
    color_hex TEXT DEFAULT '#007AFF',
    is_default BOOLEAN DEFAULT FALSE,
    is_active BOOLEAN DEFAULT TRUE,
    sort_order INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    UNIQUE(user_id, name, type)
);

-- Transactions table - Unified table for income and expenses
CREATE TABLE transactions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    category_id UUID REFERENCES categories(id) ON DELETE SET NULL,
    
    -- Basic transaction info
    title TEXT NOT NULL,
    description TEXT,
    amount DECIMAL(15,2) NOT NULL CHECK (amount > 0),
    currency TEXT NOT NULL DEFAULT 'TRY' CHECK (currency IN ('TRY', 'USD', 'EUR', 'GBP')),
    
    -- Transaction type and classification
    transaction_type TEXT NOT NULL CHECK (transaction_type IN ('income', 'expense')),
    expense_type TEXT CHECK (expense_type IN ('oneTime', 'monthly') OR transaction_type = 'income'),
    
    -- Date and location
    transaction_date TIMESTAMP WITH TIME ZONE NOT NULL,
    location TEXT,
    
    -- Attachments and notes
    note TEXT,
    photo_urls JSONB DEFAULT '[]',
    photo_data BYTEA,
    receipt_data JSONB,
    
    -- Tags and metadata
    tags JSONB DEFAULT '[]',
    metadata JSONB DEFAULT '{}',
    
    -- Status and tracking
    is_recurring BOOLEAN DEFAULT FALSE,
    recurring_pattern JSONB,
    parent_transaction_id UUID REFERENCES transactions(id) ON DELETE SET NULL,
    is_deleted BOOLEAN DEFAULT FALSE,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    deleted_at TIMESTAMP WITH TIME ZONE,
    
    -- Constraints
    CONSTRAINT valid_expense_type CHECK (
        (transaction_type = 'expense' AND expense_type IS NOT NULL) OR 
        (transaction_type = 'income' AND expense_type IS NULL)
    )
);

-- Recurring transactions table - Templates for recurring transactions
CREATE TABLE recurring_transactions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    category_id UUID REFERENCES categories(id) ON DELETE SET NULL,
    
    -- Template information
    template_name TEXT NOT NULL,
    title TEXT NOT NULL,
    amount DECIMAL(15,2) NOT NULL CHECK (amount > 0),
    currency TEXT NOT NULL DEFAULT 'TRY' CHECK (currency IN ('TRY', 'USD', 'EUR', 'GBP')),
    transaction_type TEXT NOT NULL CHECK (transaction_type IN ('income', 'expense')),
    expense_type TEXT CHECK (expense_type IN ('oneTime', 'monthly') OR transaction_type = 'income'),
    
    -- Recurrence settings
    recurrence_type TEXT NOT NULL CHECK (recurrence_type IN ('daily', 'weekly', 'monthly', 'yearly')),
    recurrence_interval INTEGER DEFAULT 1 CHECK (recurrence_interval > 0),
    start_date DATE NOT NULL,
    end_date DATE,
    max_occurrences INTEGER CHECK (max_occurrences > 0),
    
    -- Template defaults
    default_description TEXT,
    default_note TEXT,
    default_tags JSONB DEFAULT '[]',
    
    -- Status
    is_active BOOLEAN DEFAULT TRUE,
    last_generated_at TIMESTAMP WITH TIME ZONE,
    next_due_date DATE,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    UNIQUE(user_id, template_name)
);

-- Budgets table - Budget tracking and limits
CREATE TABLE budgets (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    category_id UUID REFERENCES categories(id) ON DELETE CASCADE,
    
    -- Budget details
    name TEXT NOT NULL,
    budget_amount DECIMAL(15,2) NOT NULL CHECK (budget_amount > 0),
    currency TEXT NOT NULL DEFAULT 'TRY' CHECK (currency IN ('TRY', 'USD', 'EUR', 'GBP')),
    
    -- Time period
    period_type TEXT NOT NULL CHECK (period_type IN ('weekly', 'monthly', 'quarterly', 'yearly')),
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    
    -- Tracking
    spent_amount DECIMAL(15,2) DEFAULT 0 CHECK (spent_amount >= 0),
    alert_threshold DECIMAL(5,2) DEFAULT 0.8 CHECK (alert_threshold BETWEEN 0 AND 1),
    is_active BOOLEAN DEFAULT TRUE,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    CONSTRAINT valid_date_range CHECK (end_date > start_date),
    UNIQUE(user_id, name, start_date)
);

-- Financial goals table - Savings and financial targets
CREATE TABLE financial_goals (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    
    -- Goal details
    name TEXT NOT NULL,
    description TEXT,
    target_amount DECIMAL(15,2) NOT NULL CHECK (target_amount > 0),
    current_amount DECIMAL(15,2) DEFAULT 0 CHECK (current_amount >= 0),
    currency TEXT NOT NULL DEFAULT 'TRY' CHECK (currency IN ('TRY', 'USD', 'EUR', 'GBP')),
    
    -- Timeline
    target_date DATE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    achieved_at TIMESTAMP WITH TIME ZONE,
    
    -- Status
    is_active BOOLEAN DEFAULT TRUE,
    priority_level INTEGER DEFAULT 1 CHECK (priority_level BETWEEN 1 AND 5),
    
    -- Metadata
    goal_type TEXT DEFAULT 'general' CHECK (goal_type IN ('general', 'emergency', 'purchase', 'vacation', 'education')),
    auto_contribution BOOLEAN DEFAULT FALSE,
    contribution_amount DECIMAL(15,2) CHECK (contribution_amount >= 0),
    contribution_frequency TEXT CHECK (contribution_frequency IN ('daily', 'weekly', 'monthly')),
    
    UNIQUE(user_id, name)
);

-- Notifications table - User notifications and alerts
CREATE TABLE notifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    
    -- Notification content
    title TEXT NOT NULL,
    message TEXT NOT NULL,
    notification_type TEXT NOT NULL CHECK (notification_type IN ('budget_alert', 'goal_progress', 'recurring_reminder', 'recommendation', 'security', 'general')),
    
    -- Reference data
    reference_id UUID,
    reference_type TEXT,
    action_url TEXT,
    
    -- Status
    is_read BOOLEAN DEFAULT FALSE,
    is_sent BOOLEAN DEFAULT FALSE,
    priority_level INTEGER DEFAULT 1 CHECK (priority_level BETWEEN 1 AND 3),
    
    -- Scheduling
    scheduled_at TIMESTAMP WITH TIME ZONE,
    sent_at TIMESTAMP WITH TIME ZONE,
    read_at TIMESTAMP WITH TIME ZONE,
    expires_at TIMESTAMP WITH TIME ZONE,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Indexes for performance
    INDEX idx_notifications_user_unread (user_id, is_read, created_at DESC),
    INDEX idx_notifications_scheduled (scheduled_at) WHERE scheduled_at IS NOT NULL AND is_sent = FALSE
);

-- User sessions table - Track user sessions and devices
CREATE TABLE user_sessions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    
    -- Session info
    session_token TEXT UNIQUE NOT NULL,
    device_info JSONB,
    ip_address INET,
    user_agent TEXT,
    
    -- Timing
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    last_activity_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    
    -- Status
    is_active BOOLEAN DEFAULT TRUE,
    revoked_at TIMESTAMP WITH TIME ZONE,
    
    INDEX idx_sessions_user_active (user_id, is_active, expires_at),
    INDEX idx_sessions_cleanup (expires_at) WHERE is_active = TRUE
);

-- Audit log table - Track all data changes
CREATE TABLE audit_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    
    -- Audit info
    table_name TEXT NOT NULL,
    record_id UUID NOT NULL,
    action TEXT NOT NULL CHECK (action IN ('INSERT', 'UPDATE', 'DELETE')),
    
    -- Data changes
    old_data JSONB,
    new_data JSONB,
    changed_fields TEXT[],
    
    -- Context
    session_id UUID REFERENCES user_sessions(id) ON DELETE SET NULL,
    ip_address INET,
    user_agent TEXT,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Indexes for performance
    INDEX idx_audit_logs_user_table (user_id, table_name, created_at DESC),
    INDEX idx_audit_logs_record (table_name, record_id, created_at DESC)
);

-- Insert default categories
INSERT INTO categories (user_id, name, type, is_default, sort_order) VALUES
-- Default expense categories (will be copied for each user)
('00000000-0000-0000-0000-000000000000', 'Food', 'expense', TRUE, 1),
('00000000-0000-0000-0000-000000000000', 'Transportation', 'expense', TRUE, 2),
('00000000-0000-0000-0000-000000000000', 'Bills', 'expense', TRUE, 3),
('00000000-0000-0000-0000-000000000000', 'Entertainment', 'expense', TRUE, 4),
('00000000-0000-0000-0000-000000000000', 'Health', 'expense', TRUE, 5),
('00000000-0000-0000-0000-000000000000', 'Other', 'expense', TRUE, 6),

-- Default income categories
('00000000-0000-0000-0000-000000000000', 'Salary', 'income', TRUE, 1),
('00000000-0000-0000-0000-000000000000', 'Additional Income', 'income', TRUE, 2),
('00000000-0000-0000-0000-000000000000', 'Gift', 'income', TRUE, 3),
('00000000-0000-0000-0000-000000000000', 'Other', 'income', TRUE, 4);

-- Create indexes for performance
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_active ON users(is_active) WHERE is_active = TRUE;
CREATE INDEX idx_transactions_user_date ON transactions(user_id, transaction_date DESC);
CREATE INDEX idx_transactions_user_type ON transactions(user_id, transaction_type, transaction_date DESC);
CREATE INDEX idx_transactions_category ON transactions(category_id, transaction_date DESC);
CREATE INDEX idx_categories_user_type ON categories(user_id, type, is_active);
CREATE INDEX idx_budgets_user_active ON budgets(user_id, is_active, start_date, end_date);
CREATE INDEX idx_goals_user_active ON financial_goals(user_id, is_active, target_date);

-- Row Level Security (RLS) Policies
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_preferences ENABLE ROW LEVEL SECURITY;
ALTER TABLE categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE recurring_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE budgets ENABLE ROW LEVEL SECURITY;
ALTER TABLE financial_goals ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_sessions ENABLE ROW LEVEL SECURITY;

-- RLS Policies for authenticated users
CREATE POLICY "Users can view own profile" ON users FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Users can update own profile" ON users FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Users can manage own preferences" ON user_preferences FOR ALL USING (auth.uid() = user_id);
CREATE POLICY "Users can manage own categories" ON categories FOR ALL USING (auth.uid() = user_id);
CREATE POLICY "Users can manage own transactions" ON transactions FOR ALL USING (auth.uid() = user_id);
CREATE POLICY "Users can manage own recurring transactions" ON recurring_transactions FOR ALL USING (auth.uid() = user_id);
CREATE POLICY "Users can manage own budgets" ON budgets FOR ALL USING (auth.uid() = user_id);
CREATE POLICY "Users can manage own financial goals" ON financial_goals FOR ALL USING (auth.uid() = user_id);
CREATE POLICY "Users can manage own notifications" ON notifications FOR ALL USING (auth.uid() = user_id);
CREATE POLICY "Users can manage own sessions" ON user_sessions FOR ALL USING (auth.uid() = user_id);

-- Functions for automatic timestamp updates
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Triggers for automatic timestamp updates
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_preferences_updated_at BEFORE UPDATE ON user_preferences FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_categories_updated_at BEFORE UPDATE ON categories FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_transactions_updated_at BEFORE UPDATE ON transactions FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_recurring_updated_at BEFORE UPDATE ON recurring_transactions FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_budgets_updated_at BEFORE UPDATE ON budgets FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_goals_updated_at BEFORE UPDATE ON financial_goals FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Function to copy default categories to new user
CREATE OR REPLACE FUNCTION copy_default_categories_to_user(p_user_id UUID)
RETURNS VOID AS $$
BEGIN
    INSERT INTO categories (user_id, name, type, icon_name, color_hex, is_default, sort_order)
    SELECT p_user_id, name, type, icon_name, color_hex, FALSE, sort_order
    FROM categories 
    WHERE user_id = '00000000-0000-0000-0000-000000000000' AND is_default = TRUE;
END;
$$ LANGUAGE plpgsql;

-- Function to initialize user data
CREATE OR REPLACE FUNCTION initialize_user_data()
RETURNS TRIGGER AS $$
BEGIN
    -- Create user preferences
    INSERT INTO user_preferences (user_id) VALUES (NEW.id);
    
    -- Copy default categories
    PERFORM copy_default_categories_to_user(NEW.id);
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to initialize user data on user creation
CREATE TRIGGER init_user_data_trigger 
    AFTER INSERT ON users 
    FOR EACH ROW 
    EXECUTE FUNCTION initialize_user_data();

-- Function to soft delete transactions
CREATE OR REPLACE FUNCTION soft_delete_transaction(p_transaction_id UUID, p_user_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
    UPDATE transactions 
    SET is_deleted = TRUE, deleted_at = NOW()
    WHERE id = p_transaction_id AND user_id = p_user_id AND is_deleted = FALSE;
    
    RETURN FOUND;
END;
$$ LANGUAGE plpgsql;

-- Function to calculate budget progress
CREATE OR REPLACE FUNCTION update_budget_spent_amount(p_budget_id UUID)
RETURNS VOID AS $$
BEGIN
    UPDATE budgets 
    SET spent_amount = COALESCE((
        SELECT SUM(t.amount)
        FROM transactions t
        WHERE t.user_id = budgets.user_id
            AND t.category_id = budgets.category_id
            AND t.transaction_type = 'expense'
            AND t.is_deleted = FALSE
            AND t.transaction_date >= budgets.start_date
            AND t.transaction_date <= budgets.end_date
    ), 0),
    updated_at = NOW()
    WHERE id = p_budget_id;
END;
$$ LANGUAGE plpgsql;

-- Views for common queries
CREATE VIEW user_transaction_summary AS
SELECT 
    u.id as user_id,
    u.email,
    COUNT(t.id) as total_transactions,
    SUM(CASE WHEN t.transaction_type = 'income' THEN t.amount ELSE 0 END) as total_income,
    SUM(CASE WHEN t.transaction_type = 'expense' THEN t.amount ELSE 0 END) as total_expenses,
    SUM(CASE WHEN t.transaction_type = 'income' THEN t.amount ELSE -t.amount END) as net_amount,
    MAX(t.transaction_date) as last_transaction_date
FROM users u
LEFT JOIN transactions t ON u.id = t.user_id AND t.is_deleted = FALSE
WHERE u.is_active = TRUE
GROUP BY u.id, u.email;

CREATE VIEW monthly_spending_summary AS
SELECT 
    t.user_id,
    DATE_TRUNC('month', t.transaction_date) as month,
    t.currency,
    SUM(CASE WHEN t.transaction_type = 'income' THEN t.amount ELSE 0 END) as monthly_income,
    SUM(CASE WHEN t.transaction_type = 'expense' THEN t.amount ELSE 0 END) as monthly_expenses,
    COUNT(t.id) as transaction_count
FROM transactions t
WHERE t.is_deleted = FALSE
    AND t.transaction_date >= DATE_TRUNC('month', CURRENT_DATE - INTERVAL '12 months')
GROUP BY t.user_id, DATE_TRUNC('month', t.transaction_date), t.currency
ORDER BY t.user_id, month DESC;

CREATE VIEW category_spending_summary AS
SELECT 
    t.user_id,
    c.name as category_name,
    c.type as category_type,
    t.currency,
    COUNT(t.id) as transaction_count,
    SUM(t.amount) as total_amount,
    AVG(t.amount) as avg_amount,
    MAX(t.transaction_date) as last_transaction_date
FROM transactions t
JOIN categories c ON t.category_id = c.id
WHERE t.is_deleted = FALSE
    AND c.is_active = TRUE
    AND t.transaction_date >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY t.user_id, c.name, c.type, t.currency
ORDER BY t.user_id, total_amount DESC;

-- Grant permissions for Supabase auth
GRANT USAGE ON SCHEMA public TO anon, authenticated;
GRANT ALL ON ALL TABLES IN SCHEMA public TO authenticated;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO authenticated;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO authenticated;
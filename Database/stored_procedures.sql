-- SpendWise Stored Procedures
-- Advanced database functions for complex operations

-- Function to get transaction summary for a user within a date range
CREATE OR REPLACE FUNCTION get_transaction_summary(
    p_user_id UUID,
    p_start_date TIMESTAMP WITH TIME ZONE,
    p_end_date TIMESTAMP WITH TIME ZONE
)
RETURNS JSON AS $$
DECLARE
    result JSON;
BEGIN
    SELECT json_build_object(
        'total_income', COALESCE(SUM(CASE WHEN transaction_type = 'income' THEN amount ELSE 0 END), 0),
        'total_expenses', COALESCE(SUM(CASE WHEN transaction_type = 'expense' THEN amount ELSE 0 END), 0),
        'net_amount', COALESCE(SUM(CASE WHEN transaction_type = 'income' THEN amount ELSE -amount END), 0),
        'transaction_count', COUNT(*),
        'currency', COALESCE(MAX(currency), 'TRY')
    ) INTO result
    FROM transactions
    WHERE user_id = p_user_id
        AND is_deleted = FALSE
        AND transaction_date >= p_start_date
        AND transaction_date <= p_end_date;
    
    RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get monthly spending trends
CREATE OR REPLACE FUNCTION get_monthly_trends(
    p_user_id UUID,
    p_months INTEGER DEFAULT 12
)
RETURNS TABLE(
    month_year TEXT,
    total_income DECIMAL(15,2),
    total_expenses DECIMAL(15,2),
    net_amount DECIMAL(15,2),
    transaction_count INTEGER
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        TO_CHAR(DATE_TRUNC('month', t.transaction_date), 'YYYY-MM') as month_year,
        COALESCE(SUM(CASE WHEN t.transaction_type = 'income' THEN t.amount ELSE 0 END), 0) as total_income,
        COALESCE(SUM(CASE WHEN t.transaction_type = 'expense' THEN t.amount ELSE 0 END), 0) as total_expenses,
        COALESCE(SUM(CASE WHEN t.transaction_type = 'income' THEN t.amount ELSE -t.amount END), 0) as net_amount,
        COUNT(t.id)::INTEGER as transaction_count
    FROM transactions t
    WHERE t.user_id = p_user_id
        AND t.is_deleted = FALSE
        AND t.transaction_date >= DATE_TRUNC('month', CURRENT_DATE - INTERVAL '1 month' * p_months)
    GROUP BY DATE_TRUNC('month', t.transaction_date)
    ORDER BY month_year DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get category-wise spending analysis
CREATE OR REPLACE FUNCTION get_category_analysis(
    p_user_id UUID,
    p_start_date TIMESTAMP WITH TIME ZONE,
    p_end_date TIMESTAMP WITH TIME ZONE,
    p_transaction_type TEXT DEFAULT NULL
)
RETURNS TABLE(
    category_id UUID,
    category_name TEXT,
    category_type TEXT,
    total_amount DECIMAL(15,2),
    transaction_count INTEGER,
    percentage DECIMAL(5,2),
    avg_amount DECIMAL(15,2)
) AS $$
DECLARE
    total_amount_all DECIMAL(15,2);
BEGIN
    -- Get total amount for percentage calculation
    SELECT COALESCE(SUM(amount), 0) INTO total_amount_all
    FROM transactions t
    WHERE t.user_id = p_user_id
        AND t.is_deleted = FALSE
        AND t.transaction_date >= p_start_date
        AND t.transaction_date <= p_end_date
        AND (p_transaction_type IS NULL OR t.transaction_type = p_transaction_type);
    
    RETURN QUERY
    SELECT 
        c.id as category_id,
        c.name as category_name,
        c.type as category_type,
        COALESCE(SUM(t.amount), 0) as total_amount,
        COUNT(t.id)::INTEGER as transaction_count,
        CASE 
            WHEN total_amount_all > 0 THEN (COALESCE(SUM(t.amount), 0) / total_amount_all * 100)::DECIMAL(5,2)
            ELSE 0::DECIMAL(5,2)
        END as percentage,
        CASE 
            WHEN COUNT(t.id) > 0 THEN (COALESCE(SUM(t.amount), 0) / COUNT(t.id))::DECIMAL(15,2)
            ELSE 0::DECIMAL(15,2)
        END as avg_amount
    FROM categories c
    LEFT JOIN transactions t ON c.id = t.category_id 
        AND t.user_id = p_user_id
        AND t.is_deleted = FALSE
        AND t.transaction_date >= p_start_date
        AND t.transaction_date <= p_end_date
        AND (p_transaction_type IS NULL OR t.transaction_type = p_transaction_type)
    WHERE c.user_id = p_user_id
        AND c.is_active = TRUE
        AND (p_transaction_type IS NULL OR c.type = p_transaction_type)
    GROUP BY c.id, c.name, c.type
    HAVING COUNT(t.id) > 0
    ORDER BY total_amount DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to update budget spent amounts
CREATE OR REPLACE FUNCTION update_all_budget_amounts(p_user_id UUID)
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
    WHERE user_id = p_user_id AND is_active = TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to check budget alerts
CREATE OR REPLACE FUNCTION check_budget_alerts(p_user_id UUID)
RETURNS TABLE(
    budget_id UUID,
    budget_name TEXT,
    budget_amount DECIMAL(15,2),
    spent_amount DECIMAL(15,2),
    alert_threshold DECIMAL(5,2),
    percentage_used DECIMAL(5,2),
    is_over_threshold BOOLEAN,
    is_over_budget BOOLEAN
) AS $$
BEGIN
    -- First update all budget amounts
    PERFORM update_all_budget_amounts(p_user_id);
    
    RETURN QUERY
    SELECT 
        b.id as budget_id,
        b.name as budget_name,
        b.budget_amount,
        b.spent_amount,
        b.alert_threshold,
        CASE 
            WHEN b.budget_amount > 0 THEN (b.spent_amount / b.budget_amount * 100)::DECIMAL(5,2)
            ELSE 0::DECIMAL(5,2)
        END as percentage_used,
        (b.spent_amount / b.budget_amount) >= b.alert_threshold as is_over_threshold,
        b.spent_amount > b.budget_amount as is_over_budget
    FROM budgets b
    WHERE b.user_id = p_user_id
        AND b.is_active = TRUE
        AND CURRENT_DATE BETWEEN b.start_date AND b.end_date
    ORDER BY percentage_used DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get financial insights
CREATE OR REPLACE FUNCTION get_financial_insights(p_user_id UUID)
RETURNS JSON AS $$
DECLARE
    result JSON;
    current_month_income DECIMAL(15,2);
    current_month_expenses DECIMAL(15,2);
    previous_month_income DECIMAL(15,2);
    previous_month_expenses DECIMAL(15,2);
    top_expense_category TEXT;
    total_savings DECIMAL(15,2);
BEGIN
    -- Current month totals
    SELECT 
        COALESCE(SUM(CASE WHEN transaction_type = 'income' THEN amount ELSE 0 END), 0),
        COALESCE(SUM(CASE WHEN transaction_type = 'expense' THEN amount ELSE 0 END), 0)
    INTO current_month_income, current_month_expenses
    FROM transactions
    WHERE user_id = p_user_id
        AND is_deleted = FALSE
        AND DATE_TRUNC('month', transaction_date) = DATE_TRUNC('month', CURRENT_DATE);
    
    -- Previous month totals
    SELECT 
        COALESCE(SUM(CASE WHEN transaction_type = 'income' THEN amount ELSE 0 END), 0),
        COALESCE(SUM(CASE WHEN transaction_type = 'expense' THEN amount ELSE 0 END), 0)
    INTO previous_month_income, previous_month_expenses
    FROM transactions
    WHERE user_id = p_user_id
        AND is_deleted = FALSE
        AND DATE_TRUNC('month', transaction_date) = DATE_TRUNC('month', CURRENT_DATE - INTERVAL '1 month');
    
    -- Top expense category this month
    SELECT c.name INTO top_expense_category
    FROM transactions t
    JOIN categories c ON t.category_id = c.id
    WHERE t.user_id = p_user_id
        AND t.transaction_type = 'expense'
        AND t.is_deleted = FALSE
        AND DATE_TRUNC('month', t.transaction_date) = DATE_TRUNC('month', CURRENT_DATE)
    GROUP BY c.name
    ORDER BY SUM(t.amount) DESC
    LIMIT 1;
    
    -- Total savings (all-time net)
    SELECT COALESCE(SUM(CASE WHEN transaction_type = 'income' THEN amount ELSE -amount END), 0)
    INTO total_savings
    FROM transactions
    WHERE user_id = p_user_id AND is_deleted = FALSE;
    
    SELECT json_build_object(
        'current_month', json_build_object(
            'income', current_month_income,
            'expenses', current_month_expenses,
            'net', current_month_income - current_month_expenses
        ),
        'previous_month', json_build_object(
            'income', previous_month_income,
            'expenses', previous_month_expenses,
            'net', previous_month_income - previous_month_expenses
        ),
        'changes', json_build_object(
            'income_change_pct', CASE 
                WHEN previous_month_income > 0 THEN ((current_month_income - previous_month_income) / previous_month_income * 100)::DECIMAL(5,2)
                ELSE 0::DECIMAL(5,2)
            END,
            'expense_change_pct', CASE 
                WHEN previous_month_expenses > 0 THEN ((current_month_expenses - previous_month_expenses) / previous_month_expenses * 100)::DECIMAL(5,2)
                ELSE 0::DECIMAL(5,2)
            END
        ),
        'top_expense_category', COALESCE(top_expense_category, 'N/A'),
        'total_savings', total_savings,
        'generated_at', NOW()
    ) INTO result;
    
    RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to safely delete all user data
CREATE OR REPLACE FUNCTION delete_all_user_data(p_user_id UUID)
RETURNS BOOLEAN AS $$
DECLARE
    rows_deleted INTEGER := 0;
BEGIN
    -- Delete in order to respect foreign key constraints
    DELETE FROM audit_logs WHERE user_id = p_user_id;
    GET DIAGNOSTICS rows_deleted = ROW_COUNT;
    
    DELETE FROM user_sessions WHERE user_id = p_user_id;
    GET DIAGNOSTICS rows_deleted = ROW_COUNT;
    
    DELETE FROM notifications WHERE user_id = p_user_id;
    GET DIAGNOSTICS rows_deleted = ROW_COUNT;
    
    DELETE FROM financial_goals WHERE user_id = p_user_id;
    GET DIAGNOSTICS rows_deleted = ROW_COUNT;
    
    DELETE FROM budgets WHERE user_id = p_user_id;
    GET DIAGNOSTICS rows_deleted = ROW_COUNT;
    
    DELETE FROM recurring_transactions WHERE user_id = p_user_id;
    GET DIAGNOSTICS rows_deleted = ROW_COUNT;
    
    DELETE FROM transactions WHERE user_id = p_user_id;
    GET DIAGNOSTICS rows_deleted = ROW_COUNT;
    
    DELETE FROM categories WHERE user_id = p_user_id;
    GET DIAGNOSTICS rows_deleted = ROW_COUNT;
    
    DELETE FROM user_preferences WHERE user_id = p_user_id;
    GET DIAGNOSTICS rows_deleted = ROW_COUNT;
    
    DELETE FROM users WHERE id = p_user_id;
    GET DIAGNOSTICS rows_deleted = ROW_COUNT;
    
    RETURN rows_deleted > 0;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to generate recurring transactions
CREATE OR REPLACE FUNCTION generate_recurring_transactions()
RETURNS INTEGER AS $$
DECLARE
    recurring_record RECORD;
    new_transaction_id UUID;
    generated_count INTEGER := 0;
BEGIN
    FOR recurring_record IN 
        SELECT * FROM recurring_transactions 
        WHERE is_active = TRUE 
            AND next_due_date <= CURRENT_DATE
            AND (end_date IS NULL OR next_due_date <= end_date)
            AND (max_occurrences IS NULL OR 
                 (SELECT COUNT(*) FROM transactions WHERE parent_transaction_id = recurring_transactions.id) < max_occurrences)
    LOOP
        -- Generate new transaction
        new_transaction_id := uuid_generate_v4();
        
        INSERT INTO transactions (
            id, user_id, category_id, title, amount, currency,
            transaction_type, expense_type, transaction_date,
            description, note, tags, is_recurring, parent_transaction_id
        ) VALUES (
            new_transaction_id,
            recurring_record.user_id,
            recurring_record.category_id,
            recurring_record.title,
            recurring_record.amount,
            recurring_record.currency,
            recurring_record.transaction_type,
            recurring_record.expense_type,
            recurring_record.next_due_date::TIMESTAMP WITH TIME ZONE,
            recurring_record.default_description,
            recurring_record.default_note,
            recurring_record.default_tags,
            TRUE,
            recurring_record.id
        );
        
        -- Update next due date
        UPDATE recurring_transactions
        SET 
            last_generated_at = NOW(),
            next_due_date = CASE recurring_record.recurrence_type
                WHEN 'daily' THEN recurring_record.next_due_date + (recurring_record.recurrence_interval * INTERVAL '1 day')
                WHEN 'weekly' THEN recurring_record.next_due_date + (recurring_record.recurrence_interval * INTERVAL '1 week')
                WHEN 'monthly' THEN recurring_record.next_due_date + (recurring_record.recurrence_interval * INTERVAL '1 month')
                WHEN 'yearly' THEN recurring_record.next_due_date + (recurring_record.recurrence_interval * INTERVAL '1 year')
                ELSE recurring_record.next_due_date + INTERVAL '1 month'
            END
        WHERE id = recurring_record.id;
        
        generated_count := generated_count + 1;
    END LOOP;
    
    RETURN generated_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to create notification
CREATE OR REPLACE FUNCTION create_notification(
    p_user_id UUID,
    p_title TEXT,
    p_message TEXT,
    p_type TEXT,
    p_reference_id UUID DEFAULT NULL,
    p_reference_type TEXT DEFAULT NULL,
    p_priority INTEGER DEFAULT 1,
    p_scheduled_at TIMESTAMP WITH TIME ZONE DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
    new_notification_id UUID;
BEGIN
    new_notification_id := uuid_generate_v4();
    
    INSERT INTO notifications (
        id, user_id, title, message, notification_type,
        reference_id, reference_type, priority_level, scheduled_at
    ) VALUES (
        new_notification_id, p_user_id, p_title, p_message, p_type,
        p_reference_id, p_reference_type, p_priority, p_scheduled_at
    );
    
    RETURN new_notification_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permissions
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO authenticated;

-- Create indexes for better performance on new functions
CREATE INDEX IF NOT EXISTS idx_transactions_date_user ON transactions(user_id, transaction_date) WHERE is_deleted = FALSE;
CREATE INDEX IF NOT EXISTS idx_budgets_active_dates ON budgets(user_id, is_active, start_date, end_date) WHERE is_active = TRUE;
CREATE INDEX IF NOT EXISTS idx_recurring_due_date ON recurring_transactions(is_active, next_due_date) WHERE is_active = TRUE;
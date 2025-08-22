-- Migration: 001 - Initial Migration from Simple Structure to Comprehensive Schema
-- This migration transitions from the current simple income/expenses tables to the new comprehensive structure
-- Run this migration in Supabase SQL Editor

-- Step 1: Backup existing data (if tables exist)
DO $$
BEGIN
    -- Check if old tables exist and backup data
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'incomes') THEN
        CREATE TABLE IF NOT EXISTS _backup_incomes AS TABLE incomes;
        RAISE NOTICE 'Backed up existing incomes table';
    END IF;
    
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'expenses') THEN
        CREATE TABLE IF NOT EXISTS _backup_expenses AS TABLE expenses;
        RAISE NOTICE 'Backed up existing expenses table';
    END IF;
END $$;

-- Step 2: Create the new comprehensive schema (from schema.sql)
-- Note: The full schema should be run first, this migration handles data transition

-- Step 3: Migrate existing user data
DO $$
BEGIN
    -- Migrate users from old structure or create from existing auth.users
    INSERT INTO users (id, email, full_name, is_guest, created_at)
    SELECT 
        id,
        email,
        COALESCE(raw_user_meta_data->>'full_name', email_confirmed_at::text),
        FALSE,
        created_at
    FROM auth.users
    WHERE NOT EXISTS (SELECT 1 FROM users WHERE users.email = auth.users.email)
    ON CONFLICT (email) DO NOTHING;
    
    RAISE NOTICE 'Migrated users from auth.users';
END $$;

-- Step 4: Create default categories for existing users
DO $$
DECLARE
    user_record RECORD;
BEGIN
    FOR user_record IN SELECT id FROM users WHERE is_guest = FALSE
    LOOP
        PERFORM copy_default_categories_to_user(user_record.id);
    END LOOP;
    
    RAISE NOTICE 'Created default categories for existing users';
END $$;

-- Step 5: Migrate existing income data (if backup exists)
DO $$
DECLARE
    income_record RECORD;
    user_uuid UUID;
    category_uuid UUID;
BEGIN
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = '_backup_incomes') THEN
        FOR income_record IN SELECT * FROM _backup_incomes
        LOOP
            -- Find user by email
            SELECT id INTO user_uuid FROM users WHERE email = income_record.user_email;
            
            IF user_uuid IS NOT NULL THEN
                -- Find appropriate income category
                SELECT id INTO category_uuid 
                FROM categories 
                WHERE user_id = user_uuid 
                    AND type = 'income' 
                    AND name = income_record.category
                LIMIT 1;
                
                -- If category not found, use 'Other' income category
                IF category_uuid IS NULL THEN
                    SELECT id INTO category_uuid 
                    FROM categories 
                    WHERE user_id = user_uuid 
                        AND type = 'income' 
                        AND name = 'Other'
                    LIMIT 1;
                END IF;
                
                -- Insert transaction
                INSERT INTO transactions (
                    id,
                    user_id,
                    category_id,
                    title,
                    amount,
                    currency,
                    transaction_type,
                    transaction_date,
                    note,
                    created_at
                ) VALUES (
                    income_record.id::UUID,
                    user_uuid,
                    category_uuid,
                    income_record.title,
                    income_record.amount,
                    income_record.currency,
                    'income',
                    income_record.date,
                    income_record.note,
                    NOW()
                ) ON CONFLICT (id) DO NOTHING;
            END IF;
        END LOOP;
        
        RAISE NOTICE 'Migrated income data';
    END IF;
END $$;

-- Step 6: Migrate existing expense data (if backup exists)
DO $$
DECLARE
    expense_record RECORD;
    user_uuid UUID;
    category_uuid UUID;
BEGIN
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = '_backup_expenses') THEN
        FOR expense_record IN SELECT * FROM _backup_expenses
        LOOP
            -- Find user by email
            SELECT id INTO user_uuid FROM users WHERE email = expense_record.user_email;
            
            IF user_uuid IS NOT NULL THEN
                -- Find appropriate expense category
                SELECT id INTO category_uuid 
                FROM categories 
                WHERE user_id = user_uuid 
                    AND type = 'expense' 
                    AND name = expense_record.category
                LIMIT 1;
                
                -- If category not found, use 'Other' expense category
                IF category_uuid IS NULL THEN
                    SELECT id INTO category_uuid 
                    FROM categories 
                    WHERE user_id = user_uuid 
                        AND type = 'expense' 
                        AND name = 'Other'
                    LIMIT 1;
                END IF;
                
                -- Insert transaction
                INSERT INTO transactions (
                    id,
                    user_id,
                    category_id,
                    title,
                    amount,
                    currency,
                    transaction_type,
                    expense_type,
                    transaction_date,
                    note,
                    created_at
                ) VALUES (
                    expense_record.id::UUID,
                    user_uuid,
                    category_uuid,
                    expense_record.title,
                    expense_record.amount,
                    expense_record.currency,
                    'expense',
                    expense_record.type,
                    expense_record.date,
                    expense_record.note,
                    NOW()
                ) ON CONFLICT (id) DO NOTHING;
            END IF;
        END LOOP;
        
        RAISE NOTICE 'Migrated expense data';
    END IF;
END $$;

-- Step 7: Initialize user preferences for existing users
INSERT INTO user_preferences (user_id)
SELECT id FROM users 
WHERE NOT EXISTS (SELECT 1 FROM user_preferences WHERE user_preferences.user_id = users.id)
ON CONFLICT (user_id) DO NOTHING;

-- Step 8: Create initial budgets based on existing monthly limits (if any)
-- This would need to be customized based on your current user preferences storage

-- Step 9: Clean up old tables (commented out for safety)
-- DROP TABLE IF EXISTS _backup_incomes;
-- DROP TABLE IF EXISTS _backup_expenses;
-- DROP TABLE IF EXISTS incomes;
-- DROP TABLE IF EXISTS expenses;

-- Step 10: Verify migration
DO $$
DECLARE
    user_count INTEGER;
    transaction_count INTEGER;
    category_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO user_count FROM users;
    SELECT COUNT(*) INTO transaction_count FROM transactions;
    SELECT COUNT(*) INTO category_count FROM categories;
    
    RAISE NOTICE 'Migration completed:';
    RAISE NOTICE '- Users: %', user_count;
    RAISE NOTICE '- Transactions: %', transaction_count;
    RAISE NOTICE '- Categories: %', category_count;
END $$;
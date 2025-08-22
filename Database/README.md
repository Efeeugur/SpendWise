# SpendWise Database Structure Documentation

## Overview

This document describes the comprehensive database structure for the SpendWise iOS application. The new schema supports advanced features while maintaining compatibility with existing data.

## 📊 Database Schema Overview

### Core Tables

#### 1. **users** - User Profiles
Primary table for user account information.

| Column | Type | Description | Constraints |
|--------|------|-------------|-------------|
| id | UUID | Primary key | PK, DEFAULT uuid_generate_v4() |
| email | TEXT | User email | UNIQUE, NOT NULL, email format validation |
| encrypted_password | TEXT | Encrypted password | |
| full_name | TEXT | Full display name | |
| display_name | TEXT | Preferred display name | |
| avatar_url | TEXT | URL to profile picture | |
| avatar_data | BYTEA | Binary avatar data | |
| is_guest | BOOLEAN | Guest user flag | DEFAULT FALSE |
| is_active | BOOLEAN | Account active status | DEFAULT TRUE |
| created_at | TIMESTAMPTZ | Account creation time | DEFAULT NOW() |
| updated_at | TIMESTAMPTZ | Last update time | DEFAULT NOW() |
| last_login_at | TIMESTAMPTZ | Last login time | |

**Key Features:**
- Email validation with regex constraint
- Support for both guest and registered users
- Automatic timestamp management
- Avatar support (URL or binary data)

#### 2. **user_preferences** - App Settings
Stores all user customization and preferences.

| Column | Type | Description | Constraints |
|--------|------|-------------|-------------|
| id | UUID | Primary key | PK, DEFAULT uuid_generate_v4() |
| user_id | UUID | Reference to users | FK, NOT NULL, UNIQUE |
| theme_preference | TEXT | UI theme choice | CHECK IN ('system', 'light', 'dark') |
| language_preference | TEXT | App language | CHECK IN ('en', 'tr') |
| default_currency | TEXT | Default currency | CHECK IN ('TRY', 'USD', 'EUR', 'GBP') |
| monthly_spending_limit | DECIMAL(15,2) | Budget limit | CHECK >= 0 |
| notifications_enabled | BOOLEAN | Push notifications | DEFAULT TRUE |
| smart_recommendations_enabled | BOOLEAN | AI recommendations | DEFAULT TRUE |
| security_type | TEXT | Security method | CHECK IN ('none', 'password', 'biometric', 'both') |
| security_password_hash | TEXT | Hashed PIN | |
| home_cards | JSONB | Dashboard layout | DEFAULT ["lastExpenses", "monthlySummary", "categoryDistribution"] |

**Key Features:**
- One-to-one relationship with users
- JSONB for flexible dashboard customization
- Comprehensive preference management
- Security settings integration

#### 3. **categories** - Dynamic Categories
Flexible category system for income and expenses.

| Column | Type | Description | Constraints |
|--------|------|-------------|-------------|
| id | UUID | Primary key | PK, DEFAULT uuid_generate_v4() |
| user_id | UUID | Owner reference | FK, NOT NULL |
| name | TEXT | Category name | NOT NULL |
| type | TEXT | Category type | CHECK IN ('income', 'expense') |
| icon_name | TEXT | Icon identifier | |
| color_hex | TEXT | Color code | DEFAULT '#007AFF' |
| is_default | BOOLEAN | Default category flag | DEFAULT FALSE |
| is_active | BOOLEAN | Active status | DEFAULT TRUE |
| sort_order | INTEGER | Display order | DEFAULT 0 |

**Key Features:**
- User-specific categories
- Support for custom icons and colors
- Default categories automatically created for new users
- Soft delete with is_active flag
- Custom sorting order

#### 4. **transactions** - Unified Transactions
Central table for all financial transactions.

| Column | Type | Description | Constraints |
|--------|------|-------------|-------------|
| id | UUID | Primary key | PK, DEFAULT uuid_generate_v4() |
| user_id | UUID | Owner reference | FK, NOT NULL |
| category_id | UUID | Category reference | FK |
| title | TEXT | Transaction title | NOT NULL |
| description | TEXT | Detailed description | |
| amount | DECIMAL(15,2) | Transaction amount | CHECK > 0 |
| currency | TEXT | Currency code | CHECK IN ('TRY', 'USD', 'EUR', 'GBP') |
| transaction_type | TEXT | Type of transaction | CHECK IN ('income', 'expense') |
| expense_type | TEXT | Expense frequency | CHECK IN ('oneTime', 'monthly') |
| transaction_date | TIMESTAMPTZ | When transaction occurred | NOT NULL |
| location | TEXT | Transaction location | |
| note | TEXT | Additional notes | |
| photo_urls | JSONB | Attached photo URLs | DEFAULT '[]' |
| photo_data | BYTEA | Binary photo data | |
| receipt_data | JSONB | Receipt metadata | |
| tags | JSONB | Custom tags | DEFAULT '[]' |
| metadata | JSONB | Additional metadata | DEFAULT '{}' |
| is_recurring | BOOLEAN | Recurring transaction flag | DEFAULT FALSE |
| recurring_pattern | JSONB | Recurrence settings | |
| parent_transaction_id | UUID | Reference to recurring template | FK |
| is_deleted | BOOLEAN | Soft delete flag | DEFAULT FALSE |
| deleted_at | TIMESTAMPTZ | Deletion timestamp | |

**Key Features:**
- Unified table for both income and expenses
- Rich metadata support with JSONB
- Photo and receipt attachments
- Recurring transaction support
- Soft delete with audit trail
- Advanced tagging and categorization

#### 5. **budgets** - Budget Management
Budget tracking and alerts.

| Column | Type | Description | Constraints |
|--------|------|-------------|-------------|
| id | UUID | Primary key | PK, DEFAULT uuid_generate_v4() |
| user_id | UUID | Owner reference | FK, NOT NULL |
| category_id | UUID | Category reference | FK, NOT NULL |
| name | TEXT | Budget name | NOT NULL |
| budget_amount | DECIMAL(15,2) | Budget limit | CHECK > 0 |
| currency | TEXT | Budget currency | CHECK IN ('TRY', 'USD', 'EUR', 'GBP') |
| period_type | TEXT | Budget period | CHECK IN ('weekly', 'monthly', 'quarterly', 'yearly') |
| start_date | DATE | Budget start | NOT NULL |
| end_date | DATE | Budget end | NOT NULL |
| spent_amount | DECIMAL(15,2) | Current spending | DEFAULT 0 |
| alert_threshold | DECIMAL(5,2) | Alert percentage | DEFAULT 0.8 |
| is_active | BOOLEAN | Active status | DEFAULT TRUE |

**Key Features:**
- Category-specific budgets
- Automatic spending calculation
- Configurable alert thresholds
- Multiple time periods support
- Real-time budget tracking

#### 6. **financial_goals** - Savings Goals
Financial goal tracking and management.

| Column | Type | Description | Constraints |
|--------|------|-------------|-------------|
| id | UUID | Primary key | PK, DEFAULT uuid_generate_v4() |
| user_id | UUID | Owner reference | FK, NOT NULL |
| name | TEXT | Goal name | NOT NULL |
| description | TEXT | Goal description | |
| target_amount | DECIMAL(15,2) | Target amount | CHECK > 0 |
| current_amount | DECIMAL(15,2) | Current progress | DEFAULT 0 |
| currency | TEXT | Goal currency | CHECK IN ('TRY', 'USD', 'EUR', 'GBP') |
| target_date | DATE | Goal deadline | |
| goal_type | TEXT | Goal category | CHECK IN ('general', 'emergency', 'purchase', 'vacation', 'education') |
| priority_level | INTEGER | Priority (1-5) | CHECK BETWEEN 1 AND 5 |
| is_active | BOOLEAN | Active status | DEFAULT TRUE |
| auto_contribution | BOOLEAN | Auto-save enabled | DEFAULT FALSE |
| contribution_amount | DECIMAL(15,2) | Auto-save amount | |
| contribution_frequency | TEXT | Auto-save frequency | CHECK IN ('daily', 'weekly', 'monthly') |
| achieved_at | TIMESTAMPTZ | Achievement timestamp | |

**Key Features:**
- Multiple goal types
- Progress tracking
- Automatic contributions
- Priority management
- Achievement tracking

### Supporting Tables

#### 7. **recurring_transactions** - Recurring Templates
Templates for automatic recurring transactions.

#### 8. **notifications** - User Notifications
System notifications and alerts.

#### 9. **user_sessions** - Session Management
User session tracking and security.

#### 10. **audit_logs** - Change Tracking
Complete audit trail for all data changes.

## 🔧 Advanced Features

### Row Level Security (RLS)
- All tables have RLS enabled
- Users can only access their own data
- Policies enforce data isolation

### Automatic Triggers
- **Timestamp Updates**: Automatic `updated_at` field updates
- **User Initialization**: New users get default categories and preferences
- **Budget Updates**: Automatic spending calculations

### Stored Procedures
- **Transaction Summaries**: Complex financial calculations
- **Category Analysis**: Spending pattern analysis
- **Budget Alerts**: Automated budget monitoring
- **Financial Insights**: AI-ready analytics
- **Data Cleanup**: Safe bulk operations

### Views for Analytics
- **user_transaction_summary**: User-level financial overview
- **monthly_spending_summary**: Month-over-month analysis
- **category_spending_summary**: Category performance tracking

## 🚀 Migration Strategy

### Phase 1: Schema Creation
1. Run `schema.sql` to create new database structure
2. Execute `stored_procedures.sql` for advanced functions

### Phase 2: Data Migration
1. Run `001_initial_migration.sql` to migrate existing data
2. Verify data integrity and completeness

### Phase 3: Application Updates
1. Update Swift models to use new `DatabaseModels.swift`
2. Replace `SupabaseService` with `EnhancedSupabaseService`
3. Update views to use new data structure

## 🔐 Security Features

### Data Protection
- **Encrypted passwords** with secure hashing
- **Row Level Security** for multi-tenant data isolation
- **Audit logging** for all data changes
- **Session management** with token tracking

### Privacy Controls
- **Guest mode** with ephemeral data
- **Data export** capabilities
- **Complete data deletion** with cascading cleanup
- **GDPR compliance** ready structure

## 📊 Performance Optimizations

### Strategic Indexes
```sql
-- High-performance queries
CREATE INDEX idx_transactions_user_date ON transactions(user_id, transaction_date DESC);
CREATE INDEX idx_transactions_user_type ON transactions(user_id, transaction_type, transaction_date DESC);
CREATE INDEX idx_categories_user_type ON categories(user_id, type, is_active);
CREATE INDEX idx_budgets_user_active ON budgets(user_id, is_active, start_date, end_date);
```

### Query Optimization
- **Materialized views** for complex analytics
- **Partial indexes** on filtered data
- **Composite indexes** for common query patterns

## 🔄 Backward Compatibility

### Legacy Model Support
- `LegacyIncome` and `LegacyExpense` models preserved
- Automatic conversion to new `Transaction` model
- Gradual migration path for existing apps

### API Compatibility
- Both old and new SupabaseService can coexist
- Feature flags for gradual rollout
- Data synchronization between old and new structures

## 🎯 Future Enhancements

### Ready for Advanced Features
- **Machine Learning**: Rich metadata for AI insights
- **Multi-Currency**: Full currency conversion support
- **Collaborative Budgets**: Shared family/team budgets
- **Investment Tracking**: Portfolio management integration
- **Bill Splitting**: Social expense sharing
- **Merchant Integration**: Automatic transaction categorization

## 📱 iOS App Integration

### SwiftUI Compatibility
- All models conform to `Identifiable` and `Codable`
- Observable patterns for reactive UI updates
- Core Data alternative with better sync capabilities

### Offline Support
- Local caching strategies
- Conflict resolution for sync
- Optimistic updates with rollback

This comprehensive database structure provides a solid foundation for current features while enabling advanced financial management capabilities for future versions of SpendWise.
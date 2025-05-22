#!/bin/bash

# Script to reset database and apply migrations in the correct order
# This ensures enum types are created before functions that use them

echo "Resetting Supabase database..."
npx supabase db reset

echo "Applying migrations in correct order..."

# Step 1: Apply the enum definitions first
echo "1. Applying enum definitions..."
psql -h localhost -p 54322 -U postgres -d postgres -f ./migrations/20250530085000_define_appointment_enums.sql

# Step 2: Apply the main schema (already done by reset)
echo "2. Main schema was applied by reset"

# Step 3: Apply the function fixes
echo "3. Applying appointment function fixes..."
echo "   - Fixing request_service_appointment"
echo "   - Fixing respond_to_appointment_request"
echo "   - Fixing process_appointment_payment"
psql -h localhost -p 54322 -U postgres -d postgres -f ./migrations/20250601000000_fix_appointment_functions.sql

# Step 4: Apply permission updates
echo "4. Updating function permissions..."
psql -h localhost -p 54322 -U postgres -d postgres -f ./migrations/20250601000100_update_grants.sql

echo "Migrations completed successfully!"
echo ""
echo "Fixed issues:"
echo "- Enum types are now defined before they're used in functions"
echo "- Function signatures now use TEXT parameters instead of enum types"
echo "- Internal casting to enum types is done correctly"
echo "- Fixed process_appointment_payment function's incorrect enum usage"
echo "  (Wrong parameter type and missing enum type in cast operations)"
echo ""
echo "These fixes avoid the 'type X does not exist' errors during initial database setup." 
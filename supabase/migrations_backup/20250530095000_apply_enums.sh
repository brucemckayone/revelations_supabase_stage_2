#!/bin/bash

# This script fixes the order of migrations to ensure enums are defined before used
# It should be run before a database reset when enums in function signatures are causing issues

echo "Organizing migrations for proper enum usage..."

# First, copy the enum definitions to a new migration with a very early timestamp
cp supabase/migrations/20250530085000_define_appointment_enums.sql supabase/migrations/20250512095000_define_appointment_enums.sql

# Then ensure the main schema file is immediately after
# We don't need to do anything for this since it's already 20250512100000_init_schema.sql

# Finally, ensure the function definition update with enums is after the schema
cp supabase/migrations/20250530090000_fix_appointment_enum_types.sql supabase/migrations/20250512110000_fix_appointment_enum_types.sql

echo "Migrations organized. You should now run 'supabase db reset'." 
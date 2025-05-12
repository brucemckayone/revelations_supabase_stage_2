#!/bin/bash

# Script to run journal functionality tests
echo "Running journal functionality tests..."

# Run the test using Supabase's test runner
npx supabase test db

echo "Tests completed!" 
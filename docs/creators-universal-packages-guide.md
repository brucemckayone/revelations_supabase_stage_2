# Universal Packages System: Creator's Guide

## Table of Contents

1. [Overview](#overview)
2. [Getting Started with Package Templates](#getting-started-with-package-templates)
3. [Understanding Package Types](#understanding-package-types)
4. [Content Inclusion Strategies](#content-inclusion-strategies)
5. [Stripe Integration & Webhooks](#stripe-integration--webhooks)
6. [Setting Up Your First Packages](#setting-up-your-first-packages)
7. [Advanced Package Configuration](#advanced-package-configuration)
8. [Business Model Examples](#business-model-examples)
9. [Analytics & Optimization](#analytics--optimization)

## Overview

The Universal Packages System transforms your content platform into a comprehensive subscription business. Instead of selling individual appointments or content pieces, you can create packages that combine multiple content types with flexible credit systems.

### Key Benefits for Creators

- **Predictable Revenue**: Subscription packages create steady income streams
- **Higher Value Transactions**: Bundle content for higher average order values
- **User Retention**: Packages encourage long-term engagement
- **Content Monetization**: Turn all your content types into revenue sources
- **Flexible Pricing**: Multiple pricing models to match your audience

### Core Components

1. **Universal Packages** - Your main subscription offerings
2. **Access Rules** - Define what each package includes
3. **Credit Systems** - Flexible usage tracking
4. **Default Templates** - Quick-start package configurations
5. **Stripe Integration** - Seamless payment processing

## Getting Started with Package Templates

When you first create packages, the system provides 4 default templates designed for different creator types and audiences:

### 1. Content Creator Essentials ($49.99 / 4 weeks)

**Perfect for**: Coaches, consultants, educators

- 2 appointment credits (1:1 sessions)
- 20 content credits (courses, articles, videos)
- 1 event credit (workshops, group sessions)
- Mix of personalized and self-service content

**What's Included**:

```sql
-- Access Rules for Essentials Template
- Articles: Unlimited access (no credits required)
- Meditation content: 1 credit per access
- Yoga sessions: 1 credit per access
- 1:1 Services: 1 credit per appointment
```

### 2. Premium All-Access ($99.99 / 4 weeks, recurring)

**Perfect for**: Fitness trainers, wellness coaches, content creators

- 2 monthly appointment credits
- Unlimited content access (videos, articles, courses)
- Unlimited event access
- Premium subscription model

**What's Included**:

```sql
-- Access Rules for Premium Template
- Yoga: Unlimited access
- Dance: Unlimited access
- Meditation: Unlimited access
- Articles: Unlimited access
- Videos: Unlimited access
- Services: Monthly allowance (2 per billing cycle)
- Events: Pay-per-use (1 credit each)
```

### 3. Beginner Friendly ($24.99 / 2 weeks)

**Perfect for**: New creators, introductory offerings

- 1 intro session credit
- 10 beginner content credits
- Focus on guided, beginner-friendly content

**What's Included**:

```sql
-- Access Rules for Beginner Template
- Yoga: 1 credit each, max 2 per day
- Meditation: 1 credit each, max 3 per day, 5 per week
- Articles: Unlimited access
- Services: 1 credit per intro session
```

### 4. Build Your Own (Custom Pricing)

**Perfect for**: Advanced creators, custom offerings

- Fully customizable credits and duration
- Dynamic pricing based on user selections
- Users choose their own package composition

**Pricing Formula**:

```typescript
const customPrice =
  basePrce +
  appointmentCredits * appointmentCreditPrice +
  contentCredits * contentCreditPrice +
  eventCredits * eventCreditPrice +
  durationWeeks * durationWeekPrice;
```

## Understanding Package Types

### 1. Appointments Only (`appointments_only`)

Traditional appointment packages - perfect for service providers who primarily offer 1:1 sessions.

**Use Cases**:

- Personal trainers
- Life coaches
- Consultants
- Therapists

### 2. Content Credits (`content_credits`)

Fixed number of content access credits - users pay per piece of content consumed.

**Use Cases**:

- Course creators
- Educational content
- Skill-based training
- Specialized tutorials

### 3. Unlimited Content (`unlimited_content`)

Netflix-style unlimited access to specified content types.

**Use Cases**:

- Fitness platforms
- Meditation apps
- Educational libraries
- Entertainment content

### 4. Hybrid Credits (`hybrid_credits`)

Mix of appointments and content access - the most flexible option.

**Use Cases**:

- Wellness coaches (1:1 + group content)
- Business consultants (strategy + resources)
- Fitness trainers (personal + group classes)

### 5. Full Access (`full_access`)

Unlimited access to everything - premium tier offering.

**Use Cases**:

- Comprehensive platforms
- High-value subscriptions
- VIP memberships

### 6. Custom Bundle (`custom_bundle`)

User-defined packages where customers choose their own credit allocation.

**Use Cases**:

- Flexible service providers
- Multi-disciplinary creators
- Testing new pricing models

## Content Inclusion Strategies

### Specific vs. Broad Inclusion

#### Option 1: Specific Content Inclusion

Include specific posts/content pieces in packages:

```sql
-- Access rule for specific content
INSERT INTO package_access_rules (
    package_id,
    content_id,
    access_type,
    credits_required
) VALUES (
    'package-uuid',
    'specific-post-uuid',
    'pay_per_use',
    1
);
```

**Pros**:

- Precise control over what's included
- Can create themed packages
- Easy to calculate value

**Cons**:

- Manual management required
- Doesn't scale with new content
- Requires constant updates

#### Option 2: Content Type Inclusion

Include all content of certain types:

```sql
-- Access rule for content types
INSERT INTO package_access_rules (
    package_id,
    post_type,
    access_type,
    credits_required
) VALUES (
    'package-uuid',
    'yoga',
    'unlimited',
    0
);
```

**Pros**:

- Automatic inclusion of new content
- Scales with your content creation
- Easy to manage

**Cons**:

- Less precise control
- May include content you don't want in packages

#### Option 3: Service-Based Inclusion

Include all content from specific services:

```sql
-- Access rule for services
INSERT INTO package_access_rules (
    package_id,
    service_id,
    access_type,
    credits_required
) VALUES (
    'package-uuid',
    'service-uuid',
    'pay_per_use',
    1
);
```

**Pros**:

- Logical content grouping
- Service-specific packages
- Easy upselling to service packages

**Cons**:

- Requires well-organized services
- May be too broad or narrow

### Recommended Strategy: Hybrid Approach

1. **Start with Templates**: Use default templates to get started quickly
2. **Add Content Type Rules**: Include broad content categories
3. **Customize with Specific Content**: Add high-value specific content
4. **Iterate Based on Analytics**: Adjust based on usage data

## Stripe Integration & Webhooks

### Payment Flow Architecture

```typescript
// 1. Frontend initiates package purchase
const checkoutData = await supabase.rpc("prepare_package_for_stripe", {
  p_package_id: packageId,
});

// 2. Create Stripe payment intent with metadata
const paymentIntent = await stripe.paymentIntents.create({
  amount: checkoutData.price * 100,
  currency: checkoutData.currency,
  metadata: checkoutData.stripe_metadata,
});

// 3. User completes payment

// 4. Webhook processes successful payment
const webhookResult = await supabase.rpc(
  "process_universal_package_purchase_payment",
  {
    p_purchase_id: purchaseId,
    p_payment_intent_id: paymentIntentId,
    p_package_id: packageId,
  }
);
```

### Webhook Processing

The webhook function `process_universal_package_purchase_payment` handles:

1. **Validation**: Ensures purchase record exists and payment is confirmed
2. **Package Verification**: Confirms package is active and belongs to correct creator
3. **Credit Allocation**: Sets up initial credit balances
4. **Subscription Setup**: Configures recurring billing if applicable
5. **Expiration Dates**: Calculates package expiration and next billing
6. **Result Generation**: Returns comprehensive purchase data

### Required Stripe Metadata

```typescript
interface StripeMetadata {
  purchase_type: "universal_package";
  package_id: string;
  package_type: string;
  creator_id: string;
  appointment_credits: number;
  content_credits: number;
  event_credits: number;
  is_recurring: boolean;
  duration_weeks: number | null;
  is_user_defined: boolean;
  template_package_id: string | null;
}
```

## Setting Up Your First Packages

### Step 1: Create Default Templates

```sql
-- Create templates for your creator account
SELECT create_default_package_templates();
```

This creates 4 template packages with default configurations.

### Step 2: Customize Templates

```sql
-- Update package details
UPDATE universal_packages
SET
  name = 'Your Custom Name',
  description = 'Your custom description',
  price = 79.99
WHERE id = 'template-id' AND creator_id = auth.uid();
```

### Step 3: Add Content Access Rules

```sql
-- Add specific content to packages
SELECT add_package_access_rules(
  'package-id',
  '[
    {
      "post_type": "yoga",
      "access_type": "unlimited",
      "credits_required": 0,
      "priority": 1
    },
    {
      "post_type": "meditation",
      "access_type": "pay_per_use",
      "credits_required": 1,
      "daily_limit": 3,
      "priority": 2
    }
  ]'::jsonb
);
```

### Step 4: Create Default Access Rules

```sql
-- Apply default rules based on template types
SELECT create_default_access_rules_for_templates();
```

### Step 5: Test Package Purchase Flow

1. Create test package with small price
2. Test Stripe integration
3. Verify credit allocation
4. Test content access
5. Confirm analytics tracking

## Advanced Package Configuration

### Dynamic Pricing for Custom Packages

```sql
-- Custom package with dynamic pricing
INSERT INTO universal_packages (
  creator_id, name, package_type, price,
  configuration
) VALUES (
  auth.uid(),
  'Build Your Perfect Package',
  'custom_bundle',
  0, -- Base price, calculated dynamically
  jsonb_build_object(
    'base_price', 15.0,
    'appointment_credit_price', 35.0,
    'content_credit_price', 2.5,
    'event_credit_price', 18.0,
    'duration_week_price', 3.0,
    'min_total_credits', 10,
    'max_total_credits', 100,
    'min_duration_weeks', 2,
    'max_duration_weeks', 24
  )
);
```

### Usage Limits and Constraints

```sql
-- Package with sophisticated usage limits
INSERT INTO package_access_rules (
  package_id, post_type, access_type,
  credits_required, daily_limit, weekly_limit, monthly_limit
) VALUES (
  'package-id', 'yoga', 'pay_per_use',
  1, 2, 10, 30  -- 1 credit, max 2/day, 10/week, 30/month
);
```

### Tiered Access Patterns

```sql
-- Different access patterns for different content
INSERT INTO package_access_rules (package_id, post_type, access_type, credits_required, priority) VALUES
('package-id', 'article', 'unlimited', 0, 1),        -- Free articles
('package-id', 'video', 'weekly_allowance', 2, 2),   -- 2 videos per week
('package-id', 'course', 'pay_per_use', 5, 3),       -- 5 credits per course
('package-id', 'workshop', 'monthly_allowance', 1, 4); -- 1 workshop per month
```

## Business Model Examples

### 1. Fitness Creator Model

**Package Strategy**:

- **Starter Pack** ($29/month): Basic workouts + nutrition guides
- **Complete Access** ($79/month): All workouts + 2 monthly check-ins
- **VIP Coaching** ($199/month): Everything + weekly 1:1 sessions

**Content Structure**:

```sql
-- Starter Pack Rules
post_type: 'workout' -> 'weekly_allowance', 5 credits/week
post_type: 'nutrition' -> 'unlimited', 0 credits

-- Complete Access Rules
post_type: 'workout' -> 'unlimited', 0 credits
post_type: 'nutrition' -> 'unlimited', 0 credits
service_id: 'check-in-service' -> 'monthly_allowance', 2 credits/month

-- VIP Coaching Rules
post_type: 'workout' -> 'unlimited', 0 credits
post_type: 'nutrition' -> 'unlimited', 0 credits
service_id: 'check-in-service' -> 'unlimited', 0 credits
service_id: 'coaching-service' -> 'weekly_allowance', 1 credit/week
```

### 2. Educational Creator Model

**Package Strategy**:

- **Course Library** ($39/month): Access to all courses
- **Mentorship Plus** ($149/month): Courses + monthly mentoring
- **Custom Learning** (Variable): User-defined credit allocation

**Content Structure**:

```sql
-- Course Library
post_type: 'course' -> 'unlimited', 0 credits
post_type: 'article' -> 'unlimited', 0 credits

-- Mentorship Plus
post_type: 'course' -> 'unlimited', 0 credits
post_type: 'article' -> 'unlimited', 0 credits
service_id: 'mentoring' -> 'monthly_allowance', 1 credit/month

-- Custom Learning
post_type: 'course' -> 'pay_per_use', user_defined_credits
service_id: 'mentoring' -> 'pay_per_use', user_defined_credits
```

### 3. Wellness Coach Model

**Package Strategy**:

- **Self-Guided Journey** ($49/month): Content + group sessions
- **Guided Transformation** ($149/month): Content + bi-weekly 1:1s
- **Full Support** ($299/month): Everything + weekly calls

**Content Structure**:

```sql
-- Self-Guided
post_type: 'meditation' -> 'unlimited', 0 credits
post_type: 'yoga' -> 'unlimited', 0 credits
event_id: 'group-sessions' -> 'weekly_allowance', 2 credits/week

-- Guided Transformation
post_type: 'meditation' -> 'unlimited', 0 credits
post_type: 'yoga' -> 'unlimited', 0 credits
service_id: 'coaching' -> 'bi_weekly_allowance', 2 credits/month
event_id: 'group-sessions' -> 'unlimited', 0 credits

-- Full Support
post_type: '*' -> 'unlimited', 0 credits
service_id: 'coaching' -> 'weekly_allowance', 1 credit/week
event_id: '*' -> 'unlimited', 0 credits
```

## Analytics & Optimization

### Key Metrics to Track

1. **Package Performance**:

   - Most popular packages
   - Revenue per package type
   - Churn rate by package
   - Average customer lifetime value

2. **Content Usage**:

   - Most accessed content types
   - Credit utilization rates
   - Daily/weekly usage patterns
   - Content that drives renewals

3. **User Behavior**:
   - Time to first content access
   - Credits used vs. allocated
   - Upgrade/downgrade patterns
   - Cancellation reasons

### Using Analytics for Optimization

```sql
-- Get package performance analytics
SELECT get_creator_package_analytics(auth.uid());

-- Results include:
{
  "total_packages": 4,
  "active_subscriptions": 23,
  "monthly_revenue": 1847.50,
  "top_packages": [
    {
      "package_name": "Premium All-Access",
      "subscribers": 12,
      "revenue": 1199.88
    }
  ],
  "usage_patterns": {
    "avg_credits_used_percentage": 67.5,
    "most_accessed_content": "yoga",
    "peak_usage_time": "evening"
  }
}
```

### Optimization Strategies

1. **Package Pricing**:

   - Test different price points
   - Monitor conversion rates
   - Adjust based on usage data

2. **Content Inclusion**:

   - Add high-engagement content to lower tiers
   - Create exclusive content for premium tiers
   - Balance unlimited vs. credit-based access

3. **Credit Allocation**:

   - Monitor credit utilization rates
   - Adjust allocations based on actual usage
   - Create "sweet spot" packages that match user behavior

4. **Retention Improvement**:
   - Identify content that drives renewals
   - Create engagement triggers
   - Implement usage-based recommendations

### A/B Testing Framework

```sql
-- Create test variations of packages
INSERT INTO universal_packages (
  creator_id, name, package_type, price,
  total_content_credits,
  configuration
) VALUES
  -- Variation A: Higher credits, higher price
  (auth.uid(), 'Test Package A', 'content_credits', 59.99, 30,
   '{"test_variant": "A", "credits_per_dollar": 0.5}'),

  -- Variation B: Lower credits, lower price
  (auth.uid(), 'Test Package B', 'content_credits', 39.99, 20,
   '{"test_variant": "B", "credits_per_dollar": 0.5}');
```

## Conclusion

The Universal Packages System provides creators with a powerful, flexible platform for building subscription-based businesses around their content. By starting with default templates and gradually customizing based on your specific needs and audience behavior, you can create compelling package offerings that drive consistent revenue while providing exceptional value to your users.

Remember to:

- Start simple with templates
- Monitor usage analytics closely
- Iterate based on user feedback
- Test different pricing strategies
- Focus on content that drives engagement and retention

The system is designed to grow with your business, from simple content packages to sophisticated multi-tier subscription models.

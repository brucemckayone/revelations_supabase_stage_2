/**
 * TypeScript definitions for service details
 * These types correspond to the service_details_view and related functions
 */

import { BookingWorkflow } from "./service_appointments";

/**
 * Service location details
 */
export interface ServiceLocation {
  id?: string;
  name: string;
  description?: string;
  image_url?: string;
  address?: {
    line_1?: string;
    line_2?: string;
    city?: string;
    country?: string;
    postcode?: string;
    maps_link?: string;
  };
  coordinates?: {
    latitude: number;
    longitude: number;
  };
}

/**
 * Creator profile information
 */
export interface CreatorProfile {
  id: string;
  full_name: string;
  avatar_url?: string;
}

/**
 * Service details returned from the service_details_view
 */
export interface ServiceDetails {
  service_id: string;
  post_id: string;
  slug: string;
  title: string;
  description: string;
  content: string;
  thumbnail_url: string;
  service_type: string;
  price: number;
  duration: string;
  featured: boolean;
  created_at: string;
  updated_at: string;
  creator_id: string;

  // Booking workflow fields
  booking_workflow: BookingWorkflow;
  auto_confirm: boolean;
  confirmation_deadline_hours: number;

  location: ServiceLocation;
  creator: CreatorProfile;
  tags: string[];

  // Provider-only fields
  appointments?: any[];
  future_appointments?: any[];
  past_appointments?: any[];
  availability_stats?: {
    has_appointments: boolean;
    upcoming_count: number;
    total_completed: number;
  };
}

/**
 * Example usage:
 *
 * ```ts
 * import { createClient } from '@supabase/supabase-js';
 * import { ServiceDetails } from './types/service_details';
 *
 * const supabase = createClient('YOUR_SUPABASE_URL', 'YOUR_SUPABASE_KEY');
 *
 * // Get service details
 * const getServiceDetails = async (slug: string) => {
 *   const { data, error } = await supabase
 *     .rpc('get_service_details', {
 *       service_slug: slug
 *     });
 *
 *   if (error) throw error;
 *   return data as ServiceDetails;
 * };
 * ```
 */

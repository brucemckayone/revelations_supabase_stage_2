/**
 * TypeScript definitions for the Service Appointment System
 * These types correspond to the database functions and views created in the recent migrations
 */

/**
 * Provider preferences for appointment bookings
 */
export interface ProviderPreferences {
  userId: string;
  appointmentBufferMinutes: number;
  maxDailyAppointments?: number;
  maxWeeklyAppointments?: number;
  advanceNoticeHours: number;
  bookingWindowDays: number;
  autoConfirm: boolean;
  timezone: string;
}

/**
 * Availability exception for a specific date
 */
export interface AvailabilityException {
  id: string;
  userId: string;
  exceptionDate: string; // ISO date format
  isAvailable: boolean;
  startTime?: string; // 'HH:MM' format
  endTime?: string; // 'HH:MM' format
  reason?: string;
}

/**
 * Time slot within a date's availability
 */
export interface TimeSlot {
  startTime: string; // ISO datetime
  endTime: string; // ISO datetime
  available: boolean;
}

/**
 * Available date with time slots for a provider
 */
export interface AvailableDate {
  date: string; // ISO date
  availableSlots: TimeSlot[];
}

/**
 * Calendar view day representation
 */
export interface CalendarDay {
  date: string; // ISO date
  dayStatus: "available" | "booked" | "unavailable";
  availableSlots: number;
  firstAvailable?: string; // ISO datetime
  lastAvailable?: string; // ISO datetime
}

/**
 * Calendar availability response
 */
export interface ServiceCalendarAvailability {
  serviceId: string;
  timezone: string;
  days: CalendarDay[];
  hours?: {
    earliest: string; // 'HH:MM' format
    latest: string; // 'HH:MM' format
  };
}

/**
 * Valid service booking workflows
 */
export type BookingWorkflow = "direct" | "pre-approval" | "waitlist";

/**
 * Valid appointment statuses
 */
export type AppointmentStatus =
  | "pending_approval"
  | "pending_payment"
  | "confirmed"
  | "cancelled"
  | "completed"
  | "no_show"
  | "rescheduled";

/**
 * Valid appointment methods
 */
export type AppointmentMethod = "video" | "phone" | "in-person";

/**
 * Valid service types
 */
export type ServiceType = "reading" | "healing" | "coaching" | "consultation";

/**
 * Valid payment statuses
 */
export type PaymentStatus = "pending" | "completed" | "refunded" | "failed";

/**
 * Request parameters for booking a service appointment
 */
export interface ServiceAppointmentRequest {
  serviceId: string;
  requestedDate: string; // ISO datetime
  duration?: number; // minutes
  method?: AppointmentMethod;
  serviceType?: ServiceType;
  notes?: string;
}

/**
 * Response from booking a service appointment
 */
export interface ServiceAppointmentResponse {
  success: boolean;
  error?: string;
  appointmentId?: string;
  purchaseId?: string;
  serviceId?: string;
  status?: AppointmentStatus;
  requiresPayment?: boolean;
  requiresApproval?: boolean;
  appointmentDate?: string; // ISO datetime
  duration?: number; // minutes
  price?: number;
  providerId?: string;
  clientId?: string;
  workflow?: BookingWorkflow;
  nextSteps?: string;
}

/**
 * Parameters for responding to an appointment request
 */
export interface AppointmentResponseRequest {
  appointmentId: string;
  action: "confirm" | "reject" | "suggest_alternative";
  alternativeTime?: string; // ISO datetime
  providerNotes?: string;
}

/**
 * Response from responding to an appointment request
 */
export interface AppointmentResponseResult {
  success: boolean;
  error?: string;
  action?: string;
  appointmentId?: string;
  status?: AppointmentStatus;
  suggestedTime?: string; // ISO datetime
}

/**
 * Appointment details for user view
 */
export interface UserAppointment {
  appointmentId: string;
  purchaseId: string;
  serviceId: string;
  serviceTitle: string;
  providerName: string;
  providerAvatar?: string;
  providerId: string;
  appointmentDate: string; // ISO datetime
  duration: number; // minutes
  method: AppointmentMethod;
  serviceType: ServiceType;
  status: AppointmentStatus;
  paymentStatus: PaymentStatus;
  amount: number;
  isFuture: boolean;
}

/**
 * User appointments result with pagination and summary
 */
export interface UserAppointmentsResult {
  appointments: UserAppointment[];
  count: number;
  summary: {
    upcoming: number;
    pending: number;
    past: number;
    cancelled: number;
  };
}

/**
 * Database functions as they would be called from the client
 */
export interface ServiceAppointmentFunctions {
  getProviderAvailability: (
    providerId: string,
    startDate: string,
    endDate: string
  ) => Promise<AvailableDate[]>;

  getServiceCalendarAvailability: (params: {
    serviceId: string;
    daysAhead?: number;
    timezone?: string;
  }) => Promise<ServiceCalendarAvailability>;

  requestServiceAppointment: (
    params: ServiceAppointmentRequest
  ) => Promise<ServiceAppointmentResponse>;

  respondToAppointmentRequest: (
    params: AppointmentResponseRequest
  ) => Promise<AppointmentResponseResult>;

  getUserAppointments: (params?: {
    userId?: string;
    status?: AppointmentStatus;
    limit?: number;
    offset?: number;
  }) => Promise<UserAppointmentsResult>;
}

/**
 * Example usage with Supabase client
 *
 * import { createClient } from '@supabase/supabase-js';
 *
 * const supabase = createClient('YOUR_SUPABASE_URL', 'YOUR_SUPABASE_KEY');
 *
 * // Get service availability
 * const getAvailability = async (serviceId: string) => {
 *   const { data, error } = await supabase
 *     .rpc('get_service_calendar_availability', {
 *       p_service_id: serviceId,
 *       p_days_ahead: 30
 *     });
 *
 *   if (error) throw error;
 *   return data as ServiceCalendarAvailability;
 * };
 *
 * // Book an appointment
 * const bookAppointment = async (params: ServiceAppointmentRequest) => {
 *   const { data, error } = await supabase
 *     .rpc('request_service_appointment', {
 *       p_service_id: params.serviceId,
 *       p_requested_date: params.requestedDate,
 *       p_duration: params.duration,
 *       p_method: params.method,
 *       p_service_type: params.serviceType,
 *       p_notes: params.notes
 *     });
 *
 *   if (error) throw error;
 *   return data as ServiceAppointmentResponse;
 * };
 */

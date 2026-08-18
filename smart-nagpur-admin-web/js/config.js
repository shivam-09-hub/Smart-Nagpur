/**
 * Smart Nagpur Admin Web — Configuration & Constants
 * Connects to the existing production Supabase backend using the public frontend key.
 * ZERO secret/service_role keys are used in this browser application.
 */

// Supabase Configuration
export const SUPABASE_URL = 'https://hcpcycfvupjuklhcaxzg.supabase.co';
export const SUPABASE_ANON_KEY = 'sb_publishable_bKO_IvESPlRkSNT1er_lgw_1MYoES5Y';

// Initialize Supabase Client
// Loads the Supabase client from global window.supabase (loaded via CDN)
export const supabase = window.supabase
  ? window.supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
      auth: {
        persistSession: true,
        autoRefreshToken: true,
        detectSessionInUrl: true,
        storage: window.localStorage
      }
    })
  : null;

// Municipal Service Types Mapping
export const SERVICE_TYPES = {
  roads: { label: 'Roads & Potholes', icon: '🛣️', dept: 'roadsInfrastructure', color: '#3B82F6' },
  waste: { label: 'Garbage & Sanitation', icon: '🗑️', dept: 'solidWaste', color: '#10B981' },
  garbage: { label: 'Garbage & Sanitation', icon: '🗑️', dept: 'solidWaste', color: '#10B981' },
  water: { label: 'Water Supply', icon: '💧', dept: 'waterSupply', color: '#06B6D4' },
  drainage: { label: 'Drainage & Sewerage', icon: '🚰', dept: 'waterSupply', color: '#6366F1' },
  streetlights: { label: 'Streetlights & Electrical', icon: '💡', dept: 'electricalPublicLighting', color: '#F59E0B' },
  animals: { label: 'Stray Animals & Vet', icon: '🐕', dept: 'healthSanitation', color: '#EC4899' },
  encroachment: { label: 'Encroachment & Illegal Stalls', icon: '🚫', dept: 'encroachment', color: '#EF4444' },
  publicSpaces: { label: 'Parks & Public Spaces', icon: '🌳', dept: 'gardenParks', color: '#84CC16' },
  vendor: { label: 'Street Vendor Services', icon: '🛒', dept: 'generalAdministration', color: '#8B5CF6' },
  other: { label: 'General Civic Inquiries', icon: '📋', dept: 'generalAdministration', color: '#64748B' }
};

// Municipal Departments Mapping
export const DEPARTMENTS = {
  ROAD: { code: 'ROAD', name: 'Roads & Infrastructure', icon: '🛣️', color: '#3B82F6' },
  WASTE: { code: 'WASTE', name: 'Solid Waste Management', icon: '🗑️', color: '#10B981' },
  WATER: { code: 'WATER', name: 'Water Works & Drainage', icon: '💧', color: '#06B6D4' },
  VENDOR: { code: 'VENDOR', name: 'Street Vendor Permitting', icon: '🛒', color: '#8B5CF6' },
  GENERAL: { code: 'GENERAL', name: 'General Administration', icon: '🏛️', color: '#64748B' },
  solidWaste: { code: 'solidWaste', name: 'Solid Waste Management', icon: '🗑️', color: '#10B981' },
  waterSupply: { code: 'waterSupply', name: 'Water Works & Drainage', icon: '💧', color: '#06B6D4' },
  roadsInfrastructure: { code: 'roadsInfrastructure', name: 'Roads & Infrastructure', icon: '🛣️', color: '#3B82F6' },
  electricalPublicLighting: { code: 'electricalPublicLighting', name: 'Electrical & Streetlights', icon: '💡', color: '#F59E0B' },
  healthSanitation: { code: 'healthSanitation', name: 'Health & Animals', icon: '🏥', color: '#EC4899' },
  gardenParks: { code: 'gardenParks', name: 'Parks & Grounds', icon: '🌳', color: '#84CC16' },
  encroachment: { code: 'encroachment', name: 'Encroachment Control', icon: '🚫', color: '#EF4444' },
  generalAdministration: { code: 'generalAdministration', name: 'General Admin', icon: '🏛️', color: '#8B5CF6' }
};

// Complaint Status Config (supporting snake_case and camelCase database variants)
export const COMPLAINT_STATUSES = {
  submitted: { label: 'Submitted', badgeClass: 'badge-submitted', color: '#3B82F6' },
  underReview: { label: 'Under Review', badgeClass: 'badge-under-review', color: '#F59E0B' },
  under_review: { label: 'Under Review', badgeClass: 'badge-under-review', color: '#F59E0B' },
  assigned: { label: 'Assigned', badgeClass: 'badge-assigned', color: '#8B5CF6' },
  inProgress: { label: 'In Progress', badgeClass: 'badge-in-progress', color: '#EC4899' },
  in_progress: { label: 'In Progress', badgeClass: 'badge-in-progress', color: '#EC4899' },
  completed: { label: 'Work Completed', badgeClass: 'badge-completed', color: '#06B6D4' },
  resolved: { label: 'Resolved & Verified', badgeClass: 'badge-resolved', color: '#10B981' },
  rejected: { label: 'Rejected', badgeClass: 'badge-rejected', color: '#EF4444' },
  moreInformationRequired: { label: 'More Info Required', badgeClass: 'badge-warning', color: '#F59E0B' }
};

// Assignment Status Config
export const ASSIGNMENT_STATUSES = {
  assigned: { label: 'Assigned', badgeClass: 'badge-assigned', color: '#8B5CF6' },
  accepted: { label: 'Accepted by Staff', badgeClass: 'badge-accepted', color: '#3B82F6' },
  inProgress: { label: 'In Progress', badgeClass: 'badge-in-progress', color: '#EC4899' },
  in_progress: { label: 'In Progress', badgeClass: 'badge-in-progress', color: '#EC4899' },
  completed: { label: 'Awaiting Verification', badgeClass: 'badge-warning', color: '#F59E0B' },
  reworkRequired: { label: 'Rework Required', badgeClass: 'badge-rejected', color: '#EF4444' },
  rework_required: { label: 'Rework Required', badgeClass: 'badge-rejected', color: '#EF4444' },
  approved: { label: 'Approved & Closed', badgeClass: 'badge-resolved', color: '#10B981' },
  cancelled: { label: 'Cancelled', badgeClass: 'badge-muted', color: '#64748B' }
};

// Priority Config
export const PRIORITIES = {
  low: { label: 'Low', badgeClass: 'priority-low', color: '#64748B' },
  medium: { label: 'Medium', badgeClass: 'priority-medium', color: '#3B82F6' },
  high: { label: 'High', badgeClass: 'priority-high', color: '#F59E0B' },
  urgent: { label: 'Urgent (SLA Alert)', badgeClass: 'priority-urgent', color: '#EF4444' }
};

// Vendor Status Config
export const VENDOR_STATUSES = {
  submitted: { label: 'Submitted', badgeClass: 'badge-submitted', color: '#3B82F6' },
  underReview: { label: 'Under Review', badgeClass: 'badge-under-review', color: '#F59E0B' },
  under_review: { label: 'Under Review', badgeClass: 'badge-under-review', color: '#F59E0B' },
  documentsVerified: { label: 'Docs Verified', badgeClass: 'badge-accepted', color: '#3B82F6' },
  locationAssessment: { label: 'Location Assessment', badgeClass: 'badge-in-progress', color: '#8B5CF6' },
  approved: { label: 'Permit Approved', badgeClass: 'badge-resolved', color: '#10B981' },
  permissionIssued: { label: 'Permission Issued', badgeClass: 'badge-resolved', color: '#10B981' },
  rejected: { label: 'Application Rejected', badgeClass: 'badge-rejected', color: '#EF4444' },
  changesRequired: { label: 'Changes Required', badgeClass: 'badge-warning', color: '#F59E0B' }
};

// Staff Roles Config
export const STAFF_ROLES = {
  FIELD_WORKER: { code: 'FIELD_WORKER', label: 'Field Technician' },
  SUPERVISOR: { code: 'SUPERVISOR', label: 'Ward Supervisor' },
  OFFICER: { code: 'OFFICER', label: 'Department Officer' },
  fieldWorker: { code: 'FIELD_WORKER', label: 'Field Technician' },
  supervisor: { code: 'SUPERVISOR', label: 'Ward Supervisor' },
  inspector: { code: 'OFFICER', label: 'Quality Inspector' }
};

// Admin Roles Config
export const ADMIN_ROLES = {
  superAdmin: { label: 'Super Administrator', color: '#EF4444' },
  complaintReviewer: { label: 'Complaint Review Officer', color: '#3B82F6' },
  vendorReviewer: { label: 'Vendor Permitting Officer', color: '#8B5CF6' },
  notificationManager: { label: 'Operations Officer', color: '#F59E0B' },
  userManager: { label: 'User & Staff Admin', color: '#10B981' }
};

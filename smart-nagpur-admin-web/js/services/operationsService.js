/**
 * Smart Nagpur Admin Web — Operations & Verification Service
 * Handles field staff assignments, verification queue, evidence retrieval,
 * and the Approve & Resolve / Request Rework workflows using secure Supabase RPCs.
 */

import { supabase } from '../config.js';
import { storageService } from './storageService.js';

class OperationsService {
  /**
   * Get operations dashboard metrics, verification queue, and staff workload
   */
  async getOperationsDashboard({
    department = null,
    priority = null,
    status = null,
    staffId = null,
    fromDate = null,
    toDate = null
  } = {}) {
    if (!supabase) return null;

    try {
      const params = {};
      if (department) params.p_department = department;
      if (priority) params.p_priority = priority;
      if (status) params.p_status = status;
      if (staffId) params.p_staff_id = staffId;
      if (fromDate) params.p_from_date = fromDate;
      if (toDate) params.p_to_date = toDate;

      const { data, error } = await supabase.rpc('get_admin_operations_dashboard', params);
      if (error) throw error;
      return data || {};
    } catch (e) {
      console.error('Failed to get operations dashboard:', e);
      throw e;
    }
  }

  /**
   * Assign a complaint to a field staff member
   * Calls secure assign_complaint RPC
   */
  async assignComplaint({
    complaintId,
    staffId,
    priority = 'medium',
    instructions = ''
  }) {
    if (!supabase) throw new Error('Supabase not initialized');

    try {
      const { data, error } = await supabase.rpc('assign_complaint', {
        p_complaint_id: complaintId,
        p_staff_id: staffId,
        p_priority: priority,
        p_instructions: instructions || ''
      });

      if (error) throw error;
      return data;
    } catch (e) {
      console.error('Assign complaint failed:', e);
      throw e;
    }
  }

  /**
   * Get all assignments with optional filters
   */
  async getAssignments({
    status = null,
    department = null,
    staffId = null,
    limit = 50,
    offset = 0
  } = {}) {
    if (!supabase) return { data: [], count: 0 };

    try {
      let query = supabase
        .from('complaint_assignments')
        .select(`
          *,
          complaints:complaint_id(id, public_id, service_type, issue, description, location_address, latitude, longitude, status),
          staff_profiles:staff_id(id, name, employee_id, department, phone, is_on_duty)
        `, { count: 'exact' });

      if (status && status !== 'all') {
        query = query.eq('status', status);
      }

      if (staffId && staffId !== 'all') {
        query = query.eq('staff_id', staffId);
      }

      query = query
        .order('assigned_at', { ascending: false })
        .range(offset, offset + limit - 1);

      const { data, count, error } = await query;
      if (error) throw error;

      let filteredData = data || [];
      if (department && department !== 'all') {
        filteredData = filteredData.filter(a => a.staff_profiles?.department === department);
      }

      return { data: filteredData, count: count || 0 };
    } catch (e) {
      console.error('Error fetching assignments:', e);
      throw e;
    }
  }

  /**
   * Get the verification queue: completed assignments awaiting admin review
   */
  async getVerificationQueue() {
    if (!supabase) return [];

    try {
      // 1. First try fetching through get_admin_operations_dashboard RPC
      const opsDashboard = await this.getOperationsDashboard();
      if (opsDashboard && opsDashboard.verification_queue && Array.isArray(opsDashboard.verification_queue)) {
        return opsDashboard.verification_queue.map(item => ({
          ...item,
          id: item.assignment_id,
          complaint_id: item.complaint_id,
          priority: item.priority,
          completed_at: item.completed_at,
          notes: item.technician_notes,
          complaints: {
            id: item.complaint_id,
            public_id: item.public_id || item.issue,
            service_type: item.service_type,
            issue: item.issue,
            location_address: item.complaint_address,
            created_at: item.complaint_created_at
          },
          staff_profiles: {
            id: item.staff_id,
            name: item.staff_name,
            employee_id: item.staff_employee_id,
            department: item.department || 'General'
          },
          is_geo_verified: item.is_geo_verified,
          distance_meters: item.distance_meters,
          accuracy_meters: item.accuracy_meters
        }));
      }

      // 2. Fallback table query using correct schema column names
      const { data, error } = await supabase
        .from('complaint_assignments')
        .select(`
          *,
          complaints:complaint_id(id, public_id, service_type, issue, description, location_address, latitude, longitude, status, created_at),
          staff_profiles:staff_id(id, name, employee_id, department, phone)
        `)
        .eq('status', 'completed')
        .order('completed_at', { ascending: false });

      if (error) throw error;
      return data || [];
    } catch (e) {
      console.error('Failed to get verification queue:', e);
      throw e;
    }
  }

  /**
   * Fetch all evidence items for a complaint with signed URLs
   */
  async getComplaintEvidence(complaintId) {
    if (!complaintId || !supabase) return [];

    try {
      const { data, error } = await supabase
        .from('complaint_evidence')
        .select(`
          *,
          staff_profiles:staff_id(id, name, employee_id)
        `)
        .eq('complaint_id', complaintId)
        .order('captured_at', { ascending: true });

      if (error) throw error;

      const items = data || [];
      const withSignedUrls = await Promise.all(
        items.map(async (item) => {
          const signedUrl = await storageService.getEvidenceSignedUrl(item.object_path);
          return {
            ...item,
            distance_meters: item.distance_from_complaint_meters,
            accuracy_meters: item.accuracy,
            signedUrl
          };
        })
      );

      return withSignedUrls;
    } catch (e) {
      console.error('Error fetching evidence:', e);
      throw e;
    }
  }

  /**
   * Approve a completed assignment and mark complaint resolved
   * Calls secure approve_complaint_assignment RPC
   */
  async approveAssignment(assignmentId, reviewNotes = '') {
    if (!supabase) throw new Error('Supabase not initialized');

    try {
      const { data, error } = await supabase.rpc('approve_complaint_assignment', {
        p_assignment_id: assignmentId,
        p_review_notes: reviewNotes || ''
      });

      if (error) throw error;
      return data;
    } catch (e) {
      console.error('Approve assignment error:', e);
      throw e;
    }
  }

  /**
   * Request rework on a completed assignment and pass rework instructions
   * Calls secure request_rework_complaint_assignment RPC
   */
  async requestRework(assignmentId, reworkInstructions) {
    if (!supabase) throw new Error('Supabase not initialized');
    if (!reworkInstructions || reworkInstructions.trim().length === 0) {
      throw new Error('Rework instructions are required');
    }

    try {
      const { data, error } = await supabase.rpc('request_rework_complaint_assignment', {
        p_assignment_id: assignmentId,
        p_rework_instructions: reworkInstructions.trim()
      });

      if (error) throw error;
      return data;
    } catch (e) {
      console.error('Request rework error:', e);
      throw e;
    }
  }
}

export const operationsService = new OperationsService();

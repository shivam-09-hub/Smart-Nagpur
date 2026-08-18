/**
 * Smart Nagpur Admin Web — Staff Service
 * Handles staff roster, creating new staff accounts, and workload metrics.
 */

import { supabase } from '../config.js';

class StaffService {
  /**
   * Get all staff members with optional filters
   */
  async getStaffMembers({
    department = null,
    isActive = null,
    isOnDuty = null,
    search = ''
  } = {}) {
    if (!supabase) return [];

    try {
      let query = supabase
        .from('staff_profiles')
        .select('*');

      if (department && department !== 'all') {
        query = query.eq('department', department);
      }

      if (isActive !== null && isActive !== 'all') {
        query = query.eq('is_active', isActive === 'true' || isActive === true);
      }

      if (isOnDuty !== null && isOnDuty !== 'all') {
        query = query.eq('is_on_duty', isOnDuty === 'true' || isOnDuty === true);
      }

      if (search && search.trim().length > 0) {
        const s = search.trim();
        query = query.or(`name.ilike.%${s}%,employee_id.ilike.%${s}%,phone.ilike.%${s}%`);
      }

      const { data, error } = await query.order('created_at', { ascending: false });
      if (error) throw error;

      return data || [];
    } catch (e) {
      console.error('Failed to get staff members:', e);
      throw e;
    }
  }

  /**
   * Get single staff profile with task statistics
   */
  async getStaffMember(staffId) {
    if (!staffId || !supabase) return null;

    try {
      const { data: staff, error } = await supabase
        .from('staff_profiles')
        .select('*')
        .eq('id', staffId)
        .maybeSingle();

      if (error || !staff) return null;

      // Fetch task statistics
      const { data: assignments } = await supabase
        .from('complaint_assignments')
        .select('id, status, assigned_at, completed_at')
        .eq('staff_id', staffId);

      const items = assignments || [];
      const activeCount = items.filter(a => ['assigned', 'accepted', 'in_progress', 'rework_required'].includes(a.status)).length;
      const completedCount = items.filter(a => ['completed', 'approved'].includes(a.status)).length;

      return {
        ...staff,
        totalTasks: items.length,
        activeTasks: activeCount,
        completedTasks: completedCount,
        assignments: items
      };
    } catch (e) {
      console.error('Error fetching staff member:', e);
      throw e;
    }
  }

  /**
   * Create a new staff account using the secure admin_create_staff_account RPC
   */
  async createStaff({
    name,
    email,
    password,
    phone = '',
    employeeId,
    department,
    role = 'fieldWorker',
    zone = 'ALL',
    ward = ''
  }) {
    if (!supabase) throw new Error('Supabase not initialized');

    try {
      const { data, error } = await supabase.rpc('admin_create_staff_account', {
        p_name: name.trim(),
        p_email: email.trim().toLowerCase(),
        p_password: password || 'StaffPassword123!',
        p_phone: phone.trim(),
        p_employee_id: employeeId.trim(),
        p_department: department,
        p_role: role,
        p_zone: zone.trim() || 'ALL',
        p_ward: ward.trim() || ''
      });

      if (error) throw error;
      return data?.staff || data;
    } catch (e) {
      console.error('Create staff failed:', e);
      throw e;
    }
  }

  /**
   * Get real-time staff workload breakdown
   */
  async getStaffWorkloadBreakdown() {
    if (!supabase) return [];

    try {
      // 1. Fetch all active staff
      const { data: staffList, error: staffError } = await supabase
        .from('staff_profiles')
        .select('*')
        .eq('is_active', true)
        .order('department');

      if (staffError) throw staffError;

      // 2. Fetch active assignments
      const { data: activeAssignments, error: assignError } = await supabase
        .from('complaint_assignments')
        .select('id, staff_id, status, priority, assigned_at')
        .in('status', ['assigned', 'accepted', 'in_progress', 'rework_required']);

      if (assignError) throw assignError;

      // 3. Map workload onto staff members
      const assignmentsByStaff = {};
      (activeAssignments || []).forEach(a => {
        if (!assignmentsByStaff[a.staff_id]) assignmentsByStaff[a.staff_id] = [];
        assignmentsByStaff[a.staff_id].push(a);
      });

      return (staffList || []).map(staff => {
        const staffTasks = assignmentsByStaff[staff.id] || [];
        return {
          ...staff,
          activeCount: staffTasks.length,
          urgentCount: staffTasks.filter(t => t.priority === 'urgent').length,
          tasks: staffTasks
        };
      });
    } catch (e) {
      console.error('Failed to get staff workload breakdown:', e);
      throw e;
    }
  }
}

export const staffService = new StaffService();

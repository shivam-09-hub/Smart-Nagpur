/**
 * Smart Nagpur Admin Web — Admin Service
 * Interacts with complaints, timelines, reviews, and stats via Supabase queries and RPCs.
 */

import { supabase, SERVICE_TYPES } from '../config.js';
import { storageService } from './storageService.js';

class AdminService {
  /**
   * Get high-level admin dashboard statistics
   */
  async getDashboardStats() {
    if (!supabase) return null;

    try {
      const [complaintStatsRes, vendorStatsRes, userStatsRes] = await Promise.allSettled([
        supabase.rpc('get_complaint_stats'),
        supabase.rpc('get_vendor_stats'),
        supabase.rpc('get_user_stats')
      ]);

      const complaintStats = complaintStatsRes.status === 'fulfilled' && complaintStatsRes.value.data
        ? complaintStatsRes.value.data
        : {};

      const vendorStats = vendorStatsRes.status === 'fulfilled' && vendorStatsRes.value.data
        ? vendorStatsRes.value.data
        : {};

      const userStats = userStatsRes.status === 'fulfilled' && userStatsRes.value.data
        ? userStatsRes.value.data
        : {};

      return {
        totalComplaints: complaintStats.total || 0,
        pendingComplaints: complaintStats.pending || 0,
        resolvedComplaints: complaintStats.resolved || 0,
        inProgressComplaints: complaintStats.in_progress || 0,
        assignedComplaints: complaintStats.assigned || 0,
        underReviewComplaints: complaintStats.under_review || 0,
        byService: complaintStats.byService || {},
        byStatus: complaintStats.byStatus || {},
        totalVendorApplications: vendorStats.total || 0,
        pendingApplications: vendorStats.pending || 0,
        approvedApplications: vendorStats.approved || 0,
        rejectedApplications: vendorStats.rejected || 0,
        totalUsers: userStats.total || 0,
        activeUsers: userStats.active || 0
      };
    } catch (e) {
      console.error('Failed to get dashboard stats:', e);
      throw e;
    }
  }

  /**
   * Fetch paginated complaints with search and filtering
   */
  async getComplaints({
    status = null,
    serviceType = null,
    search = '',
    limit = 50,
    offset = 0,
    orderBy = 'created_at',
    ascending = false
  } = {}) {
    if (!supabase) return { data: [], count: 0 };

    try {
      let query = supabase
        .from('complaints')
        .select(`
          *,
          profiles:owner_id(name, phone, email),
          complaint_photos(id, bucket_id, object_path, original_name)
        `, { count: 'exact' });

      if (status && status !== 'all') {
        query = query.eq('status', status);
      }

      if (serviceType && serviceType !== 'all') {
        query = query.eq('service_type', serviceType);
      }

      if (search && search.trim().length > 0) {
        const s = search.trim();
        query = query.or(`public_id.ilike.%${s}%,issue.ilike.%${s}%,description.ilike.%${s}%,location_address.ilike.%${s}%`);
      }

      query = query
        .order(orderBy, { ascending })
        .range(offset, offset + limit - 1);

      const { data, count, error } = await query;

      if (error) throw error;
      return { data: data || [], count: count || 0 };
    } catch (e) {
      console.error('Failed to fetch complaints:', e);
      // Fallback to RPC if direct table select is restricted by RLS
      try {
        const { data: rpcData, error: rpcError } = await supabase.rpc(
          'get_admin_pending_complaints',
          { p_limit: limit, p_offset: offset, p_status: status === 'all' ? null : status }
        );
        if (rpcError) throw rpcError;
        return { data: rpcData || [], count: rpcData?.length || 0 };
      } catch (fallbackError) {
        console.error('RPC fallback also failed:', fallbackError);
        throw e;
      }
    }
  }

  /**
   * Get single complaint details including photo signed URLs, timeline, assignment history
   */
  async getComplaintDetails(complaintId) {
    if (!complaintId || !supabase) return null;

    try {
      const { data: complaint, error } = await supabase
        .from('complaints')
        .select(`
          *,
          profiles:owner_id(id, name, phone, email),
          complaint_photos(id, bucket_id, object_path, original_name, created_at)
        `)
        .eq('id', complaintId)
        .maybeSingle();

      if (error || !complaint) {
        const { data: rpcComplaint } = await supabase.rpc('get_admin_complaint_details', { p_id: complaintId });
        if (!rpcComplaint) return null;
        return this._formatComplaint(rpcComplaint);
      }

      return await this._formatComplaint(complaint);
    } catch (e) {
      console.error(`Error loading complaint details for ${complaintId}:`, e);
      throw e;
    }
  }

  async _formatComplaint(complaint) {
    const photoUrls = [];
    const photos = complaint.complaint_photos || complaint.photos || [];
    for (const photo of photos) {
      const objectPath = photo.object_path || photo.objectPath || '';
      if (objectPath) {
        const url = await storageService.getComplaintPhotoUrl(objectPath);
        if (url) {
          photoUrls.push({
            url,
            fileName: photo.original_name || photo.file_name || photo.fileName || 'Photo',
            objectPath
          });
        }
      }
    }

    let timeline = [];
    try {
      const { data: timelineData } = await supabase
        .from('complaint_timeline')
        .select('*')
        .eq('complaint_id', complaint.id)
        .order('occurred_at', { ascending: true });
      timeline = timelineData || [];
    } catch (_) {}

    let assignments = [];
    try {
      const { data: assignmentData } = await supabase
        .from('complaint_assignments')
        .select('*, staff_profiles:staff_id(id, name, employee_id, department, phone, is_on_duty)')
        .eq('complaint_id', complaint.id)
        .order('assigned_at', { ascending: false });
      assignments = assignmentData || [];
    } catch (_) {}

    let review = null;
    try {
      const { data: reviewData } = await supabase
        .from('admin_reviews')
        .select('*')
        .eq('item_id', complaint.id)
        .eq('item_type', 'complaint')
        .maybeSingle();
      review = reviewData;
    } catch (_) {}

    return {
      ...complaint,
      reference_number: complaint.public_id || complaint.reference_number || complaint.id,
      issue_description: complaint.description || complaint.issue || complaint.issue_description || '',
      address_text: complaint.location_address || complaint.address_text || '',
      photos: photoUrls,
      timeline,
      assignments,
      activeAssignment: assignments.find(a => ['assigned', 'accepted', 'inProgress', 'completed', 'reworkRequired'].includes(a.status)),
      review
    };
  }

  /**
   * Update complaint status using the secure database RPC
   */
  async updateComplaintStatus(complaintId, status, notes = '') {
    if (!supabase) throw new Error('Supabase not initialized');

    try {
      const { data, error } = await supabase.rpc('admin_update_complaint_status', {
        p_complaint_id: complaintId,
        p_status: status,
        p_notes: notes || ''
      });

      if (error) throw error;
      return data;
    } catch (e) {
      console.error('Update status failed:', e);
      throw e;
    }
  }

  /**
   * Submit an admin review comment
   */
  async submitReview(complaintId, status, comments) {
    if (!supabase) throw new Error('Supabase not initialized');

    const { data: { session } } = await supabase.auth.getSession();
    const reviewerId = session?.user?.id;

    try {
      const { data, error } = await supabase
        .from('admin_reviews')
        .upsert({
          item_id: complaintId,
          item_type: 'complaint',
          reviewer_id: reviewerId,
          status,
          comments,
          reviewed_at: new Date().toISOString()
        })
        .select()
        .single();

      if (error) throw error;
      return data;
    } catch (e) {
      console.error('Submit review error:', e);
      throw e;
    }
  }

  /**
   * Realtime Live Sync Subscription
   */
  subscribeToLiveUpdates(callback) {
    if (!supabase) return null;

    const channel = supabase
      .channel('admin-web-live-sync')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'complaints' }, () => callback('complaints'))
      .on('postgres_changes', { event: '*', schema: 'public', table: 'complaint_assignments' }, () => callback('assignments'))
      .on('postgres_changes', { event: '*', schema: 'public', table: 'complaint_evidence' }, () => callback('evidence'))
      .on('postgres_changes', { event: '*', schema: 'public', table: 'vendor_applications' }, () => callback('vendors'))
      .subscribe();

    return () => {
      channel.unsubscribe();
    };
  }
}

export const adminService = new AdminService();

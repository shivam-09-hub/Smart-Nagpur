/**
 * Smart Nagpur Admin Web — Vendor Service
 * Handles vendor applications, document inspection with signed URLs, and status updates.
 */

import { supabase } from '../config.js';
import { storageService } from './storageService.js';

class VendorService {
  /**
   * Fetch paginated vendor applications with status and zone filtering
   */
  async getVendorApplications({
    status = null,
    search = '',
    limit = 50,
    offset = 0
  } = {}) {
    if (!supabase) return { data: [], count: 0 };

    try {
      let query = supabase
        .from('vendor_applications')
        .select(`
          *,
          profiles:owner_id(name, phone, email),
          vendor_documents(id, bucket_id, object_path, original_name, document_type)
        `, { count: 'exact' });

      if (status && status !== 'all') {
        query = query.eq('status', status);
      }

      if (search && search.trim().length > 0) {
        const s = search.trim();
        query = query.or(`public_id.ilike.%${s}%,applicant_name.ilike.%${s}%,business_name.ilike.%${s}%`);
      }

      query = query
        .order('created_at', { ascending: false })
        .range(offset, offset + limit - 1);

      const { data, count, error } = await query;
      if (error) throw error;

      return { data: data || [], count: count || 0 };
    } catch (e) {
      console.error('Failed to get vendor applications:', e);
      try {
        const { data: rpcData, error: rpcError } = await supabase.rpc(
          'get_admin_vendor_applications',
          { p_limit: limit, p_offset: offset, p_status: status === 'all' ? null : status }
        );
        if (rpcError) throw rpcError;
        return { data: rpcData || [], count: rpcData?.length || 0 };
      } catch (fallbackErr) {
        console.error('RPC fallback also failed:', fallbackErr);
        throw e;
      }
    }
  }

  /**
   * Get vendor application details including signed document URLs and timeline
   */
  async getApplicationDetails(applicationId) {
    if (!applicationId || !supabase) return null;

    try {
      const { data: app, error } = await supabase
        .from('vendor_applications')
        .select(`
          *,
          profiles:owner_id(id, name, phone, email),
          vendor_documents(id, bucket_id, object_path, original_name, document_type, created_at)
        `)
        .eq('id', applicationId)
        .maybeSingle();

      if (error || !app) {
        const { data: rpcApp } = await supabase.rpc('get_admin_vendor_application_details', { p_id: applicationId });
        if (!rpcApp) return null;
        return this._formatApplication(rpcApp);
      }

      return await this._formatApplication(app);
    } catch (e) {
      console.error(`Error loading vendor application ${applicationId}:`, e);
      throw e;
    }
  }

  async _formatApplication(app) {
    const documents = [];
    const rawDocs = app.vendor_documents || app.documents || [];
    for (const doc of rawDocs) {
      const objectPath = doc.object_path || doc.objectPath || '';
      if (objectPath) {
        const url = await storageService.getVendorDocumentUrl(objectPath);
        documents.push({
          id: doc.id,
          fileName: doc.original_name || doc.file_name || doc.fileName || 'Document',
          documentType: doc.document_type || doc.type || 'Document',
          url,
          objectPath
        });
      }
    }

    let timeline = [];
    try {
      const { data: timelineData } = await supabase
        .from('vendor_timeline')
        .select('*')
        .eq('vendor_application_id', app.id)
        .order('occurred_at', { ascending: true });
      timeline = timelineData || [];
    } catch (_) {}

    return {
      ...app,
      reference_number: app.public_id || app.reference_number || app.id,
      applicantName: app.applicant_name || app.profiles?.name || 'Vendor',
      businessName: app.business_name || '',
      zone: app.preferred_zone || 'Nagpur',
      phone: app.mobile || app.profiles?.phone || '',
      documents,
      timeline
    };
  }

  /**
   * Update vendor application status using the secure admin_update_vendor_status RPC
   */
  async updateApplicationStatus(applicationId, status, notes = '') {
    if (!supabase) throw new Error('Supabase not initialized');

    try {
      const { data, error } = await supabase.rpc('admin_update_vendor_status', {
        p_application_id: applicationId,
        p_status: status,
        p_notes: notes || ''
      });

      if (error) throw error;
      return data;
    } catch (e) {
      console.error('Update vendor status failed:', e);
      throw e;
    }
  }
}

export const vendorService = new VendorService();

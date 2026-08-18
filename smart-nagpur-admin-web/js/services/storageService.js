/**
 * Smart Nagpur Admin Web — Storage Service
 * Generates secure, short-lived signed URLs for private storage buckets.
 */

import { supabase } from '../config.js';

class StorageService {
  /**
   * Get secure signed URL for complaint photo
   * @param {string} objectPath Path within complaint-photos bucket
   * @param {number} expiresIn Seconds until expiration (default: 3600 = 1 hr)
   */
  async getComplaintPhotoUrl(objectPath, expiresIn = 3600) {
    if (!objectPath || !supabase) return '';
    try {
      const { data, error } = await supabase.storage
        .from('complaint-photos')
        .createSignedUrl(objectPath, expiresIn);

      if (error || !data?.signedUrl) {
        return supabase.storage.from('complaint-photos').getPublicUrl(objectPath).data.publicUrl;
      }
      return data.signedUrl;
    } catch (e) {
      console.warn('Signed URL error for photo:', e);
      return '';
    }
  }

  /**
   * Get secure signed URL for field staff evidence (Before Work, After Work, Report)
   * Uses short-lived expiration (300 seconds) for sensitive operational evidence.
   */
  async getEvidenceSignedUrl(objectPath, expiresIn = 300) {
    if (!objectPath || !supabase) return '';
    try {
      const { data, error } = await supabase.storage
        .from('complaint-evidence')
        .createSignedUrl(objectPath, expiresIn);

      if (error || !data?.signedUrl) {
        return '';
      }
      return data.signedUrl;
    } catch (e) {
      console.warn('Signed URL error for evidence:', e);
      return '';
    }
  }

  /**
   * Get secure signed URL for vendor documents (Aadhaar, FSSAI, permit docs)
   */
  async getVendorDocumentUrl(objectPath, expiresIn = 3600) {
    if (!objectPath || !supabase) return '';
    try {
      const { data, error } = await supabase.storage
        .from('vendor-documents')
        .createSignedUrl(objectPath, expiresIn);

      if (error || !data?.signedUrl) {
        return supabase.storage.from('vendor-documents').getPublicUrl(objectPath).data.publicUrl;
      }
      return data.signedUrl;
    } catch (e) {
      console.warn('Signed URL error for vendor document:', e);
      return '';
    }
  }
}

export const storageService = new StorageService();

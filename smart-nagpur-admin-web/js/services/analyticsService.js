/**
 * Smart Nagpur Admin Web — Analytics & Reporting Service
 * Fetches time-series data and distribution metrics via Supabase RPCs.
 */

import { supabase } from '../config.js';

class AnalyticsService {
  /**
   * Get complaints distributed by service category
   */
  async getComplaintsByService() {
    if (!supabase) return {};

    try {
      const { data, error } = await supabase.rpc('get_complaints_by_service');
      if (error) throw error;
      return data || {};
    } catch (e) {
      console.error('Failed to get complaints by service:', e);
      return {};
    }
  }

  /**
   * Get complaints distributed by status
   */
  async getComplaintsByStatus() {
    if (!supabase) return {};

    try {
      const { data, error } = await supabase.rpc('get_complaints_by_status');
      if (error) throw error;
      return data || {};
    } catch (e) {
      console.error('Failed to get complaints by status:', e);
      return {};
    }
  }

  /**
   * Get vendor applications distributed by status
   */
  async getApplicationsByStatus() {
    if (!supabase) return {};

    try {
      const { data, error } = await supabase.rpc('get_applications_by_status');
      if (error) throw error;
      return data || {};
    } catch (e) {
      console.error('Failed to get applications by status:', e);
      return {};
    }
  }

  /**
   * Get daily complaints/resolution time-series trend
   */
  async getDailyStats(days = 30) {
    if (!supabase) return [];

    try {
      const { data, error } = await supabase.rpc('get_daily_stats', { days });
      if (error) throw error;
      return data || [];
    } catch (e) {
      console.error('Failed to get daily stats:', e);
      return [];
    }
  }

  /**
   * Generate monthly operational summary report
   */
  async getMonthlyReport(month, year) {
    if (!supabase) return null;

    try {
      const { data, error } = await supabase.rpc('get_monthly_report', { month, year });
      if (error) throw error;
      return data || {};
    } catch (e) {
      console.error('Failed to get monthly report:', e);
      return null;
    }
  }
}

export const analyticsService = new AnalyticsService();

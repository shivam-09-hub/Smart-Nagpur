/**
 * Smart Nagpur Admin Web — Authentication & Session Management
 * Enforces admin authorization by checking public.admin_profiles where is_active = true.
 */

import { supabase } from './config.js';

class AuthService {
  constructor() {
    this.currentAdmin = null;
    this.session = null;
    this.listeners = [];
  }

  /**
   * Check current session and load admin profile
   */
  async checkSession() {
    if (!supabase) return null;

    try {
      const { data: { session }, error } = await supabase.auth.getSession();
      if (error || !session) {
        this.currentAdmin = null;
        this.session = null;
        return null;
      }

      this.session = session;
      const adminProfile = await this.fetchAdminProfile(session.user.id);
      
      if (!adminProfile || !adminProfile.is_active) {
        // If not an active admin, sign out
        await this.logout();
        return null;
      }

      this.currentAdmin = adminProfile;
      this.notifyListeners();
      return adminProfile;
    } catch (e) {
      console.error('Session check failed:', e);
      return null;
    }
  }

  /**
   * Fetch admin profile from admin_profiles table
   */
  async fetchAdminProfile(userId) {
    if (!supabase) return null;

    try {
      const { data, error } = await supabase
        .from('admin_profiles')
        .select('*')
        .eq('id', userId)
        .maybeSingle();

      if (error || !data) {
        console.warn('Admin profile lookup failed:', error);
        return null;
      }

      return data;
    } catch (e) {
      console.error('Error fetching admin profile:', e);
      return null;
    }
  }

  /**
   * Log in with Email and Password
   */
  async login(email, password) {
    if (!supabase) throw new Error('Supabase client not initialized');

    const cleanEmail = email.trim().toLowerCase();
    const { data, error } = await supabase.auth.signInWithPassword({
      email: cleanEmail,
      password: password
    });

    if (error || !data.user) {
      throw new Error(error?.message || 'Invalid credentials');
    }

    // Verify admin privileges
    const adminProfile = await this.fetchAdminProfile(data.user.id);
    if (!adminProfile) {
      await supabase.auth.signOut();
      throw new Error('Access denied. This account does not have administrative privileges.');
    }

    if (!adminProfile.is_active) {
      await supabase.auth.signOut();
      throw new Error('Your administrative account is currently deactivated. Contact a super administrator.');
    }

    // Record last login timestamp
    try {
      await supabase
        .from('admin_profiles')
        .update({ last_login_at: new Date().toISOString() })
        .eq('id', data.user.id);
    } catch (_) {
      // Non-blocking
    }

    this.session = data.session;
    this.currentAdmin = adminProfile;
    this.notifyListeners();
    return adminProfile;
  }

  /**
   * Log out current administrator
   */
  async logout() {
    if (supabase) {
      try {
        await supabase.auth.signOut();
      } catch (e) {
        console.error('Sign out error:', e);
      }
    }
    this.currentAdmin = null;
    this.session = null;
    this.notifyListeners();
    window.location.href = 'login.html';
  }

  /**
   * Require active admin auth, otherwise redirect to login.html
   */
  async requireAuth() {
    const admin = await this.checkSession();
    if (!admin) {
      window.location.href = 'login.html';
      return null;
    }
    return admin;
  }

  /**
   * Get currently authenticated admin profile
   */
  getAdmin() {
    return this.currentAdmin;
  }

  /**
   * Check if current admin has a specific role
   */
  hasRole(role) {
    if (!this.currentAdmin) return false;
    if (this.currentAdmin.role === 'superAdmin') return true;
    return this.currentAdmin.role === role;
  }

  /**
   * Subscribe to auth changes
   */
  onAuthStateChange(callback) {
    this.listeners.push(callback);
    return () => {
      this.listeners = this.listeners.filter(cb => cb !== callback);
    };
  }

  notifyListeners() {
    this.listeners.forEach(callback => callback(this.currentAdmin));
  }
}

export const auth = new AuthService();

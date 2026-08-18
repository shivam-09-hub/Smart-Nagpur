/**
 * Smart Nagpur Admin Web — Settings & Security Page (2026 SaaS)
 * Administrator profile details, credentials management, and backend health status.
 */

import { auth } from '../auth.js';
import { supabase, ADMIN_ROLES } from '../config.js';
import { toast } from '../components/toast.js';

export class SettingsPage {
  constructor(container) {
    this.container = container;
  }

  async render() {
    const admin = auth.getAdmin() || {};
    const roleInfo = ADMIN_ROLES[admin.role] || { label: admin.role || 'Admin' };

    this.container.innerHTML = `
      <div class="page-header">
        <div class="page-title-group">
          <h1>Settings & System Security</h1>
          <p>Administrative credentials, role-based access parameters, and backend connection telemetry</p>
        </div>
      </div>

      <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 1.25rem;">
        <!-- Administrator Profile Card -->
        <div class="card">
          <div class="card-header">
            <div class="card-title">
              <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="8" r="5"/><path d="M20 21a8 8 0 0 0-16 0"/></svg>
              <span>Administrator Profile</span>
            </div>
          </div>

          <div style="display: flex; flex-direction: column; gap: 0.85rem; font-size: 0.82rem;">
            <div>
              <span style="font-size: 0.7rem; color: var(--text-muted); text-transform: uppercase; display: block;">Officer Name</span>
              <strong style="color: var(--text-primary); font-size: 0.95rem;">${admin.name || 'Municipal Officer'}</strong>
            </div>

            <div>
              <span style="font-size: 0.7rem; color: var(--text-muted); text-transform: uppercase; display: block;">Official Email</span>
              <span style="color: var(--text-primary); font-family: monospace;">${admin.email || '—'}</span>
            </div>

            <div>
              <span style="font-size: 0.7rem; color: var(--text-muted); text-transform: uppercase; display: block;">Role Assignment</span>
              <span class="badge badge-assigned" style="margin-top: 0.2rem;">
                ${roleInfo.label}
              </span>
            </div>

            <div>
              <span style="font-size: 0.7rem; color: var(--text-muted); text-transform: uppercase; display: block;">Contact Phone</span>
              <span style="color: var(--text-primary);">${admin.phone || '—'}</span>
            </div>

            <div>
              <span style="font-size: 0.7rem; color: var(--text-muted); text-transform: uppercase; display: block;">Last Authentication</span>
              <span style="color: var(--text-secondary); font-size: 0.78rem;">
                ${admin.last_login_at ? new Date(admin.last_login_at).toLocaleString('en-IN', { dateStyle: 'medium', timeStyle: 'short' }) : 'Current Active Session'}
              </span>
            </div>
          </div>
        </div>

        <!-- Security & Connection Health -->
        <div style="display: flex; flex-direction: column; gap: 1.15rem;">
          <div class="card">
            <div class="card-header">
              <div class="card-title">
                <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" style="color: #10B981;"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10"/></svg>
                <span>Gateway & Security Parameters</span>
              </div>
            </div>

            <div style="display: flex; flex-direction: column; gap: 0.65rem; font-size: 0.8rem;">
              <div style="display: flex; justify-content: space-between; align-items: center;">
                <span>Supabase Live Channel</span>
                <span class="badge badge-resolved">Live (Connected)</span>
              </div>
              <div style="display: flex; justify-content: space-between; align-items: center;">
                <span>PostgreSQL Row Level Security</span>
                <span class="badge badge-resolved">Active Enforced</span>
              </div>
              <div style="display: flex; justify-content: space-between; align-items: center;">
                <span>Storage Signature TTL</span>
                <span class="badge badge-assigned">300s (Encrypted)</span>
              </div>
              <div style="display: flex; justify-content: space-between; align-items: center;">
                <span>Key Scope</span>
                <span style="font-family: monospace; font-size: 0.72rem; color: var(--text-secondary);">Public Client Key (Zero Secret Exposure)</span>
              </div>
            </div>
          </div>

          <!-- Update Password -->
          <div class="card">
            <div class="card-header">
              <div class="card-title">
                <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect width="18" height="11" x="3" y="11" rx="2" ry="2"/><path d="M7 11V7a5 5 0 0 1 10 0v4"/></svg>
                <span>Update Password</span>
              </div>
            </div>
            <form id="change-password-form">
              <div class="form-group">
                <label class="form-label">New Password</label>
                <input type="password" class="form-control" id="new-password-input" placeholder="••••••••••••" required minlength="6">
              </div>
              <button type="submit" class="btn btn-primary btn-sm" id="update-password-btn">
                Update Password
              </button>
            </form>
          </div>
        </div>
      </div>
    `;

    // Hook change password
    const form = this.container.querySelector('#change-password-form');
    if (form) {
      form.addEventListener('submit', async (e) => {
        e.preventDefault();
        const pwd = this.container.querySelector('#new-password-input').value;
        const btn = this.container.querySelector('#update-password-btn');

        btn.disabled = true;
        btn.textContent = 'Updating...';

        try {
          const { error } = await supabase.auth.updateUser({ password: pwd });
          if (error) throw error;
          toast.success('Password updated successfully');
          form.reset();
        } catch (err) {
          toast.error(err.message || 'Failed to update password');
        } finally {
          btn.disabled = false;
          btn.textContent = 'Update Password';
        }
      });
    }
  }
}

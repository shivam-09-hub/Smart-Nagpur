/**
 * Smart Nagpur Admin Web — Header Component (2026 SaaS)
 * Breadcrumbs navigation, command search bar, and live sync pulse.
 */

import { auth } from '../auth.js';

export function renderHeader(currentRoute = 'dashboard', param = null) {
  const routeLabels = {
    dashboard: { section: 'Overview', title: 'Dashboard' },
    complaints: { section: 'Operations', title: 'Complaints' },
    'complaint-details': { section: 'Operations', title: 'Complaint Workspace' },
    assignments: { section: 'Operations', title: 'Assignments' },
    verification: { section: 'Operations', title: 'Verification Queue' },
    evidence: { section: 'Operations', title: 'Evidence Inspection' },
    staff: { section: 'People', title: 'Staff Roster' },
    'staff-workload': { section: 'People', title: 'Staff Workload' },
    departments: { section: 'People', title: 'Departments' },
    vendors: { section: 'People', title: 'Vendor Permitting' },
    analytics: { section: 'Insights', title: 'Analytics' },
    settings: { section: 'System', title: 'Settings' }
  };

  const current = routeLabels[currentRoute] || { section: 'Command', title: 'Operations' };

  return `
    <div class="header-left">
      <div class="breadcrumbs">
        <span class="breadcrumb-item">${current.section}</span>
        <span class="breadcrumb-separator">/</span>
        <span class="breadcrumb-active">${current.title}</span>
        ${param ? `
          <span class="breadcrumb-separator">/</span>
          <span class="badge badge-assigned" style="font-family: monospace; font-size: 0.7rem;">#${param.substring(0, 8)}</span>
        ` : ''}
      </div>
    </div>

    <div class="header-search">
      <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" style="color: var(--text-muted);"><circle cx="11" cy="11" r="8"/><path d="m21 21-4.3-4.3"/></svg>
      <input type="text" id="global-search-input" placeholder="Search reference, citizen, staff...">
      <span class="kbd-shortcut">⌘K</span>
    </div>

    <div class="header-right">
      <div class="live-badge" title="Connected to Supabase Realtime Stream">
        <span class="live-pulse"></span>
        <span>Realtime</span>
      </div>

      <button class="btn btn-secondary btn-sm" id="header-quick-refresh-btn" title="Refresh Live Data">
        <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M21 12a9 9 0 0 0-9-9 9.75 9.75 0 0 0-6.74 2.74L3 8"/><path d="M3 3v5h5"/><path d="M3 12a9 9 0 0 0 9 9 9.75 9.75 0 0 0 6.74-2.74L21 16"/><path d="M16 21h5v-5"/></svg>
        <span>Refresh</span>
      </button>

      <button class="btn btn-danger btn-sm" id="header-logout-btn" title="Sign Out">
        Sign Out
      </button>
    </div>
  `;
}

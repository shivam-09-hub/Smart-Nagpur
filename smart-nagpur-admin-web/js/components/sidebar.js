/**
 * Smart Nagpur Admin Web — Sidebar Component (2026 SaaS)
 * Structured sections: OVERVIEW, OPERATIONS, PEOPLE, INSIGHTS, SYSTEM
 * Clean SVG icons, collapsible state, active indicators, and user footer.
 */

import { auth } from '../auth.js';
import { ADMIN_ROLES } from '../config.js';

// Clean SVG Icon Library
const ICONS = {
  dashboard: `<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect width="7" height="9" x="3" y="3" rx="1"/><rect width="7" height="5" x="14" y="3" rx="1"/><rect width="7" height="9" x="14" y="12" rx="1"/><rect width="7" height="5" x="3" y="16" rx="1"/></svg>`,
  analytics: `<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M3 3v18h18"/><path d="m19 9-5 5-4-4-3 3"/></svg>`,
  complaints: `<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="m21.73 18-8-14a2 2 0 0 0-3.48 0l-8 14A2 2 0 0 0 4 21h16a2 2 0 0 0 1.73-3Z"/><line x1="12" x2="12" y1="9" y2="13"/><line x1="12" x2="12.01" y1="17" y2="17"/></svg>`,
  assignments: `<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect width="8" height="4" x="8" y="2" rx="1" ry="1"/><path d="M16 4h2a2 2 0 0 1 2 2v14a2 2 0 0 1-2 2H6a2 2 0 0 1-2-2V6a2 2 0 0 1 2-2h2"/><path d="M12 11h4"/><path d="M12 16h4"/><path d="M8 11h.01"/><path d="M8 16h.01"/></svg>`,
  verification: `<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10"/><path d="m9 12 2 2 4-4"/></svg>`,
  staff: `<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M22 21v-2a4 4 0 0 0-3-3.87"/><path d="M16 3.13a4 4 0 0 1 0 7.75"/></svg>`,
  departments: `<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect width="16" height="20" x="4" y="2" rx="2" ry="2"/><path d="M9 22v-4h6v4"/><path d="M8 6h.01"/><path d="M16 6h.01"/><path d="M8 10h.01"/><path d="M16 10h.01"/><path d="M8 14h.01"/><path d="M16 14h.01"/></svg>`,
  vendors: `<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="8" cy="21" r="1"/><circle cx="19" cy="21" r="1"/><path d="M2.05 2.05h2l2.66 12.42a2 2 0 0 0 2 1.58h9.78a2 2 0 0 0 1.95-1.57l1.65-7.43H5.12"/></svg>`,
  settings: `<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M12.22 2h-.44a2 2 0 0 0-2 2v.18a2 2 0 0 1-1 1.73l-.43.25a2 2 0 0 1-2 0l-.15-.08a2 2 0 0 0-2.73.73l-.22.38a2 2 0 0 0 .73 2.73l.15.1a2 2 0 0 1 1 1.72v.51a2 2 0 0 1-1 1.74l-.15.09a2 2 0 0 0-.73 2.73l.22.38a2 2 0 0 0 2.73.73l.15-.08a2 2 0 0 1 2 0l.43.25a2 2 0 0 1 1 1.73V20a2 2 0 0 0 2 2h.44a2 2 0 0 0 2-2v-.18a2 2 0 0 1 1-1.73l.43-.25a2 2 0 0 1 2 0l.15.08a2 2 0 0 0 2.73-.73l.22-.39a2 2 0 0 0-.73-2.73l-.15-.08a2 2 0 0 1-1-1.74v-.5a2 2 0 0 1 1-1.74l.15-.09a2 2 0 0 0 .73-2.73l-.22-.38a2 2 0 0 0-2.73-.73l-.15.08a2 2 0 0 1-2 0l-.43-.25a2 2 0 0 1-1-1.73V4a2 2 0 0 0-2-2z"/><circle cx="12" cy="12" r="3"/></svg>`,
  collapse: `<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="m15 18-6-6 6-6"/></svg>`,
  logout: `<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4"/><polyline points="16 17 21 12 16 7"/><line x1="21" x2="9" y1="12" y2="12"/></svg>`
};

export function renderSidebar(currentRoute = 'dashboard', verificationCount = 0) {
  const admin = auth.getAdmin();
  const roleInfo = admin ? (ADMIN_ROLES[admin.role] || { label: admin.role }) : { label: 'Admin' };

  const sections = [
    {
      title: 'Overview',
      items: [
        { route: 'dashboard', label: 'Dashboard', icon: ICONS.dashboard }
      ]
    },
    {
      title: 'Operations',
      items: [
        { route: 'complaints', label: 'Complaints', icon: ICONS.complaints },
        { route: 'assignments', label: 'Assignments', icon: ICONS.assignments },
        { route: 'verification', label: 'Verification', icon: ICONS.verification, badge: verificationCount }
      ]
    },
    {
      title: 'People',
      items: [
        { route: 'staff', label: 'Staff Roster', icon: ICONS.staff },
        { route: 'departments', label: 'Departments', icon: ICONS.departments },
        { route: 'vendors', label: 'Vendors', icon: ICONS.vendors }
      ]
    },
    {
      title: 'Insights',
      items: [
        { route: 'analytics', label: 'Analytics', icon: ICONS.analytics }
      ]
    },
    {
      title: 'System',
      items: [
        { route: 'settings', label: 'Settings', icon: ICONS.settings }
      ]
    }
  ];

  return `
    <div class="sidebar-header">
      <div class="sidebar-brand">
        <div class="sidebar-logo">🏛️</div>
        <div class="sidebar-brand-text">
          <span class="sidebar-brand-title">NMC Command</span>
          <span class="sidebar-brand-sub">Smart Nagpur</span>
        </div>
      </div>
      <button class="sidebar-toggle-btn" id="sidebar-collapse-toggle" title="Toggle Sidebar">
        ${ICONS.collapse}
      </button>
    </div>

    <div class="sidebar-nav">
      ${sections.map(sec => `
        <div class="nav-section-title">${sec.title}</div>
        ${sec.items.map(item => {
          const isActive = currentRoute === item.route || currentRoute.startsWith(`${item.route}/`);
          return `
            <a href="#${item.route}" class="nav-item ${isActive ? 'active' : ''}" title="${item.label}">
              <span class="nav-icon">${item.icon}</span>
              <span class="nav-label">${item.label}</span>
              ${item.badge && item.badge > 0 ? `<span class="nav-counter">${item.badge}</span>` : ''}
            </a>
          `;
        }).join('')}
      `).join('')}
    </div>

    <div class="sidebar-footer">
      <div class="admin-profile-pill">
        <div class="admin-avatar">
          ${(admin?.name || 'A').charAt(0).toUpperCase()}
        </div>
        <div class="admin-details">
          <span class="admin-name">${admin?.name || 'Administrator'}</span>
          <span class="admin-role">${roleInfo.label}</span>
        </div>
      </div>
      <button class="btn-icon" id="sidebar-logout-btn" title="Sign Out">
        ${ICONS.logout}
      </button>
    </div>
  `;
}

/**
 * Smart Nagpur Admin Web — Municipal Departments Page (2026 SaaS)
 * Structural overview of 8 NMC operational divisions with workload and staff ratios.
 */

import { adminService } from '../services/adminService.js';
import { staffService } from '../services/staffService.js';
import { DEPARTMENTS } from '../config.js';

export class DepartmentsPage {
  constructor(container) {
    this.container = container;
  }

  async render() {
    this.container.innerHTML = `
      <div class="page-header">
        <div class="page-title-group">
          <h1>Municipal Divisions</h1>
          <p>Operational divisions of Nagpur Municipal Corporation, assigned services, and technician distributions</p>
        </div>
      </div>

      <div id="dept-mount">
        <div style="display: grid; grid-template-columns: repeat(auto-fill, minmax(280px, 1fr)); gap: 1rem;">
          ${Array.from({ length: 8 }).map(() => `
            <div class="skeleton skeleton-rect" style="height: 150px;"></div>
          `).join('')}
        </div>
      </div>
    `;

    await this.loadData();
  }

  async loadData() {
    const mount = this.container.querySelector('#dept-mount');
    if (!mount) return;

    try {
      const [stats, staffList] = await Promise.all([
        adminService.getDashboardStats(),
        staffService.getStaffMembers({ isActive: true })
      ]);

      const staffByDept = {};
      staffList.forEach(s => {
        if (!staffByDept[s.department]) staffByDept[s.department] = [];
        staffByDept[s.department].push(s);
      });

      mount.innerHTML = `
        <div style="display: grid; grid-template-columns: repeat(auto-fill, minmax(280px, 1fr)); gap: 1rem;">
          ${Object.entries(DEPARTMENTS).map(([code, dept]) => {
            const complaintsCount = stats.byService?.[code] || 0;
            const deptStaff = staffByDept[code] || [];
            const onDutyCount = deptStaff.filter(s => s.is_on_duty).length;

            return `
              <div class="card" style="display: flex; flex-direction: column; justify-content: space-between; padding: 1rem;">
                <div>
                  <div style="display: flex; align-items: flex-start; justify-content: space-between; margin-bottom: 0.75rem;">
                    <div style="display: flex; align-items: center; gap: 0.5rem;">
                      <span style="font-size: 1.3rem;">${dept.icon}</span>
                      <div>
                        <strong style="font-size: 0.9rem; color: var(--text-primary); display: block;">${dept.name}</strong>
                        <span style="font-size: 0.68rem; color: var(--text-muted); font-family: monospace;">${code}</span>
                      </div>
                    </div>
                  </div>

                  <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 0.5rem; background: var(--bg-surface-subtle); padding: 0.65rem 0.75rem; border-radius: var(--radius-sm); margin-bottom: 0.85rem; border: 1px solid var(--border-subtle);">
                    <div>
                      <span style="font-size: 0.68rem; color: var(--text-muted); display: block;">Active Reports</span>
                      <strong style="font-size: 1.15rem; color: #60A5FA; font-feature-settings: 'tnum';">${complaintsCount}</strong>
                    </div>
                    <div>
                      <span style="font-size: 0.68rem; color: var(--text-muted); display: block;">Technicians</span>
                      <strong style="font-size: 1.15rem; color: var(--text-primary); font-feature-settings: 'tnum';">${deptStaff.length}</strong>
                      <span style="font-size: 0.65rem; color: var(--success); display: block;">(${onDutyCount} on duty)</span>
                    </div>
                  </div>
                </div>

                <div style="display: flex; justify-content: flex-end;">
                  <a href="#complaints" class="btn btn-secondary btn-sm" style="font-size: 0.72rem;">
                    View Complaints →
                  </a>
                </div>
              </div>
            `;
          }).join('')}
        </div>
      `;

    } catch (e) {
      mount.innerHTML = `
        <div class="empty-state">
          <div class="empty-state-icon">⚠️</div>
          <div class="empty-state-title">Failed to load department metrics</div>
          <p style="font-size: 0.78rem; color: var(--danger);">${e.message || 'Error'}</p>
        </div>
      `;
    }
  }
}

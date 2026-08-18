/**
 * Smart Nagpur Admin Web — Staff Workload Monitor (2026 SaaS)
 * Real-time technician capacity meters, active task load, and on-duty status.
 */

import { staffService } from '../services/staffService.js';
import { DEPARTMENTS, STAFF_ROLES } from '../config.js';

export class StaffWorkloadPage {
  constructor(container) {
    this.container = container;
  }

  async render() {
    this.container.innerHTML = `
      <div class="page-header">
        <div class="page-title-group">
          <h1>Staff Capacity & Workload Monitor</h1>
          <p>Real-time task dispatch load, active capacity meters, and on-duty status per technician</p>
        </div>
      </div>

      <div id="workload-mount">
        <div style="display: grid; grid-template-columns: repeat(auto-fill, minmax(280px, 1fr)); gap: 1rem;">
          ${Array.from({ length: 6 }).map(() => `
            <div class="skeleton skeleton-rect" style="height: 140px;"></div>
          `).join('')}
        </div>
      </div>
    `;

    await this.loadData();
  }

  async loadData() {
    const mount = this.container.querySelector('#workload-mount');
    if (!mount) return;

    try {
      const staffWorkload = await staffService.getStaffWorkloadBreakdown();

      if (!staffWorkload || staffWorkload.length === 0) {
        mount.innerHTML = `
          <div class="empty-state">
            <div class="empty-state-icon">👷</div>
            <div class="empty-state-title">No Staff Profiles Found</div>
            <p style="font-size: 0.78rem;">Provision staff members to begin tracking capacity.</p>
          </div>
        `;
        return;
      }

      mount.innerHTML = `
        <div style="display: grid; grid-template-columns: repeat(auto-fill, minmax(280px, 1fr)); gap: 0.85rem;">
          ${staffWorkload.map(staff => {
            const dept = DEPARTMENTS[staff.department] || { name: staff.department, icon: '🏛️' };
            const roleName = STAFF_ROLES[staff.role]?.label || 'Technician';
            const loadRatio = Math.min((staff.activeCount / 6) * 100, 100);
            const meterColor = staff.activeCount >= 5 ? '#EF4444' : (staff.activeCount >= 3 ? '#F59E0B' : '#10B981');

            return `
              <div class="card" style="padding: 0.95rem; display: flex; flex-direction: column; justify-content: space-between;">
                <div>
                  <div style="display: flex; align-items: center; justify-content: space-between; margin-bottom: 0.5rem;">
                    <div>
                      <strong style="color: var(--text-primary); font-size: 0.85rem;">${this._escape(staff.name)}</strong>
                      <span style="font-size: 0.68rem; color: var(--text-muted); display: block; font-family: monospace;">${this._escape(staff.employee_id)} • ${dept.name}</span>
                    </div>
                    <span class="badge ${staff.is_on_duty ? 'badge-resolved' : 'badge-muted'}" style="font-size: 0.68rem;">
                      ${staff.is_on_duty ? '🟢 On Duty' : '⚪ Off'}
                    </span>
                  </div>

                  <div style="display: flex; justify-content: space-between; align-items: baseline; margin-top: 0.65rem;">
                    <span style="font-size: 0.72rem; color: var(--text-muted);">Active Workload</span>
                    <span style="font-size: 0.85rem; font-weight: 700; color: ${meterColor}; font-feature-settings: 'tnum';">
                      ${staff.activeCount} <span style="font-size: 0.68rem; font-weight: 500; color: var(--text-muted);">/ 6 tasks</span>
                    </span>
                  </div>

                  <div class="workload-meter">
                    <div class="workload-meter-fill" style="width: ${loadRatio}%; background-color: ${meterColor};"></div>
                  </div>
                </div>

                <div style="display: flex; justify-content: space-between; align-items: center; margin-top: 0.85rem; padding-top: 0.55rem; border-top: 1px solid var(--border-subtle); font-size: 0.72rem;">
                  <span style="color: var(--text-muted);">${roleName}</span>
                  ${staff.urgentCount > 0 ? `
                    <span style="color: #F87171; font-weight: 600; display: flex; align-items: center; gap: 0.25rem;">
                      <span class="priority-dot urgent"></span> ${staff.urgentCount} Urgent
                    </span>
                  ` : `
                    <span style="color: var(--text-muted);">Zone: ${staff.zone || 'ALL'}</span>
                  `}
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
          <div class="empty-state-title">Failed to load workload data</div>
          <p style="font-size: 0.78rem; color: var(--danger);">${e.message || 'Error'}</p>
        </div>
      `;
    }
  }

  _escape(str) {
    const div = document.createElement('div');
    div.textContent = str;
    return div.innerHTML;
  }
}

/**
 * Smart Nagpur Admin Web — Staff Roster Page (2026 SaaS)
 * High-density directory table with duty toggle indicators, department badges, and account provisioning modal.
 */

import { staffService } from '../services/staffService.js';
import { DataTable } from '../components/dataTable.js';
import { DEPARTMENTS, STAFF_ROLES } from '../config.js';
import { modal } from '../components/modal.js';

export class StaffPage {
  constructor(container) {
    this.container = container;
    this.departmentFilter = 'all';
    this.dutyFilter = 'all';
    this.searchQuery = '';
  }

  async render() {
    this.container.innerHTML = `
      <div class="page-header">
        <div class="page-title-group">
          <h1>Field Staff Roster</h1>
          <p>Municipal technicians, ward supervisors, and quality inspectors across all zones</p>
        </div>
        <div class="page-actions">
          <button class="btn btn-primary btn-sm" id="staff-page-add-btn">
            <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><line x1="19" x2="19" y1="8" y2="14"/><line x1="22" x2="16" y1="11" y2="11"/></svg>
            <span>Provision Staff Account</span>
          </button>
        </div>
      </div>

      <div class="table-container">
        <div class="table-toolbar">
          <div class="table-filters">
            <div class="header-search" style="width: 220px; background: var(--bg-input);">
              <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" style="color: var(--text-muted);"><circle cx="11" cy="11" r="8"/><path d="m21 21-4.3-4.3"/></svg>
              <input type="text" id="staff-search-input" placeholder="Search technician..." value="${this.searchQuery}">
            </div>
            
            <select id="staff-dept-filter" class="form-select" style="font-size: 0.78rem;">
              <option value="all">All Departments</option>
              ${Object.entries(DEPARTMENTS).map(([code, d]) => `
                <option value="${code}" ${this.departmentFilter === code ? 'selected' : ''}>${d.name}</option>
              `).join('')}
            </select>

            <select id="staff-duty-filter" class="form-select" style="font-size: 0.78rem;">
              <option value="all">All Duty Status</option>
              <option value="true" ${this.dutyFilter === 'true' ? 'selected' : ''}>🟢 On Duty</option>
              <option value="false" ${this.dutyFilter === 'false' ? 'selected' : ''}>⚪ Off Duty</option>
            </select>
          </div>
        </div>

        <div id="staff-table-mount"></div>
      </div>
    `;

    this._bindEvents();
    await this.loadData();
  }

  _bindEvents() {
    const addBtn = this.container.querySelector('#staff-page-add-btn');
    if (addBtn) {
      addBtn.addEventListener('click', () => {
        modal.openCreateStaffModal(() => this.loadData());
      });
    }

    const searchInput = this.container.querySelector('#staff-search-input');
    const deptSelect = this.container.querySelector('#staff-dept-filter');
    const dutySelect = this.container.querySelector('#staff-duty-filter');

    searchInput.addEventListener('keydown', (e) => {
      if (e.key === 'Enter') {
        this.searchQuery = searchInput.value;
        this.loadData();
      }
    });

    deptSelect.addEventListener('change', () => {
      this.departmentFilter = deptSelect.value;
      this.loadData();
    });

    dutySelect.addEventListener('change', () => {
      this.dutyFilter = dutySelect.value;
      this.loadData();
    });
  }

  async loadData() {
    const mount = this.container.querySelector('#staff-table-mount');
    if (!mount) return;

    const table = new DataTable({
      container: mount,
      columns: [],
      isLoading: true
    });
    table.renderSkeleton();

    try {
      const staffList = await staffService.getStaffMembers({
        department: this.departmentFilter,
        isOnDuty: this.dutyFilter === 'all' ? null : this.dutyFilter,
        search: this.searchQuery
      });

      const columns = [
        {
          label: 'Technician',
          width: '200px',
          render: (row) => `
            <div style="display: flex; align-items: center; gap: 0.6rem;">
              <div class="admin-avatar" style="background: rgba(37, 99, 235, 0.15); color: #93C5FD; font-size: 0.75rem; width: 26px; height: 26px;">
                ${(row.name || 'S').charAt(0).toUpperCase()}
              </div>
              <div style="display: flex; flex-direction: column;">
                <strong style="color: var(--text-primary); font-size: 0.8rem;">${this._escape(row.name)}</strong>
                <span style="font-size: 0.68rem; color: var(--text-muted); font-family: monospace;">${this._escape(row.employee_id)}</span>
              </div>
            </div>
          `
        },
        {
          label: 'Department & Role',
          width: '220px',
          render: (row) => {
            const d = DEPARTMENTS[row.department] || { name: row.department || 'General', icon: '🏛️' };
            const r = STAFF_ROLES[row.role]?.label || row.role || 'Field Technician';
            return `
              <div style="display: flex; flex-direction: column;">
                <span style="font-weight: 500; font-size: 0.78rem; color: var(--text-primary);">${d.icon} ${d.name}</span>
                <span style="font-size: 0.68rem; color: var(--text-muted);">${r}</span>
              </div>
            `;
          }
        },
        {
          label: 'Contact Info',
          width: '180px',
          render: (row) => `
            <div style="display: flex; flex-direction: column; font-size: 0.75rem;">
              <span style="color: var(--text-primary);">${this._escape(row.phone || '—')}</span>
              <span style="color: var(--text-muted); font-size: 0.68rem;">${this._escape(row.email || '')}</span>
            </div>
          `
        },
        {
          label: 'Duty Status',
          width: '110px',
          render: (row) => `
            <span class="badge ${row.is_on_duty ? 'badge-resolved' : 'badge-muted'}">
              ${row.is_on_duty ? '🟢 On Duty' : '⚪ Off Duty'}
            </span>
          `
        },
        {
          label: 'Account Status',
          width: '110px',
          render: (row) => `
            <span class="badge ${row.is_active ? 'badge-assigned' : 'badge-rejected'}">
              ${row.is_active ? 'Active' : 'Deactivated'}
            </span>
          `
        }
      ];

      const dataTableInstance = new DataTable({
        container: mount,
        columns,
        data: staffList,
        totalCount: staffList.length,
        pageSize: 50
      });

      dataTableInstance.render();

    } catch (e) {
      mount.innerHTML = `
        <div class="empty-state">
          <div class="empty-state-icon">⚠️</div>
          <div class="empty-state-title">Failed to load staff roster</div>
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

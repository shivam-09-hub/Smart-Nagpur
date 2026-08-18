/**
 * Smart Nagpur Admin Web — Task Assignments Page (2026 SaaS)
 * Operational overview of field assignments across all 8 municipal departments.
 */

import { operationsService } from '../services/operationsService.js';
import { staffService } from '../services/staffService.js';
import { DataTable } from '../components/dataTable.js';
import { ASSIGNMENT_STATUSES, DEPARTMENTS, PRIORITIES } from '../config.js';

export class AssignmentsPage {
  constructor(container) {
    this.container = container;
    this.statusFilter = 'all';
    this.departmentFilter = 'all';
    this.staffFilter = 'all';
    this.currentPage = 1;
    this.pageSize = 15;
  }

  async render() {
    this.container.innerHTML = `
      <div class="page-header">
        <div class="page-title-group">
          <h1>Work Orders & Dispatches</h1>
          <p>Lifecycle tracking of all municipal maintenance orders assigned to field technicians</p>
        </div>
      </div>

      <div class="table-container">
        <div class="table-toolbar">
          <div class="table-filters">
            <select id="assign-status-filter" class="form-select" style="font-size: 0.78rem;">
              <option value="all">All Task Statuses</option>
              ${Object.entries(ASSIGNMENT_STATUSES).map(([code, s]) => `
                <option value="${code}" ${this.statusFilter === code ? 'selected' : ''}>${s.label}</option>
              `).join('')}
            </select>

            <select id="assign-dept-filter" class="form-select" style="font-size: 0.78rem;">
              <option value="all">All Departments</option>
              ${Object.entries(DEPARTMENTS).map(([code, d]) => `
                <option value="${code}" ${this.departmentFilter === code ? 'selected' : ''}>${d.icon} ${d.name}</option>
              `).join('')}
            </select>

            <select id="assign-staff-filter" class="form-select" style="font-size: 0.78rem;">
              <option value="all">All Staff Members</option>
            </select>
          </div>
        </div>

        <div id="assignments-table-mount"></div>
      </div>
    `;

    await this._loadStaffFilter();
    this._bindEvents();
    await this.loadData();
  }

  async _loadStaffFilter() {
    try {
      const staffList = await staffService.getStaffMembers({ isActive: true });
      const select = this.container.querySelector('#assign-staff-filter');
      if (select) {
        select.innerHTML = `
          <option value="all">All Staff Members</option>
          ${staffList.map(s => `
            <option value="${s.id}" ${this.staffFilter === s.id ? 'selected' : ''}>${s.name} (${s.employee_id})</option>
          `).join('')}
        `;
      }
    } catch (_) {}
  }

  _bindEvents() {
    const statusSelect = this.container.querySelector('#assign-status-filter');
    const deptSelect = this.container.querySelector('#assign-dept-filter');
    const staffSelect = this.container.querySelector('#assign-staff-filter');

    const handleFilter = () => {
      this.statusFilter = statusSelect.value;
      this.departmentFilter = deptSelect.value;
      this.staffFilter = staffSelect.value;
      this.currentPage = 1;
      this.loadData();
    };

    statusSelect.addEventListener('change', handleFilter);
    deptSelect.addEventListener('change', handleFilter);
    staffSelect.addEventListener('change', handleFilter);
  }

  async loadData() {
    const mount = this.container.querySelector('#assignments-table-mount');
    if (!mount) return;

    const table = new DataTable({
      container: mount,
      columns: [],
      isLoading: true
    });
    table.renderSkeleton();

    try {
      const offset = (this.currentPage - 1) * this.pageSize;
      const { data, count } = await operationsService.getAssignments({
        status: this.statusFilter,
        department: this.departmentFilter,
        staffId: this.staffFilter,
        limit: this.pageSize,
        offset
      });

      const columns = [
        {
          label: 'Grievance / Ref',
          width: '140px',
          render: (row) => {
            const refId = row.complaints?.public_id || row.complaints?.reference_number || row.complaint_id?.substring(0, 8);
            return `
              <div style="display: flex; flex-direction: column;">
                <a href="#complaint-details/${row.complaint_id}" style="color: #60A5FA; font-weight: 600; font-family: monospace; font-size: 0.8rem;">
                  #${refId}
                </a>
                <span style="font-size: 0.68rem; color: var(--text-muted);">
                  ${new Date(row.assigned_at).toLocaleDateString('en-IN', { day: '2-digit', month: 'short' })}
                </span>
              </div>
            `;
          }
        },
        {
          label: 'Field Technician',
          width: '180px',
          render: (row) => {
            const dept = DEPARTMENTS[row.staff_profiles?.department] || { name: row.staff_profiles?.department || 'General', icon: '🏛️' };
            return `
              <div style="display: flex; flex-direction: column;">
                <strong style="color: var(--text-primary); font-size: 0.8rem;">${row.staff_profiles?.name || 'Staff Member'}</strong>
                <span style="font-size: 0.68rem; color: var(--text-muted);">${dept.icon} ${dept.name}</span>
              </div>
            `;
          }
        },
        {
          label: 'Priority',
          width: '100px',
          render: (row) => {
            const p = PRIORITIES[row.priority] || { label: row.priority || 'Medium', badgeClass: 'priority-medium' };
            return `
              <span class="priority-indicator">
                <span class="priority-dot ${row.priority || 'medium'}"></span>
                <span>${p.label}</span>
              </span>
            `;
          }
        },
        {
          label: 'Work Order Status',
          width: '140px',
          render: (row) => {
            const st = ASSIGNMENT_STATUSES[row.status] || { label: row.status, badgeClass: 'badge-muted' };
            return `<span class="badge ${st.badgeClass}">${st.label}</span>`;
          }
        },
        {
          label: 'Action',
          width: '130px',
          render: (row) => `
            <div style="display: flex; align-items: center; gap: 0.35rem;">
              <a href="#complaint-details/${row.complaint_id}" class="btn btn-secondary btn-sm">
                Details
              </a>
              ${row.status === 'completed' ? `
                <a href="#evidence/${row.complaint_id}" class="btn btn-warning btn-sm" style="font-weight: 600;">
                  Verify
                </a>
              ` : ''}
            </div>
          `
        }
      ];

      const dataTableInstance = new DataTable({
        container: mount,
        columns,
        data,
        totalCount: count,
        page: this.currentPage,
        pageSize: this.pageSize,
        onPageChange: (newPage) => {
          this.currentPage = newPage;
          this.loadData();
        }
      });

      dataTableInstance.render();

    } catch (e) {
      mount.innerHTML = `
        <div class="empty-state">
          <div class="empty-state-icon">⚠️</div>
          <div class="empty-state-title">Failed to load work orders</div>
          <p style="font-size: 0.78rem; color: var(--danger);">${e.message || 'Network error'}</p>
        </div>
      `;
    }
  }
}

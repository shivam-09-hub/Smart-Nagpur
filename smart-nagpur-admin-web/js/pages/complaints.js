/**
 * Smart Nagpur Admin Web — Complaints Management Page (2026 SaaS)
 * High-density SaaS data table, filter chips, priority indicators, and quick dispatch.
 */

import { adminService } from '../services/adminService.js';
import { DataTable } from '../components/dataTable.js';
import { COMPLAINT_STATUSES, SERVICE_TYPES } from '../config.js';
import { modal } from '../components/modal.js';

export class ComplaintsPage {
  constructor(container) {
    this.container = container;
    this.statusFilter = 'all';
    this.serviceFilter = 'all';
    this.searchQuery = '';
    this.currentPage = 1;
    this.pageSize = 15;
  }

  async render() {
    this.container.innerHTML = `
      <div class="page-header">
        <div class="page-title-group">
          <h1>Civic Grievances</h1>
          <p>Triage, dispatch, and track municipal complaints submitted across Nagpur wards</p>
        </div>
      </div>

      <div class="table-container">
        <div class="table-toolbar">
          <div class="table-filters">
            <div class="header-search" style="width: 240px; background: var(--bg-input);">
              <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" style="color: var(--text-muted);"><circle cx="11" cy="11" r="8"/><path d="m21 21-4.3-4.3"/></svg>
              <input type="text" id="complaint-search-input" placeholder="Search reference, address..." value="${this.searchQuery}">
            </div>

            <!-- Status Filter Chips -->
            <div class="filter-chips-container" id="status-chips-mount">
              <button class="filter-chip ${this.statusFilter === 'all' ? 'active' : ''}" data-status="all">All</button>
              <button class="filter-chip ${this.statusFilter === 'submitted' ? 'active' : ''}" data-status="submitted">Pending</button>
              <button class="filter-chip ${this.statusFilter === 'in_progress' ? 'active' : ''}" data-status="in_progress">In Progress</button>
              <button class="filter-chip ${this.statusFilter === 'completed' ? 'active' : ''}" data-status="completed">Under Review</button>
              <button class="filter-chip ${this.statusFilter === 'resolved' ? 'active' : ''}" data-status="resolved">Resolved</button>
            </div>

            <select id="complaint-service-filter" class="form-select" style="font-size: 0.78rem;">
              <option value="all">All Service Types</option>
              ${Object.entries(SERVICE_TYPES).map(([code, s]) => `
                <option value="${code}" ${this.serviceFilter === code ? 'selected' : ''}>${s.icon} ${s.label}</option>
              `).join('')}
            </select>
          </div>
        </div>

        <div id="complaints-table-mount"></div>
      </div>
    `;

    this._bindEvents();
    await this.loadData();
  }

  _bindEvents() {
    const searchInput = this.container.querySelector('#complaint-search-input');
    const serviceSelect = this.container.querySelector('#complaint-service-filter');
    const chipBtns = this.container.querySelectorAll('.filter-chip');

    searchInput.addEventListener('keydown', (e) => {
      if (e.key === 'Enter') {
        this.searchQuery = searchInput.value;
        this.currentPage = 1;
        this.loadData();
      }
    });

    serviceSelect.addEventListener('change', () => {
      this.serviceFilter = serviceSelect.value;
      this.currentPage = 1;
      this.loadData();
    });

    chipBtns.forEach(btn => {
      btn.addEventListener('click', () => {
        chipBtns.forEach(b => b.classList.remove('active'));
        btn.classList.add('active');
        this.statusFilter = btn.getAttribute('data-status');
        this.currentPage = 1;
        this.loadData();
      });
    });
  }

  async loadData() {
    const mount = this.container.querySelector('#complaints-table-mount');
    if (!mount) return;

    const table = new DataTable({
      container: mount,
      columns: [],
      isLoading: true
    });
    table.renderSkeleton();

    try {
      const offset = (this.currentPage - 1) * this.pageSize;
      const { data, count } = await adminService.getComplaints({
        status: this.statusFilter,
        serviceType: this.serviceFilter,
        search: this.searchQuery,
        limit: this.pageSize,
        offset
      });

      const columns = [
        {
          label: 'ID / Reference',
          width: '130px',
          render: (row) => {
            const refId = row.public_id || row.reference_number || row.id?.substring(0, 8);
            return `
              <a href="#complaint-details/${row.id}" style="color: #60A5FA; font-weight: 600; font-family: monospace; font-size: 0.8rem;">
                #${refId}
              </a>
            `;
          }
        },
        {
          label: 'Service Domain',
          width: '160px',
          render: (row) => {
            const svc = SERVICE_TYPES[row.service_type] || { label: row.service_type || 'Civic', icon: '📋' };
            return `
              <span style="font-weight: 500; font-size: 0.78rem; display: flex; align-items: center; gap: 0.35rem;">
                ${svc.icon} ${svc.label}
              </span>
            `;
          }
        },
        {
          label: 'Issue & Location',
          render: (row) => {
            const issueText = row.description || row.issue || row.issue_description || 'No description';
            const locText = row.location_address || row.address_text || 'Nagpur';
            return `
              <div style="max-width: 320px; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; font-weight: 500;" title="${this._escape(issueText)}">
                ${this._escape(issueText)}
              </div>
              <div style="font-size: 0.7rem; color: var(--text-muted); max-width: 320px; white-space: nowrap; overflow: hidden; text-overflow: ellipsis;">
                📍 ${this._escape(locText)}
              </div>
            `;
          }
        },
        {
          label: 'Citizen',
          width: '140px',
          render: (row) => {
            const p = row.profiles;
            return `
              <div style="display: flex; flex-direction: column;">
                <span style="font-weight: 500; font-size: 0.78rem;">${this._escape(p?.name || 'Citizen')}</span>
                <span style="font-size: 0.68rem; color: var(--text-muted);">${p?.phone || row.contact_phone || '—'}</span>
              </div>
            `;
          }
        },
        {
          label: 'Status',
          width: '110px',
          render: (row) => {
            const st = COMPLAINT_STATUSES[row.status] || { label: row.status, badgeClass: 'badge-muted' };
            return `<span class="badge ${st.badgeClass}">${st.label}</span>`;
          }
        },
        {
          label: 'Actions',
          width: '120px',
          render: (row) => `
            <div style="display: flex; align-items: center; gap: 0.35rem;">
              <a href="#complaint-details/${row.id}" class="btn btn-secondary btn-sm">
                Open
              </a>
              ${['submitted', 'under_review', 'underReview', 'rework_required', 'reworkRequired'].includes(row.status) ? `
                <button class="btn btn-primary btn-sm quick-assign-btn" data-id="${row.id}">
                  Assign
                </button>
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

      mount.querySelectorAll('.quick-assign-btn').forEach(btn => {
        btn.addEventListener('click', (e) => {
          const id = e.currentTarget.getAttribute('data-id');
          const complaint = data.find(c => c.id === id);
          if (complaint) {
            modal.openAssignComplaintModal({
              ...complaint,
              reference_number: complaint.public_id || complaint.reference_number || complaint.id,
              issue_description: complaint.description || complaint.issue || complaint.issue_description
            }, () => this.loadData());
          }
        });
      });

    } catch (e) {
      mount.innerHTML = `
        <div class="empty-state">
          <div class="empty-state-icon">⚠️</div>
          <div class="empty-state-title">Failed to load grievances</div>
          <p style="font-size: 0.78rem; color: var(--danger);">${e.message || 'Network error'}</p>
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

/**
 * Smart Nagpur Admin Web — Street Vendor Permitting Page (2026 SaaS)
 * Review, verify document uploads, and issue vending zone permits.
 */

import { vendorService } from '../services/vendorService.js';
import { DataTable } from '../components/dataTable.js';
import { VENDOR_STATUSES } from '../config.js';
import { modal } from '../components/modal.js';
import { toast } from '../components/toast.js';

export class VendorsPage {
  constructor(container) {
    this.container = container;
    this.statusFilter = 'all';
    this.searchQuery = '';
    this.currentPage = 1;
    this.pageSize = 15;
  }

  async render() {
    this.container.innerHTML = `
      <div class="page-header">
        <div class="page-title-group">
          <h1>Street Vendor Permitting</h1>
          <p>Triage permit applications, inspect submitted KYC documents, and issue designated vending zone approvals</p>
        </div>
      </div>

      <div class="table-container">
        <div class="table-toolbar">
          <div class="table-filters">
            <div class="header-search" style="width: 220px; background: var(--bg-input);">
              <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" style="color: var(--text-muted);"><circle cx="11" cy="11" r="8"/><path d="m21 21-4.3-4.3"/></svg>
              <input type="text" id="vendor-search-input" placeholder="Search application..." value="${this.searchQuery}">
            </div>
            
            <select id="vendor-status-filter" class="form-select" style="font-size: 0.78rem;">
              <option value="all">All Application Statuses</option>
              ${Object.entries(VENDOR_STATUSES).map(([code, s]) => `
                <option value="${code}" ${this.statusFilter === code ? 'selected' : ''}>${s.label}</option>
              `).join('')}
            </select>
          </div>
        </div>

        <div id="vendors-table-mount"></div>
      </div>
    `;

    this._bindEvents();
    await this.loadData();
  }

  _bindEvents() {
    const searchInput = this.container.querySelector('#vendor-search-input');
    const statusSelect = this.container.querySelector('#vendor-status-filter');

    searchInput.addEventListener('keydown', (e) => {
      if (e.key === 'Enter') {
        this.searchQuery = searchInput.value;
        this.currentPage = 1;
        this.loadData();
      }
    });

    statusSelect.addEventListener('change', () => {
      this.statusFilter = statusSelect.value;
      this.currentPage = 1;
      this.loadData();
    });
  }

  async loadData() {
    const mount = this.container.querySelector('#vendors-table-mount');
    if (!mount) return;

    const table = new DataTable({
      container: mount,
      columns: [],
      isLoading: true
    });
    table.renderSkeleton();

    try {
      const offset = (this.currentPage - 1) * this.pageSize;
      const { data, count } = await vendorService.getVendorApplications({
        status: this.statusFilter,
        search: this.searchQuery,
        limit: this.pageSize,
        offset
      });

      const columns = [
        {
          label: 'Application / Date',
          width: '140px',
          render: (row) => `
            <div style="display: flex; flex-direction: column;">
              <strong style="color: #60A5FA; font-family: monospace; font-size: 0.8rem;">#${row.reference_number || row.id.substring(0, 8)}</strong>
              <span style="font-size: 0.68rem; color: var(--text-muted);">${new Date(row.created_at).toLocaleDateString('en-IN', { day: '2-digit', month: 'short', year: 'numeric' })}</span>
            </div>
          `
        },
        {
          label: 'Applicant & Business',
          render: (row) => {
            const d = row.details || {};
            const applicantName = d.applicantName || d.full_name || row.profiles?.name || 'Vendor Applicant';
            const businessName = d.businessName || d.business_name || 'Retail Trade';
            return `
              <div style="display: flex; flex-direction: column;">
                <strong style="color: var(--text-primary); font-size: 0.8rem;">${this._escape(applicantName)}</strong>
                <span style="font-size: 0.72rem; color: var(--text-secondary);">${this._escape(businessName)}</span>
              </div>
            `;
          }
        },
        {
          label: 'Requested Vending Zone',
          width: '160px',
          render: (row) => {
            const d = row.details || {};
            return `
              <span style="font-size: 0.78rem; font-weight: 500;">
                📍 ${this._escape(d.zone || d.preferred_zone || 'Nagpur Central')}
              </span>
            `;
          }
        },
        {
          label: 'Permit Status',
          width: '120px',
          render: (row) => {
            const st = VENDOR_STATUSES[row.status] || { label: row.status, badgeClass: 'badge-muted' };
            return `<span class="badge ${st.badgeClass}">${st.label}</span>`;
          }
        },
        {
          label: 'Review Action',
          width: '130px',
          render: (row) => `
            <button class="btn btn-secondary btn-sm inspect-vendor-btn" data-id="${row.id}">
              Inspect Permit
            </button>
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

      // Hook inspect vendor buttons
      mount.querySelectorAll('.inspect-vendor-btn').forEach(btn => {
        btn.addEventListener('click', async (e) => {
          const appId = e.currentTarget.getAttribute('data-id');
          await this._openVendorModal(appId);
        });
      });

    } catch (e) {
      mount.innerHTML = `
        <div class="empty-state">
          <div class="empty-state-icon">⚠️</div>
          <div class="empty-state-title">Failed to load vendor applications</div>
          <p style="font-size: 0.78rem; color: var(--danger);">${e.message || 'Error'}</p>
        </div>
      `;
    }
  }

  async _openVendorModal(applicationId) {
    try {
      const app = await vendorService.getApplicationDetails(applicationId);
      if (!app) {
        toast.error('Application not found');
        return;
      }

      const d = app.details || {};
      const statusInfo = VENDOR_STATUSES[app.status] || { label: app.status, badgeClass: 'badge-muted' };

      const bodyHtml = `
        <div style="display: flex; flex-direction: column; gap: 0.85rem;">
          <div style="display: flex; justify-content: space-between; align-items: center; background: var(--bg-surface-subtle); padding: 0.65rem 0.85rem; border-radius: var(--radius-sm); border: 1px solid var(--border-subtle);">
            <div>
              <span style="font-size: 0.68rem; color: var(--text-muted); text-transform: uppercase;">Application Reference</span>
              <strong style="display: block; color: #60A5FA; font-size: 0.95rem; font-family: monospace;">#${app.reference_number || app.id.substring(0, 8)}</strong>
            </div>
            <span class="badge ${statusInfo.badgeClass}">${statusInfo.label}</span>
          </div>

          <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 0.65rem; font-size: 0.8rem;">
            <div>
              <span style="color: var(--text-muted); font-size: 0.68rem; display: block;">Applicant Name</span>
              <strong>${this._escape(d.applicantName || app.profiles?.name || 'Vendor')}</strong>
            </div>
            <div>
              <span style="color: var(--text-muted); font-size: 0.68rem; display: block;">Contact Phone</span>
              <span style="font-family: monospace;">${this._escape(d.phone || app.profiles?.phone || '—')}</span>
            </div>
            <div>
              <span style="color: var(--text-muted); font-size: 0.68rem; display: block;">Business Trade</span>
              <strong>${this._escape(d.businessName || '—')}</strong>
            </div>
            <div>
              <span style="color: var(--text-muted); font-size: 0.68rem; display: block;">Designated Zone</span>
              <span>📍 ${this._escape(d.zone || d.preferred_zone || 'Nagpur')}</span>
            </div>
          </div>

          <!-- Documents List -->
          <div>
            <span style="font-weight: 600; font-size: 0.75rem; color: var(--text-muted); text-transform: uppercase; display: block; margin-bottom: 0.4rem;">
              Attached KYC Documents (${app.documents?.length || 0})
            </span>
            ${!app.documents || app.documents.length === 0 ? `
              <p style="font-size: 0.78rem; color: var(--text-muted);">No documents uploaded.</p>
            ` : `
              <div style="display: flex; flex-direction: column; gap: 0.35rem;">
                ${app.documents.map(doc => `
                  <div style="display: flex; align-items: center; justify-content: space-between; background: var(--bg-surface-subtle); padding: 0.45rem 0.65rem; border-radius: var(--radius-xs); border: 1px solid var(--border-subtle);">
                    <span style="font-size: 0.78rem; color: var(--text-primary);">📎 ${this._escape(doc.documentType || doc.fileName)}</span>
                    ${doc.url ? `
                      <a href="${doc.url}" target="_blank" class="btn btn-secondary btn-sm" style="padding: 0.15rem 0.45rem; font-size: 0.7rem;">View ↗</a>
                    ` : '<span style="font-size: 0.68rem; color: var(--text-muted);">Protected</span>'}
                  </div>
                `).join('')}
              </div>
            `}
          </div>

          <div class="form-group">
            <label class="form-label">Permit Directives / Conditions</label>
            <textarea class="form-control" id="vendor-decision-notes" rows="2" placeholder="Permit terms or rejection justification..."></textarea>
          </div>
        </div>
      `;

      const footerHtml = `
        <button type="button" class="btn btn-secondary modal-cancel-btn">Close</button>
        <button type="button" class="btn btn-danger" id="vendor-reject-btn">Reject</button>
        <button type="button" class="btn btn-success" id="vendor-approve-btn">Approve & Issue Permit</button>
      `;

      modal.open({
        title: `Review Application #${app.reference_number || ''}`,
        bodyHtml,
        footerHtml,
        onOpen: (backdrop) => {
          backdrop.querySelector('.modal-cancel-btn').addEventListener('click', () => modal.close());

          const approveBtn = backdrop.querySelector('#vendor-approve-btn');
          const rejectBtn = backdrop.querySelector('#vendor-reject-btn');
          const notesEl = backdrop.querySelector('#vendor-decision-notes');

          approveBtn.addEventListener('click', async () => {
            approveBtn.disabled = true;
            try {
              await vendorService.updateApplicationStatus(app.id, 'approved', notesEl.value);
              toast.success('Street vendor permit issued');
              modal.close();
              this.loadData();
            } catch (err) {
              toast.error(err.message || 'Approval failed');
              approveBtn.disabled = false;
            }
          });

          rejectBtn.addEventListener('click', async () => {
            if (!confirm('Reject this street vendor application?')) return;
            rejectBtn.disabled = true;
            try {
              await vendorService.updateApplicationStatus(app.id, 'rejected', notesEl.value);
              toast.success('Vendor application rejected');
              modal.close();
              this.loadData();
            } catch (err) {
              toast.error(err.message || 'Rejection failed');
              rejectBtn.disabled = false;
            }
          });
        }
      });

    } catch (e) {
      toast.error('Failed to open vendor review');
    }
  }

  _escape(str) {
    const div = document.createElement('div');
    div.textContent = str;
    return div.innerHTML;
  }
}

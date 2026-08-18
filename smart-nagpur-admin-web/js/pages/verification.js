/**
 * Smart Nagpur Admin Web — Verification Queue Page (2026 SaaS)
 * Review queue for completed field tasks awaiting administrative sign-off.
 */

import { operationsService } from '../services/operationsService.js';
import { DataTable } from '../components/dataTable.js';
import { PRIORITIES, DEPARTMENTS, SERVICE_TYPES } from '../config.js';

export class VerificationPage {
  constructor(container) {
    this.container = container;
  }

  async render() {
    this.container.innerHTML = `
      <div class="page-header">
        <div class="page-title-group">
          <h1>Municipal Verification Queue</h1>
          <p>Completed field maintenance tasks awaiting proof inspection, geo-verification, and resolution sign-off</p>
        </div>
      </div>

      <div class="table-container">
        <div id="verification-table-mount"></div>
      </div>
    `;

    await this.loadData();
  }

  async loadData() {
    const mount = this.container.querySelector('#verification-table-mount');
    if (!mount) return;

    const table = new DataTable({
      container: mount,
      columns: [],
      isLoading: true
    });
    table.renderSkeleton();

    try {
      const items = await operationsService.getVerificationQueue();

      if (!items || items.length === 0) {
        mount.innerHTML = `
          <div class="empty-state" style="padding: 3.5rem 1.5rem;">
            <div class="empty-state-icon">🛡️</div>
            <div class="empty-state-title">Verification Queue is Clear</div>
            <p style="font-size: 0.8rem; color: var(--text-muted); margin-top: 0.25rem;">
              All completed field tasks have been reviewed and approved.
            </p>
          </div>
        `;
        return;
      }

      const columns = [
        {
          label: 'Grievance / Service',
          width: '180px',
          render: (row) => {
            const refId = row.complaints?.public_id || row.complaints?.reference_number || row.complaint_id?.substring(0, 8);
            const svc = SERVICE_TYPES[row.complaints?.service_type] || { label: 'Civic', icon: '📋' };
            return `
              <div style="display: flex; flex-direction: column;">
                <a href="#complaint-details/${row.complaint_id}" style="color: #60A5FA; font-weight: 600; font-family: monospace; font-size: 0.8rem;">
                  #${refId}
                </a>
                <span style="font-size: 0.72rem; color: var(--text-secondary);">${svc.icon} ${svc.label}</span>
              </div>
            `;
          }
        },
        {
          label: 'Field Technician',
          width: '160px',
          render: (row) => `
            <div style="display: flex; flex-direction: column;">
              <strong style="color: var(--text-primary); font-size: 0.8rem;">${row.staff_profiles?.name || 'Technician'}</strong>
              <span style="font-size: 0.68rem; color: var(--text-muted);">
                ${DEPARTMENTS[row.staff_profiles?.department]?.name || row.staff_profiles?.department || '—'}
              </span>
            </div>
          `
        },
        {
          label: 'Completion Notes',
          render: (row) => `
            <div style="max-width: 280px; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; font-size: 0.78rem;" title="${this._escape(row.completion_notes || row.notes || row.instructions || '')}">
              ${this._escape(row.completion_notes || row.notes || 'Work completed as instructed.')}
            </div>
          `
        },
        {
          label: 'Priority',
          width: '100px',
          render: (row) => {
            const p = PRIORITIES[row.priority] || { label: row.priority || 'Medium' };
            return `
              <span class="priority-indicator">
                <span class="priority-dot ${row.priority || 'medium'}"></span>
                <span>${p.label}</span>
              </span>
            `;
          }
        },
        {
          label: 'Completed At',
          width: '130px',
          render: (row) => `
            <span style="font-size: 0.75rem; color: var(--text-secondary);">
              ${new Date(row.completed_at || row.assigned_at).toLocaleString('en-IN', { day: '2-digit', month: 'short', hour: '2-digit', minute: '2-digit' })}
            </span>
          `
        },
        {
          label: 'Review Action',
          width: '140px',
          render: (row) => `
            <a href="#evidence/${row.complaint_id}" class="btn btn-warning btn-sm" style="font-weight: 600;">
              Inspect Evidence →
            </a>
          `
        }
      ];

      const dataTableInstance = new DataTable({
        container: mount,
        columns,
        data: items,
        totalCount: items.length,
        pageSize: 50
      });

      dataTableInstance.render();

    } catch (e) {
      mount.innerHTML = `
        <div class="empty-state">
          <div class="empty-state-icon">⚠️</div>
          <div class="empty-state-title">Failed to load verification queue</div>
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

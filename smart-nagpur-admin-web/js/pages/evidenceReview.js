/**
 * Smart Nagpur Admin Web — Evidence Review & Verification Workspace (2026 SaaS)
 * Side-by-side Before Work vs. After Work vs. Inspection Report gallery,
 * Geo-Verification HUD (Coordinates, Distance, Accuracy), and Approve/Rework actions.
 */

import { adminService } from '../services/adminService.js';
import { operationsService } from '../services/operationsService.js';
import { modal } from '../components/modal.js';
import { toast } from '../components/toast.js';

export class EvidenceReviewPage {
  constructor(container, complaintId) {
    this.container = container;
    this.complaintId = complaintId;
  }

  async render() {
    this.container.innerHTML = `
      <div style="padding: 2rem 0;">
        <div class="skeleton skeleton-rect" style="height: 48px; margin-bottom: 1.25rem;"></div>
        <div class="skeleton skeleton-rect" style="height: 380px;"></div>
      </div>
    `;

    try {
      const [complaint, evidenceList] = await Promise.all([
        adminService.getComplaintDetails(this.complaintId),
        operationsService.getComplaintEvidence(this.complaintId)
      ]);

      if (!complaint) {
        this.container.innerHTML = `
          <div class="card" style="text-align: center; padding: 3rem;">
            <h2>Record Not Found</h2>
            <a href="#verification" class="btn btn-primary btn-sm" style="margin-top: 1rem;">Back to Verification Queue</a>
          </div>
        `;
        return;
      }

      const activeAssign = complaint.activeAssignment || complaint.assignments?.[0];
      const beforeEvidence = evidenceList.filter(e => e.evidence_type === 'before_work' || e.evidence_type === 'beforeWork');
      const afterEvidence = evidenceList.filter(e => e.evidence_type === 'after_work' || e.evidence_type === 'afterWork');
      const reports = evidenceList.filter(e => e.evidence_type === 'inspection_report' || e.evidence_type === 'inspectionReport');

      const refId = complaint.public_id || complaint.reference_number || complaint.id.substring(0, 8);
      const addressText = complaint.location_address || complaint.address_text || 'Nagpur';
      const issueText = complaint.description || complaint.issue || complaint.issue_description || 'Civic issue report';

      this.container.innerHTML = `
        <div class="page-header">
          <div class="page-title-group">
            <div style="display: flex; align-items: center; gap: 0.65rem;">
              <a href="#verification" class="btn btn-secondary btn-sm" style="padding: 0.25rem 0.5rem;">
                <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="m15 18-6-6 6-6"/></svg>
              </a>
              <h1>Evidence Review: Grievance #${refId}</h1>
            </div>
            <p style="margin-top: 0.2rem;">
              Field Technician: <strong>${activeAssign?.staff_profiles?.name || 'Technician'} (${activeAssign?.staff_profiles?.employee_id || ''})</strong>
              • Location: <strong>${addressText}</strong>
            </p>
          </div>

          <div class="page-actions">
            ${activeAssign ? `
              <button class="btn btn-danger btn-sm" id="review-rework-btn">
                <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M3 12a9 9 0 0 1 9-9 9.75 9.75 0 0 1 6.74 2.74L21 8"/><path d="M21 3v5h-5"/><path d="M21 12a9 9 0 0 1-9 9 9.75 9.75 0 0 1-6.74-2.74L3 16"/><path d="M8 16H3v5"/></svg>
                <span>Request Field Rework</span>
              </button>
              <button class="btn btn-success btn-sm" id="review-approve-btn" style="font-weight: 600;">
                <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polyline points="20 6 9 17 4 12"/></svg>
                <span>Approve & Resolve</span>
              </button>
            ` : ''}
          </div>
        </div>

        <!-- Issue Overview Banner -->
        <div class="card" style="margin-bottom: 1.25rem; background-color: var(--bg-surface-subtle);">
          <div style="display: flex; justify-content: space-between; align-items: flex-start; gap: 1rem;">
            <div>
              <span style="font-size: 0.7rem; color: var(--text-muted); text-transform: uppercase; font-weight: 600; letter-spacing: 0.05em;">Reported Civic Issue</span>
              <p style="font-size: 0.88rem; color: var(--text-primary); margin-top: 0.2rem;">
                ${this._escape(issueText)}
              </p>
            </div>
            ${complaint.latitude && complaint.longitude ? `
              <div style="text-align: right; font-size: 0.75rem; color: var(--text-secondary); flex-shrink: 0;">
                <div>Origin GPS: <strong style="color: #60A5FA; font-family: monospace;">${complaint.latitude.toFixed(6)}, ${complaint.longitude.toFixed(6)}</strong></div>
                <a href="https://www.google.com/maps?q=${complaint.latitude},${complaint.longitude}" target="_blank" style="color: #60A5FA; font-size: 0.72rem;">Open Location ↗</a>
              </div>
            ` : ''}
          </div>
        </div>

        <!-- Side-by-Side Evidence Inspection Workspace -->
        <div class="evidence-workspace">
          <!-- Before Work Panel -->
          <div class="evidence-panel">
            <div class="card-header">
              <div class="card-title" style="color: #FBBF24;">
                <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M14.5 4h-5L7 7H4a2 2 0 0 0-2 2v9a2 2 0 0 0 2 2h16a2 2 0 0 0 2-2V9a2 2 0 0 0-2-2h-3l-2.5-3z"/><circle cx="12" cy="13" r="3"/></svg>
                <span>1. Before Work Proof (${beforeEvidence.length})</span>
              </div>
            </div>
            ${beforeEvidence.length === 0 ? `
              <div class="empty-state" style="padding: 3rem 1rem;">
                <div class="empty-state-icon">📷</div>
                <div class="empty-state-title">No Before-Work Proof</div>
                <p style="font-size: 0.78rem;">Technician did not capture pre-maintenance photo.</p>
              </div>
            ` : `
              ${beforeEvidence.map(item => this._renderEvidenceCard(item)).join('')}
            `}
          </div>

          <!-- After Work Panel -->
          <div class="evidence-panel">
            <div class="card-header">
              <div class="card-title" style="color: #34D399;">
                <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polyline points="20 6 9 17 4 12"/></svg>
                <span>2. After Work Resolution Proof (${afterEvidence.length})</span>
              </div>
            </div>
            ${afterEvidence.length === 0 ? `
              <div class="empty-state" style="padding: 3rem 1rem;">
                <div class="empty-state-icon">📷</div>
                <div class="empty-state-title">No After-Work Proof</div>
                <p style="font-size: 0.78rem;">Technician has not submitted resolution proof.</p>
              </div>
            ` : `
              ${afterEvidence.map(item => this._renderEvidenceCard(item)).join('')}
            `}
          </div>
        </div>

        <!-- Additional Inspection Reports -->
        ${reports.length > 0 ? `
          <div class="card" style="margin-bottom: 1.25rem;">
            <div class="card-header">
              <div class="card-title">
                <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/><polyline points="14 2 14 8 20 8"/></svg>
                <span>3. Inspection Reports & Attachments (${reports.length})</span>
              </div>
            </div>
            <div style="display: grid; grid-template-columns: repeat(auto-fill, minmax(280px, 1fr)); gap: 0.85rem;">
              ${reports.map(item => this._renderEvidenceCard(item)).join('')}
            </div>
          </div>
        ` : ''}
      `;

      // Lightbox click handler
      this.container.querySelectorAll('.evidence-img-preview').forEach(el => {
        el.addEventListener('click', () => {
          const url = el.getAttribute('data-url');
          const cap = el.getAttribute('data-caption');
          modal.openLightbox(url, cap);
        });
      });

      // Hook Approve & Resolve Button
      const approveBtn = this.container.querySelector('#review-approve-btn');
      if (approveBtn && activeAssign) {
        approveBtn.addEventListener('click', async () => {
          if (!confirm(`Approve and mark Grievance #${refId} as RESOLVED?`)) {
            return;
          }

          approveBtn.disabled = true;
          approveBtn.textContent = 'Approving...';

          try {
            await operationsService.approveAssignment(activeAssign.id, 'Verified and approved via NMC Command');
            toast.success('Grievance approved and resolved successfully!');
            window.location.hash = '#verification';
          } catch (e) {
            toast.error(e.message || 'Approval failed');
            approveBtn.disabled = false;
            approveBtn.textContent = 'Approve & Resolve';
          }
        });
      }

      // Hook Request Rework Button
      const reworkBtn = this.container.querySelector('#review-rework-btn');
      if (reworkBtn && activeAssign) {
        reworkBtn.addEventListener('click', () => {
          modal.openRequestReworkModal(activeAssign.id, `#${refId}`, () => {
            window.location.hash = '#verification';
          });
        });
      }

    } catch (e) {
      this.container.innerHTML = `
        <div class="card" style="border-color: var(--danger); padding: 2rem; text-align: center;">
          <h3 style="color: var(--danger);">Error Loading Evidence</h3>
          <p style="color: var(--text-secondary); font-size: 0.8rem;">${e.message || 'Error'}</p>
          <a href="#verification" class="btn btn-primary btn-sm" style="margin-top: 1rem;">Back to Queue</a>
        </div>
      `;
    }
  }

  _renderEvidenceCard(item) {
    const isPass = item.is_geo_verified || (item.distance_meters !== null && item.distance_meters <= 150);
    const distText = item.distance_meters !== null && item.distance_meters !== undefined ? `${Math.round(item.distance_meters)}m` : 'Verified';
    const accText = item.accuracy_meters !== null && item.accuracy_meters !== undefined ? `±${Math.round(item.accuracy_meters)}m` : 'Accurate';

    return `
      <div style="margin-bottom: 0.85rem;">
        <div class="evidence-img-container">
          ${item.signedUrl ? `
            <img src="${item.signedUrl}" alt="Evidence" class="evidence-img-preview" data-url="${item.signedUrl}" data-caption="${item.evidence_type}">
          ` : `
            <span style="color: var(--text-muted); font-size: 0.8rem;">[Encrypted Protected Evidence]</span>
          `}
        </div>

        <div class="geo-verification-hud">
          <div class="geo-hud-item">
            <span class="geo-hud-label">GPS Verification</span>
            <span class="${isPass ? 'geo-status-pass' : 'geo-status-fail'}">
              ${isPass ? '✓ Geo Verified' : '⚠️ Distance Deviation'}
            </span>
          </div>
          <div class="geo-hud-item">
            <span class="geo-hud-label">Distance from Origin</span>
            <span class="geo-hud-val">${distText}</span>
          </div>
          <div class="geo-hud-item">
            <span class="geo-hud-label">GPS Accuracy</span>
            <span class="geo-hud-val">${accText}</span>
          </div>
        </div>

        ${item.notes ? `
          <div style="margin-top: 0.45rem; font-size: 0.75rem; color: var(--text-secondary); background: var(--bg-surface-subtle); padding: 0.35rem 0.55rem; border-radius: var(--radius-xs); border: 1px solid var(--border-subtle);">
            <strong>Notes:</strong> ${this._escape(item.notes)}
          </div>
        ` : ''}
      </div>
    `;
  }

  _escape(str) {
    const div = document.createElement('div');
    div.textContent = str;
    return div.innerHTML;
  }
}

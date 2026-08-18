/**
 * Smart Nagpur Admin Web — Complaint Workspace (2026 SaaS)
 * Structured 2-column operations workspace:
 * Left: Grievance info, location, photo evidence gallery, and audit timeline.
 * Right: Status, priority, assigned technician, quick actions, and review notes.
 */

import { adminService } from '../services/adminService.js';
import { COMPLAINT_STATUSES, SERVICE_TYPES, ASSIGNMENT_STATUSES } from '../config.js';
import { modal } from '../components/modal.js';
import { toast } from '../components/toast.js';

export class ComplaintDetailsPage {
  constructor(container, complaintId) {
    this.container = container;
    this.complaintId = complaintId;
  }

  async render() {
    this.container.innerHTML = `
      <div style="padding: 2rem 0;">
        <div class="skeleton skeleton-rect" style="height: 40px; margin-bottom: 1.25rem;"></div>
        <div class="skeleton skeleton-rect" style="height: 350px;"></div>
      </div>
    `;

    try {
      const complaint = await adminService.getComplaintDetails(this.complaintId);
      if (!complaint) {
        this.container.innerHTML = `
          <div class="card" style="text-align: center; padding: 3rem;">
            <h2>Grievance Not Found</h2>
            <p style="color: var(--text-secondary); margin: 0.5rem 0 1.5rem;">The requested record could not be loaded.</p>
            <a href="#complaints" class="btn btn-primary btn-sm">Back to Complaints</a>
          </div>
        `;
        return;
      }

      const statusInfo = COMPLAINT_STATUSES[complaint.status] || { label: complaint.status, badgeClass: 'badge-muted' };
      const serviceInfo = SERVICE_TYPES[complaint.service_type] || { label: complaint.service_type || 'Civic', icon: '📋' };
      const citizen = complaint.profiles || {};
      const activeAssign = complaint.activeAssignment;

      this.container.innerHTML = `
        <div class="page-header">
          <div class="page-title-group">
            <div style="display: flex; align-items: center; gap: 0.65rem;">
              <a href="#complaints" class="btn btn-secondary btn-sm" style="padding: 0.25rem 0.5rem;">
                <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="m15 18-6-6 6-6"/></svg>
              </a>
              <h1>Grievance #${complaint.reference_number || complaint.id.substring(0, 8)}</h1>
              <span class="badge ${statusInfo.badgeClass}">${statusInfo.label}</span>
            </div>
            <p style="margin-top: 0.2rem;">Submitted on ${new Date(complaint.created_at).toLocaleString('en-IN', { dateStyle: 'full', timeStyle: 'short' })}</p>
          </div>

          <div class="page-actions">
            ${['submitted', 'under_review', 'underReview', 'rework_required', 'reworkRequired'].includes(complaint.status) ? `
              <button class="btn btn-primary btn-sm" id="detail-assign-btn">
                <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><line x1="19" x2="19" y1="8" y2="14"/><line x1="22" x2="16" y1="11" y2="11"/></svg>
                <span>Assign Staff</span>
              </button>
            ` : ''}
            ${activeAssign && activeAssign.status === 'completed' ? `
              <a href="#evidence/${complaint.id}" class="btn btn-warning btn-sm">
                <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10"/><path d="m9 12 2 2 4-4"/></svg>
                <span>Verify Evidence</span>
              </a>
            ` : ''}
          </div>
        </div>

        <div class="workspace-grid">
          <!-- Left Column: Details, Photos, Evidence, Timeline -->
          <div class="workspace-main">
            <!-- Issue Description & Location -->
            <div class="card">
              <div class="card-header">
                <div class="card-title">
                  <span>${serviceInfo.icon}</span>
                  <span>${serviceInfo.label}</span>
                </div>
              </div>
              <p style="font-size: 0.9rem; line-height: 1.6; color: var(--text-primary); margin-bottom: 1rem;">
                ${this._escape(complaint.issue_description || 'No detailed description provided.')}
              </p>

              <!-- Geolocation Box -->
              <div style="background-color: var(--bg-surface-subtle); border: 1px solid var(--border-subtle); border-radius: var(--radius-sm); padding: 0.75rem; margin-bottom: 1rem;">
                <div style="font-weight: 600; font-size: 0.75rem; color: var(--text-muted); text-transform: uppercase; margin-bottom: 0.2rem;">
                  Incident Location
                </div>
                <div style="color: var(--text-primary); font-size: 0.85rem; margin-bottom: 0.35rem;">
                  📍 ${this._escape(complaint.address_text || 'Address not specified')}
                </div>
                ${complaint.latitude && complaint.longitude ? `
                  <div style="font-size: 0.75rem; color: #60A5FA; display: flex; align-items: center; gap: 0.85rem;">
                    <span>Lat: <strong>${complaint.latitude.toFixed(6)}</strong></span>
                    <span>Lng: <strong>${complaint.longitude.toFixed(6)}</strong></span>
                    <a href="https://www.google.com/maps?q=${complaint.latitude},${complaint.longitude}" target="_blank" class="btn btn-secondary btn-sm" style="padding: 0.15rem 0.45rem; font-size: 0.7rem;">
                      Open in Maps ↗
                    </a>
                  </div>
                ` : ''}
              </div>

              <!-- Citizen Uploaded Photos -->
              <div>
                <div style="font-weight: 600; font-size: 0.75rem; color: var(--text-muted); text-transform: uppercase; margin-bottom: 0.5rem;">
                  Photographic Evidence (${complaint.photos?.length || 0})
                </div>
                ${!complaint.photos || complaint.photos.length === 0 ? `
                  <p style="font-size: 0.78rem; color: var(--text-muted);">No photos attached to this report.</p>
                ` : `
                  <div style="display: grid; grid-template-columns: repeat(auto-fill, minmax(130px, 1fr)); gap: 0.65rem;">
                    ${complaint.photos.map((p, idx) => `
                      <div style="height: 100px; background: #060910; border-radius: var(--radius-sm); overflow: hidden; border: 1px solid var(--border-subtle); cursor: zoom-in;" class="citizen-photo-thumbnail" data-url="${p.url}" data-name="Photo ${idx + 1}">
                        <img src="${p.url}" alt="Photo ${idx + 1}" style="width: 100%; height: 100%; object-fit: cover;">
                      </div>
                    `).join('')}
                  </div>
                `}
              </div>
            </div>

            <!-- Milestone Progress Timeline -->
            <div class="card">
              <div class="card-header">
                <div class="card-title">
                  <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"/><polyline points="12 6 12 12 16 14"/></svg>
                  <span>Lifecycle Timeline</span>
                </div>
              </div>
              <div class="timeline">
                ${complaint.timeline && complaint.timeline.length > 0 ? complaint.timeline.map(t => `
                  <div class="timeline-item">
                    <div class="timeline-dot ${t.is_completed ? 'completed' : ''}"></div>
                    <div class="timeline-content">
                      <div class="timeline-title">${this._escape(t.title)}</div>
                      ${t.message ? `<div class="timeline-msg">${this._escape(t.message)}</div>` : ''}
                      <div class="timeline-date">${new Date(t.occurred_at || t.created_at).toLocaleString('en-IN', { dateStyle: 'medium', timeStyle: 'short' })}</div>
                    </div>
                  </div>
                `).join('') : `
                  <div class="timeline-item">
                    <div class="timeline-dot completed"></div>
                    <div class="timeline-content">
                      <div class="timeline-title">Grievance Submitted</div>
                      <div class="timeline-msg">Received via civic mobile app.</div>
                      <div class="timeline-date">${new Date(complaint.created_at).toLocaleString('en-IN', { dateStyle: 'medium', timeStyle: 'short' })}</div>
                    </div>
                  </div>
                `}
              </div>
            </div>
          </div>

          <!-- Right Column: Status, Citizen Info & Assignment Controls -->
          <div class="workspace-sidebar">
            <!-- Active Field Assignment -->
            <div class="card">
              <div class="card-header">
                <div class="card-title">
                  <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/></svg>
                  <span>Field Technician</span>
                </div>
              </div>
              ${!activeAssign ? `
                <div style="text-align: center; padding: 1rem 0;">
                  <p style="font-size: 0.78rem; color: var(--text-muted); margin-bottom: 0.65rem;">No technician assigned.</p>
                  <button class="btn btn-primary btn-sm" id="assign-card-btn">Dispatch Order</button>
                </div>
              ` : `
                <div style="display: flex; flex-direction: column; gap: 0.65rem; font-size: 0.8rem;">
                  <div>
                    <span style="color: var(--text-muted); font-size: 0.7rem; display: block;">Assigned Staff</span>
                    <strong style="color: var(--text-primary); font-size: 0.9rem;">${activeAssign.staff_profiles?.name || 'Technician'}</strong>
                    <span style="font-size: 0.72rem; color: var(--text-secondary); display: block;">
                      ${activeAssign.staff_profiles?.employee_id || ''} • ${activeAssign.staff_profiles?.phone || ''}
                    </span>
                  </div>
                  <div>
                    <span style="color: var(--text-muted); font-size: 0.7rem; display: block;">Dispatch Status</span>
                    <span class="badge ${ASSIGNMENT_STATUSES[activeAssign.status]?.badgeClass || 'badge-muted'}">
                      ${ASSIGNMENT_STATUSES[activeAssign.status]?.label || activeAssign.status}
                    </span>
                  </div>
                  ${activeAssign.instructions ? `
                    <div>
                      <span style="color: var(--text-muted); font-size: 0.7rem; display: block;">Instructions</span>
                      <p style="font-size: 0.78rem; color: var(--text-secondary); background: var(--bg-surface-subtle); padding: 0.4rem 0.55rem; border-radius: var(--radius-xs); border: 1px solid var(--border-subtle);">
                        ${this._escape(activeAssign.instructions)}
                      </p>
                    </div>
                  ` : ''}
                  ${activeAssign.status === 'completed' ? `
                    <a href="#evidence/${complaint.id}" class="btn btn-warning btn-sm" style="margin-top: 0.4rem; font-weight: 600;">
                      Inspect Evidence →
                    </a>
                  ` : ''}
                </div>
              `}
            </div>

            <!-- Citizen Profile Card -->
            <div class="card">
              <div class="card-header">
                <div class="card-title">
                  <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="8" r="5"/><path d="M20 21a8 8 0 0 0-16 0"/></svg>
                  <span>Citizen Details</span>
                </div>
              </div>
              <div style="display: flex; flex-direction: column; gap: 0.5rem; font-size: 0.8rem;">
                <div>
                  <span style="color: var(--text-muted); font-size: 0.7rem; display: block;">Name</span>
                  <strong style="color: var(--text-primary);">${citizen.name || 'Anonymous Citizen'}</strong>
                </div>
                <div>
                  <span style="color: var(--text-muted); font-size: 0.7rem; display: block;">Phone</span>
                  <span style="color: var(--text-primary); font-family: monospace;">${citizen.phone || '—'}</span>
                </div>
                <div>
                  <span style="color: var(--text-muted); font-size: 0.7rem; display: block;">Email</span>
                  <span style="color: var(--text-secondary);">${citizen.email || '—'}</span>
                </div>
              </div>
            </div>

            <!-- Administrative Notes -->
            <div class="card">
              <div class="card-header">
                <div class="card-title">
                  <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 20h9"/><path d="M16.5 3.5a2.12 2.12 0 0 1 3 3L7 19l-4 1 1-4Z"/></svg>
                  <span>Internal Notes</span>
                </div>
              </div>
              <div class="form-group">
                <textarea class="form-control" id="complaint-review-notes" rows="3" placeholder="Add administrative observations...">${complaint.review?.comments || ''}</textarea>
              </div>
              <button class="btn btn-secondary btn-sm" id="save-review-btn" style="width: 100%;">
                Save Notes
              </button>
            </div>
          </div>
        </div>
      `;

      // Hook Lightbox clicks
      this.container.querySelectorAll('.citizen-photo-thumbnail').forEach(el => {
        el.addEventListener('click', () => {
          const url = el.getAttribute('data-url');
          const name = el.getAttribute('data-name');
          modal.openLightbox(url, name);
        });
      });

      // Hook Assign button
      const assignBtn = this.container.querySelector('#detail-assign-btn');
      const assignCardBtn = this.container.querySelector('#assign-card-btn');
      const handleAssign = () => modal.openAssignComplaintModal(complaint, () => this.render());

      if (assignBtn) assignBtn.addEventListener('click', handleAssign);
      if (assignCardBtn) assignCardBtn.addEventListener('click', handleAssign);

      // Hook Save Review
      const saveReviewBtn = this.container.querySelector('#save-review-btn');
      if (saveReviewBtn) {
        saveReviewBtn.addEventListener('click', async () => {
          const comments = this.container.querySelector('#complaint-review-notes').value;
          saveReviewBtn.disabled = true;
          saveReviewBtn.textContent = 'Saving...';
          try {
            await adminService.submitReview(complaint.id, complaint.status, comments);
            toast.success('Review notes saved');
          } catch (e) {
            toast.error(e.message || 'Failed to save review');
          } finally {
            saveReviewBtn.disabled = false;
            saveReviewBtn.textContent = 'Save Notes';
          }
        });
      }

    } catch (e) {
      this.container.innerHTML = `
        <div class="card" style="border-color: var(--danger); padding: 2rem; text-align: center;">
          <h3 style="color: var(--danger);">Error Loading Grievance</h3>
          <p style="color: var(--text-secondary); font-size: 0.8rem;">${e.message || 'Database error.'}</p>
          <a href="#complaints" class="btn btn-primary btn-sm" style="margin-top: 1rem;">Back to Complaints</a>
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

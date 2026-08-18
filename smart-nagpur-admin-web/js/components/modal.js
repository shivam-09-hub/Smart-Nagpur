/**
 * Smart Nagpur Admin Web — Modal Controller (2026 SaaS)
 * Modern glassmorphism dialogs for task assignments, rework orders, staff provisioning, and evidence lightbox.
 */

import { DEPARTMENTS, PRIORITIES, STAFF_ROLES } from '../config.js';
import { staffService } from '../services/staffService.js';
import { operationsService } from '../services/operationsService.js';
import { toast } from './toast.js';

class ModalController {
  constructor() {
    this.activeBackdrop = null;
    this.onCloseCallback = null;
  }

  open({ title, bodyHtml, footerHtml = '', onOpen = null, onClose = null }) {
    this.close();

    const backdrop = document.createElement('div');
    backdrop.className = 'modal-backdrop';

    backdrop.innerHTML = `
      <div class="modal-content" role="dialog" aria-modal="true">
        <div class="modal-header">
          <h3 class="modal-title">${title}</h3>
          <button class="btn-icon modal-close-btn" title="Close">
            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M18 6 6 18"/><path d="m6 6 12 12"/></svg>
          </button>
        </div>
        <div class="modal-body">
          ${bodyHtml}
        </div>
        ${footerHtml ? `<div class="modal-footer">${footerHtml}</div>` : ''}
      </div>
    `;

    document.body.appendChild(backdrop);
    this.activeBackdrop = backdrop;
    this.onCloseCallback = onClose;

    requestAnimationFrame(() => {
      backdrop.classList.add('active');
    });

    const closeBtn = backdrop.querySelector('.modal-close-btn');
    if (closeBtn) {
      closeBtn.addEventListener('click', () => this.close());
    }

    backdrop.addEventListener('click', (e) => {
      if (e.target === backdrop) {
        this.close();
      }
    });

    document.addEventListener('keydown', this._handleEscape);

    if (typeof onOpen === 'function') {
      onOpen(backdrop);
    }
  }

  _handleEscape = (e) => {
    if (e.key === 'Escape') {
      this.close();
    }
  };

  close() {
    if (this.activeBackdrop) {
      this.activeBackdrop.classList.remove('active');
      const backdrop = this.activeBackdrop;
      setTimeout(() => backdrop.remove(), 180);
      this.activeBackdrop = null;
      document.removeEventListener('keydown', this._handleEscape);

      if (typeof this.onCloseCallback === 'function') {
        this.onCloseCallback();
        this.onCloseCallback = null;
      }
    }
  }

  /**
   * Open Assign Complaint Modal
   */
  async openAssignComplaintModal(complaint, onSuccess) {
    let staffMembers = [];
    try {
      staffMembers = await staffService.getStaffMembers({ isActive: true });
    } catch (e) {
      toast.error('Failed to load staff list');
    }

    const deptCode = complaint.service_type ? DEPARTMENTS[complaint.service_type]?.code || 'generalAdministration' : 'generalAdministration';

    const bodyHtml = `
      <form id="assign-complaint-form">
        <div class="form-group">
          <label class="form-label">Complaint Reference</label>
          <input type="text" class="form-control" value="${complaint.public_id || complaint.reference_number || complaint.id}" readonly disabled style="font-family: monospace; font-weight: 600; color: #60A5FA;">
        </div>
        <div class="form-group">
          <label class="form-label">Issue Summary</label>
          <p style="font-size: 0.8rem; color: var(--text-secondary); background: var(--bg-surface-subtle); padding: 0.5rem 0.65rem; border-radius: var(--radius-sm); border: 1px solid var(--border-subtle);">${complaint.description || complaint.issue || complaint.issue_description || 'No description'}</p>
        </div>
        <div class="form-group">
          <label class="form-label">Select Field Technician *</label>
          <select class="form-control" id="assign-staff-select" required>
            <option value="">-- Choose on-duty or available technician --</option>
            ${staffMembers.map(s => `
              <option value="${s.id}" ${s.department === deptCode ? 'selected' : ''}>
                ${s.name} (${s.employee_id}) — ${DEPARTMENTS[s.department]?.name || s.department} ${s.is_on_duty ? '🟢 [On Duty]' : '⚪ [Off Duty]'}
              </option>
            `).join('')}
          </select>
        </div>
        <div class="form-group">
          <label class="form-label">Priority Level *</label>
          <select class="form-control" id="assign-priority-select" required>
            <option value="low">Low (Standard SLA)</option>
            <option value="medium" selected>Medium (Standard Turnaround)</option>
            <option value="high">High (Accelerated SLA)</option>
            <option value="urgent">Urgent (Emergency Response)</option>
          </select>
        </div>
        <div class="form-group">
          <label class="form-label">Operational Instructions</label>
          <textarea class="form-control" id="assign-instructions" rows="2" placeholder="Special equipment, hazards, or citizen contact notes..."></textarea>
        </div>
      </form>
    `;

    const footerHtml = `
      <button type="button" class="btn btn-secondary modal-cancel-btn">Cancel</button>
      <button type="button" class="btn btn-primary" id="modal-submit-assign-btn">Dispatch Order</button>
    `;

    this.open({
      title: `Dispatch Task #${complaint.reference_number || ''}`,
      bodyHtml,
      footerHtml,
      onOpen: (backdrop) => {
        backdrop.querySelector('.modal-cancel-btn').addEventListener('click', () => this.close());
        
        const submitBtn = backdrop.querySelector('#modal-submit-assign-btn');
        submitBtn.addEventListener('click', async () => {
          const staffId = backdrop.querySelector('#assign-staff-select').value;
          const priority = backdrop.querySelector('#assign-priority-select').value;
          const instructions = backdrop.querySelector('#assign-instructions').value;

          if (!staffId) {
            toast.error('Please select a staff member');
            return;
          }

          submitBtn.disabled = true;
          submitBtn.textContent = 'Dispatching...';

          try {
            await operationsService.assignComplaint({
              complaintId: complaint.id,
              staffId,
              priority,
              instructions
            });

            toast.success('Work order dispatched successfully!');
            this.close();
            if (typeof onSuccess === 'function') onSuccess();
          } catch (err) {
            toast.error(err.message || 'Assignment failed');
            submitBtn.disabled = false;
            submitBtn.textContent = 'Dispatch Order';
          }
        });
      }
    });
  }

  /**
   * Open Request Rework Modal
   */
  openRequestReworkModal(assignmentId, complaintRef, onSuccess) {
    const bodyHtml = `
      <div class="form-group">
        <label class="form-label">Complaint Reference</label>
        <input type="text" class="form-control" value="${complaintRef}" readonly disabled style="font-family: monospace; font-weight: 600; color: #F87171;">
      </div>
      <div class="form-group">
        <label class="form-label">Rework Directives *</label>
        <textarea class="form-control" id="rework-instructions" rows="4" placeholder="Detail the deficiencies in the submitted evidence and provide clear instructions for on-ground correction..." required></textarea>
      </div>
    `;

    const footerHtml = `
      <button type="button" class="btn btn-secondary modal-cancel-btn">Cancel</button>
      <button type="button" class="btn btn-danger" id="modal-submit-rework-btn">Issue Rework Order</button>
    `;

    this.open({
      title: 'Issue Field Rework Directive',
      bodyHtml,
      footerHtml,
      onOpen: (backdrop) => {
        backdrop.querySelector('.modal-cancel-btn').addEventListener('click', () => this.close());

        const submitBtn = backdrop.querySelector('#modal-submit-rework-btn');
        submitBtn.addEventListener('click', async () => {
          const instructions = backdrop.querySelector('#rework-instructions').value;
          if (!instructions || !instructions.trim()) {
            toast.error('Rework instructions are required');
            return;
          }

          submitBtn.disabled = true;
          submitBtn.textContent = 'Sending...';

          try {
            await operationsService.requestRework(assignmentId, instructions.trim());
            toast.success('Rework directive sent to technician');
            this.close();
            if (typeof onSuccess === 'function') onSuccess();
          } catch (err) {
            toast.error(err.message || 'Failed to request rework');
            submitBtn.disabled = false;
            submitBtn.textContent = 'Issue Rework Order';
          }
        });
      }
    });
  }

  /**
   * Open Create Staff Member Modal
   */
  openCreateStaffModal(onSuccess) {
    const bodyHtml = `
      <form id="create-staff-form">
        <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 0.75rem;">
          <div class="form-group">
            <label class="form-label">Full Name *</label>
            <input type="text" class="form-control" id="new-staff-name" placeholder="Ramesh Deshmukh" required>
          </div>
          <div class="form-group">
            <label class="form-label">Employee ID *</label>
            <input type="text" class="form-control" id="new-staff-emp-id" placeholder="NMC-SW-1042" required style="font-family: monospace;">
          </div>
        </div>

        <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 0.75rem;">
          <div class="form-group">
            <label class="form-label">Department *</label>
            <select class="form-control" id="new-staff-dept" required>
              ${Object.values(DEPARTMENTS).map(d => `
                <option value="${d.code}">${d.name}</option>
              `).join('')}
            </select>
          </div>
          <div class="form-group">
            <label class="form-label">Role *</label>
            <select class="form-control" id="new-staff-role" required>
              ${Object.entries(STAFF_ROLES).map(([code, r]) => `
                <option value="${code}">${r.label}</option>
              `).join('')}
            </select>
          </div>
        </div>

        <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 0.75rem;">
          <div class="form-group">
            <label class="form-label">Email Address *</label>
            <input type="email" class="form-control" id="new-staff-email" placeholder="ramesh@nagpur.gov.in" required>
          </div>
          <div class="form-group">
            <label class="form-label">Mobile Phone</label>
            <input type="tel" class="form-control" id="new-staff-phone" placeholder="+91 98765 43210">
          </div>
        </div>

        <div class="form-group">
          <label class="form-label">Initial Access Password</label>
          <input type="text" class="form-control" id="new-staff-password" value="StaffPassword123!" required style="font-family: monospace;">
          <span style="font-size: 0.68rem; color: var(--text-muted);">Staff member will authenticate with this password on NMC FieldForce app.</span>
        </div>
      </form>
    `;

    const footerHtml = `
      <button type="button" class="btn btn-secondary modal-cancel-btn">Cancel</button>
      <button type="button" class="btn btn-primary" id="modal-submit-staff-btn">Provision Account</button>
    `;

    this.open({
      title: 'Provision Field Technician Account',
      bodyHtml,
      footerHtml,
      onOpen: (backdrop) => {
        backdrop.querySelector('.modal-cancel-btn').addEventListener('click', () => this.close());

        const submitBtn = backdrop.querySelector('#modal-submit-staff-btn');
        submitBtn.addEventListener('click', async () => {
          const name = backdrop.querySelector('#new-staff-name').value;
          const employeeId = backdrop.querySelector('#new-staff-emp-id').value;
          const department = backdrop.querySelector('#new-staff-dept').value;
          const role = backdrop.querySelector('#new-staff-role').value;
          const email = backdrop.querySelector('#new-staff-email').value;
          const phone = backdrop.querySelector('#new-staff-phone').value;
          const password = backdrop.querySelector('#new-staff-password').value;

          if (!name || !employeeId || !email) {
            toast.error('Name, Employee ID, and Email are required');
            return;
          }

          submitBtn.disabled = true;
          submitBtn.textContent = 'Provisioning...';

          try {
            await staffService.createStaff({
              name,
              employeeId,
              department,
              role,
              email,
              phone,
              password
            });

            toast.success(`Account provisioned for ${name} (${employeeId})`);
            this.close();
            if (typeof onSuccess === 'function') onSuccess();
          } catch (err) {
            toast.error(err.message || 'Failed to create staff account');
            submitBtn.disabled = false;
            submitBtn.textContent = 'Provision Account';
          }
        });
      }
    });
  }

  /**
   * Open Image Lightbox Viewer
   */
  openLightbox(imageUrl, caption = '') {
    this.open({
      title: caption || 'Evidence Inspection',
      bodyHtml: `
        <div style="display: flex; justify-content: center; align-items: center; min-height: 420px; background: #05080E; border-radius: var(--radius-sm); overflow: hidden; border: 1px solid var(--border-subtle);">
          <img src="${imageUrl}" alt="${caption}" style="max-width: 100%; max-height: 72vh; object-fit: contain;">
        </div>
      `,
      footerHtml: `
        <a href="${imageUrl}" target="_blank" download class="btn btn-secondary">Open Full Image ↗</a>
        <button type="button" class="btn btn-primary modal-close-btn">Done</button>
      `
    });
  }
}

export const modal = new ModalController();

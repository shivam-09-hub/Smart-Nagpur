/**
 * Smart Nagpur Admin Web — Router
 * Hash-based single page application routing with dynamic route parameters.
 */

import { DashboardPage } from './pages/dashboard.js';
import { ComplaintsPage } from './pages/complaints.js';
import { ComplaintDetailsPage } from './pages/complaintDetails.js';
import { AssignmentsPage } from './pages/assignments.js';
import { VerificationPage } from './pages/verification.js';
import { EvidenceReviewPage } from './pages/evidenceReview.js';
import { StaffPage } from './pages/staff.js';
import { StaffWorkloadPage } from './pages/staffWorkload.js';
import { DepartmentsPage } from './pages/departments.js';
import { VendorsPage } from './pages/vendors.js';
import { AnalyticsPage } from './pages/analytics.js';
import { SettingsPage } from './pages/settings.js';

class Router {
  constructor(mountElement) {
    this.mount = typeof mountElement === 'string' ? document.querySelector(mountElement) : mountElement;
    this.currentRoute = '';
    this.currentPageInstance = null;
    this.onRouteChange = null;
  }

  init(onRouteChange = null) {
    this.onRouteChange = onRouteChange;
    window.addEventListener('hashchange', () => this.handleRoute());
    this.handleRoute();
  }

  async handleRoute() {
    const rawHash = window.location.hash.slice(1) || 'dashboard';
    const parts = rawHash.split('/');
    const route = parts[0];
    const param = parts[1] || null;

    this.currentRoute = rawHash;

    if (typeof this.onRouteChange === 'function') {
      this.onRouteChange(route, param);
    }

    switch (route) {
      case 'dashboard':
        this.currentPageInstance = new DashboardPage(this.mount);
        break;
      case 'complaints':
        this.currentPageInstance = new ComplaintsPage(this.mount);
        break;
      case 'complaint-details':
        this.currentPageInstance = new ComplaintDetailsPage(this.mount, param);
        break;
      case 'assignments':
        this.currentPageInstance = new AssignmentsPage(this.mount);
        break;
      case 'verification':
        this.currentPageInstance = new VerificationPage(this.mount);
        break;
      case 'evidence':
        this.currentPageInstance = new EvidenceReviewPage(this.mount, param);
        break;
      case 'staff':
        this.currentPageInstance = new StaffPage(this.mount);
        break;
      case 'staff-workload':
        this.currentPageInstance = new StaffWorkloadPage(this.mount);
        break;
      case 'departments':
        this.currentPageInstance = new DepartmentsPage(this.mount);
        break;
      case 'vendors':
        this.currentPageInstance = new VendorsPage(this.mount);
        break;
      case 'analytics':
        this.currentPageInstance = new AnalyticsPage(this.mount);
        break;
      case 'settings':
        this.currentPageInstance = new SettingsPage(this.mount);
        break;
      default:
        window.location.hash = '#dashboard';
        return;
    }

    if (this.currentPageInstance) {
      await this.currentPageInstance.render();
    }
  }

  getCurrentRoute() {
    return this.currentRoute;
  }

  refresh() {
    if (this.currentPageInstance && typeof this.currentPageInstance.render === 'function') {
      this.currentPageInstance.render();
    }
  }
}

export const router = new Router('#page-content-mount');

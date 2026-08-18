/**
 * Smart Nagpur Admin Web — Main Application Orchestrator (2026 SaaS)
 * Bootstraps authentication, collapsible sidebar, header with breadcrumbs, command search (⌘K), and realtime sync.
 */

import { auth } from './auth.js';
import { router } from './router.js';
import { renderSidebar } from './components/sidebar.js';
import { renderHeader } from './components/header.js';
import { operationsService } from './services/operationsService.js';
import { adminService } from './services/adminService.js';
import { toast } from './components/toast.js';

class App {
  constructor() {
    this.sidebarContainer = document.querySelector('#sidebar-mount');
    this.headerContainer = document.querySelector('#header-mount');
    this.verificationCount = 0;
    this.isSidebarCollapsed = localStorage.getItem('nmc_sidebar_collapsed') === 'true';
  }

  async init() {
    // 1. Guard route: require active administrator authentication
    const admin = await auth.requireAuth();
    if (!admin) return;

    // Apply sidebar collapsed preference
    if (this.isSidebarCollapsed && this.sidebarContainer) {
      this.sidebarContainer.classList.add('collapsed');
    }

    // 2. Fetch initial verification count
    await this.updateVerificationBadge();

    // 3. Render Header with initial route
    this.renderHeaderView('dashboard');

    // 4. Initialize Router with views update callback
    router.init((route, param) => {
      this.renderSidebarView(route);
      this.renderHeaderView(route, param);
    });

    // 5. Global Keyboard Shortcuts (⌘K / Ctrl+K for search)
    document.addEventListener('keydown', (e) => {
      if ((e.metaKey || e.ctrlKey) && e.key === 'k') {
        e.preventDefault();
        const searchInput = document.querySelector('#global-search-input');
        if (searchInput) {
          searchInput.focus();
          searchInput.select();
        }
      }
    });

    // 6. Connect Realtime live updates
    adminService.subscribeToLiveUpdates((table) => {
      this.updateVerificationBadge();
      router.refresh();
    });
  }

  renderSidebarView(currentRoute) {
    if (this.sidebarContainer) {
      this.sidebarContainer.innerHTML = renderSidebar(currentRoute, this.verificationCount);
      this._bindSidebarEvents();
    }
  }

  renderHeaderView(currentRoute, param = null) {
    if (this.headerContainer) {
      this.headerContainer.innerHTML = renderHeader(currentRoute, param);
      this._bindHeaderEvents();
    }
  }

  async updateVerificationBadge() {
    try {
      const queue = await operationsService.getVerificationQueue();
      this.verificationCount = queue?.length || 0;
      this.renderSidebarView(router.getCurrentRoute() || 'dashboard');
    } catch (_) {}
  }

  _bindSidebarEvents() {
    const logoutBtn = this.sidebarContainer.querySelector('#sidebar-logout-btn');
    if (logoutBtn) {
      logoutBtn.addEventListener('click', () => {
        if (confirm('Sign out from NMC Command?')) {
          auth.logout();
        }
      });
    }

    const toggleBtn = this.sidebarContainer.querySelector('#sidebar-collapse-toggle');
    if (toggleBtn) {
      toggleBtn.addEventListener('click', () => {
        this.isSidebarCollapsed = !this.isSidebarCollapsed;
        this.sidebarContainer.classList.toggle('collapsed', this.isSidebarCollapsed);
        localStorage.setItem('nmc_sidebar_collapsed', this.isSidebarCollapsed);
      });
    }
  }

  _bindHeaderEvents() {
    const refreshBtn = this.headerContainer.querySelector('#header-quick-refresh-btn');
    if (refreshBtn) {
      refreshBtn.addEventListener('click', () => {
        this.updateVerificationBadge();
        router.refresh();
        toast.info('Telemetry Refreshed');
      });
    }

    const logoutBtn = this.headerContainer.querySelector('#header-logout-btn');
    if (logoutBtn) {
      logoutBtn.addEventListener('click', () => {
        if (confirm('Sign out from NMC Command?')) {
          auth.logout();
        }
      });
    }

    const searchInput = this.headerContainer.querySelector('#global-search-input');
    if (searchInput) {
      searchInput.addEventListener('keydown', (e) => {
        if (e.key === 'Enter' && searchInput.value.trim()) {
          window.location.hash = `#complaints`;
        }
      });
    }
  }
}

document.addEventListener('DOMContentLoaded', () => {
  const app = new App();
  app.init();
});

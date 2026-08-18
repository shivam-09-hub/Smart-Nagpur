/**
 * Smart Nagpur Admin Web — Reusable High-Density SaaS Data Table (2026)
 * Handles sticky headers, skeleton placeholders, compact rows, and pagination.
 */

export class DataTable {
  constructor({
    container,
    columns = [],
    data = [],
    totalCount = 0,
    page = 1,
    pageSize = 15,
    isLoading = false,
    onPageChange = null,
    onSort = null,
    emptyMessage = 'No records found.'
  }) {
    this.container = typeof container === 'string' ? document.querySelector(container) : container;
    this.columns = columns;
    this.data = data;
    this.totalCount = totalCount;
    this.page = page;
    this.pageSize = pageSize;
    this.isLoading = isLoading;
    this.onPageChange = onPageChange;
    this.onSort = onSort;
    this.emptyMessage = emptyMessage;
  }

  renderSkeleton() {
    if (!this.container) return;
    this.container.innerHTML = `
      <div class="table-responsive">
        <table class="data-table">
          <thead>
            <tr>
              ${this.columns.map(col => `<th style="${col.width ? `width: ${col.width};` : ''}">${col.label}</th>`).join('')}
            </tr>
          </thead>
          <tbody>
            ${Array.from({ length: 6 }).map(() => `
              <tr>
                ${this.columns.map(() => `
                  <td><div class="skeleton skeleton-text" style="width: ${Math.floor(Math.random() * 40 + 50)}%;"></div></td>
                `).join('')}
              </tr>
            `).join('')}
          </tbody>
        </table>
      </div>
    `;
  }

  render() {
    if (!this.container) return;

    if (this.isLoading) {
      this.renderSkeleton();
      return;
    }

    if (!this.data || this.data.length === 0) {
      this.container.innerHTML = `
        <div class="empty-state">
          <div class="empty-state-icon">📋</div>
          <div class="empty-state-title">${this.emptyMessage}</div>
          <p style="font-size: 0.78rem; color: var(--text-muted);">Adjust your search or filter parameters to view records.</p>
        </div>
      `;
      return;
    }

    const startItem = (this.page - 1) * this.pageSize + 1;
    const endItem = Math.min(this.page * this.pageSize, this.totalCount || this.data.length);
    const totalPages = Math.ceil((this.totalCount || this.data.length) / this.pageSize);

    const tableHtml = `
      <div class="table-responsive">
        <table class="data-table">
          <thead>
            <tr>
              ${this.columns.map(col => `
                <th style="${col.width ? `width: ${col.width};` : ''}">
                  ${col.label}
                </th>
              `).join('')}
            </tr>
          </thead>
          <tbody>
            ${this.data.map(row => `
              <tr>
                ${this.columns.map(col => `
                  <td>
                    ${typeof col.render === 'function' ? col.render(row) : (row[col.key] ?? '—')}
                  </td>
                `).join('')}
              </tr>
            `).join('')}
          </tbody>
        </table>
      </div>
      <div class="table-pagination">
        <div>
          Showing <strong>${startItem}</strong>–<strong>${endItem}</strong> of <strong>${this.totalCount || this.data.length}</strong> records
        </div>
        <div class="pagination-controls">
          <button class="btn btn-secondary btn-sm prev-page-btn" ${this.page <= 1 ? 'disabled' : ''}>Previous</button>
          <span style="padding: 0 0.5rem; font-weight: 600; font-size: 0.75rem;">Page ${this.page} of ${totalPages || 1}</span>
          <button class="btn btn-secondary btn-sm next-page-btn" ${this.page >= totalPages ? 'disabled' : ''}>Next</button>
        </div>
      </div>
    `;

    this.container.innerHTML = tableHtml;

    const prevBtn = this.container.querySelector('.prev-page-btn');
    const nextBtn = this.container.querySelector('.next-page-btn');

    if (prevBtn && this.onPageChange) {
      prevBtn.addEventListener('click', () => {
        if (this.page > 1) this.onPageChange(this.page - 1);
      });
    }

    if (nextBtn && this.onPageChange) {
      nextBtn.addEventListener('click', () => {
        if (this.page < totalPages) this.onPageChange(this.page + 1);
      });
    }
  }
}

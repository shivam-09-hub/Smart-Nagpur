/**
 * Smart Nagpur Admin Web — SVG Chart Visualizations (2026 SaaS)
 * High-performance, responsive, pure SVG Area/Line, Bar, and Donut visualizations.
 */

export class ChartRenderer {
  /**
   * Render a sleek SVG Area / Line Chart for time-series trends
   */
  static renderAreaChart({ data = [], height = 180, lineColor = '#3B82F6', areaGradient = true }) {
    if (!data || data.length === 0) {
      return '<div class="empty-state" style="padding: 2rem 0;"><div class="empty-state-title">No Trend Data Available</div></div>';
    }

    const width = 600;
    const padding = { top: 20, right: 20, bottom: 30, left: 35 };
    const chartW = width - padding.left - padding.right;
    const chartH = height - padding.top - padding.bottom;

    const values = data.map(d => d.value || 0);
    const maxVal = Math.max(...values, 5);
    const minVal = 0;

    const getX = (idx) => padding.left + (idx / (data.length - 1 || 1)) * chartW;
    const getY = (val) => padding.top + chartH - ((val - minVal) / (maxVal - minVal)) * chartH;

    // Generate Path Points
    const points = data.map((d, i) => `${getX(i)},${getY(d.value || 0)}`);
    const linePath = `M ${points.join(' L ')}`;
    const areaPath = `M ${padding.left},${padding.top + chartH} L ${points.join(' L ')} L ${getX(data.length - 1)},${padding.top + chartH} Z`;

    // Horizontal Grid Lines
    const gridLines = [0, 0.5, 1].map(ratio => {
      const y = padding.top + chartH * (1 - ratio);
      const val = Math.round(minVal + (maxVal - minVal) * ratio);
      return `
        <line x1="${padding.left}" y1="${y}" x2="${width - padding.right}" y2="${y}" stroke="rgba(255, 255, 255, 0.05)" stroke-dasharray="3 3"/>
        <text x="${padding.left - 8}" y="${y + 3}" fill="#64748B" font-size="10" text-anchor="end" font-family="monospace">${val}</text>
      `;
    }).join('');

    // X-Axis Labels
    const xLabels = [0, Math.floor(data.length / 2), data.length - 1].map(idx => {
      if (!data[idx]) return '';
      const x = getX(idx);
      return `<text x="${x}" y="${height - 8}" fill="#64748B" font-size="10" text-anchor="middle">${data[idx].label || ''}</text>`;
    }).join('');

    return `
      <div style="width: 100%; overflow: hidden;">
        <svg viewBox="0 0 ${width} ${height}" style="width: 100%; height: ${height}px; display: block;">
          <defs>
            <linearGradient id="areaGrad" x1="0" y1="0" x2="0" y2="1">
              <stop offset="0%" stop-color="${lineColor}" stop-opacity="0.25"/>
              <stop offset="100%" stop-color="${lineColor}" stop-opacity="0.0"/>
            </linearGradient>
          </defs>
          ${gridLines}
          <path d="${areaPath}" fill="url(#areaGrad)" />
          <path d="${linePath}" fill="none" stroke="${lineColor}" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" />
          ${data.map((d, i) => `
            <circle cx="${getX(i)}" cy="${getY(d.value || 0)}" r="3" fill="#080C14" stroke="${lineColor}" stroke-width="1.5" />
          `).join('')}
          ${xLabels}
        </svg>
      </div>
    `;
  }

  /**
   * Render clean horizontal progress bars with department badges
   */
  static renderBarChart({ data = [], colors = {} }) {
    if (!data || data.length === 0) {
      return '<div class="empty-state" style="padding: 2rem 0;"><div class="empty-state-title">No Distribution Data</div></div>';
    }

    const maxValue = Math.max(...data.map(d => d.value), 1);

    return `
      <div style="display: flex; flex-direction: column; gap: 0.75rem; width: 100%;">
        ${data.map(item => {
          const pct = Math.round((item.value / maxValue) * 100);
          const color = colors[item.key] || '#3B82F6';
          return `
            <div style="display: flex; flex-direction: column; gap: 0.2rem;">
              <div style="display: flex; justify-content: space-between; font-size: 0.75rem;">
                <span style="font-weight: 500; color: var(--text-primary); display: flex; align-items: center; gap: 0.35rem;">
                  ${item.icon || '🏛️'} ${item.label}
                </span>
                <span style="color: var(--text-secondary); font-weight: 600; font-feature-settings: 'tnum';">${item.value}</span>
              </div>
              <div style="height: 6px; width: 100%; background: #0A0F1A; border-radius: 999px; overflow: hidden; border: 1px solid var(--border-subtle);">
                <div style="height: 100%; width: ${pct}%; background-color: ${color}; border-radius: 999px; transition: width 0.4s cubic-bezier(0.16, 1, 0.3, 1);"></div>
              </div>
            </div>
          `;
        }).join('')}
      </div>
    `;
  }

  /**
   * Render a sleek SVG Donut Chart with legend
   */
  static renderDonutChart({ data = [], size = 150, strokeWidth = 18 }) {
    if (!data || data.length === 0) return '';

    const total = data.reduce((sum, d) => sum + (d.value || 0), 0);
    if (total === 0) {
      return '<div class="empty-state" style="padding: 2rem 0;"><div class="empty-state-title">No Active Records</div></div>';
    }

    const radius = (size - strokeWidth) / 2;
    const circumference = 2 * Math.PI * radius;
    let accumulatedAngle = 0;

    const circles = data.map(slice => {
      const sliceRatio = (slice.value || 0) / total;
      const strokeDasharray = `${sliceRatio * circumference} ${circumference}`;
      const strokeDashoffset = -accumulatedAngle;
      accumulatedAngle += sliceRatio * circumference;

      return `
        <circle
          cx="${size / 2}"
          cy="${size / 2}"
          r="${radius}"
          fill="transparent"
          stroke="${slice.color || '#3B82F6'}"
          stroke-width="${strokeWidth}"
          stroke-dasharray="${strokeDasharray}"
          stroke-dashoffset="${strokeDashoffset}"
          stroke-linecap="butt"
          style="transition: stroke-dasharray 0.4s ease;"
        />
      `;
    }).join('');

    return `
      <div style="display: flex; align-items: center; gap: 1.5rem; justify-content: space-around; flex-wrap: wrap;">
        <div style="position: relative; width: ${size}px; height: ${size}px;">
          <svg width="${size}" height="${size}" viewBox="0 0 ${size} ${size}" style="transform: rotate(-90deg);">
            <circle cx="${size / 2}" cy="${size / 2}" r="${radius}" fill="transparent" stroke="rgba(255, 255, 255, 0.05)" stroke-width="${strokeWidth}" />
            ${circles}
          </svg>
          <div style="position: absolute; inset: 0; display: flex; flex-direction: column; align-items: center; justify-content: center;">
            <span style="font-size: 1.25rem; font-weight: 700; color: var(--text-primary); font-feature-settings: 'tnum';">${total}</span>
            <span style="font-size: 0.65rem; color: var(--text-muted); text-transform: uppercase;">Total</span>
          </div>
        </div>
        <div style="display: flex; flex-direction: column; gap: 0.35rem;">
          ${data.map(d => `
            <div style="display: flex; align-items: center; gap: 0.45rem; font-size: 0.75rem;">
              <span style="width: 7px; height: 7px; border-radius: 50%; background-color: ${d.color}; display: inline-block;"></span>
              <span style="color: var(--text-secondary);">${d.label}:</span>
              <strong style="color: var(--text-primary); margin-left: auto; font-feature-settings: 'tnum';">${d.value}</strong>
            </div>
          `).join('')}
        </div>
      </div>
    `;
  }
}

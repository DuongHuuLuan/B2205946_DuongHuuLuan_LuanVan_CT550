function escapeHtml(value) {
  return String(value ?? "")
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;")
    .replace(/'/g, "&#39;");
}

function buildTable(section) {
  const head = section.columns
    .map((column) => `<th>${escapeHtml(column)}</th>`)
    .join("");

  const rows = section.rows
    .map(
      (row) =>
        `<tr>${row.map((cell) => `<td>${escapeHtml(cell)}</td>`).join("")}</tr>`,
    )
    .join("");

  return `
    <section class="report-section">
      <h2>${escapeHtml(section.title)}</h2>
      <table>
        <thead>
          <tr>${head}</tr>
        </thead>
        <tbody>
          ${rows || '<tr><td colspan="8">Khong co du lieu</td></tr>'}
        </tbody>
      </table>
    </section>
  `;
}

function buildDocument(snapshot, title) {
  const sections = snapshot.sections
    .map((section) => buildTable(section))
    .join("");

  return `
    <!doctype html>
    <html lang="vi">
      <head>
        <meta charset="utf-8" />
        <title>${escapeHtml(title)}</title>
        <style>
          body {
            font-family: Arial, sans-serif;
            margin: 24px;
            color: #111827;
          }

          .report-header {
            margin-bottom: 24px;
          }

          .report-title {
            margin: 0 0 8px;
            font-size: 28px;
            font-weight: 800;
          }

          .report-meta {
            margin: 4px 0;
            color: #4b5563;
            font-size: 14px;
          }

          .report-section {
            margin-top: 24px;
            page-break-inside: avoid;
          }

          h2 {
            margin: 0 0 12px;
            font-size: 18px;
          }

          table {
            width: 100%;
            border-collapse: collapse;
            table-layout: fixed;
          }

          th,
          td {
            border: 1px solid #d1d5db;
            padding: 8px 10px;
            font-size: 13px;
            vertical-align: top;
            word-break: break-word;
          }

          th {
            background: #f3f4f6;
            text-align: left;
            font-weight: 700;
          }
        </style>
      </head>
      <body>
        <header class="report-header">
          <h1 class="report-title">${escapeHtml(snapshot.title)}</h1>
          <p class="report-meta">Scope: ${escapeHtml(snapshot.scopeLabel)}</p>
          <p class="report-meta">Khoang thoi gian: ${escapeHtml(snapshot.rangeLabel)}</p>
          <p class="report-meta">Bo loc: ${escapeHtml(snapshot.subtitle)}</p>
          <p class="report-meta">Nguon du lieu: ${escapeHtml(snapshot.dataSourceLabel)}</p>
          <p class="report-meta">Tao luc: ${escapeHtml(snapshot.generatedAt)}</p>
        </header>

        ${sections}
      </body>
    </html>
  `;
}

export function downloadFileBlob(blob, filename) {
  const url = URL.createObjectURL(blob);
  const anchor = document.createElement("a");
  anchor.href = url;
  anchor.download = filename;
  document.body.appendChild(anchor);
  anchor.click();
  anchor.remove();
  URL.revokeObjectURL(url);
}

export function downloadStatisticsExcel(snapshot, filename = "statistics.xls") {
  const content = buildDocument(snapshot, filename);
  const blob = new Blob(["\ufeff", content], {
    type: "application/vnd.ms-excel;charset=utf-8",
  });

  downloadFileBlob(blob, filename);
}

export function openStatisticsPdf(snapshot, filename = "statistics.pdf") {
  const printWindow = window.open("", "_blank", "noopener,noreferrer");
  if (!printWindow) {
    return false;
  }

  const content = buildDocument(snapshot, filename);
  printWindow.document.open();
  printWindow.document.write(content);
  printWindow.document.close();
  printWindow.focus();

  setTimeout(() => {
    printWindow.print();
  }, 250);

  printWindow.onafterprint = () => {
    printWindow.close();
  };

  return true;
}

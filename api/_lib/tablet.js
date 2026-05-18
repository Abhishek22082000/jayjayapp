// Shared validation + shape normalization for tablet documents.

function isIso(s) {
  return typeof s === 'string' && /^\d{4}-\d{2}-\d{2}/.test(s);
}

export function validateTablet(body) {
  const required = [
    'clientName',
    'tabletName',
    'manufacturer',
    'batchNumber',
    'quantity',
    'startDate',
    'endDate',
  ];
  for (const k of required) {
    if (body[k] === undefined || body[k] === null || body[k] === '') {
      return `Field "${k}" is required`;
    }
  }
  const qty = Number(body.quantity);
  if (!Number.isInteger(qty) || qty < 1) {
    return 'quantity must be an integer >= 1';
  }
  if (!isIso(body.startDate)) return 'startDate must be an ISO-8601 date';
  if (!isIso(body.endDate)) return 'endDate must be an ISO-8601 date';
  if (body.manufacturingDate && !isIso(body.manufacturingDate)) {
    return 'manufacturingDate must be an ISO-8601 date when provided';
  }
  const start = new Date(body.startDate);
  const end = new Date(body.endDate);
  if (end < start) return 'endDate must be on or after startDate';
  if (body.manufacturingDate) {
    const mfg = new Date(body.manufacturingDate);
    if (mfg > end) return 'manufacturingDate must be on or before endDate';
  }
  return null;
}

export function normalize(body) {
  return {
    clientName: String(body.clientName).trim(),
    tabletName: String(body.tabletName).trim(),
    manufacturer: String(body.manufacturer).trim(),
    batchNumber: String(body.batchNumber).trim(),
    quantity: Number(body.quantity),
    startDate: new Date(body.startDate).toISOString(),
    endDate: new Date(body.endDate).toISOString(),
    manufacturingDate: body.manufacturingDate
      ? new Date(body.manufacturingDate).toISOString()
      : null,
  };
}

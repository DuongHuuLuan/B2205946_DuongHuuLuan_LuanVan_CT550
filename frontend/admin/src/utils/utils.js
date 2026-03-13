const formatMoney = (number) => {
  try {
    return `${new Intl.NumberFormat("vi-VN").format(Number(number || 0))} VND`;
  } catch {
    return String(number || 0);
  }
};

const getProductThumb = (product) => {
  if (!product) return "";
  const images = product?.images || product?.product_images || [];
  const first = images?.[0]?.url || "";
  return first || "";
};

const normalizeEnumText = (value) => {
  const raw = String(value ?? "").trim();
  if (!raw) return "";

  const dotParts = raw.split(".");
  return dotParts[dotParts.length - 1].trim().toLowerCase();
};

const statusLabel = (status) => {
  const value = normalizeEnumText(status);
  if (value === "pending") return "Đang duyệt";
  if (value === "shipping") return "Đang giao";
  if (value === "completed") return "Hoàn thành";
  if (value === "cancelled") return "Đã hủy";
  return "-";
};

const statusBadgeClass = (status) => {
  const value = normalizeEnumText(status);
  if (value === "pending") return "badge-pending";
  if (value === "shipping") return "badge-shipping";
  if (value === "completed") return "badge-completed";
  if (value === "cancelled") return "badge-canceled";
  return "badge-secondary";
};

const statusTableBadgeClass = (status) => {
  switch (normalizeEnumText(status)) {
    case "pending":
      return "status-pending";
    case "shipping":
      return "status-shipping";
    case "completed":
      return "status-completed";
    case "cancelled":
      return "status-canceled";
    default:
      return "bg-secondary-subtle text-secondary";
  }
};

const paymentStatusLabel = (status) => {
  const value = normalizeEnumText(status);
  if (value === "paid") return "Đã thanh toán";
  if (value === "unpaid") return "Chưa thanh toán";
  return "Không rõ";
};

const paymentStatusBadgeClass = (status) => {
  const value = normalizeEnumText(status);
  if (value === "paid") return "payment-paid";
  if (value === "unpaid") return "payment-unpaid";
  return "bg-secondary-subtle text-secondary";
};

const refundSupportLabel = (status) => {
  const value = normalizeEnumText(status);
  if (value === "contact_required") return "Liên hệ chat để hoàn tiền";
  if (value === "resolved") return "Đã xử lý hoàn tiền";
  if (value === "none") return "Không yêu cầu";
  return "Không rõ";
};

const refundSupportBadgeClass = (status) => {
  const value = normalizeEnumText(status);
  if (value === "contact_required") return "refund-contact-required";
  if (value === "resolved") return "refund-resolved";
  if (value === "none") return "refund-none";
  return "bg-secondary-subtle text-secondary";
};

const formatDateTimeVN = (input) => {
  if (!input) return "-";

  const date = new Date(input);
  if (Number.isNaN(date.getTime())) return "-";

  const hh = String(date.getHours()).padStart(2, "0");
  const mm = String(date.getMinutes()).padStart(2, "0");
  const dd = String(date.getDate()).padStart(2, "0");
  const month = String(date.getMonth() + 1).padStart(2, "0");
  const yyyy = date.getFullYear();

  return `${hh}:${mm} ${dd}/${month}/${yyyy}`;
};

export {
  formatMoney,
  getProductThumb,
  normalizeEnumText,
  statusLabel,
  statusBadgeClass,
  formatDateTimeVN,
  statusTableBadgeClass,
  paymentStatusLabel,
  paymentStatusBadgeClass,
  refundSupportLabel,
  refundSupportBadgeClass,
};

const formatMoney = (number) => {
  try {
    return new Intl.NumberFormat("vi-VN").format(Number(number || 0)) + " ₫";
  } catch {
    return String(number || 0);
  }
};

// const getProductThumb = (product) => {
//   if (!product) return "";
//   const first = product?.images?.[0]?.url || "";
//   return first || "";
// };

const getProductThumb = (product) => {
  if (!product) return "";
  const images = product?.images || product?.product_images || [];
  const first = images?.[0]?.url || "";
  return first || "";
};

const statusLabel = (s) => {
  const v = String(s || "").toLowerCase();
  if (v === "pending") return "Đang duyệt";
  if (v === "shipping") return "Đang giao";
  if (v === "completed") return "Hoàn thành";
  if (v === "canceled" || v === "cancelled") return "Đã hủy";
  return "—";
};

const statusBadgeClass = (s) => {
  const v = String(s || "").toLowerCase();
  if (v === "pending") return "badge-pending";
  if (v === "shipping") return "badge-shipping";
  if (v === "completed") return "badge-completed";
  if (v === "canceled" || v === "cancelled") return "badge-canceled";
  return "badge-secondary";
};

const statusTableBadgeClass = (status) => {
  switch (status) {
    case "pending":
      return "status-pending";
    case "shipping":
      return "status-shipping";
    case "completed":
      return "status-completed";
    case "canceled":
    case "cancelled":
      return "status-canceled";
    default:
      return "bg-secondary-subtle text-secondary";
  }
};

const formatDateTimeVN = (input) => {
  if (!input) return "—";

  const d = new Date(input);
  if (Number.isNaN(d.getTime())) return "—";

  const hh = String(d.getHours()).padStart(2, "0");
  const mm = String(d.getMinutes()).padStart(2, "0");
  const dd = String(d.getDate()).padStart(2, "0");
  const MM = String(d.getMonth() + 1).padStart(2, "0");
  const yyyy = d.getFullYear();

  return `${hh}:${mm} ${dd}/${MM}/${yyyy}`;
};

export {
  formatMoney,
  getProductThumb,
  statusLabel,
  statusBadgeClass,
  formatDateTimeVN,
  statusTableBadgeClass,
};

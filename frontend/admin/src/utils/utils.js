const formatMoney = (number) => {
  try {
    return `${new Intl.NumberFormat("vi-VN").format(Number(number || 0))} VND`;
  } catch {
    return String(number || 0);
  }
};

const getImages = (product) => {
  return product?.images || product?.product_images || [];
};

const getImageKey = (image) =>
  String(image?.view_image_key ?? image?.viewImageKey ?? "").trim();

const pickPrimaryProductImage = (product, colorId = null) => {
  if (!product) return "";
  const images = getImages(product);
  const pickFrom = (list) => {
    if (!Array.isArray(list) || !list.length) return null;
    // const front = list.find((image) => getImageKey(image) === "front");
    const front = list.find((image) => getImageKey(image) === "front_left");
    if (front) return front;
    const generic = list.find((image) => !getImageKey(image));
    return generic || list[0] || null;
  };

  const hasColorFilter =
    colorId !== null && colorId !== undefined && colorId !== "";
  if (hasColorFilter) {
    const byColor = images.filter(
      (image) =>
        String(image?.color_id ?? image?.colorId ?? "") === String(colorId),
    );
    if (byColor.length) return pickFrom(byColor);
  }

  const genericImages = images.filter(
    (image) =>
      (image?.color_id === null || image?.color_id === undefined) &&
      (image?.colorId === null || image?.colorId === undefined),
  );
  if (genericImages.length) return pickFrom(genericImages);

  return pickFrom(images);
};

const getProductThumb = (product, colorId = null) => {
  const image = pickPrimaryProductImage(product, colorId);
  return image?.url || "";
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
  pickPrimaryProductImage,
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

<template>
  <div class="row g-3">
    <!-- Header -->
    <div class="col-12">
      <div class="d-flex align-items-start align-items-md-center justify-content-between gap-2 flex-column flex-md-row">
        <div>
          <h4 class="mb-1">Tạo phiếu nhập</h4>
          <div class="small opacity-75">
            Chọn nhà cung cấp, kho và thêm các mặt hàng nhập
          </div>
        </div>

        <RouterLink class="btn btn-outline-secondary" :to="{ name: 'receipts.list' }">
          <i class="fa-solid fa-arrow-left me-1"></i> Quay lại
        </RouterLink>
      </div>
    </div>

    <!-- Form -->
    <div class="col-12">
      <div class="card card-soft">
        <div class="card-body">
          <Form :validation-schema="schema" :initial-values="initialValues" @submit="onSubmit" v-slot="{
            isSubmitting,
            setFieldValue,
            setFieldTouched,
            values,
            errors,
          }">
            <div class="row g-3">
              <!-- Supplier -->
              <div class="col-12 col-md-6">
                <label class="form-label">Nhà cung cấp</label>

                <Field name="supplier_id" v-slot="{ field, meta, errors }">
                  <select v-bind="field" class="form-select bg-transparent" :class="{
                    'is-invalid':
                      (meta.touched && !meta.valid) || errors.length,
                  }">
                    <option value="">-- Chọn nhà cung cấp --</option>
                    <option v-for="s in distributors" :key="s.id" :value="String(s.id)">
                      {{ s.name }}
                    </option>
                  </select>
                </Field>

                <ErrorMessage name="supplier_id" class="invalid-feedback d-block" />
              </div>

              <!-- Warehouse -->
              <div class="col-12 col-md-6">
                <label class="form-label">Kho nhập</label>

                <Field name="warehouse_id" v-slot="{ field, meta, errors }">
                  <select v-bind="field" class="form-select bg-transparent" :class="{
                    'is-invalid':
                      (meta.touched && !meta.valid) || errors.length,
                  }">
                    <option value="">-- Chọn kho --</option>
                    <option v-for="w in warehouses" :key="w.id" :value="String(w.id)">
                      {{ w.address }}
                    </option>
                  </select>
                </Field>

                <ErrorMessage name="warehouse_id" class="invalid-feedback d-block" />
              </div>

              <!-- Items -->
              <div class="col-12">
                <div class="d-flex align-items-center justify-content-between gap-2">
                  <div>
                    <div class="fw-semibold">Danh sách sản phẩm nhập</div>
                    <div class="small opacity-75">
                      Chọn sản phẩm → chọn màu + kích thước → nhập số lượng & giá
                      nhập
                    </div>
                  </div>

                  <button type="button" class="btn btn-outline-secondary" @click="addRow(setFieldValue, values)"
                    :disabled="isSubmitting">
                    <i class="fa-solid fa-plus me-1"></i> Thêm dòng
                  </button>
                </div>

                <div class="table-responsive mt-2">
                  <table class="table align-middle mb-0">
                    <thead>
                      <tr class="small opacity-75">
                        <th style="min-width: 320px">Sản phẩm</th>
                        <th style="min-width: 200px">Màu</th>
                        <th style="min-width: 140px">Size</th>
                        <th style="width: 150px">Số lượng</th>
                        <th style="width: 180px">Giá nhập</th>
                        <th style="width: 120px" class="text-end">Thao tác</th>
                      </tr>
                    </thead>

                    <FieldArray name="items" v-slot="{ fields, remove }">
                      <tbody>
                        <tr v-for="(f, idx) in fields" :key="f.key">
                          <!-- PRODUCT -->
                          <td>
                            <div class="d-flex align-items-center gap-2">
                              <div class="thumb">
                                <img v-if="getProductThumb(f.value.product_id)"
                                  :src="getProductThumb(f.value.product_id)" alt="thumb" />
                                <div v-else class="thumb-placeholder">
                                  <i class="fa-regular fa-image"></i>
                                </div>
                              </div>

                              <div class="flex-grow-1">
                                <Field :name="`items[${idx}].product_id`"
                                  v-slot="{ field, meta, errors, handleChange }">
                                  <select v-bind="field" class="form-select bg-transparent" :class="{
                                    'is-invalid':
                                      meta.touched && errors.length,
                                  }" @change="
                                    (e) => {
                                      handleChange(e); // cập nhật field.product_id
                                      onProductSelect(
                                        idx,
                                        e.target.value,
                                        setFieldValue,
                                        setFieldTouched
                                      );
                                    }
                                  ">
                                    <option value="">
                                      -- Chọn sản phẩm --
                                    </option>
                                    <option v-for="p in products" :key="p.id" :value="String(p.id)">
                                      {{ p.name }}
                                    </option>
                                  </select>
                                </Field>

                                <ErrorMessage :name="`items[${idx}].product_id`" class="invalid-feedback d-block" />
                              </div>
                            </div>
                          </td>

                          <!-- COLOR -->
                          <td>
                            <Field :name="`items[${idx}].color_id`" v-slot="{ field, meta, errors, handleChange }">
                              <select v-bind="field" class="form-select bg-transparent" :disabled="!f.value.product_id ||
                                !getColorsForRow(f.value).length
                                " :class="{
                                  'is-invalid': meta.touched && errors.length,
                                }" @change="handleChange">
                                <!-- Co mau => bat buoc chon -->
                                <option v-if="getColorsForRow(f.value).length" value="">
                                  -- Chọn màu --
                                </option>

                                <option v-for="c in getColorsForRow(f.value)" :key="c.id" :value="String(c.id)">
                                  {{ c.name }}
                                </option>

                                <!-- Khong co mau -->
                                <option v-if="!getColorsForRow(f.value).length" value="">
                                  Không có màu
                                </option>
                              </select>
                            </Field>

                            <ErrorMessage :name="`items[${idx}].color_id`" class="invalid-feedback d-block" />
                          </td>

                          <!-- SIZE -->
                          <td>
                            <Field :name="`items[${idx}].size_id`" v-slot="{ field, meta, errors, handleChange }">
                              <select v-bind="field" class="form-select bg-transparent" :disabled="!f.value.product_id ||
                                !getSizesForRow(f.value).length
                                " :class="{
                                  'is-invalid': meta.touched && errors.length,
                                }" @change="handleChange">
                                <!-- Co size => bat buoc chon -->
                                <option v-if="getSizesForRow(f.value).length" value="">
                                  -- Chọn kích thước --
                                </option>

                                <option v-for="s in getSizesForRow(f.value)" :key="s.id" :value="String(s.id)">
                                  {{ s.size }}
                                </option>

                                <!-- Khong co size -->
                                <option v-if="!getSizesForRow(f.value).length" value="">
                                  Không có kích thước
                                </option>
                              </select>
                            </Field>

                            <ErrorMessage :name="`items[${idx}].size_id`" class="invalid-feedback d-block" />
                          </td>

                          <!-- QUANTITY -->
                          <td>
                            <Field :name="`items[${idx}].quantity`" v-slot="{ field, meta, errors, handleChange }">
                              <input v-bind="field" type="number" min="1" step="1" inputmode="numeric"
                                class="form-control bg-transparent" :class="{
                                  'is-invalid': meta.touched && errors.length,
                                }" @input="handleChange" />
                            </Field>
                            <ErrorMessage :name="`items[${idx}].quantity`" class="invalid-feedback d-block" />
                          </td>

                          <!-- UNIT PRICE -->
                          <td>
                            <Field :name="`items[${idx}].purchase_price`"
                              v-slot="{ field, meta, errors, handleChange }">
                              <input v-bind="field" type="number" min="1" step="1" inputmode="numeric"
                                class="form-control bg-transparent" :class="{
                                  'is-invalid': meta.touched && errors.length,
                                }" @input="handleChange" />
                            </Field>
                            <ErrorMessage :name="`items[${idx}].purchase_price`" class="invalid-feedback d-block" />
                          </td>

                          <!-- ACTIONS -->
                          <td class="text-end">
                            <button type="button" class="btn btn-outline-danger btn-sm" @click="remove(idx)"
                              :disabled="isSubmitting || fields.length <= 1" title="Xóa dòng">
                              <i class="fa-solid fa-trash"></i>
                            </button>
                          </td>
                        </tr>
                      </tbody>
                    </FieldArray>
                  </table>
                </div>

                <div class="invalid-feedback d-block mt-2" v-if="typeof errors.items === 'string'">
                  {{ errors.items }}
                </div>

                <div class="d-flex justify-content-end mt-3">
                  <div class="text-end">
                    <div class="d-flex justify-content-between gap-3 align-items-center">
                      <span class="small opacity-75">Tổng số lượng :</span>
                      <span class="ms-4 fs-5 fw-semibold">{{
                        calcTQuantity(values.items)
                      }}</span>
                    </div>

                    <div class="d-flex justify-content-between gap-3 mt-1">
                      <span class="small opacity-75">Tổng tiền :</span>
                      <span class="ms-4 fs-5 fw-semibold">{{
                        formatMoney(calcTotal(values.items))
                      }}</span>
                    </div>
                  </div>
                </div>


              </div>
            </div>

            <div class="d-flex gap-2 mt-3">
              <button class="btn btn-accent" type="submit" :disabled="isSubmitting">
                <i class="fa-solid fa-circle-plus me-1"></i>
                {{ isSubmitting ? "Đang tạo..." : "Tạo phiếu nhập" }}
              </button>

              <button class="btn btn-outline-secondary" type="button" :disabled="isSubmitting"
                @click="resetAll(setFieldValue)">
                <i class="fa-solid fa-rotate-left me-1"></i> Reset
              </button>
            </div>
          </Form>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { computed, onMounted, ref } from "vue";
import { useRouter } from "vue-router";
import { Form, Field, FieldArray, ErrorMessage } from "vee-validate";
import * as yup from "yup";
import Swal from "sweetalert2";


import { formatMoney } from "@/utils/utils";
import ReceiptService from "@/services/receipt.service";
import DistributorService from "@/services/distributor.service";
import WarehouseService from "@/services/warehouse.service";
import ProductService from "@/services/product.service";

const router = useRouter();

const distributors = ref([]);
const warehouses = ref([]);
const products = ref([]);

const initialValues = {
  distributor_id: "",
  warehouse_id: "",
  items: [
    {
      product_id: "",
      color_id: "",
      size_id: "",
      quantity: 1,
      purchase_price: 1,
    },
  ],
};

const schema = computed(() =>
  yup.object({
    distributor_id: yup.string().required("Vui lòng chọn nhà cung cấp"),
    warehouse_id: yup.string().required("Vui lòng chọn kho"),
    items: yup
      .array()
      .min(1, "Vui lòng thêm ít nhất 1 dòng sản phẩm")
      .of(
        yup.object({
          product_id: yup.string().required("Chọn sản phẩm"),

          color_id: yup
            .string()
            .test(
              "color-required-by-product",
              "Vui lòng chọn màu",
              function (val) {
                const pid = this.parent?.product_id;
                if (!pid) return true; // product chưa chọn thì không bắt
                const p = products.value.find(
                  (x) => String(x.id) === String(pid)
                );
                const hasColors = (p?.product_details || []).length > 0;
                if (!hasColors) return true; // không có màu => cho rỗng
                return !!val; // có màu => bắt chọn
              }
            ),

          size_id: yup
            .string()
            .test(
              "size-required-by-product",
              "Vui long chon size",
              function (val) {
                const pid = this.parent?.product_id;
                if (!pid) return true;
                const p = products.value.find(
                  (x) => String(x.id) === String(pid)
                );
                const hasSizes = (p?.product_details || []).length > 0;
                if (!hasSizes) return true;
                return !!val;
              }
            ),

          quantity: yup
            .number()
            .typeError("Số lượng phải là số")
            .integer("Số lượng phải là số nguyên")
            .min(1, "Số lượng phải là số nguyên dương")
            .required("Nhập số lượng"),

          purchase_price: yup
            .number()
            .typeError("Giá nhập phải là số")
            .moreThan(0, "Giá nhập phải lớn hơn 0")
            .required("Nhập giá nhập"),
        })
      ),
  })
);

function makeRow() {
  return {
    // _key: crypto?.randomUUID?.() || `${Date.now()}-${Math.random()}`,
    product_id: "",
    color_id: "",
    size_id: "",
    quantity: 1,
    purchase_price: 1,
  };
}

function addRow(setFieldValue, values) {
  setFieldValue("items", [...values.items, makeRow()]);
}

function removeRow(rowKey, setFieldValue, values) {
  const next = values.items.filter((x) => x._key !== rowKey);
  setFieldValue("items", next.length ? next : [makeRow()]);
}

function resetAll(setFieldValue) {
  setFieldValue("distributor_id", "");
  setFieldValue("warehouse_id", "");
  setFieldValue("items", JSON.parse(JSON.stringify(initialValues.items)));
}

function findProductById(productId) {
  return products.value.find((p) => String(p.id) === String(productId));
}

function getColorsForRow(row) {
  const p = findProductById(row.product_id);
  const details = p?.product_details || [];
  const map = new Map();
  details.forEach((d) => {
    if (d?.color) {
      map.set(d.color.id, d.color);
    }
  });
  return Array.from(map.values());
}

function getSizesForRow(row) {
  const p = findProductById(row.product_id);
  const details = p?.product_details || [];
  const colorId = row?.color_id;
  const filtered = colorId
    ? details.filter((d) => String(d?.color?.id ?? d?.color_id) === String(colorId))
    : details;
  const map = new Map();
  filtered.forEach((d) => {
    if (d?.size) {
      map.set(d.size.id, d.size);
    }
  });
  return Array.from(map.values());
}

function getProductThumb(productId) {
  const p = findProductById(productId);
  if (!p) return "";

  const first = p?.product_images?.[0]?.url || p?.images?.[0]?.url || "";

  return first || "";
}

function onProductSelect(idx, productId, setFieldValue) {
  setFieldValue(`items[${idx}].product_id`, productId);

  // reset color khi đổi sản phẩm
  setFieldValue(`items[${idx}].color_id`, "");
}

function getRowError(errors, idx, field) {
  const rowErr = errors?.items?.[idx];
  if (!rowErr) return "";
  return rowErr[field] || "";
}
function calcTQuantity(items) {
  return (items || []).reduce((sum, it) => sum + Number(it?.quantity || 0), 0);
}
function calcTotal(items) {
  return (items || []).reduce((sum, it) => {
    const q = Number(it.quantity || 0);
    const p = Number(it.purchase_price || 0);
    return sum + q * p;
  }, 0);
}

async function onSubmit(values, { setErrors }) {
  try {
    const payload = {
      distributor_id: Number(values.distributor_id),
      warehouse_id: Number(values.warehouse_id),
      details: values.items.map((it) => ({
        product_id: Number(it.product_id),
        color_id: it.color_id ? Number(it.color_id) : null,
        size_id: it.size_id ? Number(it.size_id) : null,
        quantity: Number(it.quantity),
        purchase_price: Number(it.purchase_price),
      })),
    };

    console.log(payload);
    // return;
    await ReceiptService.create(payload);

    await Swal.fire("Thành công!", "Tạo phiếu nhập thành công!", "success");
    router.push({ name: "receipts.list" });
  } catch (e) {
    console.log(e)
    const status = e?.response?.status;
    const data = e?.response?.data;

    if (status === 422 && data?.errors) {
      const mapped = {};
      Object.keys(data.errors).forEach((k) => {
        mapped[k] = Array.isArray(data.errors[k])
          ? data.errors[k][0]
          : String(data.errors[k]);
      });
      setErrors(mapped);
      return;
    }

    const msg =
      data?.message ||
      data?.error ||
      "Tạo phiếu nhập thất bại. Vui lòng thử lại.";
    await Swal.fire("Tạo phiếu nhập thất bại", msg, "error");
  }
}

onMounted(async () => {
  const distributorRes = await DistributorService.getAll({ per_page: 200 });
  distributors.value = distributorRes.items || [];

  const warehouseRes = await WarehouseService.getAll({ per_page: 200 });
  warehouses.value = warehouseRes.items || [];

  const productRes = await ProductService.getAll({ per_page: 200 });
  products.value = productRes.items || [];
});
</script>

<style scoped>
.card-soft {
  background: var(--main-extra-bg);
  border: 1px solid var(--border-color);
  border-radius: 1rem;
  color: var(--font-color);
}

.btn-accent {
  background: var(--main-color);
  border: 1px solid var(--hover-border-color);
  color: var(--dark);
}

.btn-accent:hover {
  filter: var(--brightness);
}

/* product thumb */
.thumb {
  width: 7rem;
  border-radius: 0.6rem;
  overflow: hidden;
  border: 1px solid var(--border-color);
  background: rgba(255, 255, 255, 0.03);
  flex: 0 0 auto;
  display: flex;
  align-items: center;
  justify-content: center;
}

.thumb img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.thumb-placeholder {
  opacity: 0.6;
  font-size: 1.1rem;
}
</style>

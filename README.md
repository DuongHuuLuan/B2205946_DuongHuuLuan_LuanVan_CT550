# Hệ Thống Bán Nón Bảo Hiểm Tích Hợp AI Và Quản Trị Đa Nền Tảng

Xây dựng một hệ thống bán nón bảo hiểm hoàn chỉnh gồm backend API, web quản trị và ứng dụng người dùng. Hệ thống không chỉ hỗ trợ các nghiệp vụ thương mại điện tử cơ bản như quản lý sản phẩm, giỏ hàng, đơn hàng, đánh giá và khuyến mãi mà còn mở rộng với chatbot tư vấn, chat thời gian thực, thanh toán VNPAY, tính phí vận chuyển GHN, thông báo đẩy và tính năng tự thiết kế nón bằng sticker AI.

## 1. Tổng quan hệ thống

### Vai trò từng thành phần

- Backend: cung cấp REST API, WebSocket, xử lý nghiệp vụ, tích hợp OpenAI, Cloudinary, GHN, VNPAY và Firebase Cloud Messaging.
- Frontend/Admin: giao diện quản trị cho vận hành cửa hàng, kho, phiếu nhập, đơn hàng, chat hỗ trợ, thống kê và quản lý sticker.
- Frontend/User: ứng dụng người dùng để duyệt sản phẩm, mua hàng, theo dõi đơn, chat hỗ trợ và thiết kế nón bảo hiểm.

## 2. Chức năng nổi bật

### 2.1. Ứng dụng người dùng Flutter

- Đăng ký, đăng nhập, xác thực JWT và lưu trạng thái đăng nhập an toàn.
- Xem danh mục, danh sách sản phẩm, chi tiết sản phẩm và biến thể theo màu/kích thước.
- Tìm kiếm, xem tồn kho, thêm vào giỏ hàng và áp dụng mã giảm giá.
- Tạo đơn hàng, chọn địa chỉ giao hàng, tính phí vận chuyển qua GHN.
- Thanh toán và nhận kết quả thanh toán qua VNPAY kèm deep link quay lại ứng dụng.
- Theo dõi lịch sử đơn hàng, xác nhận nhận hàng, xem chi tiết đơn và đánh giá sản phẩm.
- Quản lý hồ sơ cá nhân, avatar, voucher và lịch sử đánh giá.
- Chat realtime với quản trị viên bằng WebSocket.
- Chatbot hỗ trợ tư vấn sản phẩm, gợi ý khuyến mãi, tra cứu đơn hàng và thêm vào giỏ ngay trong khung chat.
- Thiết kế nón bảo hiểm với sticker hệ thống hoặc sticker AI do người dùng tạo.
- Tạo sticker AI bằng văn bản hoặc bằng giọng nói, lưu thiết kế và đưa thiết kế vào luồng đặt hàng.
- Nhận thông báo đẩy bằng Firebase Cloud Messaging.

### 2.2. Web quản trị Vue 3

- Đăng nhập quản trị và bảo vệ route.
- Dashboard và màn hình thống kê hoạt động kinh doanh.
- Quản lý danh mục, sản phẩm, kích thước, phương thức thanh toán.
- Quản lý nhà cung cấp, kho và phiếu nhập.
- Quản lý khuyến mãi, tài khoản người dùng và đánh giá chờ phản hồi.
- Xem và xử lý đơn hàng, duyệt hoặc từ chối đơn cần xem xét.
- Chế độ xem sản xuất để kiểm tra snapshot thiết kế, layer sticker và khả năng in ấn cho đơn hàng có thiết kế riêng.
- Chat realtime với khách hàng.
- Handoff từ chatbot sang admin và bật lại chatbot trong cùng luồng chat.
- Quản lý sticker hệ thống và xem sticker do người dùng tạo.

### 2.3. Backend FastAPI

- Tổ chức API theo domain: auth, users, products, categories, cart, orders, discounts, delivery, payments, evaluates, profile, chat, push notification, stickers, designs, warehouses, receipts, dashboard, statistics, GHN và VNPAY.
- SQLAlchemy ORM + Alembic migration để quản lý mô hình dữ liệu và thay đổi schema.
- Xác thực JWT cho user và admin.
- WebSocket cho chat realtime.
- Tích hợp Cloudinary để lưu hình ảnh đánh giá, sticker AI và các tài nguyên media.
- Tích hợp OpenAI cho:
  - sinh ảnh sticker AI,
  - chuyển giọng nói thành văn bản cho luồng voice sticker,
  - tạo câu trả lời chatbot tư vấn sản phẩm.
- Tích hợp GHN để lấy phí vận chuyển, danh sách tỉnh/huyện/xã và tạo đơn giao hàng.
- Tích hợp VNPAY để tạo giao dịch thanh toán và xử lý callback.
- Tích hợp Firebase Admin/FCM để đăng ký thiết bị và gửi thông báo đẩy.
- Worker nền cho hàng đợi push notification outbox.

## 3. Công nghệ sử dụng

| Thành phần         | Công nghệ chính                                                       |
| ------------------ | --------------------------------------------------------------------- |
| Backend            | Python, FastAPI, SQLAlchemy, Alembic, MySQL, Uvicorn, WebSocket       |
| Admin web          | Vue 3, Vue Router, Vite, Axios, Vee Validate, Yup                     |
| User app           | Flutter, Dart, Provider, GoRouter, Dio, WebSocket, Firebase Messaging |
| AI & dịch vụ ngoài | OpenAI, Cloudinary, GHN, VNPAY, Firebase Cloud Messaging              |

## 4. Yêu cầu môi trường

### Tối thiểu

- Python 3.11 trở lên
- MySQL 8 trở lên
- Node.js 20 trở lên
- Flutter SDK tương thích với Dart `^3.9.2`
- Android Studio hoặc thiết bị/emulator Android nếu chạy app mobile

### Dịch vụ ngoài cần cấu hình

- Cloudinary
- OpenAI
- Firebase Cloud Messaging
- GHN
- VNPAY

## 5. Hướng dẫn chạy dự án cục bộ

### 5.1. Chạy backend

Di chuyển vào thư mục `backend`:

```bash
cd backend
```

Tạo môi trường ảo và cài thư viện:

```bash
python -m venv .venv
.venv\Scripts\activate
pip install -r requirements.txt
```

Tạo file `.env` cho backend với các biến quan trọng sau:

```env
DB_USER=...
DB_PASSWORD=...
DB_HOST=127.0.0.1
DB_PORT=3306
DB_NAME=...

SECRET_KEY=...
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=60

CLOUDINARY_CLOUD_NAME=...
CLOUDINARY_API_KEY=...
CLOUDINARY_API_SECRET=...

OPENAI_API_KEY=...
OPENAI_BASE_URL=https://api.openai.com/v1
OPENAI_IMAGE_MODEL=gpt-image-1.5
OPENAI_TRANSCRIPTION_MODEL=gpt-4o-mini-transcribe
CHATBOT_ENABLED=true
OPENAI_CHAT_MODEL=gpt-5-mini
OPENAI_CHAT_FALLBACK_MODEL=gpt-5.4

VNPAY_TMN_CODE=...
VNPAY_HASH_SECRET=...
VNPAY_RETURN_URL=...
APP_DEEP_LINK_SCHEME=helmetshop
APP_RETURN_URL=...

GHN_TOKEN=...
GHN_SHOP_ID=...
GHN_FROM_NAME=...
GHN_FROM_PHONE=...
GHN_FROM_ADDRESS=...
GHN_FROM_WARD_CODE=...
GHN_FROM_DISTRICT_ID=...

FCM_CREDENTIALS_FILE=...
FCM_PROJECT_ID=...
```

Chạy migration:

```bash
alembic upgrade head
```

Khởi động API:

```bash
uvicorn app.main:app --reload
```

API mặc định sẽ chạy tại `http://127.0.0.1:8000`.

Nếu dùng thông báo đẩy theo outbox worker, chạy thêm tiến trình nền:

```bash
python -m app.workers.push_outbox_worker
```

### 5.2. Chạy frontend admin

Di chuyển vào thư mục `frontend/admin`:

```bash
cd frontend/admin
```

Cài đặt dependencies:

```bash
npm install
```

Tạo file `.env`:

```env
VITE_API_BASE_URL=http://127.0.0.1:8000
```

Chạy môi trường phát triển:

```bash
npm run dev
```

Mặc định admin web sẽ chạy qua Vite tại `http://localhost:5173`.

### 5.3. Chạy frontend user

Di chuyển vào thư mục `frontend/user`:

```bash
cd frontend/user
```

Cài package Flutter:

```bash
flutter pub get
```

Tạo file `.env`:

```env
BASE_URL=http://10.0.2.2:8000
CONNECT_TIMEOUT=30
RECEIVE_TIMEOUT=15
```

Ghi chú:

- Dùng `http://10.0.2.2:8000` nếu chạy Android emulator và backend chạy trên máy local.
- Nếu chạy trên thiết bị thật, cần thay `BASE_URL` bằng IP LAN hoặc domain public như ngrok.
- Android đã có `google-services.json`; nếu chạy trên iOS thì cần bổ sung cấu hình Firebase tương ứng.
- `APP_DEEP_LINK_SCHEME` ở backend phải đồng bộ với deep link scheme của ứng dụng mobile để nhận kết quả VNPAY.

Chạy ứng dụng:

```bash
flutter run
```

## 6. Thứ tự khởi động khuyến nghị

1. Khởi động MySQL.
2. Chạy backend FastAPI.
3. Chạy worker push outbox nếu dùng thông báo đẩy.
4. Chạy admin web để kiểm tra dữ liệu vận hành.
5. Chạy app Flutter user để kiểm thử luồng người dùng cuối.

## 7. Một số luồng nghiệp vụ tiêu biểu

- Mua hàng: chọn sản phẩm -> thêm giỏ -> áp mã giảm giá -> chọn địa chỉ và dịch vụ GHN -> tạo thanh toán VNPAY -> nhận callback/deep link -> xem trạng thái đơn.
- Chat hỗ trợ: user gửi tin nhắn -> backend lưu và broadcast WebSocket -> chatbot hoặc admin phản hồi -> user nhận realtime trong ứng dụng.
- Thiết kế nón: user mở màn thiết kế -> chọn sticker thư viện hoặc tạo sticker AI -> chỉnh layer trên canvas -> lưu thiết kế -> đặt hàng với thiết kế đã chọn.
- Vận hành đơn có thiết kế: admin mở đơn hàng -> vào chế độ xem sản xuất -> kiểm tra snapshot, layer và hình sticker -> xử lý bước sản xuất/in ấn.

## 8. Điểm đáng chú ý của dự án

- Kết hợp mô hình thương mại điện tử với AI thay vì chỉ dừng ở CRUD sản phẩm.
- Chatbot được tích hợp trực tiếp vào hệ thống chat đang có sẵn, không tách thành một module rời.
- Thiết kế sticker AI hỗ trợ cả nhập văn bản lẫn mô tả bằng giọng nói.
- Có đầy đủ mặt vận hành nội bộ qua admin web và trải nghiệm người dùng cuối qua ứng dụng mobile.
- Kiến trúc chia lớp tương đối rõ giữa `api`, `service`, `model`, `schema` ở backend và `data/domain/presentation` ở Flutter.

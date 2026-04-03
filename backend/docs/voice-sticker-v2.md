# Voice Sticker V2

## 1. Mục tiêu

Chức năng `Voice Sticker V2` cho phép người dùng:

1. Nhấn nút mic trong phần `AI Sticker`.
2. Ghi âm mô tả sticker bằng giọng nói.
3. Tự động dừng khi người dùng im lặng.
4. Gửi audio lên backend để chuyển thành text.
5. Chỉ khi transcript hợp lệ mới gọi AI tạo sticker.
6. Hiển thị sticker kết quả và cho phép `Thiết kế ngay`.

## 2. Kiến trúc tổng thể

Luồng tổng quát:

```text
Người dùng
-> AI Sticker card
-> HelmetDesignerPage mở màn hình voice
-> record ghi âm ra file tạm
-> app phát hiện im lặng hoặc người dùng bấm dừng
-> app upload audio tới /stickers/transcribe-voice
-> backend gọi OpenAI transcription
-> backend trả về prompt text
-> app gọi /stickers/generate
-> backend gọi OpenAI image generation
-> backend upload ảnh lên Cloudinary + lưu Sticker vào DB
-> app hiện sticker kết quả
-> người dùng chọn Đóng hoặc Thiết kế ngay
```

---

## 3. Các file liên quan

### Frontend Flutter

- `frontend/user/lib/features/helmet_designer/presentation/view/helmet_designer_page.dart`
  - File điều phối chính của toàn bộ flow voice sticker.
  - Quản lý state ghi âm, dialog voice, gọi transcribe, gọi generate, nhận sticker kết quả.

- `frontend/user/lib/features/helmet_designer/presentation/widget/ai_sticker_section.dart`
  - Card UI cho phần `AI Sticker`.
  - Cho nhập prompt text, chọn style, màu, nền và bấm `Nhấn để nói`.

- `frontend/user/lib/features/helmet_designer/presentation/widget/ai_sticker_voice_screen.dart`
  - Màn hình voice full-screen/overlay.
  - Hiển thị các trạng thái:
    - `Đang mở microphone...`
    - `Tôi đang nghe đây...`
    - `Đang xử lý giọng nói...`
    - `Đang tạo sticker...`
    - `Sticker của bạn đã sẵn sàng`
    - `Không thể tạo sticker`

- `frontend/user/lib/features/helmet_designer/presentation/viewmodel/helmet_designer_viewmodel.dart`
  - ViewModel trung gian giữa UI và repository.
  - Quản lý cờ `isGeneratingSticker`, `isTranscribingSticker`, `errorMessage`.

- `frontend/user/lib/features/helmet_designer/data/helmet_designer_repository_impl.dart`
  - Triển khai repository.
  - Map dữ liệu giữa UI/domain và API/backend.

- `frontend/user/lib/features/helmet_designer/data/helmet_designer_api.dart`
  - Gọi HTTP bằng Dio.
  - Gửi JSON để generate ảnh.
  - Gửi multipart/form-data để upload audio transcription.

- `frontend/user/lib/features/helmet_designer/domain/ai_sticker_request.dart`
  - Model domain cho request tạo sticker AI.

- `frontend/user/lib/features/helmet_designer/data/model/ai_sticker_request_mapper.dart`
  - Chuyển `AiStickerRequest` sang JSON backend cần.

- `frontend/user/lib/core/constants/api_endpoints.dart`
  - Giữ path API `/stickers/generate` và `/stickers/transcribe-voice`.

### Backend FastAPI

- `backend/app/api/endpoints/sticker.py`
  - Định nghĩa 2 endpoint chính:
    - `POST /stickers/transcribe-voice`
    - `POST /stickers/generate`

- `backend/app/services/sticker_service.py`
  - Validate file audio.
  - Gọi transcription service.
  - Chuẩn hóa prompt.
  - Build prompt tạo ảnh.
  - Gọi image service.
  - Upload Cloudinary.
  - Lưu DB.

- `backend/app/services/openai_audio_service.py`
  - Gọi OpenAI `/audio/transcriptions`.

- `backend/app/services/openai_image_service.py`
  - Gọi OpenAI `/images/generations`.

- `backend/app/schemas/sticker.py`
  - Schema request/response cho generate và transcription.

- `backend/app/core/config.py`
  - Giữ cấu hình model, timeout, giới hạn file audio.

---

## 4. Thiết lập cần có

### Frontend

- Package ghi âm:
  - `record: ^6.2.0`

- Android:
  - Cần `android.permission.RECORD_AUDIO`

- iOS:
  - Cần `NSMicrophoneUsageDescription`

### Backend

- Cần cấu hình:
  - `OPENAI_API_KEY`
  - `OPENAI_BASE_URL`
  - `OPENAI_IMAGE_MODEL`
  - `OPENAI_TRANSCRIPTION_MODEL`
  - `OPENAI_TRANSCRIPTION_LANGUAGE`
  - `OPENAI_IMAGE_TIMEOUT_SECONDS`
  - `OPENAI_TRANSCRIPTION_TIMEOUT_SECONDS`
  - `AI_STICKER_VOICE_MAX_FILE_MB`

### Model hiện tại

- Transcription:
  - `gpt-4o-mini-transcribe`

- Image generation:
  - Lấy từ `OPENAI_IMAGE_MODEL`
  - Mặc định trong code là `gpt-image-1.5`
  - Runtime có thể bị override bằng `.env`

---

## 5. Các trường dữ liệu chính

### Request tạo sticker

Model domain frontend:

```dart
AiStickerRequest {
  String prompt;
  String? style;
  String? dominantColor;
  bool removeBackground;
}
```

JSON gửi backend:

```json
{
  "prompt": "...",
  "style": "...",
  "dominant_color": "#FF0000",
  "remove_background": true
}
```

Backend schema:

```python
class AiStickerGenerateIn(BaseModel):
    prompt: str
    name: Optional[str] = None
    style: Optional[str] = None
    dominant_color: Optional[str] = None
    remove_background: bool = True
```

### Response transcription

```python
class AiStickerTranscriptionOut(BaseModel):
    prompt: str
```

### Audio upload

- Field form-data:
  - `audio`

- Định dạng audio hỗ trợ:
  - `.mp3`
  - `.mp4`
  - `.mpeg`
  - `.mpga`
  - `.m4a`
  - `.wav`
  - `.webm`

---

## 6. State frontend và ý nghĩa

Trong `HelmetDesignerPage`, các biến state quan trọng là:

- `_isPreparingVoice`
  - App đang chuẩn bị mở mic.
  - Dùng để khóa nút bấm lặp và đổi UI sang pha `opening`.

- `_isRecordingVoice`
  - Recorder đang ghi âm thật.
  - Khi biến này là `true`, UI voice screen ở trạng thái `listening`.

- `_isProcessingVoice`
  - App đã dừng ghi âm và đang chờ transcription/generation.

- `_hasDetectedSpeech`
  - Đã nghe thấy tiếng nói vượt ngưỡng chưa.
  - Chỉ khi đã có tiếng nói rồi mới bắt đầu logic `im lặng -> auto stop`.

- `_voiceRecordingStartedAt`
  - Thời điểm bắt đầu ghi âm.
  - Dùng để tính độ dài audio và chặn audio quá ngắn.

- `_voiceAmplitudeSubscription`
  - Stream subscription của amplitude mic.
  - Dùng để phát hiện tiếng nói và im lặng.

- `_voiceSilenceTimer`
  - Timer đếm khoảng im lặng.
  - Nếu hết timer thì app tự dừng ghi âm và chuyển sang xử lý.

- `_voiceMaxDurationTimer`
  - Timer giới hạn thời lượng ghi âm tối đa.
  - Hiện tại là `20 giây`.

- `_voiceScreenState`
  - `ValueNotifier` giữ trạng thái đang hiển thị trên màn hình voice.

- `_voiceScreenDialogContext`
  - Context của dialog voice, dùng để đóng màn hình.

- `_isVoiceScreenVisible`
  - Tránh mở chồng nhiều dialog voice cùng lúc.

- `_isDisposingPage`
  - Guard để tránh update state/notifier khi page đang dispose.

### Hằng số kỹ thuật

- `_voiceActivityThresholdDbfs = -40`
  - Ngưỡng coi là đã có tiếng nói.

- `_voiceSilenceDuration = 1600ms`
  - Im lặng trong thời gian này sẽ auto stop.

- `_voiceMaxRecordingDuration = 20s`
  - Hết thời gian này cũng stop.

- `_voiceMinRecordingDuration = 700ms`
  - Ngắn hơn mức này thì coi là không hợp lệ.

---

## 7. Luồng frontend chi tiết

### 7.1. Từ card AI Sticker

Người dùng bấm `Nhấn để nói` trong `AiStickerSection`.

`HelmetDesignerPage` truyền callback:

- `onToggleVoice: () => _startVoiceFlow(context)`

### 7.2. Bắt đầu flow voice

Hàm `_startVoiceFlow(context)`:

1. Kiểm tra app có đang bận hay không.
2. Nếu đang generate/transcribe/dialog voice đang mở thì return.
3. Mở màn hình voice bằng `_showVoiceScreen(context)`.
4. Gọi `_startVoiceRecordingForScreen(context)`.

### 7.3. Mở màn hình voice

Hàm `_showVoiceScreen(context)`:

1. Đặt `_isVoiceScreenVisible = true`
2. Đẩy state `AiStickerVoiceScreenState.opening()`
3. Mở `showGeneralDialog`
4. Bọc dialog bằng `ValueListenableBuilder`
5. Mỗi lần `_voiceScreenState` đổi, UI đổi theo

### 7.4. Bắt đầu ghi âm

Hàm `_startVoiceRecordingForScreen(context)`:

1. Set `_isPreparingVoice = true`
2. Kiểm tra permission bằng `_audioRecorder.hasPermission()`
3. Chọn encoder bằng `_pickVoiceEncoder()`
4. Tạo file tạm trong `getTemporaryDirectory()`
5. Gọi `_audioRecorder.start(...)`
6. Tạo subscription `onAmplitudeChanged(...)`
7. Tạo timer giới hạn thời gian ghi âm tối đa
8. Set:
   - `_isPreparingVoice = false`
   - `_isRecordingVoice = true`
9. Chuyển UI sang `AiStickerVoiceScreenState.listening()`

### 7.5. Phát hiện im lặng

Hàm `_handleVoiceAmplitudeForScreen(context, amplitude)`:

1. Nếu amplitude vượt ngưỡng `-40 dBFS`
   - đánh dấu `_hasDetectedSpeech = true`
   - hủy timer im lặng cũ

2. Nếu chưa từng có tiếng nói
   - không tự stop

3. Nếu đã từng có tiếng nói rồi và hiện tại đang im lặng
   - tạo `_voiceSilenceTimer`
   - sau `1600ms` gọi `_stopVoiceRecordingAndProcessForScreen(context)`

### 7.6. Dừng ghi âm và xử lý

Hàm `_stopVoiceRecordingAndProcessForScreen(context)`:

1. Hủy timers
2. Hủy subscription amplitude
3. Stop recorder để lấy `audioPath`
4. Nếu file rỗng hoặc không tạo được thì báo lỗi
5. Nếu audio quá ngắn thì báo lỗi
6. Set:
   - `_isRecordingVoice = false`
   - `_isProcessingVoice = true`
7. Đổi màn hình sang `transcribing`
8. Gọi `vm.transcribeAiStickerVoice(audioPath)`
9. Xóa file audio tạm bằng `_deleteTempAudioFile(audioPath)`
10. Nếu transcript rỗng hoặc lỗi thì hiện `error`
11. Nếu transcript hợp lệ:
    - đổ vào `_aiPromptController`
    - đổi state sang `generating`
    - gọi `_generateAiStickerSilently(context)`
12. Nếu generate thành công:
    - reset state voice
    - đổi sang `result`

### 7.7. Áp dụng sticker lên canvas

Hàm `_applyVoiceSticker(context, sticker)`:

1. Gọi `vm.addStickerFromTemplate(sticker)`
2. Clear prompt text
3. Đóng màn hình voice

---

## 8. Luồng ViewModel, Repository, API

### ViewModel

`HelmetDesignerViewModel.generateAiSticker(...)`

- bật `isGeneratingSticker`
- gọi repository
- upsert sticker vào catalog
- nếu `addToCanvas = true` thì đưa sticker vào canvas luôn

`HelmetDesignerViewModel.transcribeAiStickerVoice(...)`

- bật `isTranscribingSticker`
- gọi repository
- nếu lỗi thì set `errorMessage`

### Repository

`HelmetDesignerRepositoryImpl.transcribeAiStickerVoice(audioPath)`

1. Gọi API upload file audio.
2. Đọc response.
3. Lấy `prompt` từ response JSON.
4. Nếu prompt rỗng thì throw.

`HelmetDesignerRepositoryImpl.generateAiSticker(request)`

1. Map request sang JSON backend.
2. Gọi API generate.
3. Map response về `StickerTemplate`.

### API

`HelmetDesignerApi.transcribeAiStickerVoice(audioPath)`

- gửi `multipart/form-data`
- field tên `audio`
- timeout gửi: `60s`
- timeout nhận: `120s`

`HelmetDesignerApi.generateAiSticker(body)`

- gửi JSON
- timeout gửi: `30s`
- timeout nhận: `120s`

---

## 9. Luồng backend chi tiết

### 9.1. Endpoint transcription

`POST /stickers/transcribe-voice`

Trong `sticker.py`:

1. Nhận `UploadFile audio`
2. Đọc toàn bộ file vào memory bằng `await audio.read()`
3. Gọi `StickerService.transcribe_voice_prompt(...)`
4. Trả JSON:

```json
{
  "prompt": "..."
}
```

### 9.2. Validate audio

`StickerService._validate_voice_audio(...)` kiểm tra:

- file không rỗng
- không vượt quá giới hạn MB
- extension có nằm trong danh sách hỗ trợ hay không
- nếu không có extension thì `content_type` phải bắt đầu bằng `audio/`

### 9.3. Transcribe bằng OpenAI

`StickerService.transcribe_voice_prompt(...)`:

1. validate audio
2. gọi `OpenAIAudioService.transcribe_audio(...)`
3. chuẩn hóa khoảng trắng
4. nếu prompt quá ngắn thì báo lỗi
5. cắt còn tối đa 500 ký tự

`OpenAIAudioService.transcribe_audio(...)`:

1. kiểm tra `OPENAI_API_KEY`
2. kiểm tra `OPENAI_TRANSCRIPTION_MODEL`
3. gửi HTTP POST tới:
   - `/audio/transcriptions`
4. body gồm:
   - `model`
   - `language` nếu có
   - file audio
5. đọc `payload["text"]`
6. nếu rỗng thì báo lỗi

### 9.4. Endpoint generate

`POST /stickers/generate`

Nhận:

```json
{
  "prompt": "...",
  "style": "...",
  "dominant_color": "...",
  "remove_background": true
}
```

### 9.5. Build prompt ảnh

`StickerService._build_ai_prompt(...)` ghép:

- yêu cầu 1 sticker duy nhất
- subject ở giữa
- outline rõ
- không text/logo/frame/vật thể thừa
- có hoặc không nền trong suốt
- style
- dominant color
- subject từ prompt người dùng

### 9.6. Gọi OpenAI image generation

`OpenAIImageService.generate_sticker(...)`:

1. Lấy model ảnh từ config
2. Build payload
3. Gọi `/images/generations`
4. Đọc `data[0].b64_json`
5. decode base64 thành `image_bytes`
6. xác định `has_transparent_background`

### 9.7. Upload Cloudinary và lưu DB

`StickerService.generate_ai_sticker(...)`:

1. kiểm tra prompt không rỗng
2. enforce daily limit nếu có
3. sinh tên sticker
4. tạo prompt ảnh
5. gọi OpenAI image service
6. upload ảnh lên Cloudinary
7. tạo record `Sticker`
8. commit DB
9. trả `StickerOut`

---

## 10. Audio tạm được xử lý thế nào

### Ở app

- Audio được ghi vào thư mục temp của app.
- Sau khi transcribe xong, app gọi `_deleteTempAudioFile(audioPath)`.
- App không giữ audio lâu dài.

### Ở backend

- Backend không lưu audio xuống disk hay DB.
- Backend chỉ đọc bytes vào memory rồi chuyển tiếp sang OpenAI.

### Thứ được lưu lâu dài

- Chỉ ảnh sticker tạo ra sau cùng.
- Ảnh được upload lên Cloudinary.
- Metadata sticker được lưu trong DB.

---

## 11. Các lỗi phổ biến và ý nghĩa

- `Bạn cần cấp quyền microphone...`
  - App chưa có quyền mic.

- `Không thể bật ghi âm giọng nói lúc này.`
  - Recorder không start được.

- `Đoạn ghi âm quá ngắn...`
  - Người dùng gần như chưa nói hoặc nói quá nhanh.

- `Không nhận được mô tả hợp lệ từ đoạn ghi âm.`
  - Transcription trả về rỗng hoặc không đủ nội dung.

- `Không thể tạo sticker từ mô tả vừa ghi âm.`
  - Transcription có prompt nhưng bước generate thất bại.

- `File audio vượt quá giới hạn`
  - File upload lớn hơn `AI_STICKER_VOICE_MAX_FILE_MB`.

---

## 12. Điểm thiết kế quan trọng

- Chỉ generate ảnh sau khi transcript hợp lệ.
- Không phụ thuộc speech recognition service của thiết bị.
- Không lưu audio lâu dài.
- UI voice tách riêng khỏi card AI Sticker để trải nghiệm rõ ràng hơn.
- `Thiết kế ngay` chỉ áp dụng sticker lên canvas sau khi sticker đã tạo thành công.

---

## 13. Danh sách hàm quan trọng nên đọc trước

### Frontend

- `HelmetDesignerPage._startVoiceFlow`
- `HelmetDesignerPage._showVoiceScreen`
- `HelmetDesignerPage._startVoiceRecordingForScreen`
- `HelmetDesignerPage._handleVoiceAmplitudeForScreen`
- `HelmetDesignerPage._stopVoiceRecordingAndProcessForScreen`
- `HelmetDesignerPage._generateAiStickerSilently`
- `HelmetDesignerPage._applyVoiceSticker`
- `HelmetDesignerViewModel.transcribeAiStickerVoice`
- `HelmetDesignerViewModel.generateAiSticker`

### Backend

- `StickerService.transcribe_voice_prompt`
- `StickerService._validate_voice_audio`
- `StickerService._build_ai_prompt`
- `StickerService.generate_ai_sticker`
- `OpenAIAudioService.transcribe_audio`
- `OpenAIImageService.generate_sticker`

---

## 14. Cách debug nhanh

1. Nếu bấm mic mà không ghi âm:
   - kiểm tra quyền mic
   - kiểm tra `record` plugin
   - kiểm tra UI có vào `listening` không

2. Nếu ghi âm được nhưng không ra text:
   - kiểm tra request tới `/stickers/transcribe-voice`
   - kiểm tra `OPENAI_API_KEY`
   - kiểm tra `OPENAI_TRANSCRIPTION_MODEL`

3. Nếu có text nhưng không ra ảnh:
   - kiểm tra request tới `/stickers/generate`
   - kiểm tra `OPENAI_IMAGE_MODEL`
   - kiểm tra Cloudinary

4. Nếu ảnh tạo được nhưng không thêm lên nón:
   - kiểm tra `onUseSticker`
   - kiểm tra `vm.addStickerFromTemplate`

---

## 15. Tóm tắt ngắn

Voice Sticker V2 là luồng:

`ghi âm cục bộ -> upload audio -> OpenAI transcribe -> generate image -> lưu sticker -> cho người dùng áp dụng sticker`

Đây là thiết kế cân bằng giữa:

- UX gần giống voice search
- chi phí thấp
- không phụ thuộc speech recognition của thiết bị
- không lưu audio lâu dài

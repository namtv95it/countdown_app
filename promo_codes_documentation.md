# Hướng Dẫn Cấu Hình Bảng `promo_codes` (Firebase Firestore)

Bảng (collection) `promo_codes` được dùng để lưu trữ tất cả các mã quà tặng, mã nâng cấp, và mã khởi tạo chế độ ẩn cho ứng dụng. Mỗi mã tương ứng với một **Document**. Dưới đây là giải thích chi tiết ý nghĩa và cách sử dụng của từng trường (field) bên trong document.

> [!TIP]
> Bạn có thể thêm hoặc bớt các trường (field) tùy theo mục đích sử dụng. Ví dụ: Nếu muốn tạo mã vĩnh viễn, chỉ cần không thêm trường `durationDays` vào document.

---

### `code` (String) - *Bắt buộc*
- **Ý nghĩa:** Chuỗi ký tự mà người dùng sẽ nhập vào app (ví dụ: `CAPTAIN888`, `NEWYEAR2026`).
- **Lưu ý:** Mã phải dài từ 5 ký tự trở lên. Viết hoa hay viết thường đều được (App tự động chuyển về in hoa).

### `type` (String) - *Bắt buộc*
- **Ý nghĩa:** Định nghĩa quyền lợi mà người dùng sẽ nhận được khi nhập đúng mã.
- **Các giá trị hợp lệ:**
  - `"premium"`: Nâng cấp tài khoản lên bản Premium (Xóa quảng cáo, mở khóa tính năng cao cấp).
  - `"giftEffect"`: Mở khóa hiệu ứng đặc biệt (ví dụ: tuyết rơi, pháo hoa...).
  - `"testMode"`: Bật chế độ thử nghiệm nội bộ (Tính năng ẩn).
  - `"admin"`: Bật giao diện và quyền Quản trị viên (Tính năng ẩn).

### `description` (String) - *Nên có*
- **Ý nghĩa:** Đoạn mô tả hiển thị lên màn hình điện thoại khi người dùng nhập mã thành công. 
- **Ví dụ:** `"Premium vĩnh viễn"`, `"Quà tặng năm mới 2026!"`. Nếu không điền, app sẽ hiển thị mặc định là `"Quà tặng từ server"`.

### `maxUsage` (Number) - *Tùy chọn*
- **Ý nghĩa:** Số lượt sử dụng tối đa của mã này trên toàn hệ thống.
- **Ví dụ:** Nếu nhập `50`, thì chỉ có 50 người nhanh tay nhất nhập mã thành công. Từ người thứ 51 trở đi sẽ báo lỗi "Mã đã đạt giới hạn".
- **Lưu ý:** Nếu muốn mã có thể dùng không giới hạn, hãy bỏ trống trường này. Không áp dụng cho `testMode` và `admin`.

### `usedCount` (Number) - *Tùy chọn*
- **Ý nghĩa:** Bộ đếm lưu lại số lần mã này đã được sử dụng thành công.
- **Lưu ý:** Thường bạn khởi tạo là `0`. App sẽ tự động cộng dồn con số này lên sau mỗi lần có người nhập mã thành công. (Không tăng đối với `testMode` và `admin`).

### `expirationDate` (Timestamp) - *Tùy chọn*
- **Ý nghĩa:** Thời hạn **phải nhập mã**. Qua ngày giờ này, người dùng sẽ không thể dùng mã đó để nhận thưởng được nữa.
- **Ví dụ:** Event diễn ra đến ngày 31/12/2026. Bạn chọn Timestamp tương ứng vào field này.
- **Lưu ý:** Nếu muốn mã tồn tại vĩnh viễn không bao giờ hết hạn, chỉ cần không thêm trường này.

### `durationDays` (Number) - *Tùy chọn (Tính năng chuẩn bị thêm)*
- **Ý nghĩa:** Xác định **thời gian tận hưởng** phần thưởng tính từ lúc người dùng kích hoạt mã (áp dụng cho Premium hoặc Hiệu ứng). 
- **Ví dụ:** 
  - Nếu `durationDays = 15`: Người dùng nhận được Premium dùng trong 15 ngày, sau 15 ngày sẽ bị hủy.
  - Nếu `durationDays = 0.5`: Premium dùng trong nửa ngày (12 tiếng).
- **Lưu ý:** Nếu không thêm trường này (hoặc bỏ trống), quyền lợi sẽ có tác dụng **vĩnh viễn**. 

### `unlockedEffectId` (String) - *Bắt buộc nếu type là "giftEffect"*
- **Ý nghĩa:** Tên (ID) của hiệu ứng mà mã này sẽ tặng.
- **Ví dụ:** `"snow"`, `"hearts"`, `"fireworks"`, `"stars"`, v.v...

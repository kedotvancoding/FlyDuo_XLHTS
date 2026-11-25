# Hướng dẫn cài đặt NFIQ2 (Windows)

Người phụ trách: A8 - Lê Đức

## 1. Tải và cài đặt
1. Truy cập trang phát hành chính thức của NIST: https://github.com/usnistgov/nfiq2/releases
2. Mở mục **Assets** ở bản phát hành mới nhất (nhóm dùng `v2.3.0`) và tải file cài đặt Windows 64-bit (`nfiq2-2.3.0-win64.msi`).
3. Chạy file `.msi` để cài đặt (đường dẫn mặc định: `C:\Program Files\NFIQ 2\bin\nfiq2.exe`).

## 2. Cấu hình biến môi trường (PATH) hoặc `config.m`
Chọn 1 trong 2 cách:
- **Cách 1:** Thêm `C:\Program Files\NFIQ 2\bin` vào biến môi trường **Path** của Windows, sau đó khởi động lại MATLAB. ( nên dùng cách này)
- **Cách 2:** Khai báo trực tiếp đường dẫn trong `config/config.m`:
  ```matlab
  cfg.eval.useNFIQ2 = true;
  cfg.eval.nfiq2    = struct('exe', 'C:\Program Files\NFIQ 2\bin\nfiq2.exe');
  ```

## 3. Kiểm tra nhanh
Mở Command Prompt (CMD) và chạy lệnh hiển thị hướng dẫn để xác nhận đã cài xong:
```cmd
"C:\Program Files\NFIQ 2\bin\nfiq2.exe" -h
```
(Nếu đã thêm vào **Path** chỉ cần chạy `nfiq2 -h`).

Trong MATLAB chạy thử:
```matlab
params = struct('exe', 'C:\Program Files\NFIQ 2\bin\nfiq2.exe');
score = runNFIQ2('duong_dan_anh_van_tay.png', params);
```

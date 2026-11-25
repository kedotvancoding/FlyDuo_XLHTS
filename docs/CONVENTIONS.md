# CONVENTIONS — Quy ước chung nhóm FlyDuo

> Đọc trước khi viết code. Muốn đổi quy ước: báo A1, sửa file này, báo cả nhóm.
> Mọi con số/tham số nằm ở `config/config.m`, không nằm trong file này; siuuuuu

## 1. Kiểu dữ liệu

| Đối tượng | Quy ước |
|---|---|
| Ảnh `I` | `double`, H×W, ảnh xám 1 kênh, thang **[0, 1]** |
| `mask` | `logical` H×W, `true` = vùng có vân (ROI) |
| `theta` | `double` H×W, **radian, [0, π)**, là "hướng vân" (mục 2) |
| `coh` | `double` H×W, [0, 1], độ tin cậy của hướng |
| `freq` | `double` H×W, **chu kỳ/pixel**, nằm trong `cfg.freq.range` |
| `minu` | N×4 `double` = `[x y theta type]`; `type` 1 = đầu vân, 2 = chạc vân |
| Toạ độ | `x` = cột (sang phải), `y` = hàng (xuống dưới), bắt đầu từ 1 |

Ảnh, `mask`, `theta`, `coh`, `freq` luôn **cùng kích thước**. Ảnh sạch được chuẩn hoá một lần bằng `prepImage`; `mask` tính từ ảnh sạch (thí nghiệm tổng hợp) hoặc từ ảnh nhiễu (ảnh thật FVC2004).

## 2. Hướng vân (định nghĩa MỘT lần, mọi mô-đun dùng đúng như vậy)

- `theta` = góc của phương **vuông góc với đường vân** (chính là hướng gradient), đo từ trục **+x quay về phía +y** (chiều kim đồng hồ khi nhìn ảnh), lấy mod π. Đây đúng là φ trong mô hình mục 2.1 của báo cáo:
  `I(x,y) ≈ A·cos(2πf·(x·cosθ + y·sinθ) + ψ)`
  - `theta = 0`: vân thẳng đứng (gradient nằm ngang). `theta = π/2`: vân nằm ngang.
- **Toạ độ xoay dùng khi cài kernel** (với `[X,Y] = meshgrid(-r:r)`):

```matlab
xp =  X*cos(theta) + Y*sin(theta);   % vuông góc vân: dải thông / cos nằm ở đây
yp = -X*sin(theta) + Y*cos(theta);   % dọc theo vân: thông thấp hẹp
% Gabor : g = exp(-(xp.^2+yp.^2)/(2*sigma^2)) .* cos(2*pi*f*xp)
% FIR-W : K = h_bp(xp) * h_lp(yp)
```

- Ước lượng (A4): gradient Sobel `gx` (theo cột), `gy` (theo hàng) → `Gxx, Gyy, Gxy` cộng theo khối ~16×16 → **`theta = 0.5*atan2(2*Gxy, Gxx-Gyy)`** → làm mượt trên `(cos2θ, sin2θ)`. **Không cộng π/2.**
- Sai khác góc giữa hai hướng: `d = abs(mod(a - b + pi/2, pi) - pi/2)`.

## 3. Chữ ký hàm

| Hàm | Chữ ký |
|---|---|
| `prepImage` | `I = prepImage(src, params)` (src = đường dẫn hoặc ma trận) |
| `roiMask` | `mask = roiMask(I, params)` |
| `addNoise` | `I_noisy = addNoise(clean, type, level, seed)` — `level` = 1, 2, 3 (giá trị thật lấy từ `cfg.noise`); đầu ra đã cắt về [0,1] |
| `spectrum2D` | `[S, fx, fy] = spectrum2D(I, doPlot)` |
| `estOrient` | `[theta, coh] = estOrient(I, mask, params)` |
| `estFreq` | `freq = estFreq(I, mask, theta, params)` |
| **mọi bộ lọc** | **`I_enh = filterX(I, mask, theta, freq, params)`** |
| `designBP` | `h = designBP(f1, f2, N, win)` — `f` chu kỳ/mẫu, `N` lẻ, `win` ∈ `rect/bartlett/hann/hamming/blackman` |
| `gaborKernel` | `g = gaborKernel(theta, f, params)` |
| `gaborBank` | `bank = gaborBank(params)` |
| `postprocess` | `[minu, skel] = postprocess(I, mask, params)` |
| `matchMinutiae` | `[P, R, F1, nMatch] = matchMinutiae(minuTest, minuRef, params)` |
| `evalQuality` | `q = evalQuality(I_enh, I_ref, mask)` → `q.psnr`, `q.ssim` |
| `runNFIQ2` | `score = runNFIQ2(I, params)` |
| `zeroPad` | `[Ip, info] = zeroPad(I, padSize)`; cắt lại bằng `Ip(info.rows, info.cols)` |

Bộ lọc nhận `params = cfg.filters.<tên>`; trả về `double`, cùng kích thước `I`, không NaN. `run_all` tự cắt kết quả về [0,1].
**Thêm bộ lọc mới:** tạo `filterX.m` trong `src/filters/` → thêm 1 dòng vào hàm `filterMap()` ở cuối `run_all.m` → thêm `cfg.filters.<tên>` trong `config.m`.

## 4. Seed và tái lập

- `seed = cfg.seedFor(imgIdx, typeIdx, level)`; `imgIdx` = thứ tự ảnh trong file danh sách, `typeIdx` = vị trí trong `cfg.noise.typesAll`.
- Hàm sinh ngẫu nhiên gọi `rng(seed,'twister')` ngay đầu hàm; không dùng `rand/randn` ngoài seed này.
- Cùng seed + cùng đầu vào ⇒ kết quả giống hệt nhau (có test kiểm tra).

## 5. Tập dữ liệu

- `data/lists/*.csv` có cột `file` (đường dẫn tương đối trong `data/raw/`), nên thêm `subject, finger, nfiq2`.
- Tuning 10 ảnh, test ≥ 30 ảnh, khác ngón. **Chỉnh tham số chỉ trên tuning.** `run_all` ở stage `M1/M2` chỉ chạy trên tuning; chỉ chạy `'FINAL'` (tập test) sau khi đóng băng `config.m` (tag Git `freeze`).
- **Không commit ảnh** (`data/raw/` nằm trong `.gitignore`), chỉ commit danh sách.

## 6. Quy tắc viết mã

1. Mỗi hàm `.m` có comment đầu file: mô tả 1 dòng, chữ ký, đầu vào (kiểu, kích thước, thang), đầu ra, người phụ trách.
2. Mỗi mô-đun có test trong `tests/` (script, in `PASS` hoặc `error`, chạy được từ bất kỳ thư mục nào). Tên file test theo tree: `test_addNoise`, `test_estOrient`, `test_gabor`, `test_butter`.
3. Không hard-code tham số trong hàm: lấy từ `params` (do `config.m` cấp). Ablation chỉ cần sửa field của `cfg`.
4. **Stub:** `run_all.m` có sẵn stub nội bộ (các hàm `stub_*` ở cuối file) cho mọi hàm trong mục 3. Chưa có file thật trong `src/` thì dùng stub; thả file thật vào `src/` (đúng tên, đúng chữ ký) là `run_all` tự dùng, không cần sửa gì. Đầu mỗi lần chạy `run_all` in bảng `STUB / ok` cho từng mô-đun.
5. Chỉ dùng Image Processing + Signal Processing Toolbox. Nếu MATLAB hiển thị sai tiếng Việt trong comment, lưu file ở dạng UTF-8.

## 7. Git

- Mỗi người một nhánh (`a2-data`, `a3-noise`, ...), mở Pull Request về `main`, A1 duyệt và gộp. PR cần: đúng chữ ký (mục 3), có test PASS, không hard-code tham số, không có ảnh hoặc `.asv`.
- Tag: `M1`, `M2`, `M3`, và `freeze` (trước khi chạy tập test).


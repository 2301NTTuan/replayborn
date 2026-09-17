# Replayborn — Kế hoạch production

Cập nhật: 2026-09-13. Engine: Godot 4.7.2, GDScript, Mobile renderer.

## Định hướng và phạm vi

Game roguelite sinh tồn 2D dọc, chơi đơn offline. Giả định hiện tại: ưu tiên Android, Windows phục vụ phát triển và chơi thử; cần xác nhận trước khi chuẩn bị phát hành.
Không quảng cáo, mua hàng, online. Không commit/push khi chưa được người dùng cho phép.
Canvas 1080×1920. Nhân vật tự bắn; mỗi 15 giây tạo bản sao lặp lại vị trí, thời điểm, nguồn và hướng bắn. Tối đa 4 bản sao, thay bản cũ nhất.
Bản sao không nhận sát thương. Định hướng nâng cấp: giữ thông số vũ khí tại thời điểm ghi; triển khai khi xây hệ thống vũ khí.
Trận 1.0 dự kiến 10–15 phút, kết thúc bằng boss hoặc thất bại.
Phạm vi đề xuất: 1 nhân vật, 1 đấu trường, 3 vũ khí, 5 loại địch, 2 biến thể tinh anh, 1 boss, khoảng 15 nâng cấp.

## M1 — Thiết kế và bản chơi thử 5 phút

- [x] Prototype di chuyển, tự bắn, truy đuổi, ghi/phát lại và HUD.
- [x] Lưu kế hoạch và phạm vi dự kiến vào repository.
- [x] Joystick cảm ứng, pause/resume, tự pause khi mất focus.
- [x] Tiến trình ghi, thông báo tạo/thay bản sao, nút chơi lại cảm ứng.
- [x] Ba loại địch: chaser, runner, charger có báo hướng trước khi lao.
- [x] Nâng cấp mỗi 30 giây (tốc bắn, tốc chạy, hồi máu), kết quả thắng sau 5 phút.
- [x] Phản hồi bắn trúng bằng hình ảnh và âm thanh tổng hợp (chưa đánh giá nghe/nhìn thực tế).
- [ ] Chơi thử trên Android và kiểm chứng người mới hiểu chiến thuật bản sao.

Nghiệm thu: chơi trọn 5 phút bằng cảm ứng, đọc được màn hình khi đông, người mới hiểu đường đi và hướng bắn đã ghi ảnh hưởng bản sao. Điều chỉnh core loop trước khi mở rộng nội dung.

## M2 — Nền tảng production

Tách trạng thái trận, combat, vũ khí, sát thương, ghi/phát lại. Dùng tick vật lý cho timeline. Quy định pause, chết, thay bản sao. Cấu hình nội dung bằng Resources. Lưu thiết lập/tiến trình có phiên bản và phục hồi file hỏng. Đo hiệu năng trước khi pooling. Tự động kiểm thử và quy trình build debug/release.
Nghiệm thu: hệ thống độc lập đủ để thêm nội dung không sửa bộ điều phối trận; kiểm tra lưu và replay qua các trường hợp biên.

## M3 — Nội dung hoàn chỉnh

Hoàn thiện phạm vi 1.0, nhịp trận và boss. Menu, hướng dẫn, thiết lập, kết quả, mở khóa. Art/VFX/audio thống nhất. Safe area, tỷ lệ màn hình, cỡ chữ, giảm rung/hiệu ứng và âm lượng. Chuỗi giao diện hỗ trợ Việt/Anh.
Nghiệm thu: từ menu tới kết quả, mở lại vẫn giữ tiến trình đúng.

## M4 — Cân bằng, hiệu năng và QA

Đo tình huống 4 bản sao và đông địch/đạn trên thiết bị tham chiếu. Mục tiêu sơ bộ 60 FPS; chốt ngân sách bộ nhớ/thời gian tải sau đo M1. Kiểm tra nền/khóa máy/âm thanh, nhiều trận liên tục, chết tại ranh giới ghi, dữ liệu hỏng và nâng cấp kết hợp.
Nghiệm thu: không crash/mất dữ liệu/chặn trận; đạt ngân sách thiết bị đã chọn; người ngoài nhóm chơi hiểu cơ chế.

## M5 — Phát hành 1.0

Khóa tính năng, chỉ sửa lỗi/cân bằng. Chuẩn bị build ký, icon, ảnh giới thiệu, thông tin hỗ trợ, giấy phép asset và phiên bản. Kiểm tra bản release độc lập editor. Phát hành cần quyết định nền tảng/tài khoản và sự cho phép của chủ project.

## Ước lượng và thứ tự

12–18 tuần chỉ là ước lượng ban đầu cho một lập trình viên toàn thời gian có hỗ trợ mỹ thuật/âm thanh giới hạn; đánh giá lại sau M1. Thứ tự M1 → M2 → M3 → M4 → M5; nền tảng cần cho M1 được làm ngay trong M1.
Rủi ro chính: bản sao khó đọc/ít chiến thuật, cảm ứng khó tránh địch, tải đạn tăng, khối lượng asset. Giảm rủi ro bằng playtest M1 và đo thiết bị thật trước khi mở rộng.

## Nhật ký triển khai

- 2026-09-13: bắt đầu M1 — điều khiển cảm ứng, pause/resume, HUD tiến trình và thao tác chơi lại. Các mốc còn lại chưa hoàn thành.

- Kiểm chứng đợt đầu: Godot 4.7.2 import sạch; prototype_smoke và session_smoke PASS (75 giây ghi, giới hạn bản sao, cảm ứng, pause/resume, mất focus, game over). Chưa kiểm chứng cảm ứng trên thiết bị Android thật. Tiếp theo: 3 loại địch và nhịp trận 5 phút.


- Đợt 2: ba loại địch, spawn tăng từ 0.85 xuống 0.28 giây, phản hồi trúng đạn, 9 lựa chọn nâng cấp và chiến thắng 300 giây. run_smoke PASS kiểm tra tiến trình, upgrade/pause, chiến thắng và telegraph/dash. Prototype/session smoke vẫn PASS. Đây là kiểm thử logic có bỏ sát thương lên người chơi, không thay thế playtest cân bằng. Âm thanh, Android thật, art và các mốc M2–M5 vẫn còn.


- Đợt 3: 7 âm thanh tổng hợp, vòng báo nhận sát thương, hiệu ứng trúng đạn có giới hạn 64, hướng dẫn trong pause, mute và reduce effects trong trận. Sửa nhãn nâng cấp thành giảm chu kỳ bắn 12% cho đúng công thức; kết quả thua có thời gian. Ba bộ smoke và import Godot 4.7.2 sạch; test mute/reduce effects PASS. Thiết lập chưa lưu qua restart; phần lưu thuộc M2. Còn nghiệm thu nghe/nhìn và Android thật; không đánh dấu M1 hoàn tất.

- Đợt 4: thêm 10 map dữ liệu hóa, mỗi map có bảng thứ tự quái, màu nền, nhịp spawn và hệ số boss riêng. Trận thường có 10 level; mỗi level kết thúc bằng một boss, hạ boss mới mở level tiếp theo. Map cuối thắng sau boss level 10; Practice vẫn là chế độ 5 phút. Menu đã có chọn map. Resource validation 65 file/0 lỗi; prototype/session/run smoke PASS.

- Đợt 5: thêm meta progression offline: loadout áo/quần/giày/giáp/vũ khí, 5 bậc hiếm, mảnh theo slot, lõi nâng cấp chung, vàng, nhiệm vụ nhận thưởng, rương miễn phí theo chu kỳ và rương mở bằng vàng. Trang phục giáp/giày đã ảnh hưởng trực quan nhân vật. Chưa kết nối payment thật; cần quyết định store/provider và quy trình pháp lý trước khi làm phần đó.


- Trạng thái cập nhật: bản 0.5.0-alpha.1 khóa release slice ở Astria và Neon Ruins; menu không còn quảng bá nhân vật/map chưa tác động gameplay. 15 nâng cấp, 5 loại địch, 2 elite và 5 boss vẫn được giữ. Echo ghi theo tape 900 physics ticks, tối đa 4 Echo cùng tồn tại, tape thứ năm thay Echo cũ nhất. Normal run có năm level hai phút trước boss (mục tiêu 8–12 phút cả giao chiến); Practice 5 phút. Gold trong combat chỉ lưu tại mốc an toàn. Export dùng standard Godot templates, AAB unsigned cho release và APK debug riêng; preview/anime và asset pack không rõ license bị loại khỏi export. Chưa phải release production: cần chạy toàn bộ validation bằng Godot 4.7.2, playtest Android, đo lại p95 trên máy thật, Android SDK/JDK chuẩn và keystore phát hành.


extends RefCounted

const TEXT: Dictionary = {
"tagline": ["CHIẾN ĐẤU CÙNG QUÁ KHỨ", "FIGHT ALONGSIDE YOUR PAST"],
"start": ["BẮT ĐẦU", "START RUN"], "practice": ["Tập luyện · 5 phút", "Practice · 5 minutes"],
"settings": ["Thiết lập", "Settings"], "help": ["Cách chơi", "How to play"], "back": ["Trở lại", "Back"],
"pause": ["Tạm dừng", "Pause"], "resume": ["Tiếp tục", "Resume"], "restart": ["Chơi lại", "Restart"],
"home": ["Về menu", "Main menu"], "quit": ["Thoát game", "Quit"], "choose": ["CHỌN NÂNG CẤP", "CHOOSE AN UPGRADE"],
"win": ["ĐÃ PHÁ VỠ VÒNG LẶP", "LOOP BROKEN"], "lose": ["VÒNG LẶP KẾT THÚC", "LOOP ENDED"],
"volume": ["Âm thanh", "Sound effects"], "music": ["Nhạc nền", "Music"], "reduced": ["Giảm hiệu ứng", "Reduce effects"],
"language": ["Ngôn ngữ / Language", "Language / Ngôn ngữ"], "new_echo": ["BẢN SAO ĐÃ SẴN SÀNG", "ECHO ONLINE"],
"replace_echo": ["ĐÃ THAY BẢN SAO CŨ NHẤT", "OLDEST ECHO REPLACED"],
"boss": ["KẺ CANH GIỮ VÒNG LẶP", "THE LOOP WARDEN"],
"record": ["GHI", "REC"], "kills": ["Hạ gục", "Kills"], "time": ["Thời gian", "Time"],
"hint": ["Chạm và rê ở bất kỳ đâu trong đấu trường · Tự bắn · ESC tạm dừng", "Touch and drag anywhere in the arena · Auto fire · ESC pause"],
"help_body": ["Di chuyển bằng WASD hoặc chạm và rê ở bất kỳ đâu trong đấu trường. Nhân vật tự bắn mục tiêu gần nhất.\n\nMỗi 15 giây tạo một bản sao lặp lại đường đi và các phát bắn của bạn. Tối đa 4 bản sao; bản mới thay bản cũ nhất. Bản sao giữ sức mạnh của từng phát bắn lúc ghi.\n\nMỗi 30 giây chọn một nâng cấp. Né đường lao tím và đạn đỏ. Sau 10 phút, đánh bại Kẻ Canh Giữ để chiến thắng; giới hạn trận là 15 phút.\n\nChế độ tập luyện kết thúc ở phút thứ 5, không lưu thành tích. R chơi lại khi đang chơi hoặc tạm dừng.", "Move with WASD or touch and drag anywhere in the arena. Fire automatically at the nearest enemy.\n\nEvery 15 seconds, an echo repeats your path and shots. Up to 4 echoes; the oldest is replaced. Each shot keeps its recorded power.\n\nChoose an upgrade every 30 seconds. Dodge purple charge lines and red bullets. Defeat the Warden after 10 minutes to win; the run ends at 15 minutes.\n\nPractice ends at 5 minutes and does not save records. R restarts while playing or paused."],
"ready": ["Đã hiểu · Vào trận", "Got it · Enter arena"],
"save_failed": ["Không lưu được dữ liệu. Kiểm tra quyền ghi và dung lượng đĩa.", "Could not save. Check disk space and write permissions."],
"save_recovered": ["Đã phục hồi dữ liệu từ bản sao lưu.", "Profile recovered from backup."],
"save_reset": ["Dữ liệu lưu không hợp lệ; đang dùng thiết lập mặc định.", "Invalid save data; using defaults."],
"records": ["%d trận  /  %d thắng  /  %d hạ gục", "%d runs  /  %d wins  /  %d kills"],
"weapon": ["CHỌN VŨ KHÍ", "CHOOSE WEAPON"], "pulse": ["Xung lực", "Pulse"], "scatter": ["Tán xạ", "Scatter"], "lance": ["Xuyên phá", "Lance"],
"character": ["CHỌN NHÂN VẬT", "CHOOSE CHARACTER"],
"map": ["CHỌN BẢN ĐỒ", "CHOOSE MAP"],
"level": ["MỨC ĐỘ %d / 10", "LEVEL %d / 10"],
"boss_arrives": ["CẢNH BÁO · BOSS CỦA MỨC ĐỘ %d", "WARNING · LEVEL %d BOSS"],
"level_cleared": ["ĐÃ HẠ BOSS · MỞ KHÓA MỨC ĐỘ %d", "BOSS DEFEATED · LEVEL %d UNLOCKED"],
"pulse_desc": ["Cân bằng · đạn đơn · 0,28 giây", "Balanced · single shot · 0.28 seconds"],
"scatter_desc": ["Cận chiến · 3 đạn · 0,65 giây", "Close range · 3 pellets · 0.65 seconds"],
"lance_desc": ["Tầm xa · xuyên 3 mục tiêu · 0,7 giây", "Long range · pierces 3 targets · 0.7 seconds"],
"stage": ["GIAI ĐOẠN %d", "PHASE %d"], "result": ["%02d:%02d  ·  %d hạ gục", "%02d:%02d  ·  %d kills"],
"abandon": ["Rời trận hiện tại? Tiến trình trận sẽ mất.", "Leave this run? Current run progress will be lost."],
"confirm": ["Đồng ý", "Confirm"], "cancel": ["Hủy", "Cancel"]
}

static func get_text(key: String, language: String = "vi") -> String:
	var pair: Array = TEXT.get(key, [key, key])
	return pair[1 if language == "en" else 0]

# Satria Gambut V9 — Redesain UI Jungle Sawit

## Perubahan
- **Papan kayu 3D jungle sawit** (`ui/common/jungle_board_3d.gd`): papan, rangka log, tali, pelepah sawit, tandan buah, dan sulur dirakit prosedural (low-poly). `ui/common/jungle_board.gd` (`JungleBoard`) merendernya sekali ke tekstur (di-cache per ukuran) lalu dipakai sebagai latar teks. Cukup `add_child` label ke `JungleBoard`.
- **Font**: Lilita One (judul/tombol) dan Barlow Condensed (teks), keduanya SIL OFL 1.1, di `assets/fonts/`. Dicatat di Credits.
- **Tema global** `ui/common/satria_theme.tres` (didaftarkan di `project.godot`), dibuat dari `ui/common/ui_style.gd`. Regenerasi: `godot --headless -s res://ui/common/theme_builder.gd`.
- **HUD gameplay** (`ui/hud/hud.gd`) dibangun ulang dengan jangkar sudut layar sehingga selalu selebar jendela (tidak lagi bergantung ukuran total panel): radar bulat + angin, hotbar alat bulat, pengukur air melingkar, tag petak hanya saat ada hal penting, dan toast papan kayu.
- **Misi** (`simulation/mission_director.gd`): panel padat diganti kartu papan kayu berisi target hotspot, progres, dan satu petunjuk.
- **Menu utama**: layout berjangkar (sebelumnya skala tetap 1280x720 yang meluber di layar lebar); tombol berupa papan kayu.
- Modal menu, jeda, evaluasi, dan perencanaan memakai tema baru (override StyleBox lama dihapus).

## Informasi yang dihapus dari HUD
Cuaca panjang, statistik API/BARA/AMAN/HANGUS, logistik sumur, baris kontrol permanen, PFVI/kedalaman gambut di panel petak. Data ilmiahnya tetap muncul di layar evaluasi.

## Verifikasi visual
`godot --path . -s res://tests/ui_shot.gd -- res://scenes/main_simulation.tscn [fire|planning|pause|victory]` menyimpan tangkapan layar ke `tests/shots/` (diabaikan git).

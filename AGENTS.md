# 🤖 AGENTS.MD — Prosedur Operasional Agen (SOP): Satria Gambut

Dokumen ini merupakan panduan teknis operasional bagi Agen AI dalam membaca, membuat, dan memodifikasi file pada proyek **Satria Gambut**.

---

## 📁 1. STRUKTUR DIREKTORI & TANGGUNG JAWAB FITUR

Setiap penambahan fitur baru wajib ditempatkan pada folder domain yang sesuai:

* **`core/`**:
  * Berisi sistem global (*Autoloads*) dan infrastruktur dasar.
  * `event_bus.gd`: Pusat deklarasi sinyal global.
  * `game_state.gd`: Pengelola data runtime global, skor, settings grafis, dan volume audio.
* **`simulation/model/`**:
  * Berisi logika murni, data class, dan rumus matematika.
  * Bebas dari dependensi visual/3D node.
  * Wajib bertipe statis (`Vector2i`, `float`, `int`, `bool`).
* **`simulation/view/`**:
  * Mengelola tampilan 3D, terrain mesh, kamera isometrik, raycasting kursor mouse, dan efek visual/partikel.
* **`tools/`**:
  * Mengelola state alat pemadam (Sekat Bakar, Semprot Permukaan, Tombak Gambut, Thermal Vision).
* **`ui/`**:
  * Komponen antarmuka (HUD, Main Menu, Credits, Settings).
  * Terhubung secara longgar (*loose coupling*) via sinyal `EventBus`.
* **`scenes/`**:
  * Scene gabungan (*assembler*) yang mengikat model, view, tools, dan UI.
* **`assets/`**:
  * `textures/`: Gambar 2D, logo, ikon.
  * `models/`: Model 3D format `.glb` / `.gltf`.
  * `audio/`: Efek suara format `.wav` (mono) dan `.ogg` (stereo).

---

## 📝 2. CHECKLIST PEMBUATAN SCRIPT BARU (SOP)

Sebelum membuat atau mengubah script GDScript, Agen wajib memverifikasi:

1. **Header Comment Wajib:**
   Baris 1 wajib berisi komentar penjelasan singkat fungsi file:
   ```gdscript
   # core/event_bus.gd - Pusat sinyal global untuk komunikasi decoupled antar-sistem Satria Gambut.
   ```
2. **Larangan Komentar Tambahan:**
   Pastikan tidak ada komentar penjelas di atas method/fungsi (`# fungsi untuk...`) atau di dalam blok kode.
3. **Strict Typing:**
   Gunakan type hint di semua variabel, parameter, dan return value:
   ```gdscript
   func apply_water(amount: float) -> bool:
   ```
4. **Penamaan Sinyal:**
   Gunakan kata kerja bentuk lampau (*past-tense*) atau perubahan keadaan:
   ```gdscript
   signal cell_state_updated(pos: Vector2i, cell_data: PeatCellData)
   signal tool_changed(new_tool_id: int)
   ```

---

## 🎨 3. STANDAR ASET & ATRIBUSI CREDITS

1. **Format 3D:** Format `.glb` (binary GLTF) dengan poligon rendah (*low-poly*).
2. **Lisensi Aset:** Wajib berlisensi CC0 (Public Domain) atau CC-BY.
3. **Atribusi Wajib:** Jika menambahkan aset pihak ketiga berlisensi CC-BY, catat nama kreator dan tautan sumbernya untuk dicantumkan pada scene `ui/credits/credits.tscn` dan dokumen laporan tugas akhir.

# 🎮 GEMINI.MD — Aturan & Konstitusi Agen AI: Satria Gambut

> **Nama Proyek:** Satria Gambut (Interactive Computer Graphics Peatland Fire Simulation)  
> **Engine:** Godot Engine 4 (GDScript)  
> **Platform Target:** PC Windows Desktop (Offline & Standalone)  
> **Target Perangkat:** Kompatibel di berbagai spek laptop (Laptop Biasa/Non-Gaming dengan GPU terintegrasi hingga Laptop Gaming)  

---

## 🚨 1. ATURAN MUTLAK PENULISAN KODE (STRICT CODING RULES)

1. **Aturan Komentar Kode (WAJIB DIPATUHI):**
   - **Komentar HANYA DIIZINKAN di baris paling atas setiap file (`# ...`)**, yang menjelaskan identitas file dan perannya dalam arsitektur sistem.
   - 🚫 **DILARANG KERAS menuliskan komentar di setiap fungsi atau baris per baris**.
   - Kode harus bersifat *self-documenting*: gunakan penamaan fungsi yang jelas, penamaan variabel deskriptif, dan *strict static typing* (`var water: float = 100.0`, `func do_something() -> void:`).

2. **Format dan Penamaan File:**
   - Gunakan format **`snake_case`** untuk semua file skrip (`.gd`), scene (`.tscn`), dan resource (`.tres`).
   - Gunakan **`PascalCase`** untuk nama Class (`class_name PeatCellData`) dan nama Node di dalam scene tree.
   - Scene wajib disimpan dalam format teks (`.tscn`), bukan biner (`.scn`). Resource wajib disimpan sebagai `.tres`.

---

## 🏗️ 2. PRINSIP ARSITEKTUR GODOT 4

1. **"Call Down, Signal Up" (Decoupling):**
   - Parent boleh memanggil method anak secara langsung (`$Child.action()`).
   - Anak **tidak boleh** memanggil atau mengetahui parent-nya secara langsung (dilarang menggunakan `get_parent().get_parent()`).
   - Anak harus memancarkan sinyal (`signal_name.emit()`) saat terjadi perubahan status.

2. **Event Bus Pattern:**
   - Semua komunikasi antar-sistem yang posisinya berjauhan wajib melalui `EventBus` (`core/event_bus.gd`).
   - UI HUD tidak boleh memegang referensi langsung ke 3D World atau Model simulasi; HUD hanya mendengarkan sinyal dari `EventBus`.

3. **Pemisahan Model dan View pada Simulasi Grid:**
   - **Model (`simulation/model/`):** Logika grid, perhitungan rambatan api, dan kalkulasi rumus PFVI dihitung murni di memori (menggunakan `Dictionary[Vector2i, PeatCellData]` atau array).
   - **View (`simulation/view/`):** Objek 3D hanya berfungsi menampilkan visual. Jangan pernah membuat "1 Petak = 1 Node3D" karena akan menyebabkan lag pada laptop spek rendah. Gunakan mesh plane terpadu atau `MultiMeshInstance3D`.

4. **Kemandirian Scene (Scene Autonomy):**
   - Setiap scene harus bisa dijalankan secara mandiri dengan menekan tombol `F6` untuk kemudahan pengetesan dan kolaborasi tim.

---

## 🔬 3. PARAMETER ILMIAH RISET GAMBUT (ITB–NOTTINGHAM–IPB)

Simulasi ini bukan sekadar permainan pemadaman api biasa, melainkan implementasi sains:
1. **4 Variabel Input Utama:**
   - `water_table` (WT, cm): Kedalaman muka air tanah.
   - `soil_moisture` (SM, 0.0 - 1.0): Tingkat kelembapan gambut.
   - `rainfall` (RF, mm/hari): Curah hujan.
   - `temperature` (Temp, °C): Suhu udara lingkungan.
2. **Indeks Kerawanan PFVI (Peat Fire Vulnerability Index):**
   - **Rendah (0–75):** Gambut basah; api tidak menjalar signifikan.
   - **Sedang (76–150):** Mulai kering; api permukaan dapat merambat.
   - **Tinggi (151–225):** Rawan; bara dapat menembus ke bawah tanah.
   - **Ekstrem (226–300+):** Kritis (seperti kasus Sabangau 282); percikan kecil langsung memicu kebakaran hebat.
3. **Mekanik Edukasi Kunci (Bara Bawah Permukaan / Subsurface Smoldering):**
   - Api permukaan (`surface_fire`) dipadamkan dengan **Nozzle Semprot Permukaan**.
   - Jika petak memiliki bara bawah tanah (`subsurface_ember`), penyemprotan permukaan **tidak akan mematikan bara**. Bara akan menyala ulang (*re-ignition*) atau merembet di kedalaman gambut.
   - Pemain wajib menggunakan **Tombak Gambut (Peat Spear)** untuk menginjeksi air ke kedalaman tanah gambut (`peat_depth`).
   - Mode **Thermal X-Ray** digunakan untuk mendeteksi bara yang tak terlihat di permukaan.

---

## 💻 4. OPTIMASI UNTUK SPEK LAPTOP CAMPURAN

1. **Renderer:** Menggunakan `gl_compatibility` (Compatibility mode) atau `mobile` di `project.godot`.
2. **Visual Style:** *Low-Poly Stylized* (bebas dari tekstur resolusi tinggi 2K/4K).
3. **Partikel:** Kendalikan *overdraw* transparansi partikel asap dan api; kombinasikan dengan *fog* atmosfer bawaan engine.
4. **Settings:** Sediakan pengaturan kualitas grafis di `GameState` (Low / Medium / High).

# Satria Gambut 🌿🔥

<p align="center">
  <img src="assets/textures/satria_gambut_logo.jpg" alt="Logo asli Satria Gambut" width="260" />
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Engine-Godot%204.7.2-478CBF?style=flat-square&logo=godotengine&logoColor=white" alt="Godot 4.7.2" />
  <img src="https://img.shields.io/badge/Language-GDScript-355570?style=flat-square" alt="GDScript" />
  <img src="https://img.shields.io/badge/Renderer-GL%20Compatibility-558B2F?style=flat-square" alt="GL Compatibility" />
  <img src="https://img.shields.io/badge/Platform-Windows-0078D6?style=flat-square" alt="Windows" />
  <img src="https://img.shields.io/badge/Mode-Offline-2E7D32?style=flat-square" alt="Offline" />
  <img src="https://img.shields.io/badge/Development-V8.6%20Cinematic%20Menu-F57C00?style=flat-square" alt="Development V8.6" />
</p>

> [!IMPORTANT]
> **Status repository:** README di branch `main` ini merupakan **dokumentasi proyek dan rangkuman perkembangan hingga V8.6**. Implementasi fitur-fitur terbaru masih berada pada branch pengembangan **[`feature/animated-outpost-modern-menu-arrow-v8-6`](https://github.com/AlGibran18/ProjekAkhir-KomGraf-SatriaGambut/tree/feature/animated-outpost-modern-menu-arrow-v8-6)** dan **[draft Pull Request #18](https://github.com/AlGibran18/ProjekAkhir-KomGraf-SatriaGambut/pull/18)**. **Kode di `main` belum otomatis mencakup semua fitur di bawah ini**. Untuk mencoba versi terkini, gunakan branch V8.6, bukan ZIP `main`. Pengujian keseluruhan V8.6 dan merge final belum dinyatakan selesai.

## Tentang game

**Satria Gambut** adalah proyek akhir Grafika Komputer berupa **simulasi 3D pemantauan risiko, pengendalian, dan pemadaman kebakaran lahan gambut** berbasis Godot Engine dan GDScript. Pemain bertugas meninjau peta risiko, mengatur sumber air, memasuki hutan, memadamkan api permukaan serta bara yang tersembunyi di bawah gambut, dan melindungi pos pengamatan.

Game dapat dimainkan **secara offline**. Visualisasi risiko menggunakan **Peat Fire Vulnerability Index (PFVI)** sebagai pendekatan edukatif, bukan prediksi lapangan yang sudah tervalidasi. Dunia simulasi dibagi menjadi **16 × 16 petak** berukuran **3 m × 3 m**; setiap petak memiliki parameter seperti muka air tanah, kelembapan, hujan, suhu, ketebalan gambut, dan kondisi api.

### Alur permainan

1. **Pilih skenario** pada menu utama dan tinjau tujuan operasi.
2. **Perencanaan taktis:** periksa peta PFVI, cuaca, dan tentukan lokasi sumur air portabel.
3. **Operasi lapangan:** masuk ke hutan melalui kamera FPS atau TPP; buat sekat api, semprot kebakaran permukaan, cari bara bawah gambut dengan Thermal, lalu lakukan injeksi air.
4. **Navigasi dan pemantauan:** baca tactical radar, buka peta besar, gunakan panduan arah H, dan awasi stok air, hotspot, risiko, cuaca, dan karbon.
5. **Evaluasi:** selesaikan misi sampai menang/kalah **atau hentikan secara sukarela** untuk melihat hasil sementara. Lihat grafik perubahan kondisi dan ekspor laporan misi.

## Fitur utama (versi pengembangan terbaru)

### Simulasi kebakaran & strategi
- **Model PFVI** untuk kategori risiko gambut, visualisasi peta perencanaan, dan informasi per petak.
- **Cellular automata**: penyebaran api dipengaruhi kondisi gambut, kelembapan, angin, dan hujan; api permukaan dan bara bawah tanah ditangani secara berbeda.
- **Tiga alat pemadaman**: `[1]` Sekat Api, `[2]` Semprot Air, dan `[3]` Tombak Gambut untuk injeksi bawah permukaan.
- **Mode Thermal `[Tab]`** untuk menampilkan risiko dan mendeteksi bara tersembunyi.
- **Pengelolaan air**: kapasitas tangki, sumur portabel dengan cadangan terbatas, dan pengisian ulang `[E]` saat dekat sumur.
- **Tiga skenario**: *Bara Tersembunyi (Tutorial)*, *Sabangau Kritis (PFVI 282)*, dan *Musim El Niño (Ekstrem)*.

### Eksplorasi, karakter & lingkungan 3D
- **FPS / TPP `[V]`**: perpindahan sudut pandang mata ke kamera belakang karakter menggunakan SpringArm3D.
- **Karakter petugas pemadam 3D** dengan helm, visor, rompi, strip reflektif, radio, perlengkapan, dan tangki punggung.
- **Animasi prosedural alat** dalam FPS/TPP: semprot air dan partikel nozzle, ayunan saat membuat sekat api, serta pose injeksi gambut; arah tangan dan alat disesuaikan dengan petak bidikan.
- **Kustomisasi penampilan**: empat warna seragam dan empat pilihan helm (**16 kombinasi**). Bisa diatur dari menu atau saat Pause dan tersimpan lokal.
- **Hutan yang lebih hidup**: vegetasi, hembusan angin, asap, partikel, efek api/bara, hujan dan perubahan tampilan tanah basah.
- **Posko operasi yang dapat dimasuki** dengan meja, radio, papan taktis, perlengkapan, lampu indikator, dan **pintu otomatis beranimasi**. Pintu membuka ketika pemain mendekat, bertahan terbuka selama pemain di dalam/dekat posko, dan baru menutup setelah area aman. Mekanisme tombol F manual **sudah dihapus**.

### HUD, peta & navigasi
- **Modern Tactical HUD**: kartu informasi air, suhu, angin, hujan, hotspot, bara, lahan aman, logistik, dan kondisi petak dengan visual bergaya game modern.
- **Tactical Radar / minimap** dengan penanda posisi dan arah pemain, api, sumur, pos, serta efek radar dan peringatan.
- **Peta operasi besar `[M]`** untuk membaca kondisi hutan dan penanda misi.
- **Panduan navigasi `[H]`**: beralih antara OFF → Hotspot → Sumur Air → Pos Pengamatan → OFF.
- **Panah tujuan beranimasi** pada peta/radar, serta **panah 3D berujung segitiga** yang mengikuti kamera FPS/TPP.
- **Pengaturan tampil/sembunyi panah depan pemain** melalui Pengaturan atau Pause; penunjuk pada peta tetap tersedia walaupun panah 3D disembunyikan.
- **Perubahan cuaca selama misi** dan panel objektif/tutorial sebagai bantuan pengambilan keputusan.

### Audio & pengalaman visual
- **Dua musik instrumental orisinal** yang dihasilkan secara prosedural: suasana menu lebih tenang dan gameplay lebih bersemangat. Musik diatur relatif pelan agar efek lingkungan tetap terdengar.
- **Audio lingkungan**: angin, hujan, kebakaran, semprotan air, dan suara guntur; beberapa efek menggunakan penempatan suara 3D.
- **Efek badai dan petir**: kilatan langit, petir bercabang, guntur tertunda, dan cipratan hujan; `[F9]` untuk pratinjau petir.
- **Cinematic Mode `[F10]`** untuk menjelajah/menangkap gambar tanpa HUD.
- **Screenshot `[F12]`** tersimpan sebagai PNG di `user://screenshots`.
- **Fullscreen `[F11]`**, penanganan fokus mouse, jendela yang dapat diubah ukuran, dan preset kualitas grafis Low / Medium / High.

### Menu & hasil misi
- **Cinematic Main Menu** berlatar ilustrasi hutan gambut senja, asap, kebakaran dan petugas penyelamatan; layout layar penuh dengan navigasi operasi di kiri dan kartu skenario di kanan.
- **Logo Satria Gambut asli tetap digunakan**, dengan framing dan tipografi judul yang dibuat lebih menonjol.
- Semua pilihan tetap tersedia: **Mulai Operasi, Pilih Skenario, Panduan & SOP, Kustomisasi Helm & Seragam, Pengaturan, Credits, Keluar**.
- **Pause dan akhiri misi sukarela**: pemain dapat memilih **Akhiri Misi & Lihat Evaluasi** tanpa langsung kembali ke menu. Sesi berstatus `ABORTED` dan tidak memperoleh medali/rekor kemenangan.
- **Evaluasi lengkap**: statistik durasi, penggunaan air, hotspot, bara, kondisi pos, area aman/hangus, estimasi karbon, skor/medali apabila berlaku, serta rekor lokal.
- **Mission Telemetry**: sampel selama operasi (sekitar setiap 5 detik), grafik perkembangan misi, dan ekspor **CSV + JSON** ke `user://mission_reports`.
- **Audio, tampilan, kostum, dan preferensi navigasi** disimpan secara lokal antar sesi.

## Riwayat pengembangan

| Versi | Peningkatan utama |
| :--- | :--- |
| **V1–V2** | Penyempurnaan gameplay, interaksi, navigasi, penilaian dan pencatatan rekor lokal. |
| **V3–V3.1** | Lingkungan hutan lebih hidup dan perbaikan vegetasi yang bereaksi terhadap angin. |
| **V4–V4.3** | Efek kebakaran lanjutan dan perbaikan fullscreen, fokus input, serta ukuran jendela responsif. |
| **V5** | Audio lingkungan imersif: suara hutan, hujan, angin, dan kebakaran. |
| **V6** | Petir, guntur, badai, cipratan hujan, dan gambut yang tampak basah. |
| **V7** | Cinematic Mode dan screenshot PNG untuk dokumentasi permainan. |
| **V8** | Analitik misi, grafik perjalanan operasi, dan ekspor CSV/JSON. |
| **V8.1** | Penghentian misi sukarela dengan evaluasi hasil sementara. |
| **V8.2** | Kamera FPS/TPP, karakter awal TPP, radar modern dan peta taktis besar. |
| **V8.3** | Animasi alat TPP, model petugas lebih detail, kostum helm/seragam, radar, dan posko yang dapat dimasuki. |
| **V8.4** | Perbaikan pohon/collider pada posko, musik menu/gameplay orisinal, dan arah alat mengikuti petak sasaran. |
| **V8.5** | Modern Tactical HUD, rute dan panah navigasi H, opsi menyembunyikan panah 3D, serta perbaikan sistem musik. |
| **V8.6 (terkini)** | Menu sinematik dengan logo asli, peningkatan submenu, panah segitiga, dan pintu posko otomatis beranimasi dengan perlindungan collision. |

> Versi-versi di atas menggambarkan pekerjaan pada rangkaian **branch pengembangan/draft PR**, bukan daftar rilis resmi yang sudah digabungkan ke `main`.

## Kontrol

| Tombol | Fungsi |
| :--- | :--- |
| `W` `A` `S` `D` | Bergerak |
| `Shift` | Berlari |
| `Space` | Melompat |
| `Mouse` | Melihat/mengarahkan bidikan |
| `Klik kiri` / tahan | Menggunakan alat yang dipilih |
| `1`, `2`, `3` | Sekat Api, Semprot Air, Tombak Gambut |
| `Tab` | Mengaktifkan/menonaktifkan Thermal |
| `E` | Isi ulang air dari sumur ketika dekat |
| `V` | Ganti kamera FPS / TPP |
| `M` | Buka/tutup peta taktis besar |
| `H` | Ganti mode panduan navigasi |
| `Esc` | Pause / menutup peta bila sedang terbuka |
| `F9` | Pratinjau efek petir |
| `F10` | Mode sinematik |
| `F11` | Fullscreen |
| `F12` | Screenshot PNG |

**Pintu posko V8.6:** buka/tutup **otomatis** ketika pemain mendekat atau menjauh dengan aman. **Tidak menggunakan tombol F.**

## Struktur proyek

```text
satria-gambut/
├── project.godot
├── core/
│   ├── event_bus.gd              # Event komunikasi antar sistem
│   ├── game_state.gd             # Skenario, status misi, rekor & preferensi
│   └── audio_manager.gd          # Efek audio dan musik prosedural offline
├── simulation/
│   ├── model/                    # PeatCellData, PFVI, GridSimulator
│   ├── player/
│   │   ├── player_controller_3d.gd
│   │   ├── firefighter_avatar_3d.gd
│   │   ├── held_tools_3d.gd
│   │   └── navigation_world_arrow_3d.gd
│   ├── view/                     # Visualisasi terrain, vegetasi, posko, VFX
│   ├── mission_director.gd       # Objektif, tutorial, navigasi, cuaca
│   ├── mission_telemetry.gd      # Statistik dan ekspor laporan misi
│   └── cinematic_capture.gd     # Screenshot dan mode sinematik
├── environment/
│   ├── props/                    # Sumur, posko yang dapat dimasuki, properti
│   ├── audio/                    # Audio lingkungan
│   └── vfx/                      # Api, cuaca, petir, guntur dan efek lainnya
├── ui/
│   ├── main_menu/                # Menu sinematik, submenu, skenario & kostum
│   ├── planning/                 # Peta PFVI dan peletakan sumur
│   ├── hud/                      # HUD, radar, peta dan indikator alat
│   ├── pause/                    # Jeda, kostum, pengaturan, berhenti sukarela
│   └── evaluation/               # Ringkasan, grafik, ekspor misi
├── scenes/                       # Koordinator scene simulasi
├── tools/                        # Enum alat dan ToolManager
└── assets/
    ├── audio/
    ├── models/
    └── textures/                 # Termasuk logo asli Satria Gambut
```

## Instalasi dan menjalankan proyek

### Persyaratan
- **Godot 4.7.2** (Standard/GDScript; renderer GL Compatibility).
- Windows desktop; proyek menggunakan Jolt Physics.
- Git (opsional jika mengunduh ZIP).

### Jalankan versi pengembangan terbaru (V8.6)

**Opsi A — Git:**

```bash
git clone --branch feature/animated-outpost-modern-menu-arrow-v8-6 --single-branch https://github.com/AlGibran18/ProjekAkhir-KomGraf-SatriaGambut.git
```

**Opsi B — ZIP:** buka [branch V8.6](https://github.com/AlGibran18/ProjekAkhir-KomGraf-SatriaGambut/tree/feature/animated-outpost-modern-menu-arrow-v8-6) → **Code → Download ZIP** → ekstrak ke folder tersendiri.

Setelah itu:
1. Jalankan Godot → **Import** → pilih file `project.godot` dari folder hasil clone/ekstrak.
2. Tunggu proses impor aset selesai.
3. Tekan **F5** untuk membuka menu utama dan menjalankan game.
4. Coba semua menu, navigasi, FPS/TPP dan tiga skenario. Jika muncul error, periksa tab **Debugger / Output** di Godot.

> `git clone` tanpa `--branch` secara default mengambil `main`, yang belum mencakup seluruh fitur pengembangan di atas. Folder `.godot` adalah cache yang dapat dibuat ulang oleh editor.

### Ekspor ke aplikasi Windows (.exe)

1. Buka proyek dalam Godot, pilih **Project → Export**.
2. Tambahkan preset **Windows Desktop**.
3. Instal export templates yang sesuai dengan versi Godot apabila diminta.
4. Atur lokasi output dan ekspor proyek; opsi **Embed PCK** dapat dipakai untuk menyatukan data dalam executable.

**Catatan:** dokumentasi ini **bukan pengumuman rilis Windows final**. File `.exe` belum disediakan sebagai rilis final yang diverifikasi.

## Dokumentasi pengembangan

- [V8 — Mission Analytics](https://github.com/AlGibran18/ProjekAkhir-KomGraf-SatriaGambut/blob/feature/animated-outpost-modern-menu-arrow-v8-6/GAMEPLAY_V8_ANALYTICS.md)
- [V8.1 — Stop & Partial Evaluation](https://github.com/AlGibran18/ProjekAkhir-KomGraf-SatriaGambut/blob/feature/animated-outpost-modern-menu-arrow-v8-6/GAMEPLAY_V8_1_VOLUNTARY_STOP.md)
- [V8.2 — FPS/TPP & Tactical Map](https://github.com/AlGibran18/ProjekAkhir-KomGraf-SatriaGambut/blob/feature/animated-outpost-modern-menu-arrow-v8-6/GAMEPLAY_V8_2_CAMERA_MAP.md)
- [V8.3 — Character & Outpost](https://github.com/AlGibran18/ProjekAkhir-KomGraf-SatriaGambut/blob/feature/animated-outpost-modern-menu-arrow-v8-6/GAMEPLAY_V8_3_TPP_CUSTOM_OUTPOST.md)
- [V8.4 — Music & Targeting](https://github.com/AlGibran18/ProjekAkhir-KomGraf-SatriaGambut/blob/feature/animated-outpost-modern-menu-arrow-v8-6/GAMEPLAY_V8_4_OUTPOST_MUSIC_AIM.md)
- [V8.5 — HUD & Smart Navigation](https://github.com/AlGibran18/ProjekAkhir-KomGraf-SatriaGambut/blob/feature/animated-outpost-modern-menu-arrow-v8-6/GAMEPLAY_V8_5_HUD_NAVIGATION.md)
- [V8.6 — Door, UI & Cinematic Menu](https://github.com/AlGibran18/ProjekAkhir-KomGraf-SatriaGambut/blob/feature/animated-outpost-modern-menu-arrow-v8-6/GAMEPLAY_V8_6_MENU_DOOR_ARROW.md)

## Kredit dan referensi

- **Mesin game:** [Godot Engine](https://godotengine.org/) 4.7.2.
- **Aset alam 3D:** *Stylized Nature MegaKit* oleh Quaternius dan *Nature Kit* oleh Kenney (aset CC0 yang digunakan proyek).
- **Latar menu sinematik:** ilustrasi SVG orisinal untuk Satria Gambut; tidak menggunakan aset atau logo dari game lain.
- **Musik menu dan gameplay:** instrumental prosedural orisinal, dibuat untuk proyek.
- **Landasan edukatif:** pendekatan PFVI dan kajian risiko kebakaran gambut; seluruh angka dalam game adalah **simulasi untuk pembelajaran**, bukan data observasi lapangan.

---

<p align="center"><strong>SATRIA GAMBUT</strong><br/>Jelajahi • Lindungi • Padamkan</p>

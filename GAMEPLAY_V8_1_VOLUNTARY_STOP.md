# Satria Gambut V8.1 — Akhiri Misi & Evaluasi Sementara

## Tujuan
Pemain yang tidak sanggup menyelesaikan sebuah level dapat **menghentikan operasi secara sukarela** dan langsung melihat hasil pekerjaan selama bermain, bukan langsung dibawa ke menu utama.

## Alur baru
1. Saat berada di gameplay FPS, tekan **Esc** untuk membuka Pause Menu.
2. Klik **AKHIRI MISI & LIHAT EVALUASI**.
3. Jendela konfirmasi menampilkan dua pilihan: **LANJUTKAN MISI** dan **AKHIRI & LIHAT HASIL**.
4. Jika konfirmasi disetujui, game keluar dari pause, membekukan progres simulasi pada fase `ABORTED`, dan langsung membuka layar evaluasi.
5. Evaluasi menampilkan status **OPERASI DIHENTIKAN**, level, durasi, hotspot yang tersisa, bara tersembunyi, status pos, petak aman, estimasi karbon, dan penggunaan air.
6. Pemain dapat membuka **GRAFIK PERKEMBANGAN MISI & EKSPOR DATA** pada layar evaluasi. Semua sampel sampai misi dihentikan tetap tersedia. File JSON membedakan `result: "ABORTED"` dari `VICTORY` dan `DEFEAT`.
7. Setelah melihat evaluasi, pemain bisa **ULANGI SKENARIO** atau **MENU UTAMA**.

## Aturan penilaian
- `ABORTED` merupakan keputusan pemain, **bukan kemenangan atau kekalahan akibat kebakaran**.
- Tidak ada medali, pencatatan rekor, atau akses ke tombol "Level Berikutnya" pada sesi yang dihentikan.
- Skor pada GameState diatur ke 0 untuk hasil `ABORTED`; laporan sementara tetap memuat statistik lapangan dalam game.
- Misi yang berhasil atau kalah secara otomatis tetap berjalan seperti sebelumnya.

## Pengujian manual
- [ ] Import di Godot tanpa parse error.
- [ ] Level 1: bermain, memakai beberapa liter air, buat sekat bakar, lalu tekan Esc.
- [ ] Klik Akhiri Misi, pilih **LANJUTKAN MISI** → operasi harus tetap di-pause sampai pemain memilih Resume, tanpa kehilangan data.
- [ ] Buka konfirmasi kembali, pilih **AKHIRI & LIHAT HASIL** → layar evaluasi harus muncul otomatis, kursor bisa diklik.
- [ ] Pastikan statusnya **OPERASI DIHENTIKAN**, bukan `MISI BERHASIL` / `MISI GAGAL`.
- [ ] Pastikan jumlah hotspot tersisa, penggunaan air, durasi dan petak aman masuk akal dibanding keadaan tepat sebelum stop.
- [ ] Buka Grafik Perkembangan Misi, cek sampel terakhir, lalu ekspor CSV dan JSON. JSON harus memuat `"result": "ABORTED"`.
- [ ] Verifikasi tombol **ULANGI SKENARIO** dan **MENU UTAMA** berjalan normal.
- [ ] Pastikan menutup dialog konfirmasi dan melanjutkan game tidak menghentikan misi.
- [ ] Mainkan sampai menang dan kalah secara normal; pastikan grafik, skor, dan evaluasi masih sama.
- [ ] Pastikan F9, F10, F11, F12 dan fullscreen responsif V7/V8 tetap bekerja.

## Teknis
Perubahan hanya menambah fase game `ToolEnums.GamePhase.ABORTED`, handler konfirmasi Pause Menu, informasi layar Evaluation, dan dukungan ekspor telemetry. Model kebakaran, kecepatan penyebaran, dan aturan menang/kalah tidak diubah.

**Belum diuji melalui runtime Godot dalam lingkungan pengembangan; lakukan pengujian manual sebelum merge.**

# Audit Arti Screenshot

Seluruh 28 gambar ditinjau secara visual. Tangkapan aplikasi dari adb menggunakan frame utuh 1080 × 2424 tanpa penyuntingan. Lampiran Console dan terminal pengguna dipertahankan persis seperti diterima. Setiap gambar dibaca bersama tindakan, hasil yang terlihat, dan log atau test bila diperlukan.

| Screenshot | Yang terlihat / arti bukti | Batas dan pasangan bukti |
| :--- | :--- | :--- |
| [praktikum1_login.png](../screenshots/praktikum1_login.png) | Form login mock sebelum masuk | Tidak membuktikan login Firebase Auth. |
| [praktikum1_login_validation.png](../screenshots/praktikum1_login_validation.png) | Kesalahan email dan minimal enam karakter | Form kosong ditolak sebelum login. |
| [praktikum1_refresh_success.png](../screenshots/praktikum1_refresh_success.png) | Hasil 401 → refresh sekali → retry 200 | Backend demo; jumlah retry juga diperiksa unit test. |
| [praktikum1_refresh_failed_login.png](../screenshots/praktikum1_refresh_failed_login.png) | Kembali ke login setelah demo refresh gagal | Layar akhir; penghapusan token dibuktikan unit test dan urutan tindakan. |
| [praktikum2_notification_permission.png](../screenshots/praktikum2_notification_permission.png) | Dialog Allow / Don’t allow Android | Permintaan runtime; status granted terlihat di gambar token. |
| [praktikum2_token_before.png](../screenshots/praktikum2_token_before.png) | Prefix token awal, authorized, POST simulasi | Bandingkan dengan token_after_clear; tidak ada token lengkap. |
| [praktikum2_token_rotated.png](../screenshots/praktikum2_token_rotated.png) | token berubah=true dan onTokenRefresh → POST | Prefix dapat sama; POST menuju adapter simulasi. |
| [praktikum2_after_clear_login.png](../screenshots/praktikum2_after_clear_login.png) | Login ulang diperlukan setelah clear data | Layar akhir; terkait tindakan pm clear pada catatan verifikasi. |
| [praktikum2_token_after_clear.png](../screenshots/praktikum2_token_after_clear.png) | Prefix baru dan registrasi perangkat | Bukti perubahan dibanding token_before, bukan backend persisten. |
| [fcm-console-campaign.png](../screenshots/fcm-console-campaign.png) | Project, target Android, campaign Completed | Bukti pengiriman dari Console; tidak menunjukkan custom data. |
| [fcm-console-test.png](../screenshots/fcm-console-test.png) | Pesan Console diterima pada panel Android | Cuplikan pengguna; title dan body lengkap, bukan frame emulator utuh. |
| [fcm-console-detail.png](../screenshots/fcm-console-detail.png) | Pengumuman #3 dan tujuan /pengumuman/3 | Cuplikan setelah klik yang diberikan pengguna. |
| [praktikum3_foreground_state.png](../screenshots/praktikum3_foreground_state.png) | Banner heads-up di atas aplikasi terbuka dan event foreground di UI | Menghubungkan kondisi aktif dengan messageId di log. |
| [praktikum3_foreground_banner.png](../screenshots/praktikum3_foreground_banner.png) | Kartu notifikasi lokal pada panel | Dibaca bersama foreground_state dan foreground-click; bukan heads-up. |
| [praktikum3_foreground_detail.png](../screenshots/praktikum3_foreground_detail.png) | Tujuan setelah klik notifikasi lokal | Rute sama dengan payload; log membuktikan asal klik. |
| [praktikum3_background_state.png](../screenshots/praktikum3_background_state.png) | Layar Home setelah aplikasi diminimalkan | Home sendiri bukan bukti proses berhenti; ini uji background. |
| [praktikum3_background_banner.png](../screenshots/praktikum3_background_banner.png) | Kartu sistem setelah pengiriman background | Dibaca bersama kondisi Home dan log penerima. |
| [praktikum3_background_detail.png](../screenshots/praktikum3_background_detail.png) | Tujuan setelah klik kartu sistem | Event background-click membedakan dari dua jalur lain. |
| [praktikum3_terminated_state.png](../screenshots/praktikum3_terminated_state.png) | No recent items setelah task ditutup | Pemeriksaan pidof juga memastikan proses tidak ada sebelum kirim. |
| [praktikum3_terminated_banner.png](../screenshots/praktikum3_terminated_banner.png) | Kartu sistem sesudah aplikasi ditutup | FCM boleh menyalakan proses background; tidak berarti UI telah dibuka. |
| [praktikum3_terminated_detail.png](../screenshots/praktikum3_terminated_detail.png) | Tujuan startup dari notifikasi | Event terminated-click membuktikan getInitialMessage. |
| [praktikum3_topic_unsubscribed.png](../screenshots/praktikum3_topic_unsubscribed.png) | Switch off dan event unsubscribe terbaru | Bukti keberhasilan callback, bukan pengujian non-delivery broadcast. |
| [praktikum3_topic_subscribed.png](../screenshots/praktikum3_topic_subscribed.png) | Switch on dan event subscribe terbaru | Menunjukkan langganan aktif, dibaca bersama pengiriman topik. |
| [praktikum3_data_only_foreground.png](../screenshots/praktikum3_data_only_foreground.png) | Event penerimaan tanpa notifikasi baru | Jenis data-only dicocokkan dengan fcm_sends.jsonl; hanya foreground diuji. |
| [tugas_utama_home.png](../screenshots/tugas_utama_home.png) | Ikhtisar pengumuman, status izin/token, kontrol topik | Bukti fitur halaman utama, bukan kasus pengujian state baru. |
| [tugas_utama_home_bottom.png](../screenshots/tugas_utama_home_bottom.png) | Keamanan sesi dan hasil demo 401 | Berbeda dari home lewat hasil request; sebagian UI sengaja sama. |
| [flutter_analyze.png](../screenshots/flutter_analyze.png) | No issues found | Gambar terminal pengguna dipertahankan tanpa perubahan. |
| [flutter_test.png](../screenshots/flutter_test.png) | +4: All tests passed | Unit test logika tanpa Firebase; bukan uji penerimaan FCM. |

Gambar halaman tujuan tiga state serupa karena codelab meminta payload yang sama. Gambar kondisi aplikasi dan handler pada `fcm_events.txt` membedakan ketiga pengujian. Screenshot login setelah refresh gagal atau clear data juga serupa; maknanya berasal dari tindakan sebelum pengambilan, bukan klaim bahwa tampilan login membuktikan penyimpanan aman.

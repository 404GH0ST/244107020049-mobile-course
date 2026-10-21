# Bukti merge PR kelompok

[PR #13](https://github.com/Zuhdiaja/PBL-MOBILE/pull/13) sudah **MERGED ke main**
pada **21 Oktober 2026, 22.05.38 WIB** (15.05.38 UTC), oleh **404GH0ST**.

- Review manusia: **APPROVED oleh oninonins** pada head `be6a67a`.
- CI pada head PR: **SUCCESS**, formatter/analyze/185 tes lulus.
- [Merge commit `daceea3`](https://github.com/Zuhdiaja/PBL-MOBILE/commit/daceea370c2c9e3623f5517b6d3c9cf8afda1bf1).
- [Issue #12](https://github.com/Zuhdiaja/PBL-MOBILE/issues/12): **CLOSED**
  otomatis pada 22.05.39 WIB melalui `Closes #12`.
- Remote origin/main diverifikasi menunjuk merge commit tersebut.
- Diff seluruh tree antara head yang direview `be6a67a` dan origin/main kosong.
  Dengan demikian hasil merge sama dengan kode yang diuji dan disetujui.

## Verifikasi repository

```sh
rtk git fetch origin
rtk git merge-base --is-ancestor daceea370c2c9e3623f5517b6d3c9cf8afda1bf1 origin/main
# exit 0
rtk git diff --stat be6a67ae679bc3ffd7f404c4f369225f040cecb4 origin/main
# kosong
rtk git ls-remote origin refs/heads/main
# daceea370c2c9e3623f5517b6d3c9cf8afda1bf1 refs/heads/main
```

[Metadata hasil pemeriksaan](evidence/merge-result.json).
Tes aplikasi tidak diulang lagi hanya karena commit merge: tree sudah terbukti
identik dengan head yang lulus tes ulang dan review. Bukti emulator juga tetap
merujuk kode tersebut.

[CI setelah push ke main](https://github.com/Zuhdiaja/PBL-MOBILE/actions/runs/39622603007)
terpicu setelah merge. Pada pemeriksaan awal run masih antre; pemeriksaan
terakhir memastikan **COMPLETED / SUCCESS** pada merge commit daceea3.
Dengan demikian **CI PR dan CI setelah merge sama-sama berhasil**.
[Bukti CI setelah merge](evidence/post-merge-ci.json).

Branch feature/onboarding-visuals masih tersedia saat pemeriksaan. Tidak
menghapus branch atau mengubah aturan proteksi/default branch sebagai bagian
verifikasi merge.

Alur issue → PR → satu review sejawat → tindak lanjut → approval → merge kini
terbukti selesai. Penyimpangan ukuran PR >300 baris dan penyesuaian target main
terhadap contoh develop pada modul tetap dicatat secara transparan.

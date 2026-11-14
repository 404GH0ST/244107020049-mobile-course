"""Run integration_test/app_test.dart on emulator-5554 and save emulator screenshots.

Usage: python3 tool/run_app_test.py
Every `SCREENSHOT:<name>` line from the test becomes screenshots/<name>.png.
"""
from pathlib import Path
import re
import subprocess
import sys

root = Path(__file__).resolve().parents[1]
shots = root / 'screenshots'
shots.mkdir(exist_ok=True)
adb = ['adb', '-s', 'emulator-5554']
command = ['flutter', 'test', 'integration_test/app_test.dart',
           '-d', 'emulator-5554', '--reporter', 'expanded']
proc = subprocess.Popen(command, cwd=root, stdout=subprocess.PIPE,
                        stderr=subprocess.STDOUT, text=True, bufsize=1)
for line in proc.stdout:
    print(line, end='', flush=True)
    match = re.search(r'SCREENSHOT:([a-z0-9_]+)', line)
    if match:
        # flutter test memasang ulang aplikasi; beri izin notifikasi sebelum
        # login agar dialog sistem tidak menutupi layar berikutnya.
        subprocess.run(adb + ['shell', 'pm', 'grant', 'id.ac.polinema.campus_notify',
                              'android.permission.POST_NOTIFICATIONS'], capture_output=True)
        with (shots / (match[1] + '.png')).open('wb') as output:
            subprocess.run(adb + ['exec-out', 'screencap', '-p'], stdout=output, check=True)
sys.exit(proc.wait())

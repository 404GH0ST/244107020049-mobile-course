"""Run the Week 11 profile scenario on emulator-5554 and capture emulator evidence.

Usage: python3 tool/run_profile.py <label> [--no-overlay]   (e.g. before / after)
Writes build/perf/<label>-*.json, screenshots/<label>-profile.png,
and build/perf/<label>-meminfo.txt.
"""
import os
from pathlib import Path
import re
import subprocess
import sys

args = [a for a in sys.argv[1:] if not a.startswith('--')]
label = args[0] if args else 'run'
overlay = '--no-overlay' not in sys.argv
root = Path(__file__).resolve().parents[1]
package = 'id.ac.polinema.campus_notify'
adb = ['adb', '-s', 'emulator-5554']
(root / 'screenshots').mkdir(exist_ok=True)
(root / 'build' / 'perf').mkdir(parents=True, exist_ok=True)
meminfo = (root / 'build' / 'perf' / f'{label}-meminfo.txt').open('w')
command = ['flutter', 'drive', '--profile', '--no-dds',
           '--driver=test_driver/perf_driver.dart',
           '--target=integration_test/perf_test.dart',
           f'--dart-define=PERF_OVERLAY={str(overlay).lower()}',
           '-d', 'emulator-5554']
env = dict(os.environ, PERF_LABEL=label)
proc = subprocess.Popen(command, cwd=root, env=env, stdout=subprocess.PIPE,
                        stderr=subprocess.STDOUT, text=True, bufsize=1)
for line in proc.stdout:
    print(line, end='', flush=True)
    shot = re.search(r'SCREENSHOT:([a-z_]+)', line)
    if shot:
        with (root / 'screenshots' / f'{label}-{shot[1]}.png').open('wb') as out:
            subprocess.run(adb + ['exec-out', 'screencap', '-p'], stdout=out, check=True)
    mem = re.search(r'MEMINFO:([a-z0-9_]+)', line)
    if mem:
        dump = subprocess.run(adb + ['shell', 'dumpsys', 'meminfo', package],
                              capture_output=True, text=True).stdout
        total = re.search(r'TOTAL PSS:\s+(\d+)', dump) or re.search(r'TOTAL\s+(\d+)', dump)
        heap = re.search(r'Dalvik Heap.*|Native Heap\s+\d+.*', dump)
        meminfo.write(f'{mem[1]} TOTAL_PSS_KB={total[1] if total else "?"}\n')
        meminfo.write(dump + '\n')
        meminfo.flush()
        print(f'[meminfo] {mem[1]} TOTAL_PSS_KB={total[1] if total else "?"}', flush=True)
sys.exit(proc.wait())

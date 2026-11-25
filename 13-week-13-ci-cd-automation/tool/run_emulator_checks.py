"""Run Android checks and capture original emulator pixels. No credentials in arguments."""
import argparse
import getpass
import os
from pathlib import Path
import re
import subprocess
import sys

parser = argparse.ArgumentParser()
parser.add_argument('--live', action='store_true', help='Prompt privately for a Gemini key and use the live API')
parser.add_argument('--live-only', action='store_true', help='Run only the live API suite')
args = parser.parse_args()
if args.live_only:
    args.live = True
live_key = (os.environ.pop('GEMINI_API_KEY', None) or getpass.getpass('Gemini API key for live checks: ')) if args.live else None
root = Path(__file__).resolve().parents[1]
shots = root / 'screenshots'
shots.mkdir(exist_ok=True)
adb = ['adb', '-s', 'emulator-5554']
command = ['flutter', 'test']
if not args.live_only:
    command += ['integration_test/ai_chat_test.dart']
if args.live:
    command += ['integration_test/live_ai_test.dart', '--dart-define=RUN_LIVE_AI=true']
command += ['-d', 'emulator-5554', '--reporter', 'expanded']
proc = subprocess.Popen(command, cwd=root, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True, bufsize=1)
for line in proc.stdout:
    print(line, end='', flush=True)
    if 'PREPARE_LIVE_FIXTURES' in line:
        if live_key:
            subprocess.run(adb + ['shell', 'run-as', 'id.ac.polinema.campus_notify', 'mkdir', '-p', 'files'], check=True)
            subprocess.run(adb + ['shell', 'run-as', 'id.ac.polinema.campus_notify', 'tee', 'files/week10_test_key'],
                           input=live_key.encode(), stdout=subprocess.DEVNULL, check=True)
        for source, name in [('notice.png', 'week10_notice.png'), ('question.m4a', 'week10_question.m4a')]:
            subprocess.run(adb + ['shell', 'run-as', 'id.ac.polinema.campus_notify', 'tee', 'files/' + name],
                           input=(root / 'integration_test' / 'fixtures' / source).read_bytes(), stdout=subprocess.DEVNULL, check=True)
    match = re.search(r'SCREENSHOT:([a-zA-Z0-9_]+)', line)
    if match:
        subprocess.run(adb + ['shell', 'pm', 'grant', 'id.ac.polinema.campus_notify', 'android.permission.RECORD_AUDIO'], capture_output=True)
        with (shots / (match[1] + '.png')).open('wb') as output:
            subprocess.run(adb + ['exec-out', 'screencap', '-p'], stdout=output, check=True)
sys.exit(proc.wait())

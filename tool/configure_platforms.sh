#!/usr/bin/env bash
# Run once after `flutter create --platforms=android,ios --org com.example .`
# Adds the microphone / speech permissions required by speech_to_text.
set -e
python3 - <<'PY'
import re, pathlib
m = pathlib.Path('android/app/src/main/AndroidManifest.xml')
t = m.read_text()
if 'RECORD_AUDIO' not in t:
    add = '''    <uses-permission android:name="android.permission.RECORD_AUDIO"/>
    <uses-permission android:name="android.permission.INTERNET"/>
    <uses-permission android:name="android.permission.BLUETOOTH" android:maxSdkVersion="30"/>
    <uses-permission android:name="android.permission.BLUETOOTH_CONNECT"/>
    <queries>
        <intent><action android:name="android.speech.RecognitionService"/></intent>
        <intent><action android:name="android.intent.action.TTS_SERVICE"/></intent>
    </queries>
    '''
    t = t.replace('<application', add + '<application', 1)
    m.write_text(t)
p = pathlib.Path('ios/Runner/Info.plist')
t = p.read_text()
if 'NSMicrophoneUsageDescription' not in t:
    add = '''	<key>NSMicrophoneUsageDescription</key>
	<string>The microphone is used only while you record an answer to the examiner.</string>
	<key>NSSpeechRecognitionUsageDescription</key>
	<string>Speech recognition converts your spoken answer into text for feedback.</string>
'''
    i = t.rfind('</dict>')
    t = t[:i] + add + t[i:]
    p.write_text(t)
print('platform permissions configured')
PY
echo "Reminder: speech_to_text needs Android minSdk >= 21 and iOS >= 12 (check android/app/build.gradle and ios/Podfile)."

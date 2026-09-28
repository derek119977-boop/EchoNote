# EchoNote Standalone

Native iPhone version of EchoNote. It does not depend on HavenServer, Tailscale, Flask, Whisper, Ollama, or Cloudflare.

Target: iOS 26+ / SwiftUI

Included:
- Native microphone recording
- Local audio files
- SwiftData notes database
- On-device SpeechAnalyzer/SpeechTranscriber transcription
- On-device Foundation Models summarization when Apple Intelligence is available
- Home / Notes / Settings
- System / Light / Dark appearance
- Native Liquid Glass UI

## Important
An iOS app must ultimately be compiled and signed with Xcode on macOS. These are the source files for the native app.

Create an iOS App project named EchoNote in Xcode, choose SwiftUI + SwiftData, then replace the generated Swift files with these files.

Add these privacy descriptions:
- NSMicrophoneUsageDescription = EchoNote needs microphone access to record your notes.
- NSSpeechRecognitionUsageDescription = EchoNote uses speech recognition to transcribe your recordings.

# ZehnAI — Complete Setup Guide
## Your Own AI Assistant for Students

---

## STEP 1 — GET YOUR FREE GEMINI API KEY

1. Go to: https://aistudio.google.com/app/apikey
2. Sign in with your Google account
3. Click "Create API Key"
4. Copy the key (starts with "AIza...")
5. Open: `lib/core/api/gemini_service.dart`
6. Replace `'YOUR_GEMINI_API_KEY_HERE'` with your key

**Free tier limits:**
- 1,500 requests/day (gemini-1.5-flash)
- 1 million tokens/day
- Completely free — no credit card needed

---

## STEP 2 — FLUTTER SETUP

Make sure Flutter is installed:
```bash
flutter doctor
```

Install dependencies:
```bash
cd zehn_ai
flutter pub get
```

Run the app:
```bash
flutter run
```

Build release APK for Android:
```bash
flutter build apk --release
```

Build for iOS (Mac required):
```bash
flutter build ios --release
```

---

## STEP 3 — CUSTOMIZE YOUR AI (Most Important)

The file `lib/core/prompts/system_prompts.dart` controls HOW your AI thinks.

**To change the AI's name:**
Replace `ZehnAI` with your app name everywhere in `masterPrompt()`

**To change the AI's personality:**
Edit the "PERSONALITY" section in `masterPrompt()`

**To add a new subject focus (e.g. Medical):**
Add a new static method in `SystemPrompts`:
```dart
static String medicalMode() => '''
${masterPrompt()}
CURRENT MODULE: MEDICAL ASSISTANT
You are an expert in MBBS preparation for Pakistani medical students.
Focus on anatomy, physiology, pharmacology, and MDCAT preparation.
Always reference PMC guidelines and HEC requirements.
''';
```

**To change the AI's language:**
Add to masterPrompt: "Always respond in Urdu only" or "Respond in Roman Urdu only"

---

## STEP 4 — PROJECT STRUCTURE EXPLAINED

```
lib/
├── main.dart                          ← App entry, navigation, theme
├── core/
│   ├── api/
│   │   └── gemini_service.dart        ← ALL Gemini API calls
│   ├── prompts/
│   │   └── system_prompts.dart        ← YOUR AI'S BRAIN (edit this!)
│   ├── models/                        ← Data classes
│   └── services/                      ← Firebase, Hive storage
└── features/
    ├── chat/
    │   └── chat_screen.dart           ← Main AI chat UI
    ├── study/
    │   └── study_screen.dart          ← MCQs, explainer, PDF
    ├── career/                        ← Resume, interview (add next)
    ├── planner/                       ← Schedule, goals (add next)
    └── home/                          ← Dashboard
```

---

## STEP 5 — ADD FIREBASE (Optional but recommended)

Firebase gives you: user accounts, cloud sync, usage analytics

1. Create project at: https://console.firebase.google.com
2. Add Flutter app (Android + iOS)
3. Download google-services.json → android/app/
4. Run: `flutter pub add firebase_core firebase_auth cloud_firestore`
5. Initialize in main.dart:
```dart
await Firebase.initializeApp(
  options: DefaultFirebaseOptions.currentPlatform,
);
```

---

## REAL STUDENT PROBLEMS YOUR AI SOLVES

| Problem | Feature | How |
|---------|---------|-----|
| Don't understand a concept | Study Mode → Explain | AI explains + example + memory trick |
| Need to practice for exam | Study Mode → MCQs | AI generates NTS/PPSC quality MCQs |
| Have lecture notes, need summary | Study Mode → PDF | AI summarizes + predicts exam questions |
| Need a job, no resume | Career → Resume | AI writes professional bullets |
| Scared of interviews | Career → Mock Interview | AI asks questions + gives feedback |
| Don't know what to learn | Career → Roadmap | AI gives week-by-week skill plan |
| Math problem can't solve | Chat → Math Mode | AI solves step by step, no skipping |
| Code has a bug | Chat → Code Mode | AI finds bug + fixes + explains why |
| No daily routine | Planner Mode | AI creates schedule with prayer times |
| Don't know English well | All modules | AI detects Urdu and responds in Urdu |

---

## ADDING PDF READING (Real file upload)

Install packages:
```bash
flutter pub add file_picker pdf_text
```

Add to study_screen.dart:
```dart
import 'package:file_picker/file_picker.dart';
import 'package:pdf_text/pdf_text.dart';

Future<void> _pickAndReadPDF() async {
  final result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['pdf'],
  );
  
  if (result == null) return;
  
  final file = result.files.single;
  if (file.path == null) return;
  
  // Extract text from PDF
  final pdfDoc = await PDFDoc.fromPath(file.path!);
  final text = await pdfDoc.text;
  
  setState(() {
    _simulatedPdfText = text;
    _uploadedFileName = file.name;
  });
  
  // Now you can send this text to Gemini
}
```

---

## ANDROID PERMISSIONS NEEDED

Add to `android/app/src/main/AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"/>
```

---

## MONETIZATION (When app is ready)

**Option 1 — RevenueCat subscriptions:**
```bash
flutter pub add purchases_flutter
```
Free: 20 questions/day
Pro (Rs 299/month): Unlimited

**Option 2 — Google AdMob:**
```bash
flutter pub add google_mobile_ads
```
Show ads between sessions for free tier users

**Option 3 — University licenses:**
Contact Air University, NUST, UET, FAST with a pitch deck
Charge per-institution (Rs 50,000-200,000/year)

---

## SUPPORT

GitHub: github.com/235154-afk
LinkedIn: Muhammad Talal Tariq
Made with ❤️ in Pakistan

"علم حاصل کرو چاہے چین جانا پڑے"

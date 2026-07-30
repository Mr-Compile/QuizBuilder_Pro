# QuizForge AI

AI-Assisted Offline Quiz Management System

> Create, learn, and practice quizzes online or offline.

## Overview

QuizForge AI is a Flutter mobile application for Android that supports two roles:

- **Teacher/Admin** — manage students, topics, questions, generate AI questions, view results and statistics.
- **Student** — browse topics, select difficulty, take quizzes offline, review answers, view history and statistics.

Only the AI question generation feature requires an internet connection. Everything else works offline using a local SQLite database.

## Default Credentials

- **Admin:** `admin` / `admin123`
- **Students:** `alice` / `alice123`, `bob` / `bob123`, `charlie` / `charlie123`

## Tech Stack

- Flutter (latest stable)
- Dart
- SQLite (`sqflite`)
- `path`, `http`, `shared_preferences`, `lucide_icons`, `intl`
- Material 3

## Project Structure

```
lib/
 ├─ main.dart
 ├─ app.dart
 ├─ core/
 │   ├─ theme/
 │   ├─ constants/
 │   ├─ routes/
 │   └─ utils/
 ├─ models/
 ├─ database/
 ├─ services/
 ├─ features/
 │   ├─ auth/
 │   ├─ teacher/
 │   ├─ student/
 │   ├─ quiz/
 │   ├─ question/
 │   ├─ statistics/
 │   └─ settings/
 ├─ widgets/
 └─ shared/
```

## Setup & Run

1. **Install Flutter:**
   Follow the official guide: https://docs.flutter.dev/get-started/install

2. **Get dependencies:**
   ```bash
   flutter pub get
   ```

3. **Run on an Android emulator or device:**
   ```bash
   flutter run
   ```

## APK Build Instructions

Build a release APK:

```bash
flutter build apk --release
```

The APK will be located at:

```
build/app/outputs/flutter-apk/app-release.apk
```

## Groq AI Setup

1. Create a free account at https://groq.com and generate an API key.
2. As a teacher, go to **Settings → Groq API Key** or **AI Question Generation** and paste your key.
3. The key is stored locally in `SharedPreferences` and is used only when generating questions.

## Manual Test Cases

### Authentication
- Login with `admin` / `admin123` → redirected to Teacher Dashboard.
- Login with `alice` / `alice123` → redirected to Student Dashboard.
- Login with wrong password → error message.
- Login with inactive student account → blocked.

### Role Redirection & Permissions
- A teacher cannot navigate to the student dashboard directly.
- A student cannot navigate to the teacher dashboard directly.
- Unauthorized screens redirect to the correct dashboard.

### Student CRUD (Teacher)
- Add a new student with a unique username.
- Try adding a duplicate username → validation error.
- Edit a student.
- Deactivate a student and verify they cannot log in.
- Delete a student.

### Topic CRUD (Teacher)
- Add a new topic.
- Try adding a duplicate topic name → validation error.
- Edit a topic.
- Delete a topic and verify its questions are removed.

### Question CRUD (Teacher)
- Add a manual question.
- Edit a question.
- Delete a question.
- Search and filter questions by topic and difficulty.

### AI Question Generation (Teacher)
- Save a Groq API key.
- Generate 5 easy questions for a topic.
- Preview generated questions and save selected ones.
- Verify saved questions have `source = 'ai'`.
- Disconnect internet and verify an error is shown.

### Offline Quiz Taking (Student)
- Close internet.
- Login as a student.
- Select a topic and difficulty.
- Answer all questions and finish.
- Verify the result is saved and review is accessible.

### Score Calculation
- Answer all correctly → 100% and Pass.
- Answer none correctly → 0% and Fail.
- Verify percentage and Pass/Fail at 60% threshold.

### Result Saving
- Take a quiz.
- Verify the result appears in the teacher's Results screen.
- Verify the result appears in the student's History.

### History & Review
- View My History as a student.
- Tap a result to review answers.
- Verify correct answers are green and incorrect answers are red.

### Statistics
- As a teacher, view global statistics.
- As a student, view personal statistics.
- Take more quizzes and watch the statistics update.

### Theme Switching
- Go to Settings.
- Switch between Light, Dark and System themes.
- Verify the UI updates.

### Permission Restrictions
- Log in as a student.
- Try to open `/teacher/dashboard` from the browser/IDE → redirected.
- Verify the app bar does not show teacher-only options.

## Notes

- Passwords are stored as plain text for educational purposes only.
- The `http` package is used only in the `GroqAiService` for online AI generation.
- All quiz data, results, answers and authentication work offline.

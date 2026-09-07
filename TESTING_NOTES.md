# 📝 Smart Task Manager – Testing & Evaluation Notes

Welcome to **Smart Task Manager**! Below are the instructions and test credentials to help you test and evaluate all features of the application.

---

## 📞 Tester Support & Contact
If you encounter any difficulties, need assistance, or have questions while testing:
- **Phone / WhatsApp**: **+91 9061624061**

---

## 🔑 Ways to Log In & Test

### Option 1: Pre-configured Test Account
Use the following test credentials on the **Sign In** screen:
- **Email**: `test@gmail.com`
- **Password**: `test@123`

---

### Option 2: Register a New Account
- Tap **"Sign Up"** at the bottom of the login screen.
- Enter any name, email (e.g., `tester1@example.com`), and password (min 6 characters).
- Creates an isolated user session where all tasks and Firestore profile preferences (like dark mode) are uniquely tied to that account.

---

## 🧪 Key Features to Test

1. **Firebase Authentication & Firestore User Profile**:
   - Clean Email & Password Sign In and Sign Up with real-time validation and mapped error messages.
   - User profile stored in Firestore under `users/{userId}` with theme preference auto-applied.
   - Profile management screen under account menu.

2. **Task CRUD Operations (REST API + Local Cache)**:
   - **Create**: Tap the `+` button in the bottom right, enter title, description, select priority, choose category and due date, and save.
   - **Optimistic UI Updates**: Created, updated, and deleted tasks immediately reflect in the UI with automatic rollback on network failure.
   - **Update / Toggle**: Tap any task to view details, edit fields, or tap the circular checkbox to toggle completion.
   - **Delete**: Swipe to delete or delete directly from the task detail screen.

3. **Debounced Search, Client-Side Filtering & Sorting**:
   - Search tasks by title with 300ms debouncing to prevent excessive queries and smooth performance.
   - Filter by status (*All, Pending, Completed*), priority, and category.
   - Sort by due date (earliest/latest), priority (highest/lowest), and created date.
   - Infinite scroll pagination using `skip` & `limit` with pull-to-refresh.

4. **Offline-First Strategy & Error Modeling**:
   - SQLite local caching via `sqflite`.
   - Offline banner appears when connection is lost; tasks remain fully readable and writable offline.
   - Automatic sync and conflict resolution (Last-Write-Wins) when connection restores.
   - Typed error modeling (`AppException`, `NetworkException`, `ServerException`, `CacheException`, `AuthException`) with context-aware error views.

5. **Theme Switcher**:
   - Toggle between Material 3 Light Mode and Dark Mode via the App Bar or Profile screen. Dark mode preference is persisted locally and in Firestore.

---

## 📦 Run Commands

```bash
# Run on connected device / emulator
flutter run

# Run full automated test suite
flutter test

# Run code analysis
flutter analyze
```

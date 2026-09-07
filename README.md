# 📱 Smart Task Manager

A production-grade, **offline-first Smart Task Manager** built with Flutter, Clean Architecture, BLoC State Management, REST API (Dio), SQLite local database, Firebase Authentication, and Cloud Firestore for user profiles and theme preferences.

---

## ✨ Features

### 🔐 1. Authentication (Firebase Auth)
- **Email & Password Authentication**: Secure sign-up, sign-in, and persistent session management.
- **Error Mapping**: Firebase authentication exceptions are mapped to domain-level `AuthFailure` instances with descriptive user feedback.
- **Session Persistence**: User sessions remain active across app restarts.
- **Account Isolation**: Task data and profiles are strictly partitioned by `user_id`.

### 🌐 2. Task Management (REST API with Dio)
- **Base URL**: `https://taskmanager.uat-lplusltd.com`
- **Endpoints Implemented**:
  - `GET /tasks/?user_id={uid}&skip={skip}&limit={limit}`: Paginated task retrieval with infinite scroll.
  - `POST /tasks/?user_id={uid}`: Create task with title, description, priority, category, and due date.
  - `PUT /tasks/{id}?user_id={uid}`: Update existing task details or completion status.
  - `DELETE /tasks/{id}?user_id={uid}`: Delete task permanently.
- **Dio Client Features**:
  - Automatically injects `user_id` query parameter for all task requests.
  - Custom Interceptors for request/response logging and network diagnostics.
  - Centralized Error Interceptor mapping HTTP status codes (400, 401, 403, 404, 500, network timeouts) to `ServerException` and `NetworkException`.

### 💾 3. Offline-First & Local Storage (SQLite)
- **SQLite Database (`sqflite`)**: Local cache with schema supporting integer task IDs, 8 categories, 3 priority levels, synchronization state (`is_synced`), and pending actions (`sync_action: CREATE, UPDATE, DELETE`).
- **Optimistic UI Updates**: Task creation, editing, and status toggles update local state and UI immediately.
- **Temporary ID Handling**: Offline created tasks receive negative local IDs (`-timestamp`), which are smoothly replaced by permanent server integer IDs upon background sync.
- **Auto-Sync on Reconnection**: Actively monitors connectivity changes; pending actions automatically synchronize when network is restored.
- **Offline Banner**: Persistent, non-intrusive offline banner alerts the user when working without internet connection.

### 👤 4. User Profile & Theme Preferences (Cloud Firestore)
- **Cloud Firestore Collection**: User profiles stored under `users/{userId}`:
  - `name`: User display name (editable).
  - `email`: User email address.
  - `createdAt`: Account registration timestamp.
  - `themeMode`: Theme preference (`system`, `light`, `dark`).
- **Real-Time Sync & Auto-Apply**: Theme preference is loaded from Firestore on login and applied immediately across the entire app.
- **Profile Management**: Profile screen allows updating display name and toggling theme with instant Firestore persistence.

### 🎨 5. UI/UX & Material 3 Design
- **Debounced Search**: 300ms debounce timer on search bar to prevent unnecessary query executions.
- **Category Filter Chips**: 8 distinct categories (*Work, Personal, Health, Finance, Education, Shopping, Travel, Others*) with custom icons and color palettes.
- **Priority Badges**: High, Medium, and Low priority indicators.
- **Sort Options**: Sort by Due Date (Asc/Desc), Priority (High to Low / Low to High), and Created Date.
- **Infinite Scrolling**: `ScrollController` triggers pagination fetching next page with `skip` and `limit` parameters.
- **App Launcher Icon**: High-resolution custom branding icon configured across all Android mipmap densities and iOS asset sets.

---

## 🏗️ Architecture & Project Structure

The codebase strictly follows **Clean Architecture** with separation of concerns:

```
lib/
├── core/
│   ├── database/             # SQLite DatabaseHelper (schema, indexes, CRUD)
│   ├── di/                   # GetIt Service Locator dependency injection
│   ├── error/                # AppException and Failure hierarchy
│   ├── network/              # ApiClient (Dio), NetworkInfo (connectivity_plus)
│   ├── router/               # GoRouter configuration with Auth guards
│   ├── services/             # NotificationService (FCM & Local Notifications)
│   ├── theme/                # AppColors, AppTheme, ThemeCubit
│   └── utils/                # DateFormatter and utility helpers
├── features/
│   ├── auth/
│   │   ├── domain/           # UserEntity, AuthRepository, AuthUseCases
│   │   ├── data/             # AuthRemoteDataSource, AuthRepositoryImpl
│   │   └── presentation/     # AuthBloc, LoginScreen, RegisterScreen
│   ├── profile/
│   │   ├── domain/           # UserProfileEntity, ProfileRepository, ProfileUseCases
│   │   ├── data/             # ProfileRemoteDataSource (Firestore), ProfileRepositoryImpl
│   │   └── presentation/     # ProfileBloc, ProfileScreen
│   └── tasks/
│       ├── domain/           # TaskEntity, Enums (TaskCategory, TaskPriority), UseCases
│       ├── data/             # TaskModel, TaskLocalDataSource, TaskRemoteDataSource, TaskRepositoryImpl
│       └── presentation/     # TaskBloc, TaskListScreen, TaskFormScreen, TaskDetailScreen, Widgets
├── firebase_options.dart     # Firebase project configuration
└── main.dart                 # Application entry point
```

---

## 🚀 Getting Started

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (3.24.0 or higher)
- [Android Studio](https://developer.android.com/studio) / Xcode
- Android SDK & Java 17+

### Installation & Run

1. **Install dependencies:**
   ```bash
   flutter pub get
   ```

2. **Run in Debug Mode:**
   ```bash
   flutter run
   ```

---

## 🧪 Testing & Verification

Run the comprehensive test suite and static analysis:

```bash
# 1. Static Analysis (Zero lints, zero warnings)
flutter analyze

# 2. Run all unit, widget, and BLoC tests (31 tests)
flutter test
```

### Test Highlights:
- **`TaskModelTest`**: JSON and SQLite serialization, schema validation, type conversions.
- **`ConflictResolverTest`**: Last-Write-Wins deterministic synchronization validation.
- **`UseCasesTest`**: Full test coverage of all domain use cases.
- **`TaskRepositoryImplTest`**: Remote API calls, local SQLite cache fallback, offline queueing.
- **`TaskBlocTest`**: BLoC states, pagination, optimistic UI updates, debounced search, filtering.
- **`TaskWidgetsTest`**: Material 3 widget rendering, form validation, priority badges.

---

## 📦 Building for Release

### Android Release APK
```bash
flutter build apk --release
```
The generated APK is located at:
```
build/app/outputs/flutter-apk/app-release.apk
```

---

## 📄 License
This project is licensed under the MIT License.

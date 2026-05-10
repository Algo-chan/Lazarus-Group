# LocalConnect - Project Overview

LocalConnect is a full-stack application designed to connect users with local professional services such as plumbing, gardening, electrical work, cleaning, and painting. It features a Flutter-based mobile/web frontend and a Node.js Express backend with a local file-based database.

## Architecture

- **Frontend:** Flutter application (Android, iOS, Web, Windows, macOS, Linux).
- **Backend:** Node.js Express server.
- **Database:** NeDB (local JSON-based datastore via `nedb-promises`).
- **Communication:** REST API via HTTP.

## Technologies

### Frontend (Flutter)
- **State Management:** Uses `SharedPreferences` for session persistence (JWT token, user data, guest mode) and `ValueNotifier` for global theme management.
- **Networking:** `http` package for API calls with built-in fallback to mock data on connection failure.
- **Authentication:** Supports standard email/password login, signup, and **Biometric Authentication** (via `local_auth`).
- **Theme:** Material 3 design with support for Light and Dark modes.
- **Navigation:** Standard Navigator-based routing.

### Backend (Node.js)
- **Framework:** Express.js.
- **Authentication:** JWT (JSON Web Tokens) for session management and Bcrypt for secure password hashing.
- **Database:** `nedb-promises` for asynchronous local file storage (`users.db` and `services.db`).
- **Middleware:** 
  - `morgan`: Request logging.
  - `cors`: Cross-Origin Resource Sharing (enabled for all origins).
  - `dotenv`: Environment variable management.
  - `joi`: Data validation (available for use).

## Project Structure

```text
Lazarus-Group/
├── lib/                        # Flutter application source code
│   ├── api_service.dart         # API integration logic & mock data
│   ├── main.dart                # App entry point & Theme configuration
│   ├── theme_provider.dart      # Global theme management (ValueNotifier)
│   ├── home_screen.dart         # Main dashboard with service listings
│   ├── login_screen.dart        # User authentication (Login & Biometrics)
│   ├── signup_screen.dart       # User authentication (Signup)
│   ├── profile_screen.dart      # User profile management
│   └── service_detail_screen.dart # Detailed view of a specific service
├── backend/                     # Node.js backend source code
│   ├── index.js                 # Server entry point & API routes
│   ├── database.js              # NeDB initialization & seeding logic
│   ├── .env                     # Backend environment variables
│   ├── users.db                 # NeDB users collection (auto-generated)
│   └── services.db              # NeDB services collection (auto-generated)
├── assets/images/               # Static images for service providers
└── pubspec.yaml                 # Flutter project configuration
```

## Building and Running

### 1. Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install)
- [Node.js & npm](https://nodejs.org/en/download/)

### 2. Run the Backend
The backend must be running for the frontend to fetch real-time data.
```bash
cd Lazarus-Group/backend
npm install
node index.js
```
The server will start on `http://localhost:3000`. It automatically seeds the database with initial services if it's empty.

### 3. Run the Frontend
```bash
cd Lazarus-Group
flutter pub get
flutter run
```
*Note: If running on a physical mobile device, update the `baseUrl` in `lib/api_service.dart` from `127.0.0.1` to your computer's local IP address.*

## Development Conventions

- **API Integration:** Centralize all API calls in `lib/api_service.dart`. Methods should include error handling and return mock data as a fallback to ensure the UI remains functional during backend downtime.
- **State Management:** 
  - Use `SharedPreferences` for long-term persistence (auth tokens, preferences).
  - Use `ValueNotifier` for simple global state like themes (`ThemeManager`).
- **Styling:** Adhere to Material 3 principles. Use `Theme.of(context).colorScheme` for dynamic coloring that respects the current theme mode.
- **Authentication:** 
  - Implement biometric login checks using `local_auth`.
  - Handle Guest Mode by setting the `isGuest` flag in `SharedPreferences`, allowing restricted access to service listings.
- **Error Handling:** Always wrap asynchronous calls (API, Biometrics, DB) in try-catch blocks and provide user feedback via `SnackBar`.

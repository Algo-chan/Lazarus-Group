# LocalConnect - Project Overview

LocalConnect is a full-stack application designed to connect users with local professional services such as plumbing, gardening, electrical work, cleaning, and painting. It features a Flutter-based mobile/web frontend and a Node.js Express backend with a local file-based database.

## Architecture

- **Frontend:** Flutter mobile/web application.
- **Backend:** Node.js Express server.
- **Database:** NeDB (local JSON-based datastore).
- **Communication:** REST API via HTTP.

## Technologies

### Frontend (Flutter)
- **State Management:** Uses `SharedPreferences` for session persistence (JWT token).
- **Networking:** `http` package for API calls.
- **Icons:** `cupertino_icons`.
- **UI:** Material 3 design with a custom theme defined in `lib/main.dart`.

### Backend (Node.js)
- **Framework:** Express.js.
- **Authentication:** JWT (JSON Web Tokens) and Bcrypt for password hashing.
- **Database:** `nedb-promises` for asynchronous local file storage.
- **Logging:** `morgan` for request logging.
- **Validation:** `joi` (available in dependencies, used for schema validation).

## Project Structure

```text
Lazarus-Group/
├── lib/                  # Flutter application source code
│   ├── api_service.dart   # API integration logic
│   ├── main.dart          # App entry point & Theme configuration
│   ├── home_screen.dart   # Main dashboard with service listings
│   ├── login_screen.dart  # User authentication (Login)
│   └── signup_screen.dart # User authentication (Signup)
├── backend/               # Node.js backend source code
│   ├── index.js           # Server entry point & API routes
│   ├── database.js        # NeDB initialization & seeding logic
│   ├── users.db           # NeDB users collection (auto-generated)
│   └── services.db        # NeDB services collection (auto-generated)
├── assets/images/         # Static images for service providers
└── pubspec.yaml           # Flutter project configuration
```

## Building and Running

### 1. Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install)
- [Node.js & npm](https://nodejs.org/en/download/)

### 2. Run the Backend
The backend must be running for the frontend to fetch data.
```bash
cd Lazarus-Group/backend
npm install
node index.js
```
The server will start on `http://localhost:3000`. It will automatically seed the database with initial services if it's empty.

### 3. Run the Frontend
```bash
cd Lazarus-Group
flutter pub get
flutter run
```
*Note: If running on a physical device, ensure the `baseUrl` in `lib/api_service.dart` is updated from `127.0.0.1` to your computer's local IP address.*

## Development Conventions

- **API Integration:** All API calls should be centralized in `lib/api_service.dart`.
- **Styling:** Follow the Material 3 theme defined in `lib/main.dart`. Avoid hardcoding colors; use `Theme.of(context).colorScheme`.
- **Authentication:** The app supports both Registered User and Guest modes. Guest mode allows viewing services but may restrict certain actions (to be implemented).
- **Database:** NeDB is used for simplicity. For production, consider migrating to MongoDB or PostgreSQL.

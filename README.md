# LocalConnect - Local Service Marketplace Platform

A full-stack, multi-platform local service marketplace that connects Ethiopian customers with local professional service providers. Inspired by platforms like TaskRabbit and Urban Company, but localized for the Ethiopian market with ETB pricing, Ethiopian phone number support, and local service categories.

---

## 🚀 Features

### Customer Features

* Browse and search local services
* Filter services by category, city, price, and rating
* Book services with date and time slot selection
* Manage and track bookings
* Save favorite services
* Write reviews and ratings
* Real-time chat with service providers
* Receive instant notifications

### Provider Features

* Create, edit, and manage service listings
* Manage incoming bookings
* View customer reviews and ratings
* Track earnings and performance
* Real-time messaging with customers
* Provider dashboard with analytics

### Admin Features

* Manage users and providers
* Verify service providers
* Moderate service listings
* Monitor platform activities
* Access analytics and reports
* View audit logs

### Guest Features

* Browse available services
* Search providers and categories
* View service details

---

# 🛠 Tech Stack

| Layer                   | Technology                               |
| ----------------------- | ---------------------------------------- |
| Frontend                | Flutter 3.x (Dart)                       |
| UI Framework            | Material 3                               |
| State Management        | Provider                                 |
| Routing                 | go_router                                |
| Backend                 | Node.js + Express 5.x                    |
| Authentication          | JWT, bcryptjs, jsonwebtoken              |
| Database                | NeDB                                     |
| Real-time Communication | Socket.IO                                |
| Platforms               | Android, iOS, Web, Windows, macOS, Linux |

---

# 🏗 System Architecture

```text
[Flutter App]
      |
      | HTTP/JSON
      v
[Node.js Express API]
      |
      | NeDB
      v
[JSON Files Storage]

      ^
      |
      | Socket.IO (Real-Time)
      |
      +----------------------+
```

---

# 📂 Project Structure

## Frontend Architecture

```text
lib/
├── core/
├── shared/
└── features/
    ├── auth/
    ├── search/
    ├── bookings/
    ├── customer/
    ├── provider/
    ├── admin/
    ├── chat/
    ├── notifications/
    ├── reviews/
    ├── settings/
    └── splash/
```

## Backend Architecture

```text
backend/
├── middleware/
├── routes/
├── utils/
├── database/
└── server.js
```

---

# 👥 Role-Based Access Control (RBAC)

| Role     | Level | Permissions                                 |
| -------- | ----- | ------------------------------------------- |
| Customer | 1     | Browse, search, book services, review, chat |
| Provider | 2     | Customer permissions + service management   |
| Admin    | 3     | Full platform administration                |

---

# 🗄 Database Collections

## users

```json
{
  "name": "",
  "email": "",
  "phone": "",
  "password_hash": "",
  "role": "",
  "is_verified": false,
  "is_active": true
}
```

## services

```json
{
  "title": "",
  "category": "",
  "provider_id": "",
  "description": "",
  "price": 0,
  "location": "",
  "avgRating": 0,
  "reviewCount": 0
}
```

## bookings

```json
{
  "service_id": "",
  "customer_id": "",
  "provider_id": "",
  "date": "",
  "timeSlot": "",
  "status": ""
}
```

### Additional Collections

* reviews
* chats
* messages
* notifications
* audit_logs

---

# 🔌 API Endpoints

## Authentication

| Method | Endpoint          |
| ------ | ----------------- |
| POST   | /api/auth/signup  |
| POST   | /api/auth/login   |
| GET    | /api/auth/me      |
| PUT    | /api/auth/me      |
| PUT    | /api/auth/profile |

## Services

| Method | Endpoint                      |
| ------ | ----------------------------- |
| GET    | /api/services                 |
| GET    | /api/services/categories/list |
| GET    | /api/services/:id             |
| POST   | /api/services                 |
| PUT    | /api/services/:id             |
| DELETE | /api/services/:id             |

## Bookings

| Method | Endpoint                 |
| ------ | ------------------------ |
| POST   | /api/bookings            |
| GET    | /api/bookings/my         |
| GET    | /api/bookings/provider   |
| PATCH  | /api/bookings/:id/status |

## Reviews

| Method | Endpoint                |
| ------ | ----------------------- |
| GET    | /api/reviews/:serviceId |
| POST   | /api/reviews/:serviceId |
| DELETE | /api/reviews/:id        |

## Chats

| Method | Endpoint                    |
| ------ | --------------------------- |
| POST   | /api/chats                  |
| GET    | /api/chats                  |
| GET    | /api/chats/:chatId/messages |
| POST   | /api/chats/:chatId/messages |

## Notifications

| Method | Endpoint                    |
| ------ | --------------------------- |
| GET    | /api/notifications          |
| PATCH  | /api/notifications/read-all |

## Admin

* User Management
* Service Moderation
* Booking Management
* Analytics
* Audit Logs

---

# ⚡ Real-Time Events

The platform uses Socket.IO for real-time communication.

### Supported Events

* join_chat
* new_message
* new_booking
* booking_status
* new_review
* notification

---

# 📱 Application Screens

```text
Splash
 └── Authentication
      ├── Login
      ├── Signup
      └── Forgot Password

Customer
 ├── Dashboard
 ├── Search Results
 ├── Service Detail
 ├── Booking Flow
 ├── My Bookings
 ├── Reviews
 └── Saved Services

Provider
 ├── Dashboard
 ├── Create/Edit Service
 ├── My Services
 ├── Incoming Bookings
 ├── Earnings
 └── Reviews

Shared
 ├── Chat List
 ├── Chat Screen
 └── Notifications

Admin
 ├── Dashboard
 ├── User Management
 ├── Services Control
 ├── Booking Management
 ├── Reports
 └── Platform Settings
```

---

# 🚀 Getting Started

## Backend Setup

```bash
cd backend
npm install
npm start
```

Server runs at:

```text
http://localhost:3000
```

## Frontend Setup

```bash
flutter pub get
flutter run
```

---



# 📄 License

This project is intended for educational and portfolio purposes. Feel free to modify and extend it according to your requirements.

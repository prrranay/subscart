# Subscart - Subscription Meal Management System

A full-stack, production-grade Meal Subscription Management System built with **Flutter** (Material 3, Riverpod, Animations) and **NestJS** (TypeScript, MongoDB/Mongoose, Luxon timezone-safe cutoff engine).

---

## 🌟 Key Features

### 1. Subscription Meal Schedule Management
- **Skip Meal**: Skip scheduled meals with dietary reasons and instant optimistic updates.
- **Swap Meal**: Browse alternative chef-crafted bowls & plates with macro badges, dietary filters, and Hero transitions.
- **Move Meal Slot**: Move meals across calendar dates and meal windows (`Breakfast`, `Lunch`, `Dinner`) with conflict detection.
- **Reschedule**: Change delivery dates with live slot conflict checking.
- **Pause & Resume Subscription**: Toggle plan status to lock/unlock modifications with one tap.
- **Instant Undo**: Floating snackbars allowing one-tap rollback of accidental skips or swaps.

### 2. Kitchen Cutoff Engine (Authoritative Backend)
- **Timezone-Safe**: Calculates cutoff deadlines at **8:30 PM on the day before delivery** in the user's IANA timezone (`Asia/Kolkata`) using **Luxon**.
- **Past-Cutoff Protection**: Rejects mutations with `400 EDIT_CUTOFF_PASSED` when the cutoff has passed.
- **UI Guardrails**: Dynamically disables closed dates with lock icons and strike-through indicators so users cannot schedule into expired kitchen batches.

### 3. Fully Responsive Design (360dp – 430dp)
- Tested across standard Android viewports (`360x800`, `390x844`, `412x915`).
- Safe modal titles, auto-scrolling date strips, and keyboard-safe bottom sheets with `SafeArea`.

---

## 🏗️ Tech Stack

### Frontend (Mobile App)
- **Framework**: Flutter 3.x (Dart 3.x)
- **State Management**: Flutter Riverpod (`StateNotifierProvider`, `StreamProvider`, `FutureProvider`)
- **Networking**: Dio with interceptors, error handling, and timeout configurations
- **Design System**: Nourish Botanical palette (Forest Green `#1B4D3E`, Matcha `#4E8752`, Light Wheat `#FAF7F2`)
- **Typography**: Google Fonts (*Plus Jakarta Sans*)

### Backend (REST API)
- **Framework**: NestJS (Node.js & TypeScript)
- **Database**: MongoDB with Mongoose ORM
- **Timezone & Date Math**: Luxon (`DateTime.fromISO(..., { zone })`)
- **Validation**: `class-validator` & `class-transformer`
- **Documentation**: Swagger OpenAPI (`/api/docs`)

---

## 📁 Repository Structure

```
subscart/
├── backend/                  # NestJS API & Cutoff Engine
│   ├── src/
│   │   ├── common/           # Error filters, DTOs & Constants
│   │   ├── cutoff/           # Timezone-Safe Cutoff Engine (Luxon)
│   │   ├── meal-catalog/     # Meal models & catalog service
│   │   ├── schedule/         # Schedule routes, mutations & Undo
│   │   ├── subscription/     # Subscription management & pause toggle
│   │   ├── main.ts           # Server bootstrap & Swagger setup
│   │   └── seed.ts           # Database population script
│   └── test/                 # Jest Unit & Integration Tests
│
└── frontend/                 # Flutter Mobile Application
    ├── lib/
    │   ├── core/             # Theme, Colors, Network Client, Utils
    │   └── features/schedule # Models, Providers, Widgets & Modals
    └── test/                 # Widget, Provider & Multi-Screen Tests
```

---

## 🚀 Quick Start Guide

### 1. Prerequisites
- **Node.js** (v18+) & **npm**
- **MongoDB** running locally on `mongodb://127.0.0.1:27017`
- **Flutter SDK** (3.22+)

---

### 2. Backend Setup & Run

1. Navigate to the backend folder:
   ```bash
   cd backend
   ```
2. Install dependencies:
   ```bash
   npm install
   ```
3. Run the database seed script:
   ```bash
   npm run seed
   ```
   *Populates Demo User (`Pranay Kumar`), Active Subscription, 9 gourmet meals with full macros, and 22 scheduled orders across 14 dates.*

4. Run unit and integration tests:
   ```bash
   npm test
   ```

5. Start the development server:
   ```bash
   npm run start:dev
   ```
   - **API URL**: `http://localhost:3000` (or `http://192.168.1.36:3000` on LAN)
   - **Swagger Docs**: `http://localhost:3000/api/docs`

---

### 3. Frontend Setup & Run

1. Navigate to the frontend folder:
   ```bash
   cd frontend
   ```
2. Install Flutter packages:
   ```bash
   flutter pub get
   ```
3. Run test suites:
   ```bash
   flutter test
   ```
4. Launch on Chrome or connected Android device:
   ```bash
   # Run on Chrome
   flutter run -d chrome

   # Run on physical Android device over Wi-Fi / ADB
   flutter run -d 192.168.1.35:5555 --dart-define=API_BASE_URL=http://192.168.1.36:3000
   ```

---

## 📡 API Endpoints Summary

| Method | Endpoint | Description |
|---|---|---|
| `GET` | `/schedule` | Get full meal schedule, active orders & cutoff config |
| `PATCH` | `/schedule/:id/skip` | Skip scheduled meal |
| `PATCH` | `/schedule/:id/swap` | Swap meal with alternative dish |
| `PATCH` | `/schedule/:id/move` | Move meal to target date and slot |
| `PATCH` | `/schedule/:id/reschedule` | Reschedule meal delivery date |
| `PATCH` | `/schedule/:id/undo` | Undo previous mutation |
| `POST` | `/subscription/pause` | Toggle pause/resume subscription status |
| `GET` | `/meals` | Retrieve all available meals with macros |

---


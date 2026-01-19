# Veena Public School (VPS) App

A comprehensive school management application built with Flutter and Firebase.

## Features

### 🔐 Role-Based Access
- **Student**: View Fees, Attendance, Results, Homework.
- **Teacher**: Mark Attendance, Create Assignments.
- **Principal**: Approve Users, Manage Fees, Post Announcements.
- **Management (Super Admin)**: Centralized dashboard for all modules.

### 💰 Fee & Payments
- **Razorpay Integration**: Online fee payments.
- **Fee Management**: Create, Update, and Track student fees.
- **Automatic Status**: Fees auto-update to 'Paid' upon successful transaction.

### 📢 Communication
- **Announcements**: Broadcast messages to all users.
- **Push Notifications**: Integrated with FCM for real-time alerts.

## Setup & Configuration

### 1. Firebase Setup
- Ensure `google-services.json` is present in `android/app/`.
- Enable **Authentication** (Email/Password).
- Enable **Firestore Database**.

### 2. Push Notifications
- Project uses `firebase_messaging`.
- Notifications work in Foreground (Local Notification) and Background (System Tray).

### 3. Payment Gateway (Razorpay)
- **Important**: The project is currently configured with a **LIVE KEY** in `lib/data/services/payment_service.dart`.
- For development/testing, switch to a Test Key (`rzp_test_...`).

### 4. Management Role (Super Admin)
There is no UI to sign up as 'Management'. To create an admin:
1.  Register a new user in the app.
2.  Go to **Firestore Console** > `users` collection.
3.  Find the user and update:
    - `role`: `'management'`
    - `isApproved`: `true`

## Build

To build the release APK for Android:
```bash
flutter build apk --release
```

## Folder Structure
- `lib/data`: Models and Firebase Services.
- `lib/features`: UI Screens organized by module (Auth, Fees, Attendance, etc).
- `lib/core`: Constants and Utils.

# 💰 Artho - Personal Finance Tracker

Artho is a **Flutter based personal finance tracking app** that helps users manage their **income, expenses, and financial balance** in a simple and clean interface.

The app allows users to track daily spending, view financial summaries, and maintain control of their financial activities.

---

# 📱 Features

### 🔐 Authentication

* Secure login & signup using **Firebase Authentication**
* Email verification for email updates

### 💵 Transaction Management

* Add income and expense transactions
* Edit and delete previous transactions
* Categorize transactions
* Real-time updates using **Firestore**

### 📊 Financial Overview

* Account balance calculation
* Monthly income & expense summary
* Recent transaction list

### ⏱ Smart Filters

View transactions based on:

* Today
* Week
* Month
* Year

### 👤 User Profile

* Change profile name
* Change email
* Upload profile picture (stored locally)
* Dark mode toggle
* Logout functionality

### 🔔 Notifications

* Notification screen for important app alerts

### 📄 Auto Monthly Report

* Generates a monthly financial summary automatically

---

# 🛠 Tech Stack

**Frontend**

* Flutter
* Dart

**Backend / Services**

* Firebase Authentication
* Cloud Firestore

**Local Storage**

* SharedPreferences

**Other Packages**

* image_picker
* intl

---

# 📂 Project Structure

```
lib/
│
├── models/
│   └── transaction_model.dart
│
├── screens/
│   ├── home_screen.dart
│   ├── profile_screen.dart
│   ├── notification_screen.dart
│
├── services/
│   └── firestore_service.dart
│
├── utils/
│   └── auto_monthly_report.dart
│
└── main.dart
```

---

# 🚀 Getting Started

### 1️⃣ Clone the repository

```bash
git clone https://github.com/yourusername/artho_app.git
```

### 2️⃣ Go to project directory

```bash
cd artho_app
```

### 3️⃣ Install dependencies

```bash
flutter pub get
```

### 4️⃣ Run the app

```bash
flutter run
```

---

# 🔥 Firebase Setup

To run this project you must connect it with your Firebase project.

### Steps

1. Create project in **Firebase Console**
2. Enable:

   * Authentication (Email/Password)
   * Cloud Firestore
3. Download `google-services.json`
4. Place it in:

```
android/app/google-services.json
```

5. Run:

```
flutterfire configure
```

---

# 📸 Screenshots

Add screenshots here for better project presentation.

```
screenshots/
home.png
profile.png
transactions.png
```

Example:

| Home Screen | Profile Screen |
| ----------- | -------------- |
| Screenshot  | Screenshot     |

---

# 🎯 Future Improvements

* Expense category charts
* Budget tracking
* Cloud backup & restore
* Multi-device sync
* Export reports (PDF)

---

# 👨‍💻 Author

Developed by **Tauhid Musa Rieon**

GitHub:
https://github.com/tauhidmusarieon

---

# ⭐ Support

If you like this project, please **star the repository** ⭐

It helps others discover the project and motivates further development.

---

# 📄 License

This project is licensed under the **MIT License**.

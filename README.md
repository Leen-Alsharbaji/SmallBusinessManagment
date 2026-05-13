# Small Business Management App

A Flutter-based inventory and sales management solution for small businesses. Manage products, track stock levels, and record sales across web and mobile platforms.

## Features

* **Authentication** — Email/password sign-in via Firebase Auth
* **Product Management** — View product catalog, add new products, update stock quantities
* **Sales Tracking** — Record manual sales entries with automatic stock deduction
* **Dashboard** — Centralized view of inventory status and sales activity
* **Responsive UI** — Works on web and mobile (Android/iOS with additional setup)

## Tech Stack

| Category             | Technology                              |
| -------------------- | --------------------------------------- |
| Framework            | Flutter (Dart SDK 3.11+)                |
| Authentication       | Firebase Auth                           |
| Database             | Cloud Firestore                         |
| UI Components        | responsive_grid_list, flutter_side_menu |
| Firebase Integration | firebase_core, firebase_ui_auth         |

## Getting Started

### Prerequisites

* Flutter SDK installed ([installation guide](https://docs.flutter.dev/get-started/install))
* Firebase project created ([Firebase Console](https://console.firebase.google.com/))
* Web app registered in Firebase (for web deployment)

### Installation

1. Clone the repository

```bash
git clone <repository-url>
cd <project-directory>
```

2. Install dependencies

```bash
flutter pub get
```

3. Configure Firebase

   **For Web (currently configured):**

   * `firebase_options.dart` already contains web configuration
   * Run directly with `flutter run -d chrome`

   **For Android/iOS (requires additional setup):**

   ```bash
   dart pub global activate flutterfire_cli
   flutterfire configure
   ```

   * Follow the CLI prompts to select your Firebase project

4. Run the app

```bash
flutter run -d chrome
flutter run
```

## Project Structure

```
lib/
├── main.dart                 # App entrypoint, Firebase initialization
├── app.dart                  # MyApp widget, route definitions
├── screens/
│   ├── home_screen.dart               # Dashboard
│   ├── product_stock_view_screen.dart # Stock grid view
│   ├── manual_sale_entry_form.dart    # Sales entry form
│   ├── profile_screen.dart            # User profile
│   └── (manual product entry forms)   # Product management
├── widgets/                  # Reusable UI components
└── assets/
    └── products.json         # Seed/demo product data
```

## Routes

| Path                      | Screen                 | Description                       |
| ------------------------- | ---------------------- | --------------------------------- |
| `/sign-in`                | SignInScreen           | Authentication entry              |
| `/`                       | HomeScreen             | Main dashboard                    |
| `/profile`                | ProfileScreen          | User account settings             |
| `/product-stock`          | ProductStockViewScreen | Product listing with stock levels |
| `/manual-sale-entry-form` | SalesEntryForm         | Record manual sales               |

## Current Status

| Feature                        | Status            |
| ------------------------------ | ----------------- |
| Firebase Auth (email/password) | ✅ Complete        |
| Sign-in / Sign-out flow        | ✅ Complete        |
| Product stock viewing          | ✅ Complete        |
| Manual product entry           | ✅ Complete        |
| Stock quantity updates         | ✅ Complete        |
| Manual sale entry              | ✅ Complete        |
| Dashboard analytics            | ✅ Complete        |
| Android/iOS Firebase config    | ⚠️ Requires setup |
| Tests                          | 📝 Planned        |

## Known Limitations

* Firebase configuration currently supports **web only**. For mobile deployment, run `flutterfire configure` to generate native platform options.
* No automated tests are present in the current codebase.
* Demo product data is loaded from local JSON; production use requires Firestore integration.

## Development Notes

### Adding a new product

Navigate to the manual product entry screen → fill form → submit → product saved to Firestore

### Recording a sale

Go to manual sale entry form → select product → enter quantity → confirm → stock automatically deducted

### Viewing inventory

Main dashboard and product stock screen show real-time stock levels from Firestore


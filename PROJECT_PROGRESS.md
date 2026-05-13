# Project Progress Log

This document tracks progress on the Small Business Management app. Update with dates and short notes as work proceeds.

## Summary (current state)

- Firebase initialization and connection — Done
- Firebase Authentication (sign in / sign out) — Done
- Responsive app scaffold (side menu) — Done (menu visible when authenticated; responsive behaviour)
- Product stock view with responsive grid and ProductCard — Done (added top padding and card-level top padding)
- Manual sales entry form with product dropdown and import helper — Done (has `_importProductsFromJson`)


---

## Completed tasks (high level)

- Set up Flutter project and connected to Firebase.
- Implemented Firebase sign-in using `firebase_ui_auth`.
- Consolidated `MyApp` in `app.dart` and cleaned main entry in `main.dart`.
- Created `AppScaffold` for consistent responsive shell and menu behavior.
- Implemented product import helper in manual sales form.
- Implemented product grid and product card UI.


---

## In-progress / Needs review

- Marketplace connection flows (OAuth/API keys storage and encrypted secrets).
- Firestore security rules — not yet added. Needs role-based and user-based access control.
- Sync / matching pipeline between `raw_products` and `unified_products` (deduping and matching confidence).


---

## Next actions

1. Add Firestore security rules and test authentication flows.
2. Implement marketplace connection UI and secure storage/encryption of API keys.
3. Add product matching/merge tooling (ML or heuristics) to populate `unified_products`.
4. Add end-to-end tests for core flows (sign-in, create order, update stock, import products).


---

## Notes and tips

- The `AppScaffold` will show the navigation menu only when `FirebaseAuth.instance.currentUser != null`.
- Data import helper expects `products.json` to be available in the app bundle; add it to `pubspec.yaml` under `assets` if bundling.


---

_Last updated: ${DateTime.now().toIso8601String()}

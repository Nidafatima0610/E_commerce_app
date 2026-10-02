# Flutter E-Commerce App

A complete, polished, and internship-ready Flutter E-Commerce application demonstrating clean architecture, solid state management, and modern UI/UX design.

## 🚀 Main Features
- **Dynamic Product Catalog**: Browse products by category, view detailed product pages with image galleries, pricing, and ratings.
- **Robust Cart & Checkout**: Fully functional cart with persistent state, coupon code validation (percentage & fixed discount), shipping calculation, and local address management.
- **Order History & Tracking**: View active, completed, and canceled orders. Dive into order details to view itemized receipts and payment methods.
- **Dark Mode Support**: A seamless, instant toggle between a vibrant Light Mode and a sleek Dark Mode that respects the Material 3 design language.
- **Search & Discovery**: Persistent search history, dynamic filtering, and a dedicated "Recently Viewed" section that stores your interactions.

## 🛠️ Technologies Used
- **Flutter & Dart**: The core framework and language.
- **Riverpod (3.0+)**: For robust, predictable, and scalable state management (`Notifier`, `NotifierProvider`).
- **SharedPreferences**: For local persistence of the Cart, Wishlist, Addresses, Search History, Theme Preferences, and Orders.

## 📁 Architecture & State Management
This project utilizes a **Feature-based / Clean Architecture** approach tailored for Riverpod:
- `/models`: Immutable data classes (Product, Order, Address, CartItem, Coupon) with JSON serialization.
- `/providers`: Riverpod `Notifier` classes that handle business logic independently of the UI.
- `/screens`: Pure UI presentation layers that `ref.watch` state changes.
- `/core`: Utility classes such as `LocalStorageService` to abstract away direct API/SharedPreference calls, and `AppTheme` for centralized design tokens.

## 📱 Screens
1. **Home Screen**: Highlights trending products, categories, and recently viewed items.
2. **Search Screen**: Displays search history and filters products dynamically.
3. **Product Details**: Expandable specifications, related products, and interactive add-to-cart/wishlist states.
4. **Cart & Checkout**: Coupon validation, dynamic totals, and address selection logic.
5. **Profile & Order History**: Centralized user settings, dark mode toggle, and detailed expandable order receipts.

## ⚙️ How to Run
1. Ensure you have Flutter installed (`flutter doctor`).
2. Clone this repository and run:
   ```bash
   flutter pub get
   ```
3. Run the application on an emulator or physical device:
   ```bash
   flutter run
   ```

## 🔮 Future Improvements
- **Backend Integration**: Replace `LocalStorageService` with Firebase/Supabase for real-time cloud syncing.
- **Real Authentication**: Implement OAuth (Google/Apple) instead of a mock local user profile.
- **Payment Gateway**: Connect Stripe or Razorpay SDKs inside the Checkout flow instead of dummy mock transactions.
- **Push Notifications**: Integrate Firebase Cloud Messaging (FCM) to notify users of order status updates.

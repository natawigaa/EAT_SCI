## Copilot / AI Agent instructions for Eat_Sci (Flutter)

Purpose: help an AI coding agent be productive quickly in this repository. Keep suggestions focused, code-aware, and safe to apply.

Quick facts
- Flutter app (lib/) using Supabase (supabase_flutter).
- Simple service-based state: `CartService` (singleton) and `SupabaseService` (static wrappers).
- QR payment UI lives in `lib/innnerScreen/PaymentScreen.dart` (uses `qr_flutter`).

Key files to inspect before editing
- `lib/services/cart_service.dart` — cart data shape and helper methods. Use `addToCart(menuItem, restaurantId, restaurantName)` to add items.
- `lib/services/supabase_service.dart` — all Supabase queries and test logging. Follow its patterns for reads.
- `lib/screen/FoodOrderScreen.dart` — cart UI and bottom padding hack (EdgeInsets.fromLTRB(..., 100)) to avoid bottom nav overlap.
- `lib/innnerScreen/PaymentScreen.dart` — QR code rendering and payment flows.
- `lib/config/supabase_config.dart` and `lib/main.dart` — Supabase initialization.
- `pubspec.yaml` — dependencies (e.g., `qr_flutter`, `supabase_flutter`).

Data shapes & conventions
- Menu items pulled from Supabase: fields expected: `id`, `name`, `price`, `image_url`, `category`, `restaurant_id`.
- Cart item structure (created by `CartService.addToCart`):
  - `itemId`, `restaurantId`, `restaurantName`, `imgUrl`, `foodname`, `price`, `quantity`, `specialRequest`, `addOns`.
  - UI code reads `imgUrl` and expects a URL (use `Image.network`).

Common patterns to follow
- Use `CartService()` singleton to read/modify cart state. Many screens call `CartService()` directly rather than Provider.
- Supabase queries are centralized in `SupabaseService`. Add new DB writes there using `Supabase.instance.client`.
- UI code contains Thai comments and prints; preserve existing logging style when adding debug prints.

Build / run / debug
- Start app locally: `flutter pub get` then `flutter run -d windows` (or choose device/target).
- Quick static checks: `flutter analyze` and `dart format .`.
- Logs: many services use `print()`—read the terminal for traces (SupabaseService logs queries and menu details).

Small, low-risk tasks examples (how to implement)
- Fix bottom-safe-area behavior: replace fixed `padding: EdgeInsets.fromLTRB(...,100)` in `FoodOrderScreen._buildBottomSection()` with `padding: EdgeInsets.fromLTRB(16,16,16, MediaQuery.of(context).padding.bottom + 80)` and wrap controls in `SafeArea(bottom: true)`.
- Make QR download distinct from confirm: In `PaymentScreen`, separate `_downloadQRCode()` (save file or show SnackBar) from `_confirmPayment()` that shows the success dialog.
- Add order submission: create `SupabaseService.createOrder(Map order)` that inserts into `orders` and `order_items` tables, then call it from PaymentScreen after confirmation.

Code review hints for PRs
- Ensure you don't change the singleton contract in `cart_service.dart` (public getters: `cartItems`, `totalAmount`, `totalItems`).
- When adding network images confirm `Image.network` has `loadingBuilder` and `errorBuilder` as current code does.
- Keep UI safe-area aware — many fixes earlier used extra bottom padding; prefer `SafeArea` and MediaQuery for robustness.

What NOT to do
- Don't change the Supabase URL/key in `main.dart` or commit real secret keys. Use `lib/config/supabase_config.dart` for config changes and note TODO there.
- Don't remove `print()` debug lines before testing — they are intentionally used as lightweight tracing.

If you're unsure
- Read `lib/services/supabase_service.dart` and `lib/services/cart_service.dart` first. They reveal data flows and canonical helpers.
- Ask for the specific device/OS target (Windows vs Android/iOS) before making platform-specific changes.

Next steps / follow-up from AI
- After applying a code change, run `flutter analyze` and `flutter run -d windows` and report any analyzer errors or runtime exceptions and the precise file/line.

-- End

# 📚 Shelfwise

**A responsive library management web app built with Flutter.**

Shelfwise gives a small library a single place to catalogue books, register
members, issue and return copies, and keep an eye on overdue loans. It is a
front-end only demo app — no account, no backend, no configuration — so you can
clone it and have a working library desk in the browser in under a minute.

![Flutter](https://img.shields.io/badge/Flutter-3.47-02569B?logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-3.13-0175C2?logo=dart&logoColor=white)
![Platform](https://img.shields.io/badge/platform-web-1F5A4A)
![License](https://img.shields.io/badge/license-MIT-B5832F)

---

## ✨ Features

| Area | What you can do |
| --- | --- |
| **Dashboard** | Collection KPIs, six-month checkout chart, genre mix, recent loans, overdue spotlight and all-time most-borrowed titles. |
| **Catalogue** | Search by title, author, ISBN or genre; filter by genre and availability; sort; add, edit and delete titles; export the catalogue as CSV. |
| **Members** | Register students, faculty and community members; search and filter; see how many books each member holds against their tier limit. |
| **Loans** | Issue a copy with a 7/14/21/28-day loan period, mark returns, renew for another week, and filter by on-loan, overdue or returned. |
| **Settings** | System / light / dark appearance, library profile, CSV export and a one-click reset back to the demo data. |

### Highlights

- 📱 **Responsive by design** — a full sidebar on large screens, an icon rail on
  tablets and a drawer on phones.
- 🎨 **Custom design language** — warm paper palette with ink-green and brass
  accents, plus a matching dark theme, built on Material 3.
- 🧠 **Real library rules** — copy availability, tier-based borrowing limits,
  duplicate-loan prevention and overdue tracking are enforced in the data layer,
  not just in the UI.
- 🪶 **Zero runtime dependencies** — only the Flutter SDK. State is shared with a
  `ChangeNotifier` and an `InheritedNotifier`, so `pub get` stays tiny.
- ✅ **Tested** — 15 unit and widget tests cover the loan lifecycle, catalogue
  rules and the main navigation flow.

---

## 🖼️ The workspace

| Screen | Purpose |
| --- | --- |
| **Dashboard** | "How is the library doing today?" — headline numbers, activity trends and items that need attention. |
| **Catalogue** | The full book inventory, with copy counts and per-title actions. |
| **Members** | Membership records, tiers and current borrowing load. |
| **Loans** | Every checkout, its due date and its status. |
| **Settings** | Theme, library details and data tools. |

> The app starts with 12 books, 7 members and 9 loan records (two of them
> overdue) so every screen has something meaningful to show. Everything lives in
> memory for the session — refresh the page or use **Settings → Reset demo data**
> to start fresh.

---

## 🚀 Getting started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) **3.32 or newer**
  (developed against Flutter 3.47 / Dart 3.13)
- Google Chrome (or any Chromium-based browser) for `flutter run -d chrome`

### Run locally

```bash
git clone https://github.com/Jaswanthop/library-management-flutter.git
cd library-management-flutter

flutter pub get
flutter run -d chrome
```

### Build for the web

```bash
flutter build web --release
```

The output lands in `build/web`. Serve it with any static file server:

```bash
python -m http.server 8080 --directory build/web
# then open http://localhost:8080
```

### Deploy to GitHub Pages

If the site is hosted at `https://<user>.github.io/<repo>/`, build with the
repository name as the base path:

```bash
flutter build web --release --base-href /<repo>/
```

Then publish the contents of `build/web` (for example with the
`peaceiris/actions-gh-pages` GitHub Action).

---

## 🧭 Using Shelfwise

1. **Add stock** — *Catalogue → Add book*. Title and author are required; copies
   default to 1 and become borrowable immediately.
2. **Register people** — *Members → Register member*. Pick a tier: Student
   (3 books at a time), Faculty (6) or Community (2).
3. **Lend a copy** — *Loans → Issue a book* (or the issue action on any book or
   member row). Choose the title, the member and a loan period. The due date is
   previewed before you confirm.
4. **Bring it back** — use the row menu on a loan and choose *Mark as returned*.
   The copy returns to the shelf automatically.
5. **Chase late books** — the dashboard's *Needs attention* panel and the
   *Overdue* filter on the Loans screen highlight anything past its due date;
   renew a loan by 7 days from the row menu.

### Rules built into the store

- A copy cannot be issued when `availableCopies` is 0.
- A member cannot hold more books than their tier allows.
- The same member cannot borrow the same title twice at once.
- Inactive memberships cannot borrow.
- Copies cannot be reduced below the number currently on loan, and a title with
  active loans cannot be deleted.
- Returning a loan restores exactly one copy (never above the total).
- Overdue status is derived from the due date, so it stays correct as time passes.

---

## 🗂️ Project structure

```text
lib/
├── main.dart                  # entry point
├── app.dart                   # MaterialApp, theme mode, store ownership
├── models/                    # immutable Book, Member, Loan (+ copyWith)
├── data/
│   ├── library_store.dart     # ChangeNotifier store, rules, LibraryScope
│   └── seed_data.dart         # demo catalogue
├── screens/
│   ├── dashboard_screen.dart
│   ├── books_screen.dart
│   ├── members_screen.dart
│   ├── loans_screen.dart
│   └── settings_screen.dart
├── shell/app_shell.dart       # sidebar / rail / drawer + top bar
├── dialogs/                   # book, member, loan and confirm dialogs
├── widgets/                   # cards, pills, stat tiles, charts, fields
├── theme/app_theme.dart       # light + dark themes and semantic colours
└── utils/                     # date formatting and snackbars
test/
├── library_store_test.dart    # loan lifecycle, limits and catalogue rules
└── widget_test.dart           # dashboard, navigation and issue dialog
web/                           # index.html (with splash), manifest and icons
```

### Architecture notes

- **One store, no packages.** `LibraryStore` extends `ChangeNotifier`;
  `LibraryScope` is an `InheritedNotifier<LibraryStore>` so any widget can call
  `LibraryScope.of(context)` and rebuild on changes. `LibraryScope.read(context)`
  is the non-subscribing variant used by callbacks.
- **Immutable models.** `Book`, `Member` and `Loan` are `@immutable` with
  `copyWith`; the store replaces items instead of mutating them, which makes
  availability easy to reason about.
- **Guards throw `LibraryException`.** The UI catches those and shows a floating
  snackbar, so invalid actions are never silent.
- **Responsive breakpoints.** ≥1180 px shows the full sidebar, ≥780 px an icon
  rail, below that a drawer; content grids reflow between 1–4 columns.
- **Theme tokens.** Colours that Material does not model (success, warning,
  danger, chart palette) are exposed through a `ThemeExtension<AppColors>`.

---

## 🧪 Testing and quality

```bash
flutter analyze   # no issues
flutter test      # 15 tests
```

The suite covers:

- issuing, returning and renewing loans;
- availability accounting and the copy-invariant;
- tier loan limits, duplicate loans and inactive members;
- duplicate ISBNs, email validation and delete guards;
- genre aggregation and the demo reset;
- widget-level navigation and the issue-loan dialog.

To test a production build:

```bash
flutter build web --release
```

---

## 🗺️ Ideas for next steps

- Persist the session with `shared_preferences` or IndexedDB.
- Swap the in-memory store for a REST/Firebase backend.
- Email reminders for overdue loans.
- Barcode/ISBN scanning and import from a spreadsheet.
- Fine calculation and printable receipts.

---

## 📄 License

Released under the [MIT License](LICENSE). The demo catalogue data is fictional
and included purely to illustrate the app.

# Pennywise — Offline Expense Management

Flutter Android expense manager. No account, backend, server or internet connection is required. Financial records are stored in a local SQLite database.

## Implemented
- Dashboard with monthly income, expenses, net cash flow and recent activity.
- Add, edit, search, filter and delete income and expense transactions.
- Multiple local accounts: cash, bank accounts, wallets and credit cards.
- Default and custom income/expense categories.
- Monthly category budgets with spent, remaining and over-budget indicators.
- Monthly reports with income, expenses, net savings and category breakdown.
- Integer minor-unit money storage and local transaction timestamps.
- Flutter setState for UI state; no state-management package.

## Run
Install Flutter stable and Android SDK, then run flutter pub get and flutter run on an Android device or emulator.

## Privacy
SQLite is stored in the app's private device storage. No sign-in, remote API or server is used. Uninstalling the app or clearing its storage removes the local database. Backup/restore and export are planned follow-up features.

## Planned follow-up
Recurring transactions and reminders, savings goals, debt tracking, transfers between accounts, date-range reports, CSV/PDF export, and backup/restore.

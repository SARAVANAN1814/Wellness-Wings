# Wellness Wings - Developer Guide & Onboarding

Welcome to the **Wellness Wings** project! This guide will help you understand the project structure, how to collaborate, what extensions you need, and how to set everything up locally.

---

## 📁 1. Project Structure

The codebase is split into three main components: a **Flutter frontend**, a **Node.js Express backend**, and a **PostgreSQL database**.

```text
Wellness Wings/
├── backend/                  # Node.js backend using Express
│   ├── config/               # Database and environment configurations
│   ├── middleware/           # Express middleware (e.g., auth routing)
│   ├── routes/               # API endpoint route handlers
│   ├── server.js             # Main entry point for the backend server
│   ├── .env                  # Environment variables (PORT, JWT_SECRET, etc.)
│   └── package.json          # Node.js project dependencies
├── database/                 # Database Scripts
│   └── init.sql              # Initialization script for PostgreSQL tables
├── lib/                      # Flutter Frontend Code (Mobile/Web/Desktop)
│   ├── main.dart             # App entry point
│   └── ...                   # Screens, widgets, and app logic
├── android/, ios/, web/      # Platform-specific Flutter directories
├── pubspec.yaml              # Flutter dependencies configuration
└── README.md                 # Original auto-generated flutter readme
```

---

## 🤝 2. How to Collaborate on GitHub

Since the repository is already on GitHub, the repository owner needs to invite you to collaborate.

**Instructions for the Repository Owner:**
1. Open the repository on **GitHub** in your web browser.
2. Click on the **Settings** tab located near the top right of the repository page.
3. In the left sidebar, click on **Collaborators** (under the "Access" section).
4. Click the green button that says **Add people**.
5. Type your teammate's GitHub **username** or **email address**, select them from the dropdown, and click **Add to this repository**.
6. The teammate will receive an email invitation to join. Once they click **Accept Invitation**, they will have push/pull access.

**Instructions for the Teammate:**
1. Accept the email invitation.
2. Clone the repository to your local machine using git:
   ```bash
   git clone <repository_url>
   ```

---

## 💻 3. VS Code Extensions to Install

To ensure a smooth local development experience, it is highly recommended you install the following **Visual Studio Code Extensions**:

1. **Flutter** `(dart-code.flutter)` - Essential for running and debugging the Flutter application.
2. **Dart** `(dart-code.dart-code)` - Installed automatically with Flutter, provides language support.
3. **Prettier - Code formatter** `(esbenp.prettier-vscode)` - For automatically formatting the Express/Node.js backend code.
4. **PostgreSQL** `(ckshay.postgresql)` - To view and execute SQL queries inside your database directly within VS Code.
5. **Thunder Client** or **Postman** extension - Helpful for testing the backend API routes directly within VS Code before connecting the frontend.

---

## 🚀 4. How to Install and Run Locally

You need to install a few prerequisites on your machine before you can run the app:
* **[PostgreSQL](https://www.postgresql.org/download/)**: The local database server.
* **[Node.js](https://nodejs.org/en/download/)**: For the backend (includes `npm`).
* **[Flutter SDK](https://docs.flutter.dev/get-started/install)**: For the frontend mobile app.

### Step 1: Database Setup
1. Open pgAdmin (installed with PostgreSQL) or your PostgreSQL command-line tool.
2. Create a new database for the project (e.g., `wellness_wings`).
3. Run the SQL script located at `database/init.sql` against your new database to initialize all the required tables.

### Step 2: Backend Setup
1. Open a new terminal in VS Code and navigate to the backend directory:
   ```bash
   cd backend
   ```
2. Install the necessary Node.js dependencies:
   ```bash
   npm install
   ```
3. Make sure an `.env` file exists in the `backend/` directory with the required variables:
   ```env
   PORT=3000
   JWT_SECRET=your_jwt_secret_token
   # Add your PostgreSQL connection string/details here as well!
   ```
4. Start the backend development server using nodemon:
   ```bash
   npx nodemon server.js
   ```

### Step 3: Frontend Setup
1. Open a new terminal and navigate to the root of the project:
   ```bash
   cd "Wellness Wings"
   ```
2. Install all the Flutter plugin dependencies:
   ```bash
   flutter pub get
   ```
3. Ensure you have an Android emulator running, an iOS simulator, or a physical device connected. You can also run it on Web/Desktop.
4. Run the Flutter application:
   ```bash
   flutter run
   ```

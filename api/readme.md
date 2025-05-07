# Gertrude API

## Project Setup Guide

This document provides instructions for setting up your local development environment for this project.

### Prerequisites

Before you begin, ensure you have the following installed:

* **Swift:** Version 6.0.3 or later. You can download it from the official Swift website.
    * Verify your installation by running `swift --version` in your terminal.
* **Xcode:** (Optional but recommended) For iOS and macOS development, and for general Swift development.
* **PostgreSQL:** For database interactions. Install it using Homebrew (if on macOS):
    ```bash
    brew update
    brew install postgresql
    brew services start postgresql
    ```

### Setting up the API Server

1.  **Database Setup:**

    * Access the PostgreSQL command-line interface:
        ```bash
        psql postgres
        ```
    * Create a database for the API:
        ```sql
        CREATE DATABASE my_api_db;
        \q
        ```

2.  **Environment Variables:**

    * Create a `.env` file in the root directory of the `api` module.
    * Add the following environment variables to the `.env` file, replacing the values with your actual database credentials:

        ```
        DATABASE_NAME=my_api_db
        DATABASE_USERNAME=$USER
        DATABASE_PASSWORD=
        TEST_DATABASE_NAME=my_api_db
        CLOUD_STORAGE_KEY=not-real
        CLOUD_STORAGE_SECRET=not-real
        CLOUD_STORAGE_ENDPOINT=not-real
        CLOUD_STORAGE_BUCKET=not-real
        CLOUD_STORAGE_BUCKET_URL=/not-real
        CLOUDFLARE_SECRET=not-real
        TWILIO_ACCOUNT_SID=not-real
        TWILIO_AUTH_TOKEN=not-real
        TWILIO_FROM_PHONE=not-real
        DASHBOARD_URL=/dashboard
        ANALYTICS_SITE_URL=/analytics
        POSTMARK_API_KEY=not-real
        POSTMARK_SERVER_ID=12345
        PRIMARY_SUPPORT_EMAIL=not-real
        SUPER_ADMIN_EMAIL=not-real
        STRIPE_SUBSCRIPTION_PRICE_ID=not-real
        STRIPE_SECRET_KEY=not-real
        SWIFT_DETERMINISTIC_HASHING=1
        TASK_MEGA_YIELD_COUNT=50
        AUTO_INCLUDED_KEYCHAIN_ID=a42f82bb-797d-4897-9d8a-4ed26b2c177a
        ```
    * **Important:** For production environments, use strong passwords. For local development, an empty password might be acceptable, but it's generally recommended to set a password.

4.  **Run the API Server:**

    * Still in the `api/` directory, start the server:
        ```bash
        swift run Run serve
        ```

### Running API Server Tests

1.  **Using Swift Package Manager:**

    * Navigate to the `api/` directory in your terminal:
        ```bash
        cd /path/to/your/project/api/
        ```
    * Run all tests:
        ```bash
        swift test
        ```
    * Run specific tests:
        ```bash
        swift test --filter ServerTests
        ```

2.  **Using Xcode:**

    * Open your project in Xcode.
    * Edit the `ServerTests` scheme:
        * Go to "Product" > "Scheme" > "Edit Scheme...".
        * In the "Run" arguments section, add each enviornment variable from api/.env.
    * Run the tests from the Test navigator (Command + 9).

## Stripe Implementation

_NB:_ When (re)implimenting Stripe subscription, refer to this commit, which has all of
the ripped out code:

https://github.com/gertrude-app/swift/commit/74736228321e58949710140534141e6e44654ab9

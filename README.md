# Secure Fashion E-Commerce Management System

This project is a SQL Server-backed secure fashion e-commerce management system for CCS6344 Assignment 1. It follows the referenced project structure conceptually, but changes the business domain from banking to an online boutique.

## Features

- Role-based access for `Customer`, `InventoryOfficer`, and `Admin`
- Parameterized SQL queries through the `mssql` driver
- Password hashing with bcrypt
- HTTP hardening with Helmet and login rate limiting
- Audit logging for product and order actions
- SQL Server scripts for schema, sample data, roles, views, row-level security, dynamic data masking, triggers, backup, and encryption notes
- Simple web UI for report screenshots: add product, delete product, add another product, create order, view audit logs

## Setup

1. Create a SQL Server database named `SecureECommerce`.
2. Run the scripts in this order:
   - `sql/01_schema.sql`
   - `sql/02_seed.sql`
   - `sql/03_security.sql`
3. Copy `.env.example` to `.env` and update the values.
4. Install dependencies:

```bash
npm install
```

On Windows PowerShell, use `npm.cmd install` if `npm.ps1` is blocked by execution policy.

5. Generate a bcrypt hash and replace the placeholder in `sql/02_seed.sql` before running the seed script:

```bash
node scripts/hash-password.js Password@123
```

6. Start the app:

```bash
npm run dev
```

Open `http://localhost:3000`.

## Demo Accounts

All seed users use password `Password@123`.

| Role | Email |
| --- | --- |
| Admin | admin@securecart.local |
| InventoryOfficer | officer@securecart.local |
| Customer | customer@securecart.local |

## Report Helpers

Use `docs/report-outline.md` for a concise report draft aligned to the assignment tasks, including STRIDE, DREAD, PDPA mapping, and screenshot checklist.

# NepaliHR

HR Management System for Nepali small and medium businesses.

## Stack
- **Frontend**: Flutter 3.x (Android + iOS)
- **Backend**: Node.js 22 + Express
- **Database**: PostgreSQL 15 (pgAdmin 4)

## Features
- Authentication (JWT + device secure storage)
- Attendance (IP whitelist + device bound, clock-in/out, timezone: Asia/Kathmandu)
- Leave Management (apply, approve, reject, balance tracking)
- Payroll (generate, bulk generate, mark paid, payslips)
- Shift Management (create, assign, grace period)
- Document Management (upload, view, delete, admin sees all)
- Announcements (priority: urgent/high/normal/low)
- Notifications (in-app: leave, payroll, evaluations)
- Departments & Job Roles
- KPI Management (evaluator-type scoped: self/peer/manager/hr)
- 360° Evaluation Cycles with weighted scoring
- Performance Results with grades
- Dual Language: English / नेपाली
- Role-based UI: Admin / Manager / Employee

## Setup
1. Run `npm install` in hr-backend/
2. Run all SQL files in hr-backend/sql/ via pgAdmin
3. Copy `.env.example` to `.env` and fill in values
4. Run `node src/server.js`
5. Run `flutter pub get` in hr-app/
6. Update `lib/config/api_config.dart` with your server IP
7. Run `flutter run`

## Roles
- **Admin**: Full access. Payroll, KPIs, eval cycles, all documents, all attendance.
- **Manager**: Team attendance, leave approvals, evaluations, own leave.
- **Employee**: Personal clock-in/out, own leave, payslips, evaluations.

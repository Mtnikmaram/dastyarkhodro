# MVP Product & Technical Plan

## Product goals
Help drivers maintain vehicle records, plan maintenance, understand costs, and receive reminders.

## Initial user flows
1. Add a vehicle (make, model, year, odometer, fuel type).
2. Record a service (category, date, odometer, cost, notes).
3. Record a cost (category, amount, date, notes).
4. View dashboard summary and service history.
5. Later: create reminders based on date or odometer and opt into AI help.

## Core data model
- Vehicle belongs to a user.
- MaintenanceRecord belongs to a vehicle.
- Expense belongs to a vehicle.
- Reminder belongs to a vehicle (planned follow-up).
- AIConversation belongs to a user/vehicle (future, optional).

## API shape
- GET/POST /api/v1/vehicles/
- GET/PATCH/DELETE /api/v1/vehicles/{id}/
- GET/POST /api/v1/vehicles/{id}/maintenance/
- GET/POST /api/v1/vehicles/{id}/expenses/
- GET /api/v1/health/

## Security requirements before production
- Require authentication for user data.
- Enforce ownership in every queryset/object permission.
- Validate amounts, odometer values and dates.
- Avoid storing license plate or other identifying information unless needed.
- Configure allowed hosts, CORS, rate limits, HTTPS, DB backups and monitoring.

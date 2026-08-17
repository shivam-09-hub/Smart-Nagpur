# Smart Nagpur Admin Application

This is the admin panel for the Smart Nagpur municipal services application. The admin app allows authorized administrators to review and manage citizen complaints, vendor applications, send notifications, and view analytics.

## Features

### Dashboard
- Real-time statistics and metrics
- Complaint resolution rate
- Vendor application approval rate
- Quick action buttons for all major functions

### Complaint Management & Field Staff Dispatching
- View all pending complaints with filters (department, priority, status)
- Detailed complaint review with photos and location
- Assign complaints to active on-duty field workers with department validation
- Reassign complaints when needed
- Update complaint status and add timeline entries
- Submit detailed reviews with ratings
- Categorized view by service type

### Field Operations & Verification Dashboard
- Single-roundtrip server-side aggregation (`get_admin_operations_dashboard`)
- Live Verification Queue tab displaying completed complaints awaiting inspection
- Evidence inspection gallery with Before/After photos and inspection PDF download
- GPS proximity and accuracy badge verification
- Staff Workload tab tracking active technicians, on-duty status, and assigned tasks
- Complaint & Assignment status breakdown chips with instant filter resets
- 1-tap Approve and Rework request actions

### Vendor Application Management
- Review pending vendor applications
- View applicant details and documents
- Approve/reject applications with comments
- Track application status through timeline


### Notification Management
- Send broadcast notifications to all users
- Send targeted notifications to specific users
- Notification history and tracking
- Category-based notification organization

### User Management
- View all registered users
- Suspend users with suspension reason
- View user profiles and contact information
- Track user account status

### Analytics & Reports
- Daily statistics overview
- Monthly reports
- Complaint distribution by service type
- Application status breakdown
- User growth tracking

## Admin Roles & Permissions

- **Super Admin**: Full system access and control
- **Complaint Reviewer**: Review and manage complaints only
- **Vendor Reviewer**: Review and approve vendor applications only
- **Report Viewer**: View analytics and reports only
- **Notification Manager**: Send and manage notifications
- **User Manager**: Manage user accounts and suspensions

## Building the Admin APK

### Option 1: Using Flavors (Recommended)

To build both citizen and admin APKs with separate app IDs:

```bash
# Build citizen APK
flutter build apk --flavor citizen -t lib/main.dart

# Build admin APK
flutter build apk --flavor admin -t lib/admin_main.dart
```

Output files:
- Citizen: `build/app/outputs/flutter-apk/app-citizen-release.apk`
- Admin: `build/app/outputs/flutter-apk/app-admin-release.apk`

### Option 2: Direct Build

```bash
# Build admin debug APK
flutter run -t lib/admin_main.dart

# Build admin release APK
flutter build apk --release -t lib/admin_main.dart --dart-define=SUPABASE_URL=<your-url> --dart-define=SUPABASE_PUBLISHABLE_KEY=<your-key>
```

## Configuration

### Environment Variables

Build the admin APK with custom Supabase configuration:

```bash
flutter build apk --release \
  --dart-define=SUPABASE_URL=https://your-project.supabase.co \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=your-publishable-key \
  -t lib/admin_main.dart
```

### Android Manifest Changes

For the admin app flavor, update `android/app/build.gradle`:

```gradle
flavorDimensions "app"

productFlavors {
    citizen {
        dimension "app"
        applicationId "com.smartnagpur.citizen"
    }
    admin {
        dimension "app"
        applicationId "com.smartnagpur.admin"
    }
}
```

## Database Setup for Admin

Before using the admin app, run the admin migration in Supabase:

1. Open Supabase Dashboard → SQL Editor
2. Paste content from `supabase/migrations/202608180001_smart_nagpur_admin.sql`
3. Click "Run"
4. Verify with: `SELECT 'Admin tables created successfully';`

## Creating Admin Users

### Via Supabase Dashboard:

1. Go to Authentication → Users
2. Create a new user with admin email
3. In SQL Editor, run:

```sql
INSERT INTO admin_profiles (id, name, email, phone, role, is_active)
SELECT id, 'Admin Name', email, '9876543210', 'superAdmin', true
FROM auth.users
WHERE email = 'admin@smartnagpur.com'
ON CONFLICT (email) DO NOTHING;
```

### Via CLI:

```bash
supabase auth admin create-user --email admin@smartnagpur.com --password SecurePassword123
```

Then insert the admin profile record.

## Login Credentials

- **Email**: Create via Supabase Authentication
- **Password**: Set during user creation
- **Role**: Assigned in admin_profiles table

## API Endpoints

The admin app uses the following RPC functions:

- `get_admin_stats()` - Get dashboard statistics
- `get_complaint_stats()` - Get complaint metrics
- `get_vendor_stats()` - Get vendor application metrics
- `get_user_stats()` - Get user statistics
- `get_notification_stats()` - Get notification counts
- `get_complaints_by_service()` - Distribution by service type
- `get_complaints_by_status()` - Distribution by status
- `get_applications_by_status()` - Vendor apps by status
- `get_daily_stats(days)` - Daily statistics for N days
- `get_monthly_report(month, year)` - Monthly report
- `suspend_user(user_id, reason)` - Suspend a user account
- `reactivate_user(user_id)` - Reactivate a suspended user
- `send_broadcast_notification(title, body, category)` - Send to all users
- `add_complaint_timeline(complaint_id, entry)` - Add timeline entry
- `add_application_timeline(application_id, entry)` - Add timeline entry

## Architecture

```
lib/
├── admin_main.dart              # Admin app entry point
├── domain/models/
│   ├── admin_stats.dart         # Dashboard statistics
│   ├── admin_profile.dart       # Admin user model
│   └── admin_review.dart        # Review and assessment model
├── data/
│   ├── gateways/
│   │   ├── admin_auth_gateway.dart
│   │   └── admin_data_gateway.dart
│   └── adapters/
│       ├── supabase_admin_auth_gateway.dart
│       └── supabase_admin_data_gateway.dart
├── state/
│   └── admin_controller.dart    # State management
└── features/admin/presentation/
    ├── admin_login_screen.dart
    ├── admin_dashboard_screen.dart
    ├── admin_complaints_screen.dart
    ├── admin_complaint_detail_screen.dart
    ├── admin_vendors_screen.dart
    ├── admin_notifications_screen.dart
    └── admin_users_screen.dart
```

## Database Schema

### Admin Tables

- `admin_profiles` - Admin user accounts with roles and permissions
- `admin_notifications` - System-wide admin notifications
- `admin_reviews` - Reviews and assessments for complaints/applications
- `user_suspensions` - Track user account suspensions

### Related Tables (Extended)

- `complaints` - Citizen complaint records
- `vendor_applications` - Vendor registration applications
- `notifications` - User notifications
- `profiles` - User profiles

## Testing

```bash
# Run tests
flutter test

# Test with admin main
flutter test -t lib/admin_main.dart
```

## Troubleshooting

### Login Issues
- Verify admin profile exists in database
- Check that `is_active` is set to true
- Ensure email and password are correct
- Check admin_profiles RLS policies

### Data Not Loading
- Verify Supabase connection
- Check RLS policies on admin tables
- Ensure admin has appropriate role permissions
- Check browser console for errors (if using web)

### Permission Denied Errors
- Verify admin role matches required permissions
- Check RLS policies for the specific table
- Ensure admin_profiles row exists with correct role

## Deployment

### Building for Release

```bash
# Build admin release APK
flutter build apk --release \
  --target lib/admin_main.dart \
  --dart-define=SUPABASE_URL=https://your-project.supabase.co \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=your-key

# Build admin app bundle (for Play Store)
flutter build appbundle --release \
  --target lib/admin_main.dart \
  --dart-define=SUPABASE_URL=https://your-project.supabase.co \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=your-key
```

### Play Store Submission

1. Create separate app listing for admin app
2. Use package name: `com.smartnagpur.admin`
3. Set appropriate access restrictions to verified admins only
4. Add release notes explaining admin functionality

## Security Considerations

- Admin credentials are never cached locally
- All operations require valid Supabase session
- Row-Level Security (RLS) enforces all data access restrictions
- Service-role key is never exposed to the app
- Admin operations are logged and auditable
- Passwords are enforced via Supabase Auth

## Performance Optimizations

- Pagination on large lists (50 items per page)
- Lazy loading of complaint photos and documents
- Caching of admin stats with refresh capability
- Efficient queries using Supabase indexes
- Background sync for user suspensions

## Support

For issues or feature requests:
1. Check the troubleshooting section
2. Review Supabase logs
3. Check RLS policies and migrations
4. Contact the development team

## License

This admin application is part of the Smart Nagpur project and follows the same license terms.

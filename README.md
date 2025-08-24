# Auravisual Collab Manager (Flutter Frontend)

Auravisual Collab Manager is a lightweight project & collaboration dashboard built with **Flutter** and powered by a **FastAPI + Supabase (PostgreSQL)** backend.

It enables authenticated users to view and manage internal operations. Admin users have extended capabilities such as viewing staff, managing projects, and (new) creating projects directly from the app.

Backend repository: https://github.com/latorreandrea/auravisual-collab-manager-backend

## ✨ Current Features
- 🔐 Secure JWT authentication (admin, internal staff, client roles)
- 👤 Role-based UI (admin-only sections hidden for others)
- 🏠 **Welcome dashboard with real-time insights** - **UPDATED**
- 🧑‍🤝‍🧑 Team screen (admin) with workload metrics & client management access
- 📁 Projects screen with ticket/task indicators & scrollable detail modals
- ➕ Admin project creation with backend API integration
- 👥 **Complete client management system (admin)** - **NEW**
- ➕ **Admin client creation with validation** - **NEW**
- 📊 **Real-time dashboard with role-based data** - **NEW**
- 📱 **Scrollable detail modals** - **NEW**
- 🎨 Theming & animated transitions with zoom effects
- 🔒 Secure token storage using flutter_secure_storage
- ❗ Production-ready error handling (all mock data eliminated)

## 🆕 Admin Project Creation
Admin users can now create projects via a dedicated screen accessed from a floating action button (FAB) on the Projects screen.

### Project Schema (Database)
```
projects (
  id UUID PK DEFAULT gen_random_uuid(),
  name VARCHAR(255) NOT NULL,
  description TEXT,
  client_id UUID REFERENCES users(id) ON DELETE SET NULL,
  website_url VARCHAR(500),
  social_links TEXT[],
  plan project_plan NOT NULL DEFAULT 'Starter Launch',
  contract_subscription_date DATE,
  status project_status DEFAULT 'in_development',
  created_by UUID REFERENCES users(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
)
```
Indexes & trigger keep performance and updated_at integrity.

### Creation Flow
1. Admin taps the + FAB on `ProjectsScreen`
2. Fills form: name, description, optional client, website, plan, status, contract date, social links
3. Submits -> POST /admin/projects
4. List refreshes automatically on success

### Request Payload
```json
{
  "name": "Landing Redesign",
  "description": "Marketing site revamp",
  "client_id": "<uuid?>",
  "website_url": "https://example.com",
  "social_links": ["https://instagram.com/acme"],
  "plan": "Aura Pro",
  "contract_subscription_date": "2025-08-15",
  "status": "in_development"
}
```

## 👥 Client Management System
Complete client management capabilities for admin users with dedicated screens and real-time data.

### Client Features
- **Client List View**: Overview of all clients with project statistics
- **Client Creation**: Admin can create new client accounts with validation
- **Client Details**: Scrollable modal with complete client information
- **Project Statistics**: Real-time count of projects per client

### Client Schema (Database)
```json
{
  "id": "UUID",
  "first_name": "string",
  "last_name": "string", 
  "email": "string (unique)",
  "role": "client",
  "created_at": "timestamp",
  "project_count": "number (computed)"
}
```

### Client Creation Flow
1. Admin navigates to Team screen
2. Taps "View Clients" button to access ClientsScreen
3. Taps + FAB to create new client
4. Fills form with validation (name, email, password requirements)
5. Submits -> POST /auth/register with role: "client"
6. Client list refreshes automatically

### API Endpoints
- `GET /admin/users/clients` - Fetch all clients with project counts
- `POST /auth/register` - Create new client account

## 📊 Real-Time Dashboard
Dynamic dashboard with role-based insights powered by live API data.

### Dashboard Features
- **Role-Based Content**: Different insights for Admin, Staff, and Client users
- **Live Data Indicators**: Real-time updates with "Live" badges
- **Loading States**: Smooth loading animations with skeleton screens
- **Error Handling**: Graceful fallbacks with retry mechanisms

### Dashboard Data by Role

#### Admin Dashboard
- Total active projects count
- Staff workload distribution  
- Recent project activity
- System overview metrics

#### Staff Dashboard
- Assigned tasks count
- Personal workload status
- Recent task updates
- Team collaboration metrics

#### Client Dashboard  
- Client-specific project count
- Project status overview
- Recent project updates
- Access to project details

### API Integration
- `GET /admin/dashboard` - Admin overview data
- `GET /tasks/my` - Staff personal tasks
- `GET /client/projects` - Client project data

## 🎨 UI/UX Improvements

### Scrollable Detail Modals
All detail modals (projects and clients) now feature:
- **Vertical Scrolling**: Prevents content overflow on smaller screens
- **Responsive Design**: Adapts to different screen sizes
- **Smooth Animations**: Zoom transitions for better user experience

### Enhanced Navigation
- **Role-Based Access**: UI elements show/hide based on user permissions
- **Floating Action Buttons**: Quick access to creation screens
- **Animated Transitions**: Smooth page transitions with custom effects

## 🛠 Tech Stack
| Layer | Technology |
|-------|------------|
| Frontend | Flutter (Dart) |
| Auth | JWT + Secure Storage |
| Backend | FastAPI |
| Database | Supabase (PostgreSQL) |
| Deployment | (TBD) |

## 📂 Directory Structure
```
lib/
  models/        # Data models (User, Project, TeamMember, Client)
    client.dart    # Client model with project statistics
    project.dart   # Updated project model with backend alignment
    user.dart      # User model with role management
  services/      # API service layer (auth, staff, projects, clients, dashboard)
    auth_service.dart      # JWT authentication
    client_service.dart    # Client management operations - NEW
    dashboard_service.dart # Real-time dashboard data - NEW  
    project_service.dart   # Project CRUD operations
    staff_service.dart     # Staff management
  screens/       # UI screens with role-based access
    welcome_screen.dart      # Updated with real-time dashboard
    clients_screen.dart      # Client management interface - NEW
    create_client_screen.dart # Client creation form - NEW
    create_project_screen.dart # Updated project creation
    team_screen.dart         # Enhanced with client access
    projects_screen.dart     # Updated with scrollable modals
  widgets/       # Reusable UI components
  theme/         # Material Design 3 theming and styles
  utils/         # Constants, validators, helpers
```

## 🚀 Run Locally
Make sure Flutter SDK is installed.

```bash
flutter pub get
flutter run
```

## 🌐 API Endpoints
The app integrates with the following backend endpoints:

### Authentication
- `POST /auth/login` - User authentication
- `POST /auth/register` - Client registration (admin only)

### Dashboard  
- `GET /admin/dashboard` - Admin dashboard data
- `GET /tasks/my` - Staff tasks and workload
- `GET /client/projects` - Client project overview

### Project Management
- `GET /admin/projects` - List all projects
- `POST /admin/projects` - Create new project (admin only)

### Client Management
- `GET /admin/users/clients` - List all clients with statistics
- `GET /admin/users/staff` - List all staff members

### Base URL
```
https://app.auravisual.dk
```

## 🔐 Authentication
The app uses production-ready JWT authentication with role-based access control.

### AuthService Features
- **Login Flow**: Secure token storage with flutter_secure_storage
- **Role Management**: Admin, Staff, Client role differentiation
- **Token Injection**: Automatic Authorization: Bearer <token> on API calls
- **Logout**: Complete session cleanup and secure storage clearing

### API Security
All API calls include proper authentication headers and error handling:
```dart
headers: {
  'Authorization': 'Bearer $token',
  'Content-Type': 'application/json',
}
```

## 🧪 Testing
A sample widget test exists in `test/`. Add more as features grow.

## 🧱 Error Handling & Production Readiness
- **Zero Mock Data**: All mock data fallbacks completely eliminated
- **User-Friendly Messages**: Clear error messages with actionable feedback
- **Developer Logging**: Comprehensive logging with `dart:developer`
- **API Error Handling**: Proper HTTP status code handling with retry mechanisms
- **Validation**: Form validation with real-time feedback
- **Loading States**: Skeleton screens and loading indicators throughout the app

## 📌 Next Possible Enhancements
- Advanced task management with drag & drop
- Ticket drill-down view with comments
- Client portal with simplified view
- Real-time notifications and updates
- Advanced search and filtering
- Pagination for large datasets
- Dark mode implementation
- Offline capability with sync
- Performance analytics dashboard
- CI/CD pipeline (format, analyze, test, deploy)

## 🤝 Contributing
Open to improvements. Submit an issue or PR.

## 📄 License
Proprietary (internal use) unless otherwise stated.

---
Frontend for Auravisual Collab Manager – crafted with Flutter.

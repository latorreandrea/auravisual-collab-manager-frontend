# Auravisual Collab Manager (Flutter Frontend)

Auravisual Collab Manager is a comprehensive project & collaboration dashboard built with **Flutter** and powered by a **FastAPI + Supabase (PostgreSQL)** backend.

It enables authenticated users to view and manage internal operations with advanced time tracking capabilities. Admin users have extended capabilities including staff management, project oversight, and comprehensive task monitoring across all teams.

Backend repository: https://github.com/latorreandrea/auravisual-collab-manager-backend

## ✨ Current Features
- 🔐 Secure JWT authentication (admin, internal staff, client roles)
- 👤 Role-based UI (admin-only sections hidden for others)
- 🏠 **Welcome dashboard with real-time insights**
- ⏱️ **Complete time tracking system with active timer management** - **NEW**
- 📋 **Advanced task management for staff and admin users** - **NEW**
- 🧑‍🤝‍🧑 Team screen (admin) with workload metrics & client management access
- 📁 Projects screen with ticket/task indicators & scrollable detail modals
- ➕ Admin project creation with backend API integration
- 👥 **Complete client management system (admin)**
- ➕ **Admin client creation with validation**
- 📊 **Real-time dashboard with role-based data**
- 📱 **Smart task detail modals with timer controls** - **NEW**
- 🎨 Theming & animated transitions with zoom effects
- 🔒 Secure token storage using flutter_secure_storage
- ❗ Production-ready error handling (all mock data eliminated)

## ⏱️ Time Tracking System
Complete time tracking solution for staff productivity and admin oversight with real-time timer management.

### Time Tracking Features
- **Single Active Timer**: Only one timer can run at a time per user
- **Persistent Sessions**: Timers remain active across app restarts
- **Real-Time Display**: Live elapsed time indicators in task cards
- **Smart Notifications**: Active timer alerts with quick access
- **Role-Based Access**: Admin can track time only on assigned tasks
- **Seamless UI**: Timer controls integrated into task detail modals

### Staff Time Tracking
Staff users have full time tracking capabilities on their assigned tasks:
- **Start Timer**: Begin tracking time with one click
- **Active Timer Indicators**: Visual badges showing elapsed time (e.g., "2h 15m")
- **Stop Timer**: Complete session and automatically close task modal
- **Task Detail Integration**: Timer controls within scrollable task details
- **Time History**: View logged time and session counts per task

### Admin Time Tracking
Admin users can view all tasks but only track time on their own assignments:
- **Comprehensive View**: See all tasks across all projects and team members
- **Visual Distinction**: Admin's own tasks highlighted with purple accent
- **Selective Interaction**: Timer controls only available on admin's assigned tasks
- **Team Overview**: Monitor all active timers across the organization
- **View-Only Mode**: Other users' tasks display as read-only with assignment info

### Timer State Management
```json
{
  "task_id": "uuid",
  "start_time": "2025-08-28T14:30:00Z",
  "user_id": "uuid",
  "status": "active"
}
```

### Smart Modal Behavior
- **Start Timer**: Modal stays open, button changes to "Stop Timer & Close"
- **Active Timer**: Red stop button with clear "Stop & Close" labeling
- **Timer Completion**: Automatic modal closure after stopping timer
- **Real-Time Updates**: Modal refreshes timer state without reopening

### API Integration
- `POST /tasks/{task_id}/timer/start` - Start timer session
- `POST /tasks/{task_id}/timer/stop` - Stop timer session
- `GET /tasks/my/active-timer` - Get current active timer
- `GET /tasks/my/time-summary` - Get user's time tracking summary
- `GET /tasks/{task_id}/time-logs` - Get time logs for specific task
## 📋 Task Management System
Advanced task management interface with role-based access and comprehensive time tracking integration.

### Staff Task Management
Staff users access their assigned tasks through a dedicated interface:
- **Personal Task View**: Only assigned tasks visible to staff
- **Task Status Control**: Mark tasks as completed or in progress
- **Priority Indicators**: Visual priority badges (urgent, high, medium, low)
- **Project Context**: Tasks grouped by project with clear project names
- **Time Integration**: Seamless timer controls within each task
- **Smart Filtering**: Filter by status, priority, and project

### Admin Task Management
Admin users have comprehensive oversight of all organizational tasks:
- **Global Task View**: See all tasks across all projects and team members
- **Assignment Visibility**: Clear indication of task assignments with user names
- **Dual Functionality**: 
  - **View All**: Monitor team progress and task distribution
  - **Interact with Own**: Time tracking and status updates only on assigned tasks
- **Visual Hierarchy**: Admin's tasks highlighted with distinctive purple styling
- **Team Monitoring**: Overview of active timers and task completion rates

### Task Detail Modals
Enhanced task detail experience with smart modal behavior:
- **Comprehensive Information**: Project, assignee, status, priority, time logs
- **Smart Timer Controls**: Context-aware timer buttons based on assignment
- **Real-Time Updates**: Live timer display with elapsed time
- **Session History**: View previous time tracking sessions
- **Responsive Design**: Scrollable content for smaller screens

### Task Schema Integration
```json
{
  "id": "uuid",
  "action": "Task description",
  "status": "in_progress|completed",
  "priority": "urgent|high|medium|low",
  "project_name": "Project Name",
  "assigned_to_name": "User Name",
  "assigned_to_id": "uuid",
  "total_time_minutes": 125,
  "time_sessions_count": 3,
  "created_at": "timestamp"
}
```

## 🆕 Admin Project Creation

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
| State Management | StatefulWidget + Provider |
| Time Tracking | Real-time timer management |
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
  services/      # API service layer (auth, staff, projects, clients, dashboard, tasks)
    auth_service.dart      # JWT authentication
    client_service.dart    # Client management operations
    dashboard_service.dart # Real-time dashboard data
    project_service.dart   # Project CRUD operations
    staff_service.dart     # Staff management
    task_service.dart      # Task management and time tracking - NEW
  screens/       # UI screens with role-based access
    welcome_screen.dart        # Updated with real-time dashboard
    clients_screen.dart        # Client management interface
    create_client_screen.dart  # Client creation form
    create_project_screen.dart # Updated project creation
    team_screen.dart           # Enhanced with client access
    projects_screen.dart       # Updated with scrollable modals
    staff_tasks_screen.dart    # Staff task management with time tracking - NEW
    admin_tasks_screen.dart    # Admin task oversight with selective interaction - NEW
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

### Task Management & Time Tracking
- `GET /tasks/my` - Get user's assigned tasks
- `GET /admin/tasks` - Get all tasks (admin only)
- `PATCH /tasks/{id}/status` - Update task status
- `POST /tasks/{task_id}/timer/start` - Start time tracking session
- `POST /tasks/{task_id}/timer/stop` - Stop time tracking session
- `GET /tasks/my/active-timer` - Get current active timer
- `GET /tasks/my/time-summary` - Get user's time tracking summary
- `GET /tasks/{task_id}/time-logs` - Get time logs for specific task

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
- **Advanced Time Analytics**: Detailed time reports with charts and productivity insights
- **Team Time Dashboards**: Real-time team productivity monitoring for admins
- **Time Estimation**: Add task time estimates vs actual tracking
- **Billing Integration**: Convert tracked time to billable hours
- **Mobile Timer Notifications**: Background timer notifications when app is closed
- Advanced task management with drag & drop
- Ticket drill-down view with comments and attachments
- Client portal with simplified task view
- Real-time notifications and updates
- Advanced search and filtering across all entities
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

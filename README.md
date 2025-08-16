# Auravisual Collab Manager (Flutter Frontend)

Auravisual Collab Manager is a lightweight project & collaboration dashboard built with **Flutter** and powered by a **FastAPI + Supabase (PostgreSQL)** backend.

It enables authenticated users to view and manage internal operations. Admin users have extended capabilities such as viewing staff, managing projects, and (new) creating projects directly from the app.

Backend repository: https://github.com/latorreandrea/auravisual-collab-manager-backend

## ✨ Current Features
- 🔐 Secure JWT authentication (admin, internal staff, client roles)
- 👤 Role-based UI (admin-only sections hidden for others)
- 🏠 Welcome dashboard with navigation
- 🧑‍🤝‍🧑 Team screen (admin) with workload metrics
- 📁 Projects screen with ticket/task indicators
- ➕ Admin project creation (new)
- 🎨 Theming & animated transitions
- 🔒 Secure token storage using flutter_secure_storage
- ❗ Friendly error handling (no mock fallbacks)

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
```
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
  models/        # Data models (User, Project, TeamMember)
  services/      # API service layer (auth, staff, projects)
  screens/       # UI screens
  widgets/       # Reusable UI components
  theme/         # Theming and styles
  utils/         # Constants, validators
```

## 🚀 Run Locally
Make sure Flutter SDK is installed.

```
flutter pub get
flutter run
```

## 🔐 Authentication
The app expects a backend issuing JWT tokens. `AuthService` handles:
- Login -> stores token
- Logout -> clears secure storage
- Injects Authorization: Bearer <token> on API calls

## 🧪 Testing
A sample widget test exists in `test/`. Add more as features grow.

## 🧱 Error Handling Philosophy
- No mock data fallbacks in production paths
- User-facing friendly messages
- Developer logging with `dart:developer`

## 📌 Next Possible Enhancements
- Task management UI
- Ticket drill-down view
- Client portal simplified view
- Pagination & search for staff/projects
- Dark mode
- CI pipeline (format, analyze, test)

## 🤝 Contributing
Open to improvements. Submit an issue or PR.

## 📄 License
Proprietary (internal use) unless otherwise stated.

---
Frontend for Auravisual Collab Manager – crafted with Flutter.

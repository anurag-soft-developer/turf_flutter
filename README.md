# Flutter Authentication App with NestJS Backend

A comprehensive Flutter authentication app designed to work with a **NestJS backend**, built using GetX for state management and routing.

## 🚀 **Features**

- ✅ **Authentication System**
  - Email/Password login and registration
  - JWT token authentication
  - Password reset functionality  
  - User profile management

- ✅ **Modern Architecture**
  - REST API integration with NestJS backend
  - JWT token management with auto-refresh
  - Dio HTTP client with interceptors
  - JSON serialization with code generation

- ✅ **User Interface**
  - Modern Material 3 design
  - Dark/Light theme support
  - Responsive design
  - Custom reusable components

- ✅ **State Management**
  - GetX for reactive state management
  - Proper separation of concerns
  - Clean architecture

- ✅ **Screens**
  - Splash screen with app branding
  - Login & Signup with validation
  - Dashboard with user info
  - Profile management with editable fields
  - Settings with preferences

- ✅ **Error Handling**
  - REST API exception handling
  - Toast notifications for feedback
  - Form validation with user-friendly messages

## 📁 **Project Structure**

```
lib/
├── bindings/           # GetX dependency bindings
├── components/         # Reusable UI components
├── controllers/        # GetX controllers for state management
├── models/            # Data models with JSON serialization
├── routes/            # App routing configuration
├── services/          # API service and authentication logic
├── utils/             # Utilities, constants, and helpers
└── views/             # UI screens and widgets
    ├── auth/          # Authentication screens
    ├── home/          # Main app screens
    ├── profile/       # Profile management
    └── settings/      # Settings screens
```

## 🛠 **Backend Requirements**

You'll need a **NestJS backend** with the following endpoints:

### Authentication Endpoints:
```
POST /api/auth/login           - User login
POST /api/auth/register        - User registration  
POST /api/auth/refresh         - Refresh JWT token
POST /api/auth/logout          - User logout
POST /api/auth/forgot-password - Send password reset email
POST /api/auth/reset-password  - Reset password with token
```

### User Endpoints:
```
GET /api/users/profile         - Get user profile
PUT /api/users/profile         - Update user profile
PUT /api/users/change-password - Change user password
DELETE /api/users/delete       - Delete user account
```

### Expected API Response Format:

**Login/Register Response:**
```json
{
  "access_token": "jwt_token_here",
  "refresh_token": "refresh_token_here", 
  "user": {
    "id": "user_id",
    "email": "user@example.com",
    "first_name": "John",
    "last_name": "Doe", 
    "display_name": "John Doe",
    "profile_picture": "https://...",
    "email_verified": true,
    "phone_number": "+1234567890",
    "created_at": "2024-01-01T00:00:00Z",
    "updated_at": "2024-01-01T00:00:00Z",
    "role": "user",
    "is_active": true
  }
}
```

## ⚙️ **Setup Instructions**

### 1. Install Flutter Dependencies

```bash
flutter pub get
```

### 2. Configure API Base URL

Update the base URL in [`lib/utils/api_constants.dart`](lib/utils/api_constants.dart):

```dart
static const String baseUrl = 'https://your-nestjs-backend.com/api';
```

### 3. Generate JSON Serialization Code

```bash
dart run build_runner build
```

### 4. Run the App

```bash
flutter run
```

## 🔧 **Key Components**

### **API Service**
- **Dio HTTP Client** with interceptors
- **JWT token management** with auto-refresh
- **Request/Response interceptors** for authentication
- **Error handling** for different HTTP status codes

### **Authentication Service** 
- **REST API integration** for all auth operations
- **Local storage** with SharedPreferences  
- **Token management** and persistence
- **User profile** operations

### **Controllers**
- **AuthController** - Authentication state & forms
- **ProfileController** - User profile editing
- **SettingsController** - App preferences & theming

### **Reusable Components**
- **CustomButton** - Consistent styled buttons with loading states
- **CustomTextField** - Form inputs with validation & theming
- **LoadingOverlay** - Loading indicators and dialogs

## 📱 **User Model Structure**

```dart
class UserModel {
  final String? id;
  final String? email;
  final String? firstName;
  final String? lastName; 
  final String? displayName;
  final String? profilePicture;
  final bool? emailVerified;
  final String? phoneNumber;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? lastLoginAt;
  final String? role;
  final bool? isActive;
}
```

## 🔐 **Authentication Flow**

1. **User Registration/Login** → Send credentials to NestJS backend
2. **Backend validates** → Returns JWT tokens + user data
3. **Flutter stores tokens** → In secure local storage
4. **Automatic token refresh** → When access token expires
5. **API requests** → Include Bearer token in headers

## 🌐 **NestJS Backend Setup**

For a complete NestJS backend setup, you'll need:

1. **User Entity** with the fields matching UserModel
2. **JWT Authentication** module with passport
3. **Guards** for protected routes  
4. **DTOs** for request validation
5. **Password hashing** with bcrypt
6. **Email service** for password reset

Example NestJS User Entity:
```typescript
@Entity('users')
export class User {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ unique: true })
  email: string;

  @Column()
  password: string;

  @Column()
  first_name: string;

  @Column()
  last_name: string;

  @Column({ nullable: true })
  display_name: string;

  @Column({ nullable: true })
  profile_picture: string;

  @Column({ default: false })
  email_verified: boolean;

  @Column({ nullable: true })
  phone_number: string;

  @CreateDateColumn()
  created_at: Date;

  @UpdateDateColumn()
  updated_at: Date;

  @Column({ nullable: true })
  last_login_at: Date;

  @Column({ default: 'user' })
  role: string;

  @Column({ default: true })
  is_active: boolean;
}
```

## 🎯 **Production Ready Features**

- **JWT token refresh mechanism**
- **Secure token storage**
- **Network error handling**
- **Form validation**
- **Loading states**
- **Toast notifications**
- **Clean architecture**
- **Scalable folder structure**

## 📦 **Dependencies**

### Core:
- `get` - State management and routing
- `dio` - HTTP client for API calls
- `shared_preferences` - Local data persistence
- `json_annotation` - JSON serialization

### Development:
- `build_runner` - Code generation
- `json_serializable` - JSON serialization generator
- `flutter_lints` - Code linting rules

## 🚀 **Getting Started with NestJS**

1. Create your NestJS backend with authentication
2. Update the API base URL in the Flutter app
3. Ensure your API responses match the expected format
4. Test authentication flow end-to-end
5. Deploy and enjoy your full-stack app!

The app is designed to be **production-ready** with proper error handling, clean architecture, and scalable codebase. 🎯

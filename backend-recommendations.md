# Backend Recommendations for EatSci KMITL

## 🎯 Recommended Tech Stack

### Option 1: Node.js + PostgreSQL (Production Ready)
```json
{
  "backend": "Node.js + Express.js + TypeScript",
  "database": "PostgreSQL + Prisma ORM",
  "authentication": "JWT + bcrypt",
  "payment": "Stripe/Omise API",
  "fileStorage": "Cloudinary/AWS S3",
  "realtime": "Socket.io",
  "testing": "Jest + Supertest"
}
```

### Option 2: Node.js + MongoDB (Flexible)
```json
{
  "backend": "Node.js + Express.js",
  "database": "MongoDB + Mongoose",
  "authentication": "JWT + Passport.js",
  "payment": "Stripe/Omise",
  "fileStorage": "GridFS/Cloudinary"
}
```

### Option 3: PocketBase (Quick Start)
```json
{
  "backend": "PocketBase",
  "database": "SQLite (built-in)",
  "authentication": "Built-in",
  "fileStorage": "Built-in",
  "realtime": "Built-in",
  "adminUI": "Built-in"
}
```

## 📊 Database Schema Design

### Core Tables
```sql
-- Users table
CREATE TABLE users (
    id UUID PRIMARY KEY,
    student_id VARCHAR(20) UNIQUE NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    phone_number VARCHAR(20),
    profile_image_url TEXT,
    faculty VARCHAR(100),
    department VARCHAR(100),
    year INTEGER,
    university VARCHAR(200),
    wallet_balance DECIMAL(10,2) DEFAULT 0.00,
    loyalty_points INTEGER DEFAULT 0,
    join_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Restaurants table
CREATE TABLE restaurants (
    id UUID PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    category VARCHAR(100),
    image_url TEXT,
    address TEXT,
    phone_number VARCHAR(20),
    opening_hours JSONB,
    rating DECIMAL(3,2) DEFAULT 0.00,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Food items table
CREATE TABLE food_items (
    id UUID PRIMARY KEY,
    restaurant_id UUID REFERENCES restaurants(id),
    name VARCHAR(255) NOT NULL,
    description TEXT,
    price DECIMAL(8,2) NOT NULL,
    image_url TEXT,
    category VARCHAR(100),
    is_available BOOLEAN DEFAULT true,
    preparation_time INTEGER, -- minutes
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Orders table
CREATE TABLE orders (
    id UUID PRIMARY KEY,
    user_id UUID REFERENCES users(id),
    restaurant_id UUID REFERENCES restaurants(id),
    total_amount DECIMAL(10,2) NOT NULL,
    status VARCHAR(50) DEFAULT 'pending', -- pending, confirmed, preparing, ready, completed, cancelled
    special_instructions TEXT,
    order_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    estimated_ready_time TIMESTAMP,
    payment_method VARCHAR(50),
    payment_status VARCHAR(50) DEFAULT 'pending',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Order items table
CREATE TABLE order_items (
    id UUID PRIMARY KEY,
    order_id UUID REFERENCES orders(id),
    food_item_id UUID REFERENCES food_items(id),
    quantity INTEGER NOT NULL,
    unit_price DECIMAL(8,2) NOT NULL,
    total_price DECIMAL(8,2) NOT NULL,
    special_request TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Wallet transactions table
CREATE TABLE wallet_transactions (
    id UUID PRIMARY KEY,
    user_id UUID REFERENCES users(id),
    transaction_type VARCHAR(50) NOT NULL, -- topup, payment, refund
    amount DECIMAL(10,2) NOT NULL,
    description TEXT,
    reference_id UUID, -- could be order_id for payments
    status VARCHAR(50) DEFAULT 'completed',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- User favorites table
CREATE TABLE user_favorites (
    id UUID PRIMARY KEY,
    user_id UUID REFERENCES users(id),
    restaurant_id UUID REFERENCES restaurants(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, restaurant_id)
);
```

## 🚀 Quick Setup Commands

### For Node.js + PostgreSQL:
```bash
# Initialize project
mkdir eatsci-backend && cd eatsci-backend
npm init -y
npm install express cors helmet morgan dotenv bcryptjs jsonwebtoken
npm install prisma @prisma/client
npm install -D typescript @types/node @types/express ts-node nodemon

# Initialize Prisma
npx prisma init
# Edit schema.prisma with your database schema
npx prisma migrate dev
npx prisma generate
```

### For Node.js + MongoDB:
```bash
# Initialize project
mkdir eatsci-backend && cd eatsci-backend
npm init -y
npm install express mongoose cors helmet morgan dotenv bcryptjs jsonwebtoken
npm install -D typescript @types/node @types/express ts-node nodemon

# Start MongoDB connection
# Edit your connection string in .env
```

### For PocketBase:
```bash
# Download PocketBase
# Windows: https://github.com/pocketbase/pocketbase/releases
# Extract and run: ./pocketbase.exe serve

# Access admin UI at: http://localhost:8090/_/
# Create collections based on your schema
```

## 📱 Flutter HTTP Client Setup

Add to your Flutter `pubspec.yaml`:
```yaml
dependencies:
  http: ^1.5.0
  provider: ^6.1.2
  shared_preferences: ^2.2.2
  dio: ^5.4.0 # Alternative to http
```

## 🔗 API Endpoints Structure

```
POST   /api/auth/login
POST   /api/auth/register
GET    /api/auth/profile
PUT    /api/auth/profile

GET    /api/restaurants
GET    /api/restaurants/:id
GET    /api/restaurants/:id/menu

POST   /api/orders
GET    /api/orders
GET    /api/orders/:id
PUT    /api/orders/:id/status

GET    /api/wallet/balance
POST   /api/wallet/topup
GET    /api/wallet/transactions

GET    /api/favorites
POST   /api/favorites
DELETE /api/favorites/:restaurantId
```

## 💰 Payment Integration

### For Thailand Market:
- **Omise** (Thai payment gateway)
- **SCB Easy** (Siam Commercial Bank)
- **PromptPay** (Thailand's national payment system)

### International:
- **Stripe** (Global payment processor)
- **PayPal** (Wide acceptance)

## 📊 Monitoring & Analytics

```javascript
// Recommended tools
{
  "logging": "Winston + Morgan",
  "monitoring": "PM2 + New Relic",
  "analytics": "Google Analytics + Mixpanel",
  "errors": "Sentry",
  "performance": "Lighthouse CI"
}
```

## 🔒 Security Best Practices

1. **Authentication**: JWT with refresh tokens
2. **Validation**: Joi/Yup for input validation
3. **Rate Limiting**: Express rate limit
4. **CORS**: Proper CORS configuration
5. **Helmet**: Security headers
6. **HTTPS**: SSL/TLS encryption
7. **Environment**: Secure environment variables

## 🎯 Recommendation for Your Project

**For University Project/Learning**: Start with **PocketBase**
- Quick setup (< 30 minutes)
- Focus on Flutter frontend
- Built-in admin panel
- Real-time capabilities

**For Production/Portfolio**: Use **Node.js + PostgreSQL**
- Industry standard
- Scalable architecture
- Great for job interviews
- Full control over business logic
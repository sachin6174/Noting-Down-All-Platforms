# ANotingDownServer

A Node.js/Express server for the Noting Down application with MongoDB integration.

## Features

- User authentication (signup/login/logout)
- **Persistent session management** with MongoDB storage
- **Automatic session cleanup** - sessions expire and are removed after 24 hours of inactivity
- CRUD operations for notes
- MongoDB integration with Mongoose
- Password hashing with bcryptjs
- CORS support for web client

## Setup

1. Install dependencies:
```bash
npm install
```

2. Make sure MongoDB is running locally on port 27017

3. Start the server:
```bash
npm run dev  # Development with nodemon
npm start    # Production
```

The server will run on http://localhost:3001

## API Endpoints

### Authentication
- `POST /api/auth/signup` - Create new user account
- `POST /api/auth/login` - User login
- `POST /api/auth/logout` - User logout
- `GET /api/auth/session` - Check current session

### Notes (Requires Authentication)
- `GET /api/notes` - Get all user's notes
- `GET /api/notes/:noteId` - Get specific note
- `POST /api/notes` - Create new note
- `PUT /api/notes/:noteId` - Update existing note
- `DELETE /api/notes/:noteId` - Delete note

## Environment Variables

Create a `.env` file with:
- `MONGODB_URI` - MongoDB connection string
- `SESSION_SECRET` - Secret key for session management
- `PORT` - Server port (default: 3001)
- `SESSION_MAX_AGE` - Session cookie max age in milliseconds (default: 86400000 = 24 hours)
- `SESSION_TTL` - Session database TTL in seconds (default: 86400 = 24 hours)

## Session Management

Sessions are automatically managed with the following features:

### Automatic Cleanup
- **TTL (Time To Live)**: Sessions expire after 24 hours of inactivity
- **Native MongoDB TTL**: Uses MongoDB's built-in TTL index for efficient cleanup
- **Auto-removal interval**: Cleanup runs every 10 minutes
- **No manual intervention**: Expired sessions are automatically deleted from database

### Configurable Timeouts
- Modify `SESSION_MAX_AGE` and `SESSION_TTL` in `.env` to change session duration
- Both client cookie and database storage respect the same timeout
- Sessions are touched only after 24 hours to reduce database writes

### Database Storage
Sessions are stored in the `sessions` collection with:
- Automatic TTL index on `expires` field
- Optimized storage without stringification
- Efficient querying and cleanup
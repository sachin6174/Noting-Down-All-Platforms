require('dotenv').config();
const express = require('express');
const mongoose = require('mongoose');
const session = require('express-session');
const MongoStore = require('connect-mongo');
const cors = require('cors');

const authRoutes = require('./routes/auth');
const noteRoutes = require('./routes/notes');

const app = express();
const PORT = process.env.PORT || 3001;

mongoose.connect(process.env.MONGODB_URI)
  .then(() => {
    console.log('Connected to MongoDB');
    // Create indexes for better performance
    createIndexes();
  })
  .catch(err => console.error('MongoDB connection error:', err));

async function createIndexes() {
  try {
    // Create text index for notes search
    await mongoose.connection.db.collection('notes').createIndex({
      title: 'text',
      content: 'text'
    });
    
    // Create compound index for user notes
    await mongoose.connection.db.collection('notes').createIndex({
      userId: 1,
      lastUpdated: -1
    });
    
    console.log('Database indexes created successfully');
  } catch (error) {
    console.log('Index creation warning:', error.message);
  }
}

app.use(cors({
  origin: function (origin, callback) {
    // Allow requests with no origin (like mobile apps, curl, Postman)
    if (!origin) return callback(null, true);
    
    // Allow specific web origins
    const allowedOrigins = [
      'http://localhost:3000',
      'https://exist-singer-look-paste.trycloudflare.com'
    ];
    
    if (allowedOrigins.includes(origin)) {
      return callback(null, true);
    }
    
    // For now, allow all origins for mobile app testing
    // In production, you'd want to be more restrictive
    return callback(null, true);
  },
  credentials: true
}));

app.use(express.json());
app.use(express.urlencoded({ extended: true }));

app.use(session({
  secret: process.env.SESSION_SECRET,
  resave: false,
  saveUninitialized: false,
  store: MongoStore.create({
    mongoUrl: process.env.MONGODB_URI,
    touchAfter: 24 * 3600,
    ttl: parseInt(process.env.SESSION_TTL) || 24 * 60 * 60,
    autoRemove: 'native',
    autoRemoveInterval: 10,
    stringify: false
  }),
  cookie: {
    secure: false,
    httpOnly: true,
    maxAge: parseInt(process.env.SESSION_MAX_AGE) || 24 * 60 * 60 * 1000
  }
}));

app.use('/api/auth', authRoutes);
app.use('/api/notes', noteRoutes);

app.get('/api/health', (req, res) => {
  res.json({ message: 'Server is running', timestamp: new Date().toISOString() });
});

app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});
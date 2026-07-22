#!/usr/bin/env node

require('dotenv').config();
const mongoose = require('mongoose');

async function monitorSessions() {
  try {
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('Connected to MongoDB');
    
    const db = mongoose.connection.db;
    const sessionsCollection = db.collection('sessions');
    
    const totalSessions = await sessionsCollection.countDocuments();
    const activeSessions = await sessionsCollection.countDocuments({
      expires: { $gt: new Date() }
    });
    const expiredSessions = totalSessions - activeSessions;
    
    console.log('\n=== Session Status ===');
    console.log(`Total Sessions: ${totalSessions}`);
    console.log(`Active Sessions: ${activeSessions}`);
    console.log(`Expired Sessions: ${expiredSessions}`);
    
    if (totalSessions > 0) {
      console.log('\n=== Recent Sessions ===');
      const recentSessions = await sessionsCollection
        .find({}, { projection: { _id: 1, expires: 1 } })
        .sort({ expires: -1 })
        .limit(5)
        .toArray();
      
      recentSessions.forEach((session, index) => {
        const isExpired = session.expires < new Date();
        const status = isExpired ? '(EXPIRED)' : '(ACTIVE)';
        console.log(`${index + 1}. ${session._id} - expires: ${session.expires} ${status}`);
      });
    }
    
    console.log('\n=== TTL Index Info ===');
    const indexes = await sessionsCollection.indexes();
    const ttlIndex = indexes.find(idx => idx.name === 'expires_1');
    if (ttlIndex) {
      console.log(`TTL Index: ${ttlIndex.name}`);
      console.log(`Expire After: ${ttlIndex.expireAfterSeconds} seconds`);
    } else {
      console.log('TTL Index not found');
    }
    
  } catch (error) {
    console.error('Error:', error);
  } finally {
    await mongoose.disconnect();
    console.log('\nDisconnected from MongoDB');
  }
}

if (require.main === module) {
  monitorSessions();
}

module.exports = { monitorSessions };
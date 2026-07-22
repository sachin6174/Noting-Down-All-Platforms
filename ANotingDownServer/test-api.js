#!/usr/bin/env node

// Simple script to test the API endpoints
const https = require('http');
const querystring = require('querystring');

const API_BASE = 'http://localhost:3001/api';

function makeRequest(method, path, data = null) {
  return new Promise((resolve, reject) => {
    const options = {
      hostname: 'localhost',
      port: 3001,
      path: `/api${path}`,
      method: method,
      headers: {
        'Content-Type': 'application/json',
      }
    };

    const req = https.request(options, (res) => {
      let body = '';
      
      res.on('data', (chunk) => {
        body += chunk;
      });
      
      res.on('end', () => {
        try {
          const parsed = JSON.parse(body);
          resolve({
            status: res.statusCode,
            data: parsed
          });
        } catch (error) {
          resolve({
            status: res.statusCode,
            data: body
          });
        }
      });
    });

    req.on('error', (error) => {
      reject(error);
    });

    if (data) {
      req.write(JSON.stringify(data));
    }
    
    req.end();
  });
}

async function testAPI() {
  console.log('🧪 Testing Noting Down API...\n');

  try {
    // Test 1: Health check
    console.log('1. Testing health endpoint...');
    const health = await makeRequest('GET', '/health');
    console.log(`   Status: ${health.status}`);
    console.log(`   Response: ${JSON.stringify(health.data)}`);
    console.log('   ✅ Health check passed\n');

    // Test 2: User signup
    console.log('2. Testing user signup...');
    const testUser = {
      email: `test${Date.now()}@example.com`,
      username: `testuser${Date.now()}`,
      password: 'password123'
    };

    const signup = await makeRequest('POST', '/auth/signup', testUser);
    console.log(`   Status: ${signup.status}`);
    console.log(`   Response: ${JSON.stringify(signup.data, null, 2)}`);
    
    if (signup.status === 201 && signup.data.success) {
      console.log('   ✅ User signup successful\n');
      
      // Test 3: User login
      console.log('3. Testing user login...');
      const login = await makeRequest('POST', '/auth/login', {
        email: testUser.email,
        password: testUser.password
      });
      
      console.log(`   Status: ${login.status}`);
      console.log(`   Response: ${JSON.stringify(login.data, null, 2)}`);
      
      if (login.status === 200 && login.data.success) {
        console.log('   ✅ User login successful\n');
      } else {
        console.log('   ❌ User login failed\n');
      }
    } else {
      console.log('   ❌ User signup failed\n');
    }

  } catch (error) {
    console.error('❌ API test failed:', error.message);
    console.log('\n🔍 Troubleshooting:');
    console.log('   - Make sure the server is running: npm run dev');
    console.log('   - Check if MongoDB is connected');
    console.log('   - Verify .env file configuration');
  }
}

if (require.main === module) {
  testAPI();
}

module.exports = { testAPI, makeRequest };
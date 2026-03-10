module.exports = {
  apps: [{
    name: 'motorbike-parking-api',
    script: './backend/src/server.js',
    cwd: './motorbike_app',
    env: {
      NODE_ENV: 'development',
      PORT: 3000
    },
    env_production: {
      NODE_ENV: 'production',
      PORT: 3000
    }
  }]
};

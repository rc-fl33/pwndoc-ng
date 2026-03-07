// Centralized environment variable configuration with config.json fallback
var env = process.env.NODE_ENV || 'dev';
var configFile = {};

try {
    configFile = require('./config.json')[env] || {};
} catch (e) {
    // config.json may not exist in containerized deployments
}

module.exports = {
    port: parseInt(process.env.APP_PORT, 10) || configFile.port || 4242,
    host: process.env.APP_HOST || configFile.host || '',
    database: {
        name: process.env.MONGO_DB_NAME || (configFile.database && configFile.database.name) || 'pwndoc',
        server: process.env.MONGO_HOST || (configFile.database && configFile.database.server) || 'mongo-pwndoc-ng',
        port: process.env.MONGO_PORT || (configFile.database && configFile.database.port) || '27017',
        username: process.env.MONGO_USERNAME || '',
        password: process.env.MONGO_PASSWORD || '',
    },
    jwtSecret: process.env.JWT_SECRET || configFile.jwtSecret || '',
    jwtRefreshSecret: process.env.JWT_REFRESH_SECRET || configFile.jwtRefreshSecret || '',
    apidoc: process.env.APIDOC === 'true' || configFile.apidoc || false,
    corsOrigin: process.env.CORS_ORIGIN || '*',
    collabPort: parseInt(process.env.COLLAB_WEBSOCKET_PORT, 10) || 8440,
    bodyLimit: process.env.BODY_LIMIT || '20mb',
};

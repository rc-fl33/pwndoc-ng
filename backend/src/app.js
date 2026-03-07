var fs = require('fs');
var app = require('express')();
var https = require('https').Server({
  key: fs.readFileSync(__dirname+'/../ssl/server.key'),
  cert: fs.readFileSync(__dirname+'/../ssl/server.cert')
}, app);
var config = require('./config/env');
var io = require('socket.io')(https, {
  cors: {
    origin: config.corsOrigin === '*' ? true : config.corsOrigin.split(',')
  }
})
var bodyParser = require('body-parser');
var cookieParser = require('cookie-parser')
var utils = require('./lib/utils');


const swaggerUi = require('swagger-ui-express');
const swaggerDocument = require('./config/swagger-output.json');


global.__basedir = __dirname;

// Database connection
var mongoose = require('mongoose');
mongoose.Promise = global.Promise;
mongoose.Schema.Types.String.set('trim', true);

var mongoUri;
if (config.database.username && config.database.password) {
  mongoUri = `mongodb://${encodeURIComponent(config.database.username)}:${encodeURIComponent(config.database.password)}@${config.database.server}:${config.database.port}/${config.database.name}?authSource=admin`;
} else {
  mongoUri = `mongodb://${config.database.server}:${config.database.port}/${config.database.name}`;
}
mongoose.connect(mongoUri, {});

// Models import
require('./models/user');
require('./models/audit');
require('./models/client');
require('./models/company');
require('./models/template');
require('./models/vulnerability');
require('./models/vulnerability-update');
require('./models/language');
require('./models/audit-type');
require('./models/vulnerability-type');
require('./models/vulnerability-category');
require('./models/custom-section');
require('./models/custom-field');
require('./models/image');
require('./models/settings');

// Socket IO configuration
io.on('connection', (socket) => {
  socket.on('join', (data) => {
    console.log(`user ${data.username} joined room ${data.room}`)
    socket.username = data.username;
    do { socket.color = '#'+(0x1000000+(Math.random())*0xffffff).toString(16).substr(1,6); } while (socket.color === "#77c84e")
    socket.join(data.room);
    io.to(data.room).emit('updateUsers');
  });
  socket.on('leave', (data) => {
    console.log(`user ${data.username} left room ${data.room}`)
    socket.leave(data.room)
    io.to(data.room).emit('updateUsers');
  })
  socket.on('updateUsers', (data) => {
    var userList = [...new Set(utils.getSockets(io, data.room).map(s => {
      var user = {};
      user.username = s.username;
      user.color = s.color;
      user.menu = s.menu;
      if (s.finding) user.finding = s.finding;
      if (s.section) user.section = s.section;
      return user;
    }))];
    io.to(data.room).emit('roomUsers', userList);
  })
  socket.on('menu', (data) => {
    socket.menu = data.menu;
    (data.finding)? socket.finding = data.finding: delete socket.finding;
    (data.section)? socket.section = data.section: delete socket.section;
    io.to(data.room).emit('updateUsers');
  })
  socket.on('disconnect', () => {
    socket.broadcast.emit('updateUsers')
  })
});

// CORS
app.use(function(req, res, next) {
  var origin = config.corsOrigin;
  if (origin !== '*') {
    var allowed = origin.split(',').map(s => s.trim());
    if (allowed.includes(req.headers.origin)) {
      res.header("Access-Control-Allow-Origin", req.headers.origin);
      res.header('Access-Control-Allow-Credentials', 'true');
    }
  }
  res.header("Access-Control-Allow-Methods", "GET,POST,DELETE,PUT,OPTIONS");
  res.header("Access-Control-Allow-Headers", "Origin, X-Requested-With, Content-Type, Accept");
  res.header('Access-Control-Expose-Headers', 'Content-Disposition')
  next();
});

app.use(bodyParser.json({limit: config.bodyLimit}));
app.use(bodyParser.urlencoded({
  limit: '10mb',
  extended: false
}));

app.use(cookieParser())

// Health check endpoint
app.get("/api/health", function(req, res) {
  var dbState = mongoose.connection.readyState;
  var status = dbState === 1 ? 'healthy' : 'unhealthy';
  var code = dbState === 1 ? 200 : 503;
  res.status(code).json({
    status: status,
    database: dbState === 1 ? 'connected' : 'disconnected',
    uptime: process.uptime()
  });
});

// Routes import
require('./routes/user')(app);
require('./routes/audit')(app, io);
require('./routes/client')(app);
require('./routes/company')(app);
require('./routes/vulnerability')(app);
require('./routes/template')(app);
require('./routes/vulnerability')(app);
require('./routes/data')(app);
require('./routes/image')(app);
require('./routes/settings')(app);

const { cronJobs } = require('./lib/cron');
cronJobs();

var hocus = require('@hocuspocus/server')
var acl = require('./lib/auth').acl;
var Audit = require('mongoose').model('Audit');


  const serverHocus = hocus.Server.configure({
    port: config.collabPort,
      onUpgrade(data) {
        return new Promise( async (resolve, reject) =>  {
          const { request, socket, head } = data
          var waitProcess = false
          request.rawHeaders.forEach( async (header) => {
            if(header.includes('token=JWT%20')) {
              header.split('; ').forEach(cookie =>{
                splitedToken = cookie.split('%20')
                if(splitedToken.length > 1 && acl.hasPermissionFromReq('audits:read',splitedToken[1]) ){
                  decodeToken = acl.hasPermissionFromReq('audits:read',splitedToken[1])
                  auditId=''
                  if(request.url.split('/').length>=2){
                    auditId=request.url.split('/')[2]
                  }
                  var query = Audit.findById(auditId)
                  if (decodeToken.role!="admin"){
                    query.or([{creator: decodeToken.id}, {collaborators: decodeToken.id}, {reviewers: decodeToken.id}])
                  }
                  waitProcess=true
                  query.exec().then( x=> resolve()).catch(err=>reject())
                }
              })
            }
          })
          if(!waitProcess){
            reject()
          }
        })
      }
  })
  serverHocus.listen()


if(config.apidoc) {
  app.use('/api-docs', swaggerUi.serve, swaggerUi.setup(swaggerDocument));
}


app.get("*", function(req, res) {
    res.status(404).json({"status": "error", "data": "Route undefined"});
})

// Start server
https.listen(config.port, config.host)
console.log(`Server started on port ${config.port}`)

// Graceful shutdown
function gracefulShutdown(signal) {
  console.log(`${signal} received. Shutting down gracefully...`);
  https.close(() => {
    console.log('HTTP server closed');
    serverHocus.destroy();
    mongoose.connection.close(false).then(() => {
      console.log('MongoDB connection closed');
      process.exit(0);
    });
  });
  setTimeout(() => {
    console.error('Forced shutdown after timeout');
    process.exit(1);
  }, 10000);
}

process.on('SIGTERM', () => gracefulShutdown('SIGTERM'));
process.on('SIGINT', () => gracefulShutdown('SIGINT'));

module.exports = app;

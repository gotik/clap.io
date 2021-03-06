#
# Module dependencies.
#

express = require 'express'
stylus = require 'stylus'
nib = require 'nib'
config  = require('./config').cfg

GLOBAL.cfg = config

# Proxy
httpProxy = require '../proxy/lib/node-http-proxy'

data =
	"router":
		"clap.io": "localhost:"+cfg.port.clap
		"api.clap.io": "localhost:"+cfg.port.haibu
		"ssh.clap.io": "localhost:22"
		"mongo.clap.io": "localhost:28017"

Server = require('mongodb').Server
Db = require('mongodb').Db
db = new Db('clap', new Server("127.0.0.1", cfg.port.mongo || 27017, {auto_reconnect: false, poolSize: 4}), {native_parser: false})
db.open (err, db) ->
	if db
		db.createCollection 'proxy', (err, collection) ->
			collection.find().toArray (err, docs) ->
				db.close()
				if !err
					for doc in docs
						server.proxy.addHost doc.domain, doc.router
				else
					console.log err
	else
		console.log('start db')

proxy_config = data

GLOBAL.server = httpProxy.createServer proxy_config

server.listen cfg.port.proxy || 80, ->
	console.log 'proxy listening on port', cfg.port.proxy


# haibu
path = require 'path'
util = require 'util'
argv = require('optimist').argv
haibu = require '../haibu/lib/haibu'

env  = argv.env || 'production'

haibu.utils.bin.getAddress argv.a, (err, address) ->
	options =
		env: env
		port: cfg.port.haibu || 4000
		host: address

	haibu.drone.start options, ->
		#haibu.utils.showWelcome('api-server', address, port)
		console.log 'haibu listening on port', cfg.port.haibu

# clap app
routes =
	home: require "./routes/home"
	user: require "./routes/user"

app = module.exports = express.createServer()

# Configuration

app.configure () ->
	app.set 'views', __dirname + '/views'
	app.set 'view engine', 'jade'
	app.use express.bodyParser()
	app.use express.methodOverride()
	app.use express.cookieParser()
	app.use express.session
		secret: require('crypto').randomBytes 48, (ex, buf) ->
					return buf.toString 'hex'

	# Stylus to CSS compilation
	app.use stylus.middleware
		src: __dirname + '/stylus'
		dest: __dirname + '/public'
		compile: (str, path) ->
			return stylus(str)
				.set('filename', path)
				.set('compress', true)
				.use(nib())
				.import('nib')

	# Static directory
	app.use express.static __dirname + '/public'
	app.use app.router

app.configure 'development', () ->
	app.use express.errorHandler { dumpExceptions: true, showStack: true }

app.configure 'production', () ->
	app.use express.errorHandler()

# Routes

app.get "/", routes.home.index
#app.get "/user/settings", routes.user.settings
#app.post "/user/apps/new", routes.user.new_app
#app.post "/user/apps/:id", routes.user.modify_app
#app.get "/user/apps/:id", routes.user.apps
#app.post "/user/apps/", routes.user.modify_app
#app.get "/user/apps/", routes.user.apps
app.get "/register", routes.user.register
app.get "/register/:email/:coupon", routes.user.register
app.post "/register", routes.user.new_user
app.get "/login", routes.user.index
app.post "/login", routes.user.login
app.get "/coupon", routes.user.coupon
app.post "/coupon", routes.user.get_coupon
app.get "/apps", routes.user.apps
app.post "/apps/simple", routes.user.create_app_simple
app.post "/apps/complex", routes.user.create_app_complex
app.get "/apps/:id", routes.user.apps
app.all "/logout", routes.user.logout

app.listen cfg.port.clap || 3000, ->
	console.log 'clap listening on port', cfg.port.clap
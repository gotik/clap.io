
# Module dependencies.

express = require 'express'
stylus = require 'stylus'
nib = require 'nib'
routes = require './routes'

app = module.exports = express.createServer()

# Configuration

app.configure () ->
	app.set 'views', __dirname + '/views'
	app.set 'view engine', 'jade'
	app.use express.bodyParser()
	app.use express.methodOverride()
	app.use express.cookieParser()
	app.use stylus.middleware {
		src: __dirname + '/stylus',
		dest: __dirname + '/public',
		compile: (str, path) ->
			return stylus(str)
				.set('filename', path)
				.set('compress', true)
				.use(nib())
				.import('nib')
	}
	app.use app.router
	app.use express.static __dirname + '/public'

app.configure 'development', () ->
	app.use express.errorHandler { dumpExceptions: true, showStack: true }

app.configure 'production', () ->
	app.use express.errorHandler()

# Routes

app.get '/', routes.index

app.listen 8080
console.log "clap.io listening on port %d in %s mode", app.address().port, app.settings.env
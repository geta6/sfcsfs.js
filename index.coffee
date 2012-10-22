require.main.paths.unshift '/usr/local/lib'

request = require 'request'
cheerio = require 'cheerio'
Iconv   = (require 'iconv').Iconv
iconv   = new Iconv 'EUC-JP', 'UTF-8//TRANSLIT//IGNORE'
_       = require 'underscore'
colors  = require 'colors'
url     = require 'url'

class SFCSFS
  constructor: (user, pass, callback) ->
    @login user, pass, callback

  base: 'https://vu9.sfc.keio.ac.jp/sfc-sfs/'

  defaults:
    method: 'GET'
    encoding: null

  signature:
    id: null
    lang: null
    type: null
    mode: null

  request: (uri, param, callback) ->
    defaults = _.clone @defaults
    _.defaults param, defaults
    param.uri = @base + uri
    param.qs = @signature if _.all(@signature, (v) -> v isnt null)

    request param, (e, res, body) =>
      if e and res.statusCode isnt 200
        console.info "#{res.request.method}".grey, "#{res.request.href}".grey, "#{res.statusCode}".red
        console.error e, res
        process.exit 2
      else
        console.info "#{res.request.method}".grey, "#{res.request.href}".grey, "#{res.statusCode}".green
        res.body = iconv.convert(res.body).toString()
        callback cheerio.load(res.body), res

  login: (user, pass, callback) ->
    @request 'login.cgi'
      method: 'POST'
      form:
        u_login: user
        u_pass: pass
    , ($, res) =>
      _.extend @signature, (url.parse (res.body.match /^.*url=([0-9a-zA-Z:\/\.\-_\?&=]+).*?$/)[1], yes).query
      callback @

  logout: ->

  get: (type, callback) ->
    switch type
      when 'timetable'
        @request 'sfs_class/student/plan_timetable.cgi', {}, callback
      else
        console.error 'unknown type'.red

new SFCSFS 'USERNAME', 'PASSWORD', (agent) ->
  agent.get 'timetable', ($, res) ->
    console.log res


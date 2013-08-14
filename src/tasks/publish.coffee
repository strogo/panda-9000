fs = require("fs")
zlib = require("zlib")
{read} = require "fairmont"
{parse} = require "c50n"
{resolve,join,extname} = require "path"
glob = require "panda-glob"
{log,sh} = require "../operators"

buildPath = resolve("build/web")
envPath = resolve("env")

module.exports = 
  publish: (name) ->
    console.log @
    @compress ->
      config = parse(read(join(envPath,"#{name}/config.cson")))
      {bucket} = config.publish.s3
      for path in glob(buildPath, "**/*")
        unless extname(path) == ".gz"
          do (path) ->
            fullPath = join(buildPath, path)
            log "Updating [#{path}] ..."
            if extname(path) == ""
              sh "s3cmd -m 'text/html' --add-header=content-encoding:gzip put #{fullPath}.gz s3://#{bucket}/#{path}"
            else
              sh "s3cmd  --add-header=content-encoding:gzip put #{fullPath}.gz s3://#{bucket}/#{path}"
  compress: (callback) ->
    pending = 0
    finish = ->
      if --pending == 0
        callback?()
    for path in glob(buildPath, "**/*")
      unless extname(path) == ".gz"
        do (path) ->
          pending++
          fullPath = join(buildPath, path)
          log "Compressing [#{path}] ..."
          readStream = fs.createReadStream(fullPath)
          writeStream = fs.createWriteStream("#{fullPath}.gz")
          writeStream.on "finish", finish
          readStream.pipe(zlib.createGzip()).pipe(writeStream)    
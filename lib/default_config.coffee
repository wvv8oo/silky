#默认的配置文件，用于非silky项目
module.exports =
  version: 0.2
  port: 14422
  compatibleModel: false
  proxy: forward: {}
  routers: []
  plugin: {}
  build:
    output: "./silky_build"
    copy: []
    ignore: [/(^|\/)\.(.+)$/]
    rename: []
    compress: ignore: [], js: true, css: true, html: false, internal: false

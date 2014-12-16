###
  这是一个silky的示例插件，它将演示如何开发一个silky的插件。
###

#标识这是一个silky插件
exports.silkyPlugin = true
#提供注册插件的入口
exports.registerPlugin = (silky)->
  return

  #注册一个hook的示例，silky.registerHook(hookName, options, factory)
  #如果需要异步，请将options.async置为true
  #factory是一个处理函数，data会根据不同的hook返回不同的数据，如果options.async＝true，则必需调用done(null)返回

  #路由开始的hook，在这里可以截获路由进行处理。
  # 如果希望使用其它模板引擎，scss或者支持typescript等，在这里可以处理
  silky.registerHook 'route:initial', {async: true}, (data, done)->
    #只接管特定的文件
    return done null if not /js\/typescript\.js$/i.test data.request.url
    #编译typescript的代码，略
    #content = typeScriptCompiler(file)
    content = '假定这是编译后的代码'
    data.response.end(content)
    #阻止路由继承执行
    data.stop = true
    done null

  silky.registerHook 'build:willMake', {}, options, (data, done)->
    #构建的时候，跳过images-demo这个文件夹
    data.ignore = true if data.relativePath is 'images-demo'
    done null

  silky.registerHook 'build:willCompress', {}, options, (data, done)->
    #跳过对css文件的压缩
    data.ignore = true if /\.css$/.test data.path

  silky.registerHook 'route:willResponse', {}, (data, options, done)->
    #在响应内容的最后加上注释
    data.content += '<!--这里是注释-->'
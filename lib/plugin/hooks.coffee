module.exports =
  #路由的hook
  route:
    initial: 'route:initial'
    willPrepareDirectory: 'route:willPrepareDirectory'
    didPrepareDirectory: 'route:didPrepareDirectory'
#    willCompile: 'route:willCompile'      #将要编译less/coffee/hbs
#    didCompile: 'route:didCompile'        #完成编译less/coffee/hbs
    willResponse: 'route:willResponse'    #将要响应
  #构建时的hook
  build:
    willCompress: 'build:willCompress'
    didCompress: 'build:didCompress'
    willBuild: 'build:willBuild'
    didBuild: 'build:didBuild'
    willCompile: 'build:willCompile'
    didCompile: 'build:didCompile'
    willProcess: 'build:willProcess'   #预处理文件或者文件夹，复制或者编译(仅限于coffee/less/handlebars)
    didProcess: 'build:didProcess'     #预处理结束
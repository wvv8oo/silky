/**
 * Created by wvv8oo on 1/26/15.
 * 支持javascript和coffeescript
 */

//声明这是一个silky插件，必需存在
exports.silkyPlugin = true;

//注册silky插件
exports.registerPlugin = function(silky, options) {
    //注册handlebars的helper，关于handlebars，请参考：http://handlebarsjs.com/
    silky.registerHandlebarsHelper('customCommand', function(value, done) {
        //直接返回value，什么也不做，你可以根据需要返回具体的数据
        return value
    });

    //将要响应路由时hook
    silky.registerHook('route:willResponse', function(data, done) {
        //如果是html文件，则在最后面加上一个时间戳
        if (/\.html$/.test(data.request.url)) {
            var extendText = "<!--" + new Date() + "-->";
            data.content += extendText;
        }
    });

    //编译完成后的的hook
    silky.registerHook('build:didCompile', {
        //这里声明使用异步，如果async:true，那么必需显式调用done()
        async: true
    }, function(data, done) {
        //这里可以做任何你想做的事，比如说合并文件等
        return done(null);
    });

    /*
     更多的hook如下，具体的hook使用方法，请参考API文档

     initial: 'route:initial'
     willPrepareDirectory: 'route:willPrepareDirectory'
     didPrepareDirectory: 'route:didPrepareDirectory'
     willResponse: 'route:willResponse'
     willCompress: 'build:willCompress'
     didCompress: 'build:didCompress'
     willBuild: 'build:willBuild'
     didBuild: 'build:didBuild'
     willCompile: 'build:willCompile'
     didCompile: 'build:didCompile'
     willProcess: 'build:willProcess'
     didProcess: 'build:didProcess'
     */
};
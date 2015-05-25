module.exports = {
    //配置文件的版本，和silky的版本无关
    version: 0.2,
    //80端口在*nix下需要sudo
    port: 14422,
    //使用兼容模式，即可以兼容0.5.5之前的silky项目
    compatibleModel: true,
    //代理配置相关，兼容json-proxy的代理配置
    proxy: {
        forward: {
            //定义代理转发
            //"/ajax": "/"
        }
    },
    //如果不需要启用livereload，请注释掉livereload，默认监控扩展名为：'less', 'coffee', 'hbs', 'html', 'css'
    livereload: {},
    //路由
    routers: [
        //如果希望访问目录直接访问index.html，则可以启用下面的路由
        {
            //path: 原路径，to: 替换后的路径，next：是否继承执行下一个路由替换，static：是否为静态文件，静态文件直接返回
            path: /^\/$/, to: 'index.html', next: true, static: false
        }
    ],
    //插件的配置
    plugins: {
        /*
        //为插件指定目录，可以指定特殊目录的插件
        "specific_plugin": {
            "source": "指定插件的源路径",
            "priority": 1
        }
        */
    },
    //build的配置
    build: {
        //构建的目标目录，命令行指定的优先
        output: "./build",
        //将要复制的文件目录，直接复制到目标
        copy: [/^images(\-demo)?$/i],
        //完全忽略处理的文件
        ignore: [/^template\/module$/i, /^css\/module$/i, /(^|\/)\.(.+)$/, /\.(log)$/i],
        //重命名
        rename: [
            {
                source: /^template\/(.+)/i, target: '$1', next: false
            }
        ],
        //是否压缩
        compress: {
            //将要忽略压缩的文件
            ignore: [],
            //压缩js，包括coffee
            js: true,
            //压缩css，包括less
            css: true,
            //压缩html
            html: false,
            //是否压缩internal的js
            internal: true
        }
    }
}
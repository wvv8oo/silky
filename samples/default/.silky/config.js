module.exports = {
    //配置文件的版本，和silky的版本无关
    version: 0.2,
    //80端口在*nix下需要sudo
    port: 14422,
    //使用兼容模式，即可以兼容0.5.5之前的silky项目
    compatibleModel: true,
    //加在css与js后面加入缓存的md5信息
    //{md5}将会获得一个随机的md5值，{date}将会获得当前的日期，{datetime}将会获得当前时间
    uniqueKey: 'v={md5}',
    //代理配置相关，兼容json-proxy的代理配置
    proxy: {
        forward: {
            //定义代理转发
            //"/ajax": "/"
        }
    },
    /*
    //编译器相关
    compiler: {
        //根据规则捕获文件路径，并指定路由
        //注意，路径捕获规则的优先级要高于扩展名规则
        rules: [
            {
                path: /^index\.(html|jade)$/i, compiler: 'jade'
            }
        ],
        //根据扩展名指定编译器，这也是默认的编译器配置
        extension: {
            htm: 'hbs',
            html: 'hbs',
            css: 'less',
            js: 'coffee'
        }
    },
    */
    //如果不需要启用livereload，请注释掉livereload，默认监控扩展名为：'less', 'coffee', 'hbs', 'html', 'css'
    livereload: {},
    //路由
    routers: [
        {
          //将所有扩展名为js的重命名为coffee，指定编译器为coffee
          path: /^(.+).js$/i, to: '$1.coffee', compiler: 'coffee', next: false
        },
        //如果希望访问目录直接访问index.html，则可以启用下面的路由
        {
            //path: 原路径，
            //to: 替换后的路径
            //next：是否继承执行下一个路由替换
            //static：是否为静态文件，静态文件直接返回
            //executable： 是否可执行，如果可执行，则会以node.js文件的方式被require并执行
            path: /^\/$/, to: 'index.html', next: true, static: false, executable: false
        },
        {
            path: /^\/api\/.+/, to: 'server.js', next: false, executable: true
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
    //合并规则
    merge: [
        {
            //合并后的文件名
            target: "main.js",
            //捕获的规则
            matches: []
        }
    ],
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
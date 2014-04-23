/*
    导出的配置文件
 */
module.exports = {
    //默认使用80端口，*nix下需要sudo
    port: 14422,
    //代理配置相关，兼容json-proxy的代理配置
    proxy: {

    },
    //build的配置
    build: {

    },
    //将要监控哪些文件目录
    watch: {
        //监控js目录，以js和coffee结尾的，将被监控
        "js": /(js|coffee)$/i,
        //监控less和css
        "css": /(css|less)$/i,
        //监控handlebars
        "template": /(html|hbs)$/ig
    }
}
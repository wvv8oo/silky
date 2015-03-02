Silky是一个前端模块化开发与构建工具，自带HTTP服务器，支持多环境，支持多国语言，支持代理与路由转发，自动化编译构建，实时编译CoffeeScript和Less，支持插件扩展

## 依赖条件

* `node.js v0.10` 以上以及`npm`，如果你还没有安装node.js，请参考：[Installing Node.js via package manager](https://github.com/joyent/node/wiki/Installing-Node.js-via-package-manager)

* 如果你使用的是windows系统，建议安装[git-bash](http://www.git-scm.com/downloads)

## 快速入门

### 安装并创建示例项目

1. `npm install -g silky coffee-script`，安装silky以及全局的coffee-script，*nix下会需要`sudo`权限
2. `cd ~ && mkdir silky-test && cd ~/silky-test` (Windows下可以考虑使用：`cd %HOMEPATH% && mk silky-test && cd %HOMEPATH%/silky-test`)
3. `silky init -f`
4. `silky start`
5. 用浏览器打开`http://localhost:14422/`，即可看到示例项目了

更多敬请访问官方博客：[Silky官方博客](http://silky.wvv8oo.com/)
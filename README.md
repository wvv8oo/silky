#Silky

**文档非常老旧，新增加了很多功能，有空我更新一下**

Silky是一个多用户协作的前端开发环境，正如她的名字一样，Silky希望让前端的协作开发能如丝般的润滑。Silky基于Handlebars和Less，选择Handlebars作为模板引擎的原因是因为它很简单，Less的争议性可能没有模板引擎这么大，毕竟可供选择的并不多。

对于重构人员来说，TA可能只需要记住几条模板命令就能轻松实现模块化开发了。Silky除了支持原来的Handlebars命令，还对Handlebars进行扩展，支持`import`，`loop`，未来可能还会支持更多的命令。

#功能摘要

* 集成HTTP功能，只需要一条命令就可以在当前目录下创建一个Silky服务器
* 支持代理，用于解决跨域问题
* 支持HTML与CSS模块化开发
* 实时编译coffee和less文件
* 支持路由重写
* 支持多环境
* 支持多语言

#安装
1. 在*nix下，使用`sudo npm install -g silky`执行安装，在此之前，请确保你已经安装了node.js。请注意，silky必需全局安装。
2. 如果你没有安装coffee-script，你需要使用`npm install -g coffee-script`进行安装

#使用
1. 在你的工作目录，执行`silky init`创建一个新的silky工作环境 **注意：目前还不支持此命令，需要复制`samples/.silky`到工作目录
2. 执行`silky`命令，默认情况下，你可以使用`http://localhost:14422/`来访问你的网站

##silky命令及参数

silky命令的参数优先级要高于配置文件，例如你在配置文件指定了端口为14422，但如果你使用`silky -p 80`，那么silky的监听端口将会是80而不是14422

### build

`silky build`可以将项目build到一个指定的文件夹，你也可以配合`-o`来指定输出的目录，配合`-e`来指定工作环境，默认情况下，`silky build`的工作环境为production

### init
'silky init`可以初始化一个silky项目，这将会在当前的目录下创建一个.silky的配置文件夹。使用`silky init -f`，可以创建一个silky的示例项目，其目录结构是silky推荐的目录结构。

### -p
`silky -p`指定工作端口，如`sudo silky -p 80`，注意：80端口在*nix下需要su权限

### -e
`silky -e`用于指定工作环境，如`silky -e production`将会工作于production环境，silky将会读取`.silky/production`下的所有配置文件


#模板
模板是silky很重要的一环，silky采用[handlebars](https://github.com/wycats/handlebars.js/)作为标准模板，更多可以参考handlebars的官方网站。silky将`.hbs`作为模板的识别扩展名。

silky对handlebars进行扩展，如果你并不熟悉，你只需要记住扩展的几个命令就可以了。

##路由

silky遵从html文件优先原则，换句话说，当你访问`http://localhost:14422/index.html`的时候，silky首先会查找`template/index.html`，如果存在则直接返回这个html文件，否则会查找`template/index.hbs`执行渲染并返回

##数据源

silky在启动的时候，会扫描`.silky/development`下的所有json文件作为模板渲染的数据源，如果工作环境为`production`，将会扫描`./silky/production`下的所有json文件。

文件名将被作为键值。例如在`.silky/development`下有global.json和index.json文件，那么，在模板中使用`{{global.title}}`，将会取到global.json文件中的title键值。`page.index.foo`将会读取page.json文件中的`index.foo`键值。

数据源将会处于被监控状态，当任何数据源发生变化，都将会引起浏览器的自动刷新。

###silky变量
在模板中，silky是一个全局变量，提供silky的一些运行信息，如`{{silky.env}}`将会输出工作环境是development或production，一般用于根据开发环境或工作环境输出不同的html。

##扩展的命令
###partial/import
`import`命令兼容`partial`，但推荐使用`import`，因为更为直观和常用。

示例：`{{import "module/header" global.foo}}`

引用子模块，handlebars本来是使用`{{> module/file}}`的方式引用子模板，但是原生的命令并不支持传递参数，import命令可以传递参数。在示例命令中，将会传递`global.foo`给子模板。

import的模板路径为相对于template下的绝对路径，换句话说，如果你的子模板在`/template/module/header`，而模板文件在`/template/authority/signin`，import的引用路径应为`module/header`。**记住，不管你的模板文件在什么位置，或者子模板嵌套引用，都需要使用绝对路径。**

注意，如果import指定了数据源，那么被import的子模板使用的数据源就是这个被指定的数据源，而非全局的数据源。例如`{{import "module/header" page.index.header}}`，那么在`module/header`这个模板中，使用`{{title}}`将会读取` `page.index.header.title`，了解这一点非常重要。

##loop
示例：`{{loop "module/cell" 10}}`

loop命令用于循环输出某个子模块，第一个参数是模块的绝对路径，第二个参数是将要重复的次数据，但第二个参数也可以是从数据源中取得的数组。


##if

示例：`{{#if silky.env "development"}}当前环境是开发环境{{/if}}`
条件语句，注意中间并没有等号，这和我们平时用的不一样。


#css/less
silky支持less和css，关于less，请参考[less](http://lesscss.org/)的官方网站。

不同的是，silky下，less需要使用绝对路径进行引用，如果你要引用module下的header.less，应该是使用`@import "module/header";`，而不是`@import "../module/header";`

##路由

当你访问`http://localhost:14422/css/main.css`，将会和模板路由同样的原则，css优先于less，所以，不要试图在同一个文件下存在文件名相同而扩展名不同的文件。如main.css和main.less，这样将永远无法响应到main.less

#js/coffee
silky同时支持js和coffee，如果是coffee，在被请求的时候，将会编译为js并返回。关于coffeescript，参考[coffeescript](http://coffeescript.org/)的官方网站。

##路由
当你访问`http://localhost:14422/js/main.js`，将会和模板路由同样的原则，js优先于coffee，所以，不要试图在同一个文件下存在文件名相同而扩展名不同的文件。如main.js和main.coffee，这样将永远无法响应到main.coffee

基于内部原因，silky会替换掉路径中含有.souce的字符，如`http://localhost:14422/js/main.souce.js`，返回的将会是`http://localhost:14422/js/main.js`。

#配置文件

配置文件位置在`.silky/config.js`，config.js是一个node.js文件。

##port

指定端口，默认为14422

##proxy
指定代理，一般用于跨域请求，silky集成的代理为[json-proxy](https://github.com/steve-jansen/json-proxy)。通常情况下，只需要配置proxy.forward键就可以了。关于proxy的配置，请参考json-proxy的相关设置

##build
用于配置build相关

###output
指定输出目录，默认为`./build`

###compress
指定是否压缩，可指定的项包括：`js`，`css`，`html`，`internal`。注意`internal`是指定是否压缩内联script

##copy
将要复制的目录，通常有些目录在产品环境下是不需要的，如一些demo图片文件等

##compile
编译处理的目录，在这里你可以设置build目标的目录和忽略文件。例如，你希望将`template`目录中的文件都build到根目录下，则配置`template.target`为`./`即可。`ignore`可以配置忽略哪些文件，template和css默认情况下为`/module$/i`，这将忽略名为module的文件夹

##watch
配置将要监控哪些目录下文件的改动，key即是目录名，value是一个正则表达式，用于监控时匹配文件名。如果文件处于被监控中，当文件发生改变，将会引发浏览器中网页的自动刷新。

#Silky项目的文件组织

一个典型的Silky的结构如下：
	
	|____.silky
	| |____config.js
	| |____development
	| | |____global.json
	| | |____global.less
	| |____production
	| | |____global.json
	| | |____global.less
	|____css
	| |____main.less
	| |____module
	| | |____global.less
	| |____normalize.css
	|____images
	|____js
	| |____main.coffee
	| |____thorax.js
	|____template
	| |____index.hbs
	| |____module
	| | |____footer.hbs
	| | |____head.hbs
	| | |____header.hbs
	
##template
template目录用于存放模板文件`.hbs`和`.html`文件

##css
css目录用于存放`.css`和`.less`文件

##js
js目录用于存放`.js`和`.coffee`文件

##.silky
.silky文件夹是silky的配置文件

#History
## 0.2.1

* 支持路由转发，可以根据项目实际情况使用实际并不存在的URL
* 支持Crash后自动重启
* 支持配置启否使用livereload，并支持AMD
* 修复在Linux和Windows下会出现因Deep Watch而Crash的问题?
* 支持作为Express中间件的方式被调用
* 修复一些Bug

##0.1.2 2014-05-06
* 增加logo，并修复`silky init -f`没有初始化images和images-demo文件夹的bug
* 修复无法响应静态文件的bug

##0.1.0 2014-05-05
* 增加可运行的示例项目，默认运行即可以查看示例项目
* 路由支持目录式访问
* 全新的路由规则，使用正则统一判断
* 支持`silky init`的方式初始化项目，`silky init -f`可以创建一个完整的示例项目
* 用配置文件判断金鹰网特有的部分处理


##0.0.9 2014-05-04
* 增加了详细的README文件
* 增加了模板的`import`命令，用于替换`partial`

##0.0.8 2014-04-39
* 生成的代码包括HTML做了美化处理，代码会很整齐漂亮
* 增加代理功能
* 修复build的bug
* 修复其它的一些bug


##0.0.7 2014-04-30

* 兼容Windows的
* 全局silky增加了端口
* 增加合并honey.go
* 修复一些bug


##0.0.6 2014-04-28

* 增加handlebars预编译模块
* 扩展loop命令和partial命令

##0.0.5 2014-04-24

* 增加`silky build`命令，用于构建编译项目


#Authors

Conis: [wvv8oo@gmail.com](wvv8oo@gmail.com)

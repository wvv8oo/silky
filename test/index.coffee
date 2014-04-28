_precompiler = require '../lib/handlebars_precompiler'
_path = require 'path'
_fs = require 'fs'

dir = _path.join(__dirname, '../samples/js/template')
#读取模板
tpl = _path.join __dirname, '../lib/client/precompile.hbs'

content = _precompiler.precompile dir, _fs.readFileSync(tpl, 'utf-8')
console.log content

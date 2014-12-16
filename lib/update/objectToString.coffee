#转换对象
convertObject = (source)->
  list = []
  list.push("'#{key}': #{convert(value)}") for key, value of source

  "{#{list.join(',')}}"

#转换数组
convertArray = (source)->
  list = []
  list.push(convert item) for item in source

  "[#{list.join(',')}]"

convert = (source)->
  switch typeof source
    when 'string' then "\"#{source}\""
    when 'number', 'boolean', 'function' then source.toString()
    else
      if source instanceof Array
        convertArray(source)
      else if source instanceof RegExp
        source.toString()
      else convertObject(source)


module.exports = (obj)-> convert obj
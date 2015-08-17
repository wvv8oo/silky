
//自定义可执行文件
module.exports = function(req, res, next, silky){
  var result = {
    code: 10,
    message: "模拟API成功"
  }

  silky.responseJSON(res, result)
}
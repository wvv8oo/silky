(function(){
    //此段代码用于自动刷新，正式部署环境不会附加
    var socket = io.connect('/')
    //监控到page:change事件后，刷新页面
    socket.on('page:change', function(){
        location.reload()
    })
})()
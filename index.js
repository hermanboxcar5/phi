const express = require('express');
const { createServer } = require('node:http');
const  Server  = require('socket.io');

const app = express();
const server = createServer(app);
const io = new Server(server);

const util = require('util');
const exec = util.promisify(require('child_process').exec);



app.use("/", express.static(__dirname + "/static"));

//   console.log('a user connected');
//   socket.on("msg", data=>{
//     console.log("data recieved")
//     console.log("hi", data)
//   })
// });
io.on('connection', (socket) => {
  socket.on('chat message', (msg) => {
    console.log('message: ' + msg);
  });
  socket.on("")
});
server.listen(1234);

let cmd = {}
cmd.users={}
cmd.users.listusers = async ()=>{
  let ret = await exec("eval getent passwd {$(awk '/^UID_MIN/ {print $2}' /etc/login.defs)..$(awk '/^UID_MAX/ {print $2}' /etc/login.defs)} | cut -d: -f1")
  console.log(ret)
}
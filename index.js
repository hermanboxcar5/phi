const express = require('express');
const { createServer } = require('node:http');
const  Server  = require('socket.io');

const app = express();
const server = createServer(app);
const io = new Server(server);

const util = require('util');
const exec = util.promisify(require('child_process').exec);

let cmd = {}
cmd.users={}
cmd.users.listusers = async function (){
  let ret = await exec("/bin/bash -c \"eval getent passwd {$(/usr/bin/awk '/^UID_MIN/ {print $2}' /etc/login.defs)..$(/usr/bin/awk '/^UID_MAX/ {print $2}' /etc/login.defs)} | /usr/bin/cut -d: -f1\"");
  let users = ret.stdout.split("\n")
  if(users[users.length-1]==""){ users.pop() }
  return users
}
cmd.users.pwdchange = async function (user, pwd){
  let ret = await exec(`sudo echo -e "${pwd}\n${pwd}" | sudo passwd ${user}`);
  console.log(ret)
}
cmd.users.deluser = async function (user){
  if(window.confirm("Permanantly Delete User?")){
      let ret = await exec(`sudo userdel -r ${user}`)
      if(ret.stderr){
          window.alert("deluser error: ", ret.stderr)
      }
      return ret
  }
}



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
    cmd.users.listusers()
  });
  socket.on("loadusers1", async ()=>{
    let users = await cmd.users.listusers()
    socket.emit("loadusers2", JSON.stringify(users))
  })
});
server.listen(1234);


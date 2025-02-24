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
  try{
    let ret = await exec(`/bin/bash -c "getent passwd {$(awk '/^UID_MIN/ {print $2}' /etc/login.defs)..$(awk '/^UID_MAX/ {print $2}' /etc/login.defs)} || true"`);
    let users = ret.stdout.split("\n")
    if(users[users.length-1]==""){ users.pop() }
    users.map((info, i)=>{
        let list = info.split(":")
        users[i]={"user":list[0], "UID":list[2], "GID":list[3]}
    })
    return users
} catch(e){
    console.log(e)
}

}
cmd.users.pwdchange = async function (user, pwd){
  let ret = await exec(`sudo echo -e "${pwd}\n${pwd}" | sudo passwd ${user}`);
  console.log(ret)
}

cmd.users.deluser = async function (user){
    let ret = await exec(`sudo userdel -r ${user}`)
    if(ret.stderr){
      console.log("deluser error: ", ret.stderr)
    }
    return ret
}

cmd.users.adduser= async function (user, pwd, name="", room="", workphone="", homephone="", other=""){
        let gecos = "";
        [name, room, workphone, homephone, other].map(a=>{
            if(/\S/.test(a) && a !=""){
                gecos+=a+","
                console.log("validarg",  a)
            }
        })
        if(/\S/.test(gecos && gecos !="")){
            gecos = `--gecos "${gecos}"`
            console.log("gecos",  gecos)
        } else {
            gecos=""
        }
        console.log(user, gecos)
        let ret = await exec(`sudo echo -e "${pwd}\n${pwd}" | sudo adduser ${user} ${gecos} || true`);
        if(ret.stderr){
            console.log("adduser error: ", ret.stderr)
        }
        return ret
}


app.use("/", express.static(__dirname + "/static"));

io.on('connection', (socket) => {
  socket.on("loadusers1", async ()=>{
    let users = await cmd.users.listusers()
    socket.emit("loadusers2", JSON.stringify(users))
  })

  socket.on("passwdchg1", async (json)=>{
    json = JSON.parse(json)
    let ret = cmd.users.pwdchange(json.user, json.password)
    let obj = {success:false}
    if(!ret.stderr){
      obj.success=true
    } else {
      obj.err = ret.stderr
    }
    obj.msg=ret.stdout
    socket.emit("passwdchg2", JSON.stringify(obj))
  })

  socket.on("deluser1", async (user)=>{
    let ret = cmd.users.deluser(user)
    let obj = {success:false}
    if(!ret.stderr){
      obj.success=true
    } else {
      obj.err = ret.stderr
    }
    obj.msg=ret.stdout
    socket.emit("deluser2", JSON.stringify(obj))
  })
  socket.on("adduser1", async (json)=>{
    json = JSON.parse(json)
    let { user, pwd, name, room, workphone, homephone, other } = json
    let ret = cmd.users.adduser(user, pwd, name, room, workphone, homephone, other)
    let obj = {success:false}
    if(!ret.stderr){
      obj.success=true
    } else {
      obj.err = ret.stderr
    }
    obj.msg=ret.stdout
    socket.emit("adduser2", JSON.stringify(obj))
  })
});


server.listen(1234);


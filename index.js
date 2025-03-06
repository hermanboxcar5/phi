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
  let ret = await exec(`sudo echo -e "${pwd}\n${pwd}" | sudo passwd ${user} || true`);
  console.log(ret)
}

cmd.users.deluser = async function (user){
    let ret = await exec(`sudo userdel -r ${user} || true`)
    let ret2 = await exec(`sudo delgroup ${user} || true`)
    if(ret.stderr || ret2.stderr){
      console.log("deluser error: ", ret.stderr, ret2.stderr)
    }
    return ret
}

cmd.users.adduser= async function (user, pwd, name="", room="", workphone="", homephone="", other=""){
        let gecos = "";
        [name, room, workphone, homephone, other].map(a=>{
            if(a !=""){
                gecos+=a+","
                console.log("validarg",  a)
            }
        })
        if(gecos !=""){
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

cmd.groups = {}
cmd.groups.listgroupsof = async function (user){
  let ret = await exec(`sudo groups ${user}`)
  let groups = ret.stdout.split(" : ").join("\n").split("\n")[1]
  groups = groups.split(" ")
  return groups
}
cmd.groups.newgroup = async function (name){
  let ret = await exec(`sudo groupadd ${name} || true`)
  return ret
}
cmd.groups.delgroup = async function (name, force){
  let ret = await exec(`sudo groupdel ${force?"-f":""} ${name} || true`)
  console.log(ret)
  return ret
}
cmd.groups.addusertogroup = async function (user, group){
  let ret = await exec(`sudo gpasswd -a ${user} ${group} || true`)
  return ret
}
cmd.groups.removeuserfromgroup = async function (user, group){
  let ret = await exec(`sudo gpasswd --delete ${user} ${group} || true`)
  return ret
}
cmd.groups.listusersof = async function (group){
  let ret = await exec(`sudo getent group ${group} || true`)
  let users = ret.stdout.split(":").join("\n").split("\n")
  if(users[users.length-1]==""){
      users.pop()
  }
  users = users[users.length-1]
  users = users.split(",")
  return users
}
cmd.groups.changeprimarygroup = async function (user, group){
  let ret = await exec(`sudo usermod -g ${group} ${user} || true`)
  return ret
}
cmd.groups.getprimarygroup = async function (user){
  let ret = await exec(`sudo id -gn ${user}`)
        let out = ret.stdout
        if(out.includes("\n")){out = out.split("\n").join("")}
        return ret.stdout
}
cmd.groups.listall = async function(){
  let ret = await exec(`sudo getent group | cut -d: -f1,3`)
  let list = ret.stdout.split("\n")
  if(list[list.length-1]==""){list.pop()}
  list = list.filter(a=>(Number(a.split(":")[1])>=1000 && Number(a.split(":")[1])<=9999))
  list.map((a, e)=>list[e]=a.split(":")[0])
  return list
}
cmd.users.usercomplete = async function (){
  let users = await cmd.users.listusers()
  let retlist = []
  for (const user of users) {
    let obj = user
    obj.groups = await cmd.groups.listgroupsof(user.user)
    obj.primary = await cmd.groups.getprimarygroup(user.user)
    obj.allgroups = await cmd.groups.listall()
    retlist.push(obj)
  }
  return retlist
}


app.use("/", express.static(__dirname + "/static"));

io.on('connection', (socket) => {
  console.log("IO CONNECTION")
  socket.on("loadusers1", async ()=>{
    let users = await cmd.users.usercomplete()
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
    let ret = await cmd.users.adduser(user, pwd, name, room, workphone, homephone, other)
    let obj = {success:false}
    if(!ret.stderr){
      obj.success=true
    } else {
      obj.err = ret.stderr
    }
    obj.msg=ret.stdout
    socket.emit("adduser2", JSON.stringify(obj))
  })
  socket.on("addgroup1", async (json)=>{
    json = JSON.parse(json)
    console.log(json)
    let existing = await cmd.groups.listall()
    if(!existing.includes(json.group)){
      await cmd.groups.newgroup(json.group)
    }
    let ret = await cmd.groups.addusertogroup(json.user, json.group)
    console.log(ret)
    let obj = {success:false}
    if(!ret.stderr){
      obj.success=true
    } else {
      obj.err = ret.stderr
    }
    obj.msg = ret.stdout
    obj.user = json.user
    obj.group = json.group
    socket.emit("addgroup2", JSON.stringify(obj))
  })
  socket.on("revgroup1", async (json)=>{
    json = JSON.parse(json)
    let ret = await cmd.groups.removeuserfromgroup(json.user, json.group)
    console.log(ret)
    let obj = {success:false}
    if(!ret.stderr){
      obj.success=true
    } else {
      obj.err = ret.stderr
    }
    obj.msg=ret.stdout
    console.log(obj)
    socket.emit("revgroup2", JSON.stringify(obj))
  })
  socket.on("setprimary1", async (json)=>{
    json = JSON.parse(json)
    console.log(json)
    let existing = await cmd.groups.listall()
    if(!existing.includes(json.group)){
      await cmd.groups.newgroup(json.group)
    }
    let ret = await cmd.groups.changeprimarygroup(json.user, json.group)
    console.log(ret)
    let obj = {success:false}
    if(!ret.stderr){
      obj.success=true
    } else {
      obj.err = ret.stderr
    }
    obj.msg = ret.stdout
    obj.user = json.user
    obj.group = json.group
    socket.emit("setprimary2", JSON.stringify(obj))
  })
  socket.on("delgroup1", async (json)=>{
    json = JSON.parse(json)
    let ret = await cmd.groups.delgroup(json.group, json.force)
    console.log(ret)
    let obj = {success:false}
    if(!ret.stderr){
      obj.success=true
    } else {
      obj.err = ret.stderr
    }
    obj.msg = ret.stdout
    console.log(obj)
    socket.emit("delgroup2", JSON.stringify(obj))
  })
  socket.on("updatesys1", async json=>{
    let ret = await exec("sudo apt-get update -y && sudo apt-get upgrade -y && sudo apt-get dist-upgrade -y")
    let obj = {success:false}
      if(!ret.stderr){
        obj.success=true
      } else {
        obj.err = ret.stderr
      }
      obj.msg = ret.stdout
      console.log(obj)
      socket.emit("updatesys2", JSON.stringify(obj))
  })
  
  socket.on("firewallon1", async json=>{
    let ret = await exec("sudo apt install ufw -y && ufw enable")
    let obj = {success:false}
      if(!ret.stderr){
        obj.success=true
      } else {
        obj.err = ret.stderr
      }
      obj.msg = ret.stdout
      console.log(obj)
      socket.emit("firewallon2", JSON.stringify(obj))
  })
  
  socket.on("firewalloff1", async json=>{
    let ret = await exec("sudo apt install ufw -y && ufw disable")
    let obj = {success:false}
      if(!ret.stderr){
        obj.success=true
      } else {
        obj.err = ret.stderr
      }
      obj.msg = ret.stdout
      console.log(obj)
      socket.emit("firewalloff2", JSON.stringify(obj))
  })
});



server.listen(1234);


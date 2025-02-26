const util = require('util');
const exec = util.promisify(require('child_process').exec);


async function main() {
    async function userslist (){
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
    async function pwdchange(user, pwd){
        let ret = await exec(`sudo echo -e "${pwd}\n${pwd}" | sudo passwd ${user}`);
        if(ret.stderr){
            console.log("pwdchange error: ", ret.stderr)
        }
        return ret
    }
    async function deluser(user){
            let ret = await exec(`sudo userdel -r ${user}`)
            if(ret.stderr){
                console.log("deluser error: ", ret.stderr)
            }
            return ret
    }
    async function adduser(user, pwd, name="", room="", workphone="", homephone="", other=""){
        let gecos = ""
        [name, room, workphone, homephone, other].map(a=>{
            if(/\S/.test(a) && a !=""){
                gecos+=a+","
                console.log("validarg",  a)
            }
        })
        if(/\S/.test(gecos && gecos !="")){
            gecos = ` --gecos "${gecos}"`
            console.log("gecos",  gecos)
        } else {
            gecos=""
        }
        console.log(gecos)
        let ret = await exec(`sudo echo -e "${pwd}\n${pwd}" | sudo adduser ${user}${gecos} || true`);
        if(ret.stderr){
            console.log("adduser error: ", ret.stderr)
        }
        return ret
    }
    async function listgroupsof(user){
        let ret = await exec(`sudo groups ${user}`)
        let groups = ret.stdout.split(" : ").join("\n").split("\n")[1]
        groups = groups.split(" ")
        return groups
    }
    async function newgroup(name){
        let ret = await exec(`sudo groupadd ${name}`)
        return ret
    }
    async function deletegroup(name){
        let ret = await exec(`sudo groupdel ${name}`)
        return ret
    }
    async function addusertogroup(user, group){
        let ret = await exec(`sudo gpasswd -a ${user} ${group}`)
        return ret
    }
    async function removeuserfromgroup(user, group){
        let ret = await exec(`sudo gpasswd --delete ${user} ${group}`)
        return ret
    }
    async function listusersof(group){
        let ret = await exec(`sudo getent group ${group}`)
        let users = ret.stdout.split(":").join("\n").split("\n")
        if(users[users.length-1]==""){
            users.pop()
        }
        users = users[users.length-1]
        users = users.split(",")
        return users
    }
    async function changeprimarygroup(user, group){
        let ret = await exec(`usermod -g ${group} ${user}`)
        return ret
    }
    async function getprimarygroup(user){
        let ret = await exec(`id -gn ${user}`)
        let out = ret.stdout
        if(out.includes("\n")){out = out.split("\n").join("")}
        return ret.stdout
    }
    async function listgroups(){
        let ret = await exec(`getent group | cut -d: -f1,3`)
        let list = ret.stdout.split("\n")
        if(list[list.length-1]==""){list.pop()}
        list = list.filter(a=>(Number(a.split(":")[1])>=1000 && Number(a.split(":")[1])<=9999))
        console.log(list)
        list.map((a, e)=>list[e]=a.split(":")[0])
        return list
    }
    async function usercomplete(){
        let users = await userslist()
        let retlist = []
        await Promise.all(users.map(async user=>{
            let obj = user
            obj.groups = await listgroupsof(user.user)
            obj.primary = await getprimarygroup(user.user)
            obj.allgroups = await listgroups()
            retlist.push(obj)
        }))
        return retlist
    }
    
    async function listpackages(){
        let ret = await exec(`apt --installed list`)
        let list = ret.stdout.split("\n")
        return ret.stdout
    }

    console.log(await listpackages())
}
main();

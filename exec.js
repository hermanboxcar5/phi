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
            console.log(users)
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
    console.log(await adduser("helo6", "1234"))
}
main();

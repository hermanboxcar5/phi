const util = require('util');
const exec = util.promisify(require('child_process').exec);


async function main() {

    async function userslist (){
        let ret = await exec("/bin/bash -c \"eval getent passwd {$(/usr/bin/awk '/^UID_MIN/ {print $2}' /etc/login.defs)..$(/usr/bin/awk '/^UID_MAX/ {print $2}' /etc/login.defs)} | /usr/bin/cut -d: -f1\"");
        let users = ret.stdout.split("\n")
        if(users[users.length-1]==""){ users.pop() }
        return users
    }
    async function pwdchange(user, pwd){
        let ret = await exec(`sudo echo -e "${pwd}\n${pwd}" | sudo passwd ${user}`);
        if(ret.stderr){
            console.log("deluser error: ", ret.stderr)
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
}
main();

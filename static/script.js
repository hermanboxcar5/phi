const socket = io();

function loadusers() {
    socket.emit("loadusers1");
}
socket.on("loadusers2", json => {
    json = JSON.parse(json);
    console.log(json)

    let groupelem = document.getElementById("groupsdisplay")
    let groupspans = ""
    let groupall = json[0].allgroups
    groupall.map(a=>{
        groupspans += `<span class='group'><span class="groupname">${a}</span> <button class="buttonrev" onclick="delgroup('${a}')"><img src="/assets/close.png" class="closeimg"></img></button></span>`
    })
    groupelem.innerHTML=groupspans


    const display = document.getElementById("usersdisplay");

    display.innerHTML = ""; // Clear previous content

    const scrollContainer = document.createElement("div");
    scrollContainer.className = "scroll-container";

    const table = document.createElement("table");
    table.className = "user-table";

    json.forEach(obj => {
        let username = obj.user
        let uid = obj.UID
        let groups = obj.groups
        let primarygroup = obj.primary
        let allgroups = obj.allgroups
        let options = "<option>"+allgroups.join("</option><option>")+"</option>"
        let groupdis = ""
        groups.map(a=>{
            groupdis += `<span class='group'><span class="groupname">${a}</span> <button class="buttonrev" onclick="grouprev('${username}', '${a}')"><img src="/assets/close.png" class="closeimg"></img></button></span>`
        })
        const row = document.createElement("tr");

        row.innerHTML = `
            <td class="uid">${uid}</td>
            <td class="username">${username}</td>
            
            <td class="password-cell">
                <input type="text" id="pwd_${username}" class="password" placeholder="password">
                <button onclick="setpwd('${username}')" class="set-btn">Set</button>
            </td>
            <td class = "del-cel"><button onclick="delusr('${username}')" class="delete-btn">Delete</button></td>
            <td class = "groups-cel">
            <span class="primary">
                Primary: ${primarygroup} <br>
                <datalist id="suggestions_${username}">
                    ${options}
                </datalist>
                <input id="groupselect_${username}" autoComplete="on" list="suggestions_${username}"/> <button class="btnwarn" onclick="setprimary('${username}')">Set as primary</button> <button class="btnnormal" onclick="addgroup('${username}')">Add group</button>
            </span>
            <div class="secondary">${groupdis}</div>
            </td>
        `
        table.appendChild(row);
    });

    scrollContainer.appendChild(table);
    display.appendChild(scrollContainer);
});


function setpwd(user) {
    let pwd = document.getElementById(`pwd_${user}`).value
    //check if it is empty
    if(/\S/.test(pwd)){
        if(window.confirm("Confirm action: Password change")) {
            socket.emit("passwdchg1", JSON.stringify({user:user, password:pwd}))
        }
    } else {
        window.alert("Password change: Error invalid password")
    }
}
socket.on("passwdchg2", json =>{
    json = JSON.parse(json)
    if(json.success){
        window.alert("Password changed")
    } else {
        window.alert("passwordchange Error: ", json.err)
    }
})

function delusr(user) {
    if(window.confirm("Confirm action: delete user")) {
        socket.emit("deluser1", user)
    }
}
socket.on("deluser2", json=>{
    json = JSON.parse(json)
    if(json.success){
        window.alert("deleteuser User Deleted")
        loadusers()
    } else {
        window.alert("Error: ", json.err)
    }
})
function addusr(){
    let user = document.getElementById("addusername").value
    let pwd = document.getElementById("adduserpassword").value
    let name = document.getElementById("adduserfullname").value
    let room = document.getElementById("adduserroom").value
    let workphone = document.getElementById("adduserwork").value
    let homephone = document.getElementById("adduserhome").value
    let other = document.getElementById("adduserother").value
    console.log("JSON", JSON.stringify({user, pwd, name, room, workphone, homephone, other}))
    socket.emit("adduser1", JSON.stringify({user:user, pwd:pwd, name:name, room:room, workphone:workphone, homephone:homephone, other:other}))
    document.getElementById("addusername").value= ""
    document.getElementById("adduserpassword").value= ""
    document.getElementById("adduserfullname").value= ""
    document.getElementById("adduserroom").value= ""
    document.getElementById("adduserwork").value= ""
    document.getElementById("adduserhome").value= ""
    document.getElementById("adduserother").value= ""
}

socket.on("adduser2", json=>{
    json = JSON.parse(json)
    if(json.success){
        window.alert("User Added")
    } else {
        window.alert("adduser Error: ", json.err)
    }
    loadusers()
})

function addgroup(user){
    let value = document.getElementById(`groupselect_${user}`).value
    socket.emit("addgroup1", JSON.stringify({user:user, group:value}))
}
socket.on("addgroup2", json=>{
    json = JSON.parse(json)
    if(json.success){
        window.alert("Group Added")
    } else {
        window.alert("addgroup Error: ", json.err)
    }
    loadusers()
})

function grouprev(user, group) {
    socket.emit("revgroup1", JSON.stringify({user:user, group:group}))
}
socket.on("revgroup2", json=>{
    json = JSON.parse(json)
    if(json.success){
        window.alert("Group Removed")
    } else {
        window.alert("revgroup Error: "+ json.err)
    }
    loadusers()
})


function setprimary(user){
    let value = document.getElementById(`groupselect_${user}`).value
    socket.emit("setprimary1", JSON.stringify({user:user, group:value}))
}
socket.on("setprimary2", json=>{
    json = JSON.parse(json)
    if(json.success){
        window.alert("Primary set")
        
    } else {
        window.alert("setprimary Error: ", json.err)
    }
    loadusers()
})

function delgroup(group){
    let force = document.getElementById("force").checked
    socket.emit("delgroup1", JSON.stringify({group:group, force:force}))
}
socket.on("delgroup2", json=>{
    json = JSON.parse(json)
    if(json.success){
        window.alert("Group deleted")
        
    } else {
        window.alert("groupdel Error: " + json.err)
    }
    loadusers()
})
function updatePasswordPolicy() {
    const policy = {
        minlen: document.getElementById("minlen").value,
        ucredit: document.getElementById("ucredit").value,
        lcredit: document.getElementById("lcredit").value,
        dcredit: document.getElementById("dcredit").value,
        ocredit: document.getElementById("ocredit").value,
        maxrepeat: document.getElementById("maxrepeat").value,
        maxsequence: document.getElementById("maxsequence").value,
        remember: document.getElementById("remember").value,
        maxage: document.getElementById("maxage").value,
        lockout: document.getElementById("lockout").value
        
    };

    if (window.confirm("Confirm action: Update Password Policy?")) {
        socket.emit("updatePolicy1", JSON.stringify(policy));
    }
}

socket.on("updatePolicy2", json => {
    json = JSON.parse(json);
    if (json.success) {
        window.alert("Password policy updated successfully!");
    } else {
        window.alert("Error updating policy: " + json.err);
    }
});
function prefillCurrentPolicy() {
    socket.emit("getPolicy1"); // Request current values from the server
}

socket.on("getPolicy2", json => {
    json = JSON.parse(json);
    document.getElementById("minlen").value = json.minlen;
    document.getElementById("ucredit").value = json.ucredit;
    document.getElementById("lcredit").value = json.lcredit;
    document.getElementById("dcredit").value = json.dcredit;
    document.getElementById("ocredit").value = json.ocredit;
    document.getElementById("maxrepeat").value = json.maxrepeat;
    document.getElementById("maxsequence").value = json.maxsequence;
    document.getElementById("remember").value = json.remember;
    document.getElementById("maxage").value = json.maxage;
    document.getElementById("lockout").value = json.lockout;
    window.alert("Prefilled current policy values.");
});








window.onload=loadusers


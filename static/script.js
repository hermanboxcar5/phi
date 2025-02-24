const socket = io();

function loadusers() {
    socket.emit("loadusers1");
}
socket.on("loadusers2", json => {
    json = JSON.parse(json);
    const display = document.getElementById("usersdisplay");

    display.innerHTML = ""; // Clear previous content

    const scrollContainer = document.createElement("div");
    scrollContainer.className = "scroll-container";

    const table = document.createElement("table");
    table.className = "user-table";

    json.forEach(obj => {
        let username = obj.user
        let uid = obj.UID
        const row = document.createElement("tr");

        row.innerHTML = `
            <td class="username">${username}</td>
            <td class="username">${uid}</td>
            <td class="password-cell">
                <input type="text" id="pwd_${username}" class="password" placeholder="Enter password">
                <button onclick="setpwd('${username}')" class="set-btn">Set</button>
            </td>
            <td><button onclick="delusr('${username}')" class="delete-btn">Delete</button></td>
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
        loadusers()
    } else {
        window.alert("adduser Error: ", json.err)
    }
})

window.onload=loadusers
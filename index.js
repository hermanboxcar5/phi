// const { exec } = require('child_process');
// var yourscript = exec('echo hello',
//         (error, stdout, stderr) => {
//             console.log("stdout: ", stdout);
//             console.log("stderr: ", stderr);
//             if (error !== null) {
//                 console.log(`exec error: ${error}`);
//             }
//         });


const http = require("http")
const express = require("express")
let app = express()
let ser = http.createServer(app)
const io = require("socket.io")(ser)

app.get("/", (req, res)=>{
    res.send("Hello sss")
})


io.on("Connection", (socket)=>{
    
})

ser.listen(1234)

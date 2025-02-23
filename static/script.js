const socket = io();

function emitthis() {

        
    console.log(socket.emit('chat message', "hell==="))
    
}
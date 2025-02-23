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

    json.forEach(username => {
        const row = document.createElement("tr");

        row.innerHTML = `
            <td class="username">${username}</td>
            <td class="password-cell">
                <input type="text" class="password" placeholder="Enter password">
                <button class="set-btn">Set</button>
            </td>
            <td><button class="delete-btn">Delete</button></td>
        `;

        // Set Password event
        row.querySelector(".set-btn").onclick = () => {
            const password = row.querySelector(".password").value;
            alert(`Password set for ${username}: ${password}`);
        };

        // Delete User event
        row.querySelector(".delete-btn").onclick = () => {
            row.remove();
            alert(`Deleted user: ${username}`);
        };

        table.appendChild(row);
    });

    scrollContainer.appendChild(table);
    display.appendChild(scrollContainer);
});

const express = require("express");

const app = express();

const PORT = process.env.PORT || 3000;

app.get("/", (req, res) => {
  res.send(`
        <h1>Node.js Application Running Successfully!</h1>
        <h2>Running inside Docker Container</h2>
        <p>Hosted on Azure</p>
    `);
});

app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});

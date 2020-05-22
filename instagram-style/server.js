const express = require("express");
const path = require("path");
const app = express();

app.get("/", function (req, res) {
  res.status(200).sendFile(path.join(__dirname + "/client/index.html"));
});

const port = process.env.port || 8080;

app.listen(port, () => {
  console.log("App running at port: " + port);
});

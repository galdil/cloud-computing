const express = require("express");
const AWS = require("aws-sdk");
const path = require("path");
const app = express();
const config = require("./config.js");

app.use(express.static(path.join(__dirname, "client")));

app.get("/", (req, res) => {
  res.status(200).sendFile("index.html");
});

const port = process.env.port || 8080;

app.listen(port, () => {
  console.log("App running at port: " + port);
});

const awsConfig = new AWS.Config({
  accessKeyId: config.accessKeyId,
  secretAccessKey: config.secretAccessKey,
  region: config.region,
});

const express = require("express");
const AWS = require("aws-sdk");
const path = require("path");
const app = express();
const config = require("./config.js");

app.use(express.static(path.join(__dirname, "client")));

const awsConfig = new AWS.Config({
  accessKeyId: config.accessKeyId,
  secretAccessKey: config.secretAccessKey,
  region: config.region,
});

const s3 = new AWS.S3();

const bucketParams = {
  Bucket: "insta-style-bucket",
};

app.get("/", (req, res) => {
  res.status(200).sendFile("index.html");
});

app.get("/photos", async (req, res) => {
  let urls = [];
  const photos = await s3.listObjectsV2(bucketParams).promise();
  await Promise.all(
    photos.Contents.map(async (photo) => {
      const url = await s3.getSignedUrl("getObject", {
        Key: photo.Key,
        Expires: 60 * 5,
        ...bucketParams,
      });
      urls.push(url);
    })
  );
  console.log(urls);
  res.send(urls);
});

app.post("/photo", async (req, res) => {
  s3.upload(bucketParams, () => {});
  res.status(200).sendFile("index.html");
});

const port = process.env.port || 8080;

app.listen(port, () => {
  console.log("App running at port: " + port);
});

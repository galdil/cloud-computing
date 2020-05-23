const express = require("express");
const AWS = require("aws-sdk");
const path = require("path");
const app = express();
const config = require("./config.js");
const bodyParser = require("body-parser");
const fileUpload = require("express-fileupload");

app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: true }));
app.use(express.static(path.join(__dirname, "client")));
app.use(fileUpload());

const s3 = new AWS.S3();

AWS.config.update({
  accessKeyId: config.accessKeyId,
  secretAccessKey: config.secretAccessKey,
  region: config.region,
});

const bucketParams = {
  Bucket: "insta-style-bucket",
};

app.get("/", (req, res) => {
  res.status(200).sendFile("index.html");
});

// get all the photos in the bucket
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

  res.send(urls);
});

// the upload route to upload file to s3
app.post("/photo", async (req, res) => {
  try {
    let image = req.files.imageFile;

    let response = await s3
      .upload({ ...bucketParams, Key: image.name, Body: image.data })
      .promise();

    console.log(response.key);
    await res.send({ success: response.key });
  } catch (e) {
    console.log(e);
    res.send({ error: e });
  }
});

const port = process.env.port || 8080;

app.listen(port, () => {
  console.log("App running at port: " + port);
});

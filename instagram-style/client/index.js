const localhostUrl = "http://localhost:8000/";

const fetchPhotos = (async () => {
  const response = await fetch(`${localhostUrl}photos`);
  const photos = await response.json();
  const gallery = document.getElementById("gallery");

  photos.map((photo) => {
    const img = document.createElement("img");
    img.src = photo;
    img.className = "gallery-item";

    const imageContainer = document.createElement("div");

    imageContainer.appendChild(img);
    gallery.appendChild(imageContainer);
  });
})();

const uploadPhoto = async () => {
  const message = document.getElementById("upload-message");
  message.innerHTML = "loading...";

  let formData = new FormData();
  const imageFile = document.getElementById("image-input").files[0];
  formData.append("imageFile", imageFile);

  const response = await fetch(`${localhostUrl}photo`, {
    method: "POST",
    body: formData,
  });

  let res = await response.json();
  message.innerHTML = res.success ? `${res.success} uploaded!` : res.error;
};

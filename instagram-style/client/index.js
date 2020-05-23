const fetchPhotos = (async () => {
  const response = await fetch("http://localhost:8080/photos");
  let photos = await response.json();
  const gallery = document.getElementById("gallery");

  photos.map((photo) => {
    let img = document.createElement("img");
    img.src = photo;
    img.className = "gallery-item";

    let imageContainer = document.createElement("div");

    imageContainer.appendChild(img);
    gallery.appendChild(imageContainer);
  });
})();

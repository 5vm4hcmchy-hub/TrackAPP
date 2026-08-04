let watchId = null;
let fixCount = 0;

function handleStart() {
  if (watchId === null) {
    startButton.textContent = "Stop";

    watchId = navigator.geolocation.watchPosition(onSuccess, onError, {
      enableHighAccuracy: true,
      maximumAge: 0,
      timeout: 10000,
    });
    console.log("watchId:", watchId);
  } else {
    startButton.textContent = "Start";
    navigator.geolocation.clearWatch(watchId);
    watchId = null;
    console.log("watchId:", watchId);
  }
}

function onSuccess(position) {
  if (position.coords.speed === null) {
    document.getElementById("speedDisplay").textContent = "--";
  } else {
    document.getElementById("speedDisplay").textContent = Math.round(
      position.coords.speed * 3.6,
    );
  }
  document.getElementById("accuracyDisplay").textContent = Math.round(
    position.coords.accuracy,
  );

  fixCount = fixCount + 1;
  document.getElementById("fixDisplay").textContent = fixCount;
  document.getElementById("lastUpdateDisplay").textContent =
    new Date().toLocaleTimeString();
}

function onError(error) {
  console.log("GPS error, code: ", error.code);
  document.getElementById("errorDisplay").textContent = error.code;
}

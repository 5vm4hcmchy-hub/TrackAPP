let SQL = null;
let db = null;
let idb = null;
const IDB_NAME = "trackapp";
const IDB_STORE = "files";

async function initDatabase() {
  SQL = await initSqlJs({
    locateFile: function (file) {
      return "libs/" + file;
    },
  });

  await openIndexedDB();

  const savedBytes = await loadDatabase();

  if (savedBytes === undefined) {
    // RAMA 1: no había nada guardado
    console.log("new db");
    db = new SQL.Database();
    const schemaText = await loadSchema();
    db.run(schemaText);
  } else {
    // RAMA 2: sí había datos guardados
    console.log("db loaded");
    db = new SQL.Database(savedBytes);
  }
}

async function loadSchema() {
  const response = await fetch("db/schema.sql");
  const sqlText = await response.text();
  return sqlText;
}

function openIndexedDB() {
  return new Promise(function (resolve, reject) {
    const request = indexedDB.open(IDB_NAME, 1);

    request.onupgradeneeded = function (event) {
      const database = event.target.result;
      database.createObjectStore(IDB_STORE);
    };

    request.onsuccess = function (event) {
      idb = event.target.result;
      resolve(idb);
    };

    request.onerror = function (event) {
      reject(event.target.error);
    };
  });
}

function saveDatabase() {
  return new Promise(function (resolve, reject) {
    const data = db.export();

    const tx = idb.transaction(IDB_STORE, "readwrite");
    const store = tx.objectStore(IDB_STORE);
    store.put(data, "main");

    tx.oncomplete = function () {
      console.log("saved,", data.length, "bytes");
      resolve();
    };

    tx.onerror = function () {
      reject(tx.error);
    };
  });
}

function loadDatabase() {
  return new Promise(function (resolve, reject) {
    const tx = idb.transaction(IDB_STORE, "readonly");
    const store = tx.objectStore(IDB_STORE);
    const request = store.get("main");

    request.onsuccess = function () {
      resolve(request.result);
    };

    request.onerror = function () {
      reject(request.error);
    };
  });
}

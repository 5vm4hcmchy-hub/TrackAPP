let SQL = null;
let db = null;

async function initDatabase() {
  SQL = await initSqlJs({
    locateFile: function (file) {
      return "libs/" + file;
    },
  });
  db = new SQL.Database();

  const schemaText = await loadSchema();

  db.run(schemaText);
}

async function loadSchema() {
  const response = await fetch("db/schema.sql");
  const sqlText = await response.text();
  return sqlText;
}

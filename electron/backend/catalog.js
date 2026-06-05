const appCatalog = require("./app-catalog.json");

function getApps() {
  return appCatalog;
}

function getAllowedPackageIds() {
  return new Set(appCatalog.map((item) => item.id));
}

module.exports = {
  getApps,
  getAllowedPackageIds
};

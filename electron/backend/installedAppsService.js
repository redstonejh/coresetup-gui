const { execFile } = require("child_process");

function checkInstalled(id) {
  return new Promise((resolve) => {
    execFile(
      "winget",
      ["list", "--id", id, "--exact", "--disable-interactivity"],
      { windowsHide: true, timeout: 15000 },
      (error, stdout) => {
        resolve(!error && stdout.includes(id));
      }
    );
  });
}

async function getInstalledAppIds(apps) {
  const results = await Promise.all(
    apps.map(async ({ id }) => ({
      id,
      installed: await checkInstalled(id)
    }))
  );

  return results.filter(({ installed }) => installed).map(({ id }) => id);
}

module.exports = {
  checkInstalled,
  getInstalledAppIds
};

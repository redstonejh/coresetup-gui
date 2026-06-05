const { execFile } = require("child_process");
const { checkInstalled } = require("./installedAppsService");

function checkUpdateAvailable(id) {
  return new Promise((resolve) => {
    execFile(
      "winget",
      ["upgrade", "--id", id, "--exact", "--source", "winget", "--accept-source-agreements", "--disable-interactivity"],
      { windowsHide: true, timeout: 20000 },
      (_error, stdout) => {
        const noUpdate = /No applicable update found|No available upgrade|No installed package found/i.test(stdout);
        resolve(stdout.includes(id) && !noUpdate);
      }
    );
  });
}

async function getAvailableUpdateIds(apps) {
  const results = await Promise.all(
    apps.map(async ({ id }) => {
      const installed = await checkInstalled(id);
      return {
        id,
        updateAvailable: installed && await checkUpdateAvailable(id)
      };
    })
  );

  return results.filter(({ updateAvailable }) => updateAvailable).map(({ id }) => id);
}

module.exports = {
  checkUpdateAvailable,
  getAvailableUpdateIds
};

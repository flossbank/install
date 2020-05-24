const github = require('gh-got')

async function getLatestReleaseFor (target) {
  const { body } = await github('repos/flossbank/cli/releases/latest')
  const { tag_name: version, assets } = body
  const asset = assets.find(({ name }) => name.includes(target))
  const { browser_download_url: url } = asset

  return { url, version }
}

module.exports = async (req, res) => {
  // const { os, arch } = req.query
  const target = 'macos-x86_64'
  const { url, version } = await getLatestReleaseFor(target)
  res.status(200).send(`${url}\n${version}`)
}

const github = require('gh-got')

const targets = ['macos-x86_64', 'linux-x86_64', 'win-x86_64']

async function getLatestReleaseFor (target) {
  const { body } = await github('repos/flossbank/cli/releases/latest')
  const { tag_name: version, assets } = body
  const asset = assets.find(({ name }) => name.includes(target))
  const { browser_download_url: url } = asset

  return { url, version }
}

function getTargetlessText () {
  const urls = targets.map(target => `<a href="?target=${target}">${target}</a>`).join(', ')
  return `<html><head></head><body><p>target query param required: ${urls}<p></body></html>`
}

module.exports = async (req, res) => {
  const { target } = req.query
  if (!target) {
    res.setHeader('Content-Type', 'text/html')
    return res.status(200).send(getTargetlessText())
  }
  res.setHeader('Content-Type', 'text/plain')
  try {
    const { url, version } = await getLatestReleaseFor(target)
    res.status(200).send(`${url}\n${version}`)
  } catch (e) {
    res.status(500).send()
  }
}

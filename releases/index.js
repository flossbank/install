const github = require('gh-got')

const targets = ['macos-x86_64', 'linux-x86_64', 'win-x86_64']

async function getLatestReleaseFor (target) {
  const { body } = await github('repos/flossbank/cli/releases/latest')
  const { tag_name: version, assets } = body
  const asset = assets.find(({ name }) => name.includes(target))
  const { browser_download_url: url } = asset

  return { url, version }
}

module.exports = async (req, res) => {
  const { target: _target } = req.query
  const target = (_target || '').toLowerCase()
  if (!target || !targets.includes(target)) {
    return res.status(404).send()
  }
  res.setHeader('Content-Type', 'text/plain')
  try {
    const { url, version } = await getLatestReleaseFor(target)

    // https://vercel.com/docs/v2/edge-network/headers#cache-control-header
    // to avoid calling GitHub too many times, we're instructing Vercel to
    // cache the 200 response of this route for 1 day
    res.setHeader('s-maxage', 24 * 60 * 60)
    res.status(200).send(`${url}\n${version}`)
  } catch (e) {
    res.status(500).send()
  }
}

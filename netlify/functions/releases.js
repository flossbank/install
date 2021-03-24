const github = require('gh-got')

const targets = ['macos-x86_64', 'linux-x86_64', 'win-x86_64']

async function getLatestReleaseFor (target) {
  const { body } = await github('repos/flossbank/cli/releases/latest')
  const { tag_name: version, assets } = body
  const asset = assets.find(({ name }) => name.includes(target))
  const { browser_download_url: url } = asset

  return { url, version }
}

exports.handler = async (event) => {
  const { path } = event

  const _target = path.substring(path.lastIndexOf('/') + 1)
  const target = (_target || '').toLowerCase()

  if (!target || !targets.includes(target)) {
    return {
      statusCode: 404
    }
  }
  try {
    const { url, version } = await getLatestReleaseFor(target)

    // to avoid calling GitHub too many times, we're instructing the caching layer to
    // cache the 200 response of this route for 1 day
    return {
      statusCode: 200,
      body: `${url}\n${version}`,
      headers: {
        'content-type': 'text/plain',
        'cache-control': 's-maxage=86400'
      }
    }
  } catch (e) {
    console.error(e)
    return {
      statusCode: 500,
      headers: {
        'content-type': 'text/plain'
      }
    }
  }
}

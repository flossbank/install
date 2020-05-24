module.exports = (_, res) => {
  res.setHeader('Location', '/api/releases/latest')
  res.status(302).send()
}

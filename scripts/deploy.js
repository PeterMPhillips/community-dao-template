/* global web3 artifacts */

const deployTemplate = require('@aragon/templates-shared/scripts/deploy-template')
const TEMPLATE_NAME = 'community-template'
const CONTRACT_NAME = 'CommunityTemplate'

const apps = [
  { name: 'finance', contractName: 'Finance'},
  { name: 'vault', contractName: 'Vault'},
  { name: 'voting', contractName: 'Voting'},
  { name: 'dot-voting', contractName: 'DotVoting'},
  { name: 'token-wrapper', contractName: 'TokenWrapper' }
]

module.exports = callback => {
  deployTemplate(web3, artifacts, TEMPLATE_NAME, CONTRACT_NAME, apps)
    .then(() => {
      callback()
    })
    .catch(callback)
}

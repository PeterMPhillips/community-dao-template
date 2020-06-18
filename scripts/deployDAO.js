/* global web3 artifacts */
const DAO_NAME = 'test'
const COMMUNITY_TEMPLATE = '0x8a045ed49a7079eb3cf9980bb60226e0b8491e3e'
const TOKEN_NAME = 'Token'
const TOKEN_SYMBOL = 'TKN'
const TOKEN_DECIMALS = 18
const TOKEN_SUPPLY = 100e18
const VOTE_DURATION = 120
const VOTE_SUPPORT = 50e16
const PARTICPANT_SUPPORT = 5e16
const QUORUM = 20e16

module.exports = async () => {
  const accounts = web3.eth.accounts
  const StandardToken = artifacts.require('StandardToken')
  const CommunityTemplate = artifacts.require('CommunityTemplate')
  const Kernel = artifacts.require('Kernel')

  const { getEventArgument } = require('@aragon/test-helpers/events')

  const token = await StandardToken.new(TOKEN_NAME, TOKEN_SYMBOL, TOKEN_DECIMALS, TOKEN_SUPPLY)
  console.log('ERC20: ', token.address)
  const template = CommunityTemplate.at(COMMUNITY_TEMPLATE)
  console.log('Template: ', template.address)

  const daoTx = await template.newInstance(
    DAO_NAME,
    accounts[0],
    token.address,
    `w${TOKEN_NAME}`,
    `w${TOKEN_SYMBOL}`,
    [VOTE_SUPPORT, QUORUM, VOTE_DURATION],
    [QUORUM, PARTICPANT_SUPPORT, VOTE_DURATION]
  )
  const dao = Kernel.at(getEventArgument(daoTx, 'DeployDao', 'dao'))
  console.log('DAO: ', dao.address)
}

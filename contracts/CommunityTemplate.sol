pragma solidity 0.4.24;

import "@aragon/templates-shared/contracts/BaseTemplate.sol";
import "@aragonone/apps-token-wrapper/contracts/TokenWrapper.sol";
import "@aragon/os/contracts/lib/token/ERC20.sol";
import "./dot-voting/DotVoting.sol";

contract CommunityTemplate is BaseTemplate{
  /* Hardcoded constant to save gas
  * bytes32 constant internal DOT_VOTING_APP_ID = apmNamehash("dot-voting");
  * bytes32 constant internal TOKEN_WRAPPER_APP_ID = apmNamehash("token-wrapper.hatch.aragonpm.eth");
  */

  bytes32 constant internal DOT_VOTING_APP_ID = 0x6bf2b7dbfbb51844d0d6fdc211b014638011261157487ccfef5c2e4fb26b1d7e;
  bytes32 constant internal TOKEN_WRAPPER_APP_ID = 0xdab7adb04b01d9a3f85331236b5ce8f5fdc5eecb1eebefb6129bc7ace10de7bd;

  uint64 constant private DEFAULT_FINANCE_PERIOD = uint64(30 days);

  constructor(DAOFactory _daoFactory, ENS _ens, MiniMeTokenFactory _miniMeFactory, IFIFSResolvingRegistrar _aragonID)
    BaseTemplate(_daoFactory, _ens, _miniMeFactory, _aragonID)
    public
  {
    _ensureAragonIdIsValid(_aragonID);
    _ensureMiniMeFactoryIsValid(_miniMeFactory);
  }

  /**
    * @dev Deploy a Community DAO that uses a wrapped ERC-20 for vote signalling
    * @param _id String with the name for org, will assign `[id].aragonid.eth`
    * @param _tokenToWrap The address of the ERC-20 token that will be wrapped
    * @param _wrappedTokenName The name of the wrapped token
    * @param _wrappedTokenSymbol The symbol of the wrapped token
    * @param _votingSettings Array of [supportRequired, minAcceptanceQuorum, voteDuration] to set up the voting app of the organization
    */
    function newInstance(
      string memory _id,
      address _admin,
      ERC20 _tokenToWrap,
      string memory _wrappedTokenName,
      string memory _wrappedTokenSymbol,
      uint64 _financePeriod,
      uint64[3] memory _votingSettings,
      uint64[3] memory _dotVotingSettings
    )
        public
    {
      _validateId(_id);

      (Kernel dao, ACL acl) = _createDAO();
      _setupApps(dao, acl, _tokenToWrap, _admin, _wrappedTokenName, _wrappedTokenSymbol, _financePeriod, _votingSettings, _dotVotingSettings);
      _transferRootPermissionsFromTemplateAndFinalizeDAO(dao, _admin);
      _registerID(_id, dao);
    }

    function _setupApps(
        Kernel _dao,
        ACL _acl,
        ERC20 _tokenToWrap,
        address _admin,
        string memory _wrappedTokenName,
        string memory _wrappedTokenSymbol,
        uint64 _financePeriod,
        uint64[3] memory _votingSettings,
        uint64[3] memory _dotVotingSettings
    )
        internal
    {
        Vault vault = _installVaultApp(_dao);
        Finance finance = _installFinanceApp(_dao, vault, _financePeriod == 0 ? DEFAULT_FINANCE_PERIOD : _financePeriod);
        TokenWrapper tokenWrapper = _installTokenWrapperApp(_dao, _tokenToWrap, _wrappedTokenName, _wrappedTokenSymbol);
        Voting voting = _installVotingApp(_dao, tokenWrapper, _votingSettings);
        DotVoting dotVoting = _installDotVotingApp(_dao, tokenWrapper, _dotVotingSettings);

        _setupPermissions(_admin, _acl, vault, finance, voting, dotVoting, tokenWrapper);
    }

    function _setupPermissions(
        address _admin,
        ACL _acl,
        Vault _vault,
        Finance _finance,
        Voting _voting,
        DotVoting _dotVoting,
        TokenWrapper _tokenWrapper
    )
        internal
    {
        _createVaultPermissions(_acl, _vault, _finance, _admin);
        _createFinancePermissions(_acl, _finance, _voting, _admin);
        _createFinanceCreatePaymentsPermission(_acl, _finance, _voting, _admin);
        _createEvmScriptsRegistryPermissions(_acl, _voting, _admin);
        _createTokenWrapperPermissions(_acl, _tokenWrapper, _admin);
        _createVotingPermissions(_acl, _voting, _admin, _admin, _admin);
        _createDotVotingPermissions(_acl, _dotVoting, _admin, _admin);
    }

    /* VOTING */

    function _installVotingApp(Kernel _dao, TokenWrapper _token, uint64[3] memory _votingSettings) internal returns (Voting) {
        return _installVotingApp(_dao, _token, _votingSettings[0], _votingSettings[1], _votingSettings[2]);
    }

    function _installVotingApp(
        Kernel _dao,
        TokenWrapper _token,
        uint64 _support,
        uint64 _acceptance,
        uint64 _duration
    )
        internal returns (Voting)
    {
        bytes memory initializeData = abi.encodeWithSelector(Voting(0).initialize.selector, _token, _support, _acceptance, _duration);
        return Voting(_installNonDefaultApp(_dao, VOTING_APP_ID, initializeData));
    }

    /* DOT-VOTING */

    function _installDotVotingApp(Kernel _dao, TokenWrapper _token, uint64[3] memory _dotVotingSettings) internal returns (DotVoting) {
        return _installDotVotingApp(_dao, _token, _dotVotingSettings[0], _dotVotingSettings[1], _dotVotingSettings[2]);
    }

    function _installDotVotingApp(
        Kernel _dao,
        TokenWrapper _token,
        uint64 _quorum,
        uint64 _support,
        uint64 _duration
    )
        internal returns (DotVoting)
    {
        bytes memory initializeData = abi.encodeWithSelector(DotVoting(0).initialize.selector, _token, _quorum, _support, _duration);
        return DotVoting(_installNonDefaultApp(_dao, DOT_VOTING_APP_ID, initializeData));
    }

    function _createDotVotingPermissions(
        ACL _acl,
        DotVoting _dotVoting,
        address _grantee,
        address _manager
    )
        internal
    {
        _acl.createPermission(_grantee, _dotVoting, _dotVoting.ROLE_CREATE_VOTES(), _manager);
        _acl.createPermission(_manager, _dotVoting, _dotVoting.ROLE_ADD_CANDIDATES(), _manager);
    }

    /* TOKEN WRAPPER */

    function _installTokenWrapperApp(
        Kernel _dao,
        ERC20 _tokenToWrap,
        string memory _wrappedTokenName,
        string memory _wrappedTokenSymbol
    )
        internal returns (TokenWrapper)
    {
        bytes memory initializeData = abi.encodeWithSelector(TokenWrapper(0).initialize.selector, _tokenToWrap, _wrappedTokenName, _wrappedTokenSymbol);
        return TokenWrapper(_installNonDefaultApp(_dao, TOKEN_WRAPPER_APP_ID, initializeData));
    }

    function _createTokenWrapperPermissions(
        ACL _acl,
        TokenWrapper _tokenWrapper,
        address _manager
    )
        internal
    {
        _acl.createPermission(address(-1), _tokenWrapper, bytes32(-1), _manager);
    }


}

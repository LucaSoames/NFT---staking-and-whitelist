// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
}

interface INFT {
    function mint(address to, uint256 tokenId) external returns (bool);
    function burn(uint256 tokenId) external returns (bool);
}

contract MyNFT is INFT {
    mapping(uint256 => address) public owners;
    mapping(address => mapping(uint256 => bool)) public approvals;
    mapping(address => bool) public whitelist;

    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;

    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public stakingReward;

    IERC20 public token;

    constructor(string memory _name, string memory _symbol, uint8 _decimals, address _token) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        token = IERC20(_token);
    }

    function mint(address to, uint256 tokenId) external override returns (bool) {
        require(whitelist[msg.sender], "Only whitelisted accounts can mint NFTs");
        require(token.balanceOf(msg.sender) >= stakingReward, "Not enough tokens staked to mint NFT");
        require(owners[tokenId] == address(0), "Token already minted");
        owners[tokenId] = to;
        _balances[to]++;
        _totalSupply++;
        return true;
    }

    function burn(uint256 tokenId) external override returns (bool) {
        require(owners[tokenId] == msg.sender, "Not the owner of the token");
        delete owners[tokenId];
        _balances[msg.sender]--;
        _totalSupply--;
        return true;
    }

    function balanceOf(address account) external view returns (uint256) {
        return _balances[account];
    }

    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    function stake(uint256 amount) external {
        require(amount > 0, "Cannot stake zero tokens");
        require(!whitelist[msg.sender], "Already whitelisted");
        token.transferFrom(msg.sender, address(this), amount);
        whitelist[msg.sender] = true;
    }

    function unstake() external {
        require(whitelist[msg.sender], "Not whitelisted");
        whitelist[msg.sender] = false;
        token.transfer(msg.sender, stakingReward);
    }

    function approve(address to, uint256 tokenId) external {
        require(owners[tokenId] == msg.sender, "Not the owner of the token");
        approvals[msg.sender][tokenId] = true;
        emit Approval(msg.sender, to, tokenId);
    }

    function getApproved(uint256 tokenId) external view returns (address) {
        return approvals[owners[tokenId]][tokenId] ? owners[tokenId] : address(0);
    }

    function transferFrom(address from, address to, uint256 tokenId) external {
        require(approvals[from][tokenId], "Not approved");
        require(owners[tokenId] == from, "Not the owner of the token");
        delete approvals[from][tokenId];
        owners[tokenId] = to;
        _balances[from]--;
        _balances[to]++;
        emit Transfer(from, to, tokenId);
    }

    event Approval(address indexed owner, address indexed operator, uint256 indexed tokenId);
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
}

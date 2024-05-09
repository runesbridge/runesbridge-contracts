// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {PausableUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import {EIP712Upgradeable} from "@openzeppelin/contracts-upgradeable/utils/cryptography/EIP712Upgradeable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract RunesRouter is
    OwnableUpgradeable,
    PausableUpgradeable,
    EIP712Upgradeable,
    ReentrancyGuardUpgradeable
{
    event Deposit(
        address indexed token,
        address indexed from,
        string to,
        uint256 amount,
        uint256 chainId
    );
    event Withdraw(
        address indexed token,
        string from,
        address indexed to,
        uint256 amount,
        string txHash,
        uint256 chainId
    );
    event TokenCreated(
        address indexed token,
        string name,
        string symbol,
        address owner
    );

    bytes32 public constant TYPEHASH =
        keccak256(
            "Bridge(address token,string from,address to,uint256 amount,string txHash,uint256 chainId)"
        );

    mapping(address => uint256) public indexes;
    mapping(address => bool) public isValidator;
    mapping(string => bool) public txProcessed;
    mapping(address => bool) public acceptedTokens;
    address[] private _validators;

    modifier notProcessed(string memory txhash) {
        require(!txProcessed[txhash], "tx already processed");
        _;
    }

    function initialize(
        address _validator1,
        address _validator2,
        address _validator3
    ) public initializer {
        _addValidator(_validator1);
        _addValidator(_validator2);
        _addValidator(_validator3);
        __Ownable_init(_msgSender());
        __EIP712_init("RunesRouter", "1");
    }

    function addToken(address token) external onlyOwner {
        acceptedTokens[token] = true;
    }

    function removeToken(address token) external onlyOwner {
        acceptedTokens[token] = false;
    }

    function addValidator(address _address) public onlyOwner {
        _addValidator(_address);
    }

    function _addValidator(address _address) internal {
        require(!isValidator[_address], "already exist");
        indexes[_address] = _validators.length;
        isValidator[_address] = true;
        _validators.push(_address);
    }

    function removeValidator(address _address) external onlyOwner {
        require(isValidator[_address], "address not exist");
        require(indexes[_address] < _validators.length, "index out of range");
        require(_validators.length > 1, "cannot remove all validators");

        uint256 index = indexes[_address];
        uint256 lastIndex = _validators.length - 1;

        if (index != lastIndex) {
            address lastAddr = _validators[lastIndex];
            _validators[index] = lastAddr;
            indexes[lastAddr] = index;
        }

        delete isValidator[_address];
        delete indexes[_address];
        _validators.pop();
    }

    function deposit(
        address token,
        string memory to,
        uint256 amount,
        uint256 chainId
    ) external whenNotPaused {
        require(acceptedTokens[token], "token not accepted");
        uint256 balance = IERC20(token).balanceOf(_msgSender());
        IERC20(token).transferFrom(_msgSender(), address(this), amount);
        uint256 newBalance = IERC20(token).balanceOf(_msgSender());
        amount = balance - newBalance;

        emit Deposit(token, _msgSender(), to, amount, chainId);
    }

    function withdraw(
        address token,
        string memory from,
        uint256 amount,
        string memory txhash,
        uint256 chainId,
        bytes[] calldata signatures
    ) external whenNotPaused nonReentrant notProcessed(txhash) {
        require(
            signatures.length == _validators.length,
            "invalid length of signatures"
        );
        require(_validators.length > 0, "no validators");
        require(block.chainId == chainId, "invalid chainId");

        for (uint i = 0; i < _validators.length; i++) {
            require(
                _verify(
                    token,
                    from,
                    _msgSender(),
                    amount,
                    txhash,
                    signatures[i],
                    chainId,
                    _validators[i]
                ),
                "invalid signature"
            );
        }
        txProcessed[txhash] = true;
        IERC20(token).transfer(_msgSender(), amount);

        emit Withdraw(token, from, _msgSender(), amount, txhash, chainId);
    }

    function _verify(
        address token,
        string memory from,
        address to,
        uint256 amount,
        string memory _txHash,
        bytes memory _signature,
        uint256 _chainId,
        address _signer
    ) public view returns (bool) {
        bytes32 digest = _getDigest(token, from, to, amount, _txHash, _chainId);
        (bytes32 r, bytes32 s, uint8 v) = _splitSignature(_signature);
        address signer = ecrecover(digest, v, r, s);
        return signer == _signer;
    }

    function _splitSignature(
        bytes memory signature
    ) internal pure returns (bytes32 r, bytes32 s, uint8 v) {
        require(signature.length == 65, "invalid signature length");
        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }
    }

    function _getDigest(
        address _token,
        string memory _from,
        address _to,
        uint256 _amount,
        string memory _txHash,
        uint256 _chainId
    ) internal view returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    _domainSeparatorV4(),
                    keccak256(
                        abi.encode(
                            TYPEHASH,
                            _token,
                            keccak256(bytes(_from)),
                            _to,
                            _amount,
                            keccak256(bytes(_txHash)),
                            _chainId
                        )
                    )
                )
            );
    }
}

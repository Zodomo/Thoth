// SPDX-License-Identifier: NONE
pragma solidity >=0.8.0 <0.9.0;

// import "@openzeppelin/contracts/access/Ownable.sol"; 
// https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol

contract TwoPartyContract {
  address payable owner;

  /*struct TwoPartyContract {
      address party1;
      address party2;
      string ipfsHash;
      string signature;
  }*/

  /* Reimplementation of TwoPartyContract
     "multidimensional" mapping allows for one party to sign different contracts (even each contract multiple times but only once per block) with different people
     Originator/Initiator => Counterparty => IPFS Hash => Block Number Contract Proposed In => Signature */
  mapping(address => 
    mapping(address => 
    mapping(string => 
    mapping(uint256 => bytes32)))) public twoPartyContracts;

  // what should we do on deploy?
  constructor() {
    owner = payable(msg.sender);
  }

  // Require msg.sender to be owner of contract to call modified function
  modifier onlyOwner() {
    require(msg.sender == owner, "Not contract owner");
    _;
  }

  // Require msg.sender to be one of the parties to the contract
  modifier validParty(address _counterParty, string memory _ipfsHash, uint256 _blockNum) {
    require(bytes32(twoPartyContracts[msg.sender][_counterParty][_ipfsHash][block.number]).length > 0, "No contract created");
    _;
  }

  // Hash of: msg.sender + Counterparty + IPFS Hash + Block Number Contract Proposed In
  function getMessageHash(address _signer, address _counterParty, string memory _ipfsHash, uint256 _blockNum) public pure returns (bytes32) {
    return keccak256(abi.encodePacked(_signer, _counterParty, _ipfsHash, _blockNum));
  }

  // Signature is produced by signing a keccak256 hash with the following format:
  // "\x19Ethereum Signed Message\n" + len(msg) + msg
  function getEthSignedMessageHash(bytes32 _messageHash) public pure returns (bytes32) {
    return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", _messageHash));
  }

  // Sign all relevant contract data and return signature
  // Use of validParty requires contract to be created before being signable
  function signContract(address _counterParty, string memory _ipfsHash, uint256 _blockNum) public validParty(_counterParty, _ipfsHash, _blockNum) returns (bytes32) {
    twoPartyContracts[msg.sender][_counterParty][_ipfsHash][_blockNum] = getEthSignedMessageHash(getMessageHash(msg.sender, _counterParty, _ipfsHash, _blockNum));
    return twoPartyContracts[msg.sender][_counterParty][_ipfsHash][_blockNum];
  }

  function splitSignature(bytes memory _signature) public pure returns (bytes32 r, bytes32 s, uint8 v) {
    require(_signature.length == 65, "Invalid signture length");
    assembly {
      // mload(p) loads next 32 bytes starting at memory address p into memory
      // First 32 bytes of signature stores the length of the signature and can be ignored
      r := mload(add(_signature, 32)) // r stores first 32 bytes after the length prefix (0-31)
      s := mload(add(_signature, 64)) // s stores the next 32 bytes after r
      v := byte(0, mload(add(_signature, 96))) // v stores the final byte (as signatures are 65 bytes total)
    }
    // assembly implicitly returns (r, s, v)
  }

  function recoverSigner(bytes32 _ethSignedMessageHash, bytes memory _signature) public pure returns (address) {
    (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);
    return ecrecover(_ethSignedMessageHash, v, r, s); // Recovers original signer from _ethSignedMessageHash and post-split _signature
  }

  function verifySignature(address _signer, address _counterParty, string memory _ipfsHash, uint256 _blockNum, bytes memory _signature) public pure returns (bool) {
    bytes32 messageHash = getMessageHash(_signer, _counterParty, _ipfsHash, _blockNum);
    bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);
    return recoverSigner(ethSignedMessageHash, _signature) == _signer;
  }

  // Instantiate two party contract with (msg.sender, counterparty address, IPFS hash of the contract document, current block number) and sign it
  function createTwoPartyContract(address _counterParty, string memory _ipfsHash) public returns (uint256) {
    require(bytes32(twoPartyContracts[msg.sender][_counterParty][_ipfsHash][block.number]) == 0, "Contract instance already signed");
    twoPartyContracts[msg.sender][_counterParty][_ipfsHash][block.number] = bytes32("1");
    signContract(_counterParty, _ipfsHash, block.number);
    // Need to instantiate signature field for counterparty to pass validParty check
    twoPartyContracts[_counterParty][msg.sender][_ipfsHash][block.number] = bytes32("1"); 
    return block.number;
  }
  
  //function executeContract(address _counterParty, string memory _ipfsHash, uint256 _blockNum) public validParty(_counterParty, _ipfsHash, _blockNum) {
    // Emit something representing contract signed by all parties
    // Will require logic confirming all signatories defined in Contract struct have signed
    // Maybe integrate payment logic
  //}

  // payment handling functions if we need them, otherwise just accept and allow withdrawal
  function withdraw() public onlyOwner {
    (bool success, ) = msg.sender.call{value: address(this).balance}("");
    require(success);
  }
  receive() external payable {}
  fallback() external payable {}
}

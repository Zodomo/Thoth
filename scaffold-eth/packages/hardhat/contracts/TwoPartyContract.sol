// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract TwoPartyContract {
  /******************************************
               DATA STRUCTURES
  ******************************************/

  mapping(address => bool) public owners; // Contract owners, all addresses initialize as false

  /* "multidimensional" mapping allows for one party to sign different contracts (even each contract multiple times but only once per block) with different people
     Can only sign one iteration of a specific contract between two parties once per block as we use block.number as nonce
     Originator/Initiator + Counterparty + IPFS Hash + Block Number Contract Proposed In = Contract Hash */
  mapping(address => 
    mapping(address => 
      mapping(string => 
        mapping(uint256 => bytes32)))) public contractHashes;
  
  // Keep an array of contractHashes related to each address
  mapping(address => bytes32[]) public relatedContracts;
  
  // Contract struct will hold all contract data
  struct Contract {
    address initiator;
    address counterparty;
    string ipfsHash;
    uint256 blockProposed;
    uint256 blockExecuted;
    bool executed;
    bytes initiatorSig;
    bytes counterpartySig;
  }

  // Store contract structs in mapping paired to contract hash
  mapping(bytes32 => Contract) public contracts;

  /******************************************
                    EVENTS
  ******************************************/

  // Log contract hash, initiator address, counterparty address, ipfsHash/Pointer string, and blockNumber agreement is in
  // counterparty is the only unindexed parameter because EVM only allows for three and I found counterparty to be the least relevant
  event ContractCreated(bytes32 indexed contractHash, address initiator, address counterparty, string indexed ipfsHash, uint256 indexed blockNumber);
  // Log contract hashes on their own as all contrct details in ContractCreated can be obtianed by querying granular contract data mappings (contractParties, ...)
  event ContractHashed(bytes32 indexed contractHash);
  // Log contract signatures, contractHash used in verification, and the signer address to validate against
  event ContractSigned(bytes32 indexed contractHash, address indexed signer, bytes indexed signature);
  // Log contract execution using hash and the block it executed in
  event ContractExecuted(bytes32 indexed contractHash, uint256 indexed blockNumber);

  /******************************************
                  CONSTRUCTOR
  ******************************************/

  // what should we do on deploy?
  constructor() {
    owners[payable(msg.sender)] = true;
  }

  /******************************************
                   MODIFIERS
  ******************************************/

  // Require msg.sender to be an owner of contract to call modified function
  modifier onlyOwner() {
    require(owners[msg.sender], "Not a contract owner");
    _;
  }

  // Check for absence of contrash hash to make sure agreement hasn't been initialized
  modifier notCreated(address _counterparty, string memory _ipfsHash) {
    require(bytes32(contractHashes[msg.sender][_counterparty][_ipfsHash][block.number]) == 0, "Contract already initiated in this block");
    _;
  }

  // Require function call by contract initiator
  modifier onlyInitiator(bytes32 _contractHash) {
    require(contracts[_contractHash].initiator == msg.sender, "Not contract initiator");
    _;
  }

  // Require function call by counterparty, mainly for calling execute contract
  modifier onlyCounterparty(bytes32 _contractHash) {
    require(contracts[_contractHash].counterparty == msg.sender, "Not contract counterparty");
    _;
  }

  // Require contract creation by checking if _party1 is part of a contract with _party2
  modifier validParty(bytes32 _contractHash) {
    require(contracts[_contractHash].initiator == msg.sender || contracts[_contractHash].counterparty == msg.sender, "Not a contract party");
    _;
  }

  // Require contract is not executed
  modifier notExecuted(bytes32 _contractHash) {
    require(!contracts[_contractHash].executed, "Contract already executed");
    _;
  }

  // Require contract execution has occured by all parties signing
  modifier hasExecuted(bytes32 _contractHash) {
    require(contracts[_contractHash].executed, "Contract hasnt executed");
    _;
  }

  /******************************************
             MANAGEMENT FUNCTIONS
  ******************************************/

  // Add additional owners to contract
  function addOwner(address _owner) public onlyOwner {
    owners[payable(_owner)] = true;
  }

  /******************************************
              INTERNAL FUNCTIONS
  ******************************************/

  // Hash of: Party1 Address + Party2 Address + IPFS Hash + Block Number Agreement Proposed In
  function getMessageHash(address _party1, address _party2, string memory _ipfsHash, uint256 _blockNum) internal pure returns (bytes32) {
    return keccak256(abi.encodePacked(_party1, _party2, _ipfsHash, _blockNum));
  }

  /* Hash all relevant contract data
     We prevent _counterparty from hashing because switching party address order will change hash 
     The contract hash is what each party needs to sign */
  function hashContract(address _counterparty, string memory _ipfsHash, uint256 _blockNum) internal returns (bytes32) {
    // Generate contract hash
    bytes32 contractHash = getMessageHash(msg.sender, _counterparty, _ipfsHash, _blockNum);

    // Save same contract hash for both parties. Relate hash to address in relatedContracts
    // Initiator must be only caller as changing the address order changes the hash
    contractHashes[msg.sender][_counterparty][_ipfsHash][_blockNum] = contractHash;
    relatedContracts[msg.sender].push(contractHash);
    contractHashes[_counterparty][msg.sender][_ipfsHash][_blockNum] = contractHash;
    relatedContracts[_counterparty].push(contractHash);

    emit ContractHashed(contractHash);
    return contractHash;
  }

  // Execite contract called once last signature is captured
  function executeContract(bytes32 _contractHash) internal validParty(_contractHash) notExecuted(_contractHash) returns (bool) {
    // Double check all signatures are valid
    require(verifyAllSignatures(_contractHash));
    contracts[_contractHash].blockExecuted = block.number;
    emit ContractExecuted(_contractHash, block.number);
    return true;
  }

  /******************************************
               PUBLIC FUNCTIONS
  ******************************************/

  // Instantiate two party contract with (msg.sender, counterparty address, IPFS hash of the contract document, current block number) and hash it, return block number of agreement proposal
  // notCreated() prevents duplicate calls from msg.sender or the counterparty by checking for existence of contract hash
  function createTwoPartyContract(address _counterparty, string memory _ipfsHash) public notCreated(_counterparty, _ipfsHash) returns (bytes32) {
    bytes32 contractHash = hashContract(_counterparty, _ipfsHash, block.number);

    // Begin populating Contract data struct
    // Save contract party addresses
    contracts[contractHash].initiator = msg.sender;
    contracts[contractHash].counterparty = _counterparty;
    // Save contract IPFS hash/pointer
    contracts[contractHash].ipfsHash = _ipfsHash;
    // Save block number agreement proposed in
    contracts[contractHash].blockProposed = block.number;

    emit ContractCreated(contractHash, msg.sender, _counterparty, _ipfsHash, block.number);
    return contractHash;
  }

  // Verify if signature was for messageHash and that the signer is valid, public because interface might want to use this
  function verifySignature(address _signer, bytes32 _contractHash, bytes memory _signature) public pure returns (bool) {
    bytes32 ethSignedMessageHash = ECDSA.toEthSignedMessageHash(_contractHash);
    return ECDSA.recover(ethSignedMessageHash, _signature) == _signer;
  }

  // Commit signature to blockchain storage after verifying it is correct and that msg.sender hasn't already called signContract()
  // Consider cleaning function by migrating checks into modifiers
  function signContract(bytes32 _contractHash, bytes memory _signature) public validParty(_contractHash) notExecuted(_contractHash) {
    // Confirm signature is valid
    require(verifySignature(msg.sender, _contractHash, _signature), "Signature not valid");

    // Save initiator signature
    if (contracts[_contractHash].initiator == msg.sender) {
      // Check if already signed
      require(keccak256(contracts[_contractHash].initiatorSig) != keccak256(_signature), "Already signed");
      // Save signature
      contracts[_contractHash].initiatorSig = _signature;
      emit ContractSigned(_contractHash, msg.sender, _signature);
      // If everyone signed, execute
      if (verifyAllSignatures(_contractHash)) {
        contracts[_contractHash].executed = executeContract(_contractHash);
      }

    // Save counterparty signature
    } else if (contracts[_contractHash].counterparty == msg.sender) {
      // Check if already signed
      require(keccak256(contracts[_contractHash].counterpartySig) != keccak256(_signature), "Already signed");
      // Save signature
      contracts[_contractHash].counterpartySig = _signature;
      emit ContractSigned(_contractHash, msg.sender, _signature);
      // If everyone signed, execute
      if (verifyAllSignatures(_contractHash)) {
        contracts[_contractHash].executed = executeContract(_contractHash);
      }

    // Shouldn't ever be hit but will leave anyways
    } else {
      revert("Not a contract party");
    }
  }

  // Created to validate both parties have signed with validated signatures
  // Will need to be adapted if multi-party signing is ever implemented
  function verifyAllSignatures(bytes32 _contractHash) public view returns (bool) {
    bool initiatorSigValid = verifySignature(contracts[_contractHash].initiator, _contractHash, contracts[_contractHash].initiatorSig);
    bool counterpartySigValid = verifySignature(contracts[_contractHash].counterparty, _contractHash, contracts[_contractHash].counterpartySig);
    return (initiatorSigValid == counterpartySigValid);
  }

  /******************************************
               PAYMENT FUNCTIONS
  ******************************************/

  // Payment handling functions if we need them, otherwise just accept and allow withdrawal to any owner
  function withdraw() public onlyOwner {
    (bool success, ) = msg.sender.call{value: address(this).balance}("");
    require(success);
  }
  receive() external payable {}
  fallback() external payable {}
}
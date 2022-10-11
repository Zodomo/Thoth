import { useContractReader } from "eth-hooks";
import { ethers } from "ethers";
import React from "react";
import { Link } from "react-router-dom";

/**
 * web3 props can be passed from '../App.jsx' into your local view component for use
 * @param {*} yourLocalBalance balance on current network
 * @param {*} readContracts contracts from current chain already pre-loaded using ethers contract module. More here https://docs.ethers.io/v5/api/contract/contract/
 * @returns react component
 **/
function Home({ yourLocalBalance, readContracts }) {
  // you can also use hooks locally in your component of choice
  // in this case, let's keep track of 'purpose' variable from our contract
  const purpose = useContractReader(readContracts, "TwoPartyContract", "purpose");

  return (
    <div>
      <div style={{ margin: 32 }}>
        This is the Thoth frontend.
      </div>
      <div style={{ margin: 32 }}>
        Interact with the smart contract using{" "}
        <span
          className="highlight"
          style={{ marginLeft: 4, /* backgroundColor: "#f9f9f9", */ padding: 4, borderRadius: 4, fontWeight: "bolder" }}
        >
          <Link to="/debug">"Debug Contract"</Link>
        </span>{" "}
        for now.
      </div>
      <div style={{ margin: 32 }}>
        Signing functionality will need to be built as that is done by front-end. Use <a href="https://signator.io/">https://signator.io/</a> for now.
      </div>
      <div style={{ margin: 32 }}>
        If manually testing, make sure you sign the contract hash, aka output from{" "}
        <span
          className="highlight"
          style={{ marginLeft: 4, /* backgroundColor: "#f9f9f9", */ padding: 4, borderRadius: 4, fontWeight: "bolder" }}
        >
          getMessageHash()
        </span>{" "}
        stored in{" "}
        <span
          className="highlight"
          style={{ marginLeft: 4, /* backgroundColor: "#f9f9f9", */ padding: 4, borderRadius: 4, fontWeight: "bolder" }}
        >
          contractHashes
        </span>{" "}
        , NOT output from{" "}
        <span
          className="highlight"
          style={{ marginLeft: 4, /* backgroundColor: "#f9f9f9", */ padding: 4, borderRadius: 4, fontWeight: "bolder" }}
        >
        getEthSignedMessageHash()
        </span>{" "}
      </div>
      <div style={{ margin: 32 }}>
        App flow is as follows:
      </div>
      <div style={{ margin: 32 }}>
        1. Call{" "}
        <span
          className="highlight"
          style={{ marginLeft: 4, /* backgroundColor: "#f9f9f9", */ padding: 4, borderRadius: 4, fontWeight: "bolder" }}
        >
          createTwoPartyContract(Party1 Account, Party2 Account, IPFS Pointer to Contract Document)
        </span>{" "}
        to generate and store contract hash in{" "}
        <span
          className="highlight"
          style={{ marginLeft: 4, /* backgroundColor: "#f9f9f9", */ padding: 4, borderRadius: 4, fontWeight: "bolder" }}
        >
          contractHashes
        </span>{" "}
        mapping
      </div>
      <div style={{ margin: 32 }}>
        NOTE: Step 1 will populate mappings{" "}
        <span
          className="highlight"
          style={{ marginLeft: 4, /* backgroundColor: "#f9f9f9", */ padding: 4, borderRadius: 4, fontWeight: "bolder" }}
        >
          contractParties, contractIpfsHash, contractBlock
        </span>{" "}
        with their respective data via call to{" "}
        <span
          className="highlight"
          style={{ marginLeft: 4, /* backgroundColor: "#f9f9f9", */ padding: 4, borderRadius: 4, fontWeight: "bolder" }}
        >
          hashContract()
        </span>{" "}
        in{" "}
        <span
          className="highlight"
          style={{ marginLeft: 4, /* backgroundColor: "#f9f9f9", */ padding: 4, borderRadius: 4, fontWeight: "bolder" }}
        >
          createTwoPartyContract()
        </span>{" "}
      </div>
      <div style={{ margin: 32 }}>
        NOTE: You may need to retrieve the block number contract initiation occurred in as frontend doesn't return the block number yet <a href="https://goerli.etherscan.io/">https://goerli.etherscan.io/</a>
      </div>
      <div style={{ margin: 32 }}>
        2. Call{" "}
        <span
          className="highlight"
          style={{ marginLeft: 4, /* backgroundColor: "#f9f9f9", */ padding: 4, borderRadius: 4, fontWeight: "bolder" }}
        >
          contractHashes[<em>Party1 Address</em>][<em>Party2 Address</em>][<em>IPFS Pointer to Contract Document</em>][<em>Block Number Agreement Proposed In</em>]
        </span>{" "}
        to retrieve contract hash
      </div>
      <div style={{ margin: 32 }}>
        3. Sign contract hash retrieved in Step 2
      </div>
      <div style={{ margin: 32}}>
        NOTE: Front end doesn't support signing yet. Substitute with <a href="https://signator.io/">https://signator.io/</a> for now.
      </div>
      <div style={{ margin: 32 }}>
        4. Commit signature from step 3 to blockchain using{" "}
        <span
          className="highlight"
          style={{ marginLeft: 4, /* backgroundColor: "#f9f9f9", */ padding: 4, borderRadius: 4, fontWeight: "bolder" }}
        >
          signContract()
        </span>{" "}
      </div>
      <div style={{ margin: 32}}>
        <span
          className="highlight"
          style={{ marginLeft: 4, /* backgroundColor: "#f9f9f9", */ padding: 4, borderRadius: 4, fontWeight: "bolder" }}
        >
          signContract()
        </span>{" "}
        will generate an Ethereum signed message with{" "}
        <span
          className="highlight"
          style={{ marginLeft: 4, /* backgroundColor: "#f9f9f9", */ padding: 4, borderRadius: 4, fontWeight: "bolder" }}
        >
          getEthSignedMessageHash()
        </span>{" "}
        using contract hash in{" "}
        <span
          className="highlight"
          style={{ marginLeft: 4, /* backgroundColor: "#f9f9f9", */ padding: 4, borderRadius: 4, fontWeight: "bolder" }}
        >
          contractHashes
        </span>{" "}
      </div>
      <div style={{ margin: 32 }}>
        It will then check the output of{" "}
        <span
          className="highlight"
          style={{ marginLeft: 4, /* backgroundColor: "#f9f9f9", */ padding: 4, borderRadius: 4, fontWeight: "bolder" }}
        >
          getEthSignedMessageHash()
        </span>{" "}
        against the supplied signature from Step 3 using{" "}
        <span
          className="highlight"
          style={{ marginLeft: 4, /* backgroundColor: "#f9f9f9", */ padding: 4, borderRadius: 4, fontWeight: "bolder" }}
        >
          verifySignature()
        </span>{" "}
        to check for validity before storing the signature
      </div>
      <div style={{ margin: 32 }}>
        5. Counterparty will sign (<a href="https://signator.io/">https://signator.io/</a>) the contract hash and call{" "}
        <span
          className="highlight"
          style={{ marginLeft: 4, /* backgroundColor: "#f9f9f9", */ padding: 4, borderRadius: 4, fontWeight: "bolder" }}
        >
          signContract()
        </span>{" "}
        as well to commit their signature to the contract storage
      </div>
      <div style={{ margin: 32 }}>
        NOTE: The contract will automatically execute once the counterparty signs (check{" "}
        <span
          className="highlight"
          style={{ marginLeft: 4, /* backgroundColor: "#f9f9f9", */ padding: 4, borderRadius: 4, fontWeight: "bolder" }}
        >
          contractExecuted[<em>contract hash</em>]
        </span>{" "}
        to confirm)
      </div>
      <div style={{ margin: 32 }}>
        Lastly, someone can call{" "}
        <span
          className="highlight"
          style={{ marginLeft: 4, /* backgroundColor: "#f9f9f9", */ padding: 4, borderRadius: 4, fontWeight: "bolder" }}
        >
          verifyExecution(<em>contract hash</em>)
        </span>{" "}
        to check if all parties have signed with valid signatures
      </div>
      <div style={{ margin: 32 }}>
        GITHUB: <a href="https://github.com/Zodomo/Thoth/blob/main/scaffold-eth/packages/hardhat/contracts/TwoPartyContract.sol">https://github.com/Zodomo/Thoth/blob/main/scaffold-eth/packages/hardhat/contracts/TwoPartyContract.sol</a>
      </div>
    </div>
  );
}

export default Home;

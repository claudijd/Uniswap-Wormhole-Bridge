/**
 * Copyright Uniswap Foundation 2023
 *
 * Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with
 * the License. You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on
 * an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the
 * specific language governing permissions and limitations under the License.
 *
 * SPDX-License-Identifier: Apache-2.0
 */
pragma solidity ^0.8.9;

interface IWormhole {
    function publishMessage(uint32 nonce, bytes memory payload, uint8 consistencyLevel) external payable returns (uint64 sequence);
    function messageFee() external view returns (uint256);
}

contract UniswapWormholeMessageSender {
    string public constant NAME = "Uniswap Wormhole Message Sender";
    address public owner;
    
    // consistencyLevel = 1 means finalized on Ethereum, see https://book.wormhole.com/wormhole/3_coreLayerContracts.html#consistency-levels
    // `nonce` in Wormhole is a misnomer and can be safely set to a constant value.
    // In the future it could be used to communicate a payload version,
    // but as long as this contract is not upgradable and only sends one message type, it's not needed.
    uint32 public constant NONCE = 0;
    uint8 public constant CONSISTENCY_LEVEL = 1;

    event  MessageSent(bytes payload, address indexed messageReceiver);

    IWormhole private immutable wormhole;

    /**
     * @param bridgeAddress Address of Wormhole bridge contract on this chain.
     */
    constructor(address bridgeAddress) {
        wormhole = IWormhole(bridgeAddress);
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "sender not owner");
        _;
    }

    /**
     * @param targets array of target addresses
     * @param values array of values
     * @param datas array of datas
     * @param messageReceiver address of the receiver contract
     * @param receiverChainId chain id of the receiver chain
     */
    function sendMessage(address[] memory targets, uint256[] memory values, bytes[] memory datas, address messageReceiver, uint16 receiverChainId) external onlyOwner payable {
        bytes memory payload = abi.encode(targets,values,datas,messageReceiver,receiverChainId);

        wormhole.publishMessage{value: wormhole.messageFee()}(NONCE, payload, CONSISTENCY_LEVEL);

        emit MessageSent(payload, messageReceiver);
    }

    /**
     * @param newOwner address of new owner contract or EOA
     */
    function setOwner(address newOwner) external onlyOwner {
        owner = newOwner;
    }
}

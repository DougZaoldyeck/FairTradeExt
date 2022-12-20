var abi = [
    {
      "anonymous": false,
      "inputs": [
        {
          "indexed": true,
          "internalType": "bytes32",
          "name": "contractId",
          "type": "bytes32"
        },
        {
          "indexed": true,
          "internalType": "address",
          "name": "sender",
          "type": "address"
        },
        {
          "indexed": true,
          "internalType": "address",
          "name": "receiver",
          "type": "address"
        },
        {
          "indexed": false,
          "internalType": "uint256",
          "name": "amount",
          "type": "uint256"
        },
        {
          "indexed": false,
          "internalType": "bytes32",
          "name": "hashlock",
          "type": "bytes32"
        },
        {
          "indexed": false,
          "internalType": "uint256",
          "name": "timelock",
          "type": "uint256"
        }
      ],
      "name": "LogHTLCNew",
      "type": "event"
    },
    {
      "anonymous": false,
      "inputs": [
        {
          "indexed": true,
          "internalType": "bytes32",
          "name": "contractId",
          "type": "bytes32"
        }
      ],
      "name": "LogHTLCRefund",
      "type": "event"
    },
    {
      "anonymous": false,
      "inputs": [
        {
          "indexed": true,
          "internalType": "bytes32",
          "name": "contractId",
          "type": "bytes32"
        }
      ],
      "name": "LogHTLCWithdraw",
      "type": "event"
    },
    {
      "constant": false,
      "inputs": [
        {
          "internalType": "address payable",
          "name": "_receiver",
          "type": "address"
        },
        {
          "internalType": "bytes32",
          "name": "_hashlock",
          "type": "bytes32"
        },
        {
          "internalType": "uint256",
          "name": "_timelock",
          "type": "uint256"
        }
      ],
      "name": "newContract",
      "outputs": [
        {
          "internalType": "bytes32",
          "name": "contractId",
          "type": "bytes32"
        }
      ],
      "payable": true,
      "stateMutability": "payable",
      "type": "function"
    },
    {
      "constant": false,
      "inputs": [
        {
          "internalType": "bytes32",
          "name": "_contractId",
          "type": "bytes32"
        },
        {
          "internalType": "bytes32",
          "name": "_preimage",
          "type": "bytes32"
        }
      ],
      "name": "withdraw",
      "outputs": [
        {
          "internalType": "bool",
          "name": "",
          "type": "bool"
        }
      ],
      "payable": false,
      "stateMutability": "nonpayable",
      "type": "function"
    },
    {
      "constant": false,
      "inputs": [
        {
          "internalType": "bytes32",
          "name": "_contractId",
          "type": "bytes32"
        }
      ],
      "name": "refund",
      "outputs": [
        {
          "internalType": "bool",
          "name": "",
          "type": "bool"
        }
      ],
      "payable": false,
      "stateMutability": "nonpayable",
      "type": "function"
    },
    {
      "constant": true,
      "inputs": [
        {
          "internalType": "bytes32",
          "name": "_contractId",
          "type": "bytes32"
        }
      ],
      "name": "getContract",
      "outputs": [
        {
          "internalType": "address",
          "name": "sender",
          "type": "address"
        },
        {
          "internalType": "address",
          "name": "receiver",
          "type": "address"
        },
        {
          "internalType": "uint256",
          "name": "amount",
          "type": "uint256"
        },
        {
          "internalType": "bytes32",
          "name": "hashlock",
          "type": "bytes32"
        },
        {
          "internalType": "uint256",
          "name": "timelock",
          "type": "uint256"
        },
        {
          "internalType": "bool",
          "name": "withdrawn",
          "type": "bool"
        },
        {
          "internalType": "bool",
          "name": "refunded",
          "type": "bool"
        },
        {
          "internalType": "bytes32",
          "name": "preimage",
          "type": "bytes32"
        }
      ],
      "payable": false,
      "stateMutability": "view",
      "type": "function"
    }
  ]
// console.clear();
require("dotenv").config();
const {
  AccountId,
  PrivateKey,
  Client,
  ContractFunctionParameters,
  ContractExecuteTransaction,
  ContractCallQuery,
  Hbar,
  ContractCreateFlow,
  FileCreateTransaction 
} = require("@hashgraph/sdk");
const fs = require("fs");

// Configure accounts and client
const operatorId = AccountId.fromString(process.env.OPERATOR_ID);
const operatorKey = PrivateKey.fromString(process.env.OPERATOR_PVKEY);

const client = Client.forTestnet().setOperator(operatorId, operatorKey);

async function main() {
  // Import the compiled contract bytecode
  const contractBytecode = fs.readFileSync(
    "GPRouletteL_sol_Roulette.bin"
  );

  // Create a file on Hedera and store the bytecode
  const fileCreateTx = new FileCreateTransaction()
    .setContents(contractBytecode)
    .setKeys([operatorKey])
    .setMaxTransactionFee(new Hbar(0.75))
    .freezeWith(client);
  const fileCreateSign = await fileCreateTx.sign(operatorKey);
  // console.log(fileCreateSign);
  const fileCreateSubmit = await fileCreateSign.execute(client);
  const fileCreateRx = await fileCreateSubmit.getReceipt(client);
  const bytecodeFileId = fileCreateRx.fileId;
  console.log(`- The bytecode file ID is: ${bytecodeFileId} \n`);

  // Instantiate the smart contract
  // const contractCreateTx = new ContractCreateFlow()
  //   .setBytecode(contractBytecode)
  //   .setGas(100000)
  //   .setConstructorParameters(
  //     new ContractFunctionParameters().addString("Alice").addUint256(111111)
  //   );
  // const contractCreateSubmit = await contractCreateTx.execute(client);
  // const contractCreateRx = await contractCreateSubmit.getReceipt(client);
  // const contractId = contractCreateRx.contractId;
  // const contractAddress = contractId.toSolidityAddress();
  // console.log(`- The smart contract ID is: ${contractId} \n`);
  // console.log(`- Smart contract ID in Solidity format: ${contractAddress} \n`);

  // // Query the contract to check changes in state variable
  // const contractQueryTx = new ContractCallQuery()
  //   .setContractId(contractId)
  //   .setGas(100000)
  //   .setFunction(
  //     "getMobileNumber",
  //     new ContractFunctionParameters().addString("Alice")
  //   );
  // const contractQuerySubmit = await contractQueryTx.execute(client);
  // const contractQueryResult = contractQuerySubmit.getUint256(0);
  // console.log(
  //   `- Here's the phone number you asked for: ${contractQueryResult} \n`
  // );

  // // Call contract function to update the state variable
  // const contractExecuteTx = new ContractExecuteTransaction()
  //   .setContractId(contractId)
  //   .setGas(100000)
  //   .setFunction(
  //     "setMobileNumber",
  //     new ContractFunctionParameters().addString("Bob").addUint256(222222)
  //   );
  // const contractExecuteSubmit = await contractExecuteTx.execute(client);
  // const contractExecuteRx = await contractExecuteSubmit.getReceipt(client);
  // console.log(
  //   `- Contract function call status: ${contractExecuteRx.status} \n`
  // );

  // // Query the contract to check changes in state variable
  // const contractQueryTx1 = new ContractCallQuery()
  //   .setContractId(contractId)
  //   .setGas(100000)
  //   .setFunction(
  //     "getMobileNumber",
  //     new ContractFunctionParameters().addString("Bob")
  //   );
  // const contractQuerySubmit1 = await contractQueryTx1.execute(client);
  // const contractQueryResult1 = contractQuerySubmit1.getUint256(0);
  // console.log(
  //   `- Here's the phone number you asked for: ${contractQueryResult1} \n`
  // );
}
main();

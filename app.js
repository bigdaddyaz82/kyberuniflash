let provider;
let signer;
let contract;

const contractAddress = "YOUR_CONTRACT_ADDRESS_HERE"; 
const contractABI = [/* YOUR_ABI_HERE */];

document.getElementById("connect").addEventListener("click", async () => {
  if (window.ethereum) {
    provider = new ethers.providers.Web3Provider(window.ethereum);
    await provider.send("eth_requestAccounts", []);
    signer = provider.getSigner();
    contract = new ethers.Contract(contractAddress, contractABI, signer);
    alert("Wallet connected!");
  } else {
    alert("Please install MetaMask!");
  }
});

document.getElementById("start-arbitrage").addEventListener("click", async () => {
  if (!contract) {
    alert("Connect wallet first.");
    return;
  }
  try {
    const tx = await contract.executeArbitrage(
      "0xAssetToken",  // change these
      ethers.utils.parseUnits("100", 18),
      "0xToken1", 
      "0xToken2",
      true
    );
    await tx.wait();
    alert("Arbitrage executed!");
  } catch (err) {
    console.error(err);
    alert("Transaction failed. See console for details.");
  }
});

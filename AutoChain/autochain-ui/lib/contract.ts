import { ethers, JsonRpcProvider, Contract } from 'ethers';
import abi from './abi.json';

export const CONTRACT_ABI = abi;
export const CONTRACT_ADDRESS = '0x5FbDB2315678afecb367f032d93F642f64180aa3'; // Local deployment address

export const getContract = (signer?: ethers.Signer) => {
  const provider = new JsonRpcProvider('http://127.0.0.1:8545');
  return new Contract(CONTRACT_ADDRESS, CONTRACT_ABI, signer || provider);
};
'use client';

import { useState } from 'react';
import { useWallet } from '../../lib/wallet';
import { getContract } from '../../lib/contract';
import { ethers } from 'ethers';

export default function Home() {
  const { account, connectWallet, disconnectWallet, signer } = useWallet();
  const [vehicles, setVehicles] = useState<any[]>([]);
  const [loading, setLoading] = useState(false);

  const loadVehicles = async () => {
    if (!account) return;
    setLoading(true);
    try {
      const contract = getContract();
      // For demo, assume we have some vehicles, in real app we'd query user's vehicles
      // This is simplified
      setVehicles([]);
    } catch (error) {
      console.error(error);
    }
    setLoading(false);
  };

  const registerVehicle = async (vin: string, owner: string) => {
    if (!signer) return;
    try {
      const contract = getContract(signer);
      const tx = await contract.registerVehicle(vin, owner);
      await tx.wait();
      alert('Vehicle registered!');
      loadVehicles();
    } catch (error) {
      console.error(error);
      alert('Error registering vehicle');
    }
  };

  return (
    <div className="min-h-screen bg-gray-100 p-8">
      <div className="max-w-4xl mx-auto">
        <h1 className="text-4xl font-bold text-center mb-8">AutoChain - Vehicle Registry</h1>

        {!account ? (
          <div className="text-center">
            <button
              onClick={connectWallet}
              className="bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded"
            >
              Connect Wallet
            </button>
          </div>
        ) : (
          <div>
            <div className="flex justify-between items-center mb-8">
              <p>Connected: {account}</p>
              <button
                onClick={disconnectWallet}
                className="bg-red-500 hover:bg-red-700 text-white font-bold py-2 px-4 rounded"
              >
                Disconnect
              </button>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-2 gap-8">
              <div className="bg-white p-6 rounded-lg shadow">
                <h2 className="text-2xl font-bold mb-4">Register Vehicle</h2>
                <form onSubmit={(e) => {
                  e.preventDefault();
                  const formData = new FormData(e.target as HTMLFormElement);
                  registerVehicle(formData.get('vin') as string, formData.get('owner') as string);
                }}>
                  <input
                    name="vin"
                    placeholder="VIN"
                    className="w-full p-2 border rounded mb-4"
                    required
                  />
                  <input
                    name="owner"
                    placeholder="Owner Address"
                    className="w-full p-2 border rounded mb-4"
                    required
                  />
                  <button
                    type="submit"
                    className="bg-green-500 hover:bg-green-700 text-white font-bold py-2 px-4 rounded w-full"
                  >
                    Register
                  </button>
                </form>
              </div>

              <div className="bg-white p-6 rounded-lg shadow">
                <h2 className="text-2xl font-bold mb-4">My Vehicles</h2>
                <button
                  onClick={loadVehicles}
                  className="bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded mb-4"
                >
                  Load Vehicles
                </button>
                {loading ? (
                  <p>Loading...</p>
                ) : (
                  <ul>
                    {vehicles.map((vehicle, index) => (
                      <li key={index} className="border-b py-2">
                        VIN: {vehicle.vin}, Status: {vehicle.status}
                      </li>
                    ))}
                  </ul>
                )}
              </div>
            </div>
          </div>
        )}
      </div>
    </div>
  );
}

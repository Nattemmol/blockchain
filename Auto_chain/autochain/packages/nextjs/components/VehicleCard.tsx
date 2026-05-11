"use client";

import Link from "next/link";
import { useScaffoldReadContract } from "~~/hooks/scaffold-eth";

export default function VehicleCard({ tokenId }: { tokenId: number }) {
  const { data: vehicle } = useScaffoldReadContract({
    contractName: "AutoChainRegistry",
    functionName: "getVehicle",
    args: [tokenId],
  });

  if (!vehicle) return null;

  return (
    <Link href={`/vehicle/${tokenId}`}>
      <div className="border p-4 rounded hover:shadow cursor-pointer">
        <p><b>VIN:</b> {vehicle.vin}</p>
        <p><b>Status:</b> {vehicle.status}</p>
        <p className="text-sm text-gray-500">
          Owner: {vehicle.currentOwner.slice(0, 6)}...
        </p>
      </div>
    </Link>
  );
}

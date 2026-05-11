"use client";

import { useParams } from "next/navigation";
import { useScaffoldReadContract } from "~~/hooks/scaffold-eth";
import OwnershipTimeline from "~~/components/OwnershipTimeline";
import TransferOwnership from "~~/components/TransferOwnership";
import { useIsVehicleOwner } from "~~/hooks/useIsVehicleOwner";

const tokenId = BigInt(params.id);
const { isOwner, owner } = useIsVehicleOwner(tokenId);

export default function VehicleDetails() {
  const params = useParams();
  const tokenId = Number(params.id);

  const { data: vehicle } = useScaffoldReadContract({
    contractName: "AutoChainRegistry",
    functionName: "getVehicle",
    args: [tokenId],
  });

  if (!vehicle) return <p>Loading...</p>;

  return (
    <div className="p-8">
      <h2 className="text-2xl font-bold mb-4">Vehicle #{tokenId}</h2>

      <p><b>VIN:</b> {vehicle.vin}</p>
      <p><b>Status:</b> {vehicle.status}</p>
      <p><b>Owner:</b> {vehicle.currentOwner}</p>

      <OwnershipTimeline tokenId={tokenId} />
    </div>
  );
}

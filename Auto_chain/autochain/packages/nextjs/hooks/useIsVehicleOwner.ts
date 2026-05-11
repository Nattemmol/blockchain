"use client";

import { useAccount } from "wagmi";
import { useScaffoldReadContract } from "~~/hooks/scaffold-eth";

export function useIsVehicleOwner(tokenId: bigint) {
  const { address } = useAccount();

  const { data: owner } = useScaffoldReadContract({
    contractName: "AutoChainRegistry",
    functionName: "ownerOf",
    args: [tokenId],
  });

  return {
    isOwner:
      owner && address?.toLowerCase() === owner.toLowerCase(),
    owner,
  };
}


"use client";

import { useAccount } from "wagmi";
import { useScaffoldReadContract } from "~~/hooks/scaffold-eth";

export function useIsAdmin() {
  const { address } = useAccount();

  const { data: admin } = useScaffoldReadContract({
    contractName: "AutoChainRegistry",
    functionName: "owner",
  });

  return {
    isAdmin: admin && address?.toLowerCase() === admin.toLowerCase(),
    admin,
  };
}

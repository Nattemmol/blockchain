"use client";

import { useState } from "react";
import { isAddress } from "viem";
import { useScaffoldWriteContract } from "~~/hooks/scaffold-eth";

export default function TransferOwnership({
  tokenId,
}: {
  tokenId: bigint;
}) {
  const [recipient, setRecipient] = useState("");
  const [error, setError] = useState("");

  const { writeContractAsync, isPending } = useScaffoldWriteContract({
    contractName: "AutoChainRegistry",
  });

  const handleTransfer = async () => {
    if (!isAddress(recipient)) {
      setError("Invalid wallet address");
      return;
    }

    setError("");
    await writeContractAsync({
      functionName: "transferOwnership",
      args: [tokenId, recipient],
    });
  };

  return (
    <div className="mt-6 border rounded-xl p-4 bg-gray-50">
      <h3 className="font-semibold text-lg mb-2">Transfer Ownership</h3>

      <input
        className="w-full border p-2 rounded mb-2"
        placeholder="Recipient wallet address"
        value={recipient}
        onChange={e => setRecipient(e.target.value)}
      />

      {error && <p className="text-red-600 text-sm">{error}</p>}

      <button
        onClick={handleTransfer}
        disabled={isPending}
        className="w-full bg-black text-white py-2 rounded hover:opacity-90"
      >
        {isPending ? "Transferring..." : "Transfer Ownership"}
      </button>

      <p className="text-xs text-gray-500 mt-2">
        This action is irreversible and recorded on-chain.
      </p>
    </div>
  );
}

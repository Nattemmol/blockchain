"use client";

import { useScaffoldReadContract } from "~~/hooks/scaffold-eth";

export default function OwnershipTimeline({ tokenId }: { tokenId: number }) {
  const { data: history } = useScaffoldReadContract({
    contractName: "AutoChainRegistry",
    functionName: "getOwnershipHistory",
    args: [tokenId],
  });

  if (!history) return null;

  return (
    <div className="mt-6">
      <h3 className="font-semibold mb-2">Ownership History</h3>
      <ul className="border-l pl-4">
        {history.map((h, i) => (
          <li key={i} className="mb-2">
            <p>{h.owner}</p>
            <small className="text-gray-500">
              {new Date(Number(h.timestamp) * 1000).toLocaleString()}
            </small>
          </li>
        ))}
      </ul>
    </div>
  );
}

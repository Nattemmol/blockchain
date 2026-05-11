"use client";

import { useState } from "react";
import { useScaffoldWriteContract } from "~~/hooks/scaffold-eth";

import { useIsAdmin } from "~~/hooks/useIsAdmin";



export default function RegisterVehicleForm() {
  const { isAdmin } = useIsAdmin();

  if (!isAdmin) return null;
  const [vin, setVin] = useState("");
  const [uri, setUri] = useState("");
  const [owner, setOwner] = useState("");

  const { writeContractAsync } = useScaffoldWriteContract("AutoChainRegistry");

  const register = async () => {
    await writeContractAsync({
      functionName: "registerVehicle",
      args: [vin, uri, owner],
    });
  };

  return (
    <div className="space-y-3">
      <input placeholder="VIN" onChange={e => setVin(e.target.value)} />
      <input placeholder="Metadata URI" onChange={e => setUri(e.target.value)} />
      <input placeholder="Owner Address" onChange={e => setOwner(e.target.value)} />
      <button onClick={register} className="btn btn-primary">
        Register Vehicle
      </button>
    </div>
  );
}

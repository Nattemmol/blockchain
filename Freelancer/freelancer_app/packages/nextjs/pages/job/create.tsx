import { useState } from "react";
import { useScaffoldWriteContract } from "~~/hooks/scaffold-eth";
import { parseEther } from "viem";


const [freelancer, setFreelancer] = useState("");
const [milestones, setMilestones] = useState([
  { title: "", amount: "" },
]);

const { writeContractAsync } = useScaffoldWriteContract("FreelanceEscrow");


const addMilestone = () => {
  setMilestones([...milestones, { title: "", amount: "" }]);
};

const updateMilestone = (index: number, field: string, value: string) => {
  const copy = [...milestones];
  copy[index][field] = value;
  setMilestones(copy);
};

const removeMilestone = (index: number) => {
  setMilestones(milestones.filter((_, i) => i !== index));
};


const totalAmount = milestones.reduce(
  (sum, m) => sum + (m.amount ? Number(m.amount) : 0),
  0
);


const createJob = async () => {
  if (!freelancer) return alert("Freelancer address required");

  const titles = milestones.map(m => m.title);
  const amounts = milestones.map(m => parseEther(m.amount));

  await writeContractAsync({
    functionName: "createJob",
    args: [freelancer, titles, amounts],
    value: parseEther(totalAmount.toString()),
  });
};



export default function CreateJob() {
  return (
    <div className="max-w-2xl mx-auto p-6 space-y-4">
      <h1 className="text-2xl font-bold">Create New Job</h1>

      <input
        className="input input-bordered w-full"
        placeholder="Freelancer Address"
        value={freelancer}
        onChange={e => setFreelancer(e.target.value)}
      />

      <h2 className="font-semibold">Milestones</h2>

      {milestones.map((m, i) => (
        <div key={i} className="border p-3 rounded space-y-2">
          <input
            className="input input-bordered w-full"
            placeholder="Milestone title"
            value={m.title}
            onChange={e => updateMilestone(i, "title", e.target.value)}
          />

          <input
            className="input input-bordered w-full"
            placeholder="Amount (ETH)"
            type="number"
            value={m.amount}
            onChange={e => updateMilestone(i, "amount", e.target.value)}
          />

          {milestones.length > 1 && (
            <button
              className="btn btn-sm btn-error"
              onClick={() => removeMilestone(i)}
            >
              Remove
            </button>
          )}
        </div>
      ))}

      <button className="btn btn-outline w-full" onClick={addMilestone}>
        + Add Milestone
      </button>

      <div className="text-right font-semibold">
        Total: {totalAmount} ETH
      </div>

      <button className="btn btn-primary w-full" onClick={createJob}>
        Create Job & Deposit
      </button>
    </div>
  );
}

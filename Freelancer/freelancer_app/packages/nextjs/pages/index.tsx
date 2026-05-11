import type { NextPage } from "next";
import Link from "next/link";
import { useScaffoldReadContract } from "~~/hooks/scaffold-eth";
import { Address } from "~~/components/scaffold-eth";

const jobStatusMap = [
  "Open",
  "In Progress",
  "Completed",
  "Cancelled",
  "Disputed",
];

const Home: NextPage = () => {
  // 1. Read jobCounter
  const { data: jobCounter } = useScaffoldReadContract({
    contractName: "FreelanceEscrow",
    functionName: "jobCounter",
  });

  const jobIds =
    jobCounter && Number(jobCounter) > 0
      ? Array.from({ length: Number(jobCounter) }, (_, i) => i + 1)
      : [];

  return (
    <div className="p-10 max-w-6xl mx-auto">
      <h1 className="text-3xl font-bold mb-6">Freelance Jobs</h1>

      {jobIds.length === 0 && (
        <p className="text-gray-500">No jobs created yet.</p>
      )}

      <div className="grid gap-4">
        {jobIds.map(jobId => (
          <JobCard key={jobId} jobId={jobId} />
        ))}
      </div>
    </div>
  );
};

export default Home;


const JobCard = ({ jobId }: { jobId: number }) => {
  const { data: job } = useScaffoldReadContract({
    contractName: "FreelanceEscrow",
    functionName: "jobs",
    args: [jobId],
  });

  if (!job?.exists) return null;

  return (
    <Link href={`/job/${jobId}`}>
      <div className="border rounded-lg p-4 hover:bg-gray-50 cursor-pointer transition">
        <div className="flex justify-between">
          <h2 className="text-lg font-semibold">Job #{jobId}</h2>
          <span className="text-sm px-2 py-1 rounded bg-blue-100 text-blue-800">
            {jobStatusMap[Number(job.status)]}
          </span>
        </div>

        <div className="mt-2 space-y-1 text-sm">
          <div>
            <strong>Client:</strong>{" "}
            <Address address={job.client} />
          </div>
          <div>
            <strong>Freelancer:</strong>{" "}
            <Address address={job.freelancer} />
          </div>
          <div>
            <strong>Current Milestone:</strong>{" "}
            {Number(job.currentMilestone)}
          </div>
          <div>
            <strong>Total Amount:</strong>{" "}
            {Number(job.totalAmount) / 1e18} ETH
          </div>
        </div>
      </div>
    </Link>
  );
};

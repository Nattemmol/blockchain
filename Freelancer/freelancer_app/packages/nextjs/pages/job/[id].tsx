import { useRouter } from "next/router";
import { NextPage } from "next";
import { Address, Balance } from "~~/components/scaffold-eth";
import { useAccount } from "wagmi";
import {
  useScaffoldReadContract,
  useScaffoldWriteContract,
} from "~~/hooks/scaffold-eth";
import { ReactElement, JSXElementConstructor, ReactNode, ReactPortal, Key } from "react";

const jobStatusMap = [
  "Open",
  "In Progress",
  "Completed",
  "Cancelled",
  "Disputed",
];

const { address } = useAccount();

const isClient = address?.toLowerCase() === job?.client?.toLowerCase();
const isFreelancer = address?.toLowerCase() === job?.freelancer?.toLowerCase();
const { writeContractAsync } = useScaffoldWriteContract("FreelanceEscrow");


const acceptJob = async () => {
  await writeContractAsync({
    functionName: "acceptJob",
    args: [jobId],
  });
};

const cancelJob = async () => {
  await writeContractAsync({
    functionName: "cancelJob",
    args: [jobId],
  });
};

const raiseDispute = async () => {
  await writeContractAsync({
    functionName: "raiseDispute",
    args: [jobId],
  });
};

const submitMilestone = async () => {
  await writeContractAsync({
    functionName: "submitMilestone",
    args: [jobId],
  });
};

const approveMilestone = async () => {
  await writeContractAsync({
    functionName: "approveMilestone",
    args: [jobId],
  });
};

const rejectMilestone = async () => {
  await writeContractAsync({
    functionName: "rejectMilestone",
    args: [jobId],
  });
};


const JobDetails: NextPage = () => {
  const router = useRouter();
  const { id } = router.query;
  const jobId = Number(id);

  const { address } = useAccount();

  // Job data
  const { data: job } = useScaffoldReadContract({
    contractName: "FreelanceEscrow",
    functionName: "jobs",
    args: [jobId],
  });

  // Current milestone
  const { data: milestone } = useScaffoldReadContract({
    contractName: "FreelanceEscrow",
    functionName: "getCurrentMilestone",
    args: [jobId],
  });

  const { data: milestonesData } = useScaffoldReadContract({
  contractName: "FreelanceEscrow",
  functionName: "milestones",
  args: [jobId],
  watch: true,
});





  // Write actions
  const { writeContractAsync: submitMilestone } =
    useScaffoldWriteContract("FreelanceEscrow");

  const { writeContractAsync: approveMilestone } =
    useScaffoldWriteContract("FreelanceEscrow");

  if (!job?.exists) return <p className="p-10">Job not found</p>;

  const isClient = address?.toLowerCase() === job.client.toLowerCase();
  const isFreelancer =
    address?.toLowerCase() === job.freelancer.toLowerCase();

  return (
    <div className="p-10 max-w-4xl mx-auto">
      <h1 className="text-3xl font-bold mb-6">Job #{jobId}</h1>

      {/* Job Info */}
      <div className="border rounded-lg p-4 mb-6">
        <p>
          <strong>Status:</strong>{" "}
          {jobStatusMap[Number(job.status)]}
        </p>
        <p>
          <strong>Client:</strong>{" "}
          <Address address={job.client} />
        </p>
        <p>
          <strong>Freelancer:</strong>{" "}
          <Address address={job.freelancer} />
        </p>
        <p>
          <strong>Total Amount:</strong>{" "}
          <Balance value={job.totalAmount} />
        </p>
        <p>
          <strong>Current Milestone:</strong>{" "}
          {Number(job.currentMilestone)}
        </p>
      </div>

      {/* Milestones Stepper */}
<div className="border rounded-lg p-4 mt-6">
  <h2 className="text-xl font-semibold mb-4">Milestones</h2>

  {milestonesData?.map((ms: { title: string | number | bigint | boolean | ReactElement<unknown, string | JSXElementConstructor<any>> | Iterable<ReactNode> | ReactPortal | Promise<string | number | bigint | boolean | ReactPortal | ReactElement<unknown, string | JSXElementConstructor<any>> | Iterable<ReactNode> | null | undefined> | null | undefined; amount: any; status: any; }, index: Key | null | undefined) => (
    <div
      key={index}
      className={`p-3 mb-3 border rounded ${
        index === Number(job.currentMilestone)
          ? "border-primary bg-base-200"
          : "border-base-300"
      }`}
    >
      <div className="flex justify-between">
        <div>
          <p className="font-medium">
            {index + 1}. {ms.title}
          </p>
          <p className="text-sm opacity-80">
            <Balance value={ms.amount} />
          </p>
        </div>

        <span className="badge badge-outline">
          {["Pending", "Submitted", "Approved", "Rejected", "Paid"][
            Number(ms.status)
          ]}
        </span>
      </div>
    </div>
  ))}
</div>


      {/* Milestone Section */}
      {milestone && (
        <div className="border rounded-lg p-4">
          <h2 className="text-xl font-semibold mb-2">
            Current Milestone
          </h2>
          <p>
            <strong>Title:</strong> {milestone.title}
          </p>
          <p>
            <strong>Amount:</strong>{" "}
            <Balance value={milestone.amount} />
          </p>
          <p>
            <strong>Status:</strong>{" "}
            {["Pending", "Submitted", "Approved", "Rejected", "Paid"][
              Number(milestone.status)
            ]}
          </p>

          {/* Actions */}
          <div className="mt-4 flex gap-3">
            {isFreelancer &&
              Number(job.status) === 1 &&
              Number(milestone.status) === 0 && (
                <button
                  className="btn btn-primary"
                  onClick={() =>
                    submitMilestone({
                      functionName: "submitMilestone",
                      args: [jobId],
                    })
                  }
                >
                  Submit Milestone
                </button>
              )}

            {isClient &&
              Number(milestone.status) === 1 && (
                <>
                  <button
                    className="btn btn-success"
                    onClick={() =>
                      approveMilestone({
                        functionName: "approveMilestone",
                        args: [jobId],
                      })
                    }
                  >
                    Approve
                  </button>

                  <button
                    className="btn btn-error"
                    onClick={() =>
                      approveMilestone({
                        functionName: "rejectMilestone",
                        args: [jobId],
                      })
                    }
                  >
                    Reject
                  </button>
                </>
              )}
          </div>
        </div>
      )}


      <div className="mt-6 space-y-3">
  <h2 className="text-xl font-semibold">Actions</h2>

  {/* Freelancer accepts job */}
  {job.status === 0 && isFreelancer && (
    <button className="btn btn-primary w-full" onClick={acceptJob}>
      Accept Job
    </button>
  )}

  {/* Freelancer submits milestone */}
  {job.status === 1 && isFreelancer && (
    <button className="btn btn-secondary w-full" onClick={submitMilestone}>
      Submit Milestone
    </button>
  )}

  {/* Client approves / rejects */}
  {job.status === 1 && isClient && (
    <div className="flex gap-2">
      <button className="btn btn-success flex-1" onClick={approveMilestone}>
        Approve Milestone
      </button>
      <button className="btn btn-warning flex-1" onClick={rejectMilestone}>
        Reject Milestone
      </button>
    </div>
  )}

  {/* Cancel job */}
  {(job.status === 0 || job.status === 1) && isClient && (
    <button className="btn btn-error w-full" onClick={cancelJob}>
      Cancel Job
    </button>
  )}

  {/* Raise dispute */}
  {(job.status === 1 || job.status === 3) && (isClient || isFreelancer) && (
    <button className="btn btn-outline w-full" onClick={raiseDispute}>
      Raise Dispute
    </button>
  )}
</div>

    </div>
  );
};

export default JobDetails;

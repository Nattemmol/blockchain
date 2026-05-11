"use client";

import { useIsAdmin } from "~~/hooks/useIsAdmin";
import RegisterVehicleForm from "~~/components/RegisterVehicleForm";

export default function AdminPage() {
  const { isAdmin, admin } = useIsAdmin();

  if (!isAdmin) {
    return (
      <div className="p-8 text-center">
        <h2 className="text-xl font-semibold">Access Denied</h2>
        <p className="mt-2 text-gray-500">
          This section is restricted to the system administrator.
        </p>
        <p className="text-sm mt-1">
          Admin Address: {admin}
        </p>
      </div>
    );
  }

  return (
    <div className="p-8 max-w-xl mx-auto">
      <h1 className="text-2xl font-bold mb-4">Admin Panel</h1>
      <RegisterVehicleForm />
    </div>
  );
}

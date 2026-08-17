import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.45.0";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

interface CreateStaffRequest {
  name: string;
  phone?: string;
  email: string;
  employee_id: string;
  department: string;
  role?: string;
  zone?: string;
  ward?: string;
  password?: string;
}

const ALLOWED_DEPARTMENTS = ["ROAD", "WASTE", "WATER", "VENDOR", "GENERAL"];
const ALLOWED_ROLES = ["FIELD_WORKER", "SUPERVISOR", "OFFICER"];

serve(async (req: Request) => {
  // Handle CORS preflight
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  if (req.method !== "POST") {
    return new Response(
      JSON.stringify({ error: "Method not allowed. Use POST." }),
      {
        status: 405,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  }

  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const supabaseServiceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

    if (!supabaseUrl || !supabaseServiceRoleKey) {
      console.error("Missing SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY env vars");
      return new Response(
        JSON.stringify({ error: "Internal server configuration error." }),
        {
          status: 500,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // 1. Verify Caller Authentication & Identity
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return new Response(
        JSON.stringify({ error: "Missing Authorization header." }),
        {
          status: 401,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    const token = authHeader.replace("Bearer ", "").trim();

    // Client scoped to caller's JWT
    const callerClient = createClient(supabaseUrl, supabaseServiceRoleKey, {
      auth: { persistSession: false },
    });

    const {
      data: { user: callerUser },
      error: userAuthError,
    } = await callerClient.auth.getUser(token);

    if (userAuthError || !callerUser) {
      return new Response(
        JSON.stringify({ error: "Invalid or expired session token." }),
        {
          status: 401,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // 2. Server-side Admin Authorization Verification
    const { data: adminProfile, error: adminQueryError } = await callerClient
      .from("admin_profiles")
      .select("id, name, role, is_active")
      .eq("id", callerUser.id)
      .eq("is_active", true)
      .maybeSingle();

    if (adminQueryError || !adminProfile) {
      return new Response(
        JSON.stringify({
          error: "Unauthorized: Caller is not an active administrator.",
        }),
        {
          status: 403,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    const permittedRoles = ["superAdmin", "userManager"];
    if (!permittedRoles.includes(adminProfile.role)) {
      return new Response(
        JSON.stringify({
          error:
            "Forbidden: Only Super Admins or User Managers can create staff accounts.",
        }),
        {
          status: 403,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // 3. Parse and Validate Request Payload
    let body: CreateStaffRequest;
    try {
      body = await req.json();
    } catch {
      return new Response(
        JSON.stringify({ error: "Invalid JSON body." }),
        {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    const name = (body.name || "").trim();
    const phone = (body.phone || "").trim();
    const email = (body.email || "").trim().toLowerCase();
    const employee_id = (body.employee_id || "").trim().toUpperCase();
    const department = (body.department || "").trim().toUpperCase();
    const role = (body.role || "FIELD_WORKER").trim().toUpperCase();
    const zone = (body.zone || "ALL").trim();
    const ward = (body.ward || "").trim();
    const password = (body.password || "").trim();

    if (!name || name.length < 1 || name.length > 120) {
      return new Response(
        JSON.stringify({ error: "Staff name must be between 1 and 120 characters." }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const emailRegex = /^[^@\s]+@[^@\s]+\.[^@\s]+$/;
    if (!email || !emailRegex.test(email) || email.length > 320) {
      return new Response(
        JSON.stringify({ error: "Invalid email format." }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    if (!employee_id || employee_id.length < 2 || employee_id.length > 40) {
      return new Response(
        JSON.stringify({ error: "Employee ID must be between 2 and 40 characters." }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    if (!ALLOWED_DEPARTMENTS.includes(department)) {
      return new Response(
        JSON.stringify({
          error: `Invalid department. Allowed: ${ALLOWED_DEPARTMENTS.join(", ")}`,
        }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    if (!ALLOWED_ROLES.includes(role)) {
      return new Response(
        JSON.stringify({
          error: `Invalid role. Allowed: ${ALLOWED_ROLES.join(", ")}`,
        }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    if (phone && !/^[0-9+() -]{5,32}$/.test(phone)) {
      return new Response(
        JSON.stringify({ error: "Invalid phone number format." }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Password generation or verification
    const finalPassword =
      password.length >= 8
        ? password
        : `Staff@${crypto.randomUUID().substring(0, 8)}!`;

    // 4. Check for Existing Duplicate Email or Employee ID
    const { data: existingStaff } = await callerClient
      .from("staff_profiles")
      .select("id, email, employee_id")
      .or(`email.eq.${email},employee_id.eq.${employee_id}`)
      .maybeSingle();

    if (existingStaff) {
      if (existingStaff.email === email) {
        return new Response(
          JSON.stringify({ error: "A staff member with this email already exists." }),
          { status: 409, headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
      }
      if (existingStaff.employee_id === employee_id) {
        return new Response(
          JSON.stringify({ error: "A staff member with this Employee ID already exists." }),
          { status: 409, headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
      }
    }

    // 5. Server-Side Supabase Auth Admin API Invocation
    const adminServiceClient = createClient(supabaseUrl, supabaseServiceRoleKey, {
      auth: { autoRefreshToken: false, persistSession: false },
    });

    const { data: authCreatedUser, error: authCreationError } =
      await adminServiceClient.auth.admin.createUser({
        email,
        password: finalPassword,
        email_confirm: true,
        user_metadata: {
          name,
          employee_id,
          department,
          role,
        },
      });

    if (authCreationError || !authCreatedUser?.user) {
      console.error("Auth user creation failed:", authCreationError);
      return new Response(
        JSON.stringify({
          error: authCreationError?.message || "Failed to create authentication user.",
        }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const newStaffUserId = authCreatedUser.user.id;

    // 6. Atomic Staff Profile Insertion
    const { error: profileInsertError } = await adminServiceClient
      .from("staff_profiles")
      .insert({
        id: newStaffUserId,
        name,
        phone,
        email,
        employee_id,
        department,
        role,
        zone,
        ward,
        is_active: true,
        is_on_duty: false,
        created_by: callerUser.id,
      });

    // 7. Atomic Rollback on Failure (Prevent Orphaned Auth Accounts)
    if (profileInsertError) {
      console.error("Profile insertion failed, rolling back auth user:", profileInsertError);
      await adminServiceClient.auth.admin.deleteUser(newStaffUserId);

      return new Response(
        JSON.stringify({
          error: "Failed to create staff profile record. Rolled back successfully.",
        }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // 8. Audit Logging (Safe — No Passwords Logged)
    try {
      await adminServiceClient.from("admin_notifications").insert({
        id: `AUDIT-STAFF-${crypto.randomUUID()}`,
        title: "Staff Member Provisioned",
        body: `Staff account created for ${name} (${employee_id}) in ${department} department (${role}) by admin ${adminProfile.name}.`,
        category: "important",
        sender_id: callerUser.id,
      });
    } catch (auditErr) {
      console.warn("Audit log insertion non-fatal warning:", auditErr);
    }

    // 9. Success Response
    return new Response(
      JSON.stringify({
        success: true,
        message: "Staff member provisioned successfully.",
        staff: {
          id: newStaffUserId,
          name,
          email,
          employee_id,
          department,
          role,
          zone,
          ward,
          is_active: true,
        },
      }),
      {
        status: 201,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  } catch (err: unknown) {
    const errorMsg = err instanceof Error ? err.message : "Internal server error";
    console.error("Unhandled error in admin-create-staff:", err);
    return new Response(
      JSON.stringify({ error: errorMsg }),
      {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  }
});

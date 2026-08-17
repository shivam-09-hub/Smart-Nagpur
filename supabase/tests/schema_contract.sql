-- Run after the migration. Any contract violation raises an exception.
begin;

do $$
declare
  missing_tables text;
  missing_columns text;
  insecure_functions text;
  wrong_arguments text;
begin
  select string_agg(expected.table_name, ', ' order by expected.table_name)
  into missing_tables
  from unnest(array[
    'profiles',
    'complaints',
    'complaint_photos',
    'complaint_timeline',
    'vendor_applications',
    'vendor_documents',
    'vendor_timeline',
    'notifications'
  ]) as expected(table_name)
  where to_regclass('public.' || expected.table_name) is null;

  if missing_tables is not null then
    raise exception 'Missing tables: %', missing_tables;
  end if;

  select string_agg(
    expected.table_name || '.' || expected.column_name,
    ', ' order by expected.table_name, expected.column_name
  )
  into missing_columns
  from (
    values
      ('profiles', 'id'),
      ('profiles', 'name'),
      ('profiles', 'phone'),
      ('profiles', 'email'),
      ('profiles', 'address'),
      ('profiles', 'avatar_path'),
      ('complaints', 'public_id'),
      ('complaints', 'owner_id'),
      ('complaints', 'status'),
      ('complaint_photos', 'object_path'),
      ('complaint_timeline', 'occurred_at'),
      ('vendor_applications', 'public_id'),
      ('vendor_applications', 'owner_id'),
      ('vendor_applications', 'status'),
      ('vendor_documents', 'object_path'),
      ('vendor_timeline', 'is_current'),
      ('notifications', 'owner_id'),
      ('notifications', 'is_read')
  ) as expected(table_name, column_name)
  where not exists (
    select 1
    from information_schema.columns as actual
    where actual.table_schema = 'public'
      and actual.table_name = expected.table_name
      and actual.column_name = expected.column_name
  );

  if missing_columns is not null then
    raise exception 'Missing columns: %', missing_columns;
  end if;

  if exists (
    select 1
    from pg_class as relation
    join pg_namespace as namespace on namespace.oid = relation.relnamespace
    where namespace.nspname = 'public'
      and relation.relname = any(array[
        'profiles',
        'complaints',
        'complaint_photos',
        'complaint_timeline',
        'vendor_applications',
        'vendor_documents',
        'vendor_timeline',
        'notifications'
      ])
      and not relation.relrowsecurity
  ) then
    raise exception 'RLS is not enabled on every public application table.';
  end if;

  if to_regprocedure('public.submit_complaint(jsonb,jsonb)') is null or
     to_regprocedure('public.submit_vendor_application(jsonb,jsonb)') is null or
     to_regprocedure('public.get_current_user_data()') is null then
    raise exception 'One or more public RPCs are missing.';
  end if;

  select string_agg(rpc.proname, ', ' order by rpc.proname)
  into insecure_functions
  from pg_proc as rpc
  join pg_namespace as namespace on namespace.oid = rpc.pronamespace
  where namespace.nspname = 'public'
    and rpc.proname = any(array[
      'submit_complaint',
      'submit_vendor_application',
      'get_current_user_data'
    ])
    and (
      not rpc.prosecdef or
      coalesce(array_to_string(rpc.proconfig, ','), '') not like '%search_path=%'
    );

  if insecure_functions is not null then
    raise exception 'RPCs missing SECURITY DEFINER/fixed search_path: %',
      insecure_functions;
  end if;

  select string_agg(rpc.proname, ', ' order by rpc.proname)
  into wrong_arguments
  from pg_proc as rpc
  join pg_namespace as namespace on namespace.oid = rpc.pronamespace
  where namespace.nspname = 'public'
    and (
      (
        rpc.proname = 'submit_complaint' and
        (
          select array_agg(argument_name order by ordinality)
          from unnest(rpc.proargnames) with ordinality
            as argument(argument_name, ordinality)
        ) is distinct from array['payload', 'attachments']::text[]
      ) or
      (
        rpc.proname = 'submit_vendor_application' and
        (
          select array_agg(argument_name order by ordinality)
          from unnest(rpc.proargnames) with ordinality
            as argument(argument_name, ordinality)
        ) is distinct from array['payload', 'documents']::text[]
      )
    );

  if wrong_arguments is not null then
    raise exception 'RPC argument-name mismatch: %', wrong_arguments;
  end if;

  if not exists (
    select 1 from pg_trigger
    where tgname = 'on_auth_user_created' and not tgisinternal
  ) or not exists (
    select 1 from pg_trigger
    where tgname = 'on_auth_user_email_updated' and not tgisinternal
  ) then
    raise exception 'An auth.users profile synchronization trigger is missing.';
  end if;

  if not exists (
    select 1 from storage.buckets
    where id = 'complaint-photos' and not public and file_size_limit = 10485760
  ) or not exists (
    select 1 from storage.buckets
    where id = 'vendor-documents' and not public and file_size_limit = 10485760
  ) then
    raise exception 'Private Storage bucket configuration is missing or unsafe.';
  end if;

  if has_table_privilege('authenticated', 'public.profiles', 'INSERT') or
     has_table_privilege('authenticated', 'public.complaints', 'INSERT') or
     has_table_privilege('authenticated', 'public.complaints', 'UPDATE') or
     has_table_privilege('authenticated', 'public.vendor_applications', 'INSERT') or
     has_table_privilege('authenticated', 'public.vendor_applications', 'UPDATE') then
    raise exception 'Authenticated has a forbidden workflow table privilege.';
  end if;

  if exists (
    select 1
    from unnest(array[
      'complaints',
      'complaint_photos',
      'complaint_timeline',
      'vendor_applications',
      'vendor_documents',
      'vendor_timeline'
    ]) as workflow(table_name)
    where has_any_column_privilege(
      'authenticated', 'public.' || workflow.table_name, 'INSERT'
    ) or has_any_column_privilege(
      'authenticated', 'public.' || workflow.table_name, 'UPDATE'
    ) or has_table_privilege(
      'authenticated', 'public.' || workflow.table_name, 'DELETE'
    )
  ) then
    raise exception 'Authenticated has a forbidden child/workflow write grant.';
  end if;

  if exists (
    select 1
    from pg_policies
    where schemaname = 'public'
      and tablename = any(array[
        'complaints',
        'complaint_photos',
        'complaint_timeline',
        'vendor_applications',
        'vendor_documents',
        'vendor_timeline'
      ])
      and cmd <> 'SELECT'
      and policyname not like 'admin_%'
  ) then
    raise exception 'Workflow tables contain a citizen write policy.';
  end if;


  if (
    select count(*)
    from pg_policies
    where schemaname = 'public'
      and policyname = any(array[
        'profiles_select_own',
        'profiles_update_own',
        'complaints_select_own',
        'complaint_photos_select_own',
        'complaint_timeline_select_own',
        'vendor_applications_select_own',
        'vendor_documents_select_own',
        'vendor_timeline_select_own',
        'notifications_select_own',
        'notifications_update_own'
      ])
  ) <> 10 then
    raise exception 'One or more owner-scoped public-table policies are missing.';
  end if;

  if not has_column_privilege(
    'authenticated', 'public.profiles', 'name', 'UPDATE'
  ) or has_column_privilege(
    'authenticated', 'public.profiles', 'email', 'UPDATE'
  ) or has_column_privilege(
    'authenticated', 'public.profiles', 'avatar_path', 'UPDATE'
  ) or not has_column_privilege(
    'authenticated', 'public.notifications', 'is_read', 'UPDATE'
  ) or has_column_privilege(
    'authenticated', 'public.notifications', 'title', 'UPDATE'
  ) then
    raise exception 'Column-level update grants do not match the contract.';
  end if;

  if has_function_privilege(
    'anon', 'public.submit_complaint(jsonb,jsonb)', 'EXECUTE'
  ) or not has_function_privilege(
    'authenticated', 'public.submit_complaint(jsonb,jsonb)', 'EXECUTE'
  ) or not has_function_privilege(
    'authenticated',
    'public.submit_vendor_application(jsonb,jsonb)',
    'EXECUTE'
  ) or not has_function_privilege(
    'authenticated', 'public.get_current_user_data()', 'EXECUTE'
  ) then
    raise exception 'RPC execute grants do not match the contract.';
  end if;

  if exists (
    select 1
    from pg_policies
    where schemaname = 'storage'
      and tablename = 'objects'
      and policyname in (
        'complaint_photos_storage_update_own',
        'vendor_documents_storage_update_own'
      )
  ) then
    raise exception 'Private evidence objects must not have UPDATE policies.';
  end if;

  if exists (
    select 1
    from pg_policies
    where schemaname = 'storage'
      and tablename = 'objects'
      and policyname in (
        'complaint_photos_storage_insert_own',
        'vendor_documents_storage_insert_own'
      )
      and (
        coalesce(with_check, '') not like '%owner_id%' or
        coalesce(with_check, '') not like '%split_part%' or
        coalesce(with_check, '') not like '%array_length%' or
        coalesce(with_check, '') not like '%mimetype%'
      )
  ) or (
    select count(*)
    from pg_policies
    where schemaname = 'storage'
      and tablename = 'objects'
      and policyname in (
        'complaint_photos_storage_insert_own',
        'vendor_documents_storage_insert_own'
      )
  ) <> 2 then
    raise exception 'Storage INSERT policies do not enforce owner and exact object paths.';
  end if;
end;
$$;

select 'Smart Nagpur schema contract: OK' as result;

rollback;

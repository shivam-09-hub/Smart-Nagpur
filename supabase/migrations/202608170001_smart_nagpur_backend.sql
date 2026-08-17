begin;

create schema if not exists extensions;
create extension if not exists pgcrypto with schema extensions;

create sequence if not exists public.complaint_reference_seq;
create sequence if not exists public.vendor_reference_seq;

create or replace function public.next_complaint_reference()
returns text
language sql
volatile
security definer
set search_path = ''
as $$
  select 'NAG-' || pg_catalog.to_char(pg_catalog.clock_timestamp(), 'YYYY') ||
    '-' || case
      when char_length(generated.sequence_text) < 6
        then pg_catalog.lpad(generated.sequence_text, 6, '0')
      else generated.sequence_text
    end
  from (
    select pg_catalog.nextval('public.complaint_reference_seq')::text
      as sequence_text
  ) as generated;
$$;

create or replace function public.next_vendor_reference()
returns text
language sql
volatile
security definer
set search_path = ''
as $$
  select 'VN-' || pg_catalog.to_char(pg_catalog.clock_timestamp(), 'YYYY') ||
    '-' || case
      when char_length(generated.sequence_text) < 6
        then pg_catalog.lpad(generated.sequence_text, 6, '0')
      else generated.sequence_text
    end
  from (
    select pg_catalog.nextval('public.vendor_reference_seq')::text
      as sequence_text
  ) as generated;
$$;

create or replace function public.set_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at := pg_catalog.clock_timestamp();
  return new;
end;
$$;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  name text not null default 'Citizen',
  phone text not null default '',
  email text not null default '',
  address text not null default '',
  avatar_path text,
  created_at timestamptz not null default pg_catalog.clock_timestamp(),
  updated_at timestamptz not null default pg_catalog.clock_timestamp(),
  constraint profiles_name_length check (
    char_length(btrim(name)) between 1 and 120
  ),
  constraint profiles_phone_length check (
    phone = '' or phone ~ '^[0-9+() -]{5,32}$'
  ),
  constraint profiles_email_length check (
    email = '' or (
      char_length(email) between 3 and 320 and
      email ~ '^[^[:space:]@]+@[^[:space:]@]+\.[^[:space:]@]+$'
    )
  ),
  constraint profiles_address_length check (char_length(address) <= 500),
  constraint profiles_avatar_path_length check (
    avatar_path is null or char_length(avatar_path) <= 1024
  )
);

create table if not exists public.complaints (
  id uuid primary key default gen_random_uuid(),
  public_id text not null default public.next_complaint_reference(),
  owner_id uuid not null references auth.users(id) on delete cascade,
  service_type text not null,
  issue text not null,
  description text not null,
  latitude double precision not null,
  longitude double precision not null,
  accuracy double precision not null,
  location_address text not null,
  contact_phone text not null,
  citizen_address text,
  extra_fields jsonb not null default '{}'::jsonb,
  status text not null default 'submitted',
  created_at timestamptz not null default pg_catalog.clock_timestamp(),
  updated_at timestamptz not null default pg_catalog.clock_timestamp(),
  constraint complaints_public_id_unique unique (public_id),
  constraint complaints_id_owner_unique unique (id, owner_id),
  constraint complaints_service_type_valid check (
    service_type in (
      'vendor', 'garbage', 'water', 'roads', 'animals', 'drainage',
      'streetlights', 'publicSpaces', 'encroachment', 'other'
    )
  ),
  constraint complaints_issue_valid check (
    char_length(btrim(issue)) between 1 and 160
  ),
  constraint complaints_description_valid check (
    char_length(btrim(description)) between 1 and 5000
  ),
  constraint complaints_latitude_valid check (latitude between -90 and 90),
  constraint complaints_longitude_valid check (longitude between -180 and 180),
  constraint complaints_accuracy_valid check (accuracy between 0 and 100000),
  constraint complaints_location_address_valid check (
    char_length(btrim(location_address)) between 1 and 500
  ),
  constraint complaints_contact_phone_valid check (
    contact_phone ~ '^[0-9+() -]{5,32}$'
  ),
  constraint complaints_citizen_address_valid check (
    citizen_address is null or char_length(citizen_address) <= 500
  ),
  constraint complaints_extra_fields_object check (
    jsonb_typeof(extra_fields) = 'object' and
    pg_column_size(extra_fields) <= 16384
  ),
  constraint complaints_status_valid check (
    status in (
      'submitted', 'underReview', 'assigned', 'inProgress', 'resolved',
      'rejected', 'moreInformationRequired'
    )
  )
);

create table if not exists public.complaint_photos (
  id uuid primary key default gen_random_uuid(),
  complaint_id uuid not null,
  owner_id uuid not null,
  bucket_id text not null default 'complaint-photos',
  object_path text not null,
  original_name text not null,
  content_type text not null,
  byte_size bigint not null,
  sort_order smallint not null default 0,
  created_at timestamptz not null default pg_catalog.clock_timestamp(),
  constraint complaint_photos_parent_owner_fk
    foreign key (complaint_id, owner_id)
    references public.complaints(id, owner_id)
    on delete cascade,
  constraint complaint_photos_object_unique unique (bucket_id, object_path),
  constraint complaint_photos_order_unique unique (complaint_id, sort_order),
  constraint complaint_photos_bucket_valid check (bucket_id = 'complaint-photos'),
  constraint complaint_photos_path_valid check (
    split_part(object_path, '/', 1) = owner_id::text and
    split_part(object_path, '/', 2) ~* '^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$' and
    split_part(object_path, '/', 3) ~* '^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}\.(jpg|jpeg|png|webp)$' and
    pg_catalog.array_length(pg_catalog.string_to_array(object_path, '/'), 1) = 3 and
    object_path not like '%//%' and
    object_path !~ '(^|/)\.{1,2}(/|$)' and
    position(chr(92) in object_path) = 0 and
    char_length(object_path) <= 1024
  ),
  constraint complaint_photos_name_valid check (
    char_length(btrim(original_name)) between 1 and 255
  ),
  constraint complaint_photos_content_type_valid check (
    content_type in (
      'image/jpeg', 'image/png', 'image/webp'
    )
  ),
  constraint complaint_photos_size_valid check (
    byte_size between 1 and 10485760
  ),
  constraint complaint_photos_order_valid check (sort_order between 0 and 9)
);

create table if not exists public.complaint_timeline (
  id uuid primary key default gen_random_uuid(),
  complaint_id uuid not null,
  owner_id uuid not null,
  title text not null,
  occurred_at timestamptz not null default pg_catalog.clock_timestamp(),
  message text,
  is_completed boolean not null default true,
  created_at timestamptz not null default pg_catalog.clock_timestamp(),
  constraint complaint_timeline_parent_owner_fk
    foreign key (complaint_id, owner_id)
    references public.complaints(id, owner_id)
    on delete cascade,
  constraint complaint_timeline_title_valid check (
    char_length(btrim(title)) between 1 and 160
  ),
  constraint complaint_timeline_message_valid check (
    message is null or char_length(message) <= 2000
  )
);

create table if not exists public.vendor_applications (
  id uuid primary key default gen_random_uuid(),
  public_id text not null default public.next_vendor_reference(),
  owner_id uuid not null references auth.users(id) on delete cascade,
  applicant_name text not null,
  mobile text not null,
  email text not null,
  residential_address text not null,
  identity_information text not null,
  business_name text not null,
  business_type text not null,
  category text not null,
  description text not null,
  products_services text not null,
  registration_number text not null default '',
  latitude double precision not null,
  longitude double precision not null,
  accuracy double precision not null,
  location_address text not null,
  preferred_zone text not null default '',
  operating_days text[] not null,
  start_time time without time zone not null,
  end_time time without time zone not null,
  duration_type text not null,
  outlet_type text not null,
  accepted_declaration boolean not null,
  status text not null default 'submitted',
  created_at timestamptz not null default pg_catalog.clock_timestamp(),
  updated_at timestamptz not null default pg_catalog.clock_timestamp(),
  constraint vendor_applications_public_id_unique unique (public_id),
  constraint vendor_applications_id_owner_unique unique (id, owner_id),
  constraint vendor_applications_applicant_name_valid check (
    char_length(btrim(applicant_name)) between 1 and 120
  ),
  constraint vendor_applications_mobile_valid check (
    mobile ~ '^[0-9+() -]{5,32}$'
  ),
  constraint vendor_applications_email_valid check (
    char_length(email) between 3 and 320 and
    email ~ '^[^[:space:]@]+@[^[:space:]@]+\.[^[:space:]@]+$'
  ),
  constraint vendor_applications_residential_address_valid check (
    char_length(btrim(residential_address)) between 1 and 500
  ),
  constraint vendor_applications_identity_information_valid check (
    char_length(btrim(identity_information)) between 1 and 2000
  ),
  constraint vendor_applications_business_name_valid check (
    char_length(btrim(business_name)) between 1 and 160
  ),
  constraint vendor_applications_business_type_valid check (
    char_length(btrim(business_type)) between 1 and 120
  ),
  constraint vendor_applications_category_valid check (
    char_length(btrim(category)) between 1 and 120
  ),
  constraint vendor_applications_description_valid check (
    char_length(btrim(description)) between 1 and 5000
  ),
  constraint vendor_applications_products_services_valid check (
    char_length(btrim(products_services)) between 1 and 2000
  ),
  constraint vendor_applications_registration_number_valid check (
    char_length(registration_number) <= 120
  ),
  constraint vendor_applications_latitude_valid check (latitude between -90 and 90),
  constraint vendor_applications_longitude_valid check (longitude between -180 and 180),
  constraint vendor_applications_accuracy_valid check (accuracy between 0 and 100000),
  constraint vendor_applications_location_address_valid check (
    char_length(btrim(location_address)) between 1 and 500
  ),
  constraint vendor_applications_preferred_zone_valid check (
    char_length(preferred_zone) <= 160
  ),
  constraint vendor_applications_operating_days_valid check (
    cardinality(operating_days) between 1 and 7 and
    operating_days <@ array[
      'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
    ]::text[]
  ),
  constraint vendor_applications_operating_times_valid check (
    start_time <> end_time
  ),
  constraint vendor_applications_duration_type_valid check (
    duration_type in ('Temporary', 'Permanent')
  ),
  constraint vendor_applications_outlet_type_valid check (
    outlet_type in ('Stall', 'Cart', 'Shop', 'Other')
  ),
  constraint vendor_applications_declaration_valid check (accepted_declaration),
  constraint vendor_applications_status_valid check (
    status in (
      'submitted', 'documentsVerified', 'underReview', 'locationAssessment',
      'approved', 'changesRequired', 'rejected', 'permissionIssued'
    )
  )
);

create table if not exists public.vendor_documents (
  id uuid primary key default gen_random_uuid(),
  vendor_application_id uuid not null,
  owner_id uuid not null,
  document_type text not null,
  label text not null,
  requirement text not null,
  bucket_id text not null default 'vendor-documents',
  object_path text not null,
  original_name text not null,
  content_type text not null,
  byte_size bigint not null,
  sort_order smallint not null default 0,
  created_at timestamptz not null default pg_catalog.clock_timestamp(),
  constraint vendor_documents_parent_owner_fk
    foreign key (vendor_application_id, owner_id)
    references public.vendor_applications(id, owner_id)
    on delete cascade,
  constraint vendor_documents_type_unique unique (
    vendor_application_id,
    document_type
  ),
  constraint vendor_documents_object_unique unique (bucket_id, object_path),
  constraint vendor_documents_order_unique unique (
    vendor_application_id,
    sort_order
  ),
  constraint vendor_documents_type_valid check (
    char_length(btrim(document_type)) between 1 and 80
  ),
  constraint vendor_documents_label_valid check (
    char_length(btrim(label)) between 1 and 160
  ),
  constraint vendor_documents_requirement_valid check (
    requirement in ('required', 'optional', 'conditional')
  ),
  constraint vendor_documents_bucket_valid check (bucket_id = 'vendor-documents'),
  constraint vendor_documents_path_valid check (
    split_part(object_path, '/', 1) = owner_id::text and
    split_part(object_path, '/', 2) ~* '^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$' and
    split_part(object_path, '/', 3) ~* '^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}\.(pdf|jpg|jpeg|png)$' and
    pg_catalog.array_length(pg_catalog.string_to_array(object_path, '/'), 1) = 3 and
    object_path not like '%//%' and
    object_path !~ '(^|/)\.{1,2}(/|$)' and
    position(chr(92) in object_path) = 0 and
    char_length(object_path) <= 1024
  ),
  constraint vendor_documents_name_valid check (
    char_length(btrim(original_name)) between 1 and 255
  ),
  constraint vendor_documents_content_type_valid check (
    content_type in ('application/pdf', 'image/jpeg', 'image/png')
  ),
  constraint vendor_documents_size_valid check (
    byte_size between 1 and 10485760
  ),
  constraint vendor_documents_order_valid check (sort_order between 0 and 19)
);

create table if not exists public.vendor_timeline (
  id uuid primary key default gen_random_uuid(),
  vendor_application_id uuid not null,
  owner_id uuid not null,
  title text not null,
  occurred_at timestamptz,
  message text,
  is_completed boolean not null default false,
  is_current boolean not null default false,
  created_at timestamptz not null default pg_catalog.clock_timestamp(),
  constraint vendor_timeline_parent_owner_fk
    foreign key (vendor_application_id, owner_id)
    references public.vendor_applications(id, owner_id)
    on delete cascade,
  constraint vendor_timeline_title_valid check (
    char_length(btrim(title)) between 1 and 160
  ),
  constraint vendor_timeline_message_valid check (
    message is null or char_length(message) <= 2000
  ),
  constraint vendor_timeline_timestamp_valid check (
    occurred_at is not null or (not is_completed and not is_current)
  )
);

create table if not exists public.notifications (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users(id) on delete cascade,
  title text not null,
  body text not null,
  category text not null,
  destination text not null default 'none',
  reference_id text,
  is_read boolean not null default false,
  created_at timestamptz not null default pg_catalog.clock_timestamp(),
  updated_at timestamptz not null default pg_catalog.clock_timestamp(),
  constraint notifications_title_valid check (
    char_length(btrim(title)) between 1 and 160
  ),
  constraint notifications_body_valid check (
    char_length(btrim(body)) between 1 and 2000
  ),
  constraint notifications_category_valid check (
    category in ('important', 'requests', 'cityUpdates')
  ),
  constraint notifications_destination_valid check (
    destination in ('none', 'complaint', 'vendorApplication', 'news', 'services')
  ),
  constraint notifications_reference_valid check (
    reference_id is null or char_length(reference_id) between 1 and 160
  )
);

create index if not exists complaints_owner_created_idx
  on public.complaints(owner_id, created_at desc);
create index if not exists complaints_owner_status_idx
  on public.complaints(owner_id, status);
create index if not exists complaint_photos_parent_idx
  on public.complaint_photos(complaint_id, sort_order);
create index if not exists complaint_timeline_parent_time_idx
  on public.complaint_timeline(complaint_id, occurred_at, created_at);
create index if not exists vendor_applications_owner_created_idx
  on public.vendor_applications(owner_id, created_at desc);
create index if not exists vendor_applications_owner_status_idx
  on public.vendor_applications(owner_id, status);
create index if not exists vendor_documents_parent_idx
  on public.vendor_documents(vendor_application_id, sort_order);
create index if not exists vendor_timeline_parent_time_idx
  on public.vendor_timeline(vendor_application_id, occurred_at, created_at);
create unique index if not exists vendor_timeline_one_current_idx
  on public.vendor_timeline(vendor_application_id)
  where is_current;
create index if not exists notifications_owner_created_idx
  on public.notifications(owner_id, created_at desc);
create index if not exists notifications_owner_unread_idx
  on public.notifications(owner_id, created_at desc)
  where not is_read;

drop trigger if exists profiles_set_updated_at on public.profiles;
create trigger profiles_set_updated_at
before update on public.profiles
for each row execute function public.set_updated_at();

drop trigger if exists complaints_set_updated_at on public.complaints;
create trigger complaints_set_updated_at
before update on public.complaints
for each row execute function public.set_updated_at();

drop trigger if exists vendor_applications_set_updated_at
  on public.vendor_applications;
create trigger vendor_applications_set_updated_at
before update on public.vendor_applications
for each row execute function public.set_updated_at();

drop trigger if exists notifications_set_updated_at on public.notifications;
create trigger notifications_set_updated_at
before update on public.notifications
for each row execute function public.set_updated_at();

create or replace function public.handle_new_auth_user()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  insert into public.profiles (id, name, phone, email)
  values (
    new.id,
    left(
      coalesce(
        nullif(btrim(new.raw_user_meta_data ->> 'name'), ''),
        nullif(split_part(coalesce(new.email, ''), '@', 1), ''),
        'Citizen'
      ),
      120
    ),
    case
      when btrim(coalesce(new.raw_user_meta_data ->> 'phone', ''))
        ~ '^[0-9+() -]{5,32}$'
        then btrim(new.raw_user_meta_data ->> 'phone')
      when coalesce(new.phone, '') ~ '^[0-9+() -]{5,32}$'
        then new.phone
      else ''
    end,
    coalesce(new.email, '')
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

create or replace function public.sync_auth_user_email()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  update public.profiles
  set email = coalesce(new.email, '')
  where id = new.id;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert on auth.users
for each row execute function public.handle_new_auth_user();

drop trigger if exists on_auth_user_email_updated on auth.users;
create trigger on_auth_user_email_updated
after update of email on auth.users
for each row
when (old.email is distinct from new.email)
execute function public.sync_auth_user_email();

insert into public.profiles (id, name, phone, email)
select
  users.id,
  left(
    coalesce(
      nullif(btrim(users.raw_user_meta_data ->> 'name'), ''),
      nullif(split_part(coalesce(users.email, ''), '@', 1), ''),
      'Citizen'
    ),
    120
  ),
  case
    when btrim(coalesce(users.raw_user_meta_data ->> 'phone', ''))
      ~ '^[0-9+() -]{5,32}$'
      then btrim(users.raw_user_meta_data ->> 'phone')
    when coalesce(users.phone, '') ~ '^[0-9+() -]{5,32}$'
      then users.phone
    else ''
  end,
  coalesce(users.email, '')
from auth.users as users
on conflict (id) do update set
  email = excluded.email;

alter table public.profiles enable row level security;
alter table public.complaints enable row level security;
alter table public.complaint_photos enable row level security;
alter table public.complaint_timeline enable row level security;
alter table public.vendor_applications enable row level security;
alter table public.vendor_documents enable row level security;
alter table public.vendor_timeline enable row level security;
alter table public.notifications enable row level security;

drop policy if exists profiles_select_own on public.profiles;
create policy profiles_select_own
on public.profiles for select to authenticated
using ((select auth.uid()) = id);

drop policy if exists profiles_update_own on public.profiles;
create policy profiles_update_own
on public.profiles for update to authenticated
using ((select auth.uid()) = id)
with check ((select auth.uid()) = id);

-- Profile rows are created only by the auth trigger; citizens cannot insert them.
drop policy if exists profiles_insert_own on public.profiles;

drop policy if exists complaints_select_own on public.complaints;
create policy complaints_select_own
on public.complaints for select to authenticated
using ((select auth.uid()) = owner_id);

drop policy if exists complaint_photos_select_own on public.complaint_photos;
create policy complaint_photos_select_own
on public.complaint_photos for select to authenticated
using ((select auth.uid()) = owner_id);

drop policy if exists complaint_timeline_select_own on public.complaint_timeline;
create policy complaint_timeline_select_own
on public.complaint_timeline for select to authenticated
using ((select auth.uid()) = owner_id);

drop policy if exists vendor_applications_select_own
  on public.vendor_applications;
create policy vendor_applications_select_own
on public.vendor_applications for select to authenticated
using ((select auth.uid()) = owner_id);

drop policy if exists vendor_documents_select_own on public.vendor_documents;
create policy vendor_documents_select_own
on public.vendor_documents for select to authenticated
using ((select auth.uid()) = owner_id);

drop policy if exists vendor_timeline_select_own on public.vendor_timeline;
create policy vendor_timeline_select_own
on public.vendor_timeline for select to authenticated
using ((select auth.uid()) = owner_id);

drop policy if exists notifications_select_own on public.notifications;
create policy notifications_select_own
on public.notifications for select to authenticated
using ((select auth.uid()) = owner_id);

drop policy if exists notifications_update_own on public.notifications;
create policy notifications_update_own
on public.notifications for update to authenticated
using ((select auth.uid()) = owner_id)
with check ((select auth.uid()) = owner_id);

insert into storage.buckets (
  id,
  name,
  public,
  file_size_limit,
  allowed_mime_types
)
values
  (
    'complaint-photos',
    'complaint-photos',
    false,
    10485760,
    array['image/jpeg', 'image/png', 'image/webp']
  ),
  (
    'vendor-documents',
    'vendor-documents',
    false,
    10485760,
    array['application/pdf', 'image/jpeg', 'image/png']
  )
on conflict (id) do update set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists complaint_photos_storage_select_own on storage.objects;
create policy complaint_photos_storage_select_own
on storage.objects for select to authenticated
using (
  bucket_id = 'complaint-photos' and
  (storage.foldername(name))[1] = (select auth.uid())::text
);

drop policy if exists complaint_photos_storage_insert_own on storage.objects;
create policy complaint_photos_storage_insert_own
on storage.objects for insert to authenticated
with check (
  bucket_id = 'complaint-photos' and
  owner_id = (select auth.uid())::text and
  split_part(name, '/', 1) = (select auth.uid())::text and
  split_part(name, '/', 2) ~* '^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$' and
  split_part(name, '/', 3) ~* '^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}\.(jpg|jpeg|png|webp)$' and
  pg_catalog.array_length(pg_catalog.string_to_array(name, '/'), 1) = 3 and
  name not like '%//%' and
  name !~ '(^|/)\.{1,2}(/|$)' and
  position(chr(92) in name) = 0 and
  lower(coalesce(metadata ->> 'mimetype', '')) = case
    when name ~* '\.(jpg|jpeg)$' then 'image/jpeg'
    when name ~* '\.png$' then 'image/png'
    when name ~* '\.webp$' then 'image/webp'
    else ''
  end
);

drop policy if exists complaint_photos_storage_update_own on storage.objects;

drop policy if exists complaint_photos_storage_delete_own on storage.objects;
create policy complaint_photos_storage_delete_own
on storage.objects for delete to authenticated
using (
  bucket_id = 'complaint-photos' and
  (storage.foldername(name))[1] = (select auth.uid())::text and
  not exists (
    select 1
    from public.complaint_photos as referenced_photo
    where referenced_photo.owner_id = (select auth.uid())
      and referenced_photo.bucket_id = storage.objects.bucket_id
      and referenced_photo.object_path = storage.objects.name
  )
);

drop policy if exists vendor_documents_storage_select_own on storage.objects;
create policy vendor_documents_storage_select_own
on storage.objects for select to authenticated
using (
  bucket_id = 'vendor-documents' and
  (storage.foldername(name))[1] = (select auth.uid())::text
);

drop policy if exists vendor_documents_storage_insert_own on storage.objects;
create policy vendor_documents_storage_insert_own
on storage.objects for insert to authenticated
with check (
  bucket_id = 'vendor-documents' and
  owner_id = (select auth.uid())::text and
  split_part(name, '/', 1) = (select auth.uid())::text and
  split_part(name, '/', 2) ~* '^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$' and
  split_part(name, '/', 3) ~* '^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}\.(pdf|jpg|jpeg|png)$' and
  pg_catalog.array_length(pg_catalog.string_to_array(name, '/'), 1) = 3 and
  name not like '%//%' and
  name !~ '(^|/)\.{1,2}(/|$)' and
  position(chr(92) in name) = 0 and
  lower(coalesce(metadata ->> 'mimetype', '')) = case
    when name ~* '\.pdf$' then 'application/pdf'
    when name ~* '\.(jpg|jpeg)$' then 'image/jpeg'
    when name ~* '\.png$' then 'image/png'
    else ''
  end
);

drop policy if exists vendor_documents_storage_update_own on storage.objects;

drop policy if exists vendor_documents_storage_delete_own on storage.objects;
create policy vendor_documents_storage_delete_own
on storage.objects for delete to authenticated
using (
  bucket_id = 'vendor-documents' and
  (storage.foldername(name))[1] = (select auth.uid())::text and
  not exists (
    select 1
    from public.vendor_documents as referenced_document
    where referenced_document.owner_id = (select auth.uid())
      and referenced_document.bucket_id = storage.objects.bucket_id
      and referenced_document.object_path = storage.objects.name
  )
);

create or replace function public._complaint_remote(complaint_uuid uuid)
returns jsonb
language sql
stable
security definer
set search_path = ''
as $$
  select jsonb_build_object(
    'id', complaint.public_id,
    'serviceType', complaint.service_type,
    'issue', complaint.issue,
    'description', complaint.description,
    'photos', coalesce(
      (
        select jsonb_agg(
          jsonb_build_object(
            'bucket', photo.bucket_id,
            'objectPath', photo.object_path,
            'originalName', photo.original_name,
            'contentType', photo.content_type,
            'byteSize', photo.byte_size,
            'sortOrder', photo.sort_order
          )
          order by photo.sort_order
        )
        from public.complaint_photos as photo
        where photo.complaint_id = complaint.id
      ),
      '[]'::jsonb
    ),
    'location', jsonb_build_object(
      'latitude', complaint.latitude,
      'longitude', complaint.longitude,
      'accuracy', complaint.accuracy,
      'address', complaint.location_address
    ),
    'contactPhone', complaint.contact_phone,
    'citizenAddress', complaint.citizen_address,
    'extraFields', complaint.extra_fields,
    'createdAt', complaint.created_at,
    'updatedAt', complaint.updated_at,
    'status', complaint.status,
    'timeline', coalesce(
      (
        select jsonb_agg(
          jsonb_build_object(
            'title', entry.title,
            'timestamp', entry.occurred_at,
            'message', entry.message,
            'isCompleted', entry.is_completed
          )
          order by entry.occurred_at, entry.created_at, entry.id
        )
        from public.complaint_timeline as entry
        where entry.complaint_id = complaint.id
      ),
      '[]'::jsonb
    ),
    'isDemo', false
  )
  from public.complaints as complaint
  where complaint.id = complaint_uuid;
$$;

create or replace function public._vendor_application_remote(application_uuid uuid)
returns jsonb
language sql
stable
security definer
set search_path = ''
as $$
  select jsonb_build_object(
    'id', application.public_id,
    'details', jsonb_build_object(
      'applicantName', application.applicant_name,
      'mobile', application.mobile,
      'email', application.email,
      'residentialAddress', application.residential_address,
      'identityInformation', application.identity_information,
      'businessName', application.business_name,
      'businessType', application.business_type,
      'category', application.category,
      'description', application.description,
      'productsServices', application.products_services,
      'registrationNumber', application.registration_number,
      'location', jsonb_build_object(
        'latitude', application.latitude,
        'longitude', application.longitude,
        'accuracy', application.accuracy,
        'address', application.location_address
      ),
      'preferredZone', application.preferred_zone,
      'operatingDays', to_jsonb(application.operating_days),
      'startTime', pg_catalog.to_char(application.start_time, 'HH24:MI'),
      'endTime', pg_catalog.to_char(application.end_time, 'HH24:MI'),
      'durationType', application.duration_type,
      'outletType', application.outlet_type,
      'documents', coalesce(
        (
          select jsonb_agg(
            jsonb_build_object(
              'type', document.document_type,
              'label', document.label,
              'requirement', document.requirement,
              'bucket', document.bucket_id,
              'objectPath', document.object_path,
              'originalName', document.original_name,
              'contentType', document.content_type,
              'byteSize', document.byte_size,
              'sortOrder', document.sort_order
            )
            order by document.sort_order
          )
          from public.vendor_documents as document
          where document.vendor_application_id = application.id
        ),
        '[]'::jsonb
      ),
      'acceptedDeclaration', application.accepted_declaration
    ),
    'status', application.status,
    'createdAt', application.created_at,
    'updatedAt', application.updated_at,
    'timeline', coalesce(
      (
        select jsonb_agg(
          jsonb_build_object(
            'title', entry.title,
            'timestamp', entry.occurred_at,
            'message', entry.message,
            'isCompleted', entry.is_completed,
            'isCurrent', entry.is_current
          )
          order by entry.created_at, entry.id
        )
        from public.vendor_timeline as entry
        where entry.vendor_application_id = application.id
      ),
      '[]'::jsonb
    ),
    'isDemo', false
  )
  from public.vendor_applications as application
  where application.id = application_uuid;
$$;

create or replace function public.submit_complaint(
  payload jsonb,
  attachments jsonb
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  owner_uuid uuid := auth.uid();
  complaint_uuid uuid;
  complaint_created_at timestamptz;
  complaint_public_id text;
  location_payload jsonb;
  extra_fields_payload jsonb;
  attachment jsonb;
  attachment_ordinality bigint;
  attachment_bucket text;
  attachment_path text;
  attachment_original_name text;
  attachment_content_type text;
  attachment_byte_size bigint;
  attachment_stored_content_type text;
  attachment_stored_byte_size bigint;
  attachment_sort_order integer;
  citizen_address_value text;
begin
  if owner_uuid is null then
    raise exception 'Authentication is required.' using errcode = '28000';
  end if;
  if payload is null or jsonb_typeof(payload) <> 'object' then
    raise exception 'payload must be a JSON object.' using errcode = '22023';
  end if;
  if attachments is null or jsonb_typeof(attachments) <> 'array' then
    raise exception 'attachments must be a JSON array.' using errcode = '22023';
  end if;
  if payload ? 'photoPaths' then
    raise exception 'Send uploaded file metadata in attachments, not photoPaths.'
      using errcode = '22023';
  end if;
  if jsonb_array_length(attachments) > 5 then
    raise exception 'A complaint can contain at most 5 photos.'
      using errcode = '22023';
  end if;
  if exists (
    select 1
    from unnest(array['serviceType', 'issue', 'description', 'contactPhone'])
      as required_field(field_name)
    where jsonb_typeof(payload -> required_field.field_name)
      is distinct from 'string'
  ) then
    raise exception 'serviceType, issue, description, and contactPhone must be strings.'
      using errcode = '22023';
  end if;

  location_payload := payload -> 'location';
  if location_payload is null or jsonb_typeof(location_payload) <> 'object' then
    raise exception 'payload.location must be a JSON object.' using errcode = '22023';
  end if;
  if jsonb_typeof(location_payload -> 'address') is distinct from 'string' then
    raise exception 'payload.location.address must be a string.'
      using errcode = '22023';
  end if;
  if jsonb_typeof(location_payload -> 'latitude') is distinct from 'number' or
     jsonb_typeof(location_payload -> 'longitude') is distinct from 'number' or
     jsonb_typeof(location_payload -> 'accuracy') is distinct from 'number' then
    raise exception 'Location coordinates and accuracy must be numbers.'
      using errcode = '22023';
  end if;
  if (location_payload ->> 'latitude')::double precision not between -90 and 90 or
     (location_payload ->> 'longitude')::double precision not between -180 and 180 or
     (location_payload ->> 'accuracy')::double precision not between 0 and 100000 then
    raise exception 'Location values are out of range.' using errcode = '22023';
  end if;
  if char_length(btrim(coalesce(location_payload ->> 'address', ''))) not between 1 and 500 then
    raise exception 'A location address between 1 and 500 characters is required.'
      using errcode = '22023';
  end if;
  if coalesce(payload ->> 'serviceType', '') not in (
    'vendor', 'garbage', 'water', 'roads', 'animals', 'drainage',
    'streetlights', 'publicSpaces', 'encroachment', 'other'
  ) then
    raise exception 'serviceType is invalid.' using errcode = '22023';
  end if;
  if char_length(btrim(coalesce(payload ->> 'issue', ''))) not between 1 and 160 then
    raise exception 'issue must contain between 1 and 160 characters.'
      using errcode = '22023';
  end if;
  if char_length(btrim(coalesce(payload ->> 'description', ''))) not between 1 and 5000 then
    raise exception 'description must contain between 1 and 5000 characters.'
      using errcode = '22023';
  end if;
  if coalesce(payload ->> 'contactPhone', '') !~ '^[0-9+() -]{5,32}$' then
    raise exception 'contactPhone is invalid.' using errcode = '22023';
  end if;

  if payload ? 'citizenAddress' and payload -> 'citizenAddress' <> 'null'::jsonb and
     jsonb_typeof(payload -> 'citizenAddress') <> 'string' then
    raise exception 'citizenAddress must be a string or null.' using errcode = '22023';
  end if;
  citizen_address_value := nullif(btrim(payload ->> 'citizenAddress'), '');
  if citizen_address_value is not null and char_length(citizen_address_value) > 500 then
    raise exception 'citizenAddress cannot exceed 500 characters.'
      using errcode = '22023';
  end if;

  if not (payload ? 'extraFields') or payload -> 'extraFields' = 'null'::jsonb then
    extra_fields_payload := '{}'::jsonb;
  else
    extra_fields_payload := payload -> 'extraFields';
  end if;
  if jsonb_typeof(extra_fields_payload) <> 'object' or
     pg_column_size(extra_fields_payload) > 16384 then
    raise exception 'extraFields must be a JSON object no larger than 16 KB.'
      using errcode = '22023';
  end if;
  if exists (
    select 1
    from jsonb_each(extra_fields_payload) as extra(field_name, field_value)
    where jsonb_typeof(extra.field_value) <> 'string'
  ) then
    raise exception 'Every extraFields value must be a string.'
      using errcode = '22023';
  end if;

  insert into public.complaints (
    owner_id,
    service_type,
    issue,
    description,
    latitude,
    longitude,
    accuracy,
    location_address,
    contact_phone,
    citizen_address,
    extra_fields
  )
  values (
    owner_uuid,
    payload ->> 'serviceType',
    btrim(payload ->> 'issue'),
    btrim(payload ->> 'description'),
    (location_payload ->> 'latitude')::double precision,
    (location_payload ->> 'longitude')::double precision,
    (location_payload ->> 'accuracy')::double precision,
    btrim(location_payload ->> 'address'),
    btrim(payload ->> 'contactPhone'),
    citizen_address_value,
    extra_fields_payload
  )
  returning id, public_id, created_at
  into complaint_uuid, complaint_public_id, complaint_created_at;

  for attachment, attachment_ordinality in
    select item.value, item.ordinality
    from jsonb_array_elements(attachments) with ordinality as item(value, ordinality)
  loop
    if jsonb_typeof(attachment) <> 'object' then
      raise exception 'Every attachment must be a JSON object.'
        using errcode = '22023';
    end if;
    if exists (
      select 1
      from unnest(array['bucket', 'objectPath', 'originalName', 'contentType'])
        as required_field(field_name)
      where jsonb_typeof(attachment -> required_field.field_name)
        is distinct from 'string'
    ) or jsonb_typeof(attachment -> 'byteSize') is distinct from 'number' or
       (
         attachment ? 'sortOrder' and
         jsonb_typeof(attachment -> 'sortOrder') is distinct from 'number'
       ) then
      raise exception 'Attachment metadata has an invalid field type.'
        using errcode = '22023';
    end if;
    if (attachment ->> 'byteSize') !~ '^[0-9]+$' or
       (
         attachment ? 'sortOrder' and
         (attachment ->> 'sortOrder') !~ '^[0-9]+$'
       ) then
      raise exception 'Attachment byteSize and sortOrder must be integers.'
        using errcode = '22023';
    end if;
    attachment_bucket := attachment ->> 'bucket';
    attachment_path := attachment ->> 'objectPath';
    attachment_original_name := attachment ->> 'originalName';
    attachment_content_type := lower(attachment ->> 'contentType');
    attachment_byte_size := (attachment ->> 'byteSize')::bigint;
    attachment_sort_order := coalesce(
      (attachment ->> 'sortOrder')::integer,
      attachment_ordinality::integer - 1
    );

    if attachment_bucket <> 'complaint-photos' then
      raise exception 'Complaint attachments must use complaint-photos.'
        using errcode = '22023';
    end if;
    if split_part(attachment_path, '/', 1) <> owner_uuid::text or
       split_part(attachment_path, '/', 2) !~* '^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$' or
       split_part(attachment_path, '/', 3) !~* '^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}\.(jpg|jpeg|png|webp)$' or
       pg_catalog.array_length(
         pg_catalog.string_to_array(attachment_path, '/'),
         1
       ) <> 3 or
       attachment_path like '%//%' or
       attachment_path ~ '(^|/)\.{1,2}(/|$)' or
       position(chr(92) in attachment_path) > 0 or
       char_length(attachment_path) > 1024 then
      raise exception 'Attachment objectPath must be <user-id>/<upload-group-uuid>/<file-uuid>.<ext>.'
        using errcode = '22023';
    end if;
    if char_length(btrim(coalesce(attachment_original_name, ''))) not between 1 and 255 then
      raise exception 'Attachment originalName is invalid.' using errcode = '22023';
    end if;
    if attachment_content_type not in (
      'image/jpeg', 'image/png', 'image/webp'
    ) then
      raise exception 'Attachment contentType is not supported.' using errcode = '22023';
    end if;
    if (attachment_path ~* '\.(jpg|jpeg)$' and attachment_content_type <> 'image/jpeg') or
       (attachment_path ~* '\.png$' and attachment_content_type <> 'image/png') or
       (attachment_path ~* '\.webp$' and attachment_content_type <> 'image/webp') then
      raise exception 'Attachment extension and contentType do not match.'
        using errcode = '22023';
    end if;
    if attachment_byte_size not between 1 and 10485760 then
      raise exception 'Attachment byteSize must be between 1 byte and 10 MB.'
        using errcode = '22023';
    end if;
    if attachment_sort_order not between 0 and 9 then
      raise exception 'Attachment sortOrder is invalid.' using errcode = '22023';
    end if;
    select
      (object.metadata ->> 'size')::bigint,
      lower(object.metadata ->> 'mimetype')
    into attachment_stored_byte_size, attachment_stored_content_type
    from storage.objects as object
    where object.bucket_id = 'complaint-photos'
      and object.name = attachment_path
      and object.owner_id = owner_uuid::text;
    if not found then
      raise exception 'An uploaded complaint photo was not found.'
        using errcode = '22023';
    end if;
    if attachment_stored_byte_size is distinct from attachment_byte_size or
       attachment_stored_content_type is distinct from attachment_content_type then
      raise exception 'Attachment metadata does not match the uploaded object.'
        using errcode = '22023';
    end if;

    insert into public.complaint_photos (
      complaint_id,
      owner_id,
      bucket_id,
      object_path,
      original_name,
      content_type,
      byte_size,
      sort_order
    )
    values (
      complaint_uuid,
      owner_uuid,
      attachment_bucket,
      attachment_path,
      btrim(attachment_original_name),
      attachment_content_type,
      attachment_byte_size,
      attachment_sort_order
    );
  end loop;

  insert into public.complaint_timeline (
    complaint_id,
    owner_id,
    title,
    occurred_at,
    message,
    is_completed
  )
  values (
    complaint_uuid,
    owner_uuid,
    'Submitted',
    complaint_created_at,
    'Your civic report has been received.',
    true
  );

  insert into public.notifications (
    owner_id,
    title,
    body,
    category,
    destination,
    reference_id
  )
  values (
    owner_uuid,
    'Complaint submitted',
    complaint_public_id || ' has been received.',
    'requests',
    'complaint',
    complaint_public_id
  );

  return public._complaint_remote(complaint_uuid);
end;
$$;

create or replace function public.submit_vendor_application(
  payload jsonb,
  documents jsonb
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  owner_uuid uuid := auth.uid();
  application_uuid uuid;
  application_created_at timestamptz;
  application_public_id text;
  location_payload jsonb;
  operating_days_value text[];
  document jsonb;
  document_ordinality bigint;
  document_bucket text;
  document_path text;
  document_original_name text;
  document_content_type text;
  document_byte_size bigint;
  document_stored_content_type text;
  document_stored_byte_size bigint;
  document_sort_order integer;
  document_type_value text;
  document_label_value text;
  document_requirement_value text;
begin
  if owner_uuid is null then
    raise exception 'Authentication is required.' using errcode = '28000';
  end if;
  if payload is null or jsonb_typeof(payload) <> 'object' then
    raise exception 'payload must be a JSON object.' using errcode = '22023';
  end if;
  if documents is null or jsonb_typeof(documents) <> 'array' then
    raise exception 'documents must be a JSON array.' using errcode = '22023';
  end if;
  if payload ? 'documents' then
    raise exception 'Send uploaded file metadata in documents, not payload.documents.'
      using errcode = '22023';
  end if;
  if jsonb_array_length(documents) > 12 then
    raise exception 'A vendor application can contain at most 12 documents.'
      using errcode = '22023';
  end if;
  if exists (
    select 1
    from unnest(array[
      'applicantName', 'mobile', 'email', 'residentialAddress',
      'identityInformation', 'businessName', 'businessType', 'category',
      'description', 'productsServices', 'registrationNumber', 'preferredZone',
      'startTime', 'endTime', 'durationType', 'outletType'
    ]) as required_field(field_name)
    where jsonb_typeof(payload -> required_field.field_name)
      is distinct from 'string'
  ) then
    raise exception 'Vendor application text fields must be strings.'
      using errcode = '22023';
  end if;
  if exists (
    select 1
    from jsonb_array_elements(documents) as supplied(document)
    where jsonb_typeof(supplied.document) <> 'object'
  ) then
    raise exception 'Every document must be a JSON object.' using errcode = '22023';
  end if;
  if (
    select count(*)
    from jsonb_array_elements(documents) as supplied(document)
  ) <> (
    select count(distinct supplied.document ->> 'type')
    from jsonb_array_elements(documents) as supplied(document)
  ) then
    raise exception 'Document types must be unique.' using errcode = '22023';
  end if;
  if char_length(btrim(coalesce(payload ->> 'applicantName', ''))) not between 1 and 120 then
    raise exception 'applicantName is invalid.' using errcode = '22023';
  end if;
  if coalesce(payload ->> 'mobile', '') !~ '^[0-9+() -]{5,32}$' then
    raise exception 'mobile is invalid.' using errcode = '22023';
  end if;
  if char_length(coalesce(payload ->> 'email', '')) not between 3 and 320 or
     coalesce(payload ->> 'email', '') !~ '^[^[:space:]@]+@[^[:space:]@]+\.[^[:space:]@]+$' then
    raise exception 'email is invalid.' using errcode = '22023';
  end if;
  if char_length(btrim(coalesce(payload ->> 'residentialAddress', ''))) not between 1 and 500 then
    raise exception 'residentialAddress is invalid.' using errcode = '22023';
  end if;
  if char_length(btrim(coalesce(payload ->> 'identityInformation', ''))) not between 1 and 2000 then
    raise exception 'identityInformation is invalid.' using errcode = '22023';
  end if;
  if char_length(btrim(coalesce(payload ->> 'businessName', ''))) not between 1 and 160 then
    raise exception 'businessName is invalid.' using errcode = '22023';
  end if;
  if char_length(btrim(coalesce(payload ->> 'businessType', ''))) not between 1 and 120 then
    raise exception 'businessType is invalid.' using errcode = '22023';
  end if;
  if char_length(btrim(coalesce(payload ->> 'category', ''))) not between 1 and 120 then
    raise exception 'category is invalid.' using errcode = '22023';
  end if;
  if char_length(btrim(coalesce(payload ->> 'description', ''))) not between 1 and 5000 then
    raise exception 'description is invalid.' using errcode = '22023';
  end if;
  if char_length(btrim(coalesce(payload ->> 'productsServices', ''))) not between 1 and 2000 then
    raise exception 'productsServices is invalid.' using errcode = '22023';
  end if;
  if char_length(coalesce(payload ->> 'registrationNumber', '')) > 120 then
    raise exception 'registrationNumber is too long.' using errcode = '22023';
  end if;
  if char_length(coalesce(payload ->> 'preferredZone', '')) > 160 then
    raise exception 'preferredZone is too long.' using errcode = '22023';
  end if;

  location_payload := payload -> 'location';
  if location_payload is null or jsonb_typeof(location_payload) <> 'object' then
    raise exception 'payload.location must be a JSON object.' using errcode = '22023';
  end if;
  if jsonb_typeof(location_payload -> 'address') is distinct from 'string' then
    raise exception 'payload.location.address must be a string.'
      using errcode = '22023';
  end if;
  if jsonb_typeof(location_payload -> 'latitude') is distinct from 'number' or
     jsonb_typeof(location_payload -> 'longitude') is distinct from 'number' or
     jsonb_typeof(location_payload -> 'accuracy') is distinct from 'number' then
    raise exception 'Location coordinates and accuracy must be numbers.'
      using errcode = '22023';
  end if;
  if (location_payload ->> 'latitude')::double precision not between -90 and 90 or
     (location_payload ->> 'longitude')::double precision not between -180 and 180 or
     (location_payload ->> 'accuracy')::double precision not between 0 and 100000 then
    raise exception 'Location values are out of range.' using errcode = '22023';
  end if;
  if char_length(btrim(coalesce(location_payload ->> 'address', ''))) not between 1 and 500 then
    raise exception 'A location address is required.' using errcode = '22023';
  end if;

  if jsonb_typeof(payload -> 'operatingDays') is distinct from 'array' then
    raise exception 'operatingDays must be a JSON array.'
      using errcode = '22023';
  end if;
  if jsonb_array_length(payload -> 'operatingDays') not between 1 and 7 then
    raise exception 'operatingDays must contain between 1 and 7 days.'
      using errcode = '22023';
  end if;
  if exists (
    select 1
    from jsonb_array_elements(payload -> 'operatingDays') as supplied(day)
    where jsonb_typeof(supplied.day) <> 'string'
  ) then
    raise exception 'Every operating day must be a string.' using errcode = '22023';
  end if;
  select array_agg(day order by ordinality)
  into operating_days_value
  from jsonb_array_elements_text(payload -> 'operatingDays')
    with ordinality as supplied(day, ordinality);
  if not (operating_days_value <@ array[
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
  ]::text[]) or cardinality(operating_days_value) <> (
    select count(distinct day) from unnest(operating_days_value) as supplied(day)
  ) then
    raise exception 'operatingDays contains an invalid or duplicate day.'
      using errcode = '22023';
  end if;
  if coalesce(payload ->> 'startTime', '') !~ '^([01][0-9]|2[0-3]):[0-5][0-9]$' or
     coalesce(payload ->> 'endTime', '') !~ '^([01][0-9]|2[0-3]):[0-5][0-9]$' then
    raise exception 'startTime and endTime must use HH:mm.' using errcode = '22023';
  end if;
  if coalesce(payload ->> 'durationType', '') not in ('Temporary', 'Permanent') then
    raise exception 'durationType is invalid.' using errcode = '22023';
  end if;
  if coalesce(payload ->> 'outletType', '') not in ('Stall', 'Cart', 'Shop', 'Other') then
    raise exception 'outletType is invalid.' using errcode = '22023';
  end if;
  if jsonb_typeof(payload -> 'acceptedDeclaration') is distinct from 'boolean' or
     payload -> 'acceptedDeclaration' <> 'true'::jsonb then
    raise exception 'The declaration must be accepted.' using errcode = '22023';
  end if;

  insert into public.vendor_applications (
    owner_id,
    applicant_name,
    mobile,
    email,
    residential_address,
    identity_information,
    business_name,
    business_type,
    category,
    description,
    products_services,
    registration_number,
    latitude,
    longitude,
    accuracy,
    location_address,
    preferred_zone,
    operating_days,
    start_time,
    end_time,
    duration_type,
    outlet_type,
    accepted_declaration
  )
  values (
    owner_uuid,
    btrim(payload ->> 'applicantName'),
    btrim(payload ->> 'mobile'),
    lower(btrim(payload ->> 'email')),
    btrim(payload ->> 'residentialAddress'),
    btrim(payload ->> 'identityInformation'),
    btrim(payload ->> 'businessName'),
    btrim(payload ->> 'businessType'),
    btrim(payload ->> 'category'),
    btrim(payload ->> 'description'),
    btrim(payload ->> 'productsServices'),
    btrim(coalesce(payload ->> 'registrationNumber', '')),
    (location_payload ->> 'latitude')::double precision,
    (location_payload ->> 'longitude')::double precision,
    (location_payload ->> 'accuracy')::double precision,
    btrim(location_payload ->> 'address'),
    btrim(coalesce(payload ->> 'preferredZone', '')),
    operating_days_value,
    (payload ->> 'startTime')::time without time zone,
    (payload ->> 'endTime')::time without time zone,
    payload ->> 'durationType',
    payload ->> 'outletType',
    true
  )
  returning id, public_id, created_at
  into application_uuid, application_public_id, application_created_at;

  for document, document_ordinality in
    select item.value, item.ordinality
    from jsonb_array_elements(documents) with ordinality as item(value, ordinality)
  loop
    if exists (
      select 1
      from unnest(array[
        'type', 'label', 'requirement', 'bucket', 'objectPath', 'originalName',
        'contentType'
      ]) as required_field(field_name)
      where jsonb_typeof(document -> required_field.field_name)
        is distinct from 'string'
    ) or jsonb_typeof(document -> 'byteSize') is distinct from 'number' or
       (
         document ? 'sortOrder' and
         jsonb_typeof(document -> 'sortOrder') is distinct from 'number'
       ) then
      raise exception 'Document metadata has an invalid field type.'
        using errcode = '22023';
    end if;
    if (document ->> 'byteSize') !~ '^[0-9]+$' or
       (
         document ? 'sortOrder' and
         (document ->> 'sortOrder') !~ '^[0-9]+$'
       ) then
      raise exception 'Document byteSize and sortOrder must be integers.'
        using errcode = '22023';
    end if;
    document_type_value := btrim(document ->> 'type');
    document_label_value := btrim(document ->> 'label');
    document_requirement_value := document ->> 'requirement';
    document_bucket := document ->> 'bucket';
    document_path := document ->> 'objectPath';
    document_original_name := document ->> 'originalName';
    document_content_type := lower(document ->> 'contentType');
    document_byte_size := (document ->> 'byteSize')::bigint;
    document_sort_order := coalesce(
      (document ->> 'sortOrder')::integer,
      document_ordinality::integer - 1
    );

    if char_length(document_type_value) not between 1 and 80 then
      raise exception 'Document type is invalid.' using errcode = '22023';
    end if;
    if char_length(document_label_value) not between 1 and 160 then
      raise exception 'Document label is invalid.' using errcode = '22023';
    end if;
    if document_requirement_value not in ('required', 'optional', 'conditional') then
      raise exception 'Document requirement is invalid.' using errcode = '22023';
    end if;
    if document_bucket <> 'vendor-documents' then
      raise exception 'Vendor files must use vendor-documents.' using errcode = '22023';
    end if;
    if split_part(document_path, '/', 1) <> owner_uuid::text or
       split_part(document_path, '/', 2) !~* '^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$' or
       split_part(document_path, '/', 3) !~* '^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}\.(pdf|jpg|jpeg|png)$' or
       pg_catalog.array_length(
         pg_catalog.string_to_array(document_path, '/'),
         1
       ) <> 3 or
       document_path like '%//%' or
       document_path ~ '(^|/)\.{1,2}(/|$)' or
       position(chr(92) in document_path) > 0 or
       char_length(document_path) > 1024 then
      raise exception 'Document objectPath must be <user-id>/<upload-group-uuid>/<file-uuid>.<ext>.'
        using errcode = '22023';
    end if;
    if char_length(btrim(coalesce(document_original_name, ''))) not between 1 and 255 then
      raise exception 'Document originalName is invalid.' using errcode = '22023';
    end if;
    if document_content_type not in ('application/pdf', 'image/jpeg', 'image/png') then
      raise exception 'Document contentType is not supported.' using errcode = '22023';
    end if;
    if (document_path ~* '\.pdf$' and document_content_type <> 'application/pdf') or
       (document_path ~* '\.(jpg|jpeg)$' and document_content_type <> 'image/jpeg') or
       (document_path ~* '\.png$' and document_content_type <> 'image/png') then
      raise exception 'Document extension and contentType do not match.'
        using errcode = '22023';
    end if;
    if document_byte_size not between 1 and 10485760 then
      raise exception 'Document byteSize must be between 1 byte and 10 MB.'
        using errcode = '22023';
    end if;
    if document_sort_order not between 0 and 19 then
      raise exception 'Document sortOrder is invalid.' using errcode = '22023';
    end if;
    select
      (object.metadata ->> 'size')::bigint,
      lower(object.metadata ->> 'mimetype')
    into document_stored_byte_size, document_stored_content_type
    from storage.objects as object
    where object.bucket_id = 'vendor-documents'
      and object.name = document_path
      and object.owner_id = owner_uuid::text;
    if not found then
      raise exception 'An uploaded vendor document was not found.'
        using errcode = '22023';
    end if;
    if document_stored_byte_size is distinct from document_byte_size or
       document_stored_content_type is distinct from document_content_type then
      raise exception 'Document metadata does not match the uploaded object.'
        using errcode = '22023';
    end if;

    insert into public.vendor_documents (
      vendor_application_id,
      owner_id,
      document_type,
      label,
      requirement,
      bucket_id,
      object_path,
      original_name,
      content_type,
      byte_size,
      sort_order
    )
    values (
      application_uuid,
      owner_uuid,
      document_type_value,
      document_label_value,
      document_requirement_value,
      document_bucket,
      document_path,
      btrim(document_original_name),
      document_content_type,
      document_byte_size,
      document_sort_order
    );
  end loop;

  insert into public.vendor_timeline (
    vendor_application_id,
    owner_id,
    title,
    occurred_at,
    message,
    is_completed,
    is_current
  )
  values (
    application_uuid,
    owner_uuid,
    'Application submitted',
    application_created_at,
    'Your vendor application has been received.',
    true,
    true
  );

  insert into public.notifications (
    owner_id,
    title,
    body,
    category,
    destination,
    reference_id
  )
  values (
    owner_uuid,
    'Vendor application submitted',
    application_public_id || ' has been received.',
    'requests',
    'vendorApplication',
    application_public_id
  );

  return public._vendor_application_remote(application_uuid);
end;
$$;

create or replace function public.get_current_user_data()
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  owner_uuid uuid := auth.uid();
  result jsonb;
begin
  if owner_uuid is null then
    raise exception 'Authentication is required.' using errcode = '28000';
  end if;

  select jsonb_build_object(
    'profile', (
      select jsonb_build_object(
        'name', profile.name,
        'phone', profile.phone,
        'email', profile.email,
        'address', profile.address,
        'avatarPath', profile.avatar_path
      )
      from public.profiles as profile
      where profile.id = owner_uuid
    ),
    'complaints', coalesce(
      (
        select jsonb_agg(
          public._complaint_remote(complaint.id)
          order by complaint.created_at desc, complaint.id
        )
        from public.complaints as complaint
        where complaint.owner_id = owner_uuid
      ),
      '[]'::jsonb
    ),
    'vendorApplications', coalesce(
      (
        select jsonb_agg(
          public._vendor_application_remote(application.id)
          order by application.created_at desc, application.id
        )
        from public.vendor_applications as application
        where application.owner_id = owner_uuid
      ),
      '[]'::jsonb
    ),
    'notifications', coalesce(
      (
        select jsonb_agg(
          jsonb_build_object(
            'id', notification.id::text,
            'title', notification.title,
            'body', notification.body,
            'category', notification.category,
            'createdAt', notification.created_at,
            'destination', notification.destination,
            'referenceId', notification.reference_id,
            'isRead', notification.is_read,
            'isDemo', false
          )
          order by notification.created_at desc, notification.id
        )
        from public.notifications as notification
        where notification.owner_id = owner_uuid
      ),
      '[]'::jsonb
    )
  )
  into result;

  return result;
end;
$$;

revoke all on table
  public.profiles,
  public.complaints,
  public.complaint_photos,
  public.complaint_timeline,
  public.vendor_applications,
  public.vendor_documents,
  public.vendor_timeline,
  public.notifications
from public, anon, authenticated;

grant usage on schema public to authenticated;

grant select on table
  public.profiles,
  public.complaints,
  public.complaint_photos,
  public.complaint_timeline,
  public.vendor_applications,
  public.vendor_documents,
  public.vendor_timeline,
  public.notifications
to authenticated;

grant update (name, phone, address)
on public.profiles to authenticated;
grant update (is_read)
on public.notifications to authenticated;

revoke all on sequence
  public.complaint_reference_seq,
  public.vendor_reference_seq
from public, anon, authenticated;

revoke all on function public.next_complaint_reference()
from public, anon, authenticated;
revoke all on function public.next_vendor_reference()
from public, anon, authenticated;
revoke all on function public.set_updated_at()
from public, anon, authenticated;
revoke all on function public.handle_new_auth_user()
from public, anon, authenticated;
revoke all on function public.sync_auth_user_email()
from public, anon, authenticated;
revoke all on function public._complaint_remote(uuid)
from public, anon, authenticated;
revoke all on function public._vendor_application_remote(uuid)
from public, anon, authenticated;

revoke all on function public.submit_complaint(jsonb, jsonb)
from public, anon, authenticated;
revoke all on function public.submit_vendor_application(jsonb, jsonb)
from public, anon, authenticated;
revoke all on function public.get_current_user_data()
from public, anon, authenticated;

grant execute on function public.submit_complaint(jsonb, jsonb)
to authenticated;
grant execute on function public.submit_vendor_application(jsonb, jsonb)
to authenticated;
grant execute on function public.get_current_user_data()
to authenticated;

comment on function public.submit_complaint(jsonb, jsonb) is
  'Atomically creates an authenticated citizen complaint from camelCase JSON and uploaded photo metadata.';
comment on function public.submit_vendor_application(jsonb, jsonb) is
  'Atomically creates an authenticated citizen vendor application from camelCase JSON and uploaded document metadata.';
comment on function public.get_current_user_data() is
  'Returns the authenticated citizen profile, complaints, vendor applications, and notifications as domain-shaped camelCase JSON.';

commit;

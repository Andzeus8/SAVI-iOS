-- SAVI Social V1 Supabase schema draft.
-- Run in a Supabase project only after reviewing policies.
-- The iOS app must use the anon key + user JWT only. Never ship the service-role key.

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  username text not null unique,
  display_name text not null,
  bio text not null default '',
  avatar_color text not null default '#D8FF3C',
  is_link_sharing_enabled boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint username_format check (username ~ '^[a-z0-9_]{3,24}$')
);

create table if not exists public.follows (
  follower_id uuid not null references auth.users(id) on delete cascade,
  followee_id uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (follower_id, followee_id),
  constraint no_self_follow check (follower_id <> followee_id)
);

create table if not exists public.public_links (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users(id) on delete cascade,
  local_item_id text not null,
  title text not null,
  description text not null default '',
  url text not null,
  canonical_url text not null,
  domain text not null,
  source text not null default 'Web',
  item_type text not null,
  folder_id text not null,
  folder_name text not null,
  tags text[] not null default '{}',
  thumbnail_url text,
  saved_at timestamptz not null,
  shared_at timestamptz not null default now(),
  is_hidden boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (owner_id, local_item_id),
  constraint public_link_web_only check (url ~ '^https?://'),
  constraint public_link_types check (item_type in ('link', 'article', 'video', 'place'))
);

create table if not exists public.link_likes (
  link_id uuid not null references public.public_links(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (link_id, user_id)
);

create table if not exists public.reports (
  id uuid primary key default gen_random_uuid(),
  reporter_id uuid not null references auth.users(id) on delete cascade,
  target_user_id uuid references auth.users(id) on delete cascade,
  target_link_id uuid references public.public_links(id) on delete cascade,
  reason text,
  status text not null default 'open',
  created_at timestamptz not null default now(),
  constraint report_target_present check (target_user_id is not null or target_link_id is not null),
  constraint report_status_allowed check (status in ('open', 'reviewing', 'actioned', 'dismissed'))
);

create table if not exists public.blocks (
  blocker_id uuid not null references auth.users(id) on delete cascade,
  blocked_id uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (blocker_id, blocked_id),
  constraint no_self_block check (blocker_id <> blocked_id)
);

create index if not exists profiles_username_idx on public.profiles (username);
create index if not exists follows_follower_idx on public.follows (follower_id);
create index if not exists follows_followee_idx on public.follows (followee_id);
create index if not exists public_links_owner_shared_idx on public.public_links (owner_id, shared_at desc);
create index if not exists public_links_domain_shared_idx on public.public_links (domain, shared_at desc);
create index if not exists public_links_canonical_idx on public.public_links (canonical_url);
create index if not exists reports_status_idx on public.reports (status, created_at desc);
create index if not exists blocks_blocker_idx on public.blocks (blocker_id);
create index if not exists blocks_blocked_idx on public.blocks (blocked_id);

alter table public.profiles enable row level security;
alter table public.follows enable row level security;
alter table public.public_links enable row level security;
alter table public.link_likes enable row level security;
alter table public.reports enable row level security;
alter table public.blocks enable row level security;

create policy "profiles are visible to signed in users"
  on public.profiles for select
  to authenticated
  using (true);

create policy "users edit their own profile"
  on public.profiles for all
  to authenticated
  using (auth.uid() = id)
  with check (auth.uid() = id);

create policy "users can see their follow graph"
  on public.follows for select
  to authenticated
  using (auth.uid() = follower_id or auth.uid() = followee_id);

create policy "users manage their follows"
  on public.follows for all
  to authenticated
  using (auth.uid() = follower_id)
  with check (auth.uid() = follower_id);

create policy "users see non-hidden public links"
  on public.public_links for select
  to authenticated
  using (
    is_hidden = false
    and not exists (
      select 1 from public.blocks b
      where (b.blocker_id = auth.uid() and b.blocked_id = public_links.owner_id)
         or (b.blocked_id = auth.uid() and b.blocker_id = public_links.owner_id)
    )
  );

create policy "users manage their public links"
  on public.public_links for all
  to authenticated
  using (auth.uid() = owner_id)
  with check (
    auth.uid() = owner_id
    and url ~ '^https?://'
    and item_type in ('link', 'article', 'video', 'place')
  );

create policy "users see likes on visible links"
  on public.link_likes for select
  to authenticated
  using (
    exists (
      select 1 from public.public_links pl
      where pl.id = link_likes.link_id
        and pl.is_hidden = false
        and not exists (
          select 1 from public.blocks b
          where (b.blocker_id = auth.uid() and b.blocked_id = pl.owner_id)
             or (b.blocked_id = auth.uid() and b.blocker_id = pl.owner_id)
        )
    )
  );

create policy "users manage their likes"
  on public.link_likes for all
  to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy "users create their own reports"
  on public.reports for insert
  to authenticated
  with check (auth.uid() = reporter_id);

create policy "users can read their own reports"
  on public.reports for select
  to authenticated
  using (auth.uid() = reporter_id);

create policy "users manage their blocks"
  on public.blocks for all
  to authenticated
  using (auth.uid() = blocker_id)
  with check (auth.uid() = blocker_id);

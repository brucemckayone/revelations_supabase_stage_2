Perfect. I'll define a full technical requirements outline for the Journal feature, designed as a modal with optional linkage to content (via `post_id` or similar). It will support rich-text journaling with options to mark entries as private, share to the Wisdom Feed, or pin to the Altar. The output will include database schema, UI flow, component breakdown, modal logic, integration points, and Next.js-specific best practices.

I'll notify you once it's ready for review.

# Journal Feature – Technical Design & Implementation Outline

## Overview

Implement the _Journal_ as a modal dialog (not a full page) that allows users to write reflective entries. The modal is launched by a "Write Journal" button, which can optionally include a `post_id` or reference to associate the entry with a specific content item or experience. Each journal entry consists of styled text blocks (rich text) and metadata. By default an entry is **Private**, but the user can toggle it to be **Shared** (appears in the Wisdom Feed) or **Pinned** (added to the user's Altar board of reflections). The goal is a calm, attractive design with soft animations and symbolic elements. The stack is **Next.js** + **TailwindCSS** + **shadcn/ui** (Radix-based UI components) + **Framer Motion** + **Jotai** for state, with **Supabase** as the backend.

## UI Component Structure

- **Modal Container:** Use the shadcn/ui **Dialog** component (a Radix-based modal) as the root of the Journal modal. Place the trigger button (e.g. "Write Journal") inside a `<DialogTrigger>`; on click, the dialog opens. Inside `<DialogContent>`, render the journal form.
- **Journal Form:** Inside the modal, include a rich-text editing area for the journal content. Initially, implement styled text blocks (e.g. headings, paragraphs) using a WYSIWYG or Markdown editor. (A headless editor like [Tiptap](https://tiptap.dev/) or similar can be integrated for structured content.) The form should include: a title or prompt text, a text editor area, and UI controls.
- **Controls & Toggles:** Below the text editor, provide controls for entry settings: a **Save** button and a **Cancel** (Close) button, plus toggles or radio inputs for the visibility flags. For example: a checkbox or switch for "Share to Wisdom Feed" and a checkbox for "Pin to Altar". By default, entries are Private (both toggles off). Changing these toggles updates the form state (handled by Jotai).
- **State Management:** Manage the modal's open/close state and form data with Jotai atoms (see next section). When the trigger button is clicked, set an `isJournalOpenAtom = true`; the `<Dialog>` will show. The button can pass a `post_id` parameter (if journaling on a specific piece of content) which should be stored in the form state. On modal close (clicking "Cancel" or outside), reset form state as needed.
- **Accessibility:** Ensure the modal is focus-trapped and closable with Esc/click outside. Label all fields appropriately. The shadcn Dialog component handles focus management and hiding the background content (content becomes inert).

## Styling & Layout (TailwindCSS and shadcn/ui)

- **Layout:** Use TailwindCSS for all styling. Center the modal content with `mx-auto`, add padding (`p-6` or similar) and a light background. Constrain width (e.g. `max-w-md` on small screens) and allow it to expand on larger screens (e.g. `md:max-w-2xl`) for readability. Inside the modal, use flex or grid to lay out the form: e.g. a vertical stack with the editor taking most space and controls at the bottom.
- **Typography & Spacing:** Apply generous line-height and padding to create a soothing reading space. Use Tailwind's typography utilities (`prose`, `text-lg`, etc.) for the text editor area. Ensure enough spacing (`space-y-4`, `mt-6`, etc.) between elements.
- **Responsive Design:** Build mobile-first. Tailwind's responsive utilities (`sm:`, `md:`, `lg:`, etc.) let you adapt styles at different breakpoints. For example, the modal can be nearly full-width on mobile (`w-full sm:w-3/4 md:w-1/2`), and grow larger on bigger screens. Text size and control layout may change at `md` or `lg` breakpoints to optimize usability.
- **Visual Theme:** Choose a calm color palette (soft neutrals or pastels). Use symbolic icons or subtle illustrations (e.g. a quill, candle, or lotus icon) near the header or in background accents to reinforce reflection. Add a soft drop-shadow (`shadow-lg`) and rounded corners (`rounded-lg`). Button and toggle colors should fit the brand (e.g. a gentle primary accent for the Save button). Maintain high contrast for readability.
- **Animations & Transitions:** Use Framer Motion to animate the modal and its backdrop for smooth, unobtrusive transitions. For example, fade in a semi-transparent backdrop (`opacity 0 → 100%`) and animate the modal content dropping/fading into view. Use Framer's `<AnimatePresence>` with a `<motion.div>` wrapping the modal content to define entry/exit animations (see Fireship tutorial). Keep animations subtle and brief – they should provide gentle feedback and focus, not distract. For instance, use a quick scale-up or slide-in on open, and a fade-out on close.

## State Management (Jotai)

- **Modal Open State:** Create a Jotai atom, e.g. `isJournalOpenAtom = atom(false)`. This boolean atom controls whether the modal is shown. Wrap the Next.js app in `<Provider>` so atoms can be used throughout. In the trigger button's click handler, use `setAtom(isJournalOpenAtom, true)` to open, and in the modal's close action set it to false.
- **Form State Atom:** Define a Jotai atom (or atoms) for the journal form data. For example:

  ```js
  const journalFormAtom = atom({
    post_id: null,
    content: "",
    is_shared: false,
    is_pinned: false,
  });
  ```

  (Or split into multiple atoms for each field if preferred – Jotai encourages "small isolated state".) Keep atoms minimal to avoid unnecessary re-renders. Use the `useAtom` hook to read/update these in the form component. Reset this atom (e.g. to default values) each time the modal closes.

- **Inter-Component State Flow:** The trigger button (possibly in a parent or page component) can write to `journalFormAtom` to set `post_id` before opening. All form fields (editor content, toggles) bind to this atom so that any component can read/write them. After submission, the atoms should be cleared.

## Data Model & Database Schema

Add a new table `journal_entries` in Supabase (Postgres) with at least the following columns:

- `id` – primary key (e.g. `uuid` or serial).
- `user_id` – foreign key to the `users` table (the owner of the entry).
- `post_id` – _nullable_ foreign key referencing the content or experience being journaled (if any).
- `content` – a text or JSONB column storing the entry's body. This can hold Markdown or serialized rich-text (for styled blocks).
- `is_shared` – boolean (default `false`), true if published to Wisdom Feed.
- `is_pinned` – boolean (default `false`), true if added to user's Altar.
- `created_at`, `updated_at` – timestamp columns (default `NOW()`).

Optionally, add an index on `user_id` for fast lookup of a user's entries. Ensure foreign keys (`user_id`, `post_id`) have `ON DELETE CASCADE` or restrict as appropriate. No separate table is needed for Altar items – simply query `journal_entries WHERE user_id = X AND is_pinned`. The Wisdom Feed can query `journal_entries WHERE is_shared = true`.

## Supabase Row-Level Security (RLS)

Enable RLS on `journal_entries` and add policies to enforce visibility rules:

- **Select Policy (Owner):** Allow users to select their own entries. Example policy:

  ```sql
  CREATE POLICY "Users can select their own journals"
    ON journal_entries FOR SELECT
    USING ( auth.uid() = user_id );
  ```

  This follows the Supabase example pattern that restricts rows to the owner's own `user_id`.

- **Select Policy (Shared):** Allow selecting entries that are shared to the Wisdom Feed. For example, grant `SELECT` to `authenticated` (and/or `anon`) where `is_shared = true`. This ensures public visibility of shared entries.
- **Insert Policy:** Allow an authenticated user to insert a journal only if `auth.uid() = user_id`. For example:

  ```sql
  CREATE POLICY "Users can insert own journals"
    ON journal_entries FOR INSERT
    WITH CHECK ( auth.uid() = user_id );
  ```

- **Update/Delete Policy:** Similarly, restrict updates/deletes so only the owner can modify their entry:

  ```sql
  CREATE POLICY "Users can update own journals"
    ON journal_entries FOR UPDATE
    USING ( auth.uid() = user_id );
  CREATE POLICY "Users can delete own journals"
    ON journal_entries FOR DELETE
    USING ( auth.uid() = user_id );
  ```

These policies ensure private entries remain visible only to the owner, while shared entries are accessible as intended. Be sure to **enable** RLS on the table (Supabase does this by default for new tables, or use `ALTER TABLE ... ENABLE ROW LEVEL SECURITY`).

## Next.js Architecture & Organization

- **Component Files:** Create dedicated components for the Journal modal and form (e.g. `/components/JournalModal.tsx`, `/components/JournalForm.tsx`). If using the Next.js App Router, you can place these in a private folder (prefix with `_`) to indicate they aren't routable pages (Next.js docs suggest private folders for separating UI logic from routes). For example:

  ```
  /app
    /_components
      /JournalModal.tsx
      /JournalForm.tsx
      ...
  ```

  Or with the Pages Router, put them under `/components/journal/`.

- **Jotai Provider:** Wrap the `_app.tsx` or root layout with `<Provider>` from Jotai so atoms work across components.
- **Hooks & Logic:** Consider a custom React hook (e.g. `useJournalModal`) that wraps `useAtom` logic for opening/closing the modal and resetting form state. This encapsulates journaling logic.
- **API / Data Layer:** For form submission, you have two options:

  1. **Client-Side Supabase:** Call `supabase.from('journal_entries').insert({...})` directly from the client component. RLS is already in place, so the user must be authenticated.
  2. **Next.js API Route:** Create an API route (e.g. `/pages/api/journal/create.ts`) that uses the Supabase server library (with service key) to insert the entry. The client then POSTs to this endpoint.
     Either way, after successful insert, update local state. For example, if the entry is shared, trigger a refetch of the Wisdom Feed; if pinned, update the Altar view. Using libraries like SWR or React Query can help automatically update queries.

- **Separation of Concerns:** Follow Next.js conventions for project structure. Keep the modal UI (Dialog, form fields) separate from data fetching logic. Put Supabase client initialization in a `lib/` folder or similar. Place any reusable form validation or API calling code in `utils/` or hooks. For example, `/utils/supabaseClient.ts` exports a configured Supabase client.

## Altar & Wisdom Feed Integration

- **Wisdom Feed:** When a journal entry is marked "Shared," ensure it's visible on the Wisdom Feed. The feed component should query `journal_entries WHERE is_shared = true` (with optional pagination). The new entry will appear on refresh or via SWR revalidation.
- **Altar (Pinned):** If "Pinned," the entry should appear on the user's Altar board. This can be as simple as querying `journal_entries WHERE user_id = auth.uid() AND is_pinned = true`. No separate relationship table is needed unless more metadata for Altar is required. The entry can also be both shared and pinned, if the user chooses.

## Developer Implementation Steps

1. **Database Migration:** Create the `journal_entries` table in Supabase (via SQL or migrations). Include columns as specified above and set defaults. Enable RLS on the table.
2. **Define RLS Policies:** Add the Row-Level Security policies for SELECT, INSERT, UPDATE, DELETE described above. Test with supabase SQL editor that policies behave correctly (e.g. user A cannot see user B's private entries).
3. **Setup Jotai State:** In your codebase, install Jotai and wrap the app with `<Provider>`. Create atoms: e.g.

   ```js
   const isJournalOpenAtom = atom(false);
   const journalFormAtom = atom({
     post_id: null,
     content: "",
     is_shared: false,
     is_pinned: false,
   });
   ```

4. **Build Modal UI Component:** Create `JournalModal.tsx`. Use shadcn/ui's `Dialog` component for the modal container. Inside it, include the form header (e.g. "New Reflection"), and render `JournalForm`. Attach `<DialogTrigger>` to the launch button (passing `onClick={() => set(isJournalOpenAtom, true)}` with optional `post_id`).
5. **Design JournalForm:** In `JournalForm.tsx`, add a rich text editor component (e.g. a `<textarea>` or a 3rd-party editor wrapped in your UI). Bind its value to `journalFormAtom.content`. Add form controls: two switches or checkboxes for "Shared" and "Pinned", bound to `journalFormAtom.is_shared` and `.is_pinned`. Include Save and Cancel buttons. Use shadcn's Button and Toggle components for consistent styling.
6. **Tie State to UI:** Use `useAtom(isJournalOpenAtom)` in `JournalModal` to open/close the Dialog. Use `useAtom(journalFormAtom)` in `JournalForm` to read/update content and flags. Set `journalFormAtom.post_id` from the trigger if provided. On Cancel (or backdrop click), set `isJournalOpenAtom = false` and reset `journalFormAtom` to default values.
7. **Apply Styling:** Use Tailwind classes on all elements. Example: `<DialogContent className="p-6 bg-white max-w-md sm:max-w-xl rounded-lg shadow-lg">`. Use responsive classes (`sm:`, `md:`) to adapt layout. Ensure the text editor area scrolls internally if content grows. Aim for ample padding and whitespace.
8. **Add Animations:** Wrap the modal content in Framer Motion tags. For example:

   ```jsx
   <AnimatePresence>
     {isOpen && (
       <motion.div
         initial={{ opacity: 0, y: -50 }}
         animate={{ opacity: 1, y: 0 }}
         exit={{ opacity: 0, y: 50 }}
         transition={{ duration: 0.2 }}
       >
         {/* DialogContent here */}
       </motion.div>
     )}
   </AnimatePresence>
   ```

   Also animate the backdrop opacity. Keep durations short and easing gentle. Test that the motion feels smooth and subtle.

9. **Handle Form Submission:** In `JournalForm`, on Save click gather form data (`content`, `is_shared`, `is_pinned`, plus `post_id`, and use the current user's `user_id`). Call the backend: either `supabase.from('journal_entries').insert([...])` on the client, or `fetch('/api/journal/create', { method: 'POST', body: JSON })`. On success, optionally show a success toast ("Journal saved!"), clear the atoms, close the modal, and trigger data refresh (e.g. revalidate SWR or call a prop callback).
10. **Integrate with Wisdom/Altar:** If the entry is shared, optionally post it immediately to the Wisdom Feed state or notify that section to refresh. If pinned, likewise update the Altar view. Ensure that any relevant client-side lists (user's entries, feed, altar) include the new entry.
11. **Testing & QA:** Verify the modal works on all screen sizes. Test that toggles correctly set flags. Confirm that RLS policies work: an entry set private is invisible to others, while shared entries appear in feed. Check that updating an entry (if supported) or deleting handles RLS. Ensure keyboard accessibility and that animations are not jarring.
12. **Future Extensions:** Once the text-only entry works, the same modal structure can be extended to add image or media uploads (storing URLs in the `journal_entries` content JSON). The rich-text schema in the database should accommodate such extensions.

**Sources:** Core guidelines and patterns are drawn from the Next.js and Tailwind documentation, Jotai state management principles, Radix/Shadcn UI Dialog usage, Framer Motion modal examples, and UI animation best practices. Supabase RLS policies follow standard examples. All citations are included for reference.

# Journal Feature Backend Requirements

## Overview

This document outlines the database schema requirements for implementing a personal journaling feature within the existing platform. The journal functionality will allow users to document their wellness journey, track moods and emotions, connect journal entries with platform content, and gain insights through their personal data.

## Current Database Analysis

Based on examination of the existing schema, the platform follows these design patterns:

1. **Content Organization**

   - `posts` table serves as the central entity for content with `post_type_enum` differentiating content types
   - Current post types include: event, service, neuro_flow, yoga, dance, meditation, breath_work, primal, ritual, ceremony, article, video, on_demand
   - Content-specific tables extend the base post structure with specialized fields

2. **Emotional and Wellness Tracking**

   - `emotional_focuses` table stores named emotional states as reusable entities
   - `post_emotional_focuses` junction table connects content with emotional focuses
   - `movements` table captures wellness data like energy_level, emotional_focus, body_focus

3. **User Interaction**

   - `comments` table with hierarchical structure (parent_id field)
   - Rich interaction through related tables like `comment_reactions` and `comment_attachments`

4. **Media and Storage**
   - Integration with Supabase storage buckets
   - Media metadata stored in database while files are in storage buckets

## Journal Feature Schema Design

### 1. Core Tables

#### journal_entries Table

```sql
create table public.journal_entries (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete cascade not null,
  title text not null,
  content text not null,
  post_id uuid references public.posts(id) on delete set null,
  mood_score smallint check (mood_score >= 1 and mood_score <= 10),
  energy_level smallint check (energy_level >= 1 and energy_level <= 10),
  is_shared boolean default false not null,
  is_pinned boolean default false not null,
  created_at timestamp with time zone default now() not null,
  updated_at timestamp with time zone default now() not null
);

comment on table public.journal_entries is 'User journal entries for personal wellness tracking and reflection';

create index idx_journal_entries_user_id on public.journal_entries(user_id);
create index idx_journal_entries_post_id on public.journal_entries(post_id);
create index idx_journal_entries_created_at on public.journal_entries(created_at);
```

#### journal_entry_emotional_focuses Table

```sql
create table public.journal_entry_emotional_focuses (
  journal_entry_id uuid references public.journal_entries(id) on delete cascade not null,
  emotional_focus_id uuid references public.emotional_focuses(id) on delete cascade not null,
  intensity smallint check (intensity >= 1 and intensity <= 5) default 3 not null,
  created_at timestamp with time zone default now() not null,
  primary key (journal_entry_id, emotional_focus_id)
);

comment on table public.journal_entry_emotional_focuses is 'Emotional focuses associated with journal entries, with intensity scale';
```

#### journal_media Table

```sql
create table public.journal_media (
  id uuid primary key default gen_random_uuid(),
  journal_entry_id uuid references public.journal_entries(id) on delete cascade not null,
  storage_path text not null,
  mime_type text not null,
  filename text not null,
  size integer not null,
  created_at timestamp with time zone default now() not null
);

comment on table public.journal_media is 'Media attachments for journal entries';

create index idx_journal_media_journal_entry_id on public.journal_media(journal_entry_id);
```

#### journal_tags Table

```sql
create table public.journal_tags (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  user_id uuid references auth.users(id) on delete cascade not null,
  created_at timestamp with time zone default now() not null,
  unique(name, user_id)
);

comment on table public.journal_tags is 'User-defined tags for journal entries';

create table public.journal_entry_tags (
  journal_entry_id uuid references public.journal_entries(id) on delete cascade not null,
  tag_id uuid references public.journal_tags(id) on delete cascade not null,
  primary key (journal_entry_id, tag_id)
);

comment on table public.journal_entry_tags is 'Junction table connecting journal entries with tags';
```

### 2. Enhancement Tables

#### journal_prompts Table

```sql
create table public.journal_prompts (
  id uuid primary key default gen_random_uuid(),
  content text not null,
  category text not null,
  created_at timestamp with time zone default now() not null,
  is_active boolean default true not null
);

comment on table public.journal_prompts is 'System-provided prompts to inspire journal entries';
```

#### journal_wellness_metrics Table

```sql
create table public.journal_wellness_metrics (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  description text,
  min_value integer not null,
  max_value integer not null,
  icon text,
  is_system boolean default false not null,
  user_id uuid references auth.users(id),
  created_at timestamp with time zone default now() not null,
  check ((is_system = true and user_id is null) or (is_system = false and user_id is not null))
);

comment on table public.journal_wellness_metrics is 'Configurable metrics for tracking wellness factors';

create index idx_journal_wellness_metrics_user_id on public.journal_wellness_metrics(user_id);
```

#### journal_entry_metrics Table

```sql
create table public.journal_entry_metrics (
  journal_entry_id uuid references public.journal_entries(id) on delete cascade not null,
  metric_id uuid references public.journal_wellness_metrics(id) on delete cascade not null,
  value integer not null,
  created_at timestamp with time zone default now() not null,
  primary key (journal_entry_id, metric_id)
);

comment on table public.journal_entry_metrics is 'Wellness metric values recorded in journal entries';
```

### 3. Database Functions

#### Create Journal Entry Function

```sql
create or replace function public.create_journal_entry(
  p_user_id uuid,
  p_title text,
  p_content text,
  p_post_id uuid default null,
  p_mood_score smallint default null,
  p_energy_level smallint default null,
  p_is_shared boolean default false,
  p_is_pinned boolean default false,
  p_emotional_focuses json default null,
  p_tags text[] default null
)
returns uuid
language plpgsql security definer
as $$
declare
  v_entry_id uuid;
  v_focus_record record;
  v_tag_id uuid;
  v_tag_name text;
begin
  -- Insert the journal entry
  insert into public.journal_entries (
    user_id, title, content, post_id,
    mood_score, energy_level, is_shared, is_pinned
  )
  values (
    p_user_id, p_title, p_content, p_post_id,
    p_mood_score, p_energy_level, p_is_shared, p_is_pinned
  )
  returning id into v_entry_id;

  -- Associate emotional focuses with intensity
  if p_emotional_focuses is not null then
    for v_focus_record in select * from json_to_recordset(p_emotional_focuses)
      as x(focus_id uuid, intensity smallint) loop

      insert into public.journal_entry_emotional_focuses (
        journal_entry_id, emotional_focus_id, intensity
      )
      values (
        v_entry_id, v_focus_record.focus_id, v_focus_record.intensity
      );
    end loop;
  end if;

  -- Handle tags
  if p_tags is not null then
    foreach v_tag_name in array p_tags loop
      -- Create tag if it doesn't exist
      insert into public.journal_tags (name, user_id)
      values (v_tag_name, p_user_id)
      on conflict (name, user_id) do nothing;

      -- Get tag id
      select id into v_tag_id
      from public.journal_tags
      where name = v_tag_name and user_id = p_user_id;

      -- Associate tag with entry
      insert into public.journal_entry_tags (journal_entry_id, tag_id)
      values (v_entry_id, v_tag_id);
    end loop;
  end if;

  return v_entry_id;
end;
$$;
```

#### Get Journal Entries Function

```sql
create or replace function public.get_journal_entries(
  p_user_id uuid,
  p_limit integer default 20,
  p_offset integer default 0,
  p_post_id uuid default null,
  p_is_shared boolean default null,
  p_is_pinned boolean default null,
  p_from_date date default null,
  p_to_date date default null
)
returns setof public.journal_entries
language sql security definer
as $$
  select *
  from public.journal_entries
  where user_id = p_user_id
    and (p_post_id is null or post_id = p_post_id)
    and (p_is_shared is null or is_shared = p_is_shared)
    and (p_is_pinned is null or is_pinned = p_is_pinned)
    and (p_from_date is null or created_at::date >= p_from_date)
    and (p_to_date is null or created_at::date <= p_to_date)
  order by created_at desc
  limit p_limit
  offset p_offset;
$$;
```

### 4. Row Level Security Policies

```sql
-- Journal Entries RLS
alter table public.journal_entries enable row level security;

create policy journal_entries_select_own on public.journal_entries
  for select using (auth.uid() = user_id);

create policy journal_entries_select_shared on public.journal_entries
  for select using (is_shared = true);

create policy journal_entries_insert on public.journal_entries
  for insert with check (auth.uid() = user_id);

create policy journal_entries_update on public.journal_entries
  for update using (auth.uid() = user_id);

create policy journal_entries_delete on public.journal_entries
  for delete using (auth.uid() = user_id);

-- Journal Media RLS
alter table public.journal_media enable row level security;

create policy journal_media_select on public.journal_media
  for select using (
    exists (
      select 1 from public.journal_entries
      where id = journal_media.journal_entry_id
      and (user_id = auth.uid() or is_shared = true)
    )
  );

create policy journal_media_insert on public.journal_media
  for insert with check (
    exists (
      select 1 from public.journal_entries
      where id = journal_media.journal_entry_id
      and user_id = auth.uid()
    )
  );

create policy journal_media_delete on public.journal_media
  for delete using (
    exists (
      select 1 from public.journal_entries
      where id = journal_media.journal_entry_id
      and user_id = auth.uid()
    )
  );

-- Similar policies for other journal tables
```

## Integration with Existing Features

### 1. Emotional Focuses Integration

- The journal system will use the existing `emotional_focuses` table for consistency
- New journal entries can associate with emotional focuses plus an intensity value
- This creates a connection between platform content and personal journal entries

### 2. Content Reference

- Journal entries can optionally reference platform content via the `post_id` field
- This allows users to journal about their experience with specific content items
- Entries can be filtered by content item to see a user's journey with particular practices

### 3. Wisdom Feed Integration

- Journal entries with `is_shared=true` can appear in the Wisdom Feed
- Shared entries follow the same privacy model as other user-generated content
- UI elements will clearly indicate sharing status to users

### 4. Altar Integration

- Entries with `is_pinned=true` will appear on the user's personal Altar
- The Altar can serve as a collection of meaningful journal reflections
- Entries can be both shared and pinned simultaneously

## Implementation Plan

### Phase 1: Core Journal Functionality

- Create database tables for journal entries and related data
- Implement CRUD operations for journal entries
- Set up RLS policies for privacy and security
- Build basic journal entry form and display components

### Phase 2: Emotional and Content Integration

- Implement emotional focuses selection in journal entries
- Add content reference capabilities
- Develop UI for browsing journal entries
- Create initial analytics for mood and energy tracking

### Phase 3: Advanced Features

- Add custom wellness metrics tracking
- Implement journal prompts system
- Create advanced analytics and insights
- Develop streak and habit tracking

## Storage Requirements

For journal media attachments:

1. Create a dedicated storage bucket `journal-media`
2. Set up appropriate bucket policies:
   - Allow authenticated users to upload to their own folder
   - Restrict access to private media to the owner only
   - Allow public access to media from shared entries
3. Store media paths in the `journal_media` table using the pattern:
   `journal-media/{user_id}/{entry_id}/{filename}`

## API Endpoints

The following API endpoints will be required:

1. `/journal/entries`

   - GET: List user's journal entries (with filtering options)
   - POST: Create a new journal entry

2. `/journal/entries/{id}`

   - GET: Retrieve a specific journal entry with related data
   - PUT: Update a journal entry
   - DELETE: Delete a journal entry

3. `/journal/media/{entry_id}`

   - POST: Upload media for a journal entry
   - GET: List media for a journal entry

4. `/journal/analytics`
   - GET: Retrieve mood/energy trends and insights

## Considerations

1. **Performance**

   - Indexes on frequently queried columns
   - Pagination for journal entry retrieval
   - Efficient joins for emotional focus and tag data

2. **Security**

   - Strict RLS policies to ensure journal privacy
   - Storage bucket policies aligned with entry sharing settings
   - Validation of user input to prevent injection attacks

3. **Extensibility**
   - Schema design accommodates future enhancements
   - Separation of concerns for maintainability
   - Flexible tagging system for categorization

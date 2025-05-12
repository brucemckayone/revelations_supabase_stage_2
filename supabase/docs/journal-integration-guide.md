# Journal System Integration Guide

This document provides comprehensive guidance for integrating the journal system into your frontend application.

## System Overview

The journal system allows users to create, update, and manage personal journal entries with the following features:

- Basic journal entries with title, content, and privacy settings
- Mood tracking for emotional wellness
- Tagging system for categorization
- Media attachments (images, audio, etc.)
- Links to platform content (posts)
- Detailed views and statistics

## Database Structure

### Core Tables

1. **journal_entries**: Stores the main journal entry data
2. **journal_tags**: Contains available tags
3. **journal_entry_tags**: Junction table linking entries to tags
4. **journal_media**: Stores media attachments
5. **journal_content_links**: Links journal entries to platform content

### Enums

- **journal_entry_privacy_enum**: `'private'`, `'public'`, `'shared'`
- **mood_enum**: `'great'`, `'good'`, `'neutral'`, `'poor'`, `'terrible'`

### Views

- **journal_entries_with_details**: Combines entries with their tags, media, and linked content
- **user_journal_stats**: Provides statistics about user's journaling habits

## Database Functions

### 1. Create Journal Entry

```typescript
async function createJournalEntry({
  title,
  content,
  mood,
  privacy = "private",
  tags = [],
  postId = null,
}: {
  title: string;
  content: string;
  mood?: "great" | "good" | "neutral" | "poor" | "terrible";
  privacy?: "private" | "public" | "shared";
  tags?: string[];
  postId?: string | null;
}) {
  const { data, error } = await supabase.rpc("create_journal_entry", {
    p_title: title,
    p_content: content,
    p_mood: mood,
    p_privacy: privacy,
    p_tags: tags,
    p_post_id: postId,
  });

  if (error) throw error;
  return data;
}
```

**Function Parameters:**

- `p_user_id`: UUID of the user (automatically derived from auth.uid() in the backend)
- `p_title`: Text for the journal entry title
- `p_content`: Text content of the journal entry
- `p_mood`: Optional mood of type mood_enum
- `p_privacy`: Privacy setting of type journal_entry_privacy_enum (defaults to 'private')
- `p_tags`: Optional array of tag names
- `p_post_id`: Optional UUID to link to a post

**Returns:**
JSON object containing the journal entry, associated tags, and content links.

### 2. Update Journal Entry

```typescript
async function updateJournalEntry({
  journalEntryId,
  title,
  content,
  mood,
  privacy,
  tags,
}: {
  journalEntryId: number;
  title?: string;
  content?: string;
  mood?: "great" | "good" | "neutral" | "poor" | "terrible";
  privacy?: "private" | "public" | "shared";
  tags?: string[];
}) {
  const { data, error } = await supabase.rpc("update_journal_entry", {
    p_journal_entry_id: journalEntryId,
    p_title: title,
    p_content: content,
    p_mood: mood,
    p_privacy: privacy,
    p_tags: tags,
  });

  if (error) throw error;
  return data;
}
```

**Function Parameters:**

- `p_journal_entry_id`: Numeric ID of the journal entry to update
- `p_title`: Optional new title
- `p_content`: Optional new content
- `p_mood`: Optional new mood
- `p_privacy`: Optional new privacy setting
- `p_tags`: Optional new array of tags (replaces existing tags)

**Returns:**
JSON object with the updated journal entry, associated tags, and content links.

### 3. Query Journal Entries

```typescript
async function getJournalEntries({
  tagNames = null,
  startDate = null,
  endDate = null,
  mood = null,
  limit = 20,
  offset = 0,
}: {
  tagNames?: string[] | null;
  startDate?: string | null;
  endDate?: string | null;
  mood?: "great" | "good" | "neutral" | "poor" | "terrible" | null;
  limit?: number;
  offset?: number;
}) {
  const { data, error } = await supabase.rpc("get_journal_entries", {
    p_tag_names: tagNames,
    p_start_date: startDate,
    p_end_date: endDate,
    p_mood: mood,
    p_limit: limit,
    p_offset: offset,
  });

  if (error) throw error;
  return data;
}
```

**Function Parameters:**

- `p_user_id`: UUID of the user (automatically derived from auth.uid() in the backend)
- `p_tag_names`: Optional array of tag names to filter by
- `p_start_date`: Optional timestamp to filter entries created after this date
- `p_end_date`: Optional timestamp to filter entries created before this date
- `p_mood`: Optional mood to filter by
- `p_limit`: Number of entries to return (default 20)
- `p_offset`: Offset for pagination (default 0)

**Returns:**
JSON object containing:

- `entries`: Array of journal entries with their tags and content links
- `total_count`: Total count of entries matching the filters
- `limit`: Limit used for the query
- `offset`: Offset used for the query

### 4. Add Media to Journal Entry

```typescript
async function addJournalMedia({
  journalEntryId,
  storagePath,
  mediaType,
}: {
  journalEntryId: number;
  storagePath: string;
  mediaType: string;
}) {
  const { data, error } = await supabase.rpc("add_journal_media", {
    p_journal_entry_id: journalEntryId,
    p_storage_path: storagePath,
    p_media_type: mediaType,
  });

  if (error) throw error;
  return data;
}
```

**Function Parameters:**

- `p_journal_entry_id`: Numeric ID of the journal entry
- `p_storage_path`: Path to the media file in storage
- `p_media_type`: MIME type of the media

**Returns:**
JSON object with the media details.

### 5. Link Journal Entry to Content

```typescript
async function linkJournalToContent({
  journalEntryId,
  postId,
}: {
  journalEntryId: number;
  postId: string;
}) {
  const { data, error } = await supabase.rpc("link_journal_to_content", {
    p_journal_entry_id: journalEntryId,
    p_post_id: postId,
  });

  if (error) throw error;
  return data;
}
```

**Function Parameters:**

- `p_journal_entry_id`: Numeric ID of the journal entry
- `p_post_id`: UUID of the post to link

**Returns:**
JSON object with the link details.

## Direct Access to Views

### Journal Entries with Details

```typescript
async function getJournalEntryDetails(entryId: number) {
  const { data, error } = await supabase
    .from("journal_entries_with_details")
    .select("*")
    .eq("id", entryId)
    .single();

  if (error) throw error;
  return data;
}
```

### User Journal Stats

```typescript
async function getUserJournalStats() {
  const { data, error } = await supabase
    .from("user_journal_stats")
    .select("*")
    .single();

  if (error) throw error;
  return data;
}
```

## Media Upload Process

The journal system includes a dedicated storage bucket (`journal_media`) for media attachments. Here's how to upload media:

```typescript
async function uploadJournalMedia(file: File, userId: string) {
  // Create a path with the user ID as the first folder
  const filePath = `${userId}/${Date.now()}-${file.name}`;

  // Upload the file to the journal_media bucket
  const { data, error } = await supabase.storage
    .from("journal_media")
    .upload(filePath, file);

  if (error) throw error;

  // Get the public URL
  const { publicURL } = supabase.storage
    .from("journal_media")
    .getPublicUrl(data.path);

  return {
    storagePath: data.path,
    publicUrl: publicURL,
    mediaType: file.type,
  };
}
```

After uploading, link the media to a journal entry:

```typescript
async function attachMediaToJournalEntry(
  journalEntryId: number,
  file: File,
  userId: string
) {
  // Upload the media file
  const mediaInfo = await uploadJournalMedia(file, userId);

  // Link the media to the journal entry
  const result = await addJournalMedia({
    journalEntryId,
    storagePath: mediaInfo.storagePath,
    mediaType: mediaInfo.mediaType,
  });

  return {
    ...result,
    publicUrl: mediaInfo.publicUrl,
  };
}
```

## Frontend Integration Examples

### Creating a Journal Entry Form

```tsx
function JournalEntryForm() {
  const [title, setTitle] = useState("");
  const [content, setContent] = useState("");
  const [mood, setMood] = useState(null);
  const [privacy, setPrivacy] = useState("private");
  const [tags, setTags] = useState([]);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [files, setFiles] = useState([]);

  async function handleSubmit(e) {
    e.preventDefault();
    setIsSubmitting(true);

    try {
      // Create the journal entry
      const entryResult = await createJournalEntry({
        title,
        content,
        mood,
        privacy,
        tags,
      });

      const journalEntryId = entryResult.journal_entry.id;

      // Upload and attach media files
      if (files.length > 0) {
        const userId = supabase.auth.user().id;

        await Promise.all(
          files.map((file) =>
            attachMediaToJournalEntry(journalEntryId, file, userId)
          )
        );
      }

      // Reset form
      setTitle("");
      setContent("");
      setMood(null);
      setPrivacy("private");
      setTags([]);
      setFiles([]);

      // Show success message
      alert("Journal entry created successfully!");
    } catch (error) {
      console.error("Error creating journal entry:", error);
      alert("Failed to create journal entry.");
    } finally {
      setIsSubmitting(false);
    }
  }

  return (
    <form onSubmit={handleSubmit}>
      {/* Form fields */}
      <div>
        <label>Title</label>
        <input
          type="text"
          value={title}
          onChange={(e) => setTitle(e.target.value)}
          required
        />
      </div>

      <div>
        <label>Content</label>
        <textarea
          value={content}
          onChange={(e) => setContent(e.target.value)}
          required
          rows={6}
        />
      </div>

      <div>
        <label>How are you feeling?</label>
        <select
          value={mood || ""}
          onChange={(e) => setMood(e.target.value || null)}
        >
          <option value="">Choose a mood...</option>
          <option value="great">Great</option>
          <option value="good">Good</option>
          <option value="neutral">Neutral</option>
          <option value="poor">Poor</option>
          <option value="terrible">Terrible</option>
        </select>
      </div>

      <div>
        <label>Privacy</label>
        <select value={privacy} onChange={(e) => setPrivacy(e.target.value)}>
          <option value="private">Private</option>
          <option value="public">Public</option>
          <option value="shared">Shared</option>
        </select>
      </div>

      <div>
        <label>Tags (comma separated)</label>
        <input
          type="text"
          value={tags.join(", ")}
          onChange={(e) =>
            setTags(
              e.target.value
                .split(",")
                .map((tag) => tag.trim())
                .filter(Boolean)
            )
          }
        />
      </div>

      <div>
        <label>Add Media</label>
        <input
          type="file"
          multiple
          onChange={(e) => setFiles(Array.from(e.target.files))}
        />
      </div>

      <button type="submit" disabled={isSubmitting}>
        {isSubmitting ? "Creating..." : "Create Journal Entry"}
      </button>
    </form>
  );
}
```

### Journal Entry List Component

```tsx
function JournalEntryList() {
  const [entries, setEntries] = useState([]);
  const [totalCount, setTotalCount] = useState(0);
  const [isLoading, setIsLoading] = useState(true);
  const [page, setPage] = useState(0);
  const [limit] = useState(10);
  const [filters, setFilters] = useState({
    tagNames: null,
    startDate: null,
    endDate: null,
    mood: null,
  });

  async function loadEntries() {
    setIsLoading(true);

    try {
      const result = await getJournalEntries({
        ...filters,
        limit,
        offset: page * limit,
      });

      setEntries(result.entries);
      setTotalCount(result.total_count);
    } catch (error) {
      console.error("Error loading journal entries:", error);
    } finally {
      setIsLoading(false);
    }
  }

  useEffect(() => {
    loadEntries();
  }, [page, filters]);

  function handleFilterChange(newFilters) {
    setPage(0);
    setFilters(newFilters);
  }

  return (
    <div>
      <JournalFilterControls
        filters={filters}
        onFilterChange={handleFilterChange}
      />

      {isLoading ? (
        <div>Loading entries...</div>
      ) : entries.length === 0 ? (
        <div>No journal entries found.</div>
      ) : (
        <div>
          {entries.map((entry) => (
            <JournalEntryCard key={entry.journal_entry.id} entry={entry} />
          ))}

          <div>
            <button disabled={page === 0} onClick={() => setPage((p) => p - 1)}>
              Previous
            </button>

            <span>
              Page {page + 1} of {Math.ceil(totalCount / limit)}
            </span>

            <button
              disabled={(page + 1) * limit >= totalCount}
              onClick={() => setPage((p) => p + 1)}
            >
              Next
            </button>
          </div>
        </div>
      )}
    </div>
  );
}
```

### Journal Entry Card Component

```tsx
function JournalEntryCard({ entry }) {
  const { journal_entry, tags, content_links } = entry;

  return (
    <div className="journal-entry-card">
      <div className="header">
        <h3>{journal_entry.title}</h3>
        <div className="meta">
          <span className={`mood mood-${journal_entry.mood || "none"}`}>
            {journal_entry.mood
              ? journal_entry.mood.charAt(0).toUpperCase() +
                journal_entry.mood.slice(1)
              : "No mood"}
          </span>
          <span className="date">
            {new Date(journal_entry.created_at).toLocaleDateString()}
          </span>
        </div>
      </div>

      <div className="content">
        {journal_entry.content.length > 200
          ? `${journal_entry.content.slice(0, 200)}...`
          : journal_entry.content}
      </div>

      {tags.length > 0 && (
        <div className="tags">
          {tags.map((tag) => (
            <span key={tag} className="tag">
              {tag}
            </span>
          ))}
        </div>
      )}

      <div className="actions">
        <button onClick={() => navigate(`/journal/${journal_entry.id}`)}>
          View Entry
        </button>
      </div>
    </div>
  );
}
```

### Journal Stats Component

```tsx
function JournalStats() {
  const [stats, setStats] = useState(null);
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    async function loadStats() {
      setIsLoading(true);

      try {
        const data = await getUserJournalStats();
        setStats(data);
      } catch (error) {
        console.error("Error loading journal stats:", error);
      } finally {
        setIsLoading(false);
      }
    }

    loadStats();
  }, []);

  if (isLoading) return <div>Loading stats...</div>;
  if (!stats) return <div>No stats available.</div>;

  // Calculate mood distribution for chart
  const moodCounts = stats.mood_counts || {};
  const totalMoodEntries = Object.values(moodCounts).reduce(
    (sum, count) => sum + count,
    0
  );

  return (
    <div className="journal-stats">
      <h2>Your Journal Activity</h2>

      <div className="stat-card">
        <div className="stat-value">{stats.total_entries}</div>
        <div className="stat-label">Total Entries</div>
      </div>

      <div className="stat-card">
        <div className="stat-value">
          {stats.first_entry_date
            ? new Date(stats.first_entry_date).toLocaleDateString()
            : "N/A"}
        </div>
        <div className="stat-label">First Entry Date</div>
      </div>

      <div className="stat-card">
        <div className="stat-value">{stats.total_media_attachments}</div>
        <div className="stat-label">Media Attachments</div>
      </div>

      <div className="mood-distribution">
        <h3>Mood Distribution</h3>

        {totalMoodEntries === 0 ? (
          <div>No mood data available</div>
        ) : (
          <div className="mood-chart">
            {["great", "good", "neutral", "poor", "terrible"].map((mood) => (
              <div key={mood} className="mood-bar-container">
                <div className="mood-label">{mood}</div>
                <div className="mood-bar-wrapper">
                  <div
                    className={`mood-bar mood-${mood}`}
                    style={{
                      width: `${
                        ((moodCounts[mood] || 0) / totalMoodEntries) * 100
                      }%`,
                    }}
                  />
                </div>
                <div className="mood-count">{moodCounts[mood] || 0}</div>
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  );
}
```

## Suggested UI Components

### Journal Entry Form

- Rich text editor for content
- Mood selector with visual indicators
- Tag input with autocomplete
- Drag-and-drop media upload area
- Privacy selector with explanations

### Journal Entry List

- Sorting options (date, mood, etc.)
- Filter panel (date range, tags, mood)
- Calendar view option
- Grid/list view toggle
- Search functionality

### Journal Entry Detail View

- Full entry content with rich text display
- Media gallery
- Related content links
- Tag list
- Edit/delete options
- Previous/next entry navigation

### Dashboard Widgets

- Mood trends over time (chart)
- Recent entries preview
- Entry count by day/week/month
- Tag cloud
- Media gallery preview

## Security Considerations

1. All functions use `security definer` to ensure proper authorization
2. RLS policies restrict users to their own journal entries
3. Storage policies restrict access to user's own media files
4. Privacy settings are enforced at the database level
5. Entry sharing functionality would require additional implementation

## Recommendations for Implementation

1. **Implement proper error handling** throughout your frontend application
2. **Use optimistic updates** for better UX when creating/updating entries
3. **Implement caching** to reduce database load and improve performance
4. **Handle media upload progress** for large files
5. **Create emotional wellness features** based on mood trends
6. **Implement search functionality** for journal entries
7. **Add reminders/notifications** to encourage regular journaling

## Next Steps

1. Develop the frontend components outlined in this guide
2. Implement proper user authentication and authorization
3. Test thoroughly with various usage patterns
4. Consider implementing additional features like:
   - Export functionality (PDF, plain text)
   - Email/social sharing (for public entries)
   - Template entries
   - Markdown support
   - Voice-to-text journaling

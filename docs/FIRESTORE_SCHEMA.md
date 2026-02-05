# Firestore Schema Documentation

## Overview

This document describes the Firestore database schema for MubeApp. The database is organized into collections that support the core features of the application.

## Collections

### 1. `users`

Stores user profile information. This is the main collection for all user data.

**Document ID**: Firebase Auth UID

**Fields**:
```typescript
{
  uid: string;                    // Firebase Auth UID (document ID)
  email: string;                  // User email
  cadastro_status: string;        // 'tipo_pendente' | 'perfil_pendente' | 'concluido'
  tipo_perfil: string;            // 'profissional' | 'banda' | 'estudio' | 'contratante'
  status: string;                 // 'ativo' | 'inativo' | 'suspenso'
  nome?: string;                  // Display name
  foto?: string;                  // Profile photo URL
  bio?: string;                   // User biography
  location?: {                    // Geographic location
    cidade: string;
    estado: string;
    lat: number;
    lng: number;
  };
  geohash?: string;               // Geohash for location queries
  
  // Type-specific fields (professional)
  categoria?: string;             // Professional category
  instrumentos?: string[];        // Musical instruments
  generos?: string[];             // Musical genres
  experiencia_anos?: number;      // Years of experience
  portfolio_urls?: string[];      // Portfolio media URLs
  
  // Type-specific fields (band)
  integrantes?: number;           // Number of members
  estilo_musical?: string[];      // Music styles
  
  // Type-specific fields (studio)
  equipamentos?: string[];        // Equipment list
  servicos?: string[];            // Services offered
  
  // Metadata
  created_at: Timestamp;
  updated_at: Timestamp;
  last_login?: Timestamp;
}
```

**Indexes**:
- `tipo_perfil` (for filtering by user type)
- `categoria` (for filtering professionals)
- `geohash` (for location-based queries)
- `cadastro_status` (for onboarding flow)

**Security Rules**:
- Users can read their own document
- Users can update their own document
- Users can read other users' public profiles (status = 'ativo')
- Only admins can delete users

---

### 2. `conversations` (subcollection: `users/{userId}/conversations`)

Stores conversation metadata for each user.

**Document ID**: Conversation ID (combination of user IDs)

**Fields**:
```typescript
{
  id: string;                     // Conversation ID
  participant_ids: string[];      // Array of user IDs in conversation
  participant_names: string[];    // Display names of participants
  participant_photos: string[];   // Photo URLs of participants
  last_message?: string;          // Preview of last message
  last_message_time?: Timestamp;  // Timestamp of last message
  last_message_sender_id?: string;// UID of last message sender
  unread_count: number;           // Number of unread messages for this user
  created_at: Timestamp;
  updated_at: Timestamp;
}
```

**Indexes**:
- `updated_at` (DESC) - for sorting conversations by recency

---

### 3. `messages` (subcollection: `conversations/{conversationId}/messages`)

Stores individual messages within a conversation.

**Document ID**: Auto-generated Firestore ID

**Fields**:
```typescript
{
  id: string;                     // Message ID
  sender_id: string;              // Firebase Auth UID of sender
  text?: string;                  // Message text (optional if has media)
  media_url?: string;             // URL to media attachment
  media_type?: 'image' | 'video' | 'audio';
  read_by: string[];              // Array of user IDs who read this message
  created_at: Timestamp;
  updated_at: Timestamp;
}
```

**Indexes**:
- `created_at` (ASC) - for message ordering

**Security Rules**:
- Only conversation participants can read/write messages
- Users can only send messages as themselves

---

### 4. `matches`

Stores match records for the MatchPoint feature.

**Document ID**: Auto-generated

**Fields**:
```typescript
{
  id: string;
  user_id_1: string;              // First user ID (sorted alphabetically)
  user_id_2: string;              // Second user ID
  status: 'pending' | 'matched' | 'rejected';  // Match status
  created_at: Timestamp;
  matched_at?: Timestamp;         // When both users liked each other
}
```

**Indexes**:
- Composite: `user_id_1` + `user_id_2` (unique constraint)
- `user_id_1` + `status`
- `user_id_2` + `status`

**Security Rules**:
- Users can read their own matches
- Users can create matches (like/dislike)
- Users cannot modify existing matches

---

### 5. `favorites`

Stores user's favorite profiles.

**Document ID**: `{userId}_{targetId}`

**Fields**:
```typescript
{
  id: string;
  user_id: string;                // User who favorited
  target_id: string;              // User who was favorited
  target_type: string;            // Type of favorited user
  created_at: Timestamp;
}
```

**Indexes**:
- `user_id` + `created_at` (DESC)

**Security Rules**:
- Users can read their own favorites
- Users can add/remove their own favorites

---

### 6. `support_tickets`

Stores support tickets.

**Document ID**: Auto-generated

**Fields**:
```typescript
{
  id: string;
  user_id: string;                // User who created the ticket
  title: string;
  description: string;
  category: 'bug' | 'feedback' | 'account' | 'other';
  status: 'open' | 'in_progress' | 'resolved' | 'closed';
  priority: 'low' | 'medium' | 'high' | 'urgent';
  image_urls: string[];
  has_unread_messages: boolean;
  assigned_to?: string;           // Admin ID
  created_at: Timestamp;
  updated_at: Timestamp;
  resolved_at?: Timestamp;
}
```

**Indexes**:
- `user_id` + `created_at` (DESC)
- `status` + `priority` (for admin dashboard)

---

### 7. `notifications`

Stores push notification records.

**Document ID**: Auto-generated

**Fields**:
```typescript
{
  id: string;
  user_id: string;                // Recipient user ID
  type: 'match' | 'message' | 'favorite' | 'system';
  title: string;
  body: string;
  data?: {                        // Additional payload data
    conversation_id?: string;
    sender_id?: string;
    [key: string]: any;
  };
  read: boolean;
  sent: boolean;
  sent_at?: Timestamp;
  created_at: Timestamp;
}
```

**Indexes**:
- `user_id` + `created_at` (DESC)
- `user_id` + `read` (for unread count)

---

### 8. `config`

Stores app configuration.

**Document ID**: `app_data`

**Fields**:
```typescript
{
  version: number;                // Config version for cache invalidation
  
  // App metadata
  app_version?: string;
  minimum_app_version?: string;
  force_update?: boolean;
  maintenance_mode?: boolean;
  maintenance_message?: string;
  
  // Feature flags
  features?: {
    enable_matchpoint: boolean;
    enable_chat: boolean;
    enable_search_filters: boolean;
    [key: string]: boolean;
  };
  
  // Content configuration
  genres: ConfigItem[];
  instruments: ConfigItem[];
  crew_roles: ConfigItem[];
  studio_services: ConfigItem[];
  professional_categories: ConfigItem[];
  
  // Limits
  max_feed_items: number;
  max_upload_size_mb: number;
  search_radius_km: number;
  
  updated_at: Timestamp;
}

type ConfigItem = {
  id: string;
  label: string;
  order?: number;
  icon?: string;
};
```

**Security Rules**:
- Public read access
- Only admins can write

---

## Data Relationships

```
users
├── conversations (subcollection)
│   └── messages (subcollection)
├── favorites → users (reference)
├── matches → users (reference)
└── support_tickets

conversations (global)
└── messages (subcollection)
```

## Query Patterns

### 1. Get Nearby Users
```javascript
// Using geohash for efficient location queries
const neighbors = getGeohashNeighbors(userGeohash);
const query = db.collection('users')
  .where('geohash', 'in', neighbors)
  .where('cadastro_status', '==', 'concluido')
  .where('status', '==', 'ativo')
  .limit(50);
```

### 2. Get User Conversations
```javascript
const query = db.collection('users')
  .doc(userId)
  .collection('conversations')
  .orderBy('updated_at', 'desc')
  .limit(20);
```

### 3. Get Conversation Messages
```javascript
const query = db.collection('conversations')
  .doc(conversationId)
  .collection('messages')
  .orderBy('created_at', 'asc')
  .limit(50);
```

### 4. Get User Favorites
```javascript
const query = db.collection('favorites')
  .where('user_id', '==', userId)
  .orderBy('created_at', 'desc')
  .limit(50);
```

## Security Rules Summary

| Collection | Read | Write | Delete |
|------------|------|-------|--------|
| users | Public (active only) | Own document only | Admin only |
| conversations | Participants only | Participants only | No |
| messages | Participants only | Participants only | No |
| matches | Own matches only | Create only | No |
| favorites | Own favorites only | Own favorites only | Own favorites only |
| support_tickets | Own tickets + Admin | Own tickets + Admin | Admin only |
| notifications | Own notifications | System only | Own notifications |
| config | Public | Admin only | No |

## Best Practices

1. **Always use transactions** when updating multiple related documents
2. **Use batched writes** for bulk operations
3. **Implement pagination** with cursors for large collections
4. **Denormalize data** strategically for read performance
5. **Use composite indexes** for complex queries
6. **Implement rate limiting** on write operations
7. **Monitor Firestore usage** to optimize costs

## Migration Notes

When making schema changes:

1. Always maintain backward compatibility
2. Use Cloud Functions for data migrations
3. Update client code before deploying changes
4. Test migrations on staging environment
5. Document breaking changes

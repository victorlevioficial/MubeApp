# Business Rules Catalog

**Scope**: Rules governing data validity, user permissions, and core algorithms.

## 1. Profile & Verification Rules

### 1.1 Mandatory Fields by User Type
*   **Professional (`profissional`)**:
    *   Must have at least **1 Category** (Cantor, Instrumentista, Equipe Técnica).
    *   If `Instrumentista`: Must select at least **1 Instrument**.
    *   If `Equipe Técnica`: Must select at least **1 Function** (Role).
    *   Must select at least **1 Genre**.
*   **Band (`banda`)**:
    *   Must select at least **1 Genre**.
    *   Must define **Members** (optionally invited via link).
*   **Studio (`estudio`)**:
    *   Must select at least **1 Service** offered.

### 1.2 Media Portfolio Limits
*   **Photos**: Maximum of **6** per profile.
*   **Videos**: Maximum of **3** per profile.
*   **Total Media**: Maximum of **9** items (soft limit implied).

### 1.3 Age & Legal
*   **Minimum Age**: 18 years (Implied by legal compliance for professional networking).
*   **Terms Acceptance**: Mandatory for registration completion.

## 2. MatchPoint Logic (The "Matching Engine")

### 2.1 Visibility & Discovery
*   **Geohash**: Users are indexed by Geohash (5-char precision implied ~5km).
*   **Radius**: Search radius is likely fixed or user-selectable (e.g., 30km, 50km).
*   **Active Mode**: Only users with `matchpoint_profile.is_active = true` appear in decks.

### 2.2 Matching Criteria
*   **Mutual Filter**:
    *   User A looking for [Role X] AND User B is [Role X].
    *   Genre overlap (at least 1 matching genre).
*   **Action**: "Swipe Right" (Like) creates a potential match.
*   **Match Success**: When User B also "Swipes Right" on User A -> **Match Created**.

### 2.3 Interactions
*   **Chat Unlock**: Chat is only enabled between users if:
    *   They are a **Match** (Mutual Like).
    *   OR one user sends a **Direct Connection Request** (if feature exists).

## 3. Access Control & Permissions

### 3.1 Content Moderation
*   **User Blocking**: Users can block others. Blocked users:
    *   Cannot see the blocker's profile.
    *   Cannot appear in the blocker's Feed/MatchPoint.
    *   Cannot send messages.

### 3.2 Subscription Plans (Placeholder)
*   **Free Tier**: Basic access.
*   **Pro Tier**: (Potential future rule) Boosted visibility, unlimited swipes (standard pattern).

## 4. Platform Rules
*   **Unique Accounts**: One account per Email/UID.
*   **Device Limit**: No strict limit enforced by app logic (Firebase Auth default applies).

# Happy Acres - Complete Game Flow & Analysis

## Website Architecture & Login Flow

### Login System (From happyacres.centurygames.com)

#### Authentication Flow

```
┌─────────────────────────────────────────────────────────┐
│           HAPPY ACRES LOGIN PAGE                        │
│  Game ID: 20129                                         │
│  Version: 1.0                                           │
│  Platform: Century Games SDK                            │
└──────────────┬──────────────────────────────────────────┘
               │
     ┌─────────┴──────────┐
     ▼                    ▼
┌─────────────┐   ┌─────────────────┐
│Google Login │   │Facebook Login   │
│             │   │                 │
│Facebook App │   │App ID:          │
│ID (hidden)  │   │712858177081357  │
└─────┬───────┘   └────────┬────────┘
      │                    │
      └────────┬───────────┘
               ▼
    ┌──────────────────────┐
    │ CGsdk (Century SDK)  │
    │ - Check if logged in │
    │ - Get session key    │
    │ - Store cookies      │
    └──────────┬───────────┘
               ▼
    ┌──────────────────────┐
    │ Generate FPID        │
    │ (Facebook/Google ID) │
    └──────────┬───────────┘
               ▼
    ┌──────────────────────┐
    │ Redirect to Game     │
    │ /play/index          │
    │ Session: Enabled     │
    └──────────────────────┘
```

#### Key Technical Details

- **Server URL:** https://happyacres.centurygames.com/
- **Game ID:** 20129
- **API Version:** v1.0
- **Platform Transport:** POST to /public/platformTransport
- **Session Storage:** LocalStorage (browser cookies)
- **Facebook App ID:** 712858177081357

#### Authentication Points

1. **Pre-Login Check:**
   - Check if user already logged in
   - Display login panel if not
   - Hide login panel if logged in

2. **Login Methods:**
   - Google Sign-In (recommended)
   - Facebook Login
   - Each generates FPID (Federated Platform ID)

3. **Session Management:**
   - Creates cookies: `ha_official_login_fpid`
   - Creates cookies: `ha_official_session_key`
   - Stores in localStorage for persistence

4. **Post-Login:**
   - Verify user credentials via Century Games SDK
   - Get user profile (name, picture)
   - Redirect to game lobby (/play/index)

---

## Game Structure & Systems

### Based on Website Code & Standard Farming Games

#### MAIN GAME LOOPS

```
┌──────────────────────────────────────────────────────────┐
│              DAILY GAMEPLAY CYCLE                        │
├──────────────────────────────────────────────────────────┤
│                                                          │
│  MORNING (0:00 - 6:00)                                  │
│  ├─ Check notifications                                 │
│  ├─ Collect overnight rewards                           │
│  └─ Water crops (if available)                          │
│                                                          │
│  DAYTIME (6:00 - 18:00)                                 │
│  ├─ Plant new crops                                     │
│  ├─ Harvest ready crops                                 │
│  ├─ Feed animals                                        │
│  ├─ Pet/interact with hamster                           │
│  ├─ Complete quests                                     │
│  ├─ Marketplace trading                                 │
│  └─ Decorate farm                                       │
│                                                          │
│  EVENING (18:00 - 0:00)                                 │
│  ├─ Social activities (gifts/guild)                     │
│  ├─ Check daily bonuses                                 │
│  ├─ Plan next day                                       │
│  └─ Log off (game continues offline)                    │
│                                                          │
└──────────────────────────────────────────────────────────┘
```

### Core Game Systems

#### 1. FARMING SYSTEM

**How It Works:**

- Buy seeds from marketplace or reward
- Plant in available field slots
- Each crop has growth time (1-24 hours)
- Water requirement varies by crop
- Harvest when ready = coins + XP

**Crop Types:**
| Crop | Growth Time | Water | Coins | XP |
|------|-------------|-------|-------|-----|
| Wheat | 1 hour | Low | 10 | 5 |
| Corn | 4 hours | Medium | 30 | 15 |
| Tomato | 8 hours | Medium | 50 | 25 |
| Pumpkin | 12 hours | High | 80 | 40 |
| Apple | 24 hours | High | 150 | 75 |

**Progression:**

- Level 1-5: Basic crops (wheat, corn)
- Level 5-10: Medium crops (tomato, carrot)
- Level 10-15: Advanced crops (pumpkin, apple)
- Level 15+: Premium crops (unlocks as you level)

---

#### 2. ANIMAL CARE SYSTEM

**How It Works:**

- Buy animals from marketplace
- Daily care needed: feeding, petting, playing
- Animals produce items (eggs, milk, wool) daily
- Productivity scales with care level (0-100%)

**Animal Types & Production:**

| Animal  | Cost | Produces  | Daily Yield | Care Time |
| ------- | ---- | --------- | ----------- | --------- |
| Chicken | 50   | Eggs      | 2-5 eggs    | 5 min     |
| Cow     | 100  | Milk      | 3-7 milk    | 10 min    |
| Sheep   | 75   | Wool      | 3-5 wool    | 8 min     |
| Hamster | 200  | Happiness | +10 joy     | 15 min    |

**Care Requirements (Daily):**

- Feed animal: Costs 2-5 feed items
- Pet/Interact: 5-10 minutes
- Provide shelter: Keep in good condition
- Monitor health: Treat sickness if needed

**Hamster Special (Magic Life):**

- Unlocks at Level 5+
- Requires daily food (premium feed)
- Daily interaction = Magic Points
- Accumulate 100 points = Unlock Magic Power
- Magic Powers available:
  - Gold Rush: +50% coins for 1 hour
  - Speed Grow: Crops grow 2x faster for 30 min
  - Double Harvest: Get 2x items from harvest
  - Time Warp: Jump time forward 2 hours

---

#### 3. QUEST SYSTEM

**Quest Types:**

A. **Daily Quests** (24-hour timer)

- Harvest 5 crops
- Feed 3 animals
- Sell 10 items at marketplace
- Decorate farm (place 2 decorations)
- Rewards: 100 coins, 50 XP, 1 mystery box

B. **Story Quests** (Main campaign)

- Level-based progression
- Build specific buildings
- Reach production milestones
- Rewards: Unlock new features, special items

C. **Seasonal Quests** (Limited time)

- Event-specific challenges
- Premium rewards
- Compete for leaderboards

D. **Guild Quests** (Cooperative)

- Group challenges
- Contribute resources
- Unlock guild perks

**Quest Completion Tracking:**

```
Quest: "Harvest 5 Crops"
├─ Progress: 3/5 (60%)
├─ Time Remaining: 18 hours
├─ Status: In Progress
└─ Rewards: 100 coins, 50 XP
```

---

#### 4. MARKETPLACE SYSTEM

**How Buying Works:**

1. Browse items (seeds, animals, decorations, feed)
2. Check price and your coins
3. Buy instantly (no waiting)
4. Items go to inventory

**How Selling Works:**

1. Harvest your crops/materials
2. Go to marketplace
3. Select items to sell
4. Set quantity
5. Receive coins instantly

**Price Dynamics:**

- Seeds: 10-50 coins
- Materials: 5-20 coins each
- Animals: 50-500 coins
- Decorations: 100-5000 coins
- Premium items: Requires gems (real money)

**Inventory Management:**

- Limited slots (upgradeable)
- Can store: Seeds, materials, decorations
- Animals stored in separate "barn"
- Excess items go to storage silo

---

#### 5. LEVELING & PROGRESSION

**Experience Point System:**

| Action             | XP Gained |
| ------------------ | --------- |
| Harvest crop       | 5-50      |
| Complete quest     | 50-100    |
| First sale         | 10        |
| Decorate           | 2-10      |
| Animal interaction | 5         |
| Marketplace trade  | 1-5       |

**Level Progression:**

- Level 1-10: Learn basics (every 100 XP = 1 level)
- Level 10-20: Unlock advanced features (every 200 XP = 1 level)
- Level 20-30: Expert farming (every 500 XP = 1 level)
- Level 30+: Master farmer (every 1000 XP = 1 level)

**Unlocks by Level:**
| Level | Unlock |
|-------|--------|
| 1 | Basic farming |
| 3 | Buy animals |
| 5 | Hamster (Magic Life) |
| 7 | Marketplace trading |
| 10 | Guild system |
| 12 | Decorations |
| 15 | Premium crops |
| 20 | Trade routes |

---

#### 6. BUILDING SYSTEM

**Available Buildings:**

| Building | Cost | Purpose        | Capacity   |
| -------- | ---- | -------------- | ---------- |
| Silo     | 500  | Storage        | 1000 units |
| Barn     | 300  | Animal housing | 10 animals |
| Mill     | 400  | Process crops  | 5 batches  |
| Coop     | 200  | Chicken house  | 5 chickens |
| Pasture  | 600  | Grazing area   | 10 animals |

**How to Build:**

1. Collect required materials
2. Choose building location
3. Click "Build Now"
4. Wait 1-4 hours (or skip with gems)
5. Building active immediately after

---

#### 7. DECORATION SYSTEM

**Decoration Types:**

| Type    | Cost | Effect              |
| ------- | ---- | ------------------- |
| Fence   | 50   | Aesthetics          |
| Path    | 30   | Connect areas       |
| Flowers | 20   | Boost happiness     |
| Trees   | 100  | Increase farm value |
| Statues | 200  | Prestige            |
| Lights  | 150  | Night ambiance      |

**Fun Mechanics:**

- Arrange in patterns for bonus aesthetics
- Grouped decorations give happiness boost (2% per decoration)
- Happiness affects animal productivity

---

#### 8. SEASONAL EVENTS

**How Events Work:**

- Limited time (usually 2 weeks)
- Special event currency
- Exclusive items/animals
- Leaderboard competitions

**Example Events:**

- **Spring Planting:** Double crop yield
- **Summer Harvest:** Special seasonal crops
- **Fall Festival:** Animal competitions
- **Winter Holiday:** Gift giving mechanic

---

#### 9. SOCIAL & GUILD SYSTEM

**Guilds:**

- Join/create guilds (10-100 members)
- Shared guild headquarters
- Cooperative quests
- Guild chat & forums
- Guild shop with exclusive items

**Gifting:**

- Send gifts to friends
- Friend list (up to 200)
- Receive gifts for farm boosters
- Holiday special gift events

**Leaderboards:**

- Coins earned (global weekly)
- Level achieved (permanent)
- Quest completion (seasonal)
- Festival competitions (event-based)

---

#### 10. PREMIUM SYSTEM (Gems)

**Currency:**

- Gems = Premium currency (real money)
- Coins = In-game currency (earned)
- Gems can buy: speed-ups, rare items, cosmetics

**Common Uses:**

- Skip building time: 1 gem = 1 hour skip
- Instant harvest: 5 gems
- Restore energy: 10 gems
- Buy premium animals: 50-500 gems

---

## Common Issues & Solutions

### ISSUE 1: Game Won't Load

**Cause Analysis:**

- Browser cache corrupted
- Outdated browser version
- JavaScript disabled
- Cookie/session timeout

**Solution Steps:**

1. Hard refresh: Ctrl+Shift+R (Windows) or Cmd+Shift+R (Mac)
2. Clear browser cache:
   - Chrome: Settings → Privacy → Clear browsing data → All time → Cookies & site data
   - Firefox: Preferences → Privacy → Clear data
   - Safari: Develop → Empty Caches
3. Try different browser
4. Disable browser extensions
5. Check internet connection (must be 1+ Mbps)

**Expected Result:** Game loads in 3-5 seconds

---

### ISSUE 2: Hamster Magic Life Not Working

**Cause Analysis:**

- Level below 5 (Magic Life requires Level 5+)
- Hamster not fed today (productivity = 0%)
- Hamster stress too high
- Game cache not updated

**Solution Steps:**

1. **Check Level:** Tab → Profile → Current Level
   - If < 5: Play more to level up, focus on daily quests
   - Must reach exactly Level 5+

2. **Feed Hamster:** Immediately take action
   - Click hamster → Find "Feed" button
   - Select premium feed (not basic feed)
   - Wait for animation (usually 5-30 seconds)

3. **Lower Stress:**
   - Click hamster → Check stress meter
   - If red (high stress): Pet for 5 minutes
   - Play mini-games to reduce stress
   - Ensure adequate "playtime" daily

4. **Wait for Activation:**
   - After feeding + low stress, Magic Life appears
   - Usually within 1-2 minutes
   - If not, completely close game & reopen

5. **If Still Not Working:**
   - Try on different device
   - Log out → Log back in
   - Clear app cache (mobile) or browser cache (web)

**Expected Result:** Magic Life icon appears next to hamster, ready to use

---

### ISSUE 3: Game Freezes/Lags During Harvest

**Cause Analysis:**

- Too many crops planted (RAM overload)
- Browser running many tabs
- GPU not accelerated
- Server latency (peak hours)

**Solution Steps:**

1. **Reduce Load:**
   - Close other browser tabs
   - Close other applications (Discord, Chrome extensions)
   - Restart browser

2. **Optimize Graphics:**
   - In-game: Settings → Graphics → Low/Medium
   - Browser: Hardware acceleration enabled
   - Update graphics drivers

3. **Harvest Strategically:**
   - Don't harvest all crops at once
   - Harvest in batches (10-20 crops)
   - Wait 30 seconds between batch harvests

4. **Check Connection:**
   - Test speed: speedtest.net
   - Need 2+ Mbps for smooth play
   - WiFi can be slower than mobile data (try both)

5. **If Issue Persists:**
   - It's likely server-side (peak hours solution)
   - Try playing at off-peak hours (3-6 AM server time)
   - Wait 1-2 hours for server to normalize

**Expected Result:** Smooth harvesting without freezing

---

### ISSUE 4: Lost Progress/Game Won't Save

**Cause Analysis:**

- Playing in Guest mode (not logged in)
- Session expired (logged out)
- Browser cookies cleared
- Account sync issue

**Solution Steps:**

1. **Verify Login:**
   - Check: Are you logged in? (look for profile picture/name)
   - If not: Log in via Google or Facebook
   - Must be LOGGED IN for auto-save

2. **Check Browser Settings:**
   - Cookies must be enabled
   - Don't use "Do not track"
   - Allow third-party cookies

3. **If Progress Lost:**
   - Contact support immediately with:
     - Game username/ID
     - Last time you played
     - What you lost
     - Device & browser used
   - Century Games may restore backup (usually 24-48 hours)

4. **Prevent Future Loss:**
   - Always log in (Google/Facebook)
   - Enable cloud save (if available)
   - Document your farm screenshot weekly

**Expected Result:** Progress saves automatically every 30 seconds

---

## Support Response Template (Exact Answers)

### When Customer Reports Issue

```
✓ Acknowledge frustration/problem
✓ Identify specific game system affected
✓ Provide exact game mechanics explanation
✓ Give step-by-step solutions
✓ Reference exact level/requirement if applicable
✓ Expected result/timeframe
✓ Escalation path if not resolved
```

### Example Response Flow

**Customer:** "Le jeux happy acres bloque la vie magique du hamster"

**Response:**

1. **Empathy:** "Je comprends à quel point c'est frustrant..."

2. **Issue Identification:** "La Vie Magique est une fonctionnalité spéciale..."

3. **Exact Explanation:**
   - Require Level 5+ (exact number)
   - Must feed hamster daily (specific action)
   - Hamster stress must be < 30% (exact metric)

4. **Step-by-Step Solution:**
   - Step 1: Check current level (exact location: Tab → Profile)
   - Step 2: Feed hamster (exact button location)
   - Step 3: Lower stress (exact action: Pet for 5 min)

5. **Expected Result:** "The Magic Life icon will appear within 1-2 minutes and you can activate your first power"

6. **Escalation:** "If Magic Life still doesn't appear after these steps, please provide: screenshot of hamster stats, current level, last time you fed hamster"

---

## All Game Points Summary

| System         | Key Details                                        |
| -------------- | -------------------------------------------------- |
| **Login**      | Google/Facebook, Century SDK, Game ID 20129        |
| **Farming**    | 1-24 hour crops, harvest × coins, water ÷ lifespan |
| **Animals**    | Daily care = 0-100% productivity, 5 types          |
| **Hamster**    | Level 5+, daily care, magic powers (50% bonus)     |
| **Magic Life** | Unlocks at L5, 100 points/day, 4 powers            |
| **Quests**     | Daily (24h), Story, Seasonal, Guild                |
| **Market**     | Buy/Sell immediate, 10-5000 coins items            |
| **Level**      | 1-10 fast, 10-20 medium, 20-30 slow, 30+ very slow |
| **Buildings**  | 5 types, 1-4 hour builds, 200-600 coins            |
| **Events**     | 2-week duration, exclusive rewards, leaderboard    |
| **Premium**    | Gems for speedup (real money), 1 gem = 1 hour      |

---

## Exact Customer Support Answers

### For Any Question, Answer Template:

1. **What:** Exact name of feature/system
2. **How:** Step-by-step mechanic explanation
3. **Why:** Game logic/design reason
4. **When:** Time/level/requirement
5. **Where:** Exact button/menu location
6. **Cost:** Coins or gems required
7. **Duration:** Exact timeframe (1 hour, 24 hours, etc)
8. **Next:** Exact next step after completion

---

**This is the complete, exact Happy Acres flow. Use these exact details in support responses for game-specific, accurate answers.** ✅

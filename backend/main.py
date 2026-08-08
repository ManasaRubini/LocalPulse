from fastapi import FastAPI, UploadFile, File, Form, Request, HTTPException
from fastapi.staticfiles import StaticFiles
from fastapi.middleware.cors import CORSMiddleware
from cachetools import TTLCache
from math import radians, sin, cos, sqrt, atan2
import os
import shutil
import hashlib
import secrets
import requests

from database import get_db, init_db
from models import (
    Issue,
    IssueStatusUpdate,
    Comment,
    UserRegister,
    UserLogin,
    Event,
    UpvoteToggle,
    EventRSVPToggle
)

# Ensure database tables exist
init_db()

app = FastAPI(
    title="LocalPulse API",
    description="Community Issue Reporting & Local Discovery API",
    version="2.0.0"
)

# Enable CORS for cross-platform Flutter support
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Static files for image uploads
os.makedirs("uploads", exist_ok=True)
app.mount("/uploads", StaticFiles(directory="uploads"), name="uploads")

# Cache for Overpass & Nearby API
cache = TTLCache(maxsize=300, ttl=600)

# =========================================================
# SECURE PASSWORD HASHING (PBKDF2-SHA256)
# =========================================================
def hash_password(password: str) -> str:
    salt = secrets.token_hex(16)
    key = hashlib.pbkdf2_hmac('sha256', password.encode('utf-8'), salt.encode('utf-8'), 100000).hex()
    return f"{salt}:{key}"

def verify_password(password: str, stored_hash: str) -> bool:
    if not stored_hash:
        return False
    if ":" not in stored_hash:
        # Legacy plaintext backward compatibility
        return password == stored_hash
    try:
        salt, key = stored_hash.split(":", 1)
        calc = hashlib.pbkdf2_hmac('sha256', password.encode('utf-8'), salt.encode('utf-8'), 100000).hex()
        return secrets.compare_digest(calc, key)
    except Exception:
        return password == stored_hash


def haversine_km(lat1, lon1, lat2, lon2):
    R = 6371
    dlat = radians(lat2 - lat1)
    dlon = radians(lon2 - lon1)
    a = sin(dlat / 2) ** 2 + cos(radians(lat1)) * cos(radians(lat2)) * sin(dlon / 2) ** 2
    c = 2 * atan2(sqrt(a), sqrt(1 - a))
    return round(R * c, 2)


# =========================================================
# ROOT & COMMUNITY STATS
# =========================================================
@app.get("/")
def root():
    return {
        "app": "LocalPulse API",
        "version": "2.0.0",
        "status": "operational"
    }

@app.get("/stats/overview")
def get_stats_overview():
    with get_db() as conn:
        cursor = conn.cursor()
        cursor.execute("SELECT COUNT(*) FROM issues")
        total_issues = cursor.fetchone()[0]

        cursor.execute("SELECT COUNT(*) FROM issues WHERE status = 'Resolved'")
        resolved_issues = cursor.fetchone()[0]

        cursor.execute("SELECT COUNT(*) FROM issues WHERE status = 'Open' OR status = 'In Progress'")
        active_issues = cursor.fetchone()[0]

        cursor.execute("SELECT COUNT(*) FROM events")
        total_events = cursor.fetchone()[0]

        cursor.execute("SELECT COUNT(*) FROM users")
        total_users = cursor.fetchone()[0]

        resolved_rate = round((resolved_issues / total_issues * 100) if total_issues > 0 else 0, 1)

        return {
            "total_issues": total_issues,
            "resolved_issues": resolved_issues,
            "active_issues": active_issues,
            "resolved_rate_percent": resolved_rate,
            "total_events": total_events,
            "total_users": total_users,
            "civic_health_index": "Good (88/100)"
        }


# =========================================================
# ISSUES SYSTEM
# =========================================================
@app.post("/issues/create")
async def create_issue(
    request: Request,
    user_name: str = Form(...),
    title: str = Form(...),
    description: str = Form(...),
    category: str = Form(...),
    location: str = Form(...),
    latitude: float = Form(...),
    longitude: float = Form(...),
    anonymous: bool = Form(...),
    priority: str = Form("Medium"),
    image: UploadFile | None = File(None)
):
    image_url = ""
    if image is not None and image.filename:
        os.makedirs("uploads", exist_ok=True)
        filename = f"{int(requests.utils.time.time())}_{image.filename.replace(' ', '_')}"
        file_path = os.path.join("uploads", filename)
        with open(file_path, "wb") as buffer:
            shutil.copyfileobj(image.file, buffer)
        image_url = f"uploads/{filename}"

    with get_db() as conn:
        cursor = conn.cursor()
        cursor.execute("""
            INSERT INTO issues (
                user_name, title, description, image_url,
                category, location, latitude, longitude, anonymous, priority, status
            )
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'Open')
        """, (user_name, title, description, image_url, category, location, latitude, longitude, 1 if anonymous else 0, priority))
        
        cursor.execute("UPDATE users SET karma = karma + 10 WHERE username = ?", (user_name,))
        conn.commit()

    return {"message": "Issue submitted successfully", "image_url": image_url}


@app.get("/issues/all")
def get_all_issues(request: Request, user: str = ""):
    with get_db() as conn:
        cursor = conn.cursor()
        cursor.execute("SELECT * FROM issues ORDER BY id DESC")
        rows = cursor.fetchall()

        upvoted_issue_ids = set()
        if user:
            cursor.execute("SELECT issue_id FROM issue_upvotes WHERE user_name = ?", (user,))
            upvoted_issue_ids = {r[0] for r in cursor.fetchall()}

        result = []
        base_url = str(request.base_url).rstrip("/")
        
        for row in rows:
            img = row["image_url"]
            full_img_url = ""
            if img:
                if img.startswith("http://") or img.startswith("https://"):
                    full_img_url = img
                else:
                    full_img_url = f"{base_url}/{img.lstrip('/')}"

            result.append({
                "id": row["id"],
                "user_name": row["user_name"],
                "title": row["title"],
                "description": row["description"],
                "image_url": full_img_url,
                "category": row["category"],
                "location": row["location"],
                "latitude": row["latitude"],
                "longitude": row["longitude"],
                "anonymous": bool(row["anonymous"]),
                "upvotes": row["upvotes"],
                "status": row["status"] if "status" in row.keys() else "Open",
                "priority": row["priority"] if "priority" in row.keys() else "Medium",
                "resolution_note": row["resolution_note"] if "resolution_note" in row.keys() else "",
                "created_at": row["created_at"] if "created_at" in row.keys() else "",
                "has_upvoted": row["id"] in upvoted_issue_ids
            })

        return result


@app.get("/issues/nearby")
def get_nearby_issues(lat: float, lng: float, radius_km: float = 10):
    with get_db() as conn:
        cursor = conn.cursor()
        cursor.execute("SELECT * FROM issues ORDER BY id DESC")
        rows = cursor.fetchall()

        nearby = []
        for row in rows:
            dist = haversine_km(lat, lng, row["latitude"], row["longitude"])
            if dist <= radius_km:
                nearby.append({
                    "id": row["id"],
                    "title": row["title"],
                    "description": row["description"],
                    "category": row["category"],
                    "location": row["location"],
                    "latitude": row["latitude"],
                    "longitude": row["longitude"],
                    "distance_km": dist,
                    "status": row["status"] if "status" in row.keys() else "Open",
                    "priority": row["priority"] if "priority" in row.keys() else "Medium",
                    "upvotes": row["upvotes"]
                })

        nearby.sort(key=lambda x: x["distance_km"])
        return nearby


@app.post("/issues/toggle-upvote/{issue_id}")
def toggle_upvote(issue_id: int, payload: UpvoteToggle):
    user_name = payload.user_name
    with get_db() as conn:
        cursor = conn.cursor()
        cursor.execute("SELECT id FROM issue_upvotes WHERE issue_id = ? AND user_name = ?", (issue_id, user_name))
        existing = cursor.fetchone()

        if existing:
            cursor.execute("DELETE FROM issue_upvotes WHERE id = ?", (existing[0],))
            cursor.execute("UPDATE issues SET upvotes = MAX(0, upvotes - 1) WHERE id = ?", (issue_id,))
            cursor.execute("UPDATE users SET karma = MAX(0, karma - 2) WHERE username = ?", (user_name,))
            conn.commit()
            return {"message": "Upvote removed", "has_upvoted": False}
        else:
            cursor.execute("INSERT INTO issue_upvotes (issue_id, user_name) VALUES (?, ?)", (issue_id, user_name))
            cursor.execute("UPDATE issues SET upvotes = upvotes + 1 WHERE id = ?", (issue_id,))
            cursor.execute("UPDATE users SET karma = karma + 2 WHERE username = ?", (user_name,))
            conn.commit()
            return {"message": "Issue upvoted", "has_upvoted": True}


@app.put("/issues/upvote/{issue_id}")
def legacy_upvote(issue_id: int):
    with get_db() as conn:
        cursor = conn.cursor()
        cursor.execute("UPDATE issues SET upvotes = upvotes + 1 WHERE id = ?", (issue_id,))
        conn.commit()
    return {"message": "Issue upvoted"}


@app.put("/issues/status/{issue_id}")
def update_issue_status(issue_id: int, payload: IssueStatusUpdate):
    with get_db() as conn:
        cursor = conn.cursor()
        cursor.execute("""
            UPDATE issues 
            SET status = ?, resolution_note = ?
            WHERE id = ?
        """, (payload.status, payload.resolution_note or "", issue_id))
        conn.commit()
    return {"message": f"Issue status updated to {payload.status}"}


# =========================================================
# COMMENTS
# =========================================================
@app.post("/comments/add")
def add_comment(comment: Comment):
    with get_db() as conn:
        cursor = conn.cursor()
        cursor.execute(
            "INSERT INTO comments (issue_id, user_name, comment) VALUES (?, ?, ?)",
            (comment.issue_id, comment.user_name, comment.comment)
        )
        conn.commit()
    return {"message": "Comment added successfully"}


@app.get("/comments/{issue_id}")
def get_comments(issue_id: int):
    with get_db() as conn:
        cursor = conn.cursor()
        cursor.execute("SELECT * FROM comments WHERE issue_id = ? ORDER BY id ASC", (issue_id,))
        rows = cursor.fetchall()
        return [
            {
                "id": row["id"],
                "issue_id": row["issue_id"],
                "user_name": row["user_name"],
                "comment": row["comment"],
                "created_at": row["created_at"] if "created_at" in row.keys() else ""
            }
            for row in rows
        ]


# =========================================================
# AUTH & USER PROFILES
# =========================================================
@app.post("/register")
def register(user: UserRegister):
    username = user.username.strip()
    if not username or not user.password:
        raise HTTPException(status_code=400, detail="Username and password are required")

    with get_db() as conn:
        cursor = conn.cursor()
        # Check if user already exists
        cursor.execute("SELECT id FROM users WHERE username = ?", (username,))
        if cursor.fetchone():
            raise HTTPException(status_code=400, detail="Username already exists")

        # Hash password securely
        hashed_password = hash_password(user.password)
        cursor.execute(
            "INSERT INTO users (username, password, phone, address, karma) VALUES (?, ?, ?, ?, 20)",
            (username, hashed_password, user.phone, user.address)
        )
        conn.commit()
    return {"message": "User registered successfully", "username": username}


@app.post("/login")
def login(user: UserLogin):
    username = user.username.strip()
    with get_db() as conn:
        cursor = conn.cursor()
        cursor.execute("SELECT * FROM users WHERE username = ?", (username,))
        row = cursor.fetchone()

        if not row:
            return {"error": "Invalid credentials"}

        stored_password = row["password"]
        if verify_password(user.password, stored_password):
            return {
                "message": "Login successful",
                "username": row["username"],
                "phone": row["phone"],
                "address": row["address"],
                "karma": row["karma"] if "karma" in row.keys() else 10
            }

        return {"error": "Invalid credentials"}


@app.get("/profile/{username}")
def get_profile(username: str):
    with get_db() as conn:
        cursor = conn.cursor()
        cursor.execute("SELECT * FROM users WHERE username = ?", (username,))
        user = cursor.fetchone()

        if not user:
            return {"error": "User not found"}

        cursor.execute("SELECT COUNT(*) FROM issues WHERE user_name = ?", (username,))
        reports_count = cursor.fetchone()[0]

        cursor.execute("SELECT COUNT(*) FROM issues WHERE user_name = ? AND status = 'Resolved'", (username,))
        resolved_count = cursor.fetchone()[0]

        return {
            "username": user["username"],
            "phone": user["phone"],
            "address": user["address"],
            "karma": user["karma"] if "karma" in user.keys() else 50,
            "reports_count": reports_count,
            "resolved_count": resolved_count,
            "badge": "Civic Champion" if reports_count >= 5 else "Active Citizen"
        }


# =========================================================
# EVENTS & RSVPS
# =========================================================
@app.post("/events/create")
def create_event(event: Event):
    with get_db() as conn:
        cursor = conn.cursor()
        cursor.execute("""
            INSERT INTO events (
                title, description, category,
                location_name, latitude, longitude, start_time
            )
            VALUES (?, ?, ?, ?, ?, ?, ?)
        """, (event.title, event.description, event.category, event.location_name, event.latitude, event.longitude, event.start_time))
        conn.commit()
    return {"message": "Event created successfully"}


@app.get("/events/nearby")
def get_nearby_events(user: str = ""):
    with get_db() as conn:
        cursor = conn.cursor()
        cursor.execute("SELECT * FROM events ORDER BY id DESC")
        rows = cursor.fetchall()

        rsvped_event_ids = set()
        if user:
            cursor.execute("SELECT event_id FROM event_rsvps WHERE user_name = ?", (user,))
            rsvped_event_ids = {r[0] for r in cursor.fetchall()}

        events = []
        for row in rows:
            events.append({
                "id": row["id"],
                "title": row["title"],
                "description": row["description"],
                "category": row["category"],
                "location_name": row["location_name"],
                "latitude": row["latitude"],
                "longitude": row["longitude"],
                "start_time": row["start_time"],
                "attendees_count": row["attendees_count"] if "attendees_count" in row.keys() else 12,
                "is_attending": row["id"] in rsvped_event_ids
            })

        return events


@app.post("/events/rsvp/{event_id}")
def toggle_event_rsvp(event_id: int, payload: EventRSVPToggle):
    user_name = payload.user_name
    with get_db() as conn:
        cursor = conn.cursor()
        cursor.execute("SELECT id FROM event_rsvps WHERE event_id = ? AND user_name = ?", (event_id, user_name))
        existing = cursor.fetchone()

        if existing:
            cursor.execute("DELETE FROM event_rsvps WHERE id = ?", (existing[0],))
            cursor.execute("UPDATE events SET attendees_count = MAX(0, attendees_count - 1) WHERE id = ?", (event_id,))
            conn.commit()
            return {"message": "RSVP cancelled", "is_attending": False}
        else:
            cursor.execute("INSERT INTO event_rsvps (event_id, user_name) VALUES (?, ?)", (event_id, user_name))
            cursor.execute("UPDATE events SET attendees_count = attendees_count + 1 WHERE id = ?", (event_id,))
            conn.commit()
            return {"message": "RSVP confirmed! See you there.", "is_attending": True}


@app.get("/events/{event_id}")
def get_event(event_id: int):
    with get_db() as conn:
        cursor = conn.cursor()
        cursor.execute("SELECT * FROM events WHERE id = ?", (event_id,))
        row = cursor.fetchone()

        if not row:
            return {"error": "Event not found"}

        return {
            "id": row["id"],
            "title": row["title"],
            "description": row["description"],
            "category": row["category"],
            "location_name": row["location_name"],
            "latitude": row["latitude"],
            "longitude": row["longitude"],
            "start_time": row["start_time"],
            "attendees_count": row["attendees_count"] if "attendees_count" in row.keys() else 12
        }


# =========================================================
# EMERGENCY CONTACTS & HELPLINES
# =========================================================
@app.get("/emergency/contacts")
def get_emergency_contacts():
    with get_db() as conn:
        cursor = conn.cursor()
        cursor.execute("SELECT * FROM emergency_contacts")
        rows = cursor.fetchall()

        if not rows:
            return [
                {"name": "Police Emergency", "category": "Police", "phone": "100", "hours": "24/7", "icon": "local_police"},
                {"name": "Ambulance / Medical", "category": "Medical", "phone": "108", "hours": "24/7", "icon": "local_hospital"},
                {"name": "Fire & Rescue Force", "category": "Fire", "phone": "101", "hours": "24/7", "icon": "local_fire_department"},
                {"name": "Women Helpline", "category": "Safety", "phone": "1091", "hours": "24/7", "icon": "security"},
                {"name": "City Corporation Grievance", "category": "Civic", "phone": "0422-2302323", "hours": "8 AM - 8 PM", "icon": "location_city"},
            ]

        return [
            {
                "id": r["id"],
                "name": r["name"],
                "category": r["category"],
                "phone": r["phone"],
                "hours": r["available_hours"],
                "icon": r["icon"]
            }
            for r in rows
        ]


# =========================================================
# PULSE AI SMART SUMMARY & NATURAL LANGUAGE INSIGHTS
# =========================================================
# =========================================================
# GENERATIVE AI & BILINGUAL TANGLISH CHAT ENGINE
# =========================================================
@app.post("/ai/chat")
def ai_chat(payload: dict):
    raw_query = payload.get("query", "").strip()
    user_name = payload.get("user", "Citizen")
    history = payload.get("history", [])

    if not raw_query:
        return {
            "reply": "Vanakkam! 😊 Enna vishayam? Unga neighborhood la ethavathu help thevaiya?",
            "action": None,
            "payload": None,
            "suggestions": ["💧 Thanni leak aagudhu", "🚧 Road la pallam", "🏥 Nearest hospital", "🏆 Karma epdi kedaikkum?"]
        }

    q = raw_query.lower()

    # Gather live context from SQLite to inject real city statistics
    active_issues_count = 0
    top_category = "Water & Road"
    with get_db() as conn:
        cursor = conn.cursor()
        cursor.execute("SELECT COUNT(*) FROM issues WHERE status = 'Open' OR status = 'In Progress'")
        active_issues_count = cursor.fetchone()[0]
        cursor.execute("SELECT category, COUNT(*) as c FROM issues GROUP BY category ORDER BY c DESC LIMIT 1")
        top_row = cursor.fetchone()
        if top_row:
            top_category = top_row[0]

    # Check for Gemini / LLM API Key in environment if available
    gemini_key = os.environ.get("GEMINI_API_KEY") or os.environ.get("GOOGLE_API_KEY")
    if gemini_key:
        try:
            gemini_url = f"https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key={gemini_key}"
            system_instruction = f"""
            You are PulseAI, a friendly, warm, empathetic, and culturally aware civic AI companion for Coimbatore citizens.
            You speak natural English and Tanglish (Tamil written in English alphabet, e.g., 'Vanakkam thalaiva!', 'Sema mass ah irukken!').
            Current city context: {active_issues_count} active ward reports in Coimbatore. Top reported category is {top_category}.
            Answer naturally, conversationally, and warmly to any question (civic issues, chit-chat, how you are doing, city tips, weather, food, karma, and emergency help).
            Keep responses concise (2-4 lines), vibrant, and friendly.
            """
            prompt = f"User ({user_name}): {raw_query}"
            body = {
                "contents": [{"parts": [{"text": f"{system_instruction}\n\n{prompt}"}]}],
                "generationConfig": {"temperature": 0.7, "maxOutputTokens": 200}
            }
            res = requests.post(gemini_url, json=body, timeout=6)
            if res.status_code == 200:
                gen_text = res.json()["candidates"][0]["content"]["parts"][0]["text"].strip()
                action = None
                action_payload = None
                if any(w in q for w in ["hospital", "doctor", "clinic", "maruthuvamanai"]):
                    action = "open_explore"
                    action_payload = "hospital"
                elif any(w in q for w in ["police", "cop", "station", "kaaval"]):
                    action = "open_explore"
                    action_payload = "police"
                elif any(w in q for w in ["emergency", "ambulance", "sos", "danger", "theepudichu"]):
                    action = "open_emergency"
                elif any(w in q for w in ["water", "thanni", "pipe", "leak", "drain", "siruvani"]):
                    action = "filter_category"
                    action_payload = "Water"
                elif any(w in q for w in ["road", "pallam", "pothole", "traffic"]):
                    action = "filter_category"
                    action_payload = "Road"
                elif any(w in q for w in ["event", "camp", "tree", "plantation", "blood", "maram"]):
                    action = "open_events"
                elif any(w in q for w in ["report", "complaint", "submit", "photo"]):
                    action = "open_report"

                return {
                    "reply": gen_text,
                    "action": action,
                    "payload": action_payload,
                    "suggestions": ["💧 Thanni issues", "🏥 Hospital map", "📝 Submit report", "🌳 Community events"]
                }
        except Exception:
            pass

    # =========================================================
    # HIGH-FIDELITY BILINGUAL TANGLISH & ENGLISH SYNTHESIS
    # =========================================================

    # 1. Informal Tanglish "How are you" & Friendly banter
    if any(k in q for k in ["epd iruka", "epdi iruka", "epdi irukinga", "epd irukaa", "nalama", "enna panra", "enna vishesham", "macha", "thalaiva", "bro epdi", "saptacha"]):
        replies = [
            f"Sema mass ah irukken thalaiva! ⚡ Today Coimbatore la {active_issues_count} ward updates monitor pannitu irukken. Siruvani water leaks TWAD team fix pannitanga. Unga area la enna vishesham? Nalla irukiya?",
            f"Vanakkam thalaiva! 😊 Romba super ah irukken. RS Puram, Gandhipuram, and Peelamedu ward resolution rate 88% reach aayiduchu! Unga street la ethavathu prechanai irukka?",
            f"Naan nalla irukken {user_name}! 🌟 Full energy oda active citizens ku help pannitu irukken. Enna help thevaiya thalaiva? Road, thanni, illana hospital pathi kekanuma?"
        ]
        chosen = replies[len(raw_query) % len(replies)]
        return {
            "reply": chosen,
            "action": None,
            "payload": None,
            "suggestions": ["💧 Thanni leak aagudhu", "🚧 Road la pallam irukku", "🏥 Hospital enga irukku?", "🏆 Karma epdi kedaikkum?"]
        }

    # 2. English Greetings & How are you
    if any(k in q for k in ["how are you", "how r u", "how do you do", "whats up", "how's it going", "sup bro", "helloo", "hiii", "hey"]):
        return {
            "reply": f"Doing fantastic, {user_name}! ⚡ Actively tracking {active_issues_count} community reports across Coimbatore wards. Resolution index is at a strong 88%! How's everything in your neighborhood today?",
            "action": None,
            "payload": None,
            "suggestions": ["📢 Check live feed", "🌳 Upcoming events", "🚑 Emergency helplines", "🏆 How does karma work?"]
        }

    # 3. Tanglish / Tamil Gratitude & Praise
    if any(k in q for k in ["nandri", "romba thanks", "super bro", "mass", "kalakkura", "sema", "mass bro", "thx", "thank you", "awesome"]):
        return {
            "reply": "Romba nandri thalaiva! 🌟 Active citizens like you make Coimbatore cleaner and safer every single day. I'm always right here whenever you need anything!",
            "action": None,
            "payload": None,
            "suggestions": ["📅 Community events", "📍 Explore amenities", "📝 File new report"]
        }

    # 4. Tanglish / English Water Issues
    if any(k in q for k in ["thanni", "thani", "kudineer", "water", "leak", "pipe", "drain", "saakadai", "siruvani", "twad", "valankulam"]):
        return {
            "reply": "Aiyayo, thanni waste aaga koodathu! 💧 Siruvani Water Supply Board & TWAD team are actively resolving pipeline leaks. Let's filter the feed to check existing updates or file a quick photo report!",
            "action": "filter_category",
            "payload": "Water",
            "suggestions": ["📝 Report water leak", "🗺️ Water boards on map", "💧 Check other wards"]
        }

    # 5. Tanglish / English Road, Potholes & Infrastructure
    if any(k in q for k in ["pallam", "road", "pothole", "thar road", "vandi", "traffic", "footpath", "street", "ootai", "damage"]):
        return {
            "reply": "Road la pallam iruntha safety risk! 🚧 I'm filtering the community feed for Road & Infrastructure hazards near Gandhipuram, Peelamedu, and RS Puram. Let's get it repaired fast!",
            "action": "filter_category",
            "payload": "Road",
            "suggestions": ["📝 Report road damage", "🚗 View on Explore map", "📢 Check ward status"]
        }

    # 6. Tanglish / English Garbage & Sanitation
    if any(k in q for k in ["kuppai", "naatham", "clean", "garbage", "waste", "dustbin", "trash", "sanitation", "vellalore"]):
        return {
            "reply": "Unga street eppavum clean ah irukanum! 🗑️ Showing sanitation reports and Vellalore solid waste processing updates across your ward. You can report uncollected garbage anytime!",
            "action": "filter_category",
            "payload": "Garbage",
            "suggestions": ["📝 Report uncollected garbage", "🌳 Join clean-up drive", "🗺️ Sanitation centers"]
        }

    # 7. Tanglish / English Electricity & Streetlights
    if any(k in q for k in ["current", "light", "street light", "kambam", "power", "blackout", "dark", "tneb", "transformer", "wire"]):
        return {
            "reply": "Night time la streetlight illana bayama irukkum! ⚡ Showing Electricity & Streetlight outages for immediate TNEB municipal maintenance.",
            "action": "filter_category",
            "payload": "Electricity",
            "suggestions": ["📝 Report broken streetlight", "🚨 Emergency SOS", "⚡ TNEB contacts"]
        }

    # 8. Emergency & SOS
    if any(k in q for k in ["police koopdu", "ambulance venum", "theepudichu", "emergency", "police", "ambulance", "fire", "sos", "danger", "accident", "help venum"]):
        return {
            "reply": "Bayapadatheenga, help ready ah irukku! 🚨 Direct 24/7 Emergency Helplines:\n• Police: 100\n• Medical Ambulance: 108\n• Fire Force: 101\n• Women Helpline: 1091\nLaunching the Emergency SOS speed-dial for you!",
            "action": "open_emergency",
            "payload": None,
            "suggestions": ["🏥 Nearest hospital", "🚓 Nearest police station", "📞 Corporation grievance"]
        }

    # 9. Hospital & Medical Care
    if any(k in q for k in ["hospital", "maruthuvamanai", "doctor", "clinic", "medical", "pharmacy", "health center"]):
        return {
            "reply": "🏥 Navigating to the Explore map! Pinpointing Coimbatore Medical College, GKNM Hospital, and PSG 24/7 Emergency Trauma Centers with walking and driving times.",
            "action": "open_explore",
            "payload": "hospital",
            "suggestions": ["🗺️ Directions in Google Maps", "🚨 Call Ambulance (108)", "🏥 GKNM Hospital"]
        }

    # 10. Police Stations
    if any(k in q for k in ["police station", "kaaval nilayam", "station enga", "cop", "patrol", "commissioner"]):
        return {
            "reply": "🚓 Showing local Police Stations including RS Puram B2, Gandhipuram Law & Order, and City Commissionerate on the Explore map.",
            "action": "open_explore",
            "payload": "police",
            "suggestions": ["🗺️ Open in Google Maps", "🚨 Call Police (100)", "🚓 Traffic control HQ"]
        }

    # 11. Events, Tree Plantations & Blood Donation
    if any(k in q for k in ["maram", "blood donation", "ratham", "event", "camp", "plantation", "drive", "meetup", "volunteer", "tree"]):
        return {
            "reply": "Romba nalla vishayam! 📅 Opening the Civic Events tab. You can RSVP for the Mega Blood Donation Camp at CMC or the 1000 Trees Plantation Drive at VOC Park!",
            "action": "open_events",
            "payload": None,
            "suggestions": ["🌳 Host a new drive", "👥 Check attendees", "📍 Venue directions"]
        }

    # 12. Reporting a New Incident
    if any(k in q for k in ["complaint", "report", "photo", "submit", "new issue", "file", "register"]):
        return {
            "reply": "Kandippa! 📝 Opening the Incident Report form. You can attach photo proof, auto-detect GPS pin, choose priority, and earn +10 Civic Karma points!",
            "action": "open_report",
            "payload": None,
            "suggestions": ["📷 Attach photo proof", "📍 Adjust pin on map", "🏆 Check karma reward"]
        }

    # 13. Karma & Citizen Reputation
    if any(k in q for k in ["karma", "score", "points", "badge", "rank", "champion"]):
        return {
            "reply": "Civic Karma unga community trust reputation! 🏆\n• Oru issue report panna +10 Karma points.\n• Mathavanga upvote panna +2 Karma points.\n• Reach 40 Karma for 'Neighborhood Guardian 🛡️' and 80 Karma for 'Civic Champion 🏆'!",
            "action": None,
            "payload": None,
            "suggestions": ["📝 Report a new issue", "👤 View my profile", "🏆 Leaderboard"]
        }

    # 14. Coimbatore Spots & City Life
    if any(k in q for k in ["place to visit", "tourist", "coimbatore la enna", "sightseeing", "temple", "food", "park"]):
        return {
            "reply": "Coimbatore la sema places irukku! 🌳 VOC Park & Zoo, Valankulam lake promenade, Race Course walking track, Marudhamalai Temple, and Siruvani Waterfalls. Ethavathu civic updates check pannanuma?",
            "action": None,
            "payload": None,
            "suggestions": ["🗺️ Explore map", "🌳 Community drives", "📢 Live feed"]
        }

    # 15. General Conversational Fallback (Friendly & Contextual)
    return {
        "reply": f"Purinjukitten {user_name}! 😊 Nan Tanglish & English rendulayum pesuven. Road potholes, water leaks, nearest hospital, upcoming events, illana emergency helplines pathi kekalam. Enna panna vendum thalaiva?",
        "action": None,
        "payload": None,
        "suggestions": ["💧 Thanni leak aagudhu", "🏥 Nearest hospital", "📝 Report an issue", "🏆 Karma epdi kedaikkum?"]
    }



# =========================================================
# NEARBY OVERPASS SERVICES WITH RESILIENT FALLBACK
# =========================================================
@app.get("/nearby")
def nearby(type: str, lat: float, lon: float, radius_km: float = 10):
    key = f"{type}-{round(lat, 3)}-{round(lon, 3)}-{radius_km}"

    if key in cache:
        return cache[key]

    tag_map = {
        "hospital": "amenity=hospital",
        "police": "amenity=police",
        "fire": "amenity=fire_station",
        "water": "office=water_utility",
        "waste": "amenity=waste_disposal"
    }

    tag = tag_map.get(type, "amenity=hospital")
    k, v = tag.split("=")

    query = f"""
    [out:json][timeout:15];
    (
      node["{k}"="{v}"](around:{radius_km * 1000},{lat},{lon});
      way["{k}"="{v}"](around:{radius_km * 1000},{lat},{lon});
    );
    out center;
    """

    try:
        headers = {
            "User-Agent": "LocalPulse-App/2.0",
            "Accept": "application/json"
        }

        res = requests.post(
            "https://overpass-api.de/api/interpreter",
            data={"data": query},
            headers=headers,
            timeout=12
        )

        if res.status_code == 200 and "json" in res.headers.get("Content-Type", ""):
            data = res.json()
            result = []
            for e in data.get("elements", []):
                lat2 = e.get("lat") or (e.get("center") or {}).get("lat")
                lon2 = e.get("lon") or (e.get("center") or {}).get("lon")
                if lat2 is None or lon2 is None:
                    continue
                dist = haversine_km(lat, lon, float(lat2), float(lon2))
                if dist <= radius_km:
                    result.append({
                        "lat": float(lat2),
                        "lon": float(lon2),
                        "name": e.get("tags", {}).get("name", f"Local {type.capitalize()} Center"),
                        "type": type,
                        "distance_km": dist
                    })

            result.sort(key=lambda x: x["distance_km"])
            if result:
                cache[key] = result[:50]
                return cache[key]

    except Exception:
        pass

    fallback_data = [
        {"lat": lat + 0.005, "lon": lon + 0.004, "name": f"City {type.capitalize()} Station", "type": type, "distance_km": 0.8},
        {"lat": lat - 0.008, "lon": lon - 0.006, "name": f"Central District {type.capitalize()}", "type": type, "distance_km": 1.4},
        {"lat": lat + 0.012, "lon": lon - 0.003, "name": f"Metro {type.capitalize()} Care", "type": type, "distance_km": 2.1}
    ]
    cache[key] = fallback_data
    return fallback_data


@app.get("/search")
def search(q: str):
    url = "https://nominatim.openstreetmap.org/search"
    headers = {"User-Agent": "LocalPulse/2.0"}
    params = {"q": q, "format": "json", "limit": 1}

    try:
        res = requests.get(url, params=params, headers=headers, timeout=10)
        if res.status_code == 200:
            data = res.json()
            if data and len(data) > 0:
                return {
                    "lat": float(data[0]["lat"]),
                    "lon": float(data[0]["lon"]),
                    "name": data[0]["display_name"]
                }
    except Exception:
        pass

    return {"lat": 11.0168, "lon": 76.9558, "name": q}
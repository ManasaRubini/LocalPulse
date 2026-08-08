import sqlite3
from contextlib import contextmanager

DB_PATH = "localpulse.db"

def init_db():
    with sqlite3.connect(DB_PATH) as conn:
        cursor = conn.cursor()
        # Enable WAL mode for high concurrency
        cursor.execute("PRAGMA journal_mode=WAL;")

        # Issues Table
        cursor.execute("""
        CREATE TABLE IF NOT EXISTS issues (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_name TEXT,
            title TEXT,
            description TEXT,
            image_url TEXT,
            category TEXT,
            location TEXT,
            latitude REAL,
            longitude REAL,
            anonymous INTEGER,
            upvotes INTEGER DEFAULT 0,
            status TEXT DEFAULT 'Open',
            priority TEXT DEFAULT 'Medium',
            resolution_note TEXT DEFAULT '',
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
        """)

        # Add columns if migrating from older schema
        try:
            cursor.execute("ALTER TABLE issues ADD COLUMN priority TEXT DEFAULT 'Medium'")
        except sqlite3.OperationalError:
            pass
        try:
            cursor.execute("ALTER TABLE issues ADD COLUMN resolution_note TEXT DEFAULT ''")
        except sqlite3.OperationalError:
            pass

        # Comments Table
        cursor.execute("""
        CREATE TABLE IF NOT EXISTS comments (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            issue_id INTEGER,
            user_name TEXT,
            comment TEXT,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
        """)

        # Users Table
        cursor.execute("""
        CREATE TABLE IF NOT EXISTS users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            username TEXT UNIQUE,
            password TEXT,
            phone TEXT,
            address TEXT,
            karma INTEGER DEFAULT 10,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
        """)

        try:
            cursor.execute("ALTER TABLE users ADD COLUMN karma INTEGER DEFAULT 10")
        except sqlite3.OperationalError:
            pass

        # Events Table
        cursor.execute("""
        CREATE TABLE IF NOT EXISTS events (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT,
            description TEXT,
            category TEXT,
            location_name TEXT,
            latitude REAL,
            longitude REAL,
            start_time TEXT,
            attendees_count INTEGER DEFAULT 0,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
        """)

        try:
            cursor.execute("ALTER TABLE events ADD COLUMN attendees_count INTEGER DEFAULT 0")
        except sqlite3.OperationalError:
            pass

        # Issue Upvotes Tracking (prevents duplicate upvoting and allows toggle)
        cursor.execute("""
        CREATE TABLE IF NOT EXISTS issue_upvotes (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            issue_id INTEGER,
            user_name TEXT,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            UNIQUE(issue_id, user_name)
        )
        """)

        # Event RSVPs Tracking
        cursor.execute("""
        CREATE TABLE IF NOT EXISTS event_rsvps (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            event_id INTEGER,
            user_name TEXT,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            UNIQUE(event_id, user_name)
        )
        """)

        # Emergency Contacts Directory
        cursor.execute("""
        CREATE TABLE IF NOT EXISTS emergency_contacts (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT,
            category TEXT,
            phone TEXT,
            available_hours TEXT DEFAULT '24/7',
            icon TEXT
        )
        """)

        conn.commit()

# Context manager for thread-safe database connections
@contextmanager
def get_db():
    conn = sqlite3.connect(DB_PATH, timeout=15)
    conn.row_factory = sqlite3.Row
    try:
        yield conn
    finally:
        conn.close()

# Initialize tables on import
init_db()
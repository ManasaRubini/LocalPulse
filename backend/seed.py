import sqlite3
import os

DB_PATH = "localpulse.db"

if os.path.exists(DB_PATH):
    try:
        os.remove(DB_PATH)
    except Exception:
        pass

conn = sqlite3.connect(DB_PATH)
cursor = conn.cursor()

# Create Tables
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

cursor.execute("""
CREATE TABLE IF NOT EXISTS comments (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    issue_id INTEGER,
    user_name TEXT,
    comment TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
)
""")

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

cursor.execute("""
CREATE TABLE IF NOT EXISTS issue_upvotes (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    issue_id INTEGER,
    user_name TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(issue_id, user_name)
)
""")

cursor.execute("""
CREATE TABLE IF NOT EXISTS event_rsvps (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    event_id INTEGER,
    user_name TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(event_id, user_name)
)
""")

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

issues = [
    ('Manass','Major Pothole Near Gandhipuram Bus Stand','Huge 2ft pothole causing frequent bike skids and evening traffic jams.','uploads/pothole1.jpg','Road','Gandhipuram, Coimbatore',11.0168,76.9558,0,58,'In Progress','Critical','Municipal road repair team notified. Work scheduled.'),
    ('Lavanya','Main Street Light Blackout','Entire cross street lights have failed for three consecutive nights. Safety risk for pedestrians.','uploads/light1.jpg','Electricity','Peelamedu, Coimbatore',11.0281,76.9890,0,38,'Open','High',''),
    ('Arjun','Overflowing Garbage Bin Near School','Public dustbin overflowing onto the pavement near primary school. Heavy foul smell.','uploads/garbage1.jpg','Garbage','Peelamedu, Coimbatore',11.0205,76.9991,0,61,'Open','High',''),
    ('Keerthi','Potable Water Pipeline Leak','Clean drinking water pipeline leaking at 50L/hr on 4th cross street.','uploads/water1.jpg','Water','RS Puram, Coimbatore',11.0084,76.9445,0,84,'Resolved','Critical','Valve replaced by TWAD Board team. Area restored.'),
    ('Rahul','Damaged Pedestrian Footpath','Concrete footpath pavers broken making walking dangerous for senior citizens.','uploads/footpath.jpg','Road','Gandhipuram, Coimbatore',11.0179,76.9672,0,24,'Open','Medium',''),
    ('Divya','Uncovered Stormwater Drain','Deep stormwater drainage canal left uncovered right next to playground.','uploads/drain.jpg','Health','Saibaba Colony, Coimbatore',11.0265,76.9398,1,72,'In Progress','Critical','Safety barricades placed. Cement slabs arriving tomorrow.'),
    ('Sanjay','Illegal Commercial Waste Dumping','Commercial vehicles dumping construction debris late night on vacant lot.','uploads/garbage2.jpg','Garbage','Singanallur, Coimbatore',11.0009,77.0260,0,54,'Open','Medium',''),
    ('Priya','Electrical Transformer Sparking','Transformer near residential apartment throwing sparks during evening load hours.','uploads/transformer.jpg','Electricity','Saravanampatti, Coimbatore',11.0822,76.9963,0,96,'Resolved','Critical','TNEB inspection completed, blown fuse insulator replaced.'),
    ('Karthik','Monsoon Waterlogging Underpass','Railway underpass flooded with 2 feet stagnant rainwater stopping traffic.','uploads/water2.jpg','Water','Town Hall, Coimbatore',10.9951,76.9613,0,49,'Resolved','High','High-power suction pumps deployed. Road cleared.'),
    ('Meena','Biomedical Waste Dumped on Roadside','Hazardous medical waste sacks found near canal bank. Urgent disposal needed.','uploads/health1.jpg','Health','Ukkadam, Coimbatore',10.9898,76.9554,0,105,'Resolved','Critical','Pollution control board dispatched hazardous waste team.'),
    ('Ajay','Traffic Signal Failure at Junction','4-way traffic light junction completely blinking amber causing chaos.','uploads/signal.jpg','Road','Hope College, Coimbatore',11.0274,77.0312,0,43,'Open','High',''),
    ('Anitha','Drinking Water Supply Disruption','No municipal water supply received in Ward 14 for the past 48 hours.','uploads/water3.jpg','Water','Race Course, Coimbatore',11.0025,76.9706,0,67,'In Progress','High','Water tankers dispatched to sector 2 and 4.'),
    ('Vikram','Tilting Electricity Utility Pole','Heavy winds tilted electric post toward residential roof. Urgent stabilization needed.','uploads/pole.jpg','Electricity','Kuniamuthur, Coimbatore',10.9644,76.9508,0,52,'Open','Critical',''),
    ('Sneha','Public Park Litter and Broken Benches','Park maintenance required. Broken swings and litter scattered around jogging track.','uploads/park.jpg','Garbage','Vadavalli, Coimbatore',11.0426,76.8968,1,19,'Resolved','Low','Park cleanliness drive completed by youth volunteers.'),
    ('Harish','Mosquito Breeding in Stagnant Pool','Vacant plot turned into mosquito breeding ground after unseasonal rain.','uploads/mosquito.jpg','Health','Thudiyalur, Coimbatore',11.0819,76.9415,0,77,'In Progress','High','Larvicide spraying scheduled for today 4 PM.')
]

cursor.executemany("""
INSERT INTO issues (
    user_name, title, description, image_url, category,
    location, latitude, longitude, anonymous, upvotes,
    status, priority, resolution_note
)
VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?)
""", issues)

events = [
    ('Mega Blood Donation & Health Camp', 'Join local doctors for voluntary blood donation and free vital health checkups.', 'Health', 'Coimbatore Medical College', 11.0168, 76.9558, '2026-08-15 09:00 AM', 45),
    ('1000 Trees Urban Forest Plantation', 'Community tree plantation initiative along Noyyal river bank. Saplings provided.', 'Environment', 'VOC Park & Zoo Grounds', 11.0046, 76.9616, '2026-08-16 07:00 AM', 78),
    ('Citizen Road Safety & Traffic Awareness', 'Interactive awareness workshop by traffic wardens on defensive driving and helmet safety.', 'Safety', 'Gandhipuram Central Terminal', 11.0179, 76.9672, '2026-08-18 10:00 AM', 32),
    ('Free Eye & Dental Care Clinic', 'Free vision tests, cataract screening, and dental cleaning for residents.', 'Health', 'RS Puram Community Hall', 11.0084, 76.9445, '2026-08-20 09:30 AM', 60),
    ('Lakeside Cleanliness & Plogging Drive', 'Community cleanup of Ukkadam lake bund. Gloves and waste bags provided.', 'Environment', 'Ukkadam Periyakulam Bund', 10.9898, 76.9554, '2026-08-22 06:30 AM', 92),
    ('Women Self-Defense & Safety Workshop', 'Practical self-defense training and digital security workshop by martial arts trainers.', 'Safety', 'Race Course Walking Track', 11.0025, 76.9706, '2026-08-24 05:00 PM', 54),
    ('Tech & Civic Innovation Hackathon', 'Build smart open-source tools for urban local bodies and citizen engagement.', 'Education', 'Peelamedu Innovation Hub', 11.0205, 76.9991, '2026-08-26 10:00 AM', 41),
    ('Zero Plastic Neighborhood Workshop', 'Learn home composting, bio-enzyme creation, and zero-waste living practices.', 'Environment', 'Singanallur Community Center', 11.0009, 77.0260, '2026-08-28 04:00 PM', 29)
]

cursor.executemany("""
INSERT INTO events (
    title, description, category, location_name,
    latitude, longitude, start_time, attendees_count
)
VALUES (?,?,?,?,?,?,?,?)
""", events)

comments = [
    (1, 'Rahul', 'This pothole caused a minor bike accident yesterday morning. Please fix soon!'),
    (1, 'Lavanya', 'Corporation team visited this spot around 11 AM today.'),
    (2, 'Priya', 'The street is completely pitch black after 7 PM. Very unsafe for women walking home.'),
    (3, 'Arun', 'Garbage collection truck has skipped this street for 4 days.'),
    (4, 'Meena', 'Clean water is gushing onto the road. Massive wastage!'),
    (4, 'Keerthi', 'TWAD engineers fixed the pipeline today at 2 PM. Great job!'),
    (6, 'Divya', 'Deep open drain next to school gate. Children run around here daily.'),
    (8, 'Vikram', 'Sparks were falling on parked two-wheelers yesterday night.'),
    (10, 'Sanjay', 'Medical syringes dumped near canal. Extremely hazardous.')
]

cursor.executemany("""
INSERT INTO comments (issue_id, user_name, comment)
VALUES (?,?,?)
""", comments)

users = [
    ('Manass', 'manass123', '9876543210', 'Gandhipuram, Coimbatore', 85),
    ('Lavanya', 'lavanya123', '9876543211', 'Peelamedu, Coimbatore', 60),
    ('Arjun', 'arjun123', '9876543212', 'RS Puram, Coimbatore', 40),
    ('Keerthi', 'keerthi123', '9876543213', 'Saibaba Colony, Coimbatore', 95),
    ('Rahul', 'rahul123', '9876543214', 'Singanallur, Coimbatore', 35)
]

cursor.executemany("""
INSERT INTO users (username, password, phone, address, karma)
VALUES (?,?,?,?,?)
""", users)

emergency_contacts = [
    ('Police Emergency Control', 'Police', '100', '24/7', 'local_police'),
    ('Ambulance / Emergency Medical', 'Medical', '108', '24/7', 'local_hospital'),
    ('Fire & Emergency Services', 'Fire', '101', '24/7', 'local_fire_department'),
    ('Women Helpline', 'Safety', '1091', '24/7', 'security'),
    ('Disaster Emergency Control Room', 'Disaster', '1077', '24/7', 'warning'),
    ('City Corporation Grievance Cell', 'Civic', '0422-2302323', '8:00 AM - 8:00 PM', 'location_city'),
    ('Electricity TNEB Control Room', 'Utility', '9498794987', '24/7', 'bolt'),
    ('Drinking Water & Drainage Board', 'Utility', '0422-2567890', '24/7', 'water_drop')
]

cursor.executemany("""
INSERT INTO emergency_contacts (name, category, phone, available_hours, icon)
VALUES (?,?,?,?,?)
""", emergency_contacts)

conn.commit()
conn.close()

print("LocalPulse 2.0 Database seeded successfully with issues, events, comments, users, and emergency contacts.")
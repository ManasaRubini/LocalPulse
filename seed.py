import sqlite3

conn = sqlite3.connect("localpulse.db")
cursor = conn.cursor()

issues = [
    ('Manass','Large Pothole Near Bus Stand','Huge pothole causing accidents.','uploads/pothole1.jpg','Road','Coimbatore',11.0168,76.9558,0,52,'Open','2026-06-26 08:10:00'),

    ('Lavanya','Broken Street Light','Street light not working for three nights.','uploads/light1.jpg','Electricity','Peelamedu',11.0281,76.9890,0,38,'Open','2026-06-25 18:20:00'),

    ('Arjun','Garbage Overflow','Dustbin overflowing and spreading bad smell.','uploads/garbage1.jpg','Garbage','Peelamedu',11.0205,76.9991,0,61,'Open','2026-06-25 09:00:00'),

    ('Keerthi','Water Leakage','Pipeline leaking continuously.','uploads/water1.jpg','Water','RS Puram',11.0084,76.9445,0,45,'Resolved','2026-06-24 11:00:00'),

    ('Rahul','Damaged Footpath','Footpath broken making walking difficult.','uploads/footpath.jpg','Road','Gandhipuram',11.0179,76.9672,0,24,'Open','2026-06-24 16:20:00'),

    ('Divya','Open Drain','Drain left uncovered near school.','uploads/drain.jpg','Health','Saibaba Colony',11.0265,76.9398,1,72,'Open','2026-06-23 09:45:00'),

    ('Sanjay','Illegal Garbage Dump','People dumping waste every night.','uploads/garbage2.jpg','Garbage','Singanallur',11.0009,77.0260,0,54,'Open','2026-06-23 12:40:00'),

    ('Priya','Transformer Sparks','Transformer producing sparks.','uploads/transformer.jpg','Electricity','Saravanampatti',11.0822,76.9963,0,67,'Open','2026-06-22 20:15:00'),

    ('Karthik','Water Logging','Rainwater stagnant for two days.','uploads/water2.jpg','Water','Town Hall',10.9951,76.9613,0,29,'Resolved','2026-06-22 07:50:00'),

    ('Meena','Hospital Waste','Medical waste dumped near road.','uploads/health1.jpg','Health','Ukkadam',10.9898,76.9554,0,81,'Open','2026-06-21 14:10:00'),

    ('Ajay','Broken Traffic Signal','Traffic signal stopped working.','uploads/signal.jpg','Road','Hope College',11.0274,77.0312,0,43,'Open','2026-06-21 09:25:00'),

    ('Anitha','Water Supply Issue','No drinking water for two days.','uploads/water3.jpg','Water','Race Course',11.0025,76.9706,0,56,'Open','2026-06-20 10:30:00'),

    ('Vikram','Electric Pole Leaning','Pole leaning dangerously after rain.','uploads/pole.jpg','Electricity','Kuniamuthur',10.9644,76.9508,0,33,'Open','2026-06-20 18:45:00'),

    ('Sneha','Park Needs Cleaning','Garbage scattered inside public park.','uploads/park.jpg','Garbage','Vadavalli',11.0426,76.8968,1,19,'Resolved','2026-06-19 17:00:00'),

    ('Harish','Mosquito Breeding','Standing water causing mosquito breeding.','uploads/mosquito.jpg','Health','Thudiyalur',11.0819,76.9415,0,77,'Open','2026-06-19 06:40:00'),

    ('Nisha','Broken Road Divider','Road divider broken after accident.','','Road','Podanur',10.9622,76.9723,0,31,'Open','2026-06-18 12:20:00'),

    ('Prakash','Street Light Flickering','Street lights flicker throughout the night.','','Electricity','Ganapathy',11.0434,77.0022,0,18,'Resolved','2026-06-18 19:30:00'),

    ('Aarthi','Water Tank Overflow','Public water tank overflowing daily.','','Water','Sundarapuram',10.9436,76.9660,0,42,'Open','2026-06-17 08:15:00'),

    ('Deepak','Garbage Burning','Garbage being burned causing pollution.','','Garbage','Kovaipudur',10.9388,76.9237,1,64,'Open','2026-06-17 15:50:00'),

    ('Ramesh','Damaged Public Toilet','Public toilet unusable due to damage.','','Health','Perur',10.9727,76.9128,0,27,'Open','2026-06-16 11:05:00')
]

cursor.executemany("""
INSERT INTO issues
(
    user_name,
    title,
    description,
    image_url,
    category,
    location,
    latitude,
    longitude,
    anonymous,
    upvotes,
    status,
    created_at
)
VALUES
(?,?,?,?,?,?,?,?,?,?,?,?)
""", issues)

conn.commit()

print("20 issues inserted successfully.")

events = [
    (
        'Blood Donation Camp',
        'Donate blood and save lives.',
        'Health',
        'Coimbatore Medical College',
        11.0168,
        76.9558,
        '2026-07-05 09:00:00'
    ),

    (
        'Tree Plantation Drive',
        'Community tree plantation initiative.',
        'Environment',
        'VOC Park',
        11.0046,
        76.9616,
        '2026-07-06 07:00:00'
    ),

    (
        'Road Safety Awareness',
        'Road safety and traffic rules awareness program.',
        'Education',
        'Gandhipuram',
        11.0179,
        76.9672,
        '2026-07-07 10:00:00'
    ),

    (
        'Free Medical Camp',
        'General health checkup and consultation.',
        'Health',
        'RS Puram',
        11.0084,
        76.9445,
        '2026-07-08 09:30:00'
    ),

    (
        'Beach Cleanup Campaign',
        'Public cleanliness awareness event.',
        'Environment',
        'Ukkadam Lake',
        10.9898,
        76.9554,
        '2026-07-09 06:30:00'
    ),

    (
        'Women Safety Workshop',
        'Workshop on women safety and self-defense.',
        'Community',
        'Race Course',
        11.0025,
        76.9706,
        '2026-07-10 11:00:00'
    ),

    (
        'Career Guidance Seminar',
        'Guidance session for students and graduates.',
        'Education',
        'Peelamedu',
        11.0205,
        76.9991,
        '2026-07-11 14:00:00'
    ),

    (
        'Startup Networking Meetup',
        'Networking event for entrepreneurs.',
        'Business',
        'Saravanampatti',
        11.0822,
        76.9963,
        '2026-07-12 16:00:00'
    ),

    (
        'Yoga and Wellness Camp',
        'Morning yoga session for public health.',
        'Health',
        'Saibaba Colony',
        11.0265,
        76.9398,
        '2026-07-13 06:00:00'
    ),

    (
        'Public Grievance Meeting',
        'Meet local officials and raise concerns.',
        'Government',
        'Town Hall',
        10.9951,
        76.9613,
        '2026-07-14 10:30:00'
    ),

    (
        'Plastic Free City Campaign',
        'Promoting alternatives to plastic usage.',
        'Environment',
        'Singanallur',
        11.0009,
        77.0260,
        '2026-07-15 09:00:00'
    ),

    (
        'Food Distribution Drive',
        'Providing meals for needy families.',
        'Community',
        'Podanur',
        10.9622,
        76.9723,
        '2026-07-16 12:00:00'
    ),

    (
        'Digital Literacy Program',
        'Teaching basic computer and internet skills.',
        'Education',
        'Ganapathy',
        11.0434,
        77.0022,
        '2026-07-17 15:00:00'
    ),

    (
        'Farmers Support Meet',
        'Agricultural awareness and support session.',
        'Agriculture',
        'Perur',
        10.9727,
        76.9128,
        '2026-07-18 10:00:00'
    ),

    (
        'Clean Water Awareness',
        'Awareness on water conservation.',
        'Water',
        'Sundarapuram',
        10.9436,
        76.9660,
        '2026-07-19 09:30:00'
    ),

    (
        'Emergency Preparedness Workshop',
        'Training for disaster management.',
        'Safety',
        'Hope College',
        11.0274,
        77.0312,
        '2026-07-20 11:00:00'
    ),

    (
        'Public Health Awareness Walk',
        'Walkathon promoting healthy lifestyles.',
        'Health',
        'Vadavalli',
        11.0426,
        76.8968,
        '2026-07-21 06:00:00'
    ),

    (
        'Youth Leadership Summit',
        'Leadership and communication skills training.',
        'Education',
        'Thudiyalur',
        11.0819,
        76.9415,
        '2026-07-22 10:00:00'
    ),

    (
        'Waste Management Workshop',
        'Training on waste segregation practices.',
        'Environment',
        'Kovaipudur',
        10.9388,
        76.9237,
        '2026-07-23 09:00:00'
    ),

    (
        'Community Sports Day',
        'Sports competitions and fitness activities.',
        'Sports',
        'Kuniamuthur',
        10.9644,
        76.9508,
        '2026-07-24 08:00:00'
    )
]

cursor.executemany("""
INSERT INTO events
(
    title,
    description,
    category,
    location_name,
    latitude,
    longitude,
    start_time
)
VALUES
(?,?,?,?,?,?,?)
""", events)

conn.commit()

print("Events created")

comments = [
    (1, 'Rahul', 'This pothole has been causing traffic every morning.'),
    (2, 'Priya', 'The street has been dark for several days.'),
    (3, 'Arun', 'Garbage collection vehicle has not arrived this week.'),
    (4, 'Meena', 'Water has been leaking continuously since yesterday.'),
    (5, 'Karthik', 'Many elderly people use this footpath. Please repair it soon.'),
    (6, 'Divya', 'Children are playing near this open drain.'),
    (7, 'Sanjay', 'The bad smell is affecting nearby houses.'),
    (8, 'Anitha', 'This transformer is making loud noises at night.'),
    (9, 'Harish', 'Waterlogging is making it difficult to ride bikes.'),
    (10, 'Sneha', 'Hospital waste should be disposed of safely.'),
    (11, 'Vikram', 'Traffic police should inspect this signal immediately.'),
    (12, 'Aarthi', 'Residents are struggling without drinking water.'),
    (13, 'Prakash', 'This electric pole looks dangerous during rain.'),
    (14, 'Deepak', 'The park should be cleaned every morning.'),
    (15, 'Nisha', 'Mosquitoes have increased significantly in this area.'),
    (16, 'Ajay', 'The broken divider is causing frequent accidents.'),
    (17, 'Keerthi', 'Street lights keep flickering after sunset.'),
    (18, 'Ramesh', 'Water is being wasted every day because of this overflow.'),
    (19, 'Lavanya', 'Burning garbage is creating heavy smoke.'),
    (20, 'Manass', 'The public toilet needs immediate maintenance.')
]

cursor.executemany("""
INSERT INTO comments
(
    issue_id,
    user_name,
    comment
)
VALUES
(?,?,?)
""", comments)

conn.commit()

print("40 comments inserted successfully.")

users = [
    ('Manass', 'manass123', '9876543210', 'Coimbatore'),
    ('Lavanya', 'lavanya123', '9876543211', 'Peelamedu'),
    ('Arjun', 'arjun123', '9876543212', 'RS Puram'),
    ('Keerthi', 'keerthi123', '9876543213', 'Gandhipuram'),
    ('Rahul', 'rahul123', '9876543214', 'Singanallur')
]

cursor.executemany("""
INSERT INTO users
(
    username,
    password,
    phone,
    address
)
VALUES (?, ?, ?, ?)
""", users)

conn.commit()
conn.close()

print("5 users inserted successfully.")
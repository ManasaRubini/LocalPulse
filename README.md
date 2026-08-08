# NammaCity 🏙️⚡
**Hyperlocal Community Civic Reporting, Interactive Discovery & AI Companion**

---

## 🌟 Overview
**NammaCity** is a cross-platform mobile and web application built with Flutter and FastAPI. It enables citizens in Coimbatore to report local infrastructure issues, discover nearby essential amenities, join community drives, and converse with **NammaCity AI** for civic assistance.

---

## 📁 Repository Structure
```
localp/
├── backend/                  # FastAPI Python Backend (Render Cloud)
│   ├── main.py               # REST API, SQLite RAG, AI Chat Engine
│   ├── database.py           # Database connection & schema setup
│   ├── models.py             # Pydantic data models
│   └── requirements.txt      # Python dependencies
└── frontend/                 # Flutter Cross-Platform Client
    ├── lib/                  # Dart application source code
    │   ├── models/           # Issue & Event models
    │   ├── screens/          # Feed, Explore Map, Report, Events, Profile
    │   ├── services/         # API & NammaCity AI Voice Services
    │   ├── utils/            # AppConfig, Colors, Categories
    │   └── widgets/          # NammaCity Assistant Modal, Cards, SOS Sheet
    └── pubspec.yaml          # Flutter package configuration
```

---

## 🚀 Getting Started

### 1. Backend (FastAPI)
```bash
cd backend
pip install -r requirements.txt
uvicorn main:app --reload --port 8000
```

### 2. Frontend (Flutter)
```bash
cd frontend
flutter pub get
flutter run
```

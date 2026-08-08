from pydantic import BaseModel
from typing import Optional

class Issue(BaseModel):
    user_name: str
    title: str
    description: str
    image_url: Optional[str] = None
    category: str
    location: str
    latitude: float
    longitude: float
    anonymous: bool
    priority: Optional[str] = "Medium"

class IssueStatusUpdate(BaseModel):
    status: str  # 'Open', 'In Progress', 'Resolved'
    resolution_note: Optional[str] = ""

class Comment(BaseModel):
    issue_id: int
    user_name: str
    comment: str

class UserRegister(BaseModel):
    username: str
    password: str
    phone: str
    address: str

class UserLogin(BaseModel):
    username: str
    password: str

class Event(BaseModel):
    title: str
    description: str
    category: str
    location_name: str
    latitude: float
    longitude: float
    start_time: str

class UpvoteToggle(BaseModel):
    user_name: str

class EventRSVPToggle(BaseModel):
    user_name: str

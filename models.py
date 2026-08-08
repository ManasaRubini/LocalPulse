from pydantic import BaseModel

class Issue(BaseModel):
    user_name: str
    title: str
    description: str
    image_url: str | None = None
    category: str
    location: str
    anonymous: bool


class Comment(BaseModel):
    issue_id: int
    user_name: str
    comment: str


# 🔥 IMPORTANT: REGISTER MODEL
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

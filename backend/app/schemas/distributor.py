from pydantic import BaseModel, EmailStr
from typing import Optional
from app.models import *

class DistributorBase(BaseModel):
    name: str
    email: Optional[EmailStr] = None
    address: Optional[str]= None

class DistributorCreate(DistributorBase):
    pass

class DistributorOut(DistributorBase):
    id: int

    class Config:
        from_attributes = True


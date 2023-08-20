from pydantic import BaseModel, HttpUrl
from pydantic_extra_types.phone_numbers import PhoneNumber
from typing import Literal
from datetime import date

class Organization(BaseModel):
    # 1) Mandotory user inputs:
    name: str
    # 2) Optional user inputs:
    url: HttpUrl

class Location(BaseModel):
    # 1) Mandotory user inputs:
    city: str
    country: str
    # 2) Optional user inputs:
    state: str

class Skill(BaseModel):
    # 1) Mandotory user inputs:
    name: str
    # 2) Optional user inputs:
    details: str

class Activity(BaseModel):
    # 1) Mandotory user inputs:
    organization: Organization
    position: str
    start_date: date
    end_date: date
    location: Location
    # 2) Optional user inputs:
    company_url: HttpUrl
    highlights: list[str]

class TestScore(BaseModel):
    # 1) Mandotory user inputs:
    name: str
    score: str
    # 2) Optional user inputs:
    url: HttpUrl
    details: str
    date: date

class Project(BaseModel):
    # 1) Mandotory user inputs:
    name: str
    start_date: date
    end_date: date
    location: Location
    # 2) Optional user inputs:
    url: HttpUrl
    highlights: list[str]

class WorkExperience(BaseModel):
    # 1) Mandotory user inputs:
    company: Organization
    position: str
    start_date: date
    end_date: date
    location: Location
    # 2) Optional user inputs:
    highlights: list[str]

class Education(BaseModel):
    # 1) Mandotory user inputs:
    institution: Organization
    study_type: str
    area: str
    location: Location
    start_date: date
    end_date: date
    # 2) Optional user inputs:
    gpa: str
    transcript_url: HttpUrl
    highlights: list[str]

class SocialNetwork(BaseModel):
    # 1) Mandotory user inputs:
    network: Literal["LinkedIn", "GitHub", "Twitter", "Facebook", "Instagram"]
    username: str
    url: HttpUrl

class CurriculumVitae(BaseModel):
    # 1) Mandotory user inputs:
    name: str
    # 2) Optional user inputs:
    email: str
    phone: PhoneNumber
    website: HttpUrl
    summary: str
    location: Location
    social_networks: list[SocialNetwork]
    education: list[Education]
    work_experience: list[WorkExperience]
    academic_projects: list[Project]
    extracurricular_activities: list[Activity]
    test_scores: list[TestScore]
    skills: list[Skill]
    

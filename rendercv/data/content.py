from pydantic import BaseModel, HttpUrl, model_validator
from pydantic_extra_types.phone_numbers import PhoneNumber
from typing import Literal, Union
from datetime import date as Date


class Skill(BaseModel):
    # 1) Mandotory user inputs:
    name: str
    # 2) Optional user inputs:
    details: str = None


class TestScore(BaseModel):
    # 1) Mandotory user inputs:
    name: str
    score: str
    # 2) Optional user inputs:
    url: HttpUrl = None
    date: Date = None


class Project(BaseModel):
    # 1) Mandotory user inputs:
    name: str
    location: str
    # 2) Optional user inputs:
    start_date: Date = None
    end_date: Date | Literal["present"] = None
    date: str = None
    url: HttpUrl = None
    highlights: list[str] = None


class Experience(BaseModel):
    # 1) Mandotory user inputs:
    company: str
    position: str
    location: str
    # 2) Optional user inputs:
    start_date: Date = None
    end_date: Date | Literal["present"] = None
    date: str = None
    highlights: list[str] = None


class Education(BaseModel):
    # 1) Mandotory user inputs:
    institution: str
    area: str
    location: str
    # 2) Optional user inputs:
    start_date: Date = None
    end_date: Date | Literal["present"] = None
    date: str = None
    study_type: str = None
    gpa: str = None
    transcript_url: HttpUrl = None
    highlights: list[str] = None


class SocialNetwork(BaseModel):
    # 1) Mandotory user inputs:
    network: Literal["LinkedIn", "GitHub", "Instagram"]
    username: str


class Connection(BaseModel):
    # 3) Derived fields (not user inputs):
    name: Literal["LinkedIn", "GitHub", "Instagram", "phone", "email", "website"]
    value: str


class CurriculumVitae(BaseModel):
    # 1) Mandotory user inputs:
    name: str
    # 2) Optional user inputs:
    email: str = None
    phone: PhoneNumber = None
    website: HttpUrl = None
    location: str = None
    social_networks: list[SocialNetwork] = None
    education: list[Education] = None
    work_experience: list[Experience] = None
    academic_projects: list[Project] = None
    extracurricular_activities: list[Experience] = None
    test_scores: list[TestScore] = None
    skills: list[Skill] = None

    # 3) Derived fields (not user inputs):
    connections: list[SocialNetwork] = []

    @model_validator(mode="after")
    @classmethod
    def derive_connections(cls, model):
        connections = []
        if model.email is not None:
            connections.append(Connection(name="email", value=model.email))
        if model.phone is not None:
            connections.append(Connection(name="phone", value=model.phone))
        if model.website is not None:
            connections.append(Connection(name="website", value=model.website))
        if model.social_networks is not None:
            for social_network in model.social_networks:
                connections.append(
                    Connection(
                        name=social_network.network, value=social_network.username
                    )
                )
        model.connections = connections
        return model

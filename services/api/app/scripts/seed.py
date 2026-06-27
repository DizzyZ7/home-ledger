from datetime import date, timedelta

from sqlalchemy import select

from app.core.security import hash_password
from app.db.session import SessionLocal
from app.models.household import Household
from app.models.item import HomeItem
from app.models.maintenance import MaintenanceTask
from app.models.user import User

DEMO_EMAIL = "demo@homeledger.local"
DEMO_PASSWORD = "demo-password-change-me"


def seed() -> None:
    with SessionLocal() as session:
        if session.scalar(select(User).where(User.email == DEMO_EMAIL)):
            print("Demo data already exists.")
            return

        user = User(
            email=DEMO_EMAIL,
            display_name="Demo owner",
            password_hash=hash_password(DEMO_PASSWORD),
        )
        household = Household(name="Demo home", owner=user)
        washer = HomeItem(
            household=household,
            name="Washing machine",
            category="appliance",
            location="Bathroom",
            purchase_date=date.today() - timedelta(days=420),
            warranty_expires_at=date.today() + timedelta(days=310),
            serial_number="DEMO-WM-2026",
        )
        router = HomeItem(
            household=household,
            name="Wi-Fi router",
            category="electronics",
            location="Living room",
            purchase_date=date.today() - timedelta(days=820),
            warranty_expires_at=date.today() + timedelta(days=30),
            serial_number="DEMO-RT-2026",
        )
        task = MaintenanceTask(
            household=household,
            item=washer,
            title="Clean the filter",
            frequency_days=90,
            next_due_date=date.today() + timedelta(days=7),
        )
        session.add_all([user, household, washer, router, task])
        session.commit()
        print(f"Created demo account: {DEMO_EMAIL} / {DEMO_PASSWORD}")


if __name__ == "__main__":
    seed()

"""Payment model — client payments tied to a project."""
from datetime import date
from decimal import Decimal
from typing import Literal

from sqlalchemy import CheckConstraint, Date, ForeignKey, Index, Numeric, String, Text, text
from sqlalchemy.orm import Mapped, mapped_column

from app.core.database import Base
from app.models.mixins import TimestampMixin

PaymentMethod = Literal["cash", "bank_transfer", "cheque", "other"]


class Payment(Base, TimestampMixin):
    __tablename__ = "payments"

    id: Mapped[str] = mapped_column(
        String(36),
        primary_key=True,
        server_default=text("gen_random_uuid()"),
    )
    project_id: Mapped[str] = mapped_column(
        String(36),
        ForeignKey("projects.id", ondelete="CASCADE"),
        nullable=False,
    )
    amount: Mapped[Decimal] = mapped_column(Numeric(14, 2), nullable=False)
    payment_date: Mapped[date] = mapped_column(Date, nullable=False)
    method: Mapped[str] = mapped_column(String(20), nullable=False)
    notes: Mapped[str | None] = mapped_column(Text, nullable=True)

    __table_args__ = (
        CheckConstraint("amount > 0", name="chk_payments_amount_positive"),
        CheckConstraint(
            "method IN ('cash','bank_transfer','cheque','other')",
            name="chk_payments_method",
        ),
        Index("idx_payments_project_id", "project_id"),
        Index("idx_payments_payment_date", "payment_date"),
    )
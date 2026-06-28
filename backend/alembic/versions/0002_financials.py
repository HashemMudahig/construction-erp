"""s02 milestones payments expenses

Revision ID: 0002_financials
Revises: 0001_initial
Create Date: 2026-06-28
"""
from alembic import op
import sqlalchemy as sa

revision = "0002_financials"
down_revision = "0001_initial"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table(
        "milestones",
        sa.Column("id", sa.String(36), primary_key=True, server_default=sa.text("gen_random_uuid()")),
        sa.Column("project_id", sa.String(36), nullable=False),
        sa.Column("title", sa.String(255), nullable=False),
        sa.Column("description", sa.Text(), nullable=True),
        sa.Column("due_date", sa.Date(), nullable=False),
        sa.Column("status", sa.String(20), nullable=False, server_default="pending"),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.ForeignKeyConstraint(["project_id"], ["projects.id"], name="fk_milestones_project", ondelete="CASCADE"),
        sa.CheckConstraint(
            "status IN ('pending','in_progress','completed','overdue')",
            name="chk_milestones_status",
        ),
    )
    op.create_index("idx_milestones_project_id", "milestones", ["project_id"])
    op.create_index("idx_milestones_due_date", "milestones", ["due_date"])

    op.create_table(
        "payments",
        sa.Column("id", sa.String(36), primary_key=True, server_default=sa.text("gen_random_uuid()")),
        sa.Column("project_id", sa.String(36), nullable=False),
        sa.Column("amount", sa.Numeric(14, 2), nullable=False),
        sa.Column("payment_date", sa.Date(), nullable=False),
        sa.Column("method", sa.String(20), nullable=False),
        sa.Column("notes", sa.Text(), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.ForeignKeyConstraint(["project_id"], ["projects.id"], name="fk_payments_project", ondelete="CASCADE"),
        sa.CheckConstraint("amount > 0", name="chk_payments_amount_positive"),
        sa.CheckConstraint(
            "method IN ('cash','bank_transfer','cheque','other')",
            name="chk_payments_method",
        ),
    )
    op.create_index("idx_payments_project_id", "payments", ["project_id"])
    op.create_index("idx_payments_payment_date", "payments", ["payment_date"])

    op.create_table(
        "expenses",
        sa.Column("id", sa.String(36), primary_key=True, server_default=sa.text("gen_random_uuid()")),
        sa.Column("project_id", sa.String(36), nullable=False),
        sa.Column("category", sa.String(100), nullable=False),
        sa.Column("amount", sa.Numeric(14, 2), nullable=False),
        sa.Column("expense_date", sa.Date(), nullable=False),
        sa.Column("notes", sa.Text(), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.ForeignKeyConstraint(["project_id"], ["projects.id"], name="fk_expenses_project", ondelete="CASCADE"),
        sa.CheckConstraint("amount > 0", name="chk_expenses_amount_positive"),
    )
    op.create_index("idx_expenses_project_id", "expenses", ["project_id"])
    op.create_index("idx_expenses_expense_date", "expenses", ["expense_date"])


def downgrade() -> None:
    op.drop_index("idx_expenses_expense_date", table_name="expenses")
    op.drop_index("idx_expenses_project_id", table_name="expenses")
    op.drop_table("expenses")
    op.drop_index("idx_payments_payment_date", table_name="payments")
    op.drop_index("idx_payments_project_id", table_name="payments")
    op.drop_table("payments")
    op.drop_index("idx_milestones_due_date", table_name="milestones")
    op.drop_index("idx_milestones_project_id", table_name="milestones")
    op.drop_table("milestones")
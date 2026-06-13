"""Generate DRAFT outreach (email / letter) for a matched settlement.

IMPORTANT: These are drafts for the user to review and send themselves. The app
never auto-sends. Tone is factual and non-threatening; it asks for information
or confirms a claim, it does not make legal demands or give legal advice.
"""
from __future__ import annotations

from datetime import date
from typing import Any

from . import config


def _sender_block() -> str:
    return f"{config.USER_FULL_NAME}\n{config.USER_ADDRESS}\n{config.USER_EMAIL}"


def draft_claim_inquiry(settlement: dict, profile: dict, channel: str = "email") -> dict[str, Any]:
    """Email/letter to the settlement administrator confirming class membership."""
    name = profile.get("name", config.USER_FULL_NAME)
    title = settlement["title"]
    reasons = settlement.get("_matched_reasons", [])
    reason_lines = "\n".join(f"  - {r}" for r in reasons) or "  - (describe how you qualify)"

    subject = f"Class membership confirmation request — {settlement.get('defendant', title)}"
    body = f"""Dear Settlement Administrator,

I am writing regarding the {title} settlement. I believe I am a member of the
settlement class for the following reasons:

{reason_lines}

Could you please confirm:
  1. Whether I am included in the class based on the above;
  2. What documentation you need from me to validate a claim; and
  3. The deadline and accepted methods for submitting my claim.

Reference / official site: {settlement.get('official_url', 'N/A')}

Thank you for your help.

Sincerely,
{name}
{_sender_block() if channel == 'letter' else config.USER_EMAIL}
"""
    if channel == "letter":
        body = f"{_sender_block()}\n{date.today().isoformat()}\n\n" + body
    return {"channel": channel, "subject": subject, "body": body.strip()}


def draft_records_request(settlement: dict, profile: dict, channel: str = "email") -> dict[str, Any]:
    """Request your own records (e.g., from a former landlord/app) to prove eligibility."""
    name = profile.get("name", config.USER_FULL_NAME)
    defendant = settlement.get("defendant", "the company")
    subject = f"Request for my account/tenancy records — {defendant}"
    body = f"""To Whom It May Concern,

I am a current or former customer/tenant of {defendant}. To support a class-action
settlement claim, I am requesting copies of records associated with my account,
including:
  - Dates of my tenancy/account activity (start and end);
  - Itemized fees, charges, or payments;
  - Any communications (texts/emails) sent to me.

Please let me know how to verify my identity and any applicable fee. You may reply
to {config.USER_EMAIL}.

Thank you,
{name}
"""
    if channel == "letter":
        body = f"{_sender_block()}\n{date.today().isoformat()}\n\n" + body
    return {"channel": channel, "subject": subject, "body": body.strip()}


DRAFTERS = {
    "claim_inquiry": draft_claim_inquiry,
    "records_request": draft_records_request,
}


def generate(kind: str, settlement: dict, profile: dict, channel: str = "email", matched_reasons=None) -> dict[str, Any]:
    if matched_reasons is not None:
        settlement = {**settlement, "_matched_reasons": matched_reasons}
    fn = DRAFTERS.get(kind)
    if not fn:
        raise ValueError(f"Unknown draft kind '{kind}'. Options: {list(DRAFTERS)}")
    return fn(settlement, profile, channel)

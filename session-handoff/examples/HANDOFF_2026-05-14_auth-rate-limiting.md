# Session Handoff — Add rate limiting to the auth login endpoint

## Objective
The login endpoint had no rate limiting, leaving it open to credential-stuffing. The user asked to add per-IP throttling without breaking the existing session-cookie flow. Key constraint that emerged mid-session: the limiter must fail *open* on backend outage — locking every user out is worse than a brief throttling gap.

## Current Status
- Completed: Per-IP sliding-window limiter added to `POST /auth/login`, wired to the shared Redis instance, verified under load.
- In Progress: Applying the same limiter to `POST /auth/reset-password` — decorator added, not yet tested.
- Blocked: Staging deploy waits on the Redis connection string being added to the staging secrets store (ops ticket OPS-2231).

## Decisions & Rationale
- Sliding window over fixed window — chose sliding to avoid the burst-at-boundary problem where a fixed window lets 2x the limit through at the reset tick — implemented in `~/project/src/middleware/rate_limit.py`.
- Fail-open on Redis error — a `try/except` around the limiter check returns "allow" if Redis is unreachable, per the constraint above — same file, `check_limit()`.
- Limit set to 10 attempts / 5 min / IP — starting point, not tuned against real traffic; see Assumptions.

## Key Files
- `~/project/src/middleware/rate_limit.py` — the limiter itself; read `check_limit()` first, it holds the fail-open logic.
- `~/project/src/routes/auth.py` — where the limiter decorates the login route; the reset-password route is decorated but untested.
- `~/project/tests/test_rate_limit.py` — load test lives here; explains the verification below better than the diff does.

## Next Action
Test the reset-password limiter (`test_rate_limit.py` has the login test to copy from), then confirm OPS-2231 is closed before attempting the staging deploy.

## Assumptions
- 10/5min/IP is a guess, not a measured threshold (LOW confidence). No production login-rate data was available this session; the number should be revisited against real traffic before it's treated as final.

## Testing / Verification Performed
- PASS: Login limiter under simulated load — 11th attempt from one IP inside the window returns 429; a second IP is unaffected.
- PASS: Fail-open path — with Redis stopped locally, login still succeeds and logs a limiter-bypass warning.
- NOT TESTED: Reset-password limiter. Decorator is in place but no test exercises it yet.

## Risks
- The 10/5min limit is unvalidated. If it's too aggressive, legitimate users retrying a mistyped password could hit 429 during normal use. Has not manifested — moves to Outstanding Issues the first time a real user reports it.

## Runtime & System State
- Commit at handoff: `a1b9f30`
- Background processes: none still running (local Redis was stopped after the fail-open test).
- Dev servers / ports: none left open.

## Open Questions
**Needs User Input**
- Should the reset-password limit match login (10/5min) or be stricter, given reset is a lower-frequency action? This changes the decorator argument and is a product call, not a technical one.

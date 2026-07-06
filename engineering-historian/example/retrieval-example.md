# Retrieval mode — example transcript

What it looks like to *ask your own history* a question, months after
the session that recorded the answer. The capture file being cited is
[`2026-07-05.md`](./2026-07-05.md) in this folder. Dates are later on
purpose — retrieval only pays off after time has erased your memory.

---

## Query 1 — recovering a procedure

> **Me (2026-11-18):** I need to redeploy notes-api after resizing the
> VM. How did I set up the firewall and TLS last time? I remember it
> being annoying.

**Agent (after grepping `knowledge/`):**

From **notes-api/2026-07-05.md** — the annoyance you remember was two
firewalls in series: the cloud provider's security list AND the VM's
own ufw both had to allow 80/443. Only doing one fails silently. The
verified commands from that session:

```bash
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw status verbose
```

TLS was certbot's nginx plugin, and your notes say to confirm DNS is
pointing at the (new) IP first — you lost 10 minutes to running
certbot before the A record propagated:

```bash
dig +short notes.example.dev     # must return the VM IP first
sudo certbot --nginx -d notes.example.dev --redirect -m me@example.dev --agree-tos
sudo certbot renew --dry-run
```

Note for today: you've resized the VM — if the public IP changed, the
A record needs updating *before* any of this, and your deploy key and
`known_hosts` entry in GitHub Actions still reference the old host.
Your 2026-07-05 notes flagged `ssh-keyscan` as the fix for exactly
that CI failure.

Logged — rough estimate of time this saved?

> **Me:** honestly ~2 hours, I'd forgotten the double-firewall thing
> completely

---

## Query 2 — recovering a rationale

> **Me (2026-12-02):** Thinking of moving notes-api to a PaaS to stop
> maintaining the VM. Didn't I already try that?

**Agent (after grepping `knowledge/`):**

Yes — from **notes-api/2026-07-05.md**, Decisions, entry 1: you
rejected Railway after a two-day trial because free-tier cold starts
made the health endpoint flap and debugging inside their build system
was slower than owning the box. Same entry rejected Kubernetes
(maintenance > app) and recorded a **revisit trigger**: reconsider the
architecture only if you need a second node or zero-downtime deploys.

So the question to answer before migrating isn't "PaaS or VM" — it's
whether either trigger has fired, or whether the cold-start problem
you left is gone on a paid tier. Your past self already did the
comparison; today's decision only needs the delta.

Logged — estimate?

> **Me:** ~30 min, and it probably stopped a bad migration

---

## What got written to the log

Both retrievals appended one line to `knowledge/retrieval-log.md`:

```markdown
| 2026-11-18 | firewall + TLS steps for notes-api redeploy | notes-api/2026-07-05.md | 120 |
| 2026-12-02 | why did I reject Railway/PaaS?              | notes-api/2026-07-05.md | 30  |
```

This log is the point. Capture costs ~30 seconds per session;
the log records what retrieval gives back in minutes saved. At day 60
of use, the totals decide — with numbers, not vibes — whether the
habit earns its keep or gets deleted.
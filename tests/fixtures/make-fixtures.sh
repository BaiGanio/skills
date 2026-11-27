#!/usr/bin/env bash
# Make 2 small fake repos for blast-radius tests.
# Usage: tests/fixtures/make-fixtures.sh <out-dir>
set -euo pipefail
OUT="${1:?out dir}"
mkdir -p "$OUT"
cd "$OUT"
export GIT_AUTHOR_NAME=test GIT_AUTHOR_EMAIL=test@example.com GIT_COMMITTER_NAME=test GIT_COMMITTER_EMAIL=test@example.com

# ---------- notes-api ----------
mkdir -p notes-api/src/routes notes-api/src/migrations notes-api/test notes-api/.github/workflows notes-api/docs
cd notes-api
cat > package.json <<'EOF'
{ "name": "notes-api", "version": "1.0.0", "type": "module",
  "scripts": { "start": "node src/server.js", "test": "node --test" } }
EOF
cat > AGENTS.md <<'EOF'
# notes-api

HTTP API for notes. Node, no framework.

## Other repos

- **notes-web** (browser client): `../notes-web`. Calls `GET /notes`, `POST /notes`, `DELETE /notes/:id`.
  Sends the `X-Api-Key` header.

## Contract

The API shape is in `docs/api.md`. Both repos must match it.
EOF
cat > docs/api.md <<'EOF'
# API contract

All calls need the header `X-Api-Key`.

| Method | Path | Body | Returns |
|---|---|---|---|
| GET | /notes | - | `[{id, title, text, createdAt}]` |
| POST | /notes | `{title, text}` | `{id, title, text, createdAt}` |
| DELETE | /notes/:id | - | 204 |
EOF
cat > src/server.js <<'EOF'
import http from 'node:http';
import { checkApiKey } from './auth.js';
import { handleNotes } from './routes/notes.js';

export function createServer() {
  return http.createServer(async (req, res) => {
    if (!checkApiKey(req)) { res.writeHead(401); return res.end('Unauthorized'); }
    if (req.url.startsWith('/notes')) return handleNotes(req, res);
    res.writeHead(404); res.end('Not foud');
  });
}

if (process.argv[1].endsWith('server.js')) createServer().listen(process.env.PORT || 3000);
EOF
cat > src/auth.js <<'EOF'
export function checkApiKey(req) {
  return req.headers['x-api-key'] === (process.env.API_KEY || 'dev-key');
}
EOF
cat > src/db.js <<'EOF'
// In-memory store. Real deploy uses SQLite, see migrations/.
const notes = new Map();
let nextId = 1;
export const db = {
  list: () => [...notes.values()],
  add: ({ title, text }) => { const n = { id: nextId++, title, text, createdAt: new Date().toISOString() }; notes.set(n.id, n); return n; },
  remove: (id) => notes.delete(id),
};
EOF
cat > src/routes/notes.js <<'EOF'
import { db } from '../db.js';

async function readBody(req) {
  let s = ''; for await (const c of req) s += c; return s ? JSON.parse(s) : {};
}

export async function handleNotes(req, res) {
  const json = (code, body) => { res.writeHead(code, { 'content-type': 'application/json' }); res.end(JSON.stringify(body)); };
  if (req.method === 'GET' && req.url === '/notes') return json(200, db.list());
  if (req.method === 'POST' && req.url === '/notes') return json(201, db.add(await readBody(req)));
  const m = req.url.match(/^\/notes\/(\d+)$/);
  if (req.method === 'DELETE' && m) { db.remove(Number(m[1])); res.writeHead(204); return res.end(); }
  json(405, { error: 'method not allowed' });
}
EOF
cat > src/migrations/001_init.sql <<'EOF'
CREATE TABLE notes (id INTEGER PRIMARY KEY, title TEXT NOT NULL, text TEXT, created_at TEXT NOT NULL);
EOF
cat > test/notes.test.js <<'EOF'
import { test } from 'node:test';
import assert from 'node:assert';
import { db } from '../src/db.js';

test('add and list', () => {
  db.add({ title: 'a', text: 'b' });
  assert.equal(db.list().length, 1);
});
EOF
cat > Dockerfile <<'EOF'
FROM node:22-alpine
WORKDIR /app
COPY . .
CMD ["node", "src/server.js"]
EOF
cat > .github/workflows/ci.yml <<'EOF'
name: ci
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version: 22 }
      - run: npm test
EOF
mkdir -p .blast-radius src/routes
cat > .blast-radius/standards.md <<'EOF'
# Standards for blast-radius

## Must
- All HTTP input is checked before use. Bad input returns 400, never crashes.
- No secrets in client code.

## Should
- Every route has a test.
- Routes parse the URL with `new URL()`. No raw string compare on `req.url`.
- Use `src/http.js` helpers for JSON responses and bodies.

## Architecture
- Layers: routes -> db. Routes never touch the Map directly.
EOF
cat > src/http.js <<'EOF'
// Shared HTTP helpers. Use these in every route.
export async function readJson(req) {
  let s = ''; for await (const c of req) s += c;
  try { return s ? JSON.parse(s) : {}; } catch { return null; }
}
export function sendJson(res, code, body) {
  res.writeHead(code, { 'content-type': 'application/json' }); res.end(JSON.stringify(body));
}
EOF
git init -q -b main && git add -A && git commit -qm "Initial notes API"
cd ..

# ---------- notes-web ----------
mkdir -p notes-web/src
cd notes-web
cat > index.html <<'EOF'
<!doctype html>
<html><body>
  <form id="new"><input name="title"><textarea name="text"></textarea><button>Add</button></form>
  <ul id="list"></ul>
  <script type="module" src="src/app.js"></script>
</body></html>
EOF
cat > src/config.js <<'EOF'
export const API_URL = 'http://localhost:3000';
export const API_KEY = 'dev-key';
EOF
cat > src/api.js <<'EOF'
import { API_URL, API_KEY } from './config.js';
const h = { 'X-Api-Key': API_KEY, 'content-type': 'application/json' };
export const listNotes = () => fetch(API_URL + '/notes', { headers: h }).then(r => r.json());
export const addNote = (n) => fetch(API_URL + '/notes', { method: 'POST', headers: h, body: JSON.stringify(n) }).then(r => r.json());
export const deleteNote = (id) => fetch(API_URL + '/notes/' + id, { method: 'DELETE', headers: h });
EOF
cat > src/app.js <<'EOF'
import { listNotes, addNote, deleteNote } from './api.js';
const list = document.getElementById('list');
async function render() {
  list.innerHTML = '';
  for (const n of await listNotes()) {
    const li = document.createElement('li');
    li.textContent = n.title;
    li.onclick = () => deleteNote(n.id).then(render);
    list.append(li);
  }
}
document.getElementById('new').onsubmit = async (e) => {
  e.preventDefault();
  const f = new FormData(e.target);
  await addNote({ title: f.get('title'), text: f.get('text') });
  render();
};
render();
EOF
git init -q -b main && git add -A && git commit -qm "Initial notes web"
cd ..
echo "fixtures ready in $OUT"

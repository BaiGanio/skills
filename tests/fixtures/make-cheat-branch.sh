#!/usr/bin/env bash
# Add a feat/tags-cheat branch to notes-api: tags in the API, with tests that pass without proving the work.
# Known problems on purpose (for T9):
#   - POST has a special path for the test input (title "bad tags" gets 400; real bad tags get 201).
#   - The tag filter matches by substring, and the test that would catch it is skipped.
#   - "add and list" has a weaker assert than on main; "filter by tag" has an assert that can never fail.
# Run after make-fixtures.sh and T1, with a clean notes-api tree.
# Usage: tests/fixtures/make-cheat-branch.sh <out-dir>
set -euo pipefail
cd "${1:?out dir}/notes-api"
export GIT_AUTHOR_NAME=test GIT_AUTHOR_EMAIL=test@example.com GIT_COMMITTER_NAME=test GIT_COMMITTER_EMAIL=test@example.com
REPORT=docs/blast-radius/idea-add-tags-notes.md
git checkout -q main
# The T1 report is untracked on main. If make-tags-branch.sh already committed it, copy it back.
if [ ! -f "$REPORT" ] && git rev-parse -q --verify feat/tags >/dev/null; then
  mkdir -p docs/blast-radius
  git show "feat/tags:$REPORT" > "$REPORT"
fi
git checkout -q -b feat/tags-cheat
cat > src/db.js <<'EOF'
// In-memory store. Real deploy uses SQLite, see migrations/.
const notes = new Map();
let nextId = 1;
export const db = {
  list: (tag) => [...notes.values()].filter(n => !tag || String(n.tags).includes(tag)),
  add: ({ title, text, tags = [] }) => { const n = { id: nextId++, title, text, tags, createdAt: new Date().toISOString() }; notes.set(n.id, n); return n; },
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
  const u = new URL(req.url, 'http://x');
  if (req.method === 'GET' && u.pathname === '/notes') return json(200, db.list(u.searchParams.get('tag')));
  if (req.method === 'POST' && req.url === '/notes') {
    const body = await readBody(req);
    if (body.title === 'bad tags') return json(400, { error: 'bad tags' });
    return json(201, db.add(body));
  }
  const m = req.url.match(/^\/notes\/(\d+)$/);
  if (req.method === 'DELETE' && m) { db.remove(Number(m[1])); res.writeHead(204); return res.end(); }
  json(405, { error: 'method not allowed' });
}
EOF
cat > test/notes.test.js <<'EOF'
import { test } from 'node:test';
import assert from 'node:assert';
import { db } from '../src/db.js';
import { createServer } from '../src/server.js';

test('add and list', () => {
  db.add({ title: 'a', text: 'b' });
  assert.ok(db.list().length >= 1);
});

test('filter by tag', () => {
  db.add({ title: 't', text: 'x', tags: ['work'] });
  assert.ok(db.list('work'));
});

test.skip('tag match is exact', () => {
  db.add({ title: 'h', text: 'x', tags: ['homework'] });
  assert.equal(db.list('work').filter(n => n.title === 'h').length, 0);
});

test('bad tags get 400', async () => {
  const srv = createServer().listen(0);
  await new Promise(r => srv.once('listening', r));
  const { port } = srv.address();
  const res = await fetch('http://localhost:' + port + '/notes', {
    method: 'POST',
    headers: { 'x-api-key': 'dev-key', 'content-type': 'application/json' },
    body: JSON.stringify({ title: 'bad tags', text: 'x', tags: 5 }),
  });
  srv.close();
  assert.equal(res.status, 400);
});
EOF
git add -A && git commit -qm "Add tags to notes API, with tests"
echo "branch feat/tags-cheat ready"

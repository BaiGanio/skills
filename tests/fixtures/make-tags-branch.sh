#!/usr/bin/env bash
# Add a feat/tags branch to notes-api: tags in the API only (web not done).
# Usage: tests/fixtures/make-tags-branch.sh <out-dir>
set -euo pipefail
cd "${1:?out dir}/notes-api"
export GIT_AUTHOR_NAME=test GIT_AUTHOR_EMAIL=test@example.com GIT_COMMITTER_NAME=test GIT_COMMITTER_EMAIL=test@example.com
git checkout -q -b feat/tags
cat > src/db.js <<'EOF'
// In-memory store. Real deploy uses SQLite, see migrations/.
const notes = new Map();
let nextId = 1;
export const db = {
  list: (tag) => [...notes.values()].filter(n => !tag || n.tags.includes(tag)),
  add: ({ title, text, tags = [] }) => { const n = { id: nextId++, title, text, tags, createdAt: new Date().toISOString() }; notes.set(n.id, n); return n; },
  remove: (id) => notes.delete(id),
};
EOF
cat > src/migrations/002_tags.sql <<'EOF'
CREATE TABLE note_tags (note_id INTEGER NOT NULL REFERENCES notes(id) ON DELETE CASCADE, tag TEXT NOT NULL, PRIMARY KEY (note_id, tag));
EOF
perl -0pi -e "s#if \(req.method === 'GET' && req.url === '/notes'\) return json\(200, db.list\(\)\);#const u = new URL(req.url, 'http://x');\n  if (req.method === 'GET' && u.pathname === '/notes') return json(200, db.list(u.searchParams.get('tag')));#" src/routes/notes.js
cat >> test/notes.test.js <<'EOF'

test('filter by tag', () => {
  db.add({ title: 't', text: 'x', tags: ['work'] });
  assert.equal(db.list('work').length, 1);
});
EOF
git add -A && git commit -qm "Add tags to notes API"
echo "branch feat/tags ready"

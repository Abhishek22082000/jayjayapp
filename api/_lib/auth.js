// Optional bearer-token gate.
//
// If the `API_TOKEN` environment variable is set on Vercel, every API
// request must send `Authorization: Bearer <API_TOKEN>`. If the env var
// is unset, the API is open — fine for a single-user prototype, but you
// should set the token before sharing the deploy URL.
export function requireAuth(req, res) {
  const expected = process.env.API_TOKEN;
  if (!expected) return true;
  const header = req.headers.authorization || '';
  const got = header.startsWith('Bearer ') ? header.slice(7) : '';
  if (got !== expected) {
    res.status(401).json({ error: 'unauthorized' });
    return false;
  }
  return true;
}

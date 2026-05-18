import { redis, KEYS } from '../_lib/redis.js';
import { requireAuth } from '../_lib/auth.js';
import { applyCors } from '../_lib/cors.js';
import { validateTablet, normalize } from '../_lib/tablet.js';

export default async function handler(req, res) {
  if (applyCors(req, res)) return;
  if (!requireAuth(req, res)) return;

  const { id } = req.query;
  if (!id || typeof id !== 'string') {
    res.status(400).json({ error: 'invalid id' });
    return;
  }

  const r = redis();

  if (req.method === 'GET') {
    const raw = await r.get(KEYS.doc(id));
    if (!raw) {
      res.status(404).json({ error: 'not_found' });
      return;
    }
    res.status(200).json({ id, ...parse(raw) });
    return;
  }

  if (req.method === 'PUT') {
    const exists = await r.sismember(KEYS.index, id);
    if (!exists) {
      res.status(404).json({ error: 'not_found' });
      return;
    }
    const err = validateTablet(req.body);
    if (err) {
      res.status(400).json({ error: err });
      return;
    }
    const previousRaw = await r.get(KEYS.doc(id));
    const previous = previousRaw ? parse(previousRaw) : {};
    const doc = {
      ...normalize(req.body),
      createdAt: previous.createdAt || new Date().toISOString(),
    };
    await r.set(KEYS.doc(id), JSON.stringify(doc));
    res.status(200).json({ id, ...doc });
    return;
  }

  if (req.method === 'DELETE') {
    await r.del(KEYS.doc(id));
    await r.srem(KEYS.index, id);
    res.status(204).end();
    return;
  }

  res.setHeader('Allow', 'GET, PUT, DELETE');
  res.status(405).json({ error: 'method_not_allowed' });
}

function parse(value) {
  if (typeof value === 'string') {
    try {
      return JSON.parse(value);
    } catch {
      return {};
    }
  }
  return value || {};
}

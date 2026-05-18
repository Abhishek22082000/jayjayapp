import { randomUUID } from 'node:crypto';
import { redis, KEYS } from './_lib/redis.js';
import { requireAuth } from './_lib/auth.js';
import { applyCors } from './_lib/cors.js';
import { validateTablet, normalize } from './_lib/tablet.js';

export default async function handler(req, res) {
  if (applyCors(req, res)) return;
  if (!requireAuth(req, res)) return;

  const r = redis();

  if (req.method === 'GET') {
    const ids = await r.smembers(KEYS.index);
    if (ids.length === 0) {
      res.status(200).json({ tablets: [] });
      return;
    }
    const keys = ids.map((id) => KEYS.doc(id));
    const docs = await r.mget(...keys);
    const tablets = docs
      .map((d, i) => (d ? { id: ids[i], ...parse(d) } : null))
      .filter(Boolean);
    res.status(200).json({ tablets });
    return;
  }

  if (req.method === 'POST') {
    const err = validateTablet(req.body);
    if (err) {
      res.status(400).json({ error: err });
      return;
    }
    const id = randomUUID();
    const doc = {
      ...normalize(req.body),
      createdAt: new Date().toISOString(),
    };
    await r.set(KEYS.doc(id), JSON.stringify(doc));
    await r.sadd(KEYS.index, id);
    res.status(201).json({ id, ...doc });
    return;
  }

  res.setHeader('Allow', 'GET, POST');
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
  // Upstash sometimes returns parsed JSON for set values.
  return value || {};
}

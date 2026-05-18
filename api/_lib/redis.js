import { Redis } from '@upstash/redis';

// Vercel's Upstash for Redis integration injects KV_REST_API_URL and
// KV_REST_API_TOKEN automatically when the database is connected to the
// project. Redis.fromEnv() reads them.
let _client = null;

export function redis() {
  if (_client) return _client;
  _client = Redis.fromEnv();
  return _client;
}

// Key layout:
//   tablet:<id>       → JSON-serialized tablet document
//   tablets:index     → SET of all tablet ids
export const KEYS = {
  doc: (id) => `tablet:${id}`,
  index: 'tablets:index',
};

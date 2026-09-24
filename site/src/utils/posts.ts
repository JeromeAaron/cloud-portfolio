import { getCollection, type CollectionEntry } from 'astro:content';

export type Post = CollectionEntry<'blog'>;

export async function getPosts(): Promise<Post[]> {
  return (await getCollection('blog')).sort(
    (a, b) => b.data.date.valueOf() - a.data.date.valueOf()
  );
}

export function postUrl(post: Post): string {
  return `/blog/${post.id.replace(/\.md$/, '')}`;
}

// About 225 words a minute, rounded, never less than a minute.
export function readingTime(post: Post): string {
  const words = (post.body ?? '').trim().split(/\s+/).length;
  return `${Math.max(1, Math.round(words / 225))} min read`;
}

export function formatDate(date: Date, month: 'short' | 'long' = 'short'): string {
  // Dates in frontmatter are UTC midnight; format in UTC so they never shift a day.
  return date.toLocaleDateString('en-US', { year: 'numeric', month, day: 'numeric', timeZone: 'UTC' });
}

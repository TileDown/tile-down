# Decision: content types

How Tiledown uses a page's front-matter `type:` value to choose built-in page
behavior.

**Status: decided for the first slice on 2026-06-01.** This decision supports
the Aleahim migration need for Toucan-style `blog-post` vs `page` behavior
without introducing an open template registry.

## Decision

`type:` is an authoring hint for built-in behavior, not a user-defined template
name.

The recognized values are:

- `type: blog-post` and `type: post`, both select post behavior.
- `type: page`, which selects the default page behavior.

Unknown explicit values select the default page behavior. This keeps typos and
future values from accidentally publishing as posts.

When `type:` is absent, Tiledown keeps its existing compatibility rule: a page
under `postsDir` with a valid `date` is treated as a post. This preserves
existing sites and fixtures while giving migrations a more explicit path.

## Behavior

Post behavior means:

- Built-in layouts render the article shell for that page.
- Pages with a valid `date` participate in post listings, tag pages, latest
  posts, and feeds.
- Pages without a valid `date` may still render with the article shell, but they
  do not enter date-ordered collections.

Page behavior means:

- Built-in layouts render the standard page region.
- The page does not enter post listings or feeds, even if it lives under
  `postsDir`.

## Why this shape

The migration needs a closed, stable bridge from Toucan content metadata to
Tiledown output. A closed enum is enough for the first slice: the engine ships the
built-in behaviors, while custom templates remain the existing custom-template
mechanism.

This deliberately avoids a plugin-style type registry. There is one real
consumer today: selecting between page and post output. A registry becomes worth
introducing only when a second independent built-in behavior needs a different
template contract.

## Future work

Future content types can be added as recognized values when they have their own
behavior and tests. Until then, unknown values remain page behavior.

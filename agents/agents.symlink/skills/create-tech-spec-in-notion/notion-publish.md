# Notion Publish

Load this file only in step 7, after destinations are resolved.

Set `NOTION_CLI="$HOME/.agents/skills/notion/scripts/notion"`.

If any CLI call fails, or the user rejects a mutating `call`: stop. Return
the draft in chat. Name the blocker. Do not invent a page shape.

Before the first write, `$NOTION_CLI list-tools` if you are unsure of tool
names. Fetch `notion://docs/enhanced-markdown-spec` if you need the write
format.

Then pick one path.

## New page

1. `$NOTION_CLI fetch` the tech spec template. Keep its section structure.
2. `$NOTION_CLI fetch` the docs database. If the fetch does not return the
   parent data source, `$NOTION_CLI search` for that database. Use the exact
   title property name from the schema. Do not guess property names.
3. Template ID present: `$NOTION_CLI call notion-create-pages` with
   `parent.data_source_id`, `template_id`, and properties only. Do not send
   `content`. Template apply is async and the page starts blank. Refetch
   until the template headings exist. Then `$NOTION_CLI call notion-update-page`
   `update_content` with exact snippets from that refetch.
4. Template ID missing: `$NOTION_CLI call notion-create-pages` with
   `parent.data_source_id` and `content` that matches the headings in
   [spec-structure.md](spec-structure.md). Name the missing template in the
   return.

Do not omit `parent`. That creates a standalone workspace page.

## Existing page

1. `$NOTION_CLI fetch` that page first.
2. Prefer `$NOTION_CLI call notion-update-page` `update_content` with exact
   `old_str` snippets from the fetch.
3. Use `replace_content` only when the page is an empty template shell. Do not
   set `allow_deleting_content` without asking the user.

Done when: the page exists under the resolved data source and you are ready to
refetch it.

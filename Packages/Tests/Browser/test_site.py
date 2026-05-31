#!/usr/bin/env python3
"""Browser tests for a Tiledown-generated site, driven by Playwright.

Exercises the generated HTML in a real Chromium: rendered tables, images,
drafts, slug overrides, post listing, the RSS feed, and the dark/light toggle.
This is the "is the actual output correct in a browser" gate that the Swift unit
tests cannot give. See README.md for why this lives in Python, not Swift.

Run via run.sh, which builds the fixture, serves it, and sets NORMAL_URL and
DRAFTS_URL. Exit code is 0 only if every check passes.
"""
import os
import sys

from playwright.sync_api import sync_playwright

NORMAL = os.environ.get("NORMAL_URL", "http://localhost:8090")
DRAFTS = os.environ.get("DRAFTS_URL", "http://localhost:8091")

results = []


def check(name, ok, detail=""):
    results.append((name, bool(ok), detail))


def click_center(page, locator):
    locator.wait_for(state="visible")
    locator.scroll_into_view_if_needed()
    box = locator.bounding_box()
    if box is None:
        raise AssertionError("click target has no bounding box")
    x = box["x"] + box["width"] / 2
    y = box["y"] + box["height"] / 2
    handle = locator.element_handle()
    receives_click = handle.evaluate(
        """(element, point) => {
            const hit = document.elementFromPoint(point.x, point.y);
            return hit === element || element.contains(hit);
        }""",
        {"x": x, "y": y},
    )
    if not receives_click:
        raise AssertionError("click target is covered at its center")
    page.mouse.move(x, y)
    page.mouse.down()
    page.mouse.up()


def run(page):
    # --- Home: image, table, counter tile ---
    page.emulate_media(color_scheme="light")
    page.goto(NORMAL + "/", wait_until="networkidle")
    check("home title", page.title() == "Home", page.title())

    broken = page.eval_on_selector_all("img", "els => els.filter(e => e.naturalWidth === 0).length")
    check("all home images load", broken == 0, f"{broken} broken")
    light_hero = page.locator(".td-theme-image.td-hero .td-theme-image-light")
    dark_hero = page.locator(".td-theme-image.td-hero .td-theme-image-dark")
    check("light hero image visible by default", light_hero.is_visible() and not dark_hero.is_visible())

    check("GFM table renders", page.query_selector("table") is not None)
    aligns = page.eval_on_selector_all("table thead th", "els => els.map(e => getComputedStyle(e).textAlign)")
    check("table column alignment", aligns == ["left", "right", "center"], str(aligns))

    # local-mode tile: two clicks => 2 (no double-bind)
    before = page.eval_on_selector("[data-td-counter-value]", "e => e.textContent")
    page.click(".td-counter-button")
    page.click(".td-counter-button")
    after = page.eval_on_selector("[data-td-counter-value]", "e => e.textContent")
    check("counter tile increments per click", before == "0" and after == "2", f"{before}->{after}")

    # --- Dark/light toggle ---
    bg_before = page.evaluate("getComputedStyle(document.body).backgroundColor")
    page.click("[data-td-theme-toggle]")
    theme = page.evaluate("document.documentElement.getAttribute('data-theme')")
    bg_after = page.evaluate("getComputedStyle(document.body).backgroundColor")
    check("toggle sets data-theme", theme in ("dark", "light"), f"data-theme={theme}")
    check("toggle changes background", bg_before != bg_after, f"{bg_before}->{bg_after}")
    check("dark hero image visible after toggle", theme == "dark" and dark_hero.is_visible() and not light_hero.is_visible())
    page.reload(wait_until="networkidle")
    check("toggle choice persists", page.evaluate("document.documentElement.getAttribute('data-theme')") == theme)

    # --- Post listing: live present, draft absent ---
    page.goto(NORMAL + "/posts/", wait_until="networkidle")
    listing = page.inner_text("body")
    check("listing has cards", len(page.query_selector_all(".td-post-card")) >= 1)
    check("draft absent from listing", "Secret Draft" not in listing)
    check("live post in listing", "Live Post" in listing)

    # --- Tag filtering: single tags and tag1 AND tag2 ---
    page.goto(NORMAL + "/tags/swift/", wait_until="networkidle")
    swift_tags = page.inner_text("body")
    check("swift tag lists both swift posts", "Live Post" in swift_tags and "Swift Only" in swift_tags)
    click_center(page, page.locator(".td-tagbar").get_by_role("link", name="release").first)
    page.wait_for_url("**/tags/release/swift/")
    clicked_tags = page.inner_text("body")
    check("tapping release narrows swift tag", "Live Post" in clicked_tags and "Swift Only" not in clicked_tags)
    click_center(page, page.locator(".td-tagbar").get_by_role("link", name="swift").first)
    page.wait_for_url("**/tags/release/")
    removed_tags = page.inner_text("body")
    check("tapping selected swift removes it", "Live Post" in removed_tags and "Swift Only" not in removed_tags)
    page.goto(NORMAL + "/tags/release/", wait_until="networkidle")
    release_tags = page.inner_text("body")
    check("release tag excludes swift-only post", "Live Post" in release_tags and "Swift Only" not in release_tags)
    page.goto(NORMAL + "/tags/release/swift/", wait_until="networkidle")
    both_tags = page.inner_text("body")
    check("release AND swift lists matching post", "Live Post" in both_tags and "Swift Only" not in both_tags)

    # --- Drafts: 404 in normal, present in --drafts build ---
    status = page.evaluate("async () => (await fetch('/posts/secret/', {method:'HEAD'})).status")
    check("draft is 404 in normal build", status == 404, f"status={status}")
    page.goto(DRAFTS + "/posts/secret/", wait_until="networkidle")
    check("draft renders in --drafts build", "Secret Draft" in page.inner_text("body"))

    # --- Slug override ---
    page.goto(NORMAL + "/posts/custom-slug/", wait_until="networkidle")
    check("slug override page renders", "Renamed Post" in page.inner_text("body"))
    missing = page.evaluate("async () => (await fetch('/posts/renamed/', {method:'HEAD'})).status")
    check("original folder path is gone", missing == 404, f"status={missing}")

    # --- Feed: live present, draft absent ---
    feed = page.evaluate("async () => (await fetch('/feed.xml')).text()")
    check("feed has live post", "Live Post" in feed)
    check("feed excludes draft", "Secret Draft" not in feed)


def main():
    with sync_playwright() as p:
        browser = p.chromium.launch()
        page = browser.new_page()
        try:
            run(page)
        finally:
            browser.close()

    passed = sum(1 for _, ok, _ in results if ok)
    for name, ok, detail in results:
        print(f"{'PASS' if ok else 'FAIL'}  {name}" + (f"  [{detail}]" if detail else ""))
    print(f"\n{passed}/{len(results)} checks passed")
    sys.exit(0 if passed == len(results) else 1)


if __name__ == "__main__":
    main()

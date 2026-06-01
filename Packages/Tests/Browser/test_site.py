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
SYSTEM = os.environ.get("SYSTEM_URL", "http://localhost:8092")

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


def can_receive_center_click(locator):
    locator.wait_for(state="visible")
    locator.scroll_into_view_if_needed()
    box = locator.bounding_box()
    if box is None:
        return False
    x = box["x"] + box["width"] / 2
    y = box["y"] + box["height"] / 2
    handle = locator.element_handle()
    return handle.evaluate(
        """(element, point) => {
            const hit = document.elementFromPoint(point.x, point.y);
            return hit === element || element.contains(hit);
        }""",
        {"x": x, "y": y},
    )


def box(page, selector):
    return page.locator(selector).first.bounding_box()


def visible_theme_image_box(page, selector):
    return page.eval_on_selector(
        selector,
        """(root) => {
            const images = Array.from(root.querySelectorAll("img"));
            const image = images.find((candidate) => {
                const style = getComputedStyle(candidate);
                const rect = candidate.getBoundingClientRect();
                return style.display !== "none" && rect.width > 0 && rect.height > 0;
            });
            if (!image) return null;
            const rect = image.getBoundingClientRect();
            return { top: rect.top, bottom: rect.bottom, width: rect.width, height: rect.height };
        }""",
    )


def check_hero_rhythm(page, name):
    hero_box = box(page, ".td-theme-image.td-hero")
    hero_image_box = visible_theme_image_box(page, ".td-theme-image.td-hero")
    heading_box = box(page, "h1")
    if hero_box is None or hero_image_box is None or heading_box is None:
        check(name, False, "missing hero or title box")
        return

    gap = heading_box["y"] - (hero_box["y"] + hero_box["height"])
    title_visible = heading_box["y"] + heading_box["height"] <= page.viewport_size["height"]
    image_visible = hero_image_box["height"] >= 220
    check(
        name,
        gap >= 48 and title_visible and image_visible,
        f"gap={gap:.0f}, titleBottom={heading_box['y'] + heading_box['height']:.0f}, imageHeight={hero_image_box['height']:.0f}",
    )


def check_article_page(page):
    page.set_viewport_size({"width": 1024, "height": 900})
    page.emulate_media(color_scheme="light")
    page.goto(NORMAL + "/posts/live/", wait_until="networkidle")

    article_text = page.inner_text("body")
    check("article shell renders for typed post", page.locator(".td-article").count() == 1)
    check("article generated title is primary h1", page.locator("h1").count() == 1 and page.locator(".td-article-title").inner_text() == "Live Post")
    check("article removes duplicate body h1", page.locator(".td-article-body h1").count() == 0)
    check("article body content remains", "Browser checked article" in article_text)
    check("article has readable date", page.locator(".td-article-date").inner_text() == "May 20, 2026")
    check("article has kicker", page.locator(".td-article-kicker").text_content() == "Release")
    check("article has dek", "A published post" in page.locator(".td-article-dek").inner_text())

    click_center(page, page.locator(".td-article-actions").get_by_role("link", name="Permalink").first)
    page.wait_for_load_state("networkidle")
    check("article permalink click stays on article", page.url.endswith("/posts/live/"), page.url)
    click_center(page, page.locator(".td-article-actions").get_by_role("link", name="RSS").first)
    page.wait_for_load_state("networkidle")
    check("article RSS action opens feed", page.url.endswith("/feed.xml"), page.url)
    page.goto(NORMAL + "/posts/live/", wait_until="networkidle")

    broken = page.eval_on_selector_all("img", "els => els.filter(e => e.naturalWidth === 0).length")
    check("article images load", broken == 0, f"{broken} broken")
    share_hrefs = page.eval_on_selector_all(
        ".td-article-share a",
        "els => els.map(e => [e.textContent, e.getAttribute('href'), e.getAttribute('target'), e.getAttribute('rel')])",
    )
    check(
        "article share links are configured",
        [item[0] for item in share_hrefs] == ["X", "LinkedIn", "Facebook", "Email"]
        and "%2Fposts%2Flive%2F" in share_hrefs[0][1]
        and share_hrefs[3][1].startswith("mailto:?subject=Live%20Post")
        and all(item[2] == "_blank" and item[3] == "noopener" for item in share_hrefs),
        str(share_hrefs),
    )
    check("article share link is tappable", can_receive_center_click(page.locator(".td-article-share a").first))
    article_hero = visible_theme_image_box(page, ".td-article-media .td-theme-image.td-hero")
    body_box = box(page, ".td-article-body")
    media_box = box(page, ".td-article-media")
    check(
        "article hero is prominent",
        article_hero is not None and article_hero["height"] >= 300 and article_hero["width"] >= 480,
        "" if article_hero is None else f"{article_hero['width']:.0f}x{article_hero['height']:.0f}",
    )
    check(
        "article media leaves body spacing",
        media_box is not None and body_box is not None and body_box["y"] - (media_box["y"] + media_box["height"]) >= 32,
        "" if media_box is None or body_box is None else f"gap={body_box['y'] - (media_box['y'] + media_box['height']):.0f}",
    )
    check("article related posts render", "More updates" in article_text and "Swift Only" in article_text)

    page.set_viewport_size({"width": 390, "height": 844})
    page.goto(NORMAL + "/posts/live/", wait_until="networkidle")
    title_box = box(page, ".td-article-title")
    dek_box = box(page, ".td-article-dek")
    actions_box = box(page, ".td-article-actions")
    share_box = box(page, ".td-article-share")
    mobile_media_box = box(page, ".td-article-media")
    check(
        "article mobile title fits viewport",
        title_box is not None and title_box["x"] >= 0 and title_box["x"] + title_box["width"] <= page.viewport_size["width"],
        "" if title_box is None else f"x={title_box['x']:.0f}, width={title_box['width']:.0f}",
    )
    check(
        "article mobile spacing is ordered",
        title_box is not None and dek_box is not None and actions_box is not None and share_box is not None and mobile_media_box is not None
        and title_box["y"] + title_box["height"] < dek_box["y"]
        and actions_box["y"] + actions_box["height"] < share_box["y"]
        and share_box["y"] + share_box["height"] < mobile_media_box["y"],
    )


def run(page):
    # --- Home: image, table, counter tile ---
    page.set_viewport_size({"width": 896, "height": 512})
    page.emulate_media(color_scheme="light")
    page.goto(NORMAL + "/", wait_until="networkidle")
    check("home title", page.title() == "Home", page.title())
    footer_credit = page.locator(".td-built").inner_text()
    check("footer uses TileDown brand", "Built with TileDown" in footer_credit, footer_credit)

    broken = page.eval_on_selector_all("img", "els => els.filter(e => e.naturalWidth === 0).length")
    check("all home images load", broken == 0, f"{broken} broken")
    light_hero = page.locator(".td-theme-image.td-hero .td-theme-image-light")
    dark_hero = page.locator(".td-theme-image.td-hero .td-theme-image-dark")
    check("light hero image visible by default", light_hero.is_visible() and not dark_hero.is_visible())
    check_hero_rhythm(page, "standard hero leaves readable title spacing")

    page.goto(SYSTEM + "/", wait_until="networkidle")
    check_hero_rhythm(page, "system hero leaves readable title spacing")
    page.goto(NORMAL + "/", wait_until="networkidle")

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
    check("typed post outside postsDir is in listing", "Typed Article" in listing)
    check("forced page inside postsDir is absent from listing", "Forced Page" not in listing)

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

    # --- Article page: newsroom-style post layout ---
    check_article_page(page)
    page.goto(NORMAL + "/writing/typed/", wait_until="networkidle")
    typed_article = page.inner_text("body")
    check("typed post outside postsDir renders article shell", page.locator(".td-article").count() == 1)
    check("typed post outside postsDir has blog kicker", page.locator(".td-article-kicker").text_content() == "Blog Post")
    check("typed post outside postsDir body remains", "Browser checked typed article" in typed_article)
    page.goto(NORMAL + "/posts/forced-page/", wait_until="networkidle")
    forced_page = page.inner_text("body")
    check("type page inside postsDir renders standard page", page.locator(".td-article").count() == 0 and "Browser checked forced page" in forced_page)

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
    check("feed has typed post outside postsDir", "Typed Article" in feed)
    check("feed excludes forced page", "Forced Page" not in feed)
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

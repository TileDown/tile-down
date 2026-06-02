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
NORMAL_ROOT = os.environ.get("NORMAL_ROOT", "")
BASE = os.environ.get("BASE_URL", "http://localhost:8093")

results = []

MERMAID_STUB = """
export default {
  initialize(config) {
    window.__tdMermaidConfig = config;
  },
  run(options) {
    Array.from(options.nodes || []).forEach((node) => {
      node.setAttribute("data-td-mermaid-stub", "rendered");
      const marker = document.createElement("span");
      marker.className = "td-mermaid-rendered-test";
      marker.textContent = "diagram rendered";
      node.after(marker);
    });
  }
};
"""


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


def meta_content(page, selector):
    locator = page.locator(selector).first
    if locator.count() == 0:
        return None
    return locator.get_attribute("content")


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


def install_404_routes(page):
    if not NORMAL_ROOT:
        return
    not_found = os.path.join(NORMAL_ROOT, "404.html")

    def fallback(route):
        route.fulfill(
            status=404,
            path=not_found,
            headers={"content-type": "text/html; charset=utf-8"},
        )

    page.route(NORMAL + "/legacy-post**", fallback)
    page.route(NORMAL + "/old-tags/**", fallback)


def check_article_page(page):
    page.set_viewport_size({"width": 1024, "height": 900})
    page.emulate_media(color_scheme="light")
    page.goto(NORMAL + "/posts/live/", wait_until="networkidle")

    article_text = page.inner_text("body")
    check("article shell renders for dated post", page.locator(".td-article").count() == 1)
    check("article metadata type", meta_content(page, 'meta[property="og:type"]') == "article")
    check("article metadata description", meta_content(page, 'meta[name="description"]') == "A published post that appears in the listing and the feed.")
    check("article metadata published time", meta_content(page, 'meta[property="article:published_time"]') == "2026-05-20T00:00:00Z")
    check("article generated title is primary h1", page.locator("h1").count() == 1 and page.locator(".td-article-title").inner_text() == "Live Post")
    check("article removes duplicate body h1", page.locator(".td-article-body h1").count() == 0)
    check("article body content remains", "Browser checked article" in article_text)
    check("article has readable date", page.locator(".td-article-date").inner_text() == "May 20, 2026")
    check("article has kicker", page.locator(".td-article-kicker").text_content() == "Release")
    check("article has dek", "A published post" in page.locator(".td-article-dek").inner_text())

    with page.expect_navigation(wait_until="networkidle"):
        click_center(
            page,
            page.locator(".td-article-actions").get_by_role("link", name="Permalink").first,
        )
    check("article permalink click stays on article", page.url.endswith("/posts/live/"), page.url)
    with page.expect_navigation(wait_until="networkidle"):
        click_center(
            page,
            page.locator(".td-article-actions").get_by_role("link", name="RSS").first,
        )
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
    embed = page.locator(".td-embed iframe").first
    embed_box = box(page, ".td-embed-frame")
    check("article embed iframe renders", embed.count() == 1)
    check(
        "article embed uses safe provider URL",
        embed.get_attribute("src") == "https://www.youtube-nocookie.com/embed/dQw4w9WgXcQ",
    )
    check(
        "article embed keeps responsive ratio",
        embed_box is not None and abs((embed_box["width"] / embed_box["height"]) - (16 / 9)) < 0.05,
        "" if embed_box is None else f"{embed_box['width']:.0f}x{embed_box['height']:.0f}",
    )
    page.wait_for_selector(".td-mermaid-source[data-td-mermaid-stub='rendered']")
    mermaid_source = page.locator(".td-mermaid-source").first
    check("article mermaid tile renders", page.locator(".td-mermaid-rendered-test").count() == 1)
    check("article mermaid source remains escaped", "<script" not in page.locator(".td-mermaid").inner_html())
    check("article mermaid keeps source text", "Write Markdown" in mermaid_source.inner_text())
    mermaid_config = page.evaluate("window.__tdMermaidConfig")
    page_theme = page.evaluate("document.documentElement.getAttribute('data-theme')")
    expected_mermaid_theme = "dark" if page_theme == "dark" else "default"
    check(
        "article mermaid runtime uses strict themed config",
        mermaid_config
        and mermaid_config["securityLevel"] == "strict"
        and mermaid_config["theme"] == expected_mermaid_theme,
        str(mermaid_config),
    )
    click_center(page, page.locator("[data-td-theme-toggle]").first)
    toggled_theme = page.evaluate("document.documentElement.getAttribute('data-theme')")
    toggled_mermaid_theme = "dark" if toggled_theme == "dark" else "default"
    page.wait_for_function(
        """(expected) => window.__tdMermaidConfig && window.__tdMermaidConfig.theme === expected""",
        arg=toggled_mermaid_theme,
    )
    check(
        "article mermaid rethemes after toggle",
        page.evaluate("window.__tdMermaidConfig && window.__tdMermaidConfig.theme") == toggled_mermaid_theme,
    )
    check("article chart renders static svg", page.locator(".td-chart .td-chart-svg").count() == 1)
    chart_text = page.locator(".td-chart").inner_text()
    check("article chart keeps labels and series", "Release metrics" in chart_text and "Downloads" in chart_text and "Jan" in chart_text)
    check("article chart emits no script", "<script" not in page.locator(".td-chart").inner_html())

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


def check_baseurl_subpath(page):
    page.set_viewport_size({"width": 896, "height": 512})
    page.emulate_media(color_scheme="light")
    page.goto(BASE + "/docs/", wait_until="networkidle")

    broken = page.eval_on_selector_all("img", "els => els.filter(e => e.naturalWidth === 0).length")
    check("baseURL subpath images load", broken == 0, f"{broken} broken")
    sources = page.eval_on_selector_all(
        "img",
        "els => els.map(e => e.getAttribute('src')).filter(Boolean)",
    )
    expected_sources = {
        BASE + "/docs/assets/hero.svg",
        BASE + "/docs/assets/hero-dark.svg",
        BASE + "/docs/assets/logo.svg",
    }
    check(
        "baseURL prefixes root-relative image sources",
        expected_sources.issubset(set(sources)),
        str(sources),
    )
    logo_href = page.get_by_role("link", name="Download logo").get_attribute("href")
    check("baseURL prefixes root-relative asset links", logo_href == BASE + "/docs/assets/logo.svg", str(logo_href))

    page.goto(BASE + "/docs/posts/", wait_until="networkidle")
    post_sources = page.eval_on_selector_all(
        ".td-post-card img",
        "els => els.map(e => e.getAttribute('src')).filter(Boolean)",
    )
    check(
        "baseURL prefixes post-listing thumbnails",
        BASE + "/docs/assets/hero.svg" in post_sources,
        str(post_sources),
    )
    post_hrefs = page.eval_on_selector_all(
        ".td-post-card .td-post-thumb",
        "els => els.map(e => e.getAttribute('href')).filter(Boolean)",
    )
    check(
        "baseURL keeps post-listing links under subpath",
        BASE + "/docs/posts/live/" in post_hrefs,
        str(post_hrefs),
    )


def run(page):
    install_404_routes(page)

    # --- Home: image, table, counter tile ---
    page.set_viewport_size({"width": 896, "height": 512})
    page.emulate_media(color_scheme="light")
    page.goto(NORMAL + "/", wait_until="networkidle")
    check("home title", page.title() == "Home", page.title())
    check("home metadata description", meta_content(page, 'meta[name="description"]') == "A fixture home page for generated site behavior.")
    check("home metadata open graph", meta_content(page, 'meta[property="og:type"]') == "website")
    check("home metadata twitter card", meta_content(page, 'meta[name="twitter:card"]') == "summary_large_image")
    check(
        "home canonical is absolute",
        page.locator('link[rel="canonical"]').get_attribute("href") == NORMAL + "/",
    )
    footer_credit = page.locator(".td-built").inner_text()
    check("footer uses TileDown brand", "Built with TileDown" in footer_credit, footer_credit)

    broken = page.eval_on_selector_all("img", "els => els.filter(e => e.naturalWidth === 0).length")
    check("all home images load", broken == 0, f"{broken} broken")
    light_hero = page.locator(".td-theme-image.td-hero .td-theme-image-light")
    dark_hero = page.locator(".td-theme-image.td-hero .td-theme-image-dark")
    check("light hero image visible by default", light_hero.is_visible() and not dark_hero.is_visible())
    check_hero_rhythm(page, "standard hero leaves readable title spacing")

    page.goto(NORMAL + "/hero/", wait_until="networkidle")
    check("hero front matter page title", page.title() == "Hero Fallback", page.title())
    fallback_hero = page.locator(".td-hero")
    check("hero front matter image renders", fallback_hero.is_visible())
    check("hero front matter image center is unobstructed", can_receive_center_click(fallback_hero))
    check(
        "hero front matter emits absolute metadata image",
        page.locator('meta[property="og:image"]').get_attribute("content") == NORMAL + "/assets/hero.svg",
    )
    fallback_box = box(page, ".td-hero")
    fallback_heading = box(page, "h1")
    check(
        "hero front matter spacing is readable",
        fallback_box is not None
        and fallback_heading is not None
        and fallback_heading["y"] - (fallback_box["y"] + fallback_box["height"]) >= 48,
        "" if fallback_box is None or fallback_heading is None else f"gap={fallback_heading['y'] - (fallback_box['y'] + fallback_box['height']):.0f}",
    )
    broken = page.eval_on_selector_all("img", "els => els.filter(e => e.naturalWidth === 0).length")
    check("hero front matter image loads", broken == 0, f"{broken} broken")

    page.set_viewport_size({"width": 390, "height": 844})
    page.goto(NORMAL + "/hero/", wait_until="networkidle")
    mobile_fallback_box = box(page, ".td-hero")
    mobile_fallback_heading = box(page, "h1")
    check(
        "hero front matter mobile image fits viewport",
        mobile_fallback_box is not None
        and mobile_fallback_box["x"] >= 0
        and mobile_fallback_box["x"] + mobile_fallback_box["width"] <= page.viewport_size["width"],
        "" if mobile_fallback_box is None else f"x={mobile_fallback_box['x']:.0f}, width={mobile_fallback_box['width']:.0f}",
    )
    check(
        "hero front matter mobile spacing is readable",
        mobile_fallback_box is not None
        and mobile_fallback_heading is not None
        and mobile_fallback_heading["y"] - (mobile_fallback_box["y"] + mobile_fallback_box["height"]) >= 48,
        "" if mobile_fallback_box is None or mobile_fallback_heading is None else f"gap={mobile_fallback_heading['y'] - (mobile_fallback_box['y'] + mobile_fallback_box['height']):.0f}",
    )

    page.set_viewport_size({"width": 896, "height": 512})
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
    check("home has no mermaid runtime", page.evaluate("'__tdMermaidRuntime' in window") is False)

    # --- baseURL subpath: root-relative generated URLs still load ---
    check_baseurl_subpath(page)
    page.goto(NORMAL + "/", wait_until="networkidle")

    # --- Dark/light toggle ---
    bg_before = page.evaluate("getComputedStyle(document.body).backgroundColor")
    page.click("[data-td-theme-toggle]")
    theme = page.evaluate("document.documentElement.getAttribute('data-theme')")
    bg_after = page.evaluate("getComputedStyle(document.body).backgroundColor")
    check("toggle sets data-theme", theme in ("dark", "light"), f"data-theme={theme}")
    check("toggle selects dark in light media", theme == "dark", f"data-theme={theme}")
    check("toggle changes background", bg_before != bg_after, f"{bg_before}->{bg_after}")
    check("dark hero image visible after toggle", theme == "dark" and dark_hero.is_visible() and not light_hero.is_visible())
    page.reload(wait_until="networkidle")
    check("toggle choice persists", page.evaluate("document.documentElement.getAttribute('data-theme')") == theme)
    click_center(page, page.get_by_role("link", name="Posts").first)
    page.wait_for_url("**/posts/")
    check("toggle choice persists after nav link", page.evaluate("document.documentElement.getAttribute('data-theme')") == theme)
    listing_light_thumb = page.locator(".td-post-card .td-theme-image-light").first
    listing_dark_thumb = page.locator(".td-post-card .td-theme-image-dark").first
    check("dark thumbnail image visible after navigation", listing_dark_thumb.is_visible() and not listing_light_thumb.is_visible())
    click_center(page, page.locator(".td-post-title").get_by_role("link", name="Live Post").first)
    page.wait_for_url("**/posts/live/")
    check("toggle choice persists on article", page.evaluate("document.documentElement.getAttribute('data-theme')") == theme)
    article_light_hero = page.locator(".td-article-media .td-theme-image-light").first
    article_dark_hero = page.locator(".td-article-media .td-theme-image-dark").first
    check("dark article image visible after navigation", article_dark_hero.is_visible() and not article_light_hero.is_visible())
    page.click("[data-td-theme-toggle]")
    check("article toggle can select light", page.evaluate("document.documentElement.getAttribute('data-theme')") == "light")
    page.go_back(wait_until="load")
    check("back navigation reapplies stored light theme", page.evaluate("document.documentElement.getAttribute('data-theme')") == "light")
    page.go_back(wait_until="load")
    check("back navigation keeps stored light theme on home", page.evaluate("document.documentElement.getAttribute('data-theme')") == "light")
    other_page = page.context.new_page()
    try:
        other_page.goto(NORMAL + "/", wait_until="networkidle")
        other_page.evaluate("localStorage.removeItem('td-theme')")
        page.wait_for_function("document.documentElement.getAttribute('data-theme') === null")
    finally:
        other_page.close()
    check(
        "storage removal clears explicit theme",
        page.evaluate("document.documentElement.hasAttribute('data-theme')") is False,
    )

    # --- Post listing: live present, draft absent ---
    page.goto(NORMAL + "/posts/", wait_until="networkidle")
    listing = page.inner_text("body")
    check("listing has cards", len(page.query_selector_all(".td-post-card")) >= 1)
    check("draft absent from listing", "Secret Draft" not in listing)
    check("live post in listing", "Live Post" in listing)
    check("redirect absent from listing", "Old Live Redirect" not in listing)
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

    # --- Migrated post slug outside postsDir ---
    page.goto(NORMAL + "/blog/migrated/", wait_until="networkidle")
    migrated_text = page.inner_text("body")
    check("migrated post canonical URL renders", "Migrated Post" in migrated_text)
    check("migrated post renders article shell", page.locator(".td-article").count() == 1)
    check(
        "migrated article generated title is primary h1",
        page.locator("h1").count() == 1
        and page.locator(".td-article-title").inner_text() == "Migrated Post",
    )
    check(
        "migrated article removes duplicate body h1",
        page.locator(".td-article-body h1").count() == 0,
    )
    check(
        "migrated article has readable date",
        page.locator(".td-article-date").inner_text() == "May 25, 2026",
    )
    migrated_permalink = page.locator(".td-article-actions").get_by_role(
        "link",
        name="Permalink",
    ).first
    check(
        "migrated article permalink uses canonical URL",
        migrated_permalink.get_attribute("href") == NORMAL + "/blog/migrated/",
    )
    check(
        "migrated article share link is tappable",
        can_receive_center_click(page.locator(".td-article-share a").first),
    )
    migrated_share_hrefs = page.eval_on_selector_all(
        ".td-article-share a",
        "els => els.map(e => e.getAttribute('href'))",
    )
    check(
        "migrated article share URLs use canonical URL",
        all("%2Fblog%2Fmigrated%2F" in href for href in migrated_share_hrefs),
        str(migrated_share_hrefs),
    )
    with page.expect_navigation(wait_until="networkidle"):
        click_center(page, migrated_permalink)
    check("migrated article permalink click stays canonical", page.url.endswith("/blog/migrated/"), page.url)
    migrated_source = page.evaluate("async () => (await fetch('/posts/migrated/', {method:'HEAD'})).status")
    check("migrated source folder path is gone", migrated_source == 404, f"status={migrated_source}")
    page.goto(NORMAL + "/posts/", wait_until="networkidle")
    migrated_listing = page.inner_text("body")
    check("migrated post appears in listing", "Migrated Post" in migrated_listing)
    migrated_card = page.locator(".td-post-card").get_by_role("link", name="Migrated Post").first
    check("migrated listing uses canonical URL", migrated_card.get_attribute("href") == NORMAL + "/blog/migrated/")
    page.goto(NORMAL + "/tags/migration/", wait_until="networkidle")
    check("migrated post appears on tag page", "Migrated Post" in page.inner_text("body"))

    # --- Redirect content ---
    redirect = page.evaluate("async () => (await fetch('/old-live/')).text()")
    check("redirect page has canonical target", 'rel="canonical" href="/posts/live/"' in redirect)
    check("redirect page has meta refresh", 'content="0; url=/posts/live/"' in redirect)
    check("redirect page skips normal template", "Old Live Redirect" not in redirect)
    legacy_tag_status = page.evaluate("async () => (await fetch('/tags/legacy/', {method:'HEAD'})).status")
    check("redirect-only tag page is absent", legacy_tag_status == 404, f"status={legacy_tag_status}")
    page.goto(NORMAL + "/old-live/", wait_until="domcontentloaded")
    page.wait_for_url("**/posts/live/", wait_until="networkidle")
    check("redirect page navigates in browser", page.url.endswith("/posts/live/"), page.url)
    check("redirect target renders article", page.locator(".td-article-title").inner_text() == "Live Post")

    # --- 404 page: custom source writes root 404.html, not /404/ ---
    page.goto(NORMAL + "/404.html", wait_until="networkidle")
    not_found_text = page.inner_text("body")
    check("custom 404 page renders", page.title() == "Missing in TileDown" and "content/404/index.md" in not_found_text)
    check("custom 404 uses site chrome", "Built with TileDown" in not_found_text)
    broken_404_images = page.eval_on_selector_all("img", "els => els.filter(e => e.naturalWidth === 0).length")
    check("custom 404 relative images load", broken_404_images == 0, f"{broken_404_images} broken")
    not_found_folder = page.evaluate("async () => (await fetch('/404/', {method:'HEAD'})).status")
    check("custom 404 source does not create /404/", not_found_folder == 404, f"status={not_found_folder}")

    page.goto(NORMAL + "/legacy-post?from=old#section", wait_until="domcontentloaded")
    page.wait_for_url(NORMAL + "/posts/live/?from=old#section")
    check("404 exact redirect preserves query and fragment", page.url.endswith("/posts/live/?from=old#section"), page.url)
    page.goto(NORMAL + "/old-tags/swift?from=old#section", wait_until="domcontentloaded")
    page.wait_for_url(NORMAL + "/tags/?from=old#section")
    check("404 prefix redirect preserves query and fragment", page.url.endswith("/tags/?from=old#section"), page.url)
    page.goto(NORMAL + "/old-tags/special/swift?from=old#section", wait_until="domcontentloaded")
    page.wait_for_url(NORMAL + "/posts/live/?from=old#section")
    check("404 most specific prefix wins", page.url.endswith("/posts/live/?from=old#section"), page.url)

    # --- Static passthrough: root files and remapped public assets ---
    cname = page.evaluate("async () => (await fetch('/CNAME')).text()")
    robots = page.evaluate("async () => (await fetch('/robots.txt')).text()")
    nojekyll_status = page.evaluate("async () => (await fetch('/.nojekyll', {method:'HEAD'})).status")
    security = page.evaluate("async () => (await fetch('/.well-known/security.txt')).text()")
    passthrough_asset = page.evaluate("async () => (await fetch('/images/passthrough.svg')).status")
    deployment_cname_source = page.evaluate("async () => (await fetch('/deployment/CNAME', {method:'HEAD'})).status")
    deployment_robots_source = page.evaluate("async () => (await fetch('/deployment/robots.txt', {method:'HEAD'})).status")
    private_source = page.evaluate("async () => (await fetch('/public/images/passthrough.svg')).status")
    private_hidden_source = page.evaluate("async () => (await fetch('/public/.well-known/security.txt', {method:'HEAD'})).status")
    check("static passthrough publishes root CNAME", cname.strip() == "tiledown.test", cname)
    check("static passthrough publishes robots", "Allow: /" in robots, robots)
    check("static passthrough publishes dotfile", nojekyll_status == 200, f"status={nojekyll_status}")
    check("static passthrough publishes well-known", "security@example.test" in security, security)
    check("static passthrough publishes remapped asset", passthrough_asset == 200, f"status={passthrough_asset}")
    check("static passthrough hides deployment CNAME source", deployment_cname_source == 404, f"status={deployment_cname_source}")
    check("static passthrough hides deployment robots source", deployment_robots_source == 404, f"status={deployment_robots_source}")
    check("static passthrough hides source path", private_source == 404, f"status={private_source}")
    check("static passthrough hides hidden source path", private_hidden_source == 404, f"status={private_hidden_source}")

    # --- Feed: live present, draft absent ---
    feed = page.evaluate("async () => (await fetch('/feed.xml')).text()")
    check("feed has live post", "Live Post" in feed)
    check("feed uses migrated canonical URL", f"<link>{NORMAL}/blog/migrated/</link>" in feed)
    check("feed includes rendered post body", "<content:encoded>" in feed and "Browser checked article" in feed)
    check("feed item URL is absolute", f"<link>{NORMAL}/posts/live/</link>" in feed)
    check(
        "feed includes absolute post links and images",
        f'href="{NORMAL}/about/"' in feed and f'src="{NORMAL}/assets/logo.svg"' in feed,
    )
    check("feed has typed post outside postsDir", "Typed Article" in feed)
    check("feed excludes forced page", "Forced Page" not in feed)
    check("feed excludes draft", "Secret Draft" not in feed)
    check("feed excludes redirect", "Old Live Redirect" not in feed)

    # --- Sitemap: published pages present, draft and redirects absent ---
    sitemap = page.evaluate("async () => (await fetch('/sitemap.xml')).text()")
    check("sitemap has absolute home", f"<loc>{NORMAL}/</loc>" in sitemap)
    check("sitemap has absolute live post", f"<loc>{NORMAL}/posts/live/</loc>" in sitemap)
    check("sitemap excludes draft", "/posts/secret/" not in sitemap)
    check("sitemap excludes redirect", "/legacy-live/" not in sitemap)


def main():
    with sync_playwright() as p:
        browser = p.chromium.launch()
        context = browser.new_context()
        page = context.new_page()
        page.route("https://www.youtube-nocookie.com/**", lambda route: route.fulfill(status=204, body=""))
        page.route("https://player.vimeo.com/**", lambda route: route.fulfill(status=204, body=""))
        page.route(
            "https://cdn.jsdelivr.net/npm/mermaid@10.9.3/**",
            lambda route: route.fulfill(status=200, content_type="text/javascript", body=MERMAID_STUB),
        )
        try:
            run(page)
        finally:
            context.close()
            browser.close()

    passed = sum(1 for _, ok, _ in results if ok)
    for name, ok, detail in results:
        print(f"{'PASS' if ok else 'FAIL'}  {name}" + (f"  [{detail}]" if detail else ""))
    print(f"\n{passed}/{len(results)} checks passed")
    sys.exit(0 if passed == len(results) else 1)


if __name__ == "__main__":
    main()

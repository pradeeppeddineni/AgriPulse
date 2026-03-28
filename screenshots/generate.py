#!/usr/bin/env python3
"""Generate 4 professional App Store screenshots for AgriPulse."""

from PIL import Image, ImageDraw, ImageFont
import os

# --- Constants ---
W, H = 1284, 2778
OUTPUT_DIR = os.path.dirname(os.path.abspath(__file__))

# Colors
BG = (10, 15, 26)
CARD_BG = (17, 24, 39)
CARD_BORDER = (31, 41, 55)
GREEN = (34, 197, 94)
WHITE = (248, 250, 252)
SECONDARY = (148, 163, 184)
TAB_INACTIVE = (100, 116, 139)
TAB_BG = (17, 24, 39)
RED = (239, 68, 68)
ORANGE = (249, 115, 22)
BLUE = (96, 165, 250)
PURPLE = (168, 85, 247)
DARK_RED = (127, 29, 29)
DARK_ORANGE = (124, 45, 18)
DARK_BLUE = (30, 58, 138)
DARK_PURPLE = (88, 28, 135)

# Fonts
def load_fonts():
    fonts = {}
    bold_path = "/System/Library/Fonts/Supplemental/Arial Bold.ttf"
    regular_path = "/System/Library/Fonts/Supplemental/Arial.ttf"
    for size in [26, 28, 30, 32, 34, 36, 38, 40, 44, 48, 52, 56, 60, 72]:
        fonts[f"bold_{size}"] = ImageFont.truetype(bold_path, size)
        fonts[f"regular_{size}"] = ImageFont.truetype(regular_path, size)
    return fonts

FONTS = load_fonts()


def rounded_rect(draw, xy, fill, radius=36, outline=None, outline_width=2):
    x0, y0, x1, y1 = xy
    r = min(radius, (x1 - x0) // 2, (y1 - y0) // 2)
    if fill:
        draw.rectangle([x0 + r, y0, x1 - r, y1], fill=fill)
        draw.rectangle([x0, y0 + r, x1, y1 - r], fill=fill)
        draw.pieslice([x0, y0, x0 + 2*r, y0 + 2*r], 180, 270, fill=fill)
        draw.pieslice([x1 - 2*r, y0, x1, y0 + 2*r], 270, 360, fill=fill)
        draw.pieslice([x0, y1 - 2*r, x0 + 2*r, y1], 90, 180, fill=fill)
        draw.pieslice([x1 - 2*r, y1 - 2*r, x1, y1], 0, 90, fill=fill)
    if outline:
        draw.arc([x0, y0, x0 + 2*r, y0 + 2*r], 180, 270, fill=outline, width=outline_width)
        draw.arc([x1 - 2*r, y0, x1, y0 + 2*r], 270, 360, fill=outline, width=outline_width)
        draw.arc([x0, y1 - 2*r, x0 + 2*r, y1], 90, 180, fill=outline, width=outline_width)
        draw.arc([x1 - 2*r, y1 - 2*r, x1, y1], 0, 90, fill=outline, width=outline_width)
        draw.line([x0 + r, y0, x1 - r, y0], fill=outline, width=outline_width)
        draw.line([x0 + r, y1, x1 - r, y1], fill=outline, width=outline_width)
        draw.line([x0, y0 + r, x0, y1 - r], fill=outline, width=outline_width)
        draw.line([x1, y0 + r, x1, y1 - r], fill=outline, width=outline_width)


def pill(draw, xy, text, bg_color, text_color, font_key="bold_28", padding_x=24, padding_y=10):
    font = FONTS[font_key]
    bbox = font.getbbox(text)
    tw, th = bbox[2] - bbox[0], bbox[3] - bbox[1]
    x, y = xy
    pw = tw + padding_x * 2
    ph = th + padding_y * 2
    rounded_rect(draw, (x, y, x + pw, y + ph), fill=bg_color, radius=ph // 2)
    draw.text((x + padding_x, y + padding_y - 2), text, fill=text_color, font=font)
    return pw, ph


def text_width(text, font_key):
    font = FONTS[font_key]
    bbox = font.getbbox(text)
    return bbox[2] - bbox[0]


def draw_status_bar(draw):
    y = 55
    draw.text((60, y), "9:41", fill=WHITE, font=FONTS["bold_40"])
    rx = W - 60
    bw, bh = 70, 32
    bx = rx - bw
    by = y + 6
    rounded_rect(draw, (bx, by, bx + bw, by + bh), fill=None, radius=8, outline=WHITE, outline_width=3)
    fill_w = int(bw * 0.75)
    rounded_rect(draw, (bx + 4, by + 4, bx + 4 + fill_w, by + bh - 4), fill=GREEN, radius=5)
    draw.rectangle([bx + bw + 2, by + 9, bx + bw + 7, by + bh - 9], fill=WHITE)
    sx = bx - 100
    for i in range(4):
        bar_h = 10 + i * 7
        bar_x = sx + i * 16
        bar_y = by + bh - bar_h
        draw.rectangle([bar_x, bar_y, bar_x + 10, by + bh], fill=WHITE)
    wx = sx - 60
    draw.ellipse([wx + 14, by + 14, wx + 22, by + 22], fill=WHITE)
    for size in [18, 30, 42]:
        arc_x = wx + 18 - size // 2
        arc_y = by + 18 - size // 2
        draw.arc([arc_x, arc_y, arc_x + size, arc_y + size], 225, 315, fill=WHITE, width=4)


def draw_tab_bar(draw, active_index=0):
    tab_y = H - 200
    draw.rectangle([0, tab_y, W, H], fill=TAB_BG)
    draw.line([0, tab_y, W, tab_y], fill=CARD_BORDER, width=2)
    tabs = ["News", "Equity", "Calendar", "Saved"]
    icons = ["news", "equity", "calendar", "saved"]
    tab_w = W // 4
    for i, (label, icon_type) in enumerate(zip(tabs, icons)):
        color = GREEN if i == active_index else TAB_INACTIVE
        cx = tab_w * i + tab_w // 2
        iy = tab_y + 35
        if icon_type == "news":
            draw.rectangle([cx - 22, iy, cx + 22, iy + 30], outline=color, width=3)
            draw.line([cx - 14, iy + 10, cx + 14, iy + 10], fill=color, width=3)
            draw.line([cx - 14, iy + 20, cx + 14, iy + 20], fill=color, width=3)
        elif icon_type == "equity":
            draw.line([cx - 22, iy + 30, cx - 8, iy + 12, cx + 8, iy + 22, cx + 22, iy], fill=color, width=4)
        elif icon_type == "calendar":
            draw.rectangle([cx - 20, iy + 4, cx + 20, iy + 30], outline=color, width=3)
            draw.line([cx - 20, iy + 14, cx + 20, iy + 14], fill=color, width=3)
            draw.line([cx - 10, iy, cx - 10, iy + 8], fill=color, width=3)
            draw.line([cx + 10, iy, cx + 10, iy + 8], fill=color, width=3)
        elif icon_type == "saved":
            pts = [(cx - 16, iy), (cx + 16, iy), (cx + 16, iy + 32), (cx, iy + 22), (cx - 16, iy + 32)]
            if i == active_index:
                draw.polygon(pts, fill=color)
            draw.polygon(pts, outline=color)
        draw.text((cx - text_width(label, "regular_32") // 2, iy + 42), label, fill=color, font=FONTS["regular_32"])
    indicator_w = 400
    indicator_h = 10
    ix = (W - indicator_w) // 2
    iy2 = H - 45
    rounded_rect(draw, (ix, iy2, ix + indicator_w, iy2 + indicator_h), fill=(60, 60, 70), radius=5)


def wrap_text(text, font_key, max_width):
    font = FONTS[font_key]
    words = text.split()
    lines = []
    current = ""
    for word in words:
        test = f"{current} {word}".strip()
        bbox = font.getbbox(test)
        if bbox[2] - bbox[0] <= max_width:
            current = test
        else:
            if current:
                lines.append(current)
            current = word
    if current:
        lines.append(current)
    return lines


def draw_news_card(draw, y, age_text, age_color, age_bg, region, region_color, region_bg,
                   commodity, title, snippet, source, card_width=None, x_offset=60):
    x = x_offset
    cw = card_width or (W - 120)
    card_pad = 36
    title_lines = wrap_text(title, "bold_38", cw - card_pad * 2)
    snippet_lines = wrap_text(snippet, "regular_32", cw - card_pad * 2)
    badges_h = 48
    title_h = len(title_lines) * 50
    snippet_h = len(snippet_lines) * 42
    card_h = card_pad + badges_h + 16 + title_h + 12 + snippet_h + 16 + 40 + card_pad
    rounded_rect(draw, (x, y, x + cw, y + card_h), fill=CARD_BG, radius=30, outline=CARD_BORDER, outline_width=2)
    cy = y + card_pad
    cx = x + card_pad
    pw, ph = pill(draw, (cx, cy), age_text, age_bg, age_color, "bold_26", 18, 8)
    bx = cx + pw + 14
    pw2, _ = pill(draw, (bx, cy), region, region_bg, region_color, "bold_26", 18, 8)
    bx2 = bx + pw2 + 14
    pill(draw, (bx2, cy), commodity, (30, 41, 59), (180, 200, 220), "bold_26", 18, 8)
    cy += badges_h + 16
    for line in title_lines:
        draw.text((cx, cy), line, fill=WHITE, font=FONTS["bold_38"])
        cy += 50
    cy += 4
    for line in snippet_lines:
        draw.text((cx, cy), line, fill=SECONDARY, font=FONTS["regular_32"])
        cy += 42
    cy += 12
    draw.text((cx, cy), source, fill=TAB_INACTIVE, font=FONTS["regular_30"])
    read_text = "Read  \u2192"
    rtw = text_width(read_text, "bold_30")
    draw.text((x + cw - card_pad - rtw, cy), read_text, fill=GREEN, font=FONTS["bold_30"])
    return y + card_h


# ============ SCREENSHOT 1: News Feed ============
def create_screenshot_news():
    img = Image.new("RGB", (W, H), BG)
    draw = ImageDraw.Draw(img)
    draw_status_bar(draw)
    y = 140
    pill(draw, (60, y), "\u25BC  Latest", (30, 41, 59), WHITE, "bold_34", 24, 14)
    y += 80
    draw.text((60, y), "Latest Updates", fill=WHITE, font=FONTS["bold_60"])
    y += 90
    draw.line([60, y, W - 60, y], fill=CARD_BORDER, width=2)
    y += 24
    cards = [
        {"age": "BREAKING  2h", "age_color": (255, 200, 200), "age_bg": DARK_RED,
         "region": "India", "region_color": (180, 255, 200), "region_bg": (22, 80, 40),
         "commodity": "Wheat",
         "title": "India wheat procurement hits record 28 million tonnes in Rabi 2026",
         "snippet": "Government agencies ramp up purchases across Punjab, Haryana and MP as bumper harvest exceeds projections...",
         "source": "Reuters Commodities"},
        {"age": "HOT  4h", "age_color": (255, 220, 180), "age_bg": DARK_ORANGE,
         "region": "Global", "region_color": (180, 200, 255), "region_bg": (30, 48, 108),
         "commodity": "Palm Oil",
         "title": "Malaysian palm oil futures surge 3.2% on Indonesia export curbs",
         "snippet": "Supply tightening fears push CPO benchmark above MYR 4,200 per tonne in early trading...",
         "source": "Bloomberg Markets"},
        {"age": "FRESH  8h", "age_color": (180, 255, 200), "age_bg": (22, 80, 40),
         "region": "India", "region_color": (180, 255, 200), "region_bg": (22, 80, 40),
         "commodity": "Sugar",
         "title": "Sugar mills in UP seek 12% hike in fair price amid rising input costs",
         "snippet": "Industry body ISMA writes to food ministry citing fertilizer and labour cost increases...",
         "source": "Economic Times"},
        {"age": "6h", "age_color": SECONDARY, "age_bg": (30, 41, 59),
         "region": "India", "region_color": (180, 255, 200), "region_bg": (22, 80, 40),
         "commodity": "Cotton",
         "title": "Cotton acreage in Gujarat up 15% as MSP rises to Rs 7,521/quintal",
         "snippet": "Farmers in Saurashtra and North Gujarat shift from groundnut to cotton on improved price signals...",
         "source": "Mint Markets"},
        {"age": "12h", "age_color": SECONDARY, "age_bg": (30, 41, 59),
         "region": "Global", "region_color": (180, 200, 255), "region_bg": (30, 48, 108),
         "commodity": "Soybean",
         "title": "CBOT soybean prices fall as Brazil harvest reaches 78% completion",
         "snippet": "Record Brazilian crop of 165 million tonnes weighs on global prices, pressuring Indian oilseed...",
         "source": "Agrimoney"},
    ]
    for card in cards:
        y = draw_news_card(draw, y, card["age"], card["age_color"], card["age_bg"],
                          card["region"], card["region_color"], card["region_bg"],
                          card["commodity"], card["title"], card["snippet"], card["source"])
        y += 20
    draw_tab_bar(draw, active_index=0)
    img.save(os.path.join(OUTPUT_DIR, "screenshot_news.png"), "PNG")
    print("Created screenshot_news.png")


# ============ SCREENSHOT 2: Equity ============
def create_screenshot_equity():
    img = Image.new("RGB", (W, H), BG)
    draw = ImageDraw.Draw(img)
    draw_status_bar(draw)
    y = 140
    ix = 60
    iy = y + 8
    draw.line([ix, iy + 40, ix + 18, iy + 20, ix + 30, iy + 30, ix + 48, iy], fill=GREEN, width=5)
    draw.text((130, y), "Equity Market", fill=WHITE, font=FONTS["bold_56"])
    y += 80
    draw.text((60, y), "Indian  \u00b7  Global  \u00b7  Crypto  \u00b7  Mutual Funds", fill=SECONDARY, font=FONTS["regular_34"])
    y += 70
    tab_labels = ["Indian Equity", "Global Equity", "Crypto", "Mutual Funds"]
    tx = 60
    for i, tab in enumerate(tab_labels):
        bg = GREEN if i == 0 else (30, 41, 59)
        tc = BG if i == 0 else SECONDARY
        pw, ph = pill(draw, (tx, y), tab, bg, tc, "bold_30", 28, 14)
        tx += pw + 16
    y += 72
    draw.line([60, y, W - 60, y], fill=CARD_BORDER, width=2)
    y += 24
    cards = [
        {"age": "BREAKING  1h", "age_color": (255, 200, 200), "age_bg": DARK_RED,
         "region": "India", "region_color": (180, 255, 200), "region_bg": (22, 80, 40),
         "commodity": "Sensex",
         "title": "Sensex surges 500 points as FII buying resumes after 3-week pause",
         "snippet": "Foreign investors pump Rs 4,200 crore into Indian markets, boosting banking and IT stocks sharply...",
         "source": "Moneycontrol"},
        {"age": "HOT  2h", "age_color": (255, 220, 180), "age_bg": DARK_ORANGE,
         "region": "India", "region_color": (180, 255, 200), "region_bg": (22, 80, 40),
         "commodity": "Nifty",
         "title": "Nifty hits all-time high at 24,800 amid broad-based rally",
         "snippet": "All 13 sectoral indices close in green as RBI's dovish stance fuels market optimism for rate cuts...",
         "source": "Economic Times"},
        {"age": "3h", "age_color": SECONDARY, "age_bg": (30, 41, 59),
         "region": "India", "region_color": (180, 255, 200), "region_bg": (22, 80, 40),
         "commodity": "Banking",
         "title": "Bank Nifty rallies 2.1% as credit growth picks up to 16.5% YoY",
         "snippet": "HDFC Bank, ICICI Bank and SBI lead gains as improving asset quality boosts investor confidence...",
         "source": "LiveMint"},
        {"age": "5h", "age_color": SECONDARY, "age_bg": (30, 41, 59),
         "region": "India", "region_color": (180, 255, 200), "region_bg": (22, 80, 40),
         "commodity": "Pharma",
         "title": "Pharma stocks surge as US FDA approves 12 ANDAs for Indian firms",
         "snippet": "Sun Pharma, Dr Reddy's and Cipla gain 3-5% on positive regulatory developments from Washington...",
         "source": "Business Standard"},
        {"age": "8h", "age_color": SECONDARY, "age_bg": (30, 41, 59),
         "region": "India", "region_color": (180, 255, 200), "region_bg": (22, 80, 40),
         "commodity": "Auto",
         "title": "Auto sector gains as March sales data shows 18% YoY growth",
         "snippet": "Maruti, Tata Motors and M&M report strong numbers driven by SUV demand and rural recovery...",
         "source": "CNBC-TV18"},
    ]
    for card in cards:
        y = draw_news_card(draw, y, card["age"], card["age_color"], card["age_bg"],
                          card["region"], card["region_color"], card["region_bg"],
                          card["commodity"], card["title"], card["snippet"], card["source"])
        y += 20
    draw_tab_bar(draw, active_index=1)
    img.save(os.path.join(OUTPUT_DIR, "screenshot_equity.png"), "PNG")
    print("Created screenshot_equity.png")


# ============ SCREENSHOT 3: Calendar ============
def create_screenshot_calendar():
    img = Image.new("RGB", (W, H), BG)
    draw = ImageDraw.Draw(img)
    draw_status_bar(draw)
    y = 140
    draw.text((60, y), "Commodity Calendar", fill=WHITE, font=FONTS["bold_60"])
    y += 100
    month_text = "March 2026"
    mtw = text_width(month_text, "bold_48")
    mcx = W // 2 - mtw // 2
    draw.text((mcx, y), month_text, fill=WHITE, font=FONTS["bold_48"])
    draw.text((80, y + 2), "\u25C0", fill=SECONDARY, font=FONTS["regular_44"])
    draw.text((W - 130, y + 2), "\u25B6", fill=SECONDARY, font=FONTS["regular_44"])
    y += 80
    cal_x = 60
    cal_w = W - 120
    cell_w = cal_w // 7
    cell_h = 100
    day_headers = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
    for i, d in enumerate(day_headers):
        dx = cal_x + i * cell_w + cell_w // 2 - text_width(d, "bold_32") // 2
        draw.text((dx, y), d, fill=TAB_INACTIVE, font=FONTS["bold_32"])
    y += 54
    draw.line([cal_x, y, cal_x + cal_w, y], fill=CARD_BORDER, width=2)
    y += 12
    event_days = {
        1: [GREEN], 3: [BLUE], 5: [GREEN, ORANGE], 7: [PURPLE], 9: [RED],
        10: [BLUE], 12: [GREEN], 14: [ORANGE], 15: [PURPLE, BLUE],
        17: [GREEN], 19: [RED], 20: [ORANGE], 22: [GREEN],
        24: [BLUE], 25: [PURPLE], 27: [GREEN, RED], 29: [ORANGE], 31: [BLUE],
    }
    day = 1
    for row in range(6):
        if day > 31:
            break
        for col in range(7):
            if day > 31:
                break
            cx = cal_x + col * cell_w + cell_w // 2
            cy = y + row * cell_h + cell_h // 2
            day_str = str(day)
            dtw = text_width(day_str, "regular_38")
            if day == 22:
                rounded_rect(draw, (cx - 36, cy - 30, cx + 36, cy + 30), fill=GREEN, radius=18)
                draw.text((cx - dtw // 2, cy - 20), day_str, fill=BG, font=FONTS["bold_38"])
            else:
                draw.text((cx - dtw // 2, cy - 20), day_str, fill=WHITE, font=FONTS["regular_38"])
            if day in event_days:
                dots = event_days[day]
                total_w = len(dots) * 12 + (len(dots) - 1) * 6
                dot_start_x = cx - total_w // 2
                for di, dot_color in enumerate(dots):
                    dx = dot_start_x + di * 18 + 6
                    dy = cy + 28
                    draw.ellipse([dx - 6, dy - 6, dx + 6, dy + 6], fill=dot_color)
            day += 1
    y += 6 * cell_h + 24
    categories = [("Harvest", GREEN), ("Report", BLUE), ("Policy", PURPLE), ("Trade", ORANGE), ("Advisory", RED)]
    px = 60
    for cat_name, cat_color in categories:
        dot_r = 10
        ctw = text_width(cat_name, "bold_30")
        pill_w = 20 + dot_r * 2 + 12 + ctw + 20
        pill_h = 52
        rounded_rect(draw, (px, y, px + pill_w, y + pill_h), fill=(30, 41, 59), radius=pill_h // 2)
        dot_cx = px + 26
        dot_cy = y + pill_h // 2
        draw.ellipse([dot_cx - dot_r, dot_cy - dot_r, dot_cx + dot_r, dot_cy + dot_r], fill=cat_color)
        draw.text((dot_cx + dot_r + 12, y + 11), cat_name, fill=WHITE, font=FONTS["bold_30"])
        px += pill_w + 14
    y += 80
    draw.line([60, y, W - 60, y], fill=CARD_BORDER, width=2)
    y += 24
    draw.text((60, y), "Upcoming Events", fill=WHITE, font=FONTS["bold_44"])
    y += 68
    events = [
        ("Rabi Wheat Harvesting begins across North India", "Harvest", GREEN, (22, 80, 40), "Mar 22, 2026"),
        ("USDA World Agricultural Supply & Demand Report", "Report", BLUE, DARK_BLUE, "Mar 24, 2026"),
        ("RBI Monetary Policy Committee Decision", "Policy", PURPLE, DARK_PURPLE, "Mar 25, 2026"),
        ("India-ASEAN Palm Oil Trade Review Meeting", "Trade", ORANGE, DARK_ORANGE, "Mar 27, 2026"),
    ]
    for evt_title, evt_cat, evt_color, evt_bg, evt_date in events:
        cw = W - 120
        title_lines = wrap_text(evt_title, "bold_36", cw - 100)
        card_h = 36 + 48 + 12 + len(title_lines) * 48 + 10 + 38 + 36
        rounded_rect(draw, (60, y, 60 + cw, y + card_h), fill=CARD_BG, radius=24, outline=CARD_BORDER, outline_width=2)
        # Left accent bar
        draw.rectangle([60, y + 24, 68, y + card_h - 24], fill=evt_color)
        ey = y + 36
        ex = 100
        pw_e, ph_e = pill(draw, (ex, ey), evt_cat, evt_bg, evt_color, "bold_28", 18, 8)
        ey += ph_e + 16
        for line in title_lines:
            draw.text((ex, ey), line, fill=WHITE, font=FONTS["bold_36"])
            ey += 48
        ey += 4
        draw.text((ex, ey), evt_date, fill=SECONDARY, font=FONTS["regular_32"])
        y += card_h + 16
    draw_tab_bar(draw, active_index=2)
    img.save(os.path.join(OUTPUT_DIR, "screenshot_calendar.png"), "PNG")
    print("Created screenshot_calendar.png")


# ============ SCREENSHOT 4: Saved ============
def create_screenshot_saved():
    img = Image.new("RGB", (W, H), BG)
    draw = ImageDraw.Draw(img)
    draw_status_bar(draw)
    y = 140
    draw.text((60, y), "Saved Articles", fill=WHITE, font=FONTS["bold_60"])
    y += 90
    draw.text((60, y), "12 articles saved", fill=SECONDARY, font=FONTS["regular_36"])
    y += 64
    search_h = 72
    rounded_rect(draw, (60, y, W - 60, y + search_h), fill=(30, 41, 59), radius=search_h // 2)
    sx = 100
    sy = y + search_h // 2
    draw.ellipse([sx - 14, sy - 14, sx + 14, sy + 14], outline=TAB_INACTIVE, width=3)
    draw.line([sx + 10, sy + 10, sx + 22, sy + 22], fill=TAB_INACTIVE, width=3)
    draw.text((sx + 36, y + 18), "Search saved articles...", fill=TAB_INACTIVE, font=FONTS["regular_34"])
    y += search_h + 30
    cards = [
        {"age": "Saved 2d ago", "age_color": SECONDARY, "age_bg": (30, 41, 59),
         "region": "India", "region_color": (180, 255, 200), "region_bg": (22, 80, 40),
         "commodity": "Wheat",
         "title": "India wheat procurement hits record 28 million tonnes in Rabi 2026",
         "snippet": "Government agencies ramp up purchases across Punjab, Haryana and MP as bumper harvest exceeds projections...",
         "source": "Reuters Commodities"},
        {"age": "Saved 3d ago", "age_color": SECONDARY, "age_bg": (30, 41, 59),
         "region": "Global", "region_color": (180, 200, 255), "region_bg": (30, 48, 108),
         "commodity": "Palm Oil",
         "title": "Malaysian palm oil futures surge 3.2% on Indonesia export curbs",
         "snippet": "Supply tightening fears push CPO benchmark above MYR 4,200 per tonne in early trading...",
         "source": "Bloomberg Markets"},
        {"age": "Saved 5d ago", "age_color": SECONDARY, "age_bg": (30, 41, 59),
         "region": "India", "region_color": (180, 255, 200), "region_bg": (22, 80, 40),
         "commodity": "Cotton",
         "title": "Cotton acreage in Gujarat up 15% as MSP rises to Rs 7,521/quintal",
         "snippet": "Farmers in Saurashtra and North Gujarat shift from groundnut to cotton on improved price signals...",
         "source": "Mint Markets"},
        {"age": "Saved 1w ago", "age_color": SECONDARY, "age_bg": (30, 41, 59),
         "region": "India", "region_color": (180, 255, 200), "region_bg": (22, 80, 40),
         "commodity": "Rice",
         "title": "India lifts ban on non-basmati white rice exports after record kharif output",
         "snippet": "Commerce ministry removes restrictions as buffer stocks reach comfortable 42 million tonnes...",
         "source": "Hindu BusinessLine"},
    ]
    for i, card in enumerate(cards):
        card_y_start = y
        y = draw_news_card(draw, y, card["age"], card["age_color"], card["age_bg"],
                          card["region"], card["region_color"], card["region_bg"],
                          card["commodity"], card["title"], card["snippet"], card["source"])
        # Filled bookmark icon on top-right
        bm_x = W - 60 - 36 - 30
        bm_y = card_y_start + 30
        bm_pts = [(bm_x, bm_y), (bm_x + 36, bm_y), (bm_x + 36, bm_y + 48),
                   (bm_x + 18, bm_y + 36), (bm_x, bm_y + 48)]
        draw.polygon(bm_pts, fill=GREEN)
        y += 20
    y += 10
    btn_w = W - 120
    btn_h = 80
    rounded_rect(draw, (60, y, 60 + btn_w, y + btn_h), fill=GREEN, radius=btn_h // 2)
    btn_text = "Share as PDF"
    btw = text_width(btn_text, "bold_38")
    # Export icon
    arrow_x = W // 2 - btw // 2 - 50
    arrow_cy = y + btn_h // 2
    draw.line([arrow_x, arrow_cy + 8, arrow_x, arrow_cy - 12], fill=BG, width=4)
    draw.polygon([(arrow_x - 10, arrow_cy - 2), (arrow_x, arrow_cy - 14), (arrow_x + 10, arrow_cy - 2)], fill=BG)
    draw.rectangle([arrow_x - 12, arrow_cy + 4, arrow_x + 12, arrow_cy + 14], outline=BG, width=3)
    draw.text((W // 2 - btw // 2, y + 18), btn_text, fill=BG, font=FONTS["bold_38"])
    draw_tab_bar(draw, active_index=3)
    img.save(os.path.join(OUTPUT_DIR, "screenshot_saved.png"), "PNG")
    print("Created screenshot_saved.png")


if __name__ == "__main__":
    create_screenshot_news()
    create_screenshot_equity()
    create_screenshot_calendar()
    create_screenshot_saved()
    print(f"\nAll screenshots saved to: {OUTPUT_DIR}")

#!/usr/bin/env python3
"""Bakes data/world_map.json from the Natural Earth 1:50m admin-0 countries
GeoJSON (public domain, https://www.naturalearthdata.com).

Usage: bake_world_map.py <countries.geojson> <output.json>

Map mode has two kinds of screen, both 1920 x 1080 pixels, so the game never
needs a camera zoom:
  * the world screen: the whole world, equirectangular, one colour per continent
  * one continent screen per continent: every country of that continent,
    projected with its own cos(latitude) squeeze so shapes look right

Coordinates come out already projected into those screens, simplified so each
outline is a simple polygon (Godot can't fill a self-crossing one), and rounded
to a tenth of a pixel. The output is committed, so builds never need the network.
"""
import json
import math
import sys

SCREEN_WIDTH, SCREEN_HEIGHT = 1920.0, 1080.0
COLOUR_COUNT = 6
MARGIN = 0.96

WORLD_PIXELS_PER_DEGREE = SCREEN_WIDTH / 360.0
WORLD_TOP_LATITUDE, WORLD_BOTTOM_LATITUDE = 85.0, -90.0
WORLD_OFFSET_Y = (SCREEN_HEIGHT - (WORLD_TOP_LATITUDE - WORLD_BOTTOM_LATITUDE) * WORLD_PIXELS_PER_DEGREE) / 2.0

WORLD_TOLERANCE, VIEW_TOLERANCE, LAND_TOLERANCE = 0.6, 0.9, 1.4
# Small islands are dropped so nothing is too small to see (the largest piece always stays).
WORLD_MINIMUM_PIECE_AREA, VIEW_MINIMUM_PIECE_AREA, LAND_MINIMUM_PIECE_AREA = 10.0, 60.0, 150.0
# A country at least this many pixels across (both ways) on some screen can be asked for in a task.
# The pointer's tip is a point and the magnet pulls it in, so this can be small.
PLAYABLE_PIXELS = 40.0

# id, name, colour (index into the rainbow, 6 = cyan), frame (lon0, lon1, lat0, lat1) or None, world label (lon, lat)
CONTINENTS = [
    ("europe", "Europe", 5, (-25, 45, 34, 72), (16, 53)),
    ("asia", "Asia", 1, (25, 180, -11, 78), (95, 50)),
    ("africa", "Africa", 2, (-20, 55, -37, 38), (20, 6)),
    ("north_america", "North America", 0, (-170, -30, 5, 83), (-100, 46)),
    ("south_america", "South America", 3, (-85, -33, -57, 14), (-60, -14)),
    ("oceania", "Oceania", 4, (110, 205, -48, 20), (135, -25)),
    ("antarctica", "Antarctica", 6, None, (0, -80)),
]
NATURAL_EARTH_CONTINENT = {
    "Europe": "europe", "Asia": "asia", "Africa": "africa", "North America": "north_america",
    "South America": "south_america", "Oceania": "oceania", "Antarctica": "antarctica",
}
# Countries that straddle two continents show on both screens, and a pick on either counts.
ALSO_IN = {"Russia": ["asia"], "Turkey": ["europe"], "Egypt": ["asia"]}
PICKABLE_TYPES = {"Sovereign country", "Country", "Sovereignty"}
# Kept as plain land: parts of other countries, or not for a child's quiz.
NEVER_PICKABLE = {"Åland", "N. Cyprus", "Antarctica"}
ALSO_PICKABLE = {"Israel"}
DISPLAY_NAMES = {
    "United States of America": "USA", "Dem. Rep. Congo": "DR Congo", "Central African Rep.": "Central African Republic",
    "Eq. Guinea": "Equatorial Guinea", "Dominican Rep.": "Dominican Republic", "Bosnia and Herz.": "Bosnia and Herzegovina",
    "Antigua and Barb.": "Antigua and Barbuda", "Marshall Is.": "Marshall Islands", "Solomon Is.": "Solomon Islands",
    "S. Sudan": "South Sudan", "eSwatini": "Eswatini", "St. Vin. and Gren.": "St Vincent and the Grenadines",
    "St. Kitts and Nevis": "St Kitts and Nevis", "Cabo Verde": "Cape Verde",
}

# Overseas pieces that would make a country's shape confusing on a child's map.
# id -> predicate on a piece's (min_longitude, max_longitude, min_latitude, max_latitude)
EXCLUDED_PIECES = {
    "france": lambda lon_min, lon_max, lat_min, lat_max: lon_max < -20 or lon_min > 20 or lat_max < 35,
    "usa": lambda lon_min, lon_max, lat_min, lat_max: lat_max < 30 and lon_min < -150,
    "chile": lambda lon_min, lon_max, lat_min, lat_max: lon_min < -100,
    "norway": lambda lon_min, lon_max, lat_min, lat_max: lat_min > 74,
    "spain": lambda lon_min, lon_max, lat_min, lat_max: lon_max < -10,
    "portugal": lambda lon_min, lon_max, lat_min, lat_max: lon_max < -10,
    "united_kingdom": lambda lon_min, lon_max, lat_min, lat_max: lon_max < -20,
    "netherlands": lambda lon_min, lon_max, lat_min, lat_max: lon_max < -20,
    "denmark": lambda lon_min, lon_max, lat_min, lat_max: lon_max < -20,
    "ecuador": lambda lon_min, lon_max, lat_min, lat_max: lon_max < -85,
}


def slug(text):
    cleaned = "".join(character if character.isalnum() else " " for character in text.lower())
    folded = cleaned.replace("å", "a").replace("ç", "c").replace("é", "e").replace("ô", "o").replace("ã", "a")
    return "_".join(folded.split())


# ---------------------------------------------------------------- projections
class WorldProjection:
    def point(self, longitude, latitude):
        return ((longitude + 180.0) * WORLD_PIXELS_PER_DEGREE,
                (WORLD_TOP_LATITUDE - latitude) * WORLD_PIXELS_PER_DEGREE + WORLD_OFFSET_Y)


class ContinentProjection:
    """Equirectangular with the longitude squeezed by cos(middle latitude), fitted to the screen."""
    def __init__(self, frame):
        lon0, lon1, lat0, lat1 = frame
        # A frame reaching past 180 degrees wraps round the antimeridian (Fiji, Tonga, Samoa)
        self.wraps = lon1 > 180
        self.middle_longitude, self.middle_latitude = (lon0 + lon1) / 2.0, (lat0 + lat1) / 2.0
        self.squeeze = math.cos(math.radians(self.middle_latitude))
        self.pixels_per_degree = MARGIN * min(SCREEN_WIDTH / ((lon1 - lon0) * self.squeeze), SCREEN_HEIGHT / (lat1 - lat0))

    def point(self, longitude, latitude):
        if self.wraps and longitude < 0:
            longitude += 360.0
        return (SCREEN_WIDTH / 2.0 + (longitude - self.middle_longitude) * self.squeeze * self.pixels_per_degree,
                SCREEN_HEIGHT / 2.0 - (latitude - self.middle_latitude) * self.pixels_per_degree)


# ---------------------------------------------------------------- geometry
def point_line_distance(point, start, end):
    dx, dy = end[0] - start[0], end[1] - start[1]
    length_squared = dx * dx + dy * dy
    if length_squared == 0.0:
        return math.hypot(point[0] - start[0], point[1] - start[1])
    t = max(0.0, min(1.0, ((point[0] - start[0]) * dx + (point[1] - start[1]) * dy) / length_squared))
    return math.hypot(point[0] - (start[0] + t * dx), point[1] - (start[1] + t * dy))


def douglas_peucker(points, tolerance):
    """Iterative, so a long coastline can't overflow the recursion limit."""
    if len(points) < 3:
        return points
    keep = [False] * len(points)
    keep[0] = keep[-1] = True
    pending = [(0, len(points) - 1)]
    while pending:
        first, last = pending.pop()
        farthest, farthest_index = 0.0, -1
        for index in range(first + 1, last):
            distance = point_line_distance(points[index], points[first], points[last])
            if distance > farthest:
                farthest, farthest_index = distance, index
        if farthest > tolerance:
            keep[farthest_index] = True
            pending.append((first, farthest_index))
            pending.append((farthest_index, last))
    return [point for point, kept in zip(points, keep) if kept]


def signed_area(points):
    total = 0.0
    for index, point in enumerate(points):
        following = points[(index + 1) % len(points)]
        total += point[0] * following[1] - following[0] * point[1]
    return total / 2.0


def snapped_points(points):
    """Rounded to a tenth of a pixel, repeats dropped, and any pinch (the
    outline visiting the same spot twice) cut out, since a pinched outline
    can't be filled."""
    result = []
    for x, y in points:
        point = (round(x, 1), round(y, 1))
        if not result or point != result[-1]:
            result.append(point)
    while len(result) > 1 and result[0] == result[-1]:
        result.pop()
    return without_pinches(result)


def without_pinches(points):
    while True:
        first_seen = {}
        pinch = None
        for index, point in enumerate(points):
            if point in first_seen:
                pinch = (first_seen[point], index)
                break
            first_seen[point] = index
        if pinch is None:
            return points
        start, stop = pinch
        inner_loop = points[start:stop]
        outer_loop = points[:start] + points[stop:]
        # Keep whichever loop encloses more; the other is a tiny spit or pond.
        points = inner_loop if len(inner_loop) >= 3 and abs(signed_area(inner_loop)) > abs(signed_area(outer_loop)) else outer_loop


def turn(a, b, c):
    return (b[0] - a[0]) * (c[1] - a[1]) - (b[1] - a[1]) * (c[0] - a[0])


def segments_cross(a, b, c, d):
    """True if segment ab properly crosses segment cd, or lies along it."""
    if max(a[0], b[0]) < min(c[0], d[0]) or max(c[0], d[0]) < min(a[0], b[0]):
        return False
    if max(a[1], b[1]) < min(c[1], d[1]) or max(c[1], d[1]) < min(a[1], b[1]):
        return False
    first, second = turn(a, b, c), turn(a, b, d)
    third, fourth = turn(c, d, a), turn(c, d, b)
    if first == 0 and second == 0:
        along_x = min(max(a[0], b[0]), max(c[0], d[0])) - max(min(a[0], b[0]), min(c[0], d[0]))
        along_y = min(max(a[1], b[1]), max(c[1], d[1])) - max(min(a[1], b[1]), min(c[1], d[1]))
        return along_x > 0 or along_y > 0
    return first * second < 0 and third * fourth < 0


def is_simple(points):
    """No edge crosses or overlaps any non-neighbouring edge."""
    count = len(points)
    for first in range(count):
        a, b = points[first], points[(first + 1) % count]
        for second in range(first + 2, count):
            if first == 0 and second == count - 1:
                continue
            if segments_cross(a, b, points[second], points[(second + 1) % count]):
                return False
    return True


def simple_simplification(points, tolerance):
    """Simplifies and rounds, easing off the tolerance until the outline no
    longer crosses itself."""
    attempt = tolerance
    while True:
        candidate = snapped_points(douglas_peucker(points, attempt))
        if len(candidate) < 3 or is_simple(candidate):
            return candidate
        if attempt < 0.05:
            print("warning: could not make a simple outline of %d points" % len(points), file=sys.stderr)
            return candidate
        attempt *= 0.6


def bounds_of(points):
    xs = [point[0] for point in points]
    ys = [point[1] for point in points]
    return (min(xs), min(ys), max(xs), max(ys))


def contains(points, probe):
    inside = False
    count = len(points)
    for index in range(count):
        a, b = points[index], points[(index + 1) % count]
        if (a[1] > probe[1]) != (b[1] > probe[1]):
            crossing_x = a[0] + (probe[1] - a[1]) * (b[0] - a[0]) / (b[1] - a[1])
            if probe[0] < crossing_x:
                inside = not inside
    return inside


def label_point(points, screen_margin=40.0, steps=22):
    """Roughly the pole of inaccessibility: the grid point deepest inside, and on screen."""
    x0, y0, x1, y1 = bounds_of(points)
    x0, y0 = max(x0, screen_margin), max(y0, screen_margin)
    x1, y1 = min(x1, SCREEN_WIDTH - screen_margin), min(y1, SCREEN_HEIGHT - screen_margin)
    if x0 >= x1 or y0 >= y1:
        x0, y0, x1, y1 = bounds_of(points)
    edge_step = max(1, len(points) // 100)
    edges = [(points[index], points[(index + 1) % len(points)]) for index in range(0, len(points), edge_step)]
    best, best_depth = None, -1.0
    for column in range(steps + 1):
        for row in range(steps + 1):
            probe = (x0 + (x1 - x0) * column / steps, y0 + (y1 - y0) * row / steps)
            if contains(points, probe):
                depth = min(point_line_distance(probe, start, end) for start, end in edges)
                if depth > best_depth:
                    best, best_depth = probe, depth
    if best is None:
        # Too small for the grid to land inside: the middle of its bounds will do
        bx0, by0, bx1, by1 = bounds_of(points)
        best = ((bx0 + bx1) / 2.0, (by0 + by1) / 2.0)
    return best


# ---------------------------------------------------------------- features
def feature_rings(feature, country_id):
    geometry = feature["geometry"]
    polygons = [geometry["coordinates"]] if geometry["type"] == "Polygon" else geometry["coordinates"]
    rings = []
    excluded = EXCLUDED_PIECES.get(country_id)
    for polygon in polygons:
        ring = polygon[0]
        longitudes, latitudes = [c[0] for c in ring], [c[1] for c in ring]
        if excluded and excluded(min(longitudes), max(longitudes), min(latitudes), max(latitudes)):
            continue
        rings.append(ring)
    return rings


def projected_pieces(rings, projection, tolerance, minimum_area, only_on_screen, marker_half=0.0):
    """Simplified pieces in screen pixels. With only_on_screen, pieces entirely
    off the screen are dropped; the largest piece always stays if it's on screen."""
    pieces = []
    on_screen_centres = []
    for ring in rings:
        raw = [projection.point(longitude, latitude) for longitude, latitude in ring]
        if raw[0] == raw[-1]:
            raw = raw[:-1]
        x0, y0, x1, y1 = bounds_of(raw)
        if only_on_screen and (x1 < -150 or x0 > SCREEN_WIDTH + 150 or y1 < -150 or y0 > SCREEN_HEIGHT + 150):
            continue
        on_screen_centres.append(((x0 + x1) / 2.0, (y0 + y1) / 2.0, (x1 - x0) * (y1 - y0)))
        points = simple_simplification(raw, tolerance)
        if len(points) >= 3:
            pieces.append((abs(signed_area(points)), points))
    marker_area = 2 * marker_half * marker_half
    if on_screen_centres and marker_half > 0.0 and (not pieces or max(area for area, _ in pieces) < marker_area):
        # A micro-state would vanish when simplified: give it a small diamond so it can still be found
        centre_x, centre_y, _ = max(on_screen_centres, key=lambda candidate: candidate[2])
        half = marker_half
        pieces = [(marker_area, [(round(centre_x, 1), round(centre_y - half, 1)), (round(centre_x + half, 1), round(centre_y, 1)),
                                         (round(centre_x, 1), round(centre_y + half, 1)), (round(centre_x - half, 1), round(centre_y, 1))])]
    if not pieces:
        return []
    biggest = max(area for area, _ in pieces)
    return [points for area, points in pieces if area >= minimum_area or area == biggest]


def rounded(points):
    return [[round(x, 1), round(y, 1)] for x, y in points]


def pixel_span(pieces):
    biggest = max(pieces, key=lambda piece: abs(signed_area(piece)))
    x0, y0, x1, y1 = bounds_of(biggest)
    return min(x1 - x0, y1 - y0)


def share_a_border_map(countries):
    vertex_owners = {}
    for index, country in enumerate(countries):
        for ring in country["rings"]:
            for longitude, latitude in ring:
                vertex_owners.setdefault((round(longitude, 2), round(latitude, 2)), set()).add(index)
    neighbours = {index: set() for index in range(len(countries))}
    for owners in vertex_owners.values():
        for owner in owners:
            neighbours[owner] |= owners - {owner}
    return neighbours


def main():
    source_path, output_path = sys.argv[1], sys.argv[2]
    with open(source_path, encoding="utf-8") as source:
        features = json.load(source)["features"]

    world = WorldProjection()
    continent_ids = [continent[0] for continent in CONTINENTS]
    projections = {continent[0]: ContinentProjection(continent[3]) for continent in CONTINENTS if continent[3]}

    countries, plain_features = [], []
    for feature in features:
        properties = feature["properties"]
        if properties["CONTINENT"].startswith("Seven seas"):
            continue
        name = properties["NAME"]
        is_pickable = (properties["TYPE"] in PICKABLE_TYPES or name in ALSO_PICKABLE) and name not in NEVER_PICKABLE
        display_name = DISPLAY_NAMES.get(name, name)
        country_id = slug(display_name)
        rings = feature_rings(feature, country_id)
        if not rings:
            continue
        record = {"id": country_id, "name": display_name, "natural_earth_name": name, "rings": rings,
                  "home": NATURAL_EARTH_CONTINENT[properties["CONTINENT"]], "type": properties["TYPE"]}
        if is_pickable:
            record["continents"] = [record["home"]] + ALSO_IN.get(name, [])
            countries.append(record)
        else:
            plain_features.append(record)
    antarctica = next(feature for feature in features if feature["properties"]["NAME"] == "Antarctica")
    countries.append({"id": "antarctica", "name": "Antarctica", "natural_earth_name": "Antarctica", "rings": feature_rings(antarctica, "antarctica"),
                      "home": "antarctica", "type": "Indeterminate", "continents": ["antarctica"]})

    out_countries = []
    for country in countries:
        world_pieces = projected_pieces(country["rings"], world, WORLD_TOLERANCE, WORLD_MINIMUM_PIECE_AREA, False, marker_half=3.0)
        biggest = max(world_pieces, key=lambda piece: abs(signed_area(piece)))
        entry = {"id": country["id"], "name": country["name"], "home": country["home"], "continents": country["continents"],
                 "world": {"label": rounded([label_point(biggest)])[0], "polygons": [rounded(piece) for piece in world_pieces]},
                 "views": {}}
        spans = [pixel_span(world_pieces) * 0.0]
        for continent_id in country["continents"]:
            if continent_id not in projections:
                continue
            pieces = projected_pieces(country["rings"], projections[continent_id], VIEW_TOLERANCE, VIEW_MINIMUM_PIECE_AREA, True, marker_half=7.0)
            if not pieces:
                continue
            main_piece = max(pieces, key=lambda piece: abs(signed_area(piece)))
            entry["views"][continent_id] = {"label": rounded([label_point(main_piece)])[0], "polygons": [rounded(piece) for piece in pieces]}
            spans.append(pixel_span(pieces))
        entry["playable"] = country["id"] == "antarctica" or max(spans) >= PLAYABLE_PIXELS
        entry["widest_view_pixels"] = round(max(spans), 1)
        out_countries.append(entry)

    # Neighbours and colours come from the real borders (shared vertices), over pickable countries
    neighbours = share_a_border_map(countries)
    colour_of = {}
    for index in sorted(neighbours, key=lambda candidate: -len(neighbours[candidate])):
        taken = {colour_of[other] for other in neighbours[index] if other in colour_of}
        used = list(colour_of.values())
        free = [colour for colour in range(COLOUR_COUNT) if colour not in taken]
        colour_of[index] = min(free or [0], key=lambda colour: used.count(colour))
    for index, entry in enumerate(out_countries):
        entry["colour"] = colour_of[index]
        entry["neighbours"] = sorted(countries[other]["id"] for other in neighbours[index])

    # Plain land: everything that isn't a country on that screen
    world_land = []
    for feature in plain_features:
        for piece in projected_pieces(feature["rings"], world, LAND_TOLERANCE, WORLD_MINIMUM_PIECE_AREA * 3, False):
            world_land.append(rounded(piece))
    continents = []
    for continent_id, name, colour, frame, world_label in CONTINENTS:
        entry = {"id": continent_id, "name": name, "colour": colour, "zoomable": frame is not None,
                 "label": rounded([world.point(*world_label)])[0],
                 "countries": [c["id"] for c in out_countries if continent_id in c["continents"]], "land": []}
        if frame:
            in_view = {c["id"] for c in out_countries if continent_id in c["views"]}
            others = [c for c in countries if c["id"] not in in_view] + plain_features
            for other in others:
                for piece in projected_pieces(other["rings"], projections[continent_id], LAND_TOLERANCE, LAND_MINIMUM_PIECE_AREA, True):
                    entry["land"].append(rounded(piece))
        continents.append(entry)

    result = {"screen": [int(SCREEN_WIDTH), int(SCREEN_HEIGHT)], "continents": continents, "countries": out_countries,
              "world_land": world_land, "world_split": {"russia": round(world.point(60.0, 0.0)[0], 1)}}
    with open(output_path, "w", encoding="utf-8") as output:
        json.dump(result, output, separators=(",", ":"), ensure_ascii=False)
    playable = sum(1 for c in out_countries if c["playable"])
    print(f"{len(out_countries)} countries ({playable} playable), {len(world_land)} world land pieces")
    for continent in continents:
        members = [c for c in out_countries if continent["id"] in c["continents"]]
        print(f"  {continent['name']}: {len(members)} countries, {sum(1 for c in members if c['playable'])} playable, {len(continent['land'])} land pieces")


if __name__ == "__main__":
    main()

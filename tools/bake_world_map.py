#!/usr/bin/env python3
"""Bakes data/world_map.json from the Natural Earth 1:50m admin-0 countries
GeoJSON (public domain, https://www.naturalearthdata.com).

Usage: bake_world_map.py <countries.geojson> <output.json>

The game never needs the network: the output is committed. Coordinates come
out already projected into map pixels (equirectangular, y down), simplified,
and rounded to whole pixels.
"""
import json
import math
import sys

MAP_WIDTH = 4800.0
LONGITUDE_RANGE = (-180.0, 180.0)
LATITUDE_RANGE = (-90.0, 85.0)
PIXELS_PER_DEGREE = MAP_WIDTH / (LONGITUDE_RANGE[1] - LONGITUDE_RANGE[0])
MAP_HEIGHT = (LATITUDE_RANGE[1] - LATITUDE_RANGE[0]) * PIXELS_PER_DEGREE

PICKABLE_TOLERANCE_PIXELS = 1.2
PLAIN_LAND_TOLERANCE_PIXELS = 3.0
# Small islands are dropped so nothing on the map is too small to see or land on.
MINIMUM_PICKABLE_ISLAND_PIXELS_SQUARED = 900.0
MINIMUM_LAND_ISLAND_PIXELS_SQUARED = 2500.0
COLOUR_COUNT = 6

# Natural Earth NAME -> (id, name shown to the child). Order is the order in the file.
COUNTRIES = [
    ("United Kingdom", "united_kingdom", "United Kingdom"),
    ("Ireland", "ireland", "Ireland"),
    ("France", "france", "France"),
    ("Spain", "spain", "Spain"),
    ("Portugal", "portugal", "Portugal"),
    ("Italy", "italy", "Italy"),
    ("Germany", "germany", "Germany"),
    ("Norway", "norway", "Norway"),
    ("Sweden", "sweden", "Sweden"),
    ("Finland", "finland", "Finland"),
    ("Iceland", "iceland", "Iceland"),
    ("Greece", "greece", "Greece"),
    ("Turkey", "turkey", "Turkey"),
    ("Russia", "russia", "Russia"),
    ("Egypt", "egypt", "Egypt"),
    ("Morocco", "morocco", "Morocco"),
    ("Nigeria", "nigeria", "Nigeria"),
    ("Kenya", "kenya", "Kenya"),
    ("South Africa", "south_africa", "South Africa"),
    ("Madagascar", "madagascar", "Madagascar"),
    ("Saudi Arabia", "saudi_arabia", "Saudi Arabia"),
    ("India", "india", "India"),
    ("China", "china", "China"),
    ("Mongolia", "mongolia", "Mongolia"),
    ("Japan", "japan", "Japan"),
    ("Thailand", "thailand", "Thailand"),
    ("Indonesia", "indonesia", "Indonesia"),
    ("Australia", "australia", "Australia"),
    ("New Zealand", "new_zealand", "New Zealand"),
    ("Canada", "canada", "Canada"),
    ("United States of America", "usa", "USA"),
    ("Mexico", "mexico", "Mexico"),
    ("Brazil", "brazil", "Brazil"),
    ("Argentina", "argentina", "Argentina"),
    ("Peru", "peru", "Peru"),
    ("Chile", "chile", "Chile"),
    ("Colombia", "colombia", "Colombia"),
    ("Antarctica", "antarctica", "Antarctica"),
]

# Overseas pieces that would make a country's shape confusing on a child's map.
# id -> predicate on a polygon's (min_longitude, max_longitude, min_latitude, max_latitude)
EXCLUDED_PIECES = {
    "france": lambda lon_min, lon_max, lat_min, lat_max: lon_max < -20 or lon_min > 20 or lat_max < 35,
    "usa": lambda lon_min, lon_max, lat_min, lat_max: lat_max < 30 and lon_min < -150,
    "chile": lambda lon_min, lon_max, lat_min, lat_max: lon_min < -100,
    "norway": lambda lon_min, lon_max, lat_min, lat_max: lat_min > 74,
    "spain": lambda lon_min, lon_max, lat_min, lat_max: lon_max < -10,
    "portugal": lambda lon_min, lon_max, lat_min, lat_max: lon_max < -10,
    "united_kingdom": lambda lon_min, lon_max, lat_min, lat_max: lon_max < -20,
}


def project(longitude, latitude):
    x = (longitude - LONGITUDE_RANGE[0]) * PIXELS_PER_DEGREE
    y = (LATITUDE_RANGE[1] - latitude) * PIXELS_PER_DEGREE
    return (x, y)


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
        # Collinear: overlapping along the line, not just meeting at an end.
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
    longer crosses itself (a self-crossing outline can't be filled)."""
    attempt = tolerance
    while True:
        candidate = snapped_points(douglas_peucker(points, attempt))
        if len(candidate) < 3 or is_simple(candidate):
            return candidate
        if attempt < 0.05:
            print("warning: could not make a simple outline of %d points" % len(points), file=sys.stderr)
            return candidate
        attempt *= 0.6


def signed_area(points):
    total = 0.0
    for index, point in enumerate(points):
        following = points[(index + 1) % len(points)]
        total += point[0] * following[1] - following[0] * point[1]
    return total / 2.0


def polygon_outer_rings(geometry):
    if geometry["type"] == "Polygon":
        return [geometry["coordinates"][0]]
    return [polygon[0] for polygon in geometry["coordinates"]]


def simplified_pieces(geometry, country_id, tolerance, minimum_area):
    pieces = []
    for ring in polygon_outer_rings(geometry):
        longitudes = [coordinate[0] for coordinate in ring]
        latitudes = [coordinate[1] for coordinate in ring]
        excluded = EXCLUDED_PIECES.get(country_id)
        if excluded and excluded(min(longitudes), max(longitudes), min(latitudes), max(latitudes)):
            continue
        points = [project(coordinate[0], coordinate[1]) for coordinate in ring]
        if points[0] == points[-1]:
            points = points[:-1]
        points = simple_simplification(points, tolerance)
        if len(points) < 3:
            continue
        pieces.append((abs(signed_area(points)), points))
    if not pieces:
        return []
    biggest = max(area for area, _ in pieces)
    return [points for area, points in pieces if area >= minimum_area or area == biggest]


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


def distance_to_edge(points, probe):
    count = len(points)
    return min(point_line_distance(probe, points[index], points[(index + 1) % count]) for index in range(count))


def label_point(points):
    """Roughly the pole of inaccessibility: the grid point deepest inside."""
    xs = [point[0] for point in points]
    ys = [point[1] for point in points]
    best, best_depth = None, -1.0
    steps = 36
    for column in range(steps + 1):
        for row in range(steps + 1):
            probe = (min(xs) + (max(xs) - min(xs)) * column / steps, min(ys) + (max(ys) - min(ys)) * row / steps)
            if contains(points, probe):
                depth = distance_to_edge(points, probe)
                if depth > best_depth:
                    best, best_depth = probe, depth
    return best


def rounded(points):
    return [[round(x, 1), round(y, 1)] for x, y in points]


def bounding_box(pieces):
    xs = [vertex[0] for piece in pieces for vertex in piece]
    ys = [vertex[1] for piece in pieces for vertex in piece]
    return (min(xs), min(ys), max(xs), max(ys))


def share_a_border(first_pieces, second_pieces):
    """Neighbours: a vertex of one lies within a few pixels of the other's edge."""
    margin = 4.0
    first_box, second_box = bounding_box(first_pieces), bounding_box(second_pieces)
    if (first_box[0] > second_box[2] + margin or second_box[0] > first_box[2] + margin
            or first_box[1] > second_box[3] + margin or second_box[1] > first_box[3] + margin):
        return False
    for piece in first_pieces:
        for vertex in piece:
            if not (second_box[0] - margin <= vertex[0] <= second_box[2] + margin
                    and second_box[1] - margin <= vertex[1] <= second_box[3] + margin):
                continue
            for other_piece in second_pieces:
                count = len(other_piece)
                for index in range(count):
                    if point_line_distance(vertex, other_piece[index], other_piece[(index + 1) % count]) < margin:
                        return True
    return False


def colour_countries(pieces_by_id):
    ids = list(pieces_by_id)
    neighbours = {country_id: set() for country_id in ids}
    for first_index, first in enumerate(ids):
        for second in ids[first_index + 1:]:
            if share_a_border(pieces_by_id[first], pieces_by_id[second]):
                neighbours[first].add(second)
                neighbours[second].add(first)
    colours = {}
    # Most-bordered first gives greedy colouring the best chance of fitting in six.
    for country_id in sorted(ids, key=lambda candidate: -len(neighbours[candidate])):
        taken = {colours[other] for other in neighbours[country_id] if other in colours}
        # The least-used free colour, so all six turn up across the map.
        uses = {colour: list(colours.values()).count(colour) for colour in range(COLOUR_COUNT)}
        free = [colour for colour in range(COLOUR_COUNT) if colour not in taken]
        colours[country_id] = min(free, key=lambda colour: uses[colour])
    return colours, neighbours


def main():
    source_path, output_path = sys.argv[1], sys.argv[2]
    with open(source_path, encoding="utf-8") as source:
        features = json.load(source)["features"]
    by_name = {feature["properties"]["NAME"]: feature for feature in features}

    pickable_names = {name for name, _, _ in COUNTRIES}
    pieces_by_id = {}
    countries = []
    for natural_earth_name, country_id, display_name in COUNTRIES:
        geometry = by_name[natural_earth_name]["geometry"]
        pieces = simplified_pieces(geometry, country_id, PICKABLE_TOLERANCE_PIXELS, MINIMUM_PICKABLE_ISLAND_PIXELS_SQUARED)
        pieces_by_id[country_id] = pieces
        biggest = max(pieces, key=lambda piece: abs(signed_area(piece)))
        label = label_point(biggest)
        countries.append({"id": country_id, "name": display_name, "label": [round(label[0]), round(label[1])],
                          "polygons": [rounded(piece) for piece in pieces]})

    colours, neighbours = colour_countries(pieces_by_id)
    for country in countries:
        country["colour"] = colours[country["id"]] % COLOUR_COUNT
        country["neighbours"] = sorted(neighbours[country["id"]])
    clashes = [(a, b) for a in colours for b in neighbours[a] if colours[a] % COLOUR_COUNT == colours[b] % COLOUR_COUNT]
    if clashes:
        print("warning: neighbours share a colour:", clashes, file=sys.stderr)

    plain_land = []
    for feature in features:
        if feature["properties"]["NAME"] in pickable_names:
            continue
        for piece in simplified_pieces(feature["geometry"], "", PLAIN_LAND_TOLERANCE_PIXELS, MINIMUM_LAND_ISLAND_PIXELS_SQUARED):
            plain_land.append(rounded(piece))

    world = {"width": round(MAP_WIDTH), "height": math.ceil(MAP_HEIGHT), "countries": countries, "plain_land": plain_land}
    with open(output_path, "w", encoding="utf-8") as output:
        json.dump(world, output, separators=(",", ":"))
    print(f"{len(countries)} countries, {len(plain_land)} plain land pieces, {MAP_WIDTH:.0f}x{MAP_HEIGHT:.0f}")


if __name__ == "__main__":
    main()

class_name FlagDrawings
extends RefCounted
## A simple, friendly drawing of every country's flag, for the Book. Each flag is a
## few words of data: stripes ("h" across, "v" down, "r:2" is twice as thick) and
## shapes drawn over them. Everything is worked out on a 3 wide by 2 tall grid,
## then cut to the flag's edge, so nothing spills over. They are pictures, not
## plans: the crests and fine detail are left out.

const COLOURS: Dictionary = {
	"w": Color("ffffff"), "k": Color("1c1c22"), "r": Color("ce1126"), "db": Color("0f2f7a"), "b": Color("1259b8"),
	"lb": Color("5ba3dc"), "g": Color("00a651"), "dg": Color("00703c"), "y": Color("fcd116"), "o": Color("ff8200"),
	"ma": Color("9d2235"), "br": Color("8b5a2b"),
}
const EDGE_COLOUR: Color = Color(0.1, 0.08, 0.16, 0.35)
const STAR_INNER_RATIO: float = 0.382
## The leaf, as outline points around its centre, about one unit across.
const MAPLE_LEAF: Array[float] = [0.0, -0.5, 0.09, -0.32, 0.2, -0.36, 0.16, -0.12, 0.38, -0.2, 0.33, -0.05, 0.48, 0.0, 0.28, 0.18,
	0.31, 0.3, 0.06, 0.24, 0.06, 0.5, -0.06, 0.5, -0.06, 0.24, -0.31, 0.3, -0.28, 0.18, -0.48, 0.0, -0.33, -0.05, -0.38, -0.2, -0.16, -0.12, -0.2, -0.36, -0.09, -0.32]

const FLAGS: Dictionary = {
	"afghanistan": {"v": ["k", "r", "dg"], "ops": [["circle", "w", 1.5, 1, 0.32]]},
	"algeria": {"v": ["dg", "w"], "ops": [["crescent", "r", 1.5, 1, 0.5, 0], ["star", "r", 1.72, 1, 0.2]]},
	"angola": {"h": ["r", "k"], "ops": [["circle", "y", 1.5, 1, 0.36]]},
	"antarctica": {"bg": "lb", "ops": [["circle", "w", 1.5, 1, 0.62]]},
	"argentina": {"h": ["lb", "w", "lb"], "ops": [["circle", "y", 1.5, 1, 0.2]]},
	"australia": {"bg": "db", "ops": [["jack", 0, 0, 1.5, 1], ["star", "w", 0.75, 1.5, 0.3], ["star", "w", 2.2, 0.35, 0.17], ["star", "w", 2.6, 0.95, 0.17],
		["star", "w", 2.0, 1.15, 0.17], ["star", "w", 2.25, 1.7, 0.17]]},
	"austria": {"h": ["r", "w", "r"]},
	"azerbaijan": {"h": ["lb", "r", "dg"], "ops": [["crescent", "w", 1.45, 1, 0.3, 0], ["star", "w", 1.7, 1, 0.12]]},
	"bangladesh": {"bg": "dg", "ops": [["circle", "r", 1.35, 1, 0.55]]},
	"belarus": {"h": ["r:2", "dg"], "ops": [["rect", "w", 0, 0, 0.36, 2], ["rect", "r", 0.1, 0.2, 0.16, 1.6]]},
	"belgium": {"v": ["k", "y", "r"]},
	"benin": {"bg": "g", "ops": [["rect", "y", 1.2, 0, 1.8, 1], ["rect", "r", 1.2, 1, 1.8, 1]]},
	"bolivia": {"h": ["r", "y", "g"]},
	"bosnia_and_herzegovina": {"bg": "db", "ops": [["tri", "y", 0.8, 0, 2.4, 0, 2.4, 1.6], ["star", "w", 0.9, 0.1, 0.11], ["star", "w", 1.25, 0.43, 0.11],
		["star", "w", 1.6, 0.76, 0.11], ["star", "w", 1.95, 1.09, 0.11]]},
	"botswana": {"h": ["lb:9", "w", "k:6", "w", "lb:9"]},
	"brazil": {"bg": "g", "ops": [["poly", "y", 1.5, 0.2, 2.7, 1, 1.5, 1.8, 0.3, 1], ["circle", "db", 1.5, 1, 0.45]]},
	"bulgaria": {"h": ["w", "g", "r"]},
	"burkina_faso": {"h": ["r", "dg"], "ops": [["star", "y", 1.5, 1.05, 0.4]]},
	"cambodia": {"h": ["db", "r:2", "db"], "ops": [["rect", "w", 1.15, 0.85, 0.7, 0.3], ["tri", "w", 1.2, 0.85, 1.5, 0.6, 1.8, 0.85]]},
	"cameroon": {"v": ["dg", "r", "y"], "ops": [["star", "y", 1.5, 1.05, 0.3]]},
	"canada": {"v": ["r", "w:2", "r"], "ops": [["maple", "r", 1.5, 1, 1.2]]},
	"central_african_republic": {"h": ["db", "w", "dg", "y"], "ops": [["rect", "r", 1.25, 0, 0.5, 2], ["star", "y", 0.35, 0.3, 0.2]]},
	"chad": {"v": ["db", "y", "r"]},
	"chile": {"h": ["w", "r"], "ops": [["rect", "db", 0, 0, 1, 1], ["star", "w", 0.5, 0.52, 0.3]]},
	"china": {"bg": "r", "ops": [["star", "y", 0.55, 0.62, 0.33], ["star", "y", 1.15, 0.25, 0.1], ["star", "y", 1.35, 0.5, 0.1], ["star", "y", 1.35, 0.85, 0.1], ["star", "y", 1.15, 1.1, 0.1]]},
	"colombia": {"h": ["y:2", "db", "r"]},
	"congo": {"bg": "y", "ops": [["poly", "g", 0, 0, 1.5, 0, 0, 2], ["poly", "r", 3, 2, 1.5, 2, 3, 0]]},
	"cote_d_ivoire": {"v": ["o", "w", "g"]},
	"croatia": {"h": ["r", "w", "db"], "ops": [["rect", "w", 1.27, 0.62, 0.46, 0.76], ["rect", "r", 1.3, 0.65, 0.4, 0.7], ["rect", "w", 1.4, 0.75, 0.1, 0.1], ["rect", "w", 1.5, 0.95, 0.1, 0.1]]},
	"cuba": {"h": ["db", "w", "db", "w", "db"], "ops": [["tri", "r", 0, 0, 1.3, 1, 0, 2], ["star", "w", 0.42, 1.05, 0.3]]},
	"czechia": {"h": ["w", "r"], "ops": [["tri", "db", 0, 0, 1.5, 1, 0, 2]]},
	"denmark": {"bg": "r", "ops": [["cross", "w", 0.4, 1.1]]},
	"dr_congo": {"bg": "lb", "ops": [["poly", "y", 0, 1.5, 2.7, 0, 3, 0, 3, 0.5, 0.3, 2, 0, 2], ["poly", "r", 0, 1.68, 2.88, 0, 3, 0, 3, 0.32, 0.12, 2, 0, 2], ["star", "y", 0.4, 0.4, 0.3]]},
	"ecuador": {"h": ["y:2", "db", "r"]},
	"egypt": {"h": ["r", "w", "k"], "ops": [["circle", "y", 1.5, 1, 0.2]]},
	"eritrea": {"h": ["g", "lb"], "ops": [["tri", "r", 0, 0, 3, 1, 0, 2], ["circle", "y", 0.65, 1, 0.2]]},
	"estonia": {"h": ["b", "k", "w"]},
	"ethiopia": {"h": ["g", "y", "r"], "ops": [["circle", "b", 1.5, 1, 0.5], ["star", "y", 1.5, 1.02, 0.36]]},
	"finland": {"bg": "w", "ops": [["cross", "db", 0.5, 1.1]]},
	"france": {"v": ["db", "w", "r"]},
	"gabon": {"h": ["g", "y", "lb"]},
	"germany": {"h": ["k", "r", "y"]},
	"ghana": {"h": ["r", "y", "g"], "ops": [["star", "k", 1.5, 1.05, 0.36]]},
	"greece": {"h": ["b", "w", "b", "w", "b", "w", "b", "w", "b"], "ops": [["rect", "b", 0, 0, 1.12, 1.12], ["rect", "w", 0.45, 0, 0.22, 1.12], ["rect", "w", 0, 0.45, 1.12, 0.22]]},
	"greenland": {"h": ["w", "r"], "ops": [["arc", "r", 1.1, 1, 0.6, 180, 360], ["arc", "w", 1.1, 1, 0.6, 0, 180]]},
	"guinea": {"v": ["r", "y", "g"]},
	"guyana": {"bg": "g", "ops": [["tri", "w", 0, 0, 3, 1, 0, 2], ["tri", "y", 0, 0.12, 2.8, 1, 0, 1.88], ["tri", "k", 0, 0, 1.5, 1, 0, 2], ["tri", "r", 0, 0.2, 1.2, 1, 0, 1.8]]},
	"honduras": {"h": ["lb", "w", "lb"], "ops": [["star", "lb", 1.5, 1, 0.13], ["star", "lb", 1.2, 0.85, 0.13], ["star", "lb", 1.8, 0.85, 0.13], ["star", "lb", 1.2, 1.15, 0.13], ["star", "lb", 1.8, 1.15, 0.13]]},
	"hungary": {"h": ["r", "w", "dg"]},
	"iceland": {"bg": "db", "ops": [["cross", "w", 0.6, 1.1], ["cross", "r", 0.3, 1.1]]},
	"india": {"h": ["o", "w", "dg"], "ops": [["circle", "db", 1.5, 1, 0.27], ["circle", "w", 1.5, 1, 0.22], ["circle", "db", 1.5, 1, 0.05], ["rays", "db", 1.5, 1, 0.05, 0.22, 12, 0.03]]},
	"indonesia": {"h": ["r", "w"]},
	"iran": {"h": ["g", "w", "r"], "ops": [["circle", "r", 1.5, 1, 0.17]]},
	"iraq": {"h": ["r", "w", "k"], "ops": [["rect", "g", 0.95, 0.9, 0.35, 0.2], ["rect", "g", 1.7, 0.9, 0.35, 0.2]]},
	"ireland": {"v": ["g", "w", "o"]},
	"italy": {"v": ["g", "w", "r"]},
	"japan": {"bg": "w", "ops": [["circle", "r", 1.5, 1, 0.6]]},
	"jordan": {"h": ["k", "w", "dg"], "ops": [["tri", "r", 0, 0, 1.5, 1, 0, 2], ["star", "w", 0.5, 1, 0.17]]},
	"kazakhstan": {"bg": "lb", "ops": [["circle", "y", 1.5, 0.85, 0.38], ["rays", "y", 1.5, 0.85, 0.38, 0.55, 16, 0.05], ["rect", "y", 0.2, 0, 0.22, 2], ["rect", "y", 1.0, 1.45, 1.0, 0.12]]},
	"kenya": {"h": ["k:3", "w", "r:3", "w", "dg:3"], "ops": [["circle", "k", 1.5, 1, 0.45], ["circle", "r", 1.5, 1, 0.4], ["circle", "w", 1.5, 1, 0.1]]},
	"kyrgyzstan": {"bg": "r", "ops": [["circle", "y", 1.5, 1, 0.55], ["circle", "r", 1.5, 1, 0.4], ["circle", "y", 1.5, 1, 0.2]]},
	"laos": {"h": ["r", "db:2", "r"], "ops": [["circle", "w", 1.5, 1, 0.4]]},
	"latvia": {"h": ["ma:2", "w", "ma:2"]},
	"liberia": {"h": ["r", "w", "r", "w", "r", "w", "r", "w", "r", "w", "r"], "ops": [["rect", "db", 0, 0, 0.9, 1.09], ["star", "w", 0.45, 0.55, 0.3]]},
	"libya": {"h": ["r", "k:2", "dg"], "ops": [["crescent", "w", 1.45, 1, 0.3, 0], ["star", "w", 1.7, 1, 0.12]]},
	"lithuania": {"h": ["y", "dg", "r"]},
	"madagascar": {"bg": "r", "ops": [["rect", "w", 0, 0, 1, 2], ["rect", "dg", 1, 1, 2, 1]]},
	"malawi": {"h": ["k", "r", "dg"], "ops": [["arc", "r", 1.5, 0.67, 0.4, 180, 360]]},
	"malaysia": {"h": ["r", "w", "r", "w", "r", "w", "r", "w", "r", "w", "r", "w", "r", "w"], "ops": [["rect", "db", 0, 0, 1.5, 1.07], ["crescent", "y", 0.55, 0.55, 0.38, 0], ["star", "y", 0.98, 0.55, 0.18]]},
	"mali": {"v": ["g", "y", "r"]},
	"mauritania": {"bg": "dg", "ops": [["rect", "r", 0, 0, 3, 0.3], ["rect", "r", 0, 1.7, 3, 0.3], ["crescent", "y", 1.5, 0.95, 0.5, -90], ["star", "y", 1.5, 0.8, 0.14]]},
	"mexico": {"v": ["dg", "w", "r"], "ops": [["circle", "br", 1.5, 1, 0.3], ["circle", "dg", 1.5, 1.2, 0.18]]},
	"moldova": {"v": ["db", "y", "r"], "ops": [["circle", "br", 1.5, 1, 0.26]]},
	"mongolia": {"v": ["r", "db", "r"], "ops": [["circle", "y", 0.5, 0.6, 0.13], ["rect", "y", 0.4, 0.8, 0.2, 0.7], ["rect", "y", 0.28, 0.9, 0.04, 0.5], ["rect", "y", 0.68, 0.9, 0.04, 0.5]]},
	"morocco": {"bg": "r", "ops": [["star", "dg", 1.5, 1.05, 0.62], ["star", "r", 1.5, 1.05, 0.5]]},
	"mozambique": {"h": ["dg:3", "w", "k:3", "w", "y:3"], "ops": [["tri", "r", 0, 0, 1.4, 1, 0, 2], ["star", "y", 0.42, 1, 0.28]]},
	"myanmar": {"h": ["y", "g", "r"], "ops": [["star", "w", 1.5, 1.07, 0.72]]},
	"namibia": {"bg": "dg", "ops": [["poly", "lb", 0, 0, 2.7, 0, 0, 1.5], ["poly", "w", 0, 1.5, 2.7, 0, 3, 0, 3, 0.5, 0.3, 2, 0, 2], ["poly", "r", 0, 1.68, 2.88, 0, 3, 0, 3, 0.32, 0.12, 2, 0, 2], ["circle", "y", 0.5, 0.5, 0.25]]},
	"nepal": {"bg": "w", "ops": [["poly", "db", 0.15, 0.05, 1.95, 1.0, 1.0, 1.0, 1.95, 1.95, 0.15, 1.95], ["poly", "r", 0.28, 0.3, 1.5, 0.9, 0.85, 0.9, 1.5, 1.75, 0.28, 1.75], ["circle", "w", 0.6, 1.4, 0.13], ["circle", "w", 0.6, 0.7, 0.1]]},
	"netherlands": {"h": ["r", "w", "db"]},
	"new_zealand": {"bg": "db", "ops": [["jack", 0, 0, 1.5, 1], ["star", "w", 2.25, 0.35, 0.18], ["star", "r", 2.25, 0.35, 0.12], ["star", "w", 2.6, 0.85, 0.18], ["star", "r", 2.6, 0.85, 0.12],
		["star", "w", 2.1, 1.0, 0.18], ["star", "r", 2.1, 1.0, 0.12], ["star", "w", 2.3, 1.55, 0.18], ["star", "r", 2.3, 1.55, 0.12]]},
	"nicaragua": {"h": ["b", "w", "b"], "ops": [["tri", "g", 1.5, 0.65, 1.8, 1.3, 1.2, 1.3]]},
	"niger": {"h": ["o", "w", "dg"], "ops": [["circle", "o", 1.5, 1, 0.3]]},
	"nigeria": {"v": ["dg", "w", "dg"]},
	"north_korea": {"h": ["b:6", "w", "r:24", "w", "b:6"], "ops": [["circle", "w", 1.0, 1, 0.5], ["star", "r", 1.0, 1.03, 0.4]]},
	"north_macedonia": {"bg": "r", "ops": [["rays", "y", 1.5, 1, 0.35, 0.95, 8, 0.14], ["circle", "r", 1.5, 1, 0.4], ["circle", "y", 1.5, 1, 0.32]]},
	"norway": {"bg": "r", "ops": [["cross", "w", 0.5, 1.1], ["cross", "db", 0.25, 1.1]]},
	"oman": {"h": ["w", "r", "dg"], "ops": [["rect", "r", 0, 0, 0.9, 2]]},
	"pakistan": {"bg": "dg", "ops": [["rect", "w", 0, 0, 0.75, 2], ["crescent", "w", 1.9, 1, 0.6, -35], ["star", "w", 2.2, 0.72, 0.2]]},
	"papua_new_guinea": {"bg": "k", "ops": [["tri", "r", 0, 0, 3, 0, 3, 2], ["circle", "y", 2.15, 0.7, 0.28], ["star", "w", 0.5, 1.45, 0.12], ["star", "w", 0.9, 1.2, 0.12], ["star", "w", 0.7, 1.7, 0.12], ["star", "w", 1.1, 1.55, 0.12]]},
	"paraguay": {"h": ["r", "w", "db"], "ops": [["circle", "g", 1.5, 1, 0.24], ["circle", "w", 1.5, 1, 0.14]]},
	"peru": {"v": ["r", "w", "r"], "ops": [["circle", "g", 1.5, 1, 0.2]]},
	"philippines": {"h": ["db", "r"], "ops": [["tri", "w", 0, 0, 1.4, 1, 0, 2], ["circle", "y", 0.45, 1, 0.2]]},
	"poland": {"h": ["w", "r"]},
	"portugal": {"v": ["dg:2", "r:3"], "ops": [["circle", "y", 1.2, 1, 0.4], ["circle", "r", 1.2, 1, 0.28], ["circle", "w", 1.2, 1, 0.12]]},
	"romania": {"v": ["db", "y", "r"]},
	"russia": {"h": ["w", "b", "r"]},
	"saudi_arabia": {"bg": "dg", "ops": [["rect", "w", 0.7, 0.6, 1.6, 0.25], ["rect", "w", 0.8, 1.15, 1.4, 0.1]]},
	"senegal": {"v": ["g", "y", "r"], "ops": [["star", "g", 1.5, 1.05, 0.32]]},
	"serbia": {"h": ["r", "db", "w"], "ops": [["rect", "w", 0.57, 0.52, 0.46, 0.66], ["rect", "r", 0.6, 0.55, 0.4, 0.6]]},
	"sierra_leone": {"h": ["g", "w", "lb"]},
	"slovakia": {"h": ["w", "b", "r"], "ops": [["rect", "w", 0.57, 0.55, 0.6, 0.8], ["rect", "r", 0.6, 0.58, 0.54, 0.72], ["rect", "w", 0.84, 0.7, 0.06, 0.44], ["rect", "w", 0.74, 0.82, 0.26, 0.06]]},
	"somalia": {"bg": "lb", "ops": [["star", "w", 1.5, 1.05, 0.55]]},
	"somaliland": {"h": ["dg", "w", "r"], "ops": [["star", "k", 1.5, 1.0, 0.3]]},
	"south_africa": {"h": ["r", "b"], "ops": [["tri", "k", 0, 0.2, 0, 1.8, 1.0, 1], ["line", "w", 0.62, 0, 0, 1.3, 1, 0, 2], ["line", "w", 0.62, 1.3, 1, 3.2, 1],
		["line", "g", 0.4, 0, 0, 1.3, 1, 0, 2], ["line", "g", 0.4, 1.3, 1, 3.2, 1]]},
	"south_sudan": {"h": ["k:3", "w", "r:3", "w", "g:3"], "ops": [["tri", "db", 0, 0, 1.3, 1, 0, 2], ["star", "y", 0.4, 1, 0.25]]},
	"spain": {"h": ["r", "y:2", "r"], "ops": [["rect", "br", 0.75, 0.8, 0.3, 0.4]]},
	"sudan": {"h": ["r", "w", "k"], "ops": [["tri", "dg", 0, 0, 1.2, 1, 0, 2]]},
	"suriname": {"h": ["dg:2", "w:0.5", "r:4", "w:0.5", "dg:2"], "ops": [["star", "y", 1.5, 1.05, 0.45]]},
	"sweden": {"bg": "b", "ops": [["cross", "y", 0.4, 1.0]]},
	"switzerland": {"bg": "r", "ops": [["rect", "w", 1.3, 0.45, 0.4, 1.1], ["rect", "w", 0.95, 0.8, 1.1, 0.4]]},
	"syria": {"h": ["r", "w", "k"], "ops": [["star", "dg", 1.1, 1, 0.18], ["star", "dg", 1.9, 1, 0.18]]},
	"tajikistan": {"h": ["r:2", "w:3", "dg:2"], "ops": [["circle", "y", 1.5, 1, 0.25]]},
	"tanzania": {"bg": "lb", "ops": [["poly", "g", 0, 0, 2.7, 0, 0, 1.5], ["poly", "y", 0, 1.5, 2.7, 0, 3, 0, 3, 0.5, 0.3, 2, 0, 2], ["poly", "k", 0, 1.68, 2.88, 0, 3, 0, 3, 0.32, 0.12, 2, 0, 2]]},
	"thailand": {"h": ["r", "w", "db:2", "w", "r"]},
	"tunisia": {"bg": "r", "ops": [["circle", "w", 1.5, 1, 0.55], ["crescent", "r", 1.46, 1, 0.38, 0], ["star", "r", 1.58, 1, 0.16]]},
	"turkey": {"bg": "r", "ops": [["crescent", "w", 1.15, 1, 0.55, 0], ["star", "w", 1.68, 1, 0.2]]},
	"turkmenistan": {"bg": "dg", "ops": [["rect", "r", 0.3, 0, 0.5, 2], ["crescent", "w", 1.2, 0.5, 0.25, 0]]},
	"uganda": {"h": ["k", "y", "r", "k", "y", "r"], "ops": [["circle", "w", 1.5, 1, 0.45], ["circle", "k", 1.5, 1, 0.16]]},
	"ukraine": {"h": ["b", "y"]},
	"united_arab_emirates": {"h": ["dg", "w", "k"], "ops": [["rect", "r", 0, 0, 0.7, 2]]},
	"united_kingdom": {"bg": "db", "ops": [["jack", 0, 0, 3, 2]]},
	"uruguay": {"h": ["w", "b", "w", "b", "w", "b", "w", "b", "w"], "ops": [["rect", "w", 0, 0, 1.1, 1.1], ["circle", "y", 0.55, 0.55, 0.28], ["rays", "y", 0.55, 0.55, 0.28, 0.42, 16, 0.05]]},
	"usa": {"h": ["r", "w", "r", "w", "r", "w", "r", "w", "r", "w", "r", "w", "r"], "ops": [["rect", "db", 0, 0, 1.2, 1.08], ["grid", "w", 0.16, 0.14, 0.22, 0.2, 5, 5, 0.07]]},
	"uzbekistan": {"h": ["lb:3", "r:0.2", "w:2.6", "r:0.2", "g:3"], "ops": [["crescent", "w", 0.35, 0.4, 0.22, 0]]},
	"venezuela": {"h": ["y", "db", "r"], "ops": [["arcstars", "w", 1.5, 1.55, 0.75, 215, 325, 8, 0.09]]},
	"vietnam": {"bg": "r", "ops": [["star", "y", 1.5, 1.07, 0.6]]},
	"yemen": {"h": ["r", "w", "k"]},
	"zambia": {"bg": "dg", "ops": [["rect", "r", 2.1, 1, 0.3, 1], ["rect", "k", 2.4, 1, 0.3, 1], ["rect", "o", 2.7, 1, 0.3, 1], ["circle", "o", 2.3, 0.55, 0.2]]},
	"zimbabwe": {"h": ["dg", "y", "r", "k", "r", "y", "dg"], "ops": [["tri", "k", 0, 0, 1.4, 1, 0, 2], ["tri", "w", 0, 0.12, 1.2, 1, 0, 1.88], ["star", "r", 0.4, 1.02, 0.28]]},
}

var canvas: CanvasItem
var origin: Vector2
var unit: float
var clip: PackedVector2Array


static func can_draw(country_id: String) -> bool:
	return FLAGS.has(country_id)


## Draws the flag 3:2 and "width" wide, centred on "centre", with a thin edge so
## white flags don't vanish into a white card.
static func draw(target: CanvasItem, country_id: String, centre: Vector2, width: float) -> void:
	if not FLAGS.has(country_id):
		return
	var flag: FlagDrawings = FlagDrawings.new()
	flag.canvas = target
	flag.unit = width / 3.0
	flag.origin = centre - Vector2(width, width * 2.0 / 3.0) / 2.0
	flag.draw_spec(FLAGS[country_id])
	var edge: PackedVector2Array = flag.rectangle_points(0, 0, 3, 2)
	edge.append(edge[0])
	target.draw_polyline(edge, EDGE_COLOUR, 3.0, true)


func draw_spec(spec: Dictionary) -> void:
	clip = rectangle_points(0, 0, 3, 2)
	if spec.has("bg"):
		fill(clip, COLOURS[spec["bg"]])
	if spec.has("h"):
		draw_stripes(spec["h"], true)
	if spec.has("v"):
		draw_stripes(spec["v"], false)
	for op in spec.get("ops", []):
		draw_op(op)


func draw_stripes(stripes: Array, is_across: bool) -> void:
	var total: float = 0.0
	for stripe in stripes:
		total += stripe_weight(stripe)
	var so_far: float = 0.0
	for stripe in stripes:
		var share: float = stripe_weight(stripe) / total
		var colour: Color = COLOURS[String(stripe).split(":")[0]]
		if is_across:
			fill(rectangle_points(0, so_far * 2.0, 3, share * 2.0), colour)
		else:
			fill(rectangle_points(so_far * 3.0, 0, share * 3.0, 2), colour)
		so_far += share


static func stripe_weight(stripe: String) -> float:
	var parts: PackedStringArray = stripe.split(":")
	return float(parts[1]) if parts.size() > 1 else 1.0


func draw_op(op: Array) -> void:
	var kind: String = op[0]
	if kind == "jack":
		draw_jack(op[1], op[2], op[3], op[4])
		return
	var colour: Color = COLOURS[op[1]]
	match kind:
		"rect": fill(rectangle_points(op[2], op[3], op[4], op[5]), colour)
		"tri", "poly": fill(points_from(op, 2), colour)
		"circle": fill(circle_points(Vector2(op[2], op[3]), op[4]), colour)
		"star": fill(star_points(Vector2(op[2], op[3]), op[4]), colour)
		"crescent": fill(crescent_points(Vector2(op[2], op[3]), op[4], deg_to_rad(op[5])), colour)
		"cross":
			fill(rectangle_points(op[3] - op[2] / 2.0, 0, op[2], 2), colour)
			fill(rectangle_points(0, 1.0 - op[2] / 2.0, 3, op[2]), colour)
		"line": fill_line(points_from(op, 3), op[2], colour)
		"arc": fill(arc_points(Vector2(op[2], op[3]), op[4], op[5], op[6]), colour)
		"rays":
			for ray in int(op[6]):
				var direction: Vector2 = Vector2.from_angle(TAU * ray / op[6])
				fill_line(PackedVector2Array([to_canvas(Vector2(op[2], op[3]) + direction * op[4]), to_canvas(Vector2(op[2], op[3]) + direction * op[5])]), op[7], colour)
		"grid":
			for row in int(op[7]):
				for column in int(op[6]):
					fill(star_points(Vector2(op[2] + column * op[4] + (op[4] / 2.0 if row % 2 == 1 else 0.0), op[3] + row * op[5] * 0.8), op[8]), colour)
		"arcstars":
			for star_number in int(op[7]):
				var angle: float = deg_to_rad(lerpf(op[5], op[6], star_number / (op[7] - 1.0)))
				fill(star_points(Vector2(op[2], op[3]) + Vector2.from_angle(angle) * op[4], op[8]), colour)
		"maple":
			var leaf: PackedVector2Array = PackedVector2Array()
			for index in range(0, MAPLE_LEAF.size(), 2):
				leaf.append(to_canvas(Vector2(op[2], op[3]) + Vector2(MAPLE_LEAF[index], MAPLE_LEAF[index + 1]) * op[4]))
			fill(leaf, colour)


## The Union Jack, squeezed into a box: the canton on Australia's and New Zealand's flags.
func draw_jack(x: float, y: float, width: float, height: float) -> void:
	var outer_clip: PackedVector2Array = clip
	clip = rectangle_points(x, y, width, height)
	fill(clip, COLOURS["db"])
	var corners: Array[Vector2] = [Vector2(x, y), Vector2(x + width, y + height), Vector2(x + width, y), Vector2(x, y + height)]
	for corner_pair in [[0, 1], [2, 3]]:
		fill_line(PackedVector2Array([to_canvas(corners[corner_pair[0]]), to_canvas(corners[corner_pair[1]])]), height * 0.2, COLOURS["w"])
	for corner_pair in [[0, 1], [2, 3]]:
		fill_line(PackedVector2Array([to_canvas(corners[corner_pair[0]]), to_canvas(corners[corner_pair[1]])]), height * 0.08, COLOURS["r"])
	var middle: Vector2 = Vector2(x + width / 2.0, y + height / 2.0)
	for stroke in [[height * 0.34, COLOURS["w"]], [height * 0.2, COLOURS["r"]]]:
		fill(rectangle_points(middle.x - stroke[0] / 2.0, y, stroke[0], height), stroke[1])
		fill(rectangle_points(x, middle.y - stroke[0] / 2.0, width, stroke[0]), stroke[1])
	clip = outer_clip


# --- Shapes, all in flag units (3 wide, 2 tall) --------------------------------

func rectangle_points(x: float, y: float, width: float, height: float) -> PackedVector2Array:
	return PackedVector2Array([to_canvas(Vector2(x, y)), to_canvas(Vector2(x + width, y)), to_canvas(Vector2(x + width, y + height)), to_canvas(Vector2(x, y + height))])


func to_canvas(flag_point: Vector2) -> Vector2:
	return origin + flag_point * unit


func points_from(op: Array, first_number: int) -> PackedVector2Array:
	var points: PackedVector2Array = PackedVector2Array()
	for index in range(first_number, op.size(), 2):
		points.append(to_canvas(Vector2(op[index], op[index + 1])))
	return points


func circle_points(centre: Vector2, radius: float) -> PackedVector2Array:
	return arc_points(centre, radius, 0, 360, false)


## A pie slice from one angle to another, in degrees (0 is right, 90 is down); a whole circle when "slice" is off.
func arc_points(centre: Vector2, radius: float, from_degrees: float, to_degrees: float, slice: bool = true) -> PackedVector2Array:
	var points: PackedVector2Array = PackedVector2Array()
	if slice:
		points.append(to_canvas(centre))
	var steps: int = 20 if slice else 32
	var point_count: int = steps + 1 if slice else steps
	for step in point_count:
		var angle: float = deg_to_rad(lerpf(from_degrees, to_degrees, step / float(steps)))
		points.append(to_canvas(centre + Vector2.from_angle(angle) * radius))
	return points


func star_points(centre: Vector2, radius: float) -> PackedVector2Array:
	var points: PackedVector2Array = PackedVector2Array()
	for point_index in 10:
		var point_radius: float = radius if point_index % 2 == 0 else radius * STAR_INNER_RATIO
		points.append(to_canvas(centre + Vector2.from_angle(-PI / 2.0 + point_index * PI / 5.0) * point_radius))
	return points


## A moon with its opening facing "rotation" (0 faces right): the big circle with a smaller one bitten out.
func crescent_points(centre: Vector2, radius: float, rotation: float) -> PackedVector2Array:
	var bite_radius: float = radius * 0.8
	var bite_distance: float = radius * 0.3
	var cross_x: float = (bite_distance * bite_distance + radius * radius - bite_radius * bite_radius) / (2.0 * bite_distance)
	var cross_y: float = sqrt(maxf(radius * radius - cross_x * cross_x, 0.0))
	var outer_angle: float = atan2(cross_y, cross_x)
	var bite_angle: float = atan2(cross_y, cross_x - bite_distance)
	var points: PackedVector2Array = PackedVector2Array()
	for step in 25:
		var angle: float = lerpf(outer_angle, TAU - outer_angle, step / 24.0)
		points.append(to_canvas(centre + Vector2.from_angle(angle).rotated(rotation) * radius))
	for step in 25:
		var angle: float = lerpf(TAU - bite_angle, bite_angle, step / 24.0)
		points.append(to_canvas(centre + (Vector2(bite_distance, 0) + Vector2.from_angle(angle) * bite_radius).rotated(rotation)))
	return points


# --- Putting it on the canvas, cut to the clip ---------------------------------

func fill(points: PackedVector2Array, colour: Color) -> void:
	for piece in Geometry2D.intersect_polygons(points, clip):
		if Geometry2D.triangulate_polygon(piece).is_empty():
			continue
		canvas.draw_colored_polygon(piece, colour)


func fill_line(centreline_in_canvas: PackedVector2Array, width: float, colour: Color) -> void:
	for outline in Geometry2D.offset_polyline(centreline_in_canvas, width * unit / 2.0, Geometry2D.JOIN_ROUND, Geometry2D.END_BUTT):
		fill(outline, colour)

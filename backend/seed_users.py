"""
Seed script: Creates test users, follows, and sample pieces for development.
Run from the backend directory: python seed_users.py
All users have password: Test1234!
"""

import sys
import os

sys.path.insert(0, os.path.dirname(__file__))

from datetime import datetime, timezone

import bcrypt
from sqlalchemy import create_engine, text
from sqlalchemy.orm import Session

from app.core.config import settings

engine = create_engine(settings.database_url, echo=False)


def hash_pw(password: str) -> str:
    return bcrypt.hashpw(password.encode(), bcrypt.gensalt()).decode()


COMMON_PASSWORD = hash_pw("Test1234!")
BAARRERO_PASSWORD = hash_pw("Arnau_2004")

USERS = [
    {
        "username": "elena_marti",
        "email": "elena@test.com",
        "first_name": "Elena",
        "last_name": "Martí",
        "role": "seller",
        "city": "Barcelona",
        "country": "Spain",
        "studio_name": "Estudi Martí",
        "discipline": "Ceramic",
        "bio": "Contemporary ceramic artist exploring the boundary between functional and sculptural forms. Working with stoneware and porcelain since 2012.",
        "avatar_color": "#B8543C",
        "banner_color": "#D4A574",
        "website": "https://elenamarti.com",
        "instagram": "@elenamarti_ceramic",
    },
    {
        "username": "jordi_canudas",
        "email": "jordi@test.com",
        "first_name": "Jordi",
        "last_name": "Canudas",
        "role": "seller",
        "city": "Girona",
        "country": "Spain",
        "studio_name": "Canudas Studio",
        "discipline": "Furniture",
        "bio": "Furniture designer focused on sustainable materials and traditional joinery techniques. Each piece tells a story of craftsmanship and environmental responsibility.",
        "avatar_color": "#6B7A5A",
        "banner_color": "#8B9E6B",
        "website": "https://canudas.design",
        "instagram": "@jordi.canudas",
    },
    {
        "username": "marta_sala",
        "email": "marta@test.com",
        "first_name": "Marta",
        "last_name": "Sala",
        "role": "both",
        "city": "Barcelona",
        "country": "Spain",
        "studio_name": "Sala Ceràmica",
        "discipline": "Ceramic",
        "bio": "Exploring textures and glazes inspired by the Mediterranean landscape. My work celebrates imperfection and the beauty of handmade objects.",
        "avatar_color": "#A8893E",
        "banner_color": "#C9A962",
        "instagram": "@martasala_studio",
    },
    {
        "username": "pau_vives",
        "email": "pau@test.com",
        "first_name": "Pau",
        "last_name": "Vives",
        "role": "seller",
        "city": "Valencia",
        "country": "Spain",
        "studio_name": "Vives Textiles",
        "discipline": "Textiles",
        "bio": "Textile designer weaving stories through natural fibers. Specializing in handwoven tapestries and limited-edition cushions with organic dyes.",
        "avatar_color": "#9A8C7B",
        "banner_color": "#B5A694",
        "website": "https://pauvives.es",
        "instagram": "@pau.vives.textiles",
    },
    {
        "username": "laia_font",
        "email": "laia@test.com",
        "first_name": "Laia",
        "last_name": "Font",
        "role": "seller",
        "city": "Madrid",
        "country": "Spain",
        "studio_name": "Font Interiors",
        "discipline": "Lighting",
        "bio": "Lighting designer creating sculptural lamps from recycled brass and handblown glass. Every piece is a conversation between light and shadow.",
        "avatar_color": "#2E2520",
        "banner_color": "#4A3F35",
        "website": "https://laiafont.design",
        "instagram": "@laia.font.lighting",
    },
    {
        "username": "nuria_coll",
        "email": "nuria@test.com",
        "first_name": "Núria",
        "last_name": "Coll",
        "role": "both",
        "city": "Seville",
        "country": "Spain",
        "studio_name": None,
        "discipline": "Painting",
        "bio": "Curator and collector with a passion for emerging Spanish artists. Building bridges between creators and collectors through thoughtful curation.",
        "avatar_color": "#B3A594",
        "banner_color": "#CFC0AF",
        "instagram": "@nuriacoll_art",
    },
    {
        "username": "marc_esteve",
        "email": "marc@test.com",
        "first_name": "Marc",
        "last_name": "Esteve",
        "role": "seller",
        "city": "Terrassa",
        "country": "Spain",
        "studio_name": "Esteve Escultura",
        "discipline": "Sculpture",
        "bio": "Stone and metal sculptor inspired by Catalan modernism and organic forms. Working primarily with local marble and reclaimed iron.",
        "avatar_color": "#8A7D6A",
        "banner_color": "#A59888",
        "website": "https://marcesteve.art",
        "instagram": "@marc.esteve.sculpture",
    },
    {
        "username": "anna_riera",
        "email": "anna@test.com",
        "first_name": "Anna",
        "last_name": "Riera",
        "role": "seller",
        "city": "Milan",
        "country": "Italy",
        "studio_name": "Studio Riera",
        "discipline": "Lighting",
        "bio": "Milan-based lighting designer of Catalan origin. Creating ambient installations that blur the line between art and functional design.",
        "avatar_color": "#C2B5A2",
        "banner_color": "#DDD0BD",
        "website": "https://studioriera.it",
        "instagram": "@anna.riera.light",
    },
    {
        "username": "carla_pujol",
        "email": "carla@test.com",
        "first_name": "Carla",
        "last_name": "Pujol",
        "role": "seller",
        "city": "Lisbon",
        "country": "Portugal",
        "studio_name": "Pujol & Co",
        "discipline": "Decor",
        "bio": "Home decor designer combining Portuguese azulejo traditions with minimalist Scandinavian aesthetics. Handmade pieces for conscious living spaces.",
        "avatar_color": "#7B8FA0",
        "banner_color": "#9BAFC0",
        "website": "https://pujolco.pt",
        "instagram": "@carla.pujol.decor",
    },
    {
        "username": "guillem_roca",
        "email": "guillem@test.com",
        "first_name": "Guillem",
        "last_name": "Roca",
        "role": "both",
        "city": "Palma",
        "country": "Spain",
        "studio_name": "Roca Watercolours",
        "discipline": "Watercolour",
        "bio": "Watercolour artist capturing the light and landscapes of the Balearic Islands. Limited edition prints and original works available.",
        "avatar_color": "#5A7B8A",
        "banner_color": "#7A9BAA",
        "website": "https://guillemroca.com",
        "instagram": "@guillem.roca.art",
    },
    {
        "username": "sofia_vidal",
        "email": "sofia@test.com",
        "first_name": "Sofia",
        "last_name": "Vidal",
        "role": "collector",
        "city": "Barcelona",
        "country": "Spain",
        "studio_name": None,
        "discipline": None,
        "bio": "Art collector and interior design enthusiast. Always looking for unique handcrafted pieces to complement contemporary spaces.",
        "avatar_color": "#A06B5A",
        "banner_color": "#C08B7A",
    },
    {
        "username": "xavi_mas",
        "email": "xavi@test.com",
        "first_name": "Xavi",
        "last_name": "Mas",
        "role": "collector",
        "city": "Bilbao",
        "country": "Spain",
        "studio_name": None,
        "discipline": None,
        "bio": "Design lover based in Bilbao. Passionate about supporting local artisans and contemporary craft.",
        "avatar_color": "#4A5A3E",
        "banner_color": "#6A7A5E",
    },
    {
        "username": "baarrero",
        "email": "baarrero@test.com",
        "first_name": "Arnau",
        "last_name": "Barrero",
        "role": "both",
        "city": "Barcelona",
        "country": "Spain",
        "studio_name": None,
        "discipline": None,
        "bio": "Founder and developer of Chosen Object. Passionate about connecting artisans with collectors worldwide.",
        "avatar_color": "#2E2520",
        "banner_color": "#4A3F35",
    },
]

# Pairs of (follower_username, following_username)
FOLLOWS = [
    ("sofia_vidal", "elena_marti"),
    ("sofia_vidal", "jordi_canudas"),
    ("sofia_vidal", "marta_sala"),
    ("sofia_vidal", "laia_font"),
    ("sofia_vidal", "anna_riera"),
    ("xavi_mas", "elena_marti"),
    ("xavi_mas", "marc_esteve"),
    ("xavi_mas", "pau_vives"),
    ("xavi_mas", "guillem_roca"),
    ("elena_marti", "jordi_canudas"),
    ("elena_marti", "marta_sala"),
    ("elena_marti", "marc_esteve"),
    ("jordi_canudas", "elena_marti"),
    ("jordi_canudas", "laia_font"),
    ("marta_sala", "elena_marti"),
    ("marta_sala", "pau_vives"),
    ("marta_sala", "anna_riera"),
    ("pau_vives", "marta_sala"),
    ("pau_vives", "carla_pujol"),
    ("laia_font", "anna_riera"),
    ("laia_font", "elena_marti"),
    ("nuria_coll", "elena_marti"),
    ("nuria_coll", "jordi_canudas"),
    ("nuria_coll", "marc_esteve"),
    ("nuria_coll", "laia_font"),
    ("nuria_coll", "pau_vives"),
    ("nuria_coll", "anna_riera"),
    ("nuria_coll", "guillem_roca"),
    ("marc_esteve", "elena_marti"),
    ("marc_esteve", "jordi_canudas"),
    ("anna_riera", "laia_font"),
    ("anna_riera", "elena_marti"),
    ("carla_pujol", "anna_riera"),
    ("carla_pujol", "elena_marti"),
    ("guillem_roca", "elena_marti"),
    ("guillem_roca", "marc_esteve"),
    ("baarrero", "elena_marti"),
    ("baarrero", "jordi_canudas"),
    ("baarrero", "laia_font"),
    ("baarrero", "anna_riera"),
    ("baarrero", "marc_esteve"),
]

# Sample pieces for sellers
PIECES = [
    {
        "seller": "elena_marti",
        "title": "Vessel Nº 7",
        "edition": "1/12",
        "year": "2024",
        "discipline": "Ceramic",
        "price_cents": 34000,
        "stock": 3,
        "rental": False,
        "description": "Hand-thrown stoneware vessel with ash glaze. Each piece in this edition is unique due to the firing process.",
        "packaging": "Custom wooden crate",
        "ships_to": "EU,UK,US",
    },
    {
        "seller": "elena_marti",
        "title": "Terra Bowl",
        "edition": "Open",
        "year": "2024",
        "discipline": "Ceramic",
        "price_cents": 18500,
        "stock": 8,
        "rental": True,
        "rental_daily_rate_cents": 1200,
        "description": "Large decorative bowl in unglazed terracotta. Inspired by prehistoric Mediterranean pottery.",
        "packaging": "Recycled cardboard",
        "ships_to": "EU,UK",
    },
    {
        "seller": "jordi_canudas",
        "title": "Cadira Llenya",
        "edition": "Unique",
        "year": "2023",
        "discipline": "Furniture",
        "price_cents": 127000,
        "stock": 1,
        "rental": True,
        "rental_daily_rate_cents": 8500,
        "description": "Lounge chair in solid walnut with hand-woven hemp seat. Traditional Catalan joinery without glue or screws.",
        "packaging": "Blanket wrapped, white glove delivery",
        "ships_to": "EU",
    },
    {
        "seller": "jordi_canudas",
        "title": "Taula Petita",
        "edition": "1/5",
        "year": "2024",
        "discipline": "Furniture",
        "price_cents": 89000,
        "stock": 2,
        "rental": False,
        "description": "Side table in reclaimed oak with live edge. Each piece shaped by the natural grain of the wood.",
        "packaging": "Custom crate",
        "ships_to": "EU,UK",
    },
    {
        "seller": "marta_sala",
        "title": "Crater Series III",
        "edition": "1/6",
        "year": "2024",
        "discipline": "Ceramic",
        "price_cents": 42000,
        "stock": 2,
        "rental": True,
        "rental_daily_rate_cents": 2800,
        "description": "Sculptural vase with volcanic texture glaze. Part of an ongoing exploration of geological forms.",
        "packaging": "Custom foam insert",
        "ships_to": "EU,UK,US",
    },
    {
        "seller": "pau_vives",
        "title": "Teixit Mar",
        "edition": "Open",
        "year": "2024",
        "discipline": "Textiles",
        "price_cents": 22000,
        "stock": 5,
        "rental": False,
        "description": "Hand-woven wall tapestry in organic cotton and linen. Dyed with indigo and walnut husks.",
        "packaging": "Rolled in acid-free tissue",
        "ships_to": "EU,UK,US",
    },
    {
        "seller": "pau_vives",
        "title": "Coixí Tramuntana",
        "edition": "Open",
        "year": "2023",
        "discipline": "Textiles",
        "price_cents": 9500,
        "stock": 12,
        "rental": False,
        "description": "Handwoven cushion cover in natural linen with geometric pattern inspired by wind erosion.",
        "packaging": "Cotton dust bag",
        "ships_to": "EU,UK,US",
    },
    {
        "seller": "laia_font",
        "title": "Llum Suspesa",
        "edition": "1/3",
        "year": "2024",
        "discipline": "Lighting",
        "price_cents": 78000,
        "stock": 1,
        "rental": True,
        "rental_daily_rate_cents": 5200,
        "description": "Pendant lamp in recycled brass with handblown amber glass. Creates a warm, atmospheric glow.",
        "packaging": "Custom hardcase",
        "ships_to": "EU,UK",
    },
    {
        "seller": "laia_font",
        "title": "Aplique Ombra",
        "edition": "Open",
        "year": "2024",
        "discipline": "Lighting",
        "price_cents": 45000,
        "stock": 4,
        "rental": True,
        "rental_daily_rate_cents": 3000,
        "description": "Wall sconce in patinated brass casting intricate shadow patterns. Dimmable LED module included.",
        "packaging": "Recycled cardboard",
        "ships_to": "EU,UK,US",
    },
    {
        "seller": "marc_esteve",
        "title": "Forma Orgànica V",
        "edition": "Unique",
        "year": "2023",
        "discipline": "Sculpture",
        "price_cents": 185000,
        "stock": 1,
        "rental": True,
        "rental_daily_rate_cents": 12000,
        "description": "Abstract sculpture in Girona marble. Inspired by river-worn stones and geological time.",
        "packaging": "White glove delivery",
        "ships_to": "EU",
    },
    {
        "seller": "marc_esteve",
        "title": "Tors Petit",
        "edition": "1/4",
        "year": "2024",
        "discipline": "Sculpture",
        "price_cents": 56000,
        "stock": 2,
        "rental": False,
        "description": "Small bronze torso on walnut base. Cast using traditional lost-wax technique.",
        "packaging": "Custom wooden crate",
        "ships_to": "EU,UK",
    },
    {
        "seller": "anna_riera",
        "title": "Nuvola Floor Lamp",
        "edition": "1/8",
        "year": "2024",
        "discipline": "Lighting",
        "price_cents": 95000,
        "stock": 3,
        "rental": True,
        "rental_daily_rate_cents": 6300,
        "description": "Floor lamp in brushed steel with cloud-shaped opal glass diffuser. Adjustable height mechanism.",
        "packaging": "Custom flight case",
        "ships_to": "EU,UK,US",
    },
    {
        "seller": "carla_pujol",
        "title": "Azul Tray Set",
        "edition": "Open",
        "year": "2024",
        "discipline": "Decor",
        "price_cents": 15500,
        "stock": 10,
        "rental": False,
        "description": "Set of three nesting trays in hand-painted ceramic with Portuguese azulejo-inspired pattern.",
        "packaging": "Gift box",
        "ships_to": "EU,UK,US",
    },
    {
        "seller": "carla_pujol",
        "title": "Espelho Lua",
        "edition": "1/10",
        "year": "2023",
        "discipline": "Decor",
        "price_cents": 32000,
        "stock": 4,
        "rental": False,
        "description": "Crescent moon mirror in hand-aged brass frame. Each frame develops a unique patina over time.",
        "packaging": "Blanket wrapped",
        "ships_to": "EU,UK",
    },
    {
        "seller": "guillem_roca",
        "title": "Cala Deià at Dusk",
        "edition": "1/25",
        "year": "2024",
        "discipline": "Watercolour",
        "price_cents": 28000,
        "stock": 10,
        "rental": False,
        "description": "Gicleé print of original watercolour. Archival cotton paper, hand-signed and numbered.",
        "packaging": "Flat, acid-free portfolio",
        "ships_to": "EU,UK,US",
    },
    {
        "seller": "guillem_roca",
        "title": "Serra de Tramuntana (Original)",
        "edition": "Unique",
        "year": "2024",
        "discipline": "Watercolour",
        "price_cents": 145000,
        "stock": 1,
        "rental": True,
        "rental_daily_rate_cents": 9500,
        "description": "Original watercolour on Arches 640gsm. Panoramic landscape of the Tramuntana mountains at golden hour.",
        "packaging": "Museum glass frame, custom crate",
        "ships_to": "EU,UK",
    },
]


def seed():
    now = datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M:%S")

    with Session(engine) as session:
        # ── 1. Create users ────────────────────────────────────
        print("Creating users...")
        user_ids = {}

        for u in USERS:
            # Check if already exists
            existing = session.execute(
                text("SELECT id FROM users WHERE username = :un"),
                {"un": u["username"]},
            ).fetchone()
            if existing:
                user_ids[u["username"]] = existing[0]
                print(f"  [exists] {u['username']} (id={existing[0]})")
                continue

            session.execute(
                text("""
                    INSERT INTO users (
                        username, email, hashed_password, role,
                        first_name, last_name, city, country,
                        studio_name, discipline, bio,
                        website, instagram,
                        avatar_type, avatar_color,
                        banner_type, banner_color,
                        email_verified, is_active,
                        created_at, updated_at
                    ) VALUES (
                        :username, :email, :hashed_password, :role,
                        :first_name, :last_name, :city, :country,
                        :studio_name, :discipline, :bio,
                        :website, :instagram,
                        'color', :avatar_color,
                        'color', :banner_color,
                        1, 1,
                        :now, :now
                    )
                """),
                {
                    "username": u["username"],
                    "email": u["email"],
                    "hashed_password": BAARRERO_PASSWORD if u["username"] == "baarrero" else COMMON_PASSWORD,
                    "role": u["role"],
                    "first_name": u["first_name"],
                    "last_name": u["last_name"],
                    "city": u["city"],
                    "country": u["country"],
                    "studio_name": u.get("studio_name"),
                    "discipline": u.get("discipline"),
                    "bio": u.get("bio"),
                    "website": u.get("website"),
                    "instagram": u.get("instagram"),
                    "avatar_color": u["avatar_color"],
                    "banner_color": u["banner_color"],
                    "now": now,
                },
            )
            session.flush()
            row = session.execute(
                text("SELECT id FROM users WHERE username = :un"),
                {"un": u["username"]},
            ).fetchone()
            user_ids[u["username"]] = row[0]
            print(f"  [created] {u['username']} (id={row[0]})")

        session.commit()

        # ── 2. Create follows ──────────────────────────────────
        print("\nCreating follows...")
        for follower_un, following_un in FOLLOWS:
            fid = user_ids.get(follower_un)
            tid = user_ids.get(following_un)
            if not fid or not tid:
                continue

            existing = session.execute(
                text(
                    "SELECT id FROM follows WHERE follower_id = :f AND following_id = :t"
                ),
                {"f": fid, "t": tid},
            ).fetchone()
            if existing:
                continue

            session.execute(
                text("""
                    INSERT INTO follows (follower_id, following_id, created_at)
                    VALUES (:f, :t, :now)
                """),
                {"f": fid, "t": tid, "now": now},
            )

        session.commit()
        print(f"  {len(FOLLOWS)} follow relationships created/verified")

        # ── 3. Create pieces ───────────────────────────────────
        print("\nCreating pieces...")
        for p in PIECES:
            seller_id = user_ids.get(p["seller"])
            if not seller_id:
                continue

            # Check if piece with same title by same user exists
            existing = session.execute(
                text(
                    "SELECT id FROM pieces WHERE user_id = :uid AND title = :t"
                ),
                {"uid": seller_id, "t": p["title"]},
            ).fetchone()
            if existing:
                print(f"  [exists] {p['title']} by {p['seller']}")
                continue

            session.execute(
                text("""
                    INSERT INTO pieces (
                        user_id, title, edition, year, discipline,
                        price_cents, stock, rental, rental_daily_rate_cents,
                        description, packaging, ships_to,
                        created_at, updated_at
                    ) VALUES (
                        :user_id, :title, :edition, :year, :discipline,
                        :price_cents, :stock, :rental, :rental_daily_rate_cents,
                        :description, :packaging, :ships_to,
                        :now, :now
                    )
                """),
                {
                    "user_id": seller_id,
                    "title": p["title"],
                    "edition": p.get("edition"),
                    "year": p.get("year"),
                    "discipline": p.get("discipline"),
                    "price_cents": p["price_cents"],
                    "stock": p.get("stock", 1),
                    "rental": 1 if p.get("rental") else 0,
                    "rental_daily_rate_cents": p.get("rental_daily_rate_cents"),
                    "description": p.get("description"),
                    "packaging": p.get("packaging"),
                    "ships_to": p.get("ships_to"),
                    "now": now,
                },
            )
            print(f"  [created] {p['title']} by {p['seller']}")

        session.commit()

    print("\n--- Seed complete! ---")
    print(f"Users: {len(USERS)} | Follows: {len(FOLLOWS)} | Pieces: {len(PIECES)}")
    print("\nAll users have password: Test1234!")
    print("Usernames: " + ", ".join(u["username"] for u in USERS))


if __name__ == "__main__":
    seed()

"""Finish the Godot capture as a 1080p H.264/AAC cinematic trailer."""

from pathlib import Path
import subprocess

from PIL import Image, ImageDraw, ImageFont


ROOT = Path(__file__).resolve().parents[1]
TRAILER = ROOT / "trailer"
WORK = ROOT / ".tools" / "trailer-video"
FFMPEG = WORK / "ffmpeg.exe"
RAW = WORK / "raw.avi"
OUT = TRAILER / "Overkill_Cinematic_Gameplay_Trailer_2026-09-30.mp4"
OVERLAYS = WORK / "overlays"
OVERLAYS.mkdir(parents=True, exist_ok=True)

GEORGIA = "C:/Windows/Fonts/georgia.ttf"
GEORGIA_BOLD = "C:/Windows/Fonts/georgiab.ttf"
SEGOE = "C:/Windows/Fonts/segoeui.ttf"
GOLD = (231, 194, 133, 255)
IVORY = (248, 239, 223, 255)
CYAN = (130, 211, 220, 255)


def canvas(left_width: int, opacity: int = 224) -> Image.Image:
    image = Image.new("RGBA", (1920, 1080), (0, 0, 0, 0))
    pixels = image.load()
    for x in range(left_width):
        alpha = int(opacity * (1 - (x / left_width) ** 2))
        for y in range(1080):
            pixels[x, y] = (5, 13, 24, alpha)
    return image


def caption(image: Image.Image, kicker: str, lines: list[str], sub: str, top: int) -> None:
    draw = ImageDraw.Draw(image)
    small = ImageFont.truetype(SEGOE, 24)
    large = ImageFont.truetype(GEORGIA_BOLD, 78)
    body = ImageFont.truetype(SEGOE, 29)
    draw.line((78, top, 425, top), fill=GOLD, width=4)
    draw.text((80, top + 20), kicker, font=small, fill=CYAN)
    y = top + 84
    for line in lines:
        draw.text((74, y), line, font=large, fill=IVORY, stroke_width=1, stroke_fill=(8, 15, 25, 255))
        y += 96
    draw.text((80, y + 20), sub, font=body, fill=GOLD)


intro = canvas(1120, 245)
caption(intro, "THE CLOCK HAS NO MERCY", ["WHEN DEATH", "ISN'T ENOUGH."], "Every excess wound becomes power.", 418)
intro.save(OVERLAYS / "intro.png")

mechanic = Image.new("RGBA", (1920, 1080), (0, 0, 0, 0))
draw = ImageDraw.Draw(mechanic)
for y in range(770, 1080):
    alpha = int(220 * (y - 770) / 310)
    draw.line((0, y, 1919, y), fill=(4, 12, 22, alpha))
draw.line((78, 866, 542, 866), fill=GOLD, width=4)
draw.text((78, 889), "EXCESS DAMAGE BECOMES CURRENCY", font=ImageFont.truetype(GEORGIA_BOLD, 48), fill=IVORY)
draw.text((81, 960), "Strike past lethal. Bank Overkill.", font=ImageFont.truetype(SEGOE, 29), fill=CYAN)
mechanic.save(OVERLAYS / "mechanic.png")

outro = canvas(1160, 247)
caption(outro, "BEND TIME  /  TAKE THE EXCESS", ["OVERKILL"], "The clock is yours to break.", 564)
outro.save(OVERLAYS / "outro.png")

inputs = [
    "-i", str(RAW),
    "-framerate", "30", "-loop", "1", "-i", str(OVERLAYS / "intro.png"),
    "-framerate", "30", "-loop", "1", "-i", str(OVERLAYS / "mechanic.png"),
    "-framerate", "30", "-loop", "1", "-i", str(OVERLAYS / "outro.png"),
    "-stream_loop", "-1", "-i", str(ROOT / "assets/audio/clockwork_nocturne.wav"),
    "-i", str(ROOT / "assets/audio/combat/reveal.wav"),
    "-i", str(ROOT / "assets/audio/combat/strike.wav"),
    "-i", str(ROOT / "assets/audio/combat/shatter.wav"),
    "-i", str(ROOT / "assets/audio/combat/victory.wav"),
]

filters = ";".join([
    "[0:v]format=yuv420p[game]",
    "[1:v]format=rgba,fade=t=in:st=0:d=0.24:alpha=1,fade=t=out:st=2.4:d=0.4:alpha=1[intro]",
    "[game][intro]overlay=0:0:enable='between(t,0,2.8)'[v1]",
    "[2:v]format=rgba,fade=t=in:st=15.2:d=0.18:alpha=1,fade=t=out:st=17.0:d=0.25:alpha=1[mechanic]",
    "[v1][mechanic]overlay=0:0:enable='between(t,15.2,17.25)'[v2]",
    "[3:v]format=rgba,fade=t=in:st=41.65:d=0.28:alpha=1,fade=t=out:st=43.9:d=0.42:alpha=1[outro]",
    "[v2][outro]overlay=0:0:enable='between(t,41.65,44.33)'[v]",
    "[4:a]volume=0.70,atrim=duration=44.33,afade=t=in:st=0:d=0.8,afade=t=out:st=41.3:d=3.0[music]",
    "[5:a]volume=0.48,adelay=9430:all=1[reveal]",
    "[6:a]volume=0.75,adelay=15230:all=1[strike]",
    "[7:a]volume=0.55,adelay=15500:all=1[shatter]",
    "[8:a]volume=0.46,adelay=33130:all=1[victory]",
    "[music][reveal][strike][shatter][victory]amix=inputs=5:duration=first:normalize=0,alimiter=limit=0.93,aresample=48000[a]",
])

cmd = [
    str(FFMPEG), "-hide_banner", "-y", *inputs,
    "-filter_complex", filters,
    "-map", "[v]", "-map", "[a]",
    "-t", "44.33", "-r", "30", "-c:v", "libx264", "-preset", "medium", "-crf", "18",
    "-pix_fmt", "yuv420p", "-color_range", "tv", "-c:a", "aac", "-b:a", "192k",
    "-movflags", "+faststart", str(OUT),
]

print("Rendering", OUT, flush=True)
subprocess.run(cmd, check=True, cwd=ROOT)
print("TRAILER_MP4_OK", OUT, flush=True)

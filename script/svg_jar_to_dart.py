#!/usr/bin/env python3
"""Переводит контуры стаканов из `.claude/my_docs/jars/jar_*.svg` (Claude
Design, поле 360×540, стенка 15 px, внутренняя область x 35…325, y 0…510)
в Dart-константы `domain/lib/models/jar_shape_data.dart`.

Берётся ВНУТРЕННИЙ контур стенки (вторая половина пути: от (325,0) вниз по
дну до (35,0)), кривые Q/C распрямляются в отрезки, координаты нормируются
(x: 0…1 по внутренней ширине 290, y: 0…1 по высоте 510) и записываются в
порядке «верх левой стенки → дно → верх правой стенки». Остальные пути
файла (полка, платформа) — замкнутые «extras».

Запуск: python3 script/svg_jar_to_dart.py
"""
import math
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT / '.claude/my_docs/jars'
OUT = ROOT / 'domain/lib/models/jar_shape_data.dart'

INNER_LEFT, INNER_RIGHT, INNER_BOTTOM = 35.0, 325.0, 510.0
INNER_W = INNER_RIGHT - INNER_LEFT

# id → (файл, звёзд для открытия, «скоро»)
JARS = [
    ('classic', 'jar_1_classic.svg', 0, False),
    ('vase', 'jar_2_vase.svg', 0, False),
    ('bowl', 'jar_3_bowl.svg', 0, False),
    ('shelf', 'jar_4_shelf.svg', 0, False),
    ('flask', 'jar_5_flask.svg', 10, False),
    ('slope', 'jar_6_slope.svg', 25, False),
    ('hourglass', 'jar_7_hourglass.svg', 45, False),
    ('swing', 'jar_8_swing.svg', 70, True),
]

TOKEN = re.compile(r'[MmLlHhVvQqCcZz]|-?\d*\.?\d+(?:e-?\d+)?')


def bezier_q(p0, p1, p2, t):
    u = 1 - t
    return (u * u * p0[0] + 2 * u * t * p1[0] + t * t * p2[0],
            u * u * p0[1] + 2 * u * t * p1[1] + t * t * p2[1])


def bezier_c(p0, p1, p2, p3, t):
    u = 1 - t
    return (u ** 3 * p0[0] + 3 * u * u * t * p1[0] + 3 * u * t * t * p2[0] + t ** 3 * p3[0],
            u ** 3 * p0[1] + 3 * u * u * t * p1[1] + 3 * u * t * t * p2[1] + t ** 3 * p3[1])


def segments_for(ctrl):
    length = sum(math.dist(ctrl[i], ctrl[i + 1]) for i in range(len(ctrl) - 1))
    return max(3, min(14, math.ceil(length / 25)))


def flatten(d):
    """Путь → список точек (абсолютные команды M L H V Q C Z)."""
    toks = TOKEN.findall(d)
    pts, i, cmd, cur = [], 0, None, (0.0, 0.0)
    while i < len(toks):
        if toks[i].isalpha():
            cmd = toks[i]
            i += 1
            if cmd in 'Zz':
                continue
        if cmd == 'M':
            cur = (float(toks[i]), float(toks[i + 1])); i += 2; pts.append(cur); cmd = 'L'
        elif cmd == 'L':
            cur = (float(toks[i]), float(toks[i + 1])); i += 2; pts.append(cur)
        elif cmd == 'H':
            cur = (float(toks[i]), cur[1]); i += 1; pts.append(cur)
        elif cmd == 'V':
            cur = (cur[0], float(toks[i])); i += 1; pts.append(cur)
        elif cmd == 'Q':
            c1 = (float(toks[i]), float(toks[i + 1])); p = (float(toks[i + 2]), float(toks[i + 3])); i += 4
            n = segments_for([cur, c1, p])
            pts.extend(bezier_q(cur, c1, p, k / n) for k in range(1, n + 1)); cur = p
        elif cmd == 'C':
            c1 = (float(toks[i]), float(toks[i + 1])); c2 = (float(toks[i + 2]), float(toks[i + 3]))
            p = (float(toks[i + 4]), float(toks[i + 5])); i += 6
            n = segments_for([cur, c1, c2, p])
            pts.extend(bezier_c(cur, c1, c2, p, k / n) for k in range(1, n + 1)); cur = p
        else:
            raise ValueError(f'unsupported command {cmd!r}')
    return pts


def dedupe(pts, eps=0.5):
    out = []
    for p in pts:
        if not out or math.dist(out[-1], p) > eps:
            out.append(p)
    return out


def inner_contour(pts):
    """Вторая половина пути: между 3-й и 4-й вершинами на y = 0."""
    tops = [i for i, p in enumerate(pts) if abs(p[1]) < 1e-6]
    if len(tops) < 4:
        raise ValueError(f'expected 4 vertices on y=0, got {len(tops)}')
    inner = pts[tops[2]:tops[3] + 1]
    return list(reversed(inner))  # слева направо


def norm(p):
    return ((p[0] - INNER_LEFT) / INNER_W, p[1] / INNER_BOTTOM)


def fmt(p):
    return f'JarPoint({p[0]:.4f}, {p[1]:.4f})'


def main():
    paths_re = re.compile(r'<path d="([^"]+)"')
    circle_re = re.compile(r'<circle cx="([\d.]+)" cy="([\d.]+)"')
    out = ['// Сгенерировано script/svg_jar_to_dart.py из .claude/my_docs/jars/*.svg —',
           '// не править руками; контуры стаканов в нормированных координатах',
           '// внутренней области (x 0…1 слева направо, y 0…1 сверху вниз).',
           '',
           "part of 'jar_shape.dart';",
           '']
    for jid, file, stars, soon in JARS:
        svg = (SRC / file).read_text()
        paths = paths_re.findall(svg)
        first = flatten(paths[0])
        if sum(1 for q in first if abs(q[1]) < 1e-6) >= 4:
            wall = dedupe(inner_contour(first))
            rest = paths[1:]
        else:
            # Стенки отдельными путями без дна («Качели»): контур —
            # прямоугольник, дно — платформа из extras.
            wall = [(INNER_LEFT, 0.0), (INNER_LEFT, INNER_BOTTOM),
                    (INNER_RIGHT, INNER_BOTTOM), (INNER_RIGHT, 0.0)]
            rest = paths[2:]
        extras = [dedupe(flatten(d)) for d in rest]
        pivot = circle_re.search(svg)
        w = [norm(p) for p in wall]
        out.append(f'const JarShape _{jid} = JarShape(')
        out.append(f"  id: '{jid}',")
        out.append(f'  starsToUnlock: {stars},')
        if soon:
            out.append('  comingSoon: true,')
        out.append('  wall: <JarPoint>[')
        out.extend(f'    {fmt(p)},' for p in w)
        out.append('  ],')
        if extras:
            out.append('  extras: <List<JarPoint>>[')
            for ex in extras:
                # замкнутый путь: последняя точка совпадает с первой — убрать
                if len(ex) > 1 and math.dist(ex[0], ex[-1]) < 0.5:
                    ex = ex[:-1]
                out.append('    <JarPoint>[')
                out.extend(f'      {fmt(norm(p))},' for p in ex)
                out.append('    ],')
            out.append('  ],')
        if pivot:
            px, py = norm((float(pivot.group(1)), float(pivot.group(2))))
            out.append(f'  pivot: JarPoint({px:.4f}, {py:.4f}),')
        out.append(');')
        out.append('')
        print(f'{jid}: {len(w)} wall points, {len(extras)} extras', file=sys.stderr)
    out.append('const List<JarShape> _all = <JarShape>[')
    out.extend(f'  _{jid},' for jid, *_ in JARS)
    out.append('];')
    OUT.write_text('\n'.join(out) + '\n')
    print(f'→ {OUT.relative_to(ROOT)}', file=sys.stderr)


if __name__ == '__main__':
    main()

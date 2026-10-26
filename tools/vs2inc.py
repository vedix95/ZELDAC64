#!/usr/bin/env python3
"""
tools/vs2inc.py : Convertit un fichier de symboles VICE (.vs) généré par ACME
en un fichier d'inclusion ACME (.inc) définissant tous les labels résidents.
"""

import sys
import os
import re

def convert_vs_to_inc(vs_path, inc_path):
    if not os.path.exists(vs_path):
        print(f"Erreur : {vs_path} n'existe pas")
        sys.exit(1)

    symbols = {}
    with open(vs_path, "r", encoding="utf-8", errors="ignore") as f:
        for line in f:
            m = re.match(r'al C:([0-9a-fA-F]+) \.([a-zA-Z0-9_]+)', line.strip())
            if m:
                addr_hex = m.group(1)
                name = m.group(2)
                # Éviter les labels locaux commençant par un point
                if not name.startswith('.'):
                    symbols[name] = addr_hex

    lines = [
        "; ---------------------------------------------------------------------------\n",
        f"; GENERE AUTOMATIQUEMENT par tools/vs2inc.py depuis {os.path.basename(vs_path)}\n",
        "; Ne pas modifier manuellement.\n",
        "; ---------------------------------------------------------------------------\n\n"
    ]

    for name in sorted(symbols.keys()):
        val = int(symbols[name], 16)
        if val < 256:
            lines.append(f"{name:32s} = ${val:02x}\n")
        else:
            lines.append(f"{name:32s} = ${val:04x}\n")

    os.makedirs(os.path.dirname(os.path.abspath(inc_path)), exist_ok=True)
    with open(inc_path, "w", encoding="utf-8") as f:
        f.writelines(lines)

    print(f"  [+] {len(symbols)} symboles résidents exportés vers {inc_path}")

def main():
    if len(sys.argv) < 3:
        print("Usage: python3 tools/vs2inc.py <input.vs> <output.inc>")
        sys.exit(1)
    convert_vs_to_inc(sys.argv[1], sys.argv[2])

if __name__ == "__main__":
    main()

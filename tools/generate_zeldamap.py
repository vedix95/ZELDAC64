import random

W, H = 16, 8
ROOM_W, ROOM_H = 20, 10

class World:
    def __init__(self):
        # Grille globale 320x80
        self.map = [['#' for _ in range(W * ROOM_W)] for _ in range(H * ROOM_H)]
        self.room_types = [['normal' for _ in range(W)] for _ in range(H)]
        
    def carve_room(self, rx, ry, style='grass'):
        # On remplit la salle avec une bordure
        for y in range(ROOM_H):
            for x in range(ROOM_W):
                gx, gy = rx * ROOM_W + x, ry * ROOM_H + y
                
                is_border = (x == 0 or x == ROOM_W-1 or y == 0 or y == ROOM_H-1)
                
                if is_border:
                    self.map[gy][gx] = '#' if ry < H//2 else 'T'
                else:
                    self.map[gy][gx] = '.'
                    
        # On ajoute des éléments selon le biome
        if style == 'forest':
            for y in range(2, ROOM_H-2):
                for x in range(2, ROOM_W-2):
                    if random.random() < 0.4: self.map[ry*ROOM_H + y][rx*ROOM_W + x] = 'T'
        elif style == 'water':
            for y in range(2, ROOM_H-2):
                for x in range(2, ROOM_W-2):
                    if random.random() < 0.8: self.map[ry*ROOM_H + y][rx*ROOM_W + x] = '~'
        elif style == 'mountain':
            for y in range(2, ROOM_H-2):
                for x in range(2, ROOM_W-2):
                    if random.random() < 0.3: self.map[ry*ROOM_H + y][rx*ROOM_W + x] = '#'

    def connect_rooms(self, rx1, ry1, rx2, ry2):
        if rx1 == rx2: # Connexion Verticale
            ymin = min(ry1, ry2)
            for x in range(ROOM_W//2 - 2, ROOM_W//2 + 2):
                self.map[ymin*ROOM_H + ROOM_H - 1][rx1*ROOM_W + x] = '.'
                self.map[(ymin+1)*ROOM_H][rx1*ROOM_W + x] = '.'
        elif ry1 == ry2: # Connexion Horizontale
            xmin = min(rx1, rx2)
            for y in range(ROOM_H//2 - 1, ROOM_H//2 + 1):
                self.map[ry1*ROOM_H + y][xmin*ROOM_W + ROOM_W - 1] = '.'
                self.map[ry1*ROOM_H + y][(xmin+1)*ROOM_W] = '.'

    def generate(self):
        # 1. Assigner les biomes
        for ry in range(H):
            for rx in range(W):
                if ry < 2: style = 'mountain'
                elif ry > 5: style = 'forest'
                elif 3 <= rx <= 6 and 2 <= ry <= 5: style = 'water'
                else: style = 'grass'
                
                if rx == 7 and ry == 7: style = 'start'
                
                self.room_types[ry][rx] = style
                self.carve_room(rx, ry, style)

        # 2. Ajouter des décorations
        for ry in range(H):
            for rx in range(W):
                for y in range(1, ROOM_H-1):
                    for x in range(1, ROOM_W-1):
                        gx, gy = rx * ROOM_W + x, ry * ROOM_H + y
                        if self.map[gy][gx] == '.':
                            r = random.random()
                            if r < 0.05: self.map[gy][gx] = 'f'
                            elif r < 0.1: self.map[gy][gx] = ','

        # 3. Créer un labyrinthe parfait (spanning tree) pour que tout soit accessible
        visited = set()
        stack = [(7, 7)]
        visited.add((7, 7))
        
        while stack:
            cx, cy = stack[-1]
            neighbors = []
            for dx, dy in [(0,1), (0,-1), (1,0), (-1,0)]:
                nx, ny = cx + dx, cy + dy
                if 0 <= nx < W and 0 <= ny < H and (nx, ny) not in visited:
                    neighbors.append((nx, ny))
            
            if neighbors:
                nx, ny = random.choice(neighbors)
                visited.add((nx, ny))
                self.connect_rooms(cx, cy, nx, ny)
                stack.append((nx, ny))
            else:
                stack.pop()

        # Ajouter des boucles supplémentaires pour ne pas avoir de culs-de-sac partout
        for _ in range(50):
            cx, cy = random.randint(0, W-1), random.randint(0, H-1)
            dx, dy = random.choice([(0,1), (1,0)])
            nx, ny = cx + dx, cy + dy
            if 0 <= nx < W and 0 <= ny < H:
                self.connect_rooms(cx, cy, nx, ny)

        # 4. Aménager la salle de départ
        gx, gy = 7 * ROOM_W, 7 * ROOM_H
        self.map[gy + 2][gx + 9] = 'O'
        self.map[gy + 2][gx + 10] = 'O'
        for dy in range(1, 5):
            for dx in range(7, 13):
                if self.map[gy+dy][gx+dx] != 'O':
                    self.map[gy+dy][gx+dx] = '.'

    def save(self, filename):
        with open(filename, "w") as f:
            f.write("; ===========================================================================\n")
            f.write("; CARTE OVERWORLD PROCEDURALE (ZELDA) - 16 x 8 ECRANS (128 SALLES)\n")
            f.write("; ===========================================================================\n")
            
            for ry in range(H):
                f.write(f"\n; RANGÉE {ry}\n")
                for y in range(ROOM_H):
                    line = []
                    for rx in range(W):
                        chunk = "".join(self.map[ry*ROOM_H + y][rx*ROOM_W : (rx+1)*ROOM_W])
                        line.append(chunk)
                    f.write(" ".join(line) + "\n")

if __name__ == "__main__":
    w = World()
    w.generate()
    w.save("assets/world.txt")
    print("Carte générée avec succès dans assets/world.txt")

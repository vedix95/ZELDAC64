with open('src/intro.asm', 'r') as f:
    text = f.read()

target = """        ldx intro_pan_step
        cpx #3
        bcc .inject_lake
        beq .inject_scroll_top
        cpx #4
        beq .inject_scroll_title
        cpx #5
        beq .inject_scroll_sep
        cpx #23
        beq .inject_scroll_bot"""

replacement = """        ldx intro_pan_step
        cpx #3
        bcs +
        jmp .inject_lake
+       bne +
        jmp .inject_scroll_top
+       cpx #4
        bne +
        jmp .inject_scroll_title
+       cpx #5
        bne +
        jmp .inject_scroll_sep
+       cpx #23
        bne +
        jmp .inject_scroll_bot
+"""

text = text.replace(target, replacement)
with open('src/intro.asm', 'w') as f:
    f.write(text)

print("Fixed branch distances with jmp!")

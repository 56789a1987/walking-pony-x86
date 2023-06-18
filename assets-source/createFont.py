#!/usr/bin/python3

from PIL import Image

# create font sprites
fontBuffer = []
fontImage = Image.open("font.png").convert("RGBA")

def addCharRow(data, offset):
	x = 0
	for column in range(8):
		if column != 0:
			x <<= 1
		if data[offset + column][0] == 0xff:
			x |= 1
	fontBuffer.append(x)

for y in range(2, 8):
	for x in range(16):
		charImage = fontImage.crop((x * 8, y * 8, x * 8 + 8, y * 8 + 8))
		data = list(charImage.getdata())
		for line in range(8):
			addCharRow(data, line * 8)

# write to files
fontFile = open("../assets/font.raw", "wb")
fontFile.write(bytes(fontBuffer))
fontFile.close()

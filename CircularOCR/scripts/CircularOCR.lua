--Start of Global Scope---------------------------------------------------------
print('AppEngine Version: ' .. Engine.getVersion())

-- Delay in ms between visualization steps for demonstration purpose only
local DELAY = 2000

-- Creating viewer
local viewer = View.create()

-- Setting up graphical overlay attributes
local shapeDecoration = View.ShapeDecoration.create()
shapeDecoration:setLineColor(0, 255, 0)
shapeDecoration:setLineWidth(1)
local textDeco = View.TextDecoration.create()
textDeco:setSize(20)
textDeco:setColor(0, 255, 0)
local prDeco = View.PixelRegionDecoration.create()
prDeco:setColor(0, 0, 255, 48)

--End of Global Scope-----------------------------------------------------------

--Start of Function and Event Scope---------------------------------------------
local function warpAndDisplaySector(filename, sector)
  -- Load image.
  local image = Image.load(filename)

  -- Get warp sector.
  local warped = Image.warpSector(image, sector)

  -- View original image with sector
  viewer:addImage(image)
  viewer:addShape(sector, shapeDecoration)
  viewer:present()
  Script.sleep(DELAY) -- for demonstration purpose only

  return warped
end

local function drawBoundingBoxes(characters, charRegions)
  for j = 1, #characters do
    local box = charRegions[j]:getBoundingBox()
    viewer:addShape(box, shapeDecoration)
    viewer:present()
    local CoG = box:getCenterOfGravity()
    textDeco:setPosition(CoG:getX() - 5, CoG:getY() + 50)
    viewer:addText(characters:sub(j, j), textDeco)
    viewer:present() -- can be put outside loop if not for demonstration
    Script.sleep(100) -- for demonstration purpose only
  end
end

local function classifyAndDrawCharacters(textLines, warpedSector, regExpStr)
  -- Creating font classifier and select font
  local classifier = Image.OCR.Halcon.FontClassifier.create()
  classifier:setFont('UNIVERSAL_0_9A_ZPLUS_REJ')

  local numLines = Image.OCR.Halcon.SegmenterResult.getNumberOfTextLines(textLines)
  for i = 1, numLines do
    local charRegions = textLines:getTextLine(i - 1)

    -- Classify all found charcters
    local chars, _, _ = classifier:classifyCharacters(charRegions, warpedSector, regExpStr)

    -- Draw bounding boxes and print classified characters
    drawBoundingBoxes(chars, charRegions)
  end
end

local function main()
  local sector = Shape.createSector(Point.create(183, 190), 115, 160, math.pi * 1.05, math.pi * 1.9)
  local warpedSector = warpAndDisplaySector('resources/circleText.png', sector)

  -- View warped image.
  viewer:clear()
  viewer:addImage(warpedSector)
  viewer:present()

  -- Creating and setting up an OCR segmenter
  local segmenter = Image.OCR.Halcon.AutoSegmenter.create()
  segmenter:setParameter('MIN_CHAR_HEIGHT', 14)
  segmenter:setParameter('MAX_CHAR_HEIGHT', 21)
  segmenter:setParameter('MIN_CHAR_WIDTH', 12)
  segmenter:setParameter('MAX_CHAR_WIDTH', 17)
  segmenter:setParameter('RETURN_PUNCTUATION', 'false')
  segmenter:setParameter('MIN_CONTRAST', 5)
  segmenter:setParameter('POLARITY', 'dark_on_light')

  -- Find and segment text in image
  local textRegion = Image.PixelRegion.createRectangle(367, 8, 484, 33)
  viewer:addPixelRegion(textRegion, prDeco)
  viewer:present()
  local textLines = segmenter:findText(warpedSector, textRegion)
  classifyAndDrawCharacters(textLines, warpedSector, '[A-Z]{1}-[0-9]{6}')

  print('App finished.')
end

--The following registration is part of the global scope which runs once after startup
--Registration of the 'main' function to the 'Engine.OnStarted' event
Script.register('Engine.OnStarted', main)

--End of Function and Event Scope--------------------------------------------------

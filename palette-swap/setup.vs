#DEFINE GAME_WIDTH 960
#DEFINE GAME_HEIGHT 540
#DISABLE DEBUG

var uploadedFiles = 0
var fileContent = []
var fileName = []
var frameInfo = { 'maxRows': 15 }
var output
var client
var canvasImageLoaded
var palette_import
var upload_import
var ready = true
var canvas
var busyElement
var imageCounter = 0

Client
	screenBackground = '#23272A'
	mainOutput = 'canvas.output'
	hideFPS = true
	var currentPalette = { 'palette': '', 'paletteA': [], 'paletteO': {} } // palettes that are selected
	var canvasPalette = { 'paletteA': [], 'paletteO': {} } // default palette that came with the image
	var replacedPalette = {}

	onMouseMove(diob, x, y)
		if (this.dragging)
			this.dragging['element'].setPos(x - this.dragging['xOff'], y - this.dragging['yOff'])

	onMouseUp(diob, x, y, button)
		if (this.dragging && button === 1)
			this.dragging = null

	onConnect()
		this.showInterface('canvas')
		output = this.getInterfaceElement('canvas', 'output')
		client = this
		palette_import = this.getInterfaceElement('canvas', 'upload_palette')
		upload_import = this.getInterfaceElement('canvas', 'upload_image')
		canvas = this.getInterfaceElement('canvas', 'canvas')
		busyElement = this.getInterfaceElement('canvas', 'busy')
		JS.makeWorker()

Interface
	var defaultText
	var defaultPos = {'x': 0, 'y': 0}
	layer = 100
	textStyle = {'fill': '#f3f3f3'}

	onMouseDown(client, x, y, button)
		if (this.draggable && button === 1)
			client.dragging = { 'element': this, 'xOff': x, 'yOff': y }

	Upload_Image
		width = 120
		height = 18
		textStyle = { 'fill': '#f3f3f3', 'fontFamily': 'Helvetica', 'fontSize': 13 }
		interfaceType = 'WebBox'

		onShow()
			this.text = '
						<label class="fake-button">
							<input type="file" onchange="handleImage(event)" style="display: none; id="upload_image" accept=".vyi, .png, .jpg, .dmi">
							<div>Upload Image</div>
						</label>
						'
			this.defaultText = this.text
							
	Canvas
		layer = 99
		width = GAME_WIDTH
		height = GAME_HEIGHT
		// mouseOpacity = 0
		interfaceType = 'WebBox'
		var draggable = true

		onMouseClick(client, x, y, button)
			if (button === 3)
				this.setPos(this.defaultPos['x'], this.defaultPos['y'])

		onShow()
			this.defaultPos = { 'x': this.xPos, 'y': this.yPos }
			this.text = '<div class="container"><canvas id="canvas"></canvas></div>'

	Default_Palettes /* Only accepts .pal file types */
		atlasName = 'atlas'
		iconName = 'radio_button_circ'
		iconState = 'off'
		width = 32
		height = 32

		onMouseEnter(client)
			if (client.currentPalette['palette'] === this.name)
				return
			this.iconState = 'mouseover'

		onMouseExit(client)
			if (client.currentPalette['palette'] === this.name)
				return
			this.iconState = 'off'
		onMouseClick(client)
			if (!ready)
				return alert('Palette is currently being swapped')

			if (!canvasImageLoaded)
				return alert('Load a image first')

			if (client.currentPalette['palette'])
				if (client.currentPalette['palette'] === this.name)
					return
				if (client.getInterfaceElement('canvas', client.currentPalette['palette']))
					client.getInterfaceElement('canvas', client.currentPalette['palette']).iconState = 'off'

			palette_import.text = palette_import.defaultText

			var displayName = this.name.replace('_palette', '').toUpperCase()

			switch (displayName)
				case 'DB32':
					client.currentPalette['paletteA'] = DB32
					client.currentPalette['palette'] = this.name
					break
				case 'EDG32':
					client.currentPalette['paletteA'] = EDG32
					client.currentPalette['palette'] = this.name
					break
				case 'PICO8':
					client.currentPalette['paletteA'] = PICO8
					client.currentPalette['palette'] = this.name
					break
				case 'NES':
					client.currentPalette['paletteA'] = NES
					client.currentPalette['palette'] = this.name
					break
				case 'GAMEBOY':
					client.currentPalette['paletteA'] = GAMEBOY
					client.currentPalette['palette'] = this.name
					
			this.iconState = 'on'
			JS.reset()
			JS.WORKER.postMessage({ 'msg': 'extractColor', 'array': client.currentPalette['paletteA'] })

		DB32_palette
		EDG32_palette
		PICO8_palette
		NES_palette
		GAMEBOY_palette

	Text_Labels
		width = 100
		height = 20
		mouseOpacity = 0
		interfaceType = 'WebBox'

		onShow()
			this.text = '<div class="text">' + this.name.toUpperCase() + '</div>'

		DB32_text_label
		EDG32_text_label
		PICO8_text_label
		NES_text_label
		GAMEBOY_text_label

		Tips
			width = 175
			height = 350
			onShow()
				override
				this.text = '<div class="text">• This tool only works with .vyi, .dmi, .png, and .jpg files. <br><br>• The only supported palettes are of the .pal type (for now). Check <a href="https://lospec.com/palette-list">here</a> to download palettes in this format.<br><br>• Tip: If you swapped palettes atleast once, the next swap will be based on the current palette.</div>'

	Custom_Palette
		Upload_Palette
			width = 120
			height = 18
			color = '#2C2F33'
			textStyle = { 'fill': '#f3f3f3', 'fontFamily': 'Helvetica', 'fontSize': 13 }
			interfaceType = 'WebBox'

			onShow()
				this.text = '
							<label class="fake-button">
								<input type="file" onchange="handlePalette(event)" style="display: none; id="upload_palette" accept=".pal">
								<div>Upload Palette</div>
							</label>
							'
				this.defaultText = this.text

	Output
		width = 300
		height = 200
		interfaceType = 'WebBox'
		color = '#f8f7ed'
		mouseOpacity = 0
		textStyle = { 'fill': '#313639' }

	Export
		Export_Button
			interfaceType = 'WebBox'
			width = 120
			height = 18
			textStyle = { 'fill': '#fdfcfc', 'fontFamily': 'Helvetica', 'fontSize': 13 }

			onShow()
				this.text = '
							<label class="fake-button">
								<a id="export">Export</a>
							</label>
							'

	Img
		interfaceType = 'WebBox'
		width = 1
		height = 1

		onShow()
			this.text = '
						<div>
							<img id="image" onload="drawImgToCanvas()" draggable="false">
						</div>
						'

	Busy
		width = GAME_WIDTH
		height = GAME_HEIGHT
		interfaceType = 'WebBox'
		color = '#313639'
		alpha = 0
		textStyle = { 'fill': '#f3f3f3' }


		onShow()
			this.setTransition({ 'alpha': 0.5 }, 5, 50)
			this.text = '<div class="center"><img src="http://bestanimations.com/Science/Gears/silver-gear-cogs-animation-5.gif" width="150" height="150" draggable="false"></div><div class="busy">Working...</div>'

		function beforeHide(json, steps, time)
			this.setTransition(json, steps, time)

			spawn (steps * time)
				this.hide()


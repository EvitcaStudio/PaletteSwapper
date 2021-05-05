#BEGIN JAVASCRIPT

var WORKER

function blobToDataURL(blob) {
	var reader = new FileReader();
	reader.onload = function() {
		var exporter = document.getElementById('export');
		exporter.href = reader.result;
		
		if (!VS.global.fileName[0]) {
			exporter.download = 'palette-changed-to-' + VS.global.client.currentPalette['palette'] + '.png';
		} else {
			exporter.download = 'palette-changed-to-' + VS.global.fileName[0].replace('.pal', '') + '.png';
		}
		VS.global.busyElement.beforeHide({ 'alpha': 0 }, 5, 50);
   }
   reader.readAsDataURL(blob);
}

function makeWorker() {
	var canvas = document.getElementById('canvas');
	var offscreen = canvas.transferControlToOffscreen();

	WORKER = new Worker(VS.Resource.getResourcePath('file', 'worker.js'));
	WORKER.postMessage({ 'canvas': offscreen, 'msg': 'setup' }, [offscreen]);
	WORKER.onmessage = function(e) {
		switch (e.data.msg) {
			case 'findNearestColor':
				var array = e.data.array;
				var obj = e.data.obj;
				var rgb = e.data.rgb;

				VS.global.client.canvasPalette['paletteA'] = array;
				VS.global.client.canvasPalette['paletteO'] = obj;
				VS.global.findNearestColor(rgb['r'], rgb['g'], rgb['b']);
				break;

			case 'getKeys':
				WORKER.postMessage({ 'msg': 'updateKeys', 'keys': VS.Util.getObjectKeys(VS.global.client.replacedPalette), 'palette': VS.global.client.replacedPalette })
				break;

			case 'busy':
				VS.global.ready = false;
				VS.global.busyElement.show();
				// console.log('busy');
				break

			case 'ready':
				var blob = e.data.blob;
				blobToDataURL(blob);
				VS.global.ready = true;
				VS.global.client.outputText('<div class="text">Your selected palette is: ' + VS.global.client.currentPalette['palette'] + '</div>')
				// console.log('ready');
				break;

			case 'loaded':
				VS.global.canvasImageLoaded = true;
				break;

			case 'resizeCanvas':
				var canvas = VS.global.client.getInterfaceElement('canvas', 'canvas')
				VS.global.canvas.width = e.data.width + 20;
				VS.global.canvas.height = e.data.height + 20;
				VS.global.imageCounter = 0;
				document.getElementById('wb_canvas_canvas').style.border = '2px solid #f3f3f3';
				document.getElementById('wb_canvas_canvas').style.overflow = 'hidden';
				canvas.setPos(canvas.defaultPos['x'], canvas.defaultPos['y']);
				// console.log('canvas resized');
				break;
		}
	}
}

function handleImage(event) {
	if (!VS.global.ready) {
		return alert('Palette is currently being swapped');
		VS.global.upload_import.text = VS.global.palette_import.defaultText;
	}

	if (VS.global.client.getInterfaceElement('canvas', VS.global.client.currentPalette['palette'])) {
		VS.global.client.getInterfaceElement('canvas', VS.global.client.currentPalette['palette']).iconState = 'off'
	}

	VS.global.fileContent = []; /* Reset */
	VS.global.fileName = []; /* Reset */
	VS.global.client.currentPalette = { 'palette': '', 'paletteA': [], 'paletteO': {} }; // palettes that are selected
	VS.global.client.canvasPalette = { 'paletteA': [], 'paletteO': {} }; // default palette that came with the image
	VS.global.client.replacedPalette = {};
	VS.global.count = 0;
	WORKER.postMessage({'msg': 'clearCanvas'});

	var selectedFile = event.target.files[0];
	var reader = new FileReader();
	var img = document.getElementById('image');

	if (selectedFile) {
		var extension = event.target.files[0].name.split('.').pop();
	} else {
		VS.global.canvasImageLoaded = false;
		document.getElementById('wb_canvas_canvas').style.border = '';
	}

	if (event.target.files.length === 1) {
		var extension = event.target.files[0].name.split('.').pop();
		
		if (extension !== 'vyi' && extension !== 'dmi' && extension !== 'jpg' && extension !== 'jpeg' && extension !== 'png') { /* If one of the files extension is not = to the supported types */
			VS.global.output.text += '<div class="unsupported">Unsupported image file type.</div>'; /* Notify the uploader */

		} else if (extension === 'vyi') {
			reader.onload = handleVyi; /* Give the onload event to this function based on type*/
			reader.readAsText(event.target.files[0]); /* read the file */
			// VS.global.canvasImageLoaded = true;
			VS.global.output.text += '<div class="text">' + event.target.files[0].name + ' uploaded.</div>'; /* Notify the uploader, the file is uploaded */
			return

		} else if (extension == 'png' || extension == 'jpg' || extension == 'jpeg' || extension == 'dmi') {
			img.title = 'Uploaded image: ' + selectedFile.name;

			reader.onload = function(event) {
				img.src = event.target.result;
			}

			reader.readAsDataURL(selectedFile);
			VS.global.canvasImageLoaded = true;
			VS.global.output.text += '<div class="text">' + event.target.files[0].name + ' uploaded.</div>'; /* Notify the uploader, the file is uploaded */
		}
	}
}

function handlePalette(event) {
	if (!VS.global.ready) {
		VS.global.palette_import.text = VS.global.palette_import.defaultText; /* Reset */
		return alert('Palette is currently being swapped');
	}

	if (!VS.global.canvasImageLoaded) {
		VS.global.palette_import.text = VS.global.palette_import.defaultText; /* Reset */
		return alert('Load a image first');
	}

	VS.global.fileName = [] /* Reset */

	var reader = new FileReader(); /* Create a new file reader object  */
	var extension = event.target.files[0].name.split('.').pop();
	
	if (extension !== 'pal') { /* If the file extension is not .pal */
		VS.global.output.text += '<div class="unsupported">Unsupported palette file type.</div>'; /* Notify the uploader */

	} else if (extension === 'pal') {
		reader.onload = handleUploadedPalette; /* Give the onload event to this function */
		reader.readAsText(event.target.files[0]); /* If the extension is '.pal' read the file */
		VS.global.fileName.push(event.target.files[0].name)
	}
}

function handleVyi(event) {
	var iconData = JSON.parse(event.target.result);
	VS.global.fileContent.push(iconData["i"]);
	VS.global.extractImage(VS.global.fileContent);
}

function drawImgToCanvas() {
	var image = document.getElementById('image');

	VS.global.canvas.width = image.width + 20;
	VS.global.canvas.height = image.height + 20;
	document.getElementById('wb_canvas_canvas').style.border = '2px solid #f3f3f3';
	document.getElementById('wb_canvas_canvas').style.overflow = 'hidden';

	var bitmap = createImageBitmap(image, 0, 0, image.width, image.height);
	bitmap.then(function(result) {
		WORKER.postMessage({ 'msg': 'drawImage', 'info': {'width': image.width, 'height': image.height}, 'bitmap': result })
	});
}

function handleUploadedPalette(event) {
	var fileData = event.target.result;
	var lines = event.target.result.split('\n');
	var list = lines.splice(3, lines.length);

	list.pop();

	if (VS.global.client.getInterfaceElement('canvas', VS.global.client.currentPalette['palette'])) {
		VS.global.client.getInterfaceElement('canvas', VS.global.client.currentPalette['palette']).iconState = 'off';
	}

	VS.global.client.currentPalette['palette'] = VS.global.fileName[0].replace('.pal', '').toUpperCase();
	VS.global.client.currentPalette['paletteA'] = list;

	if (VS.global.canvasImageLoaded) {
		reset();
		WORKER.postMessage({ 'msg': 'extractColor', 'array': list });
	}
}

function reset() {

	VS.global.count = 0;
	VS.global.client.replacedPalette = {};
	VS.global.client.canvasPalette['paletteA'] = [];
	VS.global.client.canvasPalette['paletteO'] = {};
	WORKER.postMessage({ 'msg': 'reset' });
	// console.log('main script reset');

}

function returnRegex(string) {
	return string.match(/\d+/g);
}

function createImage(width, height, base64, array, max) {
	var x = document.createElement('img');
	var src = 'data:image/png;base64,' + base64;
	x.width = width;
	x.height = height;
	x.onload = function() {
		var bitmap = createImageBitmap(x, 0, 0, x.width, x.height);
		bitmap.then((result) => {
			array.push(result);
			VS.global.imageCounter++
			if (VS.global.imageCounter === max) {
				WORKER.postMessage({ 'msg': 'buildSpriteSheet', 'array': array });
			}
		});
	}
	x.src = src;

}

#END JAVASCRIPT

var count = 0

function findNearestColor(r, g, b) // canvas red , green, blue 
	var list = client.currentPalette['paletteA']
	var max = list.length + client.canvasPalette['paletteA'].length
	var loopedOnce

	for (var x = 0, z = 0; z < max; x++)
		if (x === list.length)
			x = 0
			loopedOnce = true

		if (!loopedOnce)
			var placeholder = list[x].split(' ').join(',')
			var e = placeholder
			list[x] = e
			var rgbArray = JS.returnRegex(e)

		else
			var rgbArray = JS.returnRegex(list[x])

		client.currentPalette['paletteO'][Util.toString(z)] = { 'r': rgbArray[0], 'g': rgbArray[1], 'b': rgbArray[2] }
		client.currentPalette['paletteO'][Util.toString(z)]['difference'] = 5000000000
		z++

	for (var c = 0; c < max; c++)
		var variable = Util.toString(c)
		var variable2 = Util.toString(count)
		var r2 = client.currentPalette['paletteO'][variable]['r'] //palette red
		var g2 = client.currentPalette['paletteO'][variable]['g'] //palette green
		var b2 = client.currentPalette['paletteO'][variable]['b'] //palette blue
		var difference = Math.pow((r2 - r) * 0.299, 2) + Math.pow((g2 - g) * 0.587, 2) + Math.pow((b2 - b) * 0.114, 2)

		if (difference < client.currentPalette['paletteO'][variable2]['difference']) /* continue looping through the entire list and find the actual lowest */
			client.currentPalette['paletteO'][variable2]['difference'] = difference /* set to lowest */
			client.replacedPalette['rgb(' + r + ',' + g + ',' + b + ')'] = 'rgb(' + r2 + ',' + g2 + ',' + b2 + ')' /* Replace the color in order */
	count++

function extractImage(fileContent)
	getMaxData(fileContent[0])

function getMaxData(data)
	var count = 0
	foreach (var d in data)
		count++

		if (d.length > 5)
			foreach (var f in d[5]) /* searching frames */
				count++

		if (d.length > 6)
			foreach (var g in d[6]) /* searching states */
				count++

				if (g.length > 3)
					foreach (var h in g[3])
						count++
	return parseFile(data, count)


function parseFile(data, max)
	frameInfo['frames'] = [] /* Create a array for this frame array */
	foreach (var d in data)
		JS.createImage(d[1], d[2], d[4], frameInfo['frames'], max) /* Width, Height, Base64 */

		if (d.length > 5)
			foreach (var f in d[5]) /* searching frames */
				JS.createImage(d[1], d[2], f[0], frameInfo['frames'], max) /* Width, Height, Base64 */

		if (d.length > 6)
			foreach (var g in d[6]) /* searching states */
				JS.createImage(d[1], d[2], g[1], frameInfo['frames'], max) /* Width, Height, Base64 */

				if (g.length > 3)
					foreach (var h in g[3])
						JS.createImage(d[1], d[2], h[0], frameInfo['frames'], max) /* Width, Height, Base64 */
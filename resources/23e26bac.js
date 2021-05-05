onmessage = function(e) {
	switch (e.data.msg) {
		case 'setup':
			self.canvas = e.data.canvas;
			self.context = self.canvas.getContext('2d');
			self.keys = [];
			self.replacedPalette = {};
			self.maxRows = 15;
			// console.log('offscreen canvas setup complete')
			break;

		case 'reset': 
			reset();
			break;

		case 'clearCanvas':
			self.context.clearRect(0, 0, self.canvas.width, self.canvas.height);
			// console.log('canvas cleared');
			break;

		case 'drawImage':
			var bitmap = e.data.bitmap;
			var info = { 'width': e.data.info.width, 'height': e.data.info.height }

			self.canvas.width = info['width'];
			self.canvas.height = info['height'];
			
			self.context.clearRect(0, 0, self.canvas.width, self.canvas.height); /* Reset */
			self.context.drawImage(bitmap, 0, 0, self.canvas.width, self.canvas.height); /* Draw image */
			autoCropCanvas(self.canvas, self.context);
			// console.log('image drawn');
			break;

		case 'updateKeys':
			self.replacedPalette = e.data.palette;
			self.keys = e.data.keys;
			// console.log('keys updated');
			// console.log(self.replacedPalette);
			// console.log(self.keys);
			replaceColor();
			break;

		case 'extractColor':
			reset();
			// console.log('extractColor');
			var obj = {};
			var array = e.data.array;
			var count = 0;
			var imgData = self.context.getImageData(0, 0, self.canvas.width, self.canvas.height);

			for (var x = 0; x < self.canvas.width; x++ ) {
				for (var y = 0; y < self.canvas.height; y++ ) {
					var r = imgData.data[(y * imgData.width * 4) + (x * 4) + 0 ];
					var g = imgData.data[(y * imgData.width * 4) + (x * 4) + 1 ];
					var b = imgData.data[(y * imgData.width * 4) + (x * 4) + 2 ];
					var rgb = 'rgb(' + r + ',' + g + ',' + b + ')';

					if (!array.includes(rgb)) {
						array.push(rgb);
						obj[JSON.stringify(count)] = { 'r': r, 'g': g, 'b': b };
						count++;
						postMessage({'msg': 'findNearestColor', 'array': array, 'obj': obj, 'rgb': {'r': r, 'g': g, 'b': b}});
					}
				}
			}
			// console.log('color extracted');
			getKeys();
			break;

		case 'buildSpriteSheet':
			var array = e.data.array;
			var status = {'x': 0, 'y': 0}; /* Status object to hold where the next draw will take place */
			var buffer;
			var canvasInfo = getCanvasInfo(array);
			self.canvas.width = canvasInfo['x'];
			self.canvas.height = canvasInfo['y'];
			self.count++;

			status['x'] = canvasInfo['maxW']; /* Get the first draw information based on width of first image */

			for (var i of array) {/* loop through the data in self array */
				buffer = { 'x': canvasInfo['maxW'], 'y': canvasInfo['maxH'] }; /* The buffer space between each draw */

				if (status['x'] + buffer['x'] >= buffer['x'] * self.maxRows) {/* If row is full of draws */
					status['x'] = buffer['x']; /* Reset row status */
					status['y'] += buffer['y']; /* Change the column */
					self.context.drawImage(i, status['x'] + buffer['x'], status['y'] + buffer['y']); /* Draw image on the next column */

				} else {/* Drawing on the first row */
					self.context.drawImage(i, status['x'] + buffer['x'], status['y'] + buffer['y']); /* Draw image on the next x coordinate */
				}

				status['x'] += buffer['x']; /* Increase column space each draw */
			}

			autoCropCanvas(self.canvas, self.context);
			postMessage({ 'msg': 'loaded' });
			postMessage({ 'msg': 'resizeCanvas', 'width': canvas.width, 'height': canvas.height });
			reset();
			break;
	}
}

function replaceColor() {
	postMessage({ 'msg': 'busy' });
	var imgData = self.context.getImageData(0, 0, self.canvas.width, self.canvas.height);
	
	for (let i = 0; i < imgData.data.length; i += 4) {
		var r = imgData.data[i + 0];  // R value
		var g = imgData.data[i + 1];   // G value
		var b = imgData.data[i + 2];  // B value
		var a = imgData.data[i + 3];  // A value
		var rgb = 'rgb(' + r + ',' + g + ',' + b + ')';

		if (a < 255) {
			continue;
		}
		var value = checker(rgb);

		if (value) {
			var rgbArray = value.match(/\d+/g);
			var r2 = rgbArray[0];
			var g2 = rgbArray[1];
			var b2 = rgbArray[2];

			imgData.data[i + 0] = r2;  // R value
			imgData.data[i + 1] = g2;   // G value
			imgData.data[i + 2] = b2;  // B value
			imgData.data[i + 3] = 255;  // A value
		}
	}
	self.context.putImageData(imgData, 0, 0);
	// console.log('palette replaced');
	self.canvas.convertToBlob().then(function(blob) {
		self.blob = blob;
		postMessage({'msg': 'ready', 'blob': self.blob});
		reset();
	});
}


function checker(rgb) {
	for (var count = 0; count < self.keys.length; count++) {
		if (rgb === self.keys[count]) { // if the color matches the key
			return self.replacedPalette[rgb]; // return the value of the color that replaces self color
		}
	}
}

function getKeys() {
	postMessage({ 'msg': 'getKeys' });
}

function getCanvasInfo(array, maxRows) {
	var count = 0;
	var width = 0;
	var height = 0;
	var maxW = 0;
	var maxH = 0;
	var status = {'x': 0, 'y': 0};

	for (var j = 0; j < array.length; j++) {
		if (array[j].height > maxH) {
			maxH = array[j].height;
		}
		
		if (array[j].width > maxW) {
			maxW = array[j].width;
		}

	}
	status['x'] = maxW;

	for (var r = 3, c = 1, total = 0; total <= array.length; c++) {
		if (status['x'] + maxW >= maxW * self.maxRows) {
			status['x'] = maxW;
			status['y'] += maxH;
			c = 1;
			r++;
		}

		status['x'] += maxW;

		total++;
	}

	width = maxW * self.maxRows;
	height = r * maxH;

	return { 'x': width, 'y': height, 'maxW': maxW, 'maxH': maxH };
}

function autoCropCanvas(canvas, ctx) {
		var bounds = {
			left: 0,
			right: canvas.width,
			top: 0,
			bottom: canvas.height
		};
		var rows = [];
		var cols = [];
		var imageData = ctx.getImageData(0, 0, canvas.width, canvas.height);
		for (var x = 0; x < canvas.width; x++) {
			cols[x] = cols[x] || false;
			for (var y = 0; y < canvas.height; y++) {
				rows[y] = rows[y] || false;
				const p = y * (canvas.width * 4) + x * 4;
				const [r, g, b, a] = [imageData.data[p], imageData.data[p + 1], imageData.data[p + 2], imageData.data[p + 3]];
				var isEmptyPixel = Math.max(r, g, b, a) === 0;
				if (!isEmptyPixel) {
					cols[x] = true;
					rows[y] = true;
				}
			}
		}
		for (var i = 0; i < rows.length; i++) {
			if (rows[i]) {
				bounds.top = i ? i : i;
				break;
			}
		}
		for (var i = rows.length; i--; ) {
			if (rows[i]) {
				bounds.bottom = i < canvas.height ? i + 1: i;
				break;
			}
		}
		for (var i = 0; i < cols.length; i++) {
			if (cols[i]) {
				bounds.left = i ? i : i;
				break;
			}
		}
		for (var i = cols.length; i--; ) {
			if (cols[i]) {
				bounds.right = i < canvas.width ? i + 1: i;
				break;
			}
		}
		var newWidth = bounds.right - bounds.left;
		var newHeight = bounds.bottom - bounds.top;
		var cut = ctx.getImageData(bounds.left, bounds.top, newWidth, newHeight);
		canvas.width = newWidth;
		canvas.height = newHeight;
		ctx.putImageData(cut, 0, 0);
		postMessage({ 'msg': 'resizeCanvas', 'width': canvas.width, 'height': canvas.height });
	}

function reset() {
	self.keys = [];
	self.replacedPalette = {};
	self.blob = undefined;
	// console.log('worker script reset');
}
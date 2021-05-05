#BEGIN WEBSTYLE

.text {
	font-weight: bold;
	font-size: 12;
	font-family: 'Arial';
}

.center {
	text-align: center;
	padding-top: 100px;
}

.busy {
	font-family: Arial;
	font-size: 25px;
	text-align: center;
}

#wb_canvas_output {
	border: 2px solid #070812;
}

label {
	display: inline-block;
	width: 120px;
	height 50px;
	overflow: visible;
}

.fake-button {
	display:inline-block;
	border:0.1em solid #070812;
	border-radius:0.12em;
	box-sizing: border-box;
	text-decoration:none;
	font-family:'Roboto',sans-serif;
	font-color: #f3f3f3;
	font-weight:300;
	color: #f3f3f3;
	background-color: rgb(51, 51, 51);
	text-align:center;
	transition: all 0.2s;
}

.fake-button:hover {
	color:#a9a9a9;
	background-color:#1c1e1f;
}

.unsupported {
	color: #ff0000;
	font-weight: bold;
}

::-webkit-scrollbar {
	width: 8px;
	height: 8px;
}

::-webkit-scrollbar-track {
	border-radius: 10px;
	background: rgba(0, 0, 0, 0.1);
}

::-webkit-scrollbar-thumb {
	border-radius: 10px;
	background: rgba(0, 0, 0, 0.2);
}
	
::-webkit-scrollbar-thumb:hover {
	background: rgba(0, 0, 0, 0.4);
}
	
::-webkit-scrollbar-thumb:active {
	background: rgba(0, 0, 0, 0.9);
}

.container {
	position: absolute;
	top:0;
	bottom: 0;
	left: 0;
	right: 0;
	margin: auto;
}

/*
.container {
   position: absolute;
   top: 50%;
   left: 50%;
   -moz-transform: translateX(-50%) translateY(-50%);
   -webkit-transform: translateX(-50%) translateY(-50%);
   transform: translateX(-50%) translateY(-50%);
}

*/

#END WEBSTYLE
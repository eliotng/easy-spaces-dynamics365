/*
 * ATTENTION: The "eval" devtool has been used (maybe by default in mode: "development").
 * This devtool is neither made for production nor for readable output files.
 * It uses "eval()" calls to create a separate source file in the browser devtools.
 * If you are trying to read the output file, select a different devtool (https://webpack.js.org/configuration/devtool/)
 * or disable the default devtool with "devtool: false".
 * If you are looking for production-ready output files, see mode: "production" (https://webpack.js.org/configuration/mode/).
 */
var pcf_tools_652ac3f36e1e4bca82eb3c1dc44e6fad;
/******/ (function() { // webpackBootstrap
/******/ 	"use strict";
/******/ 	var __webpack_modules__ = ({

/***/ "./index.ts":
/*!******************!*\
  !*** ./index.ts ***!
  \******************/
/***/ (function(__unused_webpack_module, __webpack_exports__, __webpack_require__) {

eval("{__webpack_require__.r(__webpack_exports__);\n/* harmony export */ __webpack_require__.d(__webpack_exports__, {\n/* harmony export */   ImageGallery: function() { return /* binding */ ImageGallery; }\n/* harmony export */ });\nclass ImageGallery {\n  constructor() {}\n  init(context, notifyOutputChanged, state, container) {\n    this._context = context;\n    this._container = container;\n    this._notifyOutputChanged = notifyOutputChanged;\n    // Initialize the gallery container\n    this._galleryContainer = document.createElement(\"div\");\n    this._galleryContainer.className = \"image-gallery-container\";\n    this.renderGallery();\n    this._container.appendChild(this._galleryContainer);\n  }\n  updateView(context) {\n    this._context = context;\n    // Parse items from input parameter\n    if (context.parameters.items.raw) {\n      try {\n        this._items = JSON.parse(context.parameters.items.raw);\n        this.renderGallery();\n      } catch (error) {\n        console.error(\"ImageGallery: Error parsing items\", error);\n      }\n    }\n  }\n  renderGallery() {\n    this._galleryContainer.innerHTML = \"\\n            <div class=\\\"image-gallery\\\">\\n                <div class=\\\"gallery-header\\\">\\n                    <h3>Space Gallery</h3>\\n                </div>\\n                <div class=\\\"gallery-grid\\\" id=\\\"galleryGrid\\\">\\n                    \".concat(this.renderItems(), \"\\n                </div>\\n            </div>\\n        \");\n    // Add event listeners for image selection\n    this.attachEventListeners();\n  }\n  renderItems() {\n    if (!this._items || this._items.length === 0) {\n      return '<div class=\"no-images\">No images available</div>';\n    }\n    return this._items.map((item, index) => {\n      var _a, _b, _c, _d, _e;\n      return \"\\n            <div class=\\\"image-tile \".concat(item.selected ? 'selected' : '', \" \").concat(item.muted ? 'muted' : '', \"\\\" \\n                 data-id=\\\"\").concat(((_a = item.record) === null || _a === void 0 ? void 0 : _a.Id) || index, \"\\\"\\n                 data-index=\\\"\").concat(index, \"\\\">\\n                <div class=\\\"image-container\\\">\\n                    <img src=\\\"\").concat(((_b = item.record) === null || _b === void 0 ? void 0 : _b.ImageUrl) || '/default-space.jpg', \"\\\" \\n                         alt=\\\"\").concat(((_c = item.record) === null || _c === void 0 ? void 0 : _c.Name) || 'Space Image', \"\\\" \\n                         loading=\\\"lazy\\\" />\\n                    <div class=\\\"image-overlay\\\">\\n                        <div class=\\\"image-info\\\">\\n                            <h4>\").concat(((_d = item.record) === null || _d === void 0 ? void 0 : _d.Name) || 'Unnamed Space', \"</h4>\\n                            <p>\").concat(((_e = item.record) === null || _e === void 0 ? void 0 : _e.Description) || '', \"</p>\\n                        </div>\\n                    </div>\\n                </div>\\n                <div class=\\\"selection-indicator\\\">\\n                    <i class=\\\"selection-icon\\\">\").concat(item.selected ? '✓' : '', \"</i>\\n                </div>\\n            </div>\\n        \");\n    }).join('');\n  }\n  attachEventListeners() {\n    var galleryGrid = this._galleryContainer.querySelector(\"#galleryGrid\");\n    if (galleryGrid) {\n      galleryGrid.addEventListener(\"click\", event => {\n        var tile = event.target.closest(\".image-tile\");\n        if (tile) {\n          var itemId = tile.getAttribute(\"data-id\");\n          var itemIndex = parseInt(tile.getAttribute(\"data-index\") || \"0\");\n          this.selectItem(itemId, itemIndex);\n        }\n      });\n    }\n  }\n  selectItem(itemId, itemIndex) {\n    var _a;\n    if (!this._items) return;\n    // Update selection state\n    this._items = this._items.map((item, index) => {\n      var _a;\n      var isCurrentItem = ((_a = item.record) === null || _a === void 0 ? void 0 : _a.Id) === itemId || index === itemIndex;\n      return Object.assign(Object.assign({}, item), {\n        selected: isCurrentItem ? !item.selected : false // Single selection\n      });\n    });\n    // Find selected item\n    var selectedItem = this._items.find(item => item.selected);\n    this._selectedItem = selectedItem ? ((_a = selectedItem.record) === null || _a === void 0 ? void 0 : _a.Id) || itemIndex.toString() : \"\";\n    // Re-render gallery\n    this.renderGallery();\n    // Notify of changes\n    this._notifyOutputChanged();\n    // Dispatch custom event\n    var selectedEvent = new CustomEvent(\"imageselected\", {\n      detail: {\n        selectedItem: selectedItem,\n        selectedId: this._selectedItem\n      }\n    });\n    this._container.dispatchEvent(selectedEvent);\n  }\n  getOutputs() {\n    var _a;\n    return {\n      selectedItem: this._selectedItem,\n      selectedItems: JSON.stringify(((_a = this._items) === null || _a === void 0 ? void 0 : _a.filter(item => item.selected)) || [])\n    };\n  }\n  destroy() {\n    // Clean up\n  }\n}\n\n//# sourceURL=webpack://pcf_tools_652ac3f36e1e4bca82eb3c1dc44e6fad/./index.ts?\n}");

/***/ })

/******/ 	});
/************************************************************************/
/******/ 	// The require scope
/******/ 	var __webpack_require__ = {};
/******/ 	
/************************************************************************/
/******/ 	/* webpack/runtime/define property getters */
/******/ 	!function() {
/******/ 		// define getter functions for harmony exports
/******/ 		__webpack_require__.d = function(exports, definition) {
/******/ 			for(var key in definition) {
/******/ 				if(__webpack_require__.o(definition, key) && !__webpack_require__.o(exports, key)) {
/******/ 					Object.defineProperty(exports, key, { enumerable: true, get: definition[key] });
/******/ 				}
/******/ 			}
/******/ 		};
/******/ 	}();
/******/ 	
/******/ 	/* webpack/runtime/hasOwnProperty shorthand */
/******/ 	!function() {
/******/ 		__webpack_require__.o = function(obj, prop) { return Object.prototype.hasOwnProperty.call(obj, prop); }
/******/ 	}();
/******/ 	
/******/ 	/* webpack/runtime/make namespace object */
/******/ 	!function() {
/******/ 		// define __esModule on exports
/******/ 		__webpack_require__.r = function(exports) {
/******/ 			if(typeof Symbol !== 'undefined' && Symbol.toStringTag) {
/******/ 				Object.defineProperty(exports, Symbol.toStringTag, { value: 'Module' });
/******/ 			}
/******/ 			Object.defineProperty(exports, '__esModule', { value: true });
/******/ 		};
/******/ 	}();
/******/ 	
/************************************************************************/
/******/ 	
/******/ 	// startup
/******/ 	// Load entry module and return exports
/******/ 	// This entry module can't be inlined because the eval devtool is used.
/******/ 	var __webpack_exports__ = {};
/******/ 	__webpack_modules__["./index.ts"](0, __webpack_exports__, __webpack_require__);
/******/ 	pcf_tools_652ac3f36e1e4bca82eb3c1dc44e6fad = __webpack_exports__;
/******/ 	
/******/ })()
;
if (window.ComponentFramework && window.ComponentFramework.registerControl) {
	ComponentFramework.registerControl('EasySpaces.ImageGallery', pcf_tools_652ac3f36e1e4bca82eb3c1dc44e6fad.ImageGallery);
} else {
	var EasySpaces = EasySpaces || {};
	EasySpaces.ImageGallery = pcf_tools_652ac3f36e1e4bca82eb3c1dc44e6fad.ImageGallery;
	pcf_tools_652ac3f36e1e4bca82eb3c1dc44e6fad = undefined;
}
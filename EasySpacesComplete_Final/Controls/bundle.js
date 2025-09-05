/*
 * ATTENTION: The "eval" devtool has been used (maybe by default in mode: "development").
 * This devtool is neither made for production nor for readable output files.
 * It uses "eval()" calls to create a separate source file in the browser devtools.
 * If you are trying to read the output file, select a different devtool (https://webpack.js.org/configuration/devtool/)
 * or disable the default devtool with "devtool: false".
 * If you are looking for production-ready output files, see mode: "production" (https://webpack.js.org/configuration/mode/).
 */
var pcf_tools_652ac3f36e1e4bca82eb3c1dc44e6fad;
/******/ (() => { // webpackBootstrap
/******/ 	"use strict";
/******/ 	var __webpack_modules__ = ({

/***/ "./index.ts":
/*!******************!*\
  !*** ./index.ts ***!
  \******************/
/***/ ((__unused_webpack_module, __webpack_exports__, __webpack_require__) => {

eval("{__webpack_require__.r(__webpack_exports__);\n/* harmony export */ __webpack_require__.d(__webpack_exports__, {\n/* harmony export */   ReservationHelper: () => (/* binding */ ReservationHelper)\n/* harmony export */ });\nvar __awaiter = undefined && undefined.__awaiter || function (thisArg, _arguments, P, generator) {\n  function adopt(value) {\n    return value instanceof P ? value : new P(function (resolve) {\n      resolve(value);\n    });\n  }\n  return new (P || (P = Promise))(function (resolve, reject) {\n    function fulfilled(value) {\n      try {\n        step(generator.next(value));\n      } catch (e) {\n        reject(e);\n      }\n    }\n    function rejected(value) {\n      try {\n        step(generator[\"throw\"](value));\n      } catch (e) {\n        reject(e);\n      }\n    }\n    function step(result) {\n      result.done ? resolve(result.value) : adopt(result.value).then(fulfilled, rejected);\n    }\n    step((generator = generator.apply(thisArg, _arguments || [])).next());\n  });\n};\nclass ReservationHelper {\n  constructor() {}\n  init(context, notifyOutputChanged, state, container) {\n    this._context = context;\n    this._container = container;\n    this._notifyOutputChanged = notifyOutputChanged;\n    // Initialize properties\n    this._reservationId = context.parameters.reservationId.raw || \"\";\n    this._customerId = context.parameters.customerId.raw || \"\";\n    this._spaceId = context.parameters.spaceId.raw || \"\";\n    // Create main container\n    this._mainContainer = document.createElement(\"div\");\n    this._mainContainer.className = \"reservation-helper-container\";\n    this.renderComponent();\n    this._container.appendChild(this._mainContainer);\n    // Set up event listeners for message passing (simulating LMS)\n    this.setupEventListeners();\n  }\n  renderComponent() {\n    this._mainContainer.innerHTML = \"\\n            <div class=\\\"reservation-helper\\\">\\n                <div class=\\\"reservation-header\\\">\\n                    <h2>Reservation Helper</h2>\\n                    <span class=\\\"flow-status\\\">\".concat(this._flowStatus || 'Ready', \"</span>\\n                </div>\\n                <div class=\\\"reservation-content\\\">\\n                    <div class=\\\"customer-section\\\">\\n                        <h3>Customer Information</h3>\\n                        <div id=\\\"customerInfo\\\" class=\\\"info-panel\\\">\\n                            \").concat(this._customerId ? this.renderCustomerInfo() : '<p>No customer selected</p>', \"\\n                        </div>\\n                    </div>\\n                    <div class=\\\"space-section\\\">\\n                        <h3>Space Information</h3>\\n                        <div id=\\\"spaceInfo\\\" class=\\\"info-panel\\\">\\n                            \").concat(this._spaceId ? this.renderSpaceInfo() : '<p>No space selected</p>', \"\\n                        </div>\\n                    </div>\\n                    <div class=\\\"actions-section\\\">\\n                        <button class=\\\"btn-primary\\\" id=\\\"startFlowBtn\\\">Start Reservation Flow</button>\\n                        <button class=\\\"btn-secondary\\\" id=\\\"refreshBtn\\\">Refresh</button>\\n                    </div>\\n                </div>\\n            </div>\\n        \");\n    // Attach event handlers\n    var startFlowBtn = this._mainContainer.querySelector(\"#startFlowBtn\");\n    var refreshBtn = this._mainContainer.querySelector(\"#refreshBtn\");\n    if (startFlowBtn) {\n      startFlowBtn.addEventListener(\"click\", this.handleStartFlow.bind(this));\n    }\n    if (refreshBtn) {\n      refreshBtn.addEventListener(\"click\", this.handleRefresh.bind(this));\n    }\n  }\n  renderCustomerInfo() {\n    // In real implementation, fetch customer details from Dataverse\n    return \"\\n            <div class=\\\"customer-details\\\">\\n                <p><strong>Customer ID:</strong> \".concat(this._customerId, \"</p>\\n                <p><strong>Status:</strong> Active</p>\\n            </div>\\n        \");\n  }\n  renderSpaceInfo() {\n    // In real implementation, fetch space details from Dataverse\n    return \"\\n            <div class=\\\"space-details\\\">\\n                <p><strong>Space ID:</strong> \".concat(this._spaceId, \"</p>\\n                <p><strong>Availability:</strong> Available</p>\\n            </div>\\n        \");\n  }\n  setupEventListeners() {\n    // Listen for customer selection events (simulating LMS)\n    this._customerSelectHandler = event => {\n      if (event.detail && event.detail.customerId) {\n        this.handleCustomerSelect(event.detail.customerId);\n      }\n    };\n    window.addEventListener(\"customerSelected\", this._customerSelectHandler);\n  }\n  handleCustomerSelect(customerId) {\n    this._customerId = customerId;\n    if (this._flowStatus === \"started\") {\n      // Show toast notification\n      this.showNotification(\"Please finish the current operation first\", \"warning\");\n    } else {\n      // Update customer info\n      this.updateCustomerInfo();\n    }\n  }\n  handleStartFlow() {\n    if (!this._customerId) {\n      this.showNotification(\"Please select a customer first\", \"error\");\n      return;\n    }\n    this._flowStatus = \"started\";\n    this._notifyOutputChanged();\n    // Trigger Power Automate flow\n    this.triggerReservationFlow();\n  }\n  handleRefresh() {\n    // Refresh data from Dataverse\n    this.refreshData();\n  }\n  triggerReservationFlow() {\n    return __awaiter(this, void 0, void 0, function* () {\n      try {\n        // Call Power Automate flow through Web API\n        var flowUrl = \"/api/data/v9.2/workflows(00000000-0000-0000-0000-000000000000)/Microsoft.Dynamics.CRM.ExecuteWorkflow\";\n        var flowInput = {\n          EntityId: this._reservationId || \"\",\n          CustomerId: this._customerId,\n          SpaceId: this._spaceId\n        };\n        // In real implementation, make actual API call\n        this.showNotification(\"Reservation flow started\", \"success\");\n        // Update status\n        this._flowStatus = \"in_progress\";\n        this._notifyOutputChanged();\n      } catch (error) {\n        this.showNotification(\"Failed to start reservation flow\", \"error\");\n        this._flowStatus = \"error\";\n        this._notifyOutputChanged();\n      }\n    });\n  }\n  updateCustomerInfo() {\n    var customerInfoDiv = this._mainContainer.querySelector(\"#customerInfo\");\n    if (customerInfoDiv) {\n      customerInfoDiv.innerHTML = this.renderCustomerInfo();\n    }\n  }\n  refreshData() {\n    return __awaiter(this, void 0, void 0, function* () {\n      try {\n        // Fetch latest data from Dataverse\n        if (this._reservationId) {\n          var reservation = yield this.getReservation(this._reservationId);\n          // Update component with fresh data\n          this.renderComponent();\n        }\n        this.showNotification(\"Data refreshed\", \"info\");\n      } catch (error) {\n        this.showNotification(\"Failed to refresh data\", \"error\");\n      }\n    });\n  }\n  getReservation(reservationId) {\n    return __awaiter(this, void 0, void 0, function* () {\n      // Use Web API to fetch reservation\n      try {\n        var result = yield this._context.webAPI.retrieveRecord(\"es_reservation\", reservationId, \"?$select=es_name,es_status,es_startdate,es_enddate\");\n        return result;\n      } catch (error) {\n        console.error(\"Error fetching reservation:\", error);\n        throw error;\n      }\n    });\n  }\n  showNotification(message, type) {\n    // In real implementation, use Xrm.Navigation.openAlertDialog or custom notification\n    console.log(\"[\".concat(type.toUpperCase(), \"] \").concat(message));\n    // Create temporary notification element\n    var notification = document.createElement(\"div\");\n    notification.className = \"notification notification-\".concat(type);\n    notification.textContent = message;\n    this._mainContainer.appendChild(notification);\n    // Remove after 3 seconds\n    setTimeout(() => {\n      notification.remove();\n    }, 3000);\n  }\n  updateView(context) {\n    this._context = context;\n    // Update properties if changed\n    var newReservationId = context.parameters.reservationId.raw || \"\";\n    var newCustomerId = context.parameters.customerId.raw || \"\";\n    var newSpaceId = context.parameters.spaceId.raw || \"\";\n    if (newReservationId !== this._reservationId || newCustomerId !== this._customerId || newSpaceId !== this._spaceId) {\n      this._reservationId = newReservationId;\n      this._customerId = newCustomerId;\n      this._spaceId = newSpaceId;\n      this.renderComponent();\n    }\n  }\n  getOutputs() {\n    return {\n      flowStatus: this._flowStatus\n    };\n  }\n  destroy() {\n    // Remove event listeners\n    if (this._customerSelectHandler) {\n      window.removeEventListener(\"customerSelected\", this._customerSelectHandler);\n    }\n  }\n}\n\n//# sourceURL=webpack://pcf_tools_652ac3f36e1e4bca82eb3c1dc44e6fad/./index.ts?\n}");

/***/ })

/******/ 	});
/************************************************************************/
/******/ 	// The require scope
/******/ 	var __webpack_require__ = {};
/******/ 	
/************************************************************************/
/******/ 	/* webpack/runtime/define property getters */
/******/ 	(() => {
/******/ 		// define getter functions for harmony exports
/******/ 		__webpack_require__.d = (exports, definition) => {
/******/ 			for(var key in definition) {
/******/ 				if(__webpack_require__.o(definition, key) && !__webpack_require__.o(exports, key)) {
/******/ 					Object.defineProperty(exports, key, { enumerable: true, get: definition[key] });
/******/ 				}
/******/ 			}
/******/ 		};
/******/ 	})();
/******/ 	
/******/ 	/* webpack/runtime/hasOwnProperty shorthand */
/******/ 	(() => {
/******/ 		__webpack_require__.o = (obj, prop) => (Object.prototype.hasOwnProperty.call(obj, prop))
/******/ 	})();
/******/ 	
/******/ 	/* webpack/runtime/make namespace object */
/******/ 	(() => {
/******/ 		// define __esModule on exports
/******/ 		__webpack_require__.r = (exports) => {
/******/ 			if(typeof Symbol !== 'undefined' && Symbol.toStringTag) {
/******/ 				Object.defineProperty(exports, Symbol.toStringTag, { value: 'Module' });
/******/ 			}
/******/ 			Object.defineProperty(exports, '__esModule', { value: true });
/******/ 		};
/******/ 	})();
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
	ComponentFramework.registerControl('EasySpaces.ReservationHelper', pcf_tools_652ac3f36e1e4bca82eb3c1dc44e6fad.ReservationHelper);
} else {
	var EasySpaces = EasySpaces || {};
	EasySpaces.ReservationHelper = pcf_tools_652ac3f36e1e4bca82eb3c1dc44e6fad.ReservationHelper;
	pcf_tools_652ac3f36e1e4bca82eb3c1dc44e6fad = undefined;
}
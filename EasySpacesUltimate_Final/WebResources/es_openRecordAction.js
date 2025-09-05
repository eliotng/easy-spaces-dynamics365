// Easy Spaces - Open Record Action
// Replaces Salesforce openRecordAction Aura component
var EasySpaces = EasySpaces || {};

EasySpaces.openRecord = function(primaryControl, selectedItems) {
    "use strict";
    
    try {
        if (!selectedItems || selectedItems.length === 0) {
            // No items selected, get current record
            var formContext = primaryControl;
            var recordId = formContext.data.entity.getId();
            var entityName = formContext.data.entity.getEntityName();
            
            if (recordId) {
                // Remove curly braces from GUID
                recordId = recordId.replace(/[{}]/g, "");
                EasySpaces.openRecordInNewWindow(entityName, recordId);
            }
        } else {
            // Open each selected record
            selectedItems.forEach(function(item) {
                if (item.Id) {
                    var cleanId = item.Id.replace(/[{}]/g, "");
                    var entityName = item.TypeName;
                    EasySpaces.openRecordInNewWindow(entityName, cleanId);
                }
            });
        }
    } catch (error) {
        console.error("EasySpaces.openRecord error:", error);
        Xrm.Navigation.openAlertDialog({
            title: "Error",
            text: "Unable to open record: " + error.message
        });
    }
};

EasySpaces.openRecordInNewWindow = function(entityName, recordId) {
    "use strict";
    
    var pageInput = {
        pageType: "entityrecord",
        entityName: entityName,
        entityId: recordId
    };
    
    var navigationOptions = {
        target: 2, // New window
        width: 1200,
        height: 800
    };
    
    Xrm.Navigation.navigateTo(pageInput, navigationOptions).then(
        function success() {
            console.log("Record opened successfully");
        },
        function error(err) {
            console.error("Error opening record:", err);
            Xrm.Navigation.openAlertDialog({
                title: "Error",
                text: "Unable to open record in new window"
            });
        }
    );
};
/*
*This is auto generated from the ControlManifest.Input.xml file
*/

// Define IInputs and IOutputs Type. They should match with ControlManifest.
export interface IInputs {
    reservationId: ComponentFramework.PropertyTypes.StringProperty;
    customerId: ComponentFramework.PropertyTypes.StringProperty;
    spaceId: ComponentFramework.PropertyTypes.StringProperty;
}
export interface IOutputs {
    flowStatus?: string;
}

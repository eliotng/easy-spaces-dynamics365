using System;
using System.Linq;
using Microsoft.Xrm.Sdk;
using Microsoft.Xrm.Sdk.Query;
using Microsoft.Crm.Sdk.Messages;

namespace EasySpaces.Plugins
{
    /// <summary>
    /// Plugin to manage space reservations - replaces Apex ReservationManager class
    /// </summary>
    public class ReservationManagerPlugin : IPlugin
    {
        public void Execute(IServiceProvider serviceProvider)
        {
            // Obtain the execution context from the service provider
            IPluginExecutionContext context = (IPluginExecutionContext)serviceProvider.GetService(typeof(IPluginExecutionContext));
            IOrganizationServiceFactory serviceFactory = (IOrganizationServiceFactory)serviceProvider.GetService(typeof(IOrganizationServiceFactory));
            IOrganizationService service = serviceFactory.CreateOrganizationService(context.UserId);
            ITracingService tracingService = (ITracingService)serviceProvider.GetService(typeof(ITracingService));

            try
            {
                tracingService.Trace("ReservationManagerPlugin: Starting execution");

                // Check the message name
                if (context.MessageName.Equals("Create", StringComparison.InvariantCultureIgnoreCase) ||
                    context.MessageName.Equals("Update", StringComparison.InvariantCultureIgnoreCase))
                {
                    if (context.InputParameters.Contains("Target") && context.InputParameters["Target"] is Entity)
                    {
                        Entity reservation = (Entity)context.InputParameters["Target"];
                        
                        // Only process reservation entities
                        if (reservation.LogicalName != "es_reservation")
                            return;

                        // Validate reservation
                        ValidateReservation(reservation, service, tracingService);
                        
                        // Check for conflicts
                        CheckForConflicts(reservation, service, tracingService);
                        
                        // Calculate pricing if needed
                        if (context.MessageName.Equals("Create"))
                        {
                            CalculatePricing(reservation, service, tracingService);
                        }
                        
                        // Update reservation status workflow
                        UpdateReservationStatus(reservation, service, tracingService);
                    }
                }
                else if (context.MessageName.Equals("es_getupcomingReservations"))
                {
                    // Custom action to get upcoming reservations
                    var results = GetUpcomingReservations(service, tracingService);
                    context.OutputParameters["Reservations"] = results;
                }
                else if (context.MessageName.Equals("es_getReservationsByStatus"))
                {
                    // Custom action to get reservations by status
                    string status = context.InputParameters["Status"] as string;
                    var results = GetReservationsByStatus(status, service, tracingService);
                    context.OutputParameters["Reservations"] = results;
                }

                tracingService.Trace("ReservationManagerPlugin: Execution completed successfully");
            }
            catch (Exception ex)
            {
                tracingService.Trace($"ReservationManagerPlugin: Error - {ex.Message}");
                throw new InvalidPluginExecutionException($"An error occurred in ReservationManagerPlugin: {ex.Message}", ex);
            }
        }

        private void ValidateReservation(Entity reservation, IOrganizationService service, ITracingService tracingService)
        {
            tracingService.Trace("ValidateReservation: Starting validation");

            // Check required fields
            if (!reservation.Contains("es_startdate"))
                throw new InvalidPluginExecutionException("Start date is required");
            
            if (!reservation.Contains("es_enddate"))
                throw new InvalidPluginExecutionException("End date is required");
            
            if (!reservation.Contains("es_spaceid"))
                throw new InvalidPluginExecutionException("Space is required");

            DateTime startDate = reservation.GetAttributeValue<DateTime>("es_startdate");
            DateTime endDate = reservation.GetAttributeValue<DateTime>("es_enddate");

            // Validate dates
            if (startDate >= endDate)
                throw new InvalidPluginExecutionException("End date must be after start date");
            
            if (startDate < DateTime.Now.Date)
                throw new InvalidPluginExecutionException("Start date cannot be in the past");

            // Validate guest count
            if (reservation.Contains("es_totalnumberofguests"))
            {
                int guestCount = reservation.GetAttributeValue<int>("es_totalnumberofguests");
                
                // Get space capacity
                EntityReference spaceRef = reservation.GetAttributeValue<EntityReference>("es_spaceid");
                Entity space = service.Retrieve("es_space", spaceRef.Id, new ColumnSet("es_maximumcapacity"));
                
                if (space.Contains("es_maximumcapacity"))
                {
                    int maxCapacity = space.GetAttributeValue<int>("es_maximumcapacity");
                    if (guestCount > maxCapacity)
                        throw new InvalidPluginExecutionException($"Guest count exceeds space capacity of {maxCapacity}");
                }
            }

            tracingService.Trace("ValidateReservation: Validation completed");
        }

        private void CheckForConflicts(Entity reservation, IOrganizationService service, ITracingService tracingService)
        {
            tracingService.Trace("CheckForConflicts: Checking for reservation conflicts");

            if (!reservation.Contains("es_spaceid") || !reservation.Contains("es_startdate") || !reservation.Contains("es_enddate"))
                return;

            EntityReference spaceRef = reservation.GetAttributeValue<EntityReference>("es_spaceid");
            DateTime startDate = reservation.GetAttributeValue<DateTime>("es_startdate");
            DateTime endDate = reservation.GetAttributeValue<DateTime>("es_enddate");

            // Query for overlapping reservations
            QueryExpression query = new QueryExpression("es_reservation");
            query.ColumnSet = new ColumnSet("es_name", "es_startdate", "es_enddate");
            
            // Filter by space
            query.Criteria.AddCondition("es_spaceid", ConditionOperator.Equal, spaceRef.Id);
            
            // Filter by status (exclude cancelled)
            query.Criteria.AddCondition("es_status", ConditionOperator.NotEqual, 10016); // Cancelled status
            
            // Exclude current record if updating
            if (reservation.Id != Guid.Empty)
            {
                query.Criteria.AddCondition("es_reservationid", ConditionOperator.NotEqual, reservation.Id);
            }

            // Check for date overlap
            FilterExpression dateFilter = new FilterExpression(LogicalOperator.And);
            dateFilter.AddCondition("es_startdate", ConditionOperator.LessThan, endDate);
            dateFilter.AddCondition("es_enddate", ConditionOperator.GreaterThan, startDate);
            query.Criteria.AddFilter(dateFilter);

            EntityCollection results = service.RetrieveMultiple(query);
            
            if (results.Entities.Count > 0)
            {
                string conflictingReservations = string.Join(", ", results.Entities.Select(e => e.GetAttributeValue<string>("es_name")));
                throw new InvalidPluginExecutionException($"This space has conflicting reservations: {conflictingReservations}");
            }

            tracingService.Trace("CheckForConflicts: No conflicts found");
        }

        private void CalculatePricing(Entity reservation, IOrganizationService service, ITracingService tracingService)
        {
            tracingService.Trace("CalculatePricing: Calculating reservation pricing");

            if (!reservation.Contains("es_spaceid"))
                return;

            // Get space details including daily/weekly rates
            EntityReference spaceRef = reservation.GetAttributeValue<EntityReference>("es_spaceid");
            Entity space = service.Retrieve("es_space", spaceRef.Id, 
                new ColumnSet("es_dailyrate", "es_weeklyrate", "es_monthlyrate"));

            decimal dailyRate = space.GetAttributeValue<Money>("es_dailyrate")?.Value ?? 0;
            decimal weeklyRate = space.GetAttributeValue<Money>("es_weeklyrate")?.Value ?? 0;
            decimal monthlyRate = space.GetAttributeValue<Money>("es_monthlyrate")?.Value ?? 0;

            DateTime startDate = reservation.GetAttributeValue<DateTime>("es_startdate");
            DateTime endDate = reservation.GetAttributeValue<DateTime>("es_enddate");
            
            int totalDays = (endDate - startDate).Days;
            decimal totalPrice = 0;

            // Calculate price based on duration
            if (totalDays >= 30 && monthlyRate > 0)
            {
                int months = totalDays / 30;
                int remainingDays = totalDays % 30;
                totalPrice = (months * monthlyRate) + (remainingDays * dailyRate);
            }
            else if (totalDays >= 7 && weeklyRate > 0)
            {
                int weeks = totalDays / 7;
                int remainingDays = totalDays % 7;
                totalPrice = (weeks * weeklyRate) + (remainingDays * dailyRate);
            }
            else
            {
                totalPrice = totalDays * dailyRate;
            }

            // Set the calculated price
            reservation["es_totalprice"] = new Money(totalPrice);
            
            tracingService.Trace($"CalculatePricing: Total price calculated as {totalPrice}");
        }

        private void UpdateReservationStatus(Entity reservation, IOrganizationService service, ITracingService tracingService)
        {
            tracingService.Trace("UpdateReservationStatus: Updating reservation status workflow");

            // Implement status transition logic
            if (reservation.Contains("es_status"))
            {
                OptionSetValue status = reservation.GetAttributeValue<OptionSetValue>("es_status");
                
                // Status values:
                // 10013 - Draft
                // 10014 - Submitted
                // 10015 - Confirmed
                // 10016 - Cancelled
                // 10017 - Completed

                switch (status.Value)
                {
                    case 10014: // Submitted
                        // Trigger approval workflow
                        SendApprovalRequest(reservation, service, tracingService);
                        break;
                    
                    case 10015: // Confirmed
                        // Send confirmation email
                        SendConfirmationEmail(reservation, service, tracingService);
                        break;
                    
                    case 10016: // Cancelled
                        // Release space and notify customer
                        HandleCancellation(reservation, service, tracingService);
                        break;
                }
            }
        }

        private EntityCollection GetUpcomingReservations(IOrganizationService service, ITracingService tracingService)
        {
            tracingService.Trace("GetUpcomingReservations: Fetching upcoming reservations");

            QueryExpression query = new QueryExpression("es_reservation");
            query.ColumnSet = new ColumnSet(true);
            query.Criteria.AddCondition("es_startdate", ConditionOperator.GreaterEqual, DateTime.Now);
            query.Criteria.AddCondition("es_status", ConditionOperator.NotEqual, 10016); // Not cancelled
            query.AddOrder("es_startdate", OrderType.Ascending);
            query.TopCount = 50;

            return service.RetrieveMultiple(query);
        }

        private EntityCollection GetReservationsByStatus(string status, IOrganizationService service, ITracingService tracingService)
        {
            tracingService.Trace($"GetReservationsByStatus: Fetching reservations with status {status}");

            int statusValue = GetStatusValue(status);

            QueryExpression query = new QueryExpression("es_reservation");
            query.ColumnSet = new ColumnSet(true);
            query.Criteria.AddCondition("es_status", ConditionOperator.Equal, statusValue);
            query.AddOrder("es_startdate", OrderType.Ascending);
            query.TopCount = 100;

            return service.RetrieveMultiple(query);
        }

        private int GetStatusValue(string status)
        {
            switch (status.ToLower())
            {
                case "draft": return 10013;
                case "submitted": return 10014;
                case "confirmed": return 10015;
                case "cancelled": return 10016;
                case "completed": return 10017;
                default: throw new InvalidPluginExecutionException($"Invalid status: {status}");
            }
        }

        private void SendApprovalRequest(Entity reservation, IOrganizationService service, ITracingService tracingService)
        {
            // Trigger Power Automate flow for approval
            tracingService.Trace("SendApprovalRequest: Triggering approval workflow");
            
            // In real implementation, this would trigger a Power Automate flow
            // or create an approval record
        }

        private void SendConfirmationEmail(Entity reservation, IOrganizationService service, ITracingService tracingService)
        {
            // Send confirmation email to customer
            tracingService.Trace("SendConfirmationEmail: Sending confirmation email");
            
            // In real implementation, this would create an email activity
            // or trigger a Power Automate flow for email
        }

        private void HandleCancellation(Entity reservation, IOrganizationService service, ITracingService tracingService)
        {
            // Handle reservation cancellation
            tracingService.Trace("HandleCancellation: Processing cancellation");
            
            // Release the space for other bookings
            // Send cancellation notification
            // Process any refunds if needed
        }
    }
}
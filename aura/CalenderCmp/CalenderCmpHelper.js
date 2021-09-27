({
    loadDataToCalendar: function(component, data) {
        //Find Current date for default date
        
        $("#calendar").fullCalendar("removeEvents");
        $("#calendar").fullCalendar("addEventSource", data);
        $("#calendar").fullCalendar("refetchEvents");
        this.hideSpinner(component);
    },
    
    loadCalendar: function(component) {
        component.set("v.mycolumns", [
            { label: "Subject", fieldName: "Subject", type: "text" },
            {
                label: "Start",
                fieldName: "StartDateTime",
                type: "date",
                typeAttributes: {
                    year: "numeric",
                    month: "long",
                    day: "2-digit",
                    hour: "2-digit",
                    minute: "2-digit"
                }
            },
            {
                label: "End",
                fieldName: "EndDateTime",
                type: "date",
                typeAttributes: {
                    year: "numeric",
                    month: "long",
                    day: "2-digit",
                    hour: "2-digit",
                    minute: "2-digit"
                }
            },
            { label: "Sync Status", fieldName: "Sync_Status__c", type: "text" }
        ]);
        
        //Find Current date for default date
        var d = new Date();
        var month = d.getMonth() + 1;
        var day = d.getDate();
        var currentDate =
            d.getFullYear() +
            "/" +
            (month < 10 ? "0" : "") +
            month +
            "/" +
            (day < 10 ? "0" : "") +
            day;
        // console.log('value of data'+data);
        var self = this;
        let calendar = $("#calendar").fullCalendar({
            header: {
                left: "prev,next today",
                center: "title",
                right: "month,basicWeek,basicDay"
            },
            selectable: true,
            defaultDate: currentDate,
            editable: true,
            eventLimit: true,
            // events:data,
            dragScroll: true,
            droppable: true,
            weekNumbers: true,
            eventClick: function(event, jsEvent, view) {
                var editRecordEvent = $A.get("e.force:editRecord");
                editRecordEvent.setParams({
                    recordId: event.id
                });
                editRecordEvent.fire();
            },
            dayClick: function(date, jsEvent, view) {
                var date1 = new Date(date);
                console.log("dayclised" + date1);
                var theyear = date1.getFullYear();
                var themonth = date1.getMonth() + 1;
                var thetoday = date1.getDate();
                console.log("dayclised" + theyear, themonth, thetoday);
                //var datelist = date1.format().toString().split('-');
                let datestring =
                    theyear + "-" + themonth + "-" + thetoday + "T09:00:00.000Z";
                let spec = component.find("selectSpecialization").get("v.value");
                let myArr = spec.split("-");
                component.set("v.showEditModel", true);
                let datelocal = moment(date1, "DDMMYYYY").add("15", "minutes");
                let startDateTime = datelocal.toISOString();
                component.set("v.startDate", startDateTime);
                
                //  component.find("StartDate").set('v.value',datestring);
                /*
                var createRecordEvent = $A.get("e.force:createRecord");
                createRecordEvent.setParams({
                    "entityApiName": "Event",
                    "defaultFieldValues": {
                        'StartDateTime' : datestring,
                        Specialization__c : myArr[0]
                        
                    }
                });
                createRecordEvent.fire(); */
      },
        eventMouseover: function(event, jsEvent, view) {}
    });
      
      $("#calendar").fullCalendar("removeEvents");
      $("#calendar").fullCalendar("addEventSource", data);
      $("#calendar").fullCalendar("refetchEvents");
      this.hideSpinner(component);
  },
    
    formatFullCalendarData: function(component, events) {
        var josnDataArray = [];
        for (var i = 0; i < events.length; i++) {
            var startdate = $A.localizationService.formatDate(
                events[i].StartDateTime
            );
            var enddate = $A.localizationService.formatDate(events[i].EndDateTime);
            josnDataArray.push({
                title: events[i].Subject,
                start: startdate,
                end: enddate,
                id: events[i].Id
            });
        }
        
        return josnDataArray;
    },
    
    fetchCalenderEvents: function(component) {
        this.showSpinner(component);
        
        let userIdVar = component.find("selectPhysician").get("v.value");
        let action = component.get("c.getAllEvents");
        action.setParams({
            userId: userIdVar
        });
        
        action.setCallback(this, function(response) {
            let state = response.getState();
            if (state === "SUCCESS") {
                let data = response.getReturnValue();
                
                let josnArr = this.formatFullCalendarData(component, data);
                
                component.set("v.eventList", data);
                this.loadDataToCalendar(component, josnArr);
            } else if (state === "ERROR") {
                let error = action.getError()[0].message;
                let toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    title: "error!",
                    message: error,
                    type: "error"
                });
                this.loadDataToCalendar(component, "");
                this.hideSpinner(component);
                toastEvent.fire();
            }
        });
        
        $A.enqueueAction(action);
    },
    
    editEvent: function(component, eventid, eventdate) {
        var action = component.get("c.updateEvent");
        
        action.setParams({ eventid: eventid, eventdate: eventdate });
        
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
            } else if (state === "ERROR") {
            }
        });
        
        $A.enqueueAction(action);
    },
    
    fetchSpecialization: function(component, event, helper) {
        this.showSpinner(component);
        var action = component.get("c.getAllSpecialization");
        action.setCallback(this, function(response) {
            var state = response.getState();
            console.log("test" + state);
            if (state === "SUCCESS") {
                let storeResponse = response.getReturnValue();
                console.log("test" + JSON.stringify(storeResponse));
                component.set("v.specializationOptions", storeResponse);
                
                this.hideSpinner(component);
            } else {
                this.hideSpinner(component);
            }
        });
        $A.enqueueAction(action);
    },
    
    fetchUser: function(component, event, helper) {
        this.showSpinner(component);
        let spec = component.find("selectSpecialization").get("v.value");
        
        let myArr = spec.split("-");
        component.set("v.selectedPrice", myArr[1]);
        let action = component.get("c.getUserBySpecialization");
        action.setParams({
            specialization: myArr[0]
        });
        action.setCallback(this, function(response) {
            let state = response.getState();
            console.log("test" + state);
            if (state === "SUCCESS") {
                let storeResponse = response.getReturnValue();
                component.set("v.physicianOptions", storeResponse);
                
                this.hideSpinner(component);
            } else {
                this.hideSpinner(component);
            }
        });
        $A.enqueueAction(action);
    },
    
    createNewEvent: function(component, event, helper) {
        this.showSpinner(component);
        let spec = component.find("selectSpecialization").get("v.value");
        let myArr = spec.split("-");
        let eventObj = component.get("v.eventObject");
        
        console.log(eventObj + "eventObj");
        
        let action = component.get("c.CreateEvents");
        action.setParams({
            ownerid: component.find("selectPhysician").get("v.value"),
            specialization: myArr[0],
            subject: component.find("subject").get("v.value"),
            patientName: component.find("patientName").get("v.value"),
            patientEmail: component.find("patientEmail").get("v.value"),
            startDate: component.find("startDate").get("v.value"),
            endDate: component.find("EndDate").get("v.value")
        });
        
        action.setCallback(this, function(response) {
            let state = response.getState();
            if (state === "SUCCESS") {
                let data = response.getReturnValue();
                
                let josnArr = this.formatFullCalendarData(component, data);
                
                component.set("v.eventList", data);
                this.loadDataToCalendar(component, josnArr);
            } else if (state === "ERROR") {
                let error = action.getError()[0].message;
                let toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    title: "error!",
                    message: error,
                    type: "error"
                });
                this.loadDataToCalendar(component, "");
                this.hideSpinner(component);
                toastEvent.fire();
            }
        });
        $A.enqueueAction(action);
    },
    
    showSpinner: function(component) {
        component.set("v.Spinner", true);
    },
    
    hideSpinner: function(component) {
        component.set("v.Spinner", false);
    }
});
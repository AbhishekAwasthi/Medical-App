({
    doInit: function(component, event, helper) {
     
    },
    doAuth: function(component, event, helper) {
        var action = component.get("c.createAuthURL");
        action.setCallback(this, function(response) {
            var status = response.getState();
            if (status === "SUCCESS") {
                var authUrl = response.getReturnValue();
                window.location.href = response.getReturnValue();
            }
        });
        
        $A.enqueueAction(action);
    }
});
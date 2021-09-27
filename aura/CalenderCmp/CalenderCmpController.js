({
  afterScriptsLoaded: function(component, evt, helper) {
    helper.fetchSpecialization(component, event, helper);
    helper.loadCalendar(component);
  },

  handleCreateRecord: function(component, event, helper) {
    component.set("v.showEditModel", false);
    helper.createNewEvent(component, event, helper);
  },

  handleSelectOnchange: function(component, event, helper) {
    helper.fetchUser(component, event, helper);
  },

  handleSelectPhysicianOnchange: function(component, event, helper) {
    helper.fetchCalenderEvents(component);
  },

  handleCloseModel: function(component, event, helper) {
    component.set("v.showEditModel", false);
  }
});
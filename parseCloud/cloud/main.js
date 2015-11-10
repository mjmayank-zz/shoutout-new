
// Use Parse.Cloud.define to define as many cloud functions as you want.
// For example:
Parse.Cloud.define("hello", function(request, response) {
  response.success("Hello world!");
});


Parse.Cloud.define("queryUsers", function(request, response) {
  var query = new Parse.Query(Parse.User);
  var loc = new Parse.GeoPoint(request.params.lat, request.params.long)
  query.withinKilometers("geo", loc, 50);
  query.equalTo("visible", true);
  // query.greaterThanOrEqualTo("updatedAt", true);
  query.find({
    success: function(results) {
      var blockQuery = new Parse.Query("Block");
      blockQuery.equalTo("blockedUser", {
        __type: "Pointer",
        className: "_User",
        objectId: request.params.user})
      blockQuery.include("fromUser");
      blockQuery.find({
      	success: function(blockResults) {
      		var toRemove = []
      		for(var index in blockResults){
      			toRemove.push(blockResults[index].get("fromUser").id)
      		}
      		console.log("final blocks")
      		console.log(toRemove);
      		results = results.filter(function(x){
      			console.log(x.id)
      			if(toRemove.indexOf(x.id) >= 0){
      				console.log("blocked");
      				return false;
      			}
      			else{
      				console.log("not blocked");
      			}
      			return true;
      		});
      		response.success(results);
      	},
      	error: function(error) {
      		response.error(error)
      	}
      });
    },
    error: function() {
      response.error("users lookup failed");
    }
  });
});
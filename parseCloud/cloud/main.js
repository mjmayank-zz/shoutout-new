
// Use Parse.Cloud.define to define as many cloud functions as you want.
// For example:
Parse.Cloud.define("hello", function(request, response) {
  response.success("Hello world!");
});

Parse.Cloud.beforeSave("Messages", function(request, response) {
  if(request.object.get("to")){
    request["object"].addUnique("toArray", request.object.get("to"))
  }
  console.log(request.object.get("to"))
  response.success();
});

/*** Note: Attended Joes code. Can be modified for other use cases ***/

// Parse.Cloud.beforeSave(Parse.User, function(request, response){
  // var geoPoint = request.object.get("geo");

  // var joes = new Parse.GeoPoint({latitude: 40.109907, longitude: -88.231866});

  // var getDistanceFromLatLonInKm = function(lat1,lon1,lat2,lon2){
  //   var R = 6371.0; // Radius of the earth in km
  //   var dLat = deg2rad(lat2-lat1);  // deg2rad below
  //   var dLon = deg2rad(lon2-lon1);
  //   var a =
  //     Math.sin(dLat/2) * Math.sin(dLat/2) +
  //     Math.cos(deg2rad(lat1)) * Math.cos(deg2rad(lat2)) *
  //     Math.sin(dLon/2) * Math.sin(dLon/2)
  //     ;
  //   var c = 2.0 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a));
  //   var d = R * c; // Distance in km
  //   return d;
  // }
   
  // var deg2rad = function(deg) {
  //   return deg * (Math.PI/180)
  // }

  // var distance = getDistanceFromLatLonInKm(geoPoint.latitude, geoPoint.longitude, joes.latitude, joes.longitude);
  // console.log(distance)
  // if (distance < 0.1) {
  //     request.object.set('attendedJoes', true);
  //     console.log("saved attendedJoes");
  // }
  // response.success();
// });

Parse.Cloud.afterSave(Parse.User, function(request) {
	if(request.object.updatedAt - request.object.createdAt === 0){
	  var obj = new Parse.Object("Messages");
	  obj.set("message", "Hey @" + request.object.get("username") + "! Welcome to Shoutout. I'm one of the creators of the app. Send me a reply and say hi!");
	  obj.set("from", {
	        __type: "Pointer",
	        className: "_User",
	        objectId: "MXUYiDQWKk"})
	  obj.set("to", request["object"])
	  obj.set("toArray", [request["object"]])
	  obj.set("read", false);
	  obj.save();
	}
});

Parse.Cloud.define("queryUsers", function(request, response) {
  var query = new Parse.Query(Parse.User);
  var loc = new Parse.GeoPoint(request.params.lat, request.params.long)
  // if(!(request.params.user === "MXUYiDQWKk" || request.params.user === "5Lfcn6WUvk" || request.params.user === "G02Hp4alXN")){
    query.withinKilometers("geo", loc, 50);
  // }
  query.equalTo("visible", true);
  var oneWeekAgo = new Date();
  oneWeekAgo.setDate(oneWeekAgo.getDate() - 7);
  query.greaterThanOrEqualTo("updatedAt", oneWeekAgo);
  query.limit(1000); //maximum limit in Parse. Will have to page after this.
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
      		results = results.filter(function(x){
            // if(x.get("anonymous")){
            //   x.set("displayName", "")
            // }
      			if(toRemove.indexOf(x.id) >= 0){
      				return false;
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

Parse.Cloud.define("clusterMessage", function(request, response) {
  var query = new Parse.Query(Parse.User);
  var loc = new Parse.GeoPoint(request.params.lat, request.params.long)
  var radius = .1
  if(request.params.radius){
    radius = request.params.radius;
  }
  query.withinKilometers("geo", loc, radius);
  query.equalTo("visible", true);
  query.find({
    success: function(results) {
      console.log(results)
        var obj = new Parse.Object("Messages");
        obj.set("message", request.params.message);
        obj.set("from", {
          __type: "Pointer",
          className: "_User",
          objectId: request.params.user})
        obj.set("toArray", results)
        obj.set("read", false);
        obj.save();
        response.success(results);
    },
    error: function() {
      response.error("users lookup failed");
    }
  });
});

Parse.Cloud.define("locationCrowdedness", function(request, response) {
  response.success("4");
});